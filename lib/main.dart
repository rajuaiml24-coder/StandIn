import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/firebase/firebase_bootstrap.dart';
import 'src/platform/pwa_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PwaService.instance.init();
  await FirebaseBootstrap.initialize();
  runApp(const StandInApp());
}
