import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';

/// Initializes only the Firebase project configured in the host app.
/// No project ID, API key, or credentials are embedded in source control.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult> initialize() async {
    if (Firebase.apps.isNotEmpty) return const FirebaseBootstrapResult.ready();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrapResult.ready();
    } on FirebaseException catch (error) {
      return FirebaseBootstrapResult.unavailable(error.code);
    } catch (_) {
      return const FirebaseBootstrapResult.unavailable('unknown');
    }
  }
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult.ready() : isReady = true, reason = null;
  const FirebaseBootstrapResult.unavailable(this.reason) : isReady = false;
  final bool isReady;
  final String? reason;
}
