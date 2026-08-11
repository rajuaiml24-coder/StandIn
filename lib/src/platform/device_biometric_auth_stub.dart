import 'device_biometric_auth.dart';

DeviceBiometricAuth createDeviceBiometricAuth() => _UnsupportedBiometricAuth();

class _UnsupportedBiometricAuth implements DeviceBiometricAuth {
  @override Future<bool> authenticate() async => false;
  @override Future<bool> isAvailable() async => false;
}
