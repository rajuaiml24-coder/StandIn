import 'pwa_install_hint_stub.dart'
    if (dart.library.html) 'pwa_install_hint_web.dart' as platform;

class PwaInstallHint {
  static Future<String?> message() => platform.installMessage();
  static Future<void> dismiss() => platform.dismissInstallHint();
}
