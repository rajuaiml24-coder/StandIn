import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/sync/sync_engine.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/planning.dart';
import 'package:standin/src/domain/policy_engine.dart';

class OnlineConnectivity extends Mock implements Connectivity {}

AttendancePolicy rules(
        {String scope = 'csc', String id = 'p', double target = 75}) =>
    AttendancePolicy(
      id: id,
      organizationId: 'college',
      scopeId: scope,
      version: 1,
      effectiveFrom: DateTime(2000),
      state: PolicyState.community,
      evaluationPeriod: EvaluationPeriod.custom,
      basis: CalculationBasis.days,
      minimumPercent: target,
      fullUnit: 1,
      halfUnit: .5,
      startDate: DateTime(2026, 10, 10),
      endDate: DateTime(2026, 10, 15),
    );

AttendanceCalendar schedule({String scope = 'csc', String id = 'c'}) =>
    AttendanceCalendar(
        id: id,
        organizationId: 'college',
        scopeId: scope,
        version: 1,
        effectiveFrom: DateTime(2000),
        weeklyOffs: [],
        isConfigured: true);

AttendancePlan plan(int day, AttendanceStatus status, double units,
        {AttendancePolicy? policy, AttendanceCalendar? calendar}) =>
    AttendancePlan(
      id: attendanceId(DateTime(2026, 10, day), 'college', 'csc'),
      organizationId: 'college',
      scopeId: 'csc',
      date: DateTime(2026, 10, day),
      status: status,
      units: units,
      policyVersionId: planningPolicyKey(policy ?? rules()),
      calendarVersionId: planningCalendarKey(calendar ?? schedule()),
    );

