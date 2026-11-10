import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/planning.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/domain/shared_rules.dart';
import 'package:standin/src/data/organization_repository.dart';

const engine = PolicyEngine();
AttendancePolicy policy(
        {LeaveTreatment leave = LeaveTreatment.noCredit,
        bool weekend = false,
        bool holiday = false}) =>
    AttendancePolicy(
        id: 'p',
        version: 1,
        effectiveFrom: DateTime(2000),
        state: PolicyState.community,
        evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.days,
        fullUnit: 1,
        halfUnit: .5,
        minimumPercent: 85,
        organizationId: 'org',
        scopeId: 'global',
        leaveTreatment: leave,
        weekOffCredit: weekend,
        holidayCredit: holiday);
AttendanceCalendar calendar({List<Holiday> holidays = const []}) =>
    AttendanceCalendar(
        id: 'c',
        version: 1,
        effectiveFrom: DateTime(2000),
        weeklyOffs: const [6, 7],
        holidays: holidays,
        isConfigured: true,
        organizationId: 'org',
        scopeId: 'global');
AttendanceRecord mark(DateTime date, AttendanceStatus status,
        AttendancePolicy p, AttendanceCalendar c,
        {double? leaveUnits, double? units}) =>
    engine
        .createRecord(
            date: date,
            status: status,
            policy: p,
            calendar: c,
            actualUnits: units,
            leaveUnits: leaveUnits)
        .copyWith(
            organizationId: 'org',
            scopeId: 'global',
            policyVersionId: p.id,
            calendarVersionId: c.id);

