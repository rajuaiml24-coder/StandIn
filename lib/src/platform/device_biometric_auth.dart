import 'device_biometric_auth_stub.dart'
    if (dart.library.io) 'device_biometric_auth_mobile.dart' as platform;

abstract class DeviceBiometricAuth {
  Future<bool> isAvailable();
  Future<bool> authenticate();

  factory DeviceBiometricAuth.create() => platform.createDeviceBiometricAuth();
}