void main() {
  group('Planning calculations', () {
    const engine = PolicyEngine();
    final record = AttendanceRecord(
        date: DateTime(2026, 10, 10),
        status: AttendanceStatus.full,
        actualUnits: 1,
        expectedUnits: 1);
    final plans = [
      plan(11, AttendanceStatus.full, 1),
      plan(12, AttendanceStatus.half, .5),
      plan(13, AttendanceStatus.absent, 0),
      plan(14, AttendanceStatus.full, 1),
      plan(15, AttendanceStatus.full, 1)
    ];
    test('plans reach the target without changing actual attendance', () {
      final result = engine.summarizePlans(
          rules(), schedule(), [record], plans, DateTime(2026, 10, 10));
      expect(result.confirmedUnits, 1);
      expect(result.plannedUnits, 3.5);
      expect(result.totalExpected, 6);
      expect(result.percent, 75);
      expect(result.meetsTarget, isTrue);
      final actual = engine.summarize(
          rules(), schedule(), [record], DateTime(2026, 10, 10));
      expect(actual.actual, 1);
      expect(actual.percent, 100);
    });
    test('past plans remain unconfirmed and are not credited', () {
      final result = engine.summarizePlans(
          rules(), schedule(), [record], plans, DateTime(2026, 10, 12));
      expect(result.confirmedUnits, 1);
      expect(result.plannedUnits, 2);
      expect(result.unconfirmedCount, 2);
      expect(result.percent, 50);
    });
    test('rule changes exclude stale plans and request review', () {
      final changed = rules()
          .copyWith(fullUnit: 8, halfUnit: 4, basis: CalculationBasis.hours);
      final result = engine.summarizePlans(
          changed, schedule(), [record], plans, DateTime(2026, 10, 10));
      expect(result.plannedUnits, 0);
      expect(result.changedRuleCount, 5);
    });
    test(
        'holidays remove future capacity and duplicate plans do not inflate totals',
        () {
      final cal = schedule().copyWith(
          holidays: [Holiday(date: DateTime(2026, 10, 11), name: 'Holiday')]);
      final result = engine.summarizePlans(
          rules(),
          cal,
          [record],
          [
            plan(12, AttendanceStatus.half, .5, calendar: cal),
            plan(12, AttendanceStatus.half, .5, calendar: cal)
          ],
          DateTime(2026, 10, 10));
      expect(result.totalExpected, 5);
      expect(result.plannedUnits, .5);
    });
    test('future months have a projection while actual month stays not started',
        () {
      final policy =
          rules().copyWith(evaluationPeriod: EvaluationPeriod.monthly);
      final result = engine.summarizePlans(
          policy, schedule(), [], [], DateTime(2026, 9, 1),
          year: 2026, month: 10);
      expect(result.totalExpected, 31);
      expect(result.unconfirmedCount, 0);
      expect(
          engine
              .summarizeMonth(
                  policy, schedule(), [], 2026, 10, DateTime(2026, 9, 1))
              .periodLabel,
          'Not started');
    });
  });

  group('Followers and private planning sync', () {
    late StandInDatabase database;
    late FakeFirebaseFirestore firestore;
    late OrganizationRepository organizations;
    late UserRepository users;
    late FirestoreOrgRemote orgRemote;
    late FirestoreUserRemote userRemote;
    late SyncEngine sync;
    const org = Organization(
        id: 'college',
        name: 'XYZ College',
        type: OrganizationType.college,
        createdBy: 'creator');
    setUp(() async {
      database = StandInDatabase.executor(NativeDatabase.memory());
      firestore = FakeFirebaseFirestore();
      orgRemote = FirestoreOrgRemote(firestore);
      userRemote = FirestoreUserRemote(firestore);
      organizations = OrganizationRepository(database, orgRemote);
      users = UserRepository(database, userRemote);
      final online = OnlineConnectivity();
      when(() => online.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      sync = SyncEngine(database, FirestoreAttendanceRemote(firestore),
          userRemote, orgRemote, organizations,
          uid: 'user', connectivity: online);
      await orgRemote.putOrganization(org, 'creator');
      for (final id in ['csc', 'ece']) {
        await orgRemote.putScope(
            'college',
            Scope(
                id: id,
                organizationId: 'college',
                name: id.toUpperCase(),
                type: 'branch',
                createdBy: 'creator'));
      }
      await users.createProfile(const UserProfile(
          uid: 'user', displayName: 'User', role: AppRole.student));
    });
    tearDown(() async {
      await sync.stop();
      await database.close();
    });

    test(
        'organization counts unique users; group counts unique follows; switching is count neutral',
        () async {
      final first = await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      expect((await orgRemote.getScope('college', 'csc'))!.followerCount, 1);
      final second = await users.followScope('user', org, 'ece', organizations);
      await sync.syncNow();
      await users.activateFollow('user', first.id);
      await sync.syncNow();
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      await users.unfollow('user', first);
      await sync.syncNow();
      expect((await orgRemote.getScope('college', 'csc'))!.followerCount, 0);
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      await users.unfollow('user', second);
      await sync.syncNow();
      expect((await orgRemote.getScope('college', 'ece'))!.followerCount, 0);
      expect((await orgRemote.getOrganization('college'))!.followerCount, 0);
      expect((await users.getProfile('user'))!.activeFollowId, isNull);
      await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      expect((await orgRemote.getScope('college', 'csc'))!.followerCount, 1);
    });
    test(
        'popular groups are sorted and scoped rules do not leak to another branch',
        () async {
      final p = rules().copyWith(id: 'scope-csc-v2');
      final c = schedule(id: 'cal-csc-v2');
      final scope = Scope(
          id: 'csc',
          organizationId: 'college',
          name: 'CSC',
          type: 'branch',
          createdBy: 'creator',
          activePolicyId: p.id,
          activeCalendarId: c.id);
      await organizations.publishScopeRules(scope, p, c);
      await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      final scopes = await organizations.getScopesForParent('college', null);
      expect(scopes.first.id, 'csc');
      expect(scopes.first.followerCount, 1);
      final resolved =
          await organizations.getOfficialPolicyForScope('college', 'csc');
      expect(resolved!.id, p.id);
      expect(resolved.minimumPercent, 75);
      expect(await organizations.getOfficialPolicyForScope('college', 'ece'),
          isNull);
      await expectLater(
          organizations.publishScopeRules(
              Scope(
                  id: 'csc',
                  organizationId: 'college',
                  name: 'CSC',
                  type: 'branch',
                  createdBy: 'other'),
              p,
              c),
          throwsStateError);
    });
    test(
        'failed branch follows never leave an organization membership or count behind',
        () async {
      await firestore
          .doc('organizations/college/scopes/csc')
          .update({'isArchived': true});
      final follow = Follow(
          id: 'failed',
          organizationId: 'college',
          scopeId: 'csc',
          status: 'active',
          followedAt: DateTime.now());
      await expectLater(userRemote.putFollow('user', follow), throwsStateError);
      expect((await orgRemote.getOrganization('college'))!.followerCount, 0);
      expect(
          (await firestore.doc('organizations/college/members/user').get())
              .exists,
          isFalse);
      expect((await firestore.doc('users/user/follows/failed').get()).exists,
          isFalse);
    });
    test(
        'custom calculations are private, count neutral and recover on another device',
        () async {
      final branch = await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      final calculation = Follow(
          id: 'personal-calculation',
          organizationId: Follow.personalOrganizationId('user'),
          scopeId: 'global',
          status: 'active',
          followedAt: DateTime.now(),
          personalTargetPercent: 80,
          personalBasis: CalculationBasis.days,
          personalEvaluationPeriod: EvaluationPeriod.monthly,
          personalFullUnit: 1,
          personalHalfUnit: .5,
          personalWeeklyOffs: '[7]',
          personalOffSaturdays: '[2,4]',
          personalHolidays: '{"replace":true,"holidays":[]}',
          isPersonalCalendarConfigured: true);
      await users.usePersonalCalculation('user', calculation, organizations);
      await sync.syncNow();
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      expect((await orgRemote.getScope('college', 'csc'))!.followerCount, 1);
      expect((await firestore.doc('organizations/personal:user').get()).exists,
          isFalse);
      expect(
          (await firestore.doc('users/user/follows/personal-calculation').get())
              .exists,
          isTrue);
      final second = StandInDatabase.executor(NativeDatabase.memory());
      final secondUsers = UserRepository(second, userRemote);
      final secondOrgs = OrganizationRepository(second, orgRemote);
      try {
        await secondUsers.syncProfile('user');
        await secondOrgs.syncFollowContext('user', calculation.id,
            userRemote: userRemote);
        final restored = await secondOrgs.getResolvedPolicy(
            uid: 'user',
            organizationId: calculation.organizationId,
            scopeId: 'global',
            followId: calculation.id);
        final restoredCalendar = await secondOrgs.getResolvedCalendar(
            uid: 'user',
            organizationId: calculation.organizationId,
            scopeId: 'global',
            followId: calculation.id);
        expect(restored!.minimumPercent, 80);
        expect(restored.basis, CalculationBasis.days);
        expect(restoredCalendar.weeklyOffs, [7]);
        expect(restoredCalendar.offSaturdays, [2, 4]);
      } finally {
        await second.close();
      }
      await users.activateFollow('user', branch.id);
      await users.unfollow('user', calculation);
      await sync.syncNow();
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      expect((await users.getProfile('user'))!.activeFollowId, branch.id);
    });
    test(
        'editing a profile preserves its following and can remove optional contact details',
        () async {
      final follow = await users.followScope('user', org, 'csc', organizations);
      await sync.syncNow();
      await users.updateProfileDetails('user', '  New name  ', '');
      await sync.syncNow();
      final profile = await users.getProfile('user');
      expect(profile!.displayName, 'New name');
      expect(profile.mobile, isNull);
      expect(profile.role, AppRole.student);
      expect(profile.activeFollowId, follow.id);
      expect((await orgRemote.getOrganization('college'))!.followerCount, 1);
      await expectLater(
          users.updateProfileDetails('user', ' ', null), throwsStateError);
    });
    test('personal rules can be reset and do not edit shared rules or counts',
        () async {
      final p = rules();
      final c = schedule();
      await organizations.publishScopeRules(
          Scope(
              id: 'csc',
              organizationId: 'college',
              name: 'CSC',
              type: 'branch',
              createdBy: 'creator',
              activePolicyId: p.id,
              activeCalendarId: c.id),
          p,
          c);
      final follow = await users.followScope('user', org, 'csc', organizations);
      await users.saveFollow('user',
          follow.copyWith(personalTargetPercent: 90, personalFullUnit: 2));
      await sync.syncNow();
      final personal = await organizations.getResolvedPolicy(
          uid: 'user',
          organizationId: 'college',
          scopeId: 'csc',
          followId: follow.id);
      expect(personal!.minimumPercent, 90);
      expect(personal.fullUnit, 2);
      expect((await orgRemote.getPolicy('college', p.id))!.minimumPercent, 75);
      await users.saveFollow('user', follow.withoutPersonalSettings);
      await sync.syncNow();
      expect(
          (await organizations.getResolvedPolicy(
                  uid: 'user',
                  organizationId: 'college',
                  scopeId: 'csc',
                  followId: follow.id))!
              .minimumPercent,
          75);
      expect((await orgRemote.getScope('college', 'csc'))!.followerCount, 1);
    });
    test('plan edits and tombstones sync separately from attendance', () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 1);
      final repository = PlanningRepository(database,
          organizationId: 'college', scopeId: 'csc');
      final entry = AttendancePlan(
          id: attendanceId(date, 'college', 'csc'),
          organizationId: 'college',
          scopeId: 'csc',
          date: date,
          status: AttendanceStatus.full,
          units: 1,
          policyVersionId: 'p',
          calendarVersionId: 'c');
      await repository.save(entry);
      await sync.syncNow();
      expect((await database.getPlan(entry.id))!.pendingSync, isFalse);
      expect(await database.select(database.attendanceTable).get(), isEmpty);
      expect(
          (await firestore
                  .collection('users')
                  .doc('user')
                  .collection('attendance')
                  .get())
              .docs,
          isEmpty);
      await repository.remove(date);
      await sync.syncNow();
      expect(await repository.watchPlans().first, isEmpty);
      expect(
          (await firestore
                  .collection('users')
                  .doc('user')
                  .collection('plans')
                  .doc(entry.id)
                  .get())
              .data()!['isDeleted'],
          isTrue);
      await FirestoreAttendanceRemote(firestore).deleteAllAttendance('user');
      expect(
          (await firestore
                  .collection('users')
                  .doc('user')
                  .collection('plans')
                  .get())
              .docs,
          isEmpty);
    });
    test(
        'editing legacy attendance preserves its protected historical version identifiers',
        () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      final attendance = LocalFirstAttendanceRepository(database,
          uid: 'user', organizationId: 'college', scopeId: 'csc');
      await attendance.save(AttendanceRecord(
          date: date,
          status: AttendanceStatus.full,
          actualUnits: 1,
          expectedUnits: 1));
      final previous = (await attendance.watchRecords().first).single;
      await attendance.save(AttendanceRecord(
          date: date,
          status: AttendanceStatus.absent,
          actualUnits: 0,
          expectedUnits: 1,
          policyVersionId: 'new-policy',
          calendarVersionId: 'new-calendar',
          baseRevision: previous.fingerprint));
      final row =
          await database.getAttendance(attendanceId(date, 'college', 'csc'));
      expect(row!.policyVersionId, isNull);
      expect(row.calendarVersionId, isNull);
      final queued = await database.getOperation('attendance:${row.id}');
      expect(jsonDecode(queued!.payload)['policyVersionId'], isNull);
    });

    test('confirming elapsed attendance atomically removes its old plan',
        () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      final entry = AttendancePlan(
          id: attendanceId(date, 'college', 'csc'),
          organizationId: 'college',
          scopeId: 'csc',
          date: date,
          status: AttendanceStatus.full,
          units: 1);
      await database
          .upsertPlan(PlanningRepository.toRow(entry, pendingSync: false));
      await LocalFirstAttendanceRepository(database,
              uid: 'user', organizationId: 'college', scopeId: 'csc')
          .save(AttendanceRecord(
              date: date,
              status: AttendanceStatus.absent,
              actualUnits: 0,
              expectedUnits: 1));
      expect((await database.getPlan(entry.id))!.isDeleted, isTrue);
      expect((await database.getAttendance(entry.id))!.actualUnits, 0);
      expect(await database.getOperation('plan:${entry.id}'), isNotNull);
      expect(await database.getOperation('attendance:${entry.id}'), isNotNull);
    });
    test(
        'new devices restore all follows and pending edits survive remote restores',
        () async {
      final follow = Follow(
          id: 'remote-follow',
          organizationId: 'college',
          scopeId: 'csc',
          status: 'active',
          followedAt: DateTime(2000));
      await userRemote.putFollow('user', follow);
      await users.syncFollows('user');
      expect(await database.watchFollows().first, hasLength(1));
      await users.saveFollow(
          'user', follow.copyWith(personalTargetPercent: 95));
      await users.syncFollows('user');
      expect((await database.getFollow(follow.id))!.personalTargetPercent, 95);
    });
    test(
        'new personal holiday lists can replace inherited holidays while legacy lists still merge',
        () async {
      await organizations.saveCalendar(
          'college',
          schedule(scope: 'global').copyWith(holidays: [
            Holiday(date: DateTime(2026, 1, 26), name: 'Shared')
          ]));
      final follow = Follow(
          id: 'f',
          organizationId: 'college',
          scopeId: 'global',
          status: 'active',
          followedAt: DateTime(2000),
          isPersonalCalendarConfigured: true,
          personalWeeklyOffs: '[]',
          personalOffSaturdays: '[]',
          personalHolidays: jsonEncode({'replace': true, 'holidays': []}));
      await users.saveFollow('user', follow);
      expect(
          (await organizations.getResolvedCalendar(
                  uid: 'user',
                  organizationId: 'college',
                  scopeId: 'global',
                  followId: 'f'))
              .holidays,
          isEmpty);
    });
  });

  test('schema 1 upgrades without losing attendance, scopes or queued edits',
      () async {
    final old = sqlite3.openInMemory();
    old.execute(
        'CREATE TABLE user_profile_rows (uid TEXT PRIMARY KEY, display_name TEXT NOT NULL, role TEXT NOT NULL, mobile TEXT, active_follow_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
    old.execute(
        'CREATE TABLE scope_rows (id TEXT PRIMARY KEY, organization_id TEXT NOT NULL, parent_id TEXT, type TEXT NOT NULL, name TEXT NOT NULL, active_policy_id TEXT, active_calendar_id TEXT)');
    old.execute(
        "INSERT INTO scope_rows VALUES ('csc', 'college', NULL, 'branch', 'CSC', 'p', 'c')");
    old.execute(
        'CREATE TABLE attendance_table (id TEXT PRIMARY KEY, organization_id TEXT NOT NULL, scope_id TEXT NOT NULL, attendance_date INTEGER NOT NULL, status TEXT NOT NULL, actual_units REAL NOT NULL, expected_units REAL NOT NULL, policy_version_id TEXT, calendar_version_id TEXT, pending_sync INTEGER NOT NULL DEFAULT 1, sync_error TEXT, updated_at INTEGER NOT NULL)');
    old.execute(
        "INSERT INTO attendance_table VALUES ('old', 'college', 'csc', 1000, 'full', 1, 1, 'p', 'c', 1, NULL, 1000)");
    old.execute(
        'CREATE TABLE sync_queue_rows (id TEXT PRIMARY KEY, operation TEXT NOT NULL, entity_id TEXT NOT NULL, payload TEXT NOT NULL, attempt_count INTEGER NOT NULL DEFAULT 0, next_attempt_at INTEGER NOT NULL, last_error TEXT, created_at INTEGER NOT NULL)');
    old.execute(
        "INSERT INTO sync_queue_rows VALUES ('attendance:old', 'upsertAttendance', 'old', '{}', 0, 1000, NULL, 1000)");
    old.execute('PRAGMA user_version = 1');
    final database = StandInDatabase.executor(NativeDatabase.opened(old));
    try {
      expect((await database.getScope('csc'))!.followerCount, 0);
      expect((await database.getScope('csc'))!.isArchived, isFalse);
      expect((await database.getAttendance('old'))!.actualUnits, 1);
      expect((await database.getAttendance('old'))!.pendingSync, isTrue);
      expect(await database.getOperation('attendance:old'), isNotNull);
      expect(await database.select(database.attendancePlanRows).get(), isEmpty);
    } finally {
      await database.close();
    }
  });

  test(
      'schema 2 upgrade preserves optional mobile and the active legacy calendar',
      () async {
    final old = sqlite3.openInMemory();
    old.execute(
        'CREATE TABLE user_profile_rows (uid TEXT PRIMARY KEY, display_name TEXT NOT NULL, role TEXT NOT NULL, mobile TEXT, active_follow_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
    old.execute(
        "INSERT INTO user_profile_rows VALUES ('user', 'Student', 'student', '+911234567890', 'legacy-branch-follow', 1000, 1000)");
    old.execute('PRAGMA user_version = 2');
    final database = StandInDatabase.executor(NativeDatabase.opened(old));
    try {
      final profile = (await database.getUserProfile('user'))!;
      expect(profile.mobile, '+911234567890');
      expect(profile.activeFollowId, 'legacy-branch-follow');
      expect(profile.registrationNumber, isNull);
      expect(await database.getCalendarState('legacy-branch-follow'), isNull);
      await database.saveCalendarState('legacy-branch-follow', '{}');
      expect((await database.getCalendarState('legacy-branch-follow'))!.payload,
          '{}');
    } finally {
      await database.close();
    }
  });
}
