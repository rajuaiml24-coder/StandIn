import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication foundation using Firebase and third-party providers.
class AuthService {
  AuthService(this._auth, this._secureStorage, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get userChanges => _auth.userChanges();
  String? get uid => _auth.currentUser?.uid;

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Link an additional credential (e.g. Phone, Apple) to the existing account.
  Future<UserCredential?> linkCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.linkWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Verification/Biometric helpers (retained for future use)
  Future<void> saveLocalVerifier(String verifier) => _secureStorage.write(key: 'standin.auth.verifier', value: verifier);
  Future<String?> readLocalVerifier() => _secureStorage.read(key: 'standin.auth.verifier');
}
