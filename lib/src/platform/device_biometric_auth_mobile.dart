import 'package:local_auth/local_auth.dart';

import 'device_biometric_auth.dart';

DeviceBiometricAuth createDeviceBiometricAuth() => _LocalBiometricAuth();

class _LocalBiometricAuth implements DeviceBiometricAuth {
  final LocalAuthentication _authentication = LocalAuthentication();
  @override Future<bool> isAvailable() async => await _authentication.isDeviceSupported() && await _authentication.canCheckBiometrics;
  @override Future<bool> authenticate() => _authentication.authenticate(localizedReason: 'Unlock your private StandIn attendance data');
}
