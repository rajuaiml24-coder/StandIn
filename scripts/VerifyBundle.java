import com.android.aapt.Resources;
import java.util.zip.ZipFile;
import java.util.jar.JarFile;
import java.util.Properties;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HexFormat;

class VerifyBundle {
    private static void verifySignature(String bundle, String propertiesFile) throws Exception {
        var properties = new Properties();
        try (var input = Files.newInputStream(Path.of(propertiesFile))) { properties.load(input); }
        var keyPath = Path.of(propertiesFile).toAbsolutePath().getParent()
            .resolve(properties.getProperty("storeFile")).normalize();
        var password = properties.getProperty("storePassword").toCharArray();
        var store = KeyStore.getInstance(keyPath.toFile(), password);
        Arrays.fill(password, '\0');
        var expected = store.getCertificate(properties.getProperty("keyAlias"));
        if (expected == null) throw new IllegalStateException("Upload certificate is unavailable");
        int count = 0;
        try (var jar = new JarFile(bundle, true)) {
            var entries = jar.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                if (entry.isDirectory() || entry.getName().startsWith("META-INF/")) continue;
                try (var input = jar.getInputStream(entry)) { input.transferTo(java.io.OutputStream.nullOutputStream()); }
                var signers = entry.getCodeSigners();
                if (signers == null || signers.length != 1 ||
                    !expected.equals(signers[0].getSignerCertPath().getCertificates().get(0))) {
                    throw new IllegalStateException("Missing or unexpected upload signature: " + entry.getName());
                }
                count++;
            }
        }
        System.out.println("Upload-key signature verified on " + count + " bundle entries");
        System.out.println("Upload certificate SHA-256: " + HexFormat.of().withUpperCase()
            .formatHex(MessageDigest.getInstance("SHA-256").digest(expected.getEncoded())));
    }

    private static void verifyNativeAlignment(ZipFile zip) throws Exception {
        int count = 0;
        var entries = zip.entries();
        while (entries.hasMoreElements()) {
            var entry = entries.nextElement();
            if (!(entry.getName().startsWith("base/lib/arm64-v8a/") ||
                  entry.getName().startsWith("base/lib/x86_64/")) || !entry.getName().endsWith(".so")) continue;
            byte[] bytes;
            try (var input = zip.getInputStream(entry)) { bytes = input.readAllBytes(); }
            var elf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
            if (elf.getInt(0) != 0x464C457F || elf.get(4) != 2 || elf.get(5) != 1) {
                throw new IllegalStateException("Unexpected native library format: " + entry.getName());
            }
            int offset = Math.toIntExact(elf.getLong(32));
            int size = Short.toUnsignedInt(elf.getShort(54));
            int headers = Short.toUnsignedInt(elf.getShort(56));
            for (int i = 0; i < headers; i++) {
                int start = offset + i * size;
                if (elf.getInt(start) == 1 && elf.getLong(start + 48) < 16384) {
                    throw new IllegalStateException("Native library needs 16 KB alignment: " + entry.getName());
                }
            }
            count++;
        }
        System.out.println("16 KB load-segment alignment verified on " + count + " 64-bit native libraries");
    }
    private static String attribute(Resources.XmlElement element, String name) {
        for (var attribute : element.getAttributeList()) {
            if (!attribute.getName().equals(name)) continue;
            if (!attribute.getValue().isEmpty()) return attribute.getValue();
            var compiled = attribute.getCompiledItem();
            if (compiled.hasStr()) return compiled.getStr().getValue();
            if (compiled.hasPrim()) {
                var primitive = compiled.getPrim();
                if (primitive.hasIntDecimalValue()) {
                    return Integer.toString(primitive.getIntDecimalValue());
                }
                if (primitive.hasBooleanValue()) {
                    return Boolean.toString(primitive.getBooleanValue());
                }
            }
        }
        return "";
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2 && args.length != 3) throw new IllegalArgumentException("Expected bundle path, version code, and optional signing properties path");
        try (var zip = new ZipFile(args[0])) {
            var entry = zip.getEntry("base/manifest/AndroidManifest.xml");
            if (entry == null) throw new IllegalStateException("Base manifest is missing");
            Resources.XmlElement manifest;
            try (var input = zip.getInputStream(entry)) {
                manifest = Resources.XmlNode.parseFrom(input).getElement();
            }
            String appId = attribute(manifest, "package");
            String code = attribute(manifest, "versionCode");
            String version = attribute(manifest, "versionName");
            if (!"in.withwells.standin".equals(appId) || !args[1].equals(code)) {
                throw new IllegalStateException("Unexpected application ID or version code");
            }
            for (var child : manifest.getChildList()) {
                if (child.hasElement() && child.getElement().getName().equals("application")
                    && attribute(child.getElement(), "debuggable").equals("true")) {
                    throw new IllegalStateException("Bundle is debuggable");
                }
            }
            for (String abi : new String[] {"arm64-v8a", "armeabi-v7a", "x86_64"}) {
                if (zip.getEntry("base/lib/" + abi + "/libapp.so") == null) {
                    throw new IllegalStateException("Missing Flutter library for " + abi);
                }
            }
            System.out.println("Application ID: " + appId);
            System.out.println("Version code: " + code);
            System.out.println("Version name: " + version);
            System.out.println("Release manifest and three Android architectures verified");
            verifyNativeAlignment(zip);
        }
        if (args.length == 3) verifySignature(args[0], args[2]);
    }
}
