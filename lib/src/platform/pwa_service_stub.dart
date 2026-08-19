import 'dart:async';

Stream<bool> get installAvailable => const Stream.empty();
bool get isAvailable => false;

void init() {}
bool isInstalled() => false;
Future<bool> promptInstall() async => false;
