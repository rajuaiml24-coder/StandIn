import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/attendance.dart';

class FirestoreUserRemote {
  FirestoreUserRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> createUserProfile(UserProfile profile) =>
      _firestore.collection('users').doc(profile.uid).set({
        'displayName': profile.displayName,
        'role': profile.role.name,
        'mobile': profile.mobile,
        'activeFollowId': profile.activeFollowId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateActiveFollow(String uid, String followId) =>
      _firestore.collection('users').doc(uid).update({
        'activeFollowId': followId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<void> claimUsername(String username, String uid) =>
      _firestore.collection('usernames').doc(username.toLowerCase()).set({
        'uid': uid,
      });

  Future<void> putFollow(String uid, Follow follow) =>
      _firestore.collection('users').doc(uid).collection('follows').doc(follow.id).set({
        'organizationId': follow.organizationId,
        'scopeId': follow.scopeId,
        'personalTargetPercent': follow.personalTargetPercent,
        'status': follow.status,
        'followedAt': Timestamp.fromDate(follow.followedAt),
      });

  Stream<UserProfile?> watchProfile(String uid) =>
      _firestore.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        return UserProfile(
          uid: doc.id,
          displayName: data['displayName'] as String,
          role: AppRole.values.byName(data['role'] as String),
          mobile: data['mobile'] as String?,
          activeFollowId: data['activeFollowId'] as String?,
        );
      });
}
