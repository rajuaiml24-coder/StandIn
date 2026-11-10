import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_attendance_remote.dart';
import '../../domain/attendance.dart';
import 'dart:convert';
import '../../domain/calendar_updates.dart';

class FirestoreUserRemote {
  FirestoreAttendanceRemote get attendanceRemote =>
      FirestoreAttendanceRemote(_firestore);
  FirestoreUserRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<PersonalCalendarState?> watchCalendarState(
          String uid, String followId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('calendarStates')
          .doc(followId)
          .snapshots()
          .map((doc) {
        final payload = doc.data()?['state'] as String?;
        return payload == null
            ? null
            : PersonalCalendarState.fromJson(
                jsonDecode(payload) as Map<String, dynamic>);
      });

  Future<PersonalCalendarState?> getCalendarState(
      String uid, String followId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarStates')
        .doc(followId)
        .get();
    final payload = doc.data()?['state'] as String?;
    return payload == null
        ? null
        : PersonalCalendarState.fromJson(
            jsonDecode(payload) as Map<String, dynamic>);
  }

  Future<PersonalCalendarState> putCalendarState(String uid, String followId,
          PersonalCalendarState? base, PersonalCalendarState next) =>
      _firestore.runTransaction((tx) async {
        final ref = _firestore
            .collection('users')
            .doc(uid)
            .collection('calendarStates')
            .doc(followId);
        final doc = await tx.get(ref);
        final payload = doc.data()?['state'] as String?;
        final remote = payload == null
            ? null
            : PersonalCalendarState.fromJson(
                jsonDecode(payload) as Map<String, dynamic>);
        final merged = PersonalCalendarState.merge(base, next, remote);
        tx.set(ref, {
          'organizationId': merged.baseline.organizationId,
          'scopeId': merged.baseline.scopeId,
          'state': jsonEncode(merged.toJson()),
          if (merged.policy != null) 'ruleSchema': merged.ruleSchema,
          'updatedAt': FieldValue.serverTimestamp()
        });
        return merged;
      });

  Future<void> createUserProfile(UserProfile profile) =>
      _firestore.runTransaction((transaction) async {
        final reference = _firestore.collection('users').doc(profile.uid);
        final existing = await transaction.get(reference);
        final fields = <String, dynamic>{
          'displayName': profile.displayName,
          'mobile': profile.mobile,
          'registrationNumber': profile.registrationNumber,
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
    final doc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<void> claimUsername(String username, String uid) =>
      _firestore.runTransaction((transaction) async {
        final reference =
            _firestore.collection('usernames').doc(username.toLowerCase());
        final existing = await transaction.get(reference);
        if (existing.exists) {
          if (existing.data()?['uid'] == uid) return;
          throw StateError(
              'That username is already taken. Please choose another.');
        }
        transaction.set(reference, {'uid': uid});
      });

  Future<void> putFollow(String uid, Follow follow) =>
      _firestore.runTransaction((transaction) async {
        final reference = _firestore
            .collection('users')
            .doc(uid)
            .collection('follows')
            .doc(follow.id);
        final previous = await transaction.get(reference);
        if (previous.exists &&
            (previous.data()?['organizationId'] != follow.organizationId ||
                previous.data()?['scopeId'] != follow.scopeId)) {
          throw StateError('A follow cannot be moved to a different group');
        }
        DocumentReference<Map<String, dynamic>>? scopeReference;
        DocumentReference<Map<String, dynamic>>? followerReference;
        DocumentSnapshot<Map<String, dynamic>>? scope;
        DocumentSnapshot<Map<String, dynamic>>? follower;
        DocumentReference<Map<String, dynamic>>? organizationReference;
        DocumentReference<Map<String, dynamic>>? membershipReference;
        DocumentSnapshot<Map<String, dynamic>>? organization;
        DocumentSnapshot<Map<String, dynamic>>? membership;
        if (follow.isPersonalCalculation) {
          if (follow.organizationId != Follow.personalOrganizationId(uid) ||
              follow.scopeId != 'global') {
            throw StateError('This calculation belongs to another account');
          }
        } else if (follow.status == 'active') {
          organizationReference =
              _firestore.collection('organizations').doc(follow.organizationId);
          membershipReference =
              organizationReference.collection('members').doc(uid);
          organization = await transaction.get(organizationReference);
          membership = await transaction.get(membershipReference);
          if (!organization.exists) {
            throw StateError('This organization no longer exists');
          }
        }
        if (!follow.isPersonalCalculation && follow.scopeId != 'global') {
          scopeReference = _firestore
              .collection('organizations')
              .doc(follow.organizationId)
              .collection('scopes')
              .doc(follow.scopeId);
          followerReference = scopeReference.collection('followers').doc(uid);
          scope = await transaction.get(scopeReference);
          follower = await transaction.get(followerReference);
          if (!scope.exists) throw StateError('This group no longer exists');
          if (follow.status == 'active' &&
              scope.data()?['isArchived'] == true) {
            throw StateError('This group has been archived');
          }
        }
        // The organization join, exact-group ledger and follow are accepted together.
        if (membershipReference != null && !membership!.exists) {
          transaction.set(membershipReference, {
            'status': 'follower',
            'joinedAt': Timestamp.fromDate(follow.followedAt),
          });
          transaction.update(organizationReference!, {
            'followerCount':
                ((organization!.data()?['followerCount'] as num?)?.toInt() ??
                        0) +
                    1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(reference, {
          'organizationId': follow.organizationId,
          'scopeId': follow.scopeId,
          'personalTargetPercent': follow.personalTargetPercent,
          'status': follow.status,
          'followedAt': Timestamp.fromDate(follow.followedAt),
          'personalBasis': follow.personalBasis?.name,
          'personalEvaluationPeriod': follow.personalEvaluationPeriod?.name,
          'personalFullUnit': follow.personalFullUnit,
          'personalHalfUnit': follow.personalHalfUnit,
          'personalStartDate': follow.personalStartDate != null
              ? Timestamp.fromDate(follow.personalStartDate!)
              : null,
          'personalEndDate': follow.personalEndDate != null
              ? Timestamp.fromDate(follow.personalEndDate!)
              : null,
          'personalWeeklyOffs': follow.personalWeeklyOffs,
          'personalOffSaturdays': follow.personalOffSaturdays,
          'personalHolidays': follow.personalHolidays,
          'isPersonalCalendarConfigured': follow.isPersonalCalendarConfigured,
        });
        if (scopeReference != null && followerReference != null) {
          final count = (scope!.data()?['followerCount'] as num?)?.toInt() ?? 0;
          if (follow.status == 'active' && !follower!.exists) {
            transaction.set(followerReference, {'followId': follow.id});
            transaction.update(scopeReference, {
              'followerCount': count + 1,
              'updatedAt': FieldValue.serverTimestamp()
            });
          } else if (follow.status != 'active' && follower!.exists) {
            if (follower.data()?['followId'] != follow.id) {
              throw StateError('A different follow is active for this group');
            }
            transaction.delete(followerReference);
            transaction.update(scopeReference, {
              'followerCount': count > 0 ? count - 1 : 0,
              'updatedAt': FieldValue.serverTimestamp()
            });
          } else if (follow.status == 'active' &&
              follower!.data()?['followId'] != follow.id) {
            throw StateError('You already follow this group');
          }
        }
      });

  Future<Follow?> getFollow(String uid, String followId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('follows')
        .doc(followId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Follow(
      id: doc.id,
      organizationId: data['organizationId'] as String,
      scopeId: data['scopeId'] as String,
      personalTargetPercent:
          (data['personalTargetPercent'] as num?)?.toDouble(),
      status: data['status'] as String,
      followedAt: (data['followedAt'] as Timestamp).toDate(),
      personalBasis: data['personalBasis'] != null
          ? CalculationBasis.values.byName(data['personalBasis'] as String)
          : null,
      personalEvaluationPeriod: data['personalEvaluationPeriod'] != null
          ? EvaluationPeriod.values
              .byName(data['personalEvaluationPeriod'] as String)
          : null,
      personalFullUnit: (data['personalFullUnit'] as num?)?.toDouble(),
      personalHalfUnit: (data['personalHalfUnit'] as num?)?.toDouble(),
      personalStartDate: (data['personalStartDate'] as Timestamp?)?.toDate(),
      personalEndDate: (data['personalEndDate'] as Timestamp?)?.toDate(),
      personalWeeklyOffs: data['personalWeeklyOffs'] as String?,
      personalOffSaturdays: data['personalOffSaturdays'] as String?,
      personalHolidays: data['personalHolidays'] as String?,
      isPersonalCalendarConfigured:
          data['isPersonalCalendarConfigured'] as bool? ?? false,
    );
  }

  Future<List<Follow>> getFollows(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('follows')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Follow(
        id: doc.id,
        organizationId: data['organizationId'] as String,
        scopeId: data['scopeId'] as String,
        personalTargetPercent:
            (data['personalTargetPercent'] as num?)?.toDouble(),
        status: data['status'] as String,
        followedAt: (data['followedAt'] as Timestamp).toDate(),
        personalBasis: data['personalBasis'] != null
            ? CalculationBasis.values.byName(data['personalBasis'] as String)
            : null,
        personalEvaluationPeriod: data['personalEvaluationPeriod'] != null
            ? EvaluationPeriod.values
                .byName(data['personalEvaluationPeriod'] as String)
            : null,
        personalFullUnit: (data['personalFullUnit'] as num?)?.toDouble(),
        personalHalfUnit: (data['personalHalfUnit'] as num?)?.toDouble(),
        personalStartDate: (data['personalStartDate'] as Timestamp?)?.toDate(),
        personalEndDate: (data['personalEndDate'] as Timestamp?)?.toDate(),
        personalWeeklyOffs: data['personalWeeklyOffs'] as String?,
        personalOffSaturdays: data['personalOffSaturdays'] as String?,
        personalHolidays: data['personalHolidays'] as String?,
        isPersonalCalendarConfigured:
            data['isPersonalCalendarConfigured'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> deleteProfile(String uid) async {
    // 1. Delete follows subcollection
    final follows = await _firestore
        .collection('users')
        .doc(uid)
        .collection('follows')
        .get();
    final usernameDoc = await _firestore
        .collection('usernames')
        .where('uid', isEqualTo: uid)
        .get();
    final calendars = await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarStates')
        .get();
    final references = [
      ...calendars.docs.map((doc) => doc.reference),
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
          registrationNumber: data['registrationNumber'] as String?,
          activeFollowId: data['activeFollowId'] as String?,
        );
      });
}
