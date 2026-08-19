import 'dart:async';
import 'pwa_service_stub.dart'
    if (dart.library.js_interop) 'pwa_service_web.dart' as platform;

class PwaService {
  PwaService._();
  static final PwaService instance = PwaService._();

  Stream<bool> get installAvailable => platform.installAvailable;
  bool get isAvailable => platform.isAvailable;

  void init() => platform.init();

  bool isInstalled() => platform.isInstalled();

  Future<bool> promptInstall() => platform.promptInstall();
}
