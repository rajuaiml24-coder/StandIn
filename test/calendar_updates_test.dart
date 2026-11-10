import 'dart:convert';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/calendar_updates.dart';
import 'package:standin/src/domain/planning.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/data/attendance_repository.dart';

AttendanceCalendar baseline() => AttendanceCalendar(
    id: 'c',
    version: 1,
    effectiveFrom: DateTime(2000),
    organizationId: 'org',
    scopeId: 'global',
    weeklyOffs: [7],
    isConfigured: true,
    holidays: [
      Holiday(date: DateTime(2026, 12, 25), name: 'Original holiday')
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('per-date acceptance preserves declined and unrelated private dates',
      () {
    final initial = PersonalCalendarState(baseline: baseline()).withDate(
        DateTime(2026, 12, 28),
        Holiday(date: DateTime(2026, 12, 28), name: 'My holiday'));
    final revision = CalendarRevision(
        id: 'r1',
        version: 1,
        author: 'creator',
        calendar: baseline(),
        changes: {
          '2026-12-25': null,
          '2026-12-26':
              Holiday(date: DateTime(2026, 12, 26), name: 'New holiday')
                  .toJson(),
        });
    final reviewed =
        initial.review(revision, {'2026-12-25': false, '2026-12-26': true});
    expect(reviewed.reviewedVersion, 1);
    expect(reviewed.calendar.holidays.map((h) => h.name),
        containsAll(['Original holiday', 'New holiday', 'My holiday']));
    expect(
        () => initial.review(revision, {'2026-12-25': true}), throwsStateError);
    expect(
        () =>
            reviewed.review(revision, {'2026-12-25': true, '2026-12-26': true}),
        throwsStateError);
  });

  test(
      'a private working-day override can remove an inherited holiday or Sunday',
      () {
    var state = PersonalCalendarState(baseline: baseline());
    state = state
        .withDate(DateTime(2026, 12, 25), null)
        .withDate(DateTime(2026, 12, 27), null);
    expect(state.calendar.isNonWorkingDay(DateTime(2026, 12, 25)), isFalse);
    expect(state.calendar.isNonWorkingDay(DateTime(2026, 12, 27)), isFalse);
    expect(state.calendar.isNonWorkingDay(DateTime(2027, 1, 3)), isTrue);
    final recovered = PersonalCalendarState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
    expect(sameCalendarValue(state.toJson(), recovered.toJson()), isTrue);
  });

  test('different-device date edits merge and same-date conflicts are rejected',
      () {
    final base = PersonalCalendarState(baseline: baseline());
    final local = base.withDate(DateTime(2026, 12, 28),
        Holiday(date: DateTime(2026, 12, 28), name: 'A'));
    final remote = base.withDate(DateTime(2026, 12, 29),
        Holiday(date: DateTime(2026, 12, 29), name: 'B'));
    expect(
        PersonalCalendarState.merge(base, local, remote)
            .calendar
            .holidays
            .map((h) => h.name),
        containsAll(['A', 'B']));
    final conflict = base.withDate(DateTime(2026, 12, 28),
        Holiday(date: DateTime(2026, 12, 28), name: 'Other'));
    expect(() => PersonalCalendarState.merge(base, local, conflict),
        throwsStateError);
  });

  test(
      'creator publication has a sequential immutable snapshot and exact holiday delta',
      () async {
    final firestore = FakeFirebaseFirestore();
    final remote = FirestoreOrgRemote(firestore);
    await remote.putOrganization(
        const Organization(
            id: 'org',
            name: 'College',
            type: OrganizationType.college,
            activeCalendarId: 'c'),
        'creator');
    await remote.putCalendar('org', baseline());
    final revision = await remote.publishCalendarHolidays('org', 'creator',
        baseline(), [Holiday(date: DateTime(2026, 12, 26), name: 'New')]);
    expect(revision.version, 1);
    expect(revision.changes.keys, containsAll(['2026-12-25', '2026-12-26']));
    expect((await remote.nextCalendarRevision('org', 0))!.id, revision.id);
    expect(await remote.nextCalendarRevision('org', 1), isNull);
    expect((await remote.sharedCalendarSnapshot('org')).$3, 1);
    await expectLater(
        remote.publishCalendarHolidays('org', 'user', revision.calendar, []),
        throwsStateError);
    await expectLater(
        remote.publishCalendarHolidays('org', 'creator', baseline(), []),
        throwsStateError);
  });

  test(
      'future private holiday persists without shared writes and stale reviews are refused',
      () async {
    final database = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(database.close);
    final firestore = FakeFirebaseFirestore();
    final remote = FirestoreUserRemote(firestore);
    final repo = CalendarRepository(database, remote, uid: 'u', followId: 'f');
    await repo.ensure(baseline());
    final initial = (await repo.read())!;
    final day = DateTime(DateTime.now().year + 1, 2, 3);
    await repo.setHoliday(
        day, Holiday(date: day, name: 'Personal future holiday'));
    expect((await repo.read())!.calendar.isNonWorkingDay(day), isTrue);
    expect((await firestore.collection('organizations').get()).docs, isEmpty);
    final revision = CalendarRevision(
        id: 'r',
        version: 1,
        author: 'creator',
        calendar: baseline(),
        changes: {'2026-12-25': null});
    await expectLater(repo.applyReview(initial, revision, {'2026-12-25': true}),
        throwsStateError);
    final operation = await database.getOperation(repo.operationId);
    expect(jsonDecode(operation!.payload)['base'], isNull);
    final next = (await repo.read())!;
    await remote.putCalendarState('u', 'f', null, next);
    expect(
        sameCalendarValue(
            (await remote.getCalendarState('u', 'f'))!.toJson(), next.toJson()),
        isTrue);
  });

  test('optional registration survives follow switches and can be cleared',
      () async {
    final database = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(database.close);
    final users =
        UserRepository(database, FirestoreUserRemote(FakeFirebaseFirestore()));
    await users.createProfile(const UserProfile(
        uid: 'u',
        displayName: 'User',
        role: AppRole.student,
        registrationNumber: '0012-CSC'));
    await users.saveFollow(
        'u',
        Follow(
            id: 'f',
            organizationId: 'org',
            scopeId: 'global',
            status: 'active',
            followedAt: DateTime.now()));
    await users.activateFollow('u', 'f');
    expect((await users.getProfile('u'))!.registrationNumber, '0012-CSC');
    await users.updateProfileDetails('u', 'User', null, registrationNumber: '');
    expect((await users.getProfile('u'))!.registrationNumber, isNull);
  });

  test('holidays exclude recorded units without mutating attendance history',
      () {
    final day = DateTime(2026, 12, 25);
    final policy = AttendancePolicy(
        id: 'p',
        version: 1,
        effectiveFrom: DateTime(2000),
        state: PolicyState.personal,
        evaluationPeriod: EvaluationPeriod.custom,
        startDate: day,
        endDate: day,
        basis: CalculationBasis.hours,
        fullUnit: 8,
        halfUnit: 4,
        minimumPercent: 75);
    final record = AttendanceRecord(
        date: day,
        status: AttendanceStatus.full,
        actualUnits: 8,
        expectedUnits: 8);
    final summary =
        const PolicyEngine().summarize(policy, baseline(), [record], day);
    expect(summary.actual, 0);
    expect(summary.expected, 0);
    expect(record.actualUnits, 8);
    expect(
        const PolicyEngine()
            .summarizePlans(policy, baseline(), [record], [], day)
            .confirmedUnits,
        0);
  });

  test(
      'an unrelated holiday retains valid future plans; affected plans remain for review',
      () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(DateTime.now().year + 1, 2, 3);
    final policy = AttendancePolicy(
        id: 'p',
        version: 1,
        effectiveFrom: DateTime(2000),
        state: PolicyState.personal,
        evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.hours,
        fullUnit: 8,
        halfUnit: 4,
        minimumPercent: 75);
    final plans =
        PlanningRepository(db, organizationId: 'org', scopeId: 'global');
    await plans.save(AttendancePlan(
        id: attendanceId(date, 'org', 'global'),
        organizationId: 'org',
        scopeId: 'global',
        date: date,
        status: AttendanceStatus.partial,
        units: 4,
        policyVersionId: planningPolicyKey(policy),
        calendarVersionId: planningCalendarKey(baseline())));
    final unrelated = baseline().copyWith(holidays: [
      Holiday(date: DateTime(date.year, 2, 4), name: 'Other date')
    ]);
    await plans.revalidateUnchangedDates(baseline(), unrelated, policy);
    final row = (await db.getPlan(attendanceId(date, 'org', 'global')))!;
    expect(row.units, 4);
    expect(row.calendarVersionId, planningCalendarKey(unrelated));
    final affected =
        unrelated.copyWith(holidays: [Holiday(date: date, name: 'Holiday')]);
    await plans.revalidateUnchangedDates(unrelated, affected, policy);
    expect(
        (await db.getPlan(row.id))!.calendarVersionId, row.calendarVersionId);
    expect((await db.getPlan(row.id))!.isDeleted, isFalse);
  });
}
