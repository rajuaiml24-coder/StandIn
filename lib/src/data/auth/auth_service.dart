import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication foundation: local PIN is device-only; Firebase providers can be linked later.
class AuthService {
  AuthService(this._auth, this._secureStorage);
  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;

  Stream<User?> get userChanges => _auth.userChanges();
  String? get uid => _auth.currentUser?.uid;
  Future<UserCredential> createEmailAccount(String email, String password) => _auth.createUserWithEmailAndPassword(email: email, password: password);
  Future<UserCredential> signInWithEmail(String email, String password) => _auth.signInWithEmailAndPassword(email: email, password: password);
  Future<void> signOut() => _auth.signOut();

  Future<void> savePinVerifier(String verifier) => _secureStorage.write(key: 'standin.pin.verifier', value: verifier);
  Future<String?> readPinVerifier() => _secureStorage.read(key: 'standin.pin.verifier');
}
