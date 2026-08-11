import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const StandInApp());
}
