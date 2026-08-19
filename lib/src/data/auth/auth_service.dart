import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication foundation using Firebase and third-party providers.
class AuthService {
  AuthService(this._auth, this._secureStorage, {GoogleSignIn? googleSignIn, String? clientId})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(clientId: clientId);

  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get userChanges => _auth.userChanges();
  String? get uid => _auth.currentUser?.uid;

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      
      // Check if we need to force account selection (set during explicit logout)
      final needsPicker = await _secureStorage.read(key: 'standin_needs_account_picker');
      if (needsPicker == 'true') {
        provider.setCustomParameters({'prompt': 'select_account'});
        await _secureStorage.delete(key: 'standin_needs_account_picker');
      }

      return _auth.signInWithPopup(provider);
    }

    // On Mobile, use the native google_sign_in plugin
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
  }

  /// Link an additional credential (e.g. Phone, Apple) to the existing account.
  Future<UserCredential?> linkCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.linkWithCredential(credential);
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      await _secureStorage.write(key: 'standin_needs_account_picker', value: 'true');
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Verification/Biometric helpers (retained for future use)
  Future<void> saveLocalVerifier(String verifier) => _secureStorage.write(key: 'standin.auth.verifier', value: verifier);
  Future<String?> readLocalVerifier() => _secureStorage.read(key: 'standin.auth.verifier');
}
