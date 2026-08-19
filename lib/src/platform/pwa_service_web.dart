// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:js' as js;

final _installAvailableController = StreamController<bool>.broadcast();
Stream<bool> get installAvailable => _installAvailableController.stream;

bool _isAvailable = false;
bool get isAvailable => _isAvailable;

void init() {
  js.context['dispatchAppEvent'] = (String type, dynamic value) {
    if (type == 'pwa_install_available') {
      _isAvailable = value == true;
      _installAvailableController.add(_isAvailable);
    }
  };
}

bool isInstalled() {
  if (!js.context.hasProperty('isPwaInstalled')) return false;
  final result = js.context.callMethod('isPwaInstalled');
  return result == true;
}

Future<bool> promptInstall() async {
  if (!js.context.hasProperty('triggerPwaInstall')) return false;
  final result = await js.context.callMethod('triggerPwaInstall');
  return result == true;
}
