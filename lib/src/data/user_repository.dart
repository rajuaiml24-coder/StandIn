import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import '../domain/shared_rules.dart';
import '../domain/calendar_updates.dart';
import 'local/standin_database.dart';
import 'organization_repository.dart';
import 'remote/firestore_attendance_remote.dart';
import 'remote/firestore_user_remote.dart';
import 'calendar_repository.dart';

class UserRepository {
  UserRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreUserRemote _remote;
  StandInDatabase get database => _database;
  FirestoreUserRemote get remote => _remote;

  Future<void> initializeCalendar(
          String uid, String followId, AttendanceCalendar calendar,
          {int reviewedVersion = 0}) =>
      CalendarRepository(_database, _remote, uid: uid, followId: followId)
          .ensure(calendar, reviewedVersion: reviewedVersion);

  Future<UserProfile?> getProfile(String uid) async {
    final row = await _database.getUserProfile(uid);
    if (row != null) {
      return _toDomain(row);
    }
    return null;
  }

  Stream<UserProfile?> watchProfile(String uid) => _database
      .watchUserProfile(uid)
      .map((row) => row == null ? null : _toDomain(row));

  UserProfile _toDomain(UserProfileRow row) => UserProfile(
        uid: row.uid,
        displayName: row.displayName,
        role: AppRole.values.byName(row.role),
        mobile: row.mobile,
        registrationNumber: row.registrationNumber,
        activeFollowId: row.activeFollowId,
      );

