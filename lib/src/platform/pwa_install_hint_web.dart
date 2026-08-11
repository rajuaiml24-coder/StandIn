// This is the web-only half of a conditional import.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _dismissedKey = 'standin.pwa-install-hint.dismissed';

Future<String?> installMessage() async {
  if (html.window.localStorage[_dismissedKey] == 'true') return null;
  final agent = html.window.navigator.userAgent.toLowerCase();
  if (agent.contains('iphone') || agent.contains('ipad')) {
    return 'Add StandIn to your Home Screen: tap Share, then Add to Home Screen.';
  }
  if (agent.contains('android')) {
    return 'Install StandIn from your browser menu to use it like an app.';
  }
  return 'Install StandIn from your browser menu for faster access.';
}

Future<void> dismissInstallHint() async {
  html.window.localStorage[_dismissedKey] = 'true';
}
