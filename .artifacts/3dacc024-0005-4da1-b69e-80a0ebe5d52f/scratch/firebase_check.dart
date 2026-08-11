import 'package:firebase_core/firebase_core.dart';
import 'package:standin/firebase_options.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('SUCCESS: Firebase initialized');
  } catch (e) {
    print('FAIL: Firebase initialization failed: $e');
  }
}