void main() {
  test(
      '15 attended + 2 leave + 1 weekend swipe is 18/21, without another working day',
      () {
    final p = policy(leave: LeaveTreatment.countsTowardTarget, weekend: true),
        c = calendar();
    final working = [for (var d = 1; d <= 31; d++) DateTime(2026, 5, d)]
        .where((d) => !c.isNonWorkingDay(d))
        .toList();
    expect(working, hasLength(21));
    final records = [
      for (var i = 0; i < working.length; i++)
        mark(
            working[i],
            i < 15
                ? AttendanceStatus.full
                : i < 17
                    ? AttendanceStatus.leave
                    : AttendanceStatus.absent,
            p,
            c),
      mark(DateTime(2026, 5, 30), AttendanceStatus.full, p, c)
    ];
    final summary = engine.summarize(
        p, c, [...records, records.last], DateTime(2026, 5, 31));
    expect(summary.actual, 18);
    expect(summary.expected, 21);
    expect(summary.percent, closeTo(85.7142857, .00001));
    expect(summary.physicalUnits, 15);
    expect(summary.leaveCredit, 2);
    expect(summary.extraCredit, 1);
  });
  test(
      'week-off and holiday credit are independent and leave on off-days earns nothing',
      () {
    final date = DateTime(2026, 5, 30);
    final c = calendar(holidays: [Holiday(date: date, name: 'Holiday')]);
    expect(
        mark(date, AttendanceStatus.full, policy(weekend: true), c)
            .snapshot!
            .credited,
        0);
    expect(
        mark(date, AttendanceStatus.full, policy(holiday: true), c)
            .snapshot!
            .extraCredit,
        1);
    expect(
        mark(date, AttendanceStatus.leave,
                policy(leave: LeaveTreatment.countsTowardTarget), c)
            .snapshot!
            .credited,
        0);
    expect(
        mark(date, AttendanceStatus.full, policy(weekend: true), calendar())
            .snapshot!
            .requiredUnits,
        0);
  });
  test('full/half leave treatment and overlapping attendance validation', () {
    final date = DateTime(2026, 5, 29), c = calendar();
    final credited = mark(date, AttendanceStatus.half,
        policy(leave: LeaveTreatment.countsTowardTarget), c,
        leaveUnits: .5);
    expect(credited.actualUnits, .5);
    expect(credited.snapshot!.credited, 1);
    expect(credited.snapshot!.requiredUnits, 1);
    final excluded = mark(
        date, AttendanceStatus.half, policy(leave: LeaveTreatment.excluded), c,
        leaveUnits: .5);
    expect(excluded.snapshot!.credited, .5);
    expect(excluded.snapshot!.requiredUnits, .5);
    expect(
        mark(date, AttendanceStatus.leave,
                policy(leave: LeaveTreatment.excluded), c)
            .snapshot!
            .requiredUnits,
        0);
    expect(
        mark(date, AttendanceStatus.leave, policy(), c).snapshot!.requiredUnits,
        1);
    expect(() => mark(date, AttendanceStatus.full, policy(), c, leaveUnits: .5),
        throwsArgumentError);
    expect(
        () => mark(date, AttendanceStatus.half, policy(), c,
            leaveUnits: double.nan),
        throwsArgumentError);
  });
  test('zero required attendance is neutral even when extra credit exists', () {
    final p = policy(weekend: true).copyWith(
        evaluationPeriod: EvaluationPeriod.custom,
        startDate: DateTime(2026, 5, 30),
        endDate: DateTime(2026, 5, 31));
    final c = calendar();
    final result = engine.summarize(
        p,
        c,
        [mark(DateTime(2026, 5, 30), AttendanceStatus.full, p, c)],
        DateTime(2026, 5, 31));
    expect(result.actual, 1);
    expect(result.expected, 0);
    expect(result.percent, 0);
    expect(result.isSafe, false);
    expect(result.recoveryMessage, 'No required attendance');
  });
  test(
      'saved contributions ignore later holidays, leave rules and calendar changes',
      () {
    final p = policy(leave: LeaveTreatment.countsTowardTarget), c = calendar();
    final date = DateTime(2026, 5, 29);
    final records = [mark(date, AttendanceStatus.leave, p, c)];
    final changed =
        calendar(holidays: [Holiday(date: date, name: 'New holiday')]);
    final result = engine.summarize(policy(), changed, records, date);
    expect(result.actual, 1);
    expect(records.single.actualUnits, 0);
    expect(records.single.snapshot!.requiredUnits, 1);
    expect(
        engine
            .summarizePlans(policy(), changed, records, [], date)
            .confirmedUnits,
        1);
  });
  test(
      'migration preserves excluded effective contribution and the original raw swipe',
      () {
    final date = DateTime(2026, 5, 29), p = policy();
    final raw = AttendanceRecord(
        date: date,
        status: AttendanceStatus.full,
        actualUnits: 1,
        expectedUnits: 1);
    final result = engine.freezeLegacy(raw, p,
        calendar(holidays: [Holiday(date: date, name: 'Accepted holiday')]));
    expect(result.actualUnits, 1);
    expect(result.expectedUnits, 1);
    expect(result.snapshot!.credited, 0);
    expect(result.snapshot!.requiredUnits, 0);
    expect(result.snapshot!.legacy, true);
    expect(engine.summarize(p, calendar(), [result], date).actual, 0);
  });
  test('structural changes align with both old and new period boundaries', () {
    final old = policy();
    final next = old.copyWith(evaluationPeriod: EvaluationPeriod.weekly);
    expect(
        ruleActivationDate(
            old, next, DateTime(2026, 10, 26), DateTime(2026, 10, 25)),
        DateTime(2026, 11, 2));
    expect(
        ruleActivationDate(old, old.copyWith(weekOffCredit: true),
            DateTime(2026, 10, 1), DateTime(2026, 10, 25)),
        DateTime(2026, 10, 26));
    expect(
        () => ruleActivationDate(
            old,
            old.copyWith(
                evaluationPeriod: EvaluationPeriod.custom,
                startDate: DateTime(2026, 10, 1),
                endDate: DateTime(2026, 12, 1)),
            DateTime(2026, 10, 26),
            DateTime(2026, 10, 25)),
        throwsStateError);
  });
  test(
      'planned weekend credit and planned leave affect projections, never actual',
      () {
    final p = policy(weekend: true, leave: LeaveTreatment.countsTowardTarget),
        c = calendar();
    AttendancePlan plan(DateTime date, AttendanceStatus status) =>
        AttendancePlan(
            id: attendanceId(date, 'org', 'global'),
            organizationId: 'org',
            scopeId: 'global',
            date: date,
            status: status,
            units: 1,
            policyVersionId: planningPolicyKey(p),
            calendarVersionId: planningCalendarKey(c));
    final result = engine.summarizePlans(
        p,
        c,
        [],
        [
          plan(DateTime(2026, 5, 30), AttendanceStatus.full),
          plan(DateTime(2026, 5, 29), AttendanceStatus.leave)
        ],
        DateTime(2026, 5, 28));
    expect(result.plannedUnits, 2);
    expect(result.totalExpected, 21);
    expect(result.confirmedUnits, 0);
  });
  test(
      'per-field combinations reject invalid full/half units without changing other fields',
      () {
    final rules = SharedRules(policy(), calendar());
    expect(() => rules.apply({'fullUnit': .25}), throwsArgumentError);
    final result = rules.apply({'leaveTreatment': 'countsTowardTarget'});
    expect(result.policy.minimumPercent, 85);
    expect(result.policy.weekOffCredit, false);
  });
  test(
      'monthly reports never combine days and hours across a structural transition',
      () {
    final old = policy(),
        next = policy()
            .copyWith(basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4);
    final c = calendar(), now = DateTime(2026, 5, 31);
    AttendancePolicy at(DateTime date) => date.day < 16 ? old : next;
    final saved = [mark(DateTime(2026, 5, 15), AttendanceStatus.full, old, c)];
    expect(
        engine.summarize(old, c, saved, now, policyFor: at).isPolicyIncomplete,
        true);
    expect(
        engine
            .summarizePlans(old, c, saved, [], now, policyFor: at)
            .isIncomplete,
        true);
    expect(saved.single.snapshot!.credited, 1);
  });

  test('migration does not guess a historical basis from mismatched units', () {
    final raw = AttendanceRecord(date: DateTime(2026, 5, 29), status: AttendanceStatus.full,
        actualUnits: 8, expectedUnits: 8);
    final preserved = engine.freezeLegacy(raw, policy(), calendar());
    expect(preserved.actualUnits, 8);
    expect(preserved.snapshot, isNull);
  });
  group('durable protection and consent', () {
    late StandInDatabase db;
    late FakeFirebaseFirestore firestore;
    late LocalFirstAttendanceRepository records;
    late CalendarRepository calendars;
    setUp(() async {
      db = StandInDatabase.executor(NativeDatabase.memory());
      firestore = FakeFirebaseFirestore();
      records = LocalFirstAttendanceRepository(db,
          uid: 'user', organizationId: 'org', scopeId: 'global');
      calendars = CalendarRepository(db, FirestoreUserRemote(firestore),
          uid: 'user', followId: 'f');
      await calendars.ensure(calendar(), policy: policy());
    });
    tearDown(() async {
      await db.close();
    });
    test(
        'corrections keep audit history, preserve original units and refuse stale editors',
        () async {
      final date = DateTime(2026, 5, 29);
      await records
          .save(mark(date, AttendanceStatus.full, policy(), calendar()));
      final previous = (await records.watchRecords().first).single;
      final correction = mark(date, AttendanceStatus.half, policy(), calendar())
          .copyWith(baseRevision: previous.fingerprint);
      await records.save(correction);
      final current = (await records.watchRecords().first).single;
      expect(current.history.single['actualUnits'], 1);
      await expectLater(records.save(correction), throwsStateError);
      await expectLater(
          records.save(mark(date, AttendanceStatus.full,
                  policy().copyWith(fullUnit: 8, halfUnit: 4), calendar())
              .copyWith(baseRevision: current.fingerprint)),
          throwsStateError);
      expect((await records.watchRecords().first).single.actualUnits, .5);
    });
    test(
        'personal changes preserve elapsed-date requirements and queue prospective rules',
        () async {
      final before = (await calendars.read())!;
      final now = DateTime.now();
      await calendars.setSettings(
          calendar().copyWith(weeklyOffs: [1, 2, 3, 4, 5, 6, 7]),
          policy: policy(weekend: true));
      final after = (await calendars.read())!;
      expect(after.calendarAt(now).weeklyOffs, before.calendar.weeklyOffs);
      expect(after.policyAt(now)!.weekOffCredit, false);
      expect(after.ruleTimeline, hasLength(1));
      expect(after.policyAt(DateTime(2100))!.weekOffCredit, true);
      expect(after.calendarAt(DateTime(2100)).weeklyOffs, hasLength(7));
    });
    test(
        'full consent preserves unrelated personal overrides; stale review is rejected',
        () async {
      final date = DateTime.now().add(const Duration(days: 60));
      await calendars.setHoliday(date, Holiday(date: date, name: 'Mine'));
      final before = (await calendars.read())!;
      final rules = SharedRules(policy(), calendar());
      final next = rules.apply(
          {'leaveTreatment': 'countsTowardTarget', 'weekOffCredit': true});
      final revision = RuleRevision(
          id: 'rules-1',
          version: 1,
          author: 'owner',
          before: rules,
          rules: next,
          effectiveDate: DateTime.now().subtract(const Duration(days: 3)),
          changes: next.changesFrom(rules));
      await calendars.applyRuleReview(
          before, revision, {'leaveTreatment': true, 'weekOffCredit': false});
      final accepted = (await calendars.read())!;
      expect(accepted.reviewedRuleVersion, 1);
      expect(accepted.policyAt(DateTime(2100))!.leaveTreatment,
          LeaveTreatment.countsTowardTarget);
      expect(accepted.policyAt(DateTime(2100))!.weekOffCredit, false);
      expect(accepted.calendar.holidays.single.name, 'Mine');
      expect(
          DateTime.parse(
                  accepted.ruleTimeline.single['effectiveDate'] as String)
              .isAfter(DateUtilsDate.today()),
          true);
      await expectLater(
          calendars.applyRuleReview(before, revision,
              {'leaveTreatment': true, 'weekOffCredit': true}),
          throwsStateError);
    });
    test(
        'legacy migration preserves raw stored data and pending upload identity',
        () async {
      final date = DateTime(2026, 5, 29),
          id = attendanceId(date, 'org', 'global');
      await db.upsertAttendance(AttendanceTableCompanion.insert(
          id: id,
          organizationId: 'org',
          scopeId: 'global',
          attendanceDate: date,
          status: 'full',
          actualUnits: 1,
          expectedUnits: 1,
          updatedAt: DateTime.now(),
          pendingSync: const Value(false)));
      await records.protectHistory(policy(),
          calendar(holidays: [Holiday(date: date, name: 'Accepted holiday')]));
      final migrated = (await records.watchRecords().first).single;
      expect(migrated.actualUnits, 1);
      expect(migrated.snapshot!.credited, 0);
      final queued =
          jsonDecode((await db.getOperation('attendance:$id'))!.payload) as Map;
      expect(queued['actualUnits'], 1);
      expect(queued['snapshot']['legacy'], true);
    });
    test(
        'remote retries are idempotent and another-device correction cannot be replaced',
        () async {
      final date = DateTime(2026, 5, 29),
          id = attendanceId(date, 'org', 'global');
      await records
          .save(mark(date, AttendanceStatus.full, policy(), calendar()));
      final first = (await records.watchRecords().first).single;
      final remote = FirestoreAttendanceRemote(firestore);
      await remote.putAttendance('user', id, first);
      await remote.putAttendance('user', id, first);
      final corrected = mark(date, AttendanceStatus.half, policy(), calendar())
          .copyWith(
              revisionId: 'other-device',
              baseRevision: first.fingerprint,
              history: [first.toJson()]);
      await remote.putAttendance('user', id, corrected);
      await expectLater(
          remote.putAttendance(
              'user', id, corrected.copyWith(revisionId: 'stale')),
          throwsStateError);
      expect(
          (await firestore.doc('users/user/attendance/$id').get())
              .data()!['actualUnits'],
          .5);
    });
    test(
        'shared publication does not mutate attendance or legacy policy/calendar pointers',
        () async {
      await firestore.doc('configuration/sharedRules').set({'enabled': true});
      await firestore.doc('organizations/org').set({
        'createdBy': 'owner',
        'activePolicyId': 'p',
        'activeCalendarId': 'c'
      });
      final remote = FirestoreOrgRemote(firestore);
      final before = SharedRules(policy(), calendar()),
          next = SharedRules(policy(weekend: true), calendar());
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 1);
      await remote.publishRules('org', 'owner', before, next, 0, date);
      final org = (await firestore.doc('organizations/org').get()).data()!;
      expect(org['activePolicyId'], 'p');
      expect(org['activeCalendarId'], 'c');
      expect(org['latestRuleRevision'], 1);
      expect((await firestore.collection('users/user/attendance').get()).docs,
          isEmpty);
      final revision = (await remote.nextRuleRevision('org', 0))!;
      expect(revision.changes, {'weekOffCredit': true});
      await expectLater(
          remote.publishRules('org', 'owner', before, next, 0, date),
          throwsStateError);
      final dbEntry = await firestore
          .doc('organizations/org/ruleRevisions/${revision.id}')
          .get();
      expect(dbEntry.data()!['publishedAt'], isA<Timestamp>());
    });
    for (final useLocal in [true, false]) {
      test(
          'conflict resolution preserves both edits and sync preconditions: use local $useLocal',
          () async {
        final date = DateTime(2026, 5, 29),
            id = attendanceId(date, 'org', 'global');
        final remote = FirestoreAttendanceRemote(firestore);
        await records
            .save(mark(date, AttendanceStatus.full, policy(), calendar()));
        final first = (await records.watchRecords().first).single;
        await remote.putAttendance('user', id, first);
        await db
            .acknowledgeOperation((await db.getOperation('attendance:$id'))!);
        await records.save(
            mark(date, AttendanceStatus.half, policy(), calendar())
                .copyWith(baseRevision: first.fingerprint));
        final local = (await records.watchRecords().first).single;
        final cloud = mark(date, AttendanceStatus.absent, policy(), calendar())
            .copyWith(
                revisionId: 'cloud-edit',
                baseRevision: first.fingerprint,
                history: [first.toJson()]);
        await remote.putAttendance('user', id, cloud);
        await expectLater(
            remote.putAttendance('user', id, local), throwsStateError);
        await records.resolveConflict(local, cloud, remote, useLocal: useLocal);
        final resolved = (await records.watchRecords().first).single;
        expect(resolved.actualUnits, useLocal ? .5 : 0);
        expect(
            resolved.history
                .any((entry) => entry['revisionId'] == local.revisionId),
            true);
        expect(resolved.history.last['revisionId'], cloud.revisionId);
        expect(resolved.baseRevision, cloud.fingerprint);
        await remote.putAttendance('user', id, resolved);
        await expectLater(
            records.resolveConflict(local, cloud, remote, useLocal: useLocal),
            throwsStateError);
      });
    }
    test('shared selected dates replace only their override after activation',
        () async {
      final today = DateTime.now(),
          day = DateTime(today.year, today.month, today.day + 3);
      await calendars.setHoliday(day, Holiday(date: day, name: 'Mine'));
      final before = (await calendars.read())!,
          rules = SharedRules(policy(), calendar());
      final next = SharedRules(
          policy(), calendar(holidays: [Holiday(date: day, name: 'Shared')]));
      final revision = RuleRevision(
          id: 'r1',
          version: 1,
          author: 'owner',
          before: rules,
          rules: next,
          effectiveDate: day,
          changes: next.changesFrom(rules));
      await calendars.applyRuleReview(
          before, revision, {for (final k in revision.changes.keys) k: true});
      final after = (await calendars.read())!;
      expect(after.calendarAt(today).holidays.single.name, 'Mine');
      expect(after.calendarAt(day).holidays.single.name, 'Shared');
      await calendars.setHoliday(
          day, Holiday(date: day, name: 'New private choice'));
      expect((await calendars.read())!.calendarAt(day).holidays.single.name,
          'New private choice');
    });
    test(
        'a second structural change waits for the already scheduled period to end',
        () async {
      final before = (await calendars.read())!, today = DateTime(2026, 10, 25);
      final hours = policy()
          .copyWith(basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4);
      final first =
          calendars.scheduleRules(before, hours, calendar(), today, now: today);
      final second = calendars.scheduleRules(first, policy(), calendar(), today,
          now: today);
      expect(first.ruleTimeline.last['effectiveDate'], '2026-11-01');
      expect(second.ruleTimeline.last['effectiveDate'], '2026-12-01');
    });
    test(
        'owner draft is durable and private and missing gate blocks publication',
        () async {
      final orgs = OrganizationRepository(db, FirestoreOrgRemote(firestore));
      final draft = {
        'version': 0,
        'draft': {'target': '84.'}
      };
      await orgs.saveRulesDraft('user', 'org', draft);
      expect(await orgs.readRulesDraft('user', 'org'), draft);
      expect(await orgs.readRulesDraft('other', 'org'), null);
      await firestore.doc('organizations/org').set({
        'createdBy': 'user',
        'activePolicyId': 'p',
        'activeCalendarId': 'c'
      });
      await expectLater(
          orgs.publishRules(
              'org',
              'user',
              SharedRules(policy(), calendar()),
              SharedRules(policy(weekend: true), calendar()),
              0,
              DateTime.now().add(const Duration(days: 2))),
          throwsStateError);
      expect(await orgs.readRulesDraft('user', 'org'), draft);
      await orgs.removeRulesDraft('user', 'org');
      expect(await orgs.readRulesDraft('user', 'org'), null);
    });
  });
}

class DateUtilsDate {
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
