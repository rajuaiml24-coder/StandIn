import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/attendance.dart';

class FirestoreUserRemote {
  FirestoreUserRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> createUserProfile(UserProfile profile) => _firestore.runTransaction((transaction) async {
    final reference = _firestore.collection('users').doc(profile.uid);
    final existing = await transaction.get(reference);
    final fields = <String, dynamic>{
        'displayName': profile.displayName,
        'mobile': profile.mobile,
        'activeFollowId': profile.activeFollowId,
        'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing.exists) {
      transaction.update(reference, fields);
    } else {
      transaction.set(reference, {
        ...fields,
        'role': profile.role.name,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
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

  Future<void> claimUsername(String username, String uid) => _firestore.runTransaction((transaction) async {
    final reference = _firestore.collection('usernames').doc(username.toLowerCase());
    final existing = await transaction.get(reference);
    if (existing.exists) {
      if (existing.data()?['uid'] == uid) return;
      throw StateError('That username is already taken. Please choose another.');
    }
    transaction.set(reference, {'uid': uid});
  });

  Future<void> putFollow(String uid, Follow follow) =>
      _firestore.collection('users').doc(uid).collection('follows').doc(follow.id).set({
        'organizationId': follow.organizationId,
        'scopeId': follow.scopeId,
        'personalTargetPercent': follow.personalTargetPercent,
        'status': follow.status,
        'followedAt': Timestamp.fromDate(follow.followedAt),
        'personalBasis': follow.personalBasis?.name,
        'personalEvaluationPeriod': follow.personalEvaluationPeriod?.name,
        'personalFullUnit': follow.personalFullUnit,
        'personalHalfUnit': follow.personalHalfUnit,
        'personalStartDate': follow.personalStartDate != null ? Timestamp.fromDate(follow.personalStartDate!) : null,
        'personalEndDate': follow.personalEndDate != null ? Timestamp.fromDate(follow.personalEndDate!) : null,
        'personalWeeklyOffs': follow.personalWeeklyOffs,
        'personalOffSaturdays': follow.personalOffSaturdays,
        'personalHolidays': follow.personalHolidays,
        'isPersonalCalendarConfigured': follow.isPersonalCalendarConfigured,
      });

  Future<Follow?> getFollow(String uid, String followId) async {
    final doc = await _firestore.collection('users').doc(uid).collection('follows').doc(followId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Follow(
      id: doc.id,
      organizationId: data['organizationId'] as String,
      scopeId: data['scopeId'] as String,
      personalTargetPercent: (data['personalTargetPercent'] as num?)?.toDouble(),
      status: data['status'] as String,
      followedAt: (data['followedAt'] as Timestamp).toDate(),
      personalBasis: data['personalBasis'] != null ? CalculationBasis.values.byName(data['personalBasis'] as String) : null,
      personalEvaluationPeriod: data['personalEvaluationPeriod'] != null ? EvaluationPeriod.values.byName(data['personalEvaluationPeriod'] as String) : null,
      personalFullUnit: (data['personalFullUnit'] as num?)?.toDouble(),
      personalHalfUnit: (data['personalHalfUnit'] as num?)?.toDouble(),
      personalStartDate: (data['personalStartDate'] as Timestamp?)?.toDate(),
      personalEndDate: (data['personalEndDate'] as Timestamp?)?.toDate(),
      personalWeeklyOffs: data['personalWeeklyOffs'] as String?,
      personalOffSaturdays: data['personalOffSaturdays'] as String?,
      personalHolidays: data['personalHolidays'] as String?,
      isPersonalCalendarConfigured: data['isPersonalCalendarConfigured'] as bool? ?? false,
    );
  }

  Future<List<Follow>> getFollows(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('follows').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Follow(
        id: doc.id,
        organizationId: data['organizationId'] as String,
        scopeId: data['scopeId'] as String,
        personalTargetPercent: (data['personalTargetPercent'] as num?)?.toDouble(),
        status: data['status'] as String,
        followedAt: (data['followedAt'] as Timestamp).toDate(),
        personalBasis: data['personalBasis'] != null ? CalculationBasis.values.byName(data['personalBasis'] as String) : null,
        personalEvaluationPeriod: data['personalEvaluationPeriod'] != null ? EvaluationPeriod.values.byName(data['personalEvaluationPeriod'] as String) : null,
        personalFullUnit: (data['personalFullUnit'] as num?)?.toDouble(),
        personalHalfUnit: (data['personalHalfUnit'] as num?)?.toDouble(),
        personalStartDate: (data['personalStartDate'] as Timestamp?)?.toDate(),
        personalEndDate: (data['personalEndDate'] as Timestamp?)?.toDate(),
        personalWeeklyOffs: data['personalWeeklyOffs'] as String?,
        personalOffSaturdays: data['personalOffSaturdays'] as String?,
        personalHolidays: data['personalHolidays'] as String?,
        isPersonalCalendarConfigured: data['isPersonalCalendarConfigured'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> deleteProfile(String uid) async {
    
    // 1. Delete follows subcollection
    final follows = await _firestore.collection('users').doc(uid).collection('follows').get();
    final usernameDoc = await _firestore.collection('usernames').where('uid', isEqualTo: uid).get();
    final references = [
      ...follows.docs.map((doc) => doc.reference),
      ...usernameDoc.docs.map((doc) => doc.reference),
    ];
    for (var offset = 0; offset < references.length; offset += 450) {
      final batch = _firestore.batch();
      for (final reference in references.skip(offset).take(450)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
    await _firestore.collection('users').doc(uid).delete();
  }

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