  Future<bool> syncProfile(String uid) async {
    final local = await _database.getUserProfile(uid);
    if (local != null && await _database.getOperation('profile:$uid') != null) {
      return true;
    }
    UserProfile? profile;
    try {
      profile = await _remote.watchProfile(uid).first;
    } catch (_) {
      if (local != null) return true;
      rethrow;
    }
    if (profile != null) {
      await _database.upsertUserProfile(UserProfileRowsCompanion.insert(
        uid: profile.uid,
        displayName: profile.displayName,
        role: profile.role.name,
        mobile: Value(profile.mobile),
        registrationNumber: Value(profile.registrationNumber),
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
        registrationNumber: Value(profile.registrationNumber),
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
          'registrationNumber': profile.registrationNumber,
          'activeFollowId': profile.activeFollowId,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<bool> checkUsernameAvailable(String username) =>
      _remote.isUsernameAvailable(username);

  Future<void> claimUsername(String username, String uid) =>
      _remote.claimUsername(username, uid);

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
        isPersonalCalendarConfigured:
            Value(follow.isPersonalCalendarConfigured),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'follow:${follow.id}',
        operation: 'putFollow',
        entityId: follow.id,
        attemptCount: const Value(0),
        lastError: const Value(null),
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

  static Follow followFromRow(FollowRow row) => Follow(
        id: row.id,
        organizationId: row.organizationId,
        scopeId: row.scopeId,
        status: row.status,
        followedAt: row.followedAt,
        personalTargetPercent: row.personalTargetPercent,
        personalBasis: row.personalBasis == null
            ? null
            : CalculationBasis.values.byName(row.personalBasis!),
        personalEvaluationPeriod: row.personalEvaluationPeriod == null
            ? null
            : EvaluationPeriod.values.byName(row.personalEvaluationPeriod!),
        personalFullUnit: row.personalFullUnit,
        personalHalfUnit: row.personalHalfUnit,
        personalStartDate: row.personalStartDate,
        personalEndDate: row.personalEndDate,
        personalWeeklyOffs: row.personalWeeklyOffs,
        personalOffSaturdays: row.personalOffSaturdays,
        personalHolidays: row.personalHolidays,
        isPersonalCalendarConfigured: row.isPersonalCalendarConfigured,
      );

  Future<void> syncFollows(String uid) async {
    final follows = await _remote.getFollows(uid);
    for (final follow in follows) {
      if (await _database.getOperation('follow:${follow.id}') != null) continue;
      await cacheFollow(follow);
    }
  }

  Future<void> cacheFollow(Follow follow) =>
      _database.upsertFollow(FollowRowsCompanion.insert(
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
        isPersonalCalendarConfigured:
            Value(follow.isPersonalCalendarConfigured),
      ));

  Future<Follow> followScope(String uid, Organization org, String scopeId,
      OrganizationRepository orgRepo,
      {AttendanceCalendar? acceptedCalendar,
      int reviewedVersion = 0,
      Follow? personalSettings,
      AttendancePolicy? acceptedPolicy,
      RuleRevision? initialRuleRevision}) async {
    final profile = await getProfile(uid);
    if (profile == null) throw StateError('Complete your profile first');
    final existing = await (_database.select(_database.followRows)
          ..where((row) =>
              row.organizationId.equals(org.id) & row.scopeId.equals(scopeId))
          ..orderBy([(row) => OrderingTerm.desc(row.followedAt)])
          ..limit(1))
        .getSingleOrNull();
    final follow = personalSettings ??
        (existing == null
            ? Follow(
                id: Scope.generateId(org.id, 'follow', scopeId),
                organizationId: org.id,
                scopeId: scopeId,
                status: 'active',
                followedAt: DateTime.now(),
              )
            : followFromRow(existing).copyWith(status: 'active'));
    await _database.transaction(() async {
      await orgRepo.saveOrganizationMetadata(org);
      // Membership and counts are created remotely by the same follow transaction.
      await _database.upsertMembership(MembershipRowsCompanion.insert(
          uid: uid,
          organizationId: org.id,
          status: 'follower',
          joinedAt: DateTime.now()));
      await saveFollow(uid, follow);
      if (acceptedCalendar != null) {
        final calendars = CalendarRepository(_database, _remote,
            uid: uid, followId: follow.id);
        await calendars.ensure(acceptedCalendar,
            reviewedVersion: reviewedVersion,
            policy: existing == null && initialRuleRevision == null
                ? acceptedPolicy
                : null);
        if (existing == null && initialRuleRevision != null) {
          await calendars.initializePublishedRules(initialRuleRevision);
        }
      }
      await createProfile(UserProfile(
          uid: uid,
          displayName: profile.displayName,
          role: profile.role,
          mobile: profile.mobile,
          registrationNumber: profile.registrationNumber,
          activeFollowId: follow.id));
    });
    return follow;
  }

  Future<void> activateFollow(String uid, String followId) async {
    final row = await _database.getFollow(followId);
    final profile = await getProfile(uid);
    if (row == null || row.status != 'active' || profile == null) {
      throw StateError('Follow is unavailable');
    }
    await createProfile(UserProfile(
        uid: uid,
        displayName: profile.displayName,
        role: profile.role,
        mobile: profile.mobile,
        registrationNumber: profile.registrationNumber,
        activeFollowId: followId));
  }

  Future<void> updateProfileDetails(String uid, String name, String? mobile,
      {String? registrationNumber}) async {
    final profile = await getProfile(uid);
    if (profile == null) throw StateError('Profile is unavailable');
    final displayName = name.trim();
    if (displayName.isEmpty || displayName.length > 80) {
      throw StateError('Enter a name between 1 and 80 characters');
    }
    if ((registrationNumber?.trim().length ?? 0) > 80) {
      throw ArgumentError('Registration number must be at most 80 characters');
    }
    await createProfile(UserProfile(
        uid: uid,
        displayName: displayName,
        mobile: mobile == null || mobile.trim().isEmpty ? null : mobile.trim(),
        registrationNumber:
            registrationNumber == null || registrationNumber.trim().isEmpty
                ? null
                : registrationNumber.trim(),
        role: profile.role,
        activeFollowId: profile.activeFollowId));
  }

  Future<void> usePersonalCalculation(
      String uid, Follow calculation, OrganizationRepository orgRepo,
      {AttendanceCalendar? calendar,
      AttendancePolicy? policy,
      PersonalCalendarState? presented}) async {
    final profile = await getProfile(uid);
    if (profile == null ||
        calculation.organizationId != Follow.personalOrganizationId(uid) ||
        calculation.scopeId != 'global') {
      throw StateError('Calculation is unavailable');
    }
    await _database.transaction(() async {
      await orgRepo.saveOrganizationMetadata(Organization(
          id: calculation.organizationId,
          name: 'Custom calculation',
          type: profile.role == AppRole.employee
              ? OrganizationType.company
              : OrganizationType.college));
      final calendars = CalendarRepository(_database, _remote,
          uid: uid, followId: calculation.id);
      final previous = await calendars.read();
      if (presented != null &&
          (previous == null ||
              !sameCalendarValue(previous.toJson(), presented.toJson()))) {
        throw StateError(
            'Your rules changed. Reopen the editor before saving.');
      }
      if (previous != null && calendar != null) {
        await calendars.setSettings(calendar, policy: policy);
      }
      await saveFollow(uid, calculation);
      if (calendar != null) {
        await calendars.ensure(calendar, policy: policy);
      }
      await activateFollow(uid, calculation.id);
    });
  }

  Future<void> prepareFollowContext(
      String uid, String followId, OrganizationRepository orgRepo) async {
    try {
      await orgRepo.syncFollowContext(uid, followId, userRemote: _remote);
    } catch (_) {
      final follow = await _database.getFollow(followId);
      if (follow == null ||
          await _database.getOrganization(follow.organizationId) == null) {
        rethrow;
      }
    }
  }

  Future<void> unfollow(String uid, Follow follow) async {
    await _database.transaction(() async {
      await saveFollow(uid, follow.copyWith(status: 'archived'));
      final remaining = await (_database.select(_database.followRows)
            ..where((row) => row.status.equals('active')))
          .get();
      if (!follow.isPersonalCalculation &&
          !remaining
              .any((row) => row.organizationId == follow.organizationId)) {
        await (_database.delete(_database.membershipRows)
              ..where((row) =>
                  row.uid.equals(uid) &
                  row.organizationId.equals(follow.organizationId)))
            .go();
        await _database.enqueue(SyncQueueRowsCompanion.insert(
            id: 'membership:$uid:${follow.organizationId}',
            operation: 'leaveOrganizationAtomic',
            entityId: '$uid:${follow.organizationId}',
            payload: jsonEncode({'organizationId': follow.organizationId}),
            nextAttemptAt: DateTime.now(),
            createdAt: DateTime.now()));
      }
      final profile = await getProfile(uid);
      if (profile != null && profile.activeFollowId == follow.id) {
        await createProfile(UserProfile(
            uid: uid,
            displayName: profile.displayName,
            role: profile.role,
            mobile: profile.mobile,
            registrationNumber: profile.registrationNumber,
            activeFollowId: remaining.isEmpty ? null : remaining.first.id));
      }
    });
  }

  Future<void> purgeRemoteData(String uid, OrganizationRepository orgRepo,
      FirestoreAttendanceRemote attendanceRemote) async {
    // 1. Fetch follows to find memberships
    final follows = await _remote.getFollows(uid);
    for (final follow in follows.where(
        (follow) => follow.status == 'active' && follow.scopeId != 'global')) {
      await _remote.putFollow(uid, follow.copyWith(status: 'archived'));
    }
    final localFollows = await _database.select(_database.followRows).get();
    final localMemberships = await (_database.select(_database.membershipRows)
          ..where((row) => row.uid.equals(uid)))
        .get();
    final organizations = {
      ...follows.map((follow) => follow.organizationId),
      ...localFollows.map((follow) => follow.organizationId),
      ...localMemberships.map((membership) => membership.organizationId),
    };

    // 2. Delete memberships in organizations
    for (final orgId
        in organizations.where((id) => !Follow.isPersonalOrganization(id))) {
      await orgRepo.removeMembership(orgId, uid);
    }

    // 3. Delete attendance
    await attendanceRemote.deleteAllAttendance(uid);

    // 4. Delete profile and username
    await _remote.deleteProfile(uid);
  }

  Future<void> clearLocalPersonalData() => _database.clearPersonalData();
}
