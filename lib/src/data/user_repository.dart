import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'organization_repository.dart';
import 'remote/firestore_attendance_remote.dart';
import 'remote/firestore_user_remote.dart';

class UserRepository {
  UserRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreUserRemote _remote;

  Future<UserProfile?> getProfile(String uid) async {
    final row = await _database.getUserProfile(uid);
    if (row != null) {
      return _toDomain(row);
    }
    return null;
  }

  Stream<UserProfile?> watchProfile(String uid) =>
      _database.watchUserProfile(uid).map((row) => row == null ? null : _toDomain(row));

  UserProfile _toDomain(UserProfileRow row) => UserProfile(
        uid: row.uid,
        displayName: row.displayName,
        role: AppRole.values.byName(row.role),
        mobile: row.mobile,
        activeFollowId: row.activeFollowId,
      );

  Future<bool> syncProfile(String uid) async {
    final profile = await _remote.watchProfile(uid).first;
    if (profile != null) {
      await _database.upsertUserProfile(UserProfileRowsCompanion.insert(
        uid: profile.uid,
        displayName: profile.displayName,
        role: profile.role.name,
        mobile: Value(profile.mobile),
        activeFollowId: Value(profile.activeFollowId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      return true;
    }
    return false;
  }

  Future<void> createProfile(UserProfile profile) async {
    await _database.transaction(() async {
      await _database.upsertUserProfile(UserProfileRowsCompanion.insert(
        uid: profile.uid,
        displayName: profile.displayName,
        role: profile.role.name,
        mobile: Value(profile.mobile),
        activeFollowId: Value(profile.activeFollowId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'profile:${profile.uid}',
        operation: 'createUserProfile',
        entityId: profile.uid,
        payload: jsonEncode({
          'uid': profile.uid,
          'displayName': profile.displayName,
          'role': profile.role.name,
          'mobile': profile.mobile,
          'activeFollowId': profile.activeFollowId,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<bool> checkUsernameAvailable(String username) => _remote.isUsernameAvailable(username);

  Future<void> claimUsername(String username, String uid) => _remote.claimUsername(username, uid);

  Future<void> saveFollow(String uid, Follow follow) async {
    await _database.transaction(() async {
      await _database.upsertFollow(FollowRowsCompanion.insert(
        id: follow.id,
        organizationId: follow.organizationId,
        scopeId: follow.scopeId,
        status: follow.status,
        followedAt: follow.followedAt,
        personalTargetPercent: Value(follow.personalTargetPercent),
        personalBasis: Value(follow.personalBasis?.name),
        personalEvaluationPeriod: Value(follow.personalEvaluationPeriod?.name),
        personalFullUnit: Value(follow.personalFullUnit),
        personalHalfUnit: Value(follow.personalHalfUnit),
        personalStartDate: Value(follow.personalStartDate),
        personalEndDate: Value(follow.personalEndDate),
        personalWeeklyOffs: Value(follow.personalWeeklyOffs),
        personalOffSaturdays: Value(follow.personalOffSaturdays),
        personalHolidays: Value(follow.personalHolidays),
        isPersonalCalendarConfigured: Value(follow.isPersonalCalendarConfigured),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'follow:${follow.id}',
        operation: 'putFollow',
        entityId: follow.id,
        payload: jsonEncode({
          'uid': uid,
          'id': follow.id,
          'organizationId': follow.organizationId,
          'scopeId': follow.scopeId,
          'personalTargetPercent': follow.personalTargetPercent,
          'status': follow.status,
          'followedAt': follow.followedAt.toIso8601String(),
          'personalBasis': follow.personalBasis?.name,
          'personalEvaluationPeriod': follow.personalEvaluationPeriod?.name,
          'personalFullUnit': follow.personalFullUnit,
          'personalHalfUnit': follow.personalHalfUnit,
          'personalStartDate': follow.personalStartDate?.toIso8601String(),
          'personalEndDate': follow.personalEndDate?.toIso8601String(),
          'personalWeeklyOffs': follow.personalWeeklyOffs,
          'personalOffSaturdays': follow.personalOffSaturdays,
          'personalHolidays': follow.personalHolidays,
          'isPersonalCalendarConfigured': follow.isPersonalCalendarConfigured,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> purgeRemoteData(String uid, OrganizationRepository orgRepo, FirestoreAttendanceRemote attendanceRemote) async {
    // 1. Fetch follows to find memberships
    final follows = await _remote.getFollows(uid);
    
    // 2. Delete memberships in organizations
    for (var follow in follows) {
      try {
        await orgRepo.removeMembership(follow.organizationId, uid);
      } catch (e) {
        // Log and continue
      }
    }

    // 3. Delete attendance
    await attendanceRemote.deleteAllAttendance(uid);

    // 4. Delete profile and username
    await _remote.deleteProfile(uid);
  }
}
