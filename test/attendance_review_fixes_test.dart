import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/app.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/attendance_reports.dart';
import 'package:standin/src/domain/calendar_updates.dart';
import 'package:standin/src/domain/planning.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/domain/shared_rules.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:standin/src/features/profile/attendance_reports_page.dart';
import 'package:standin/src/features/profile/data_backup_status.dart';
import 'package:standin/src/features/profile/attendance_sync_status.dart';

const engine = PolicyEngine();
AttendancePolicy policy({bool weekends = false, bool once = false}) =>
    AttendancePolicy(
        id: 'p',
        version: 1,
        effectiveFrom: DateTime(2000),
        state: PolicyState.personal,
        evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.days,
        fullUnit: 1,
        halfUnit: .5,
        minimumPercent: 85,
        organizationId: 'org',
        scopeId: 'global',
        weekOffCredit: weekends,
        oneVisitFullDay: once);
AttendanceCalendar calendar() => AttendanceCalendar(
    id: 'c',
    version: 1,
    effectiveFrom: DateTime(2000),
    organizationId: 'org',
    scopeId: 'global',
    isConfigured: true,
    weeklyOffs: [6, 7]);
AttendanceRecord entry(
        AttendancePolicy p, DateTime date, AttendanceStatus status) =>
    engine
        .createRecord(
            date: date, status: status, policy: p, calendar: calendar())
        .copyWith(
            organizationId: 'org',
            scopeId: 'global',
            policyVersionId: 'p',
            calendarVersionId: 'c');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('WRITE_PREVIEWS')) {
      await (FontLoader('Roboto')
            ..addFont(File('C:/Windows/Fonts/arial.ttf')
                .readAsBytes()
                .then((b) => ByteData.sublistView(b))))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  test('actual and planned months respect each bounded attendance period', () {
    for (final period in [
      EvaluationPeriod.semester,
      EvaluationPeriod.academicYear,
      EvaluationPeriod.halfYear,
      EvaluationPeriod.custom
    ]) {
      final p = policy().copyWith(
          evaluationPeriod: period,
          startDate: DateTime(2026, 11, 16),
          endDate: DateTime(2026, 12, 15));
      final records = [
        for (var d = 16; d <= 20; d++)
          entry(p, DateTime(2026, 11, d), AttendanceStatus.full)
      ];
      final now = DateTime(2026, 11, 20);
      final month =
          engine.summarizeMonth(p, calendar(), records, 2026, 11, now);
      expect(month.percent, 100);
      expect(month.conductedToDate, 5);
      expect(month.totalConducted, 11);
      expect(
          engine
              .summarizePlans(p, calendar(), records, [], now,
                  year: 2026, month: 11)
              .totalExpected,
          11);
      final outside =
          engine.summarizeMonth(p, calendar(), records, 2026, 10, now);
      expect(outside.totalConducted, 0);
      expect(outside.isPolicyIncomplete, true);
      expect(outside.recoveryMessage, 'Outside your attendance period.');
      expect(
          engine
              .summarizePlans(p, calendar(), records, [], now,
                  year: 2026, month: 10)
              .isIncomplete,
          true);
      final end = engine.summarizeMonth(
          p, calendar(), [], 2026, 12, DateTime(2026, 12, 31));
      expect(end.totalConducted, 11);
    }
  });
  test(
      'allowed future days off make 85 percent achievable without advising missed weekdays',
      () {
    final p = policy(weekends: true), c = calendar();
    final working = [
      for (var d = 1; d <= 29; d++)
        if (DateTime(2026, 5, d).weekday <= 5) DateTime(2026, 5, d)
    ];
    final records = [
      for (var i = 0; i < working.length; i++)
        entry(p, working[i],
            i < 17 ? AttendanceStatus.full : AttendanceStatus.absent)
    ];
    final result = engine.summarize(p, c, records, DateTime(2026, 5, 29));
    expect(result.totalConducted, 21);
    expect(result.maximumPossible, 19);
    expect(result.isAchievable, true);
    expect(result.safeToMiss, 0);
    expect(result.recoveryMessage, contains('allowed days off'));
    final disabled = engine.summarize(
        p.copyWith(weekOffCredit: false), c, records, DateTime(2026, 5, 29));
    expect(disabled.isAchievable, false);
  });
  test(
      'holiday maximum uses the holiday setting, without changing required days',
      () {
    final day = DateTime(2026, 5, 30);
    final c =
        calendar().copyWith(holidays: [Holiday(date: day, name: 'Holiday')]);
    final a =
        engine.summarize(policy(weekends: true), c, [], DateTime(2026, 5, 29));
    final b = engine.summarize(
        policy(weekends: true).copyWith(holidayCredit: true),
        c,
        [],
        DateTime(2026, 5, 29));
    expect(b.maximumPossible - a.maximumPossible, 1);
    expect(a.totalConducted, b.totalConducted);
  });
  test('half days and partial classes keep fractional labels', () {
    final p = policy().copyWith(
        evaluationPeriod: EvaluationPeriod.custom,
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 2));
    final summary = engine.summarize(
        p,
        calendar(),
        [entry(p, DateTime(2026, 11, 2), AttendanceStatus.half)],
        DateTime(2026, 11, 2));
    expect(summary.percent, 50);
    expect(summary.progressLabel, '0.5 of 1 working day so far');
    expect(formatAttendanceUnits(0), '0');
    expect(formatAttendanceUnits(10.25), '10.25');
  });
  test(
      'one class or one swipe counts once; rules and history retain the choice',
      () {
    final p = policy(once: true, weekends: true);
    final day = DateTime(2026, 11, 2);
    expect(
        engine.contribution(p, AttendanceDayType.working, day, .1, 0).credited,
        1);
    expect(
        engine
            .contribution(p, AttendanceDayType.weeklyOff, day, .1, 0)
            .extraCredit,
        1);
    expect(
        engine
            .contribution(p, AttendanceDayType.weeklyOff, day, .1, 0)
            .requiredUnits,
        0);
    expect(() => engine.contribution(p, AttendanceDayType.working, day, .5, .5),
        throwsArgumentError);
    expect(p.copyWith(basis: CalculationBasis.hours, fullUnit: 8).hasValidUnits,
        false);
    expect(AttendancePolicy.fromJson(p.toJson()).oneVisitFullDay, true);
    expect(AttendancePolicy.fromJson(policy().toJson()).oneVisitFullDay, false);
    expect(policy().toJson().containsKey('oneVisitFullDay'), false);
    expect(
        entry(p, day, AttendanceStatus.full).snapshot!.toJson()['schema'], 2);
    final before = SharedRules(policy(), calendar()),
        after = SharedRules(p, calendar());
    expect(
        before.apply(after.changesFrom(before)).policy.oneVisitFullDay, true);
    final now = DateTime(2026, 11, 4);
    expect(ruleActivationDate(policy(), p, now, now), DateTime(2026, 12, 1));
  });
  test(
      'offline corrections replay their revision chain and tolerate retry after partial upload',
      () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final remote = FirestoreAttendanceRemote(FakeFirebaseFirestore());
    final repo = LocalFirstAttendanceRepository(db,
        uid: 'user', organizationId: 'org', scopeId: 'global');
    final p = policy(),
        day = DateTime(2026, 5, 29),
        id = attendanceId(DateTime(2026, 5, 29), 'org', 'global');
    await repo.save(entry(p, day, AttendanceStatus.full));
    final first = (await db.getOperation('attendance:$id'))!;
    final synced = AttendanceRecord.fromJson(jsonDecode(first.payload));
    await remote.putAttendance('user', id, synced);
    await db.acknowledgeOperation(first);
    await repo.save(entry(p, day, AttendanceStatus.half)
        .copyWith(baseRevision: synced.fingerprint));
    final second =
        LocalFirstAttendanceRepository.toDomain((await db.getAttendance(id))!);
    await repo.save(entry(p, day, AttendanceStatus.absent)
        .copyWith(baseRevision: second.fingerprint));
    final latest = AttendanceRecord.fromJson(
        jsonDecode((await db.getOperation('attendance:$id'))!.payload));
    final sequence = FirestoreAttendanceRemote.uploadSequence(latest);
    expect(sequence.map((r) => r.status),
        [AttendanceStatus.half, AttendanceStatus.absent]);
    expect(sequence.first.baseRevision, synced.revisionId);
    expect(sequence.last.baseRevision, second.revisionId);
    expect(sequence.last.history.last['revisionId'], second.revisionId);
    await remote.putAttendance('user', id, sequence.first);
    await remote.putAttendance('user', id, latest);
    await remote.putAttendance('user', id, latest);
    final restored = (await remote.getAttendance('user', id))!;
    expect(restored.status, AttendanceStatus.absent);
    expect(restored.history, hasLength(2));
    expect(restored.history.map((r) => r['status']), ['full', 'half']);
    if (const bool.fromEnvironment('WRITE_REVIEW_FIXTURES')) {
      await File('build/fixes-upload-sequence.json').writeAsString(jsonEncode({
        'first': synced.toJson(),
        'latest': latest.toJson(),
        'sequence': sequence.map((r) => r.toJson()).toList()
      }));
    }
  });
  test(
      'a first save corrected offline uploads its original creation before corrections',
      () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalFirstAttendanceRepository(db,
        uid: 'user', organizationId: 'org', scopeId: 'global');
    final remote = FirestoreAttendanceRemote(FakeFirebaseFirestore());
    final p = policy(),
        day = DateTime(2026, 5, 29),
        id = attendanceId(DateTime(2026, 5, 29), 'org', 'global');
    await repo.save(entry(p, day, AttendanceStatus.full));
    final first =
        LocalFirstAttendanceRepository.toDomain((await db.getAttendance(id))!);
    await repo.save(entry(p, day, AttendanceStatus.half)
        .copyWith(baseRevision: first.fingerprint));
    final last = AttendanceRecord.fromJson(
        jsonDecode((await db.getOperation('attendance:$id'))!.payload));
    expect(FirestoreAttendanceRemote.uploadSequence(last).first.baseRevision,
        isNull);
    await remote.putAttendance('user', id, last);
    expect((await remote.getAttendance('user', id))!.history, hasLength(1));
  });
  test(
      'an offline correction after protecting legacy attendance keeps its original entry',
      () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalFirstAttendanceRepository(db,
        uid: 'user', organizationId: 'org', scopeId: 'global');
    final remote = FirestoreAttendanceRemote(FakeFirebaseFirestore());
    final p = policy(),
        day = DateTime(2026, 5, 29),
        id = attendanceId(DateTime(2026, 5, 29), 'org', 'global');
    final original = AttendanceRecord(
        date: day,
        status: AttendanceStatus.full,
        actualUnits: 1,
        expectedUnits: 1,
        organizationId: 'org',
        scopeId: 'global',
        policyVersionId: 'p',
        calendarVersionId: 'c');
    await db.upsertAttendance(
        LocalFirstAttendanceRepository.toRow(original, id, pendingSync: false));
    await remote.putAttendance('user', id, original);
    await repo.protectHistory(p, calendar());
    final protected =
        LocalFirstAttendanceRepository.toDomain((await db.getAttendance(id))!);
    expect(protected.snapshot!.legacy, true);
    await repo.save(entry(p, day, AttendanceStatus.half)
        .copyWith(baseRevision: protected.fingerprint));
    final latest = AttendanceRecord.fromJson(
        jsonDecode((await db.getOperation('attendance:$id'))!.payload));
    final sequence = FirestoreAttendanceRemote.uploadSequence(latest);
    expect(sequence, hasLength(2));
    expect(sequence.first.snapshot!.legacy, true);
    await remote.putAttendance('user', id, latest);
    final restored = (await remote.getAttendance('user', id))!;
    expect(restored.status, AttendanceStatus.half);
    expect(restored.history.single['revisionId'], protected.revisionId);
    if (const bool.fromEnvironment('WRITE_REVIEW_FIXTURES')) {
      await File('build/fixes-legacy-upload-sequence.json').writeAsString(
          jsonEncode({
        'first': original.toJson(),
        'sequence': sequence.map((r) => r.toJson()).toList()
      }));
    }
  });
  test(
      'reports retain original semester rules, and separate years with different units',
      () {
    final p = policy().copyWith(
        evaluationPeriod: EvaluationPeriod.semester,
        startDate: DateTime(2026, 11, 16),
        endDate: DateTime(2026, 12, 15));
    final records = [
      for (var d = 16; d <= 20; d++)
        entry(p, DateTime(2026, 11, d), AttendanceStatus.full)
    ];
    final accepted = PersonalCalendarState(baseline: calendar(), policy: p);
    final reports = buildAttendanceReports(
        records, accepted, ReportGrouping.period, DateTime(2026, 11, 20));
    expect(reports.single.summary.percent, 100);
    expect(reports.single.start, p.startDate);
    final hours = policy()
        .copyWith(basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4);
    final mixed = [
      ...records,
      entry(hours, DateTime(2026, 1, 2), AttendanceStatus.full)
    ];
    final years = buildAttendanceReports(
        mixed, accepted, ReportGrouping.year, DateTime(2026, 11, 20));
    expect(years, hasLength(2));
    expect(years.every((r) => !r.summary.isPolicyIncomplete), true);
    expect(attendanceCsv('XYZ, College', records), contains('"XYZ, College"'));
  });
  testWidgets('calendar uses the new semester when it starts mid-month',
      (tester) async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final repo = LocalFirstAttendanceRepository(db,
        uid: 'u', organizationId: 'org', scopeId: 'global');
    final calendars = CalendarRepository(
        db, FirestoreUserRemote(FakeFirebaseFirestore()),
        uid: 'u', followId: 'f');
    final oldPolicy = policy().copyWith(
        evaluationPeriod: EvaluationPeriod.semester,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 15));
    final nextPolicy = policy().copyWith(
        evaluationPeriod: EvaluationPeriod.semester,
        startDate: DateTime(2026, 8, 16),
        endDate: DateTime(2026, 9, 15));
    final state = PersonalCalendarState(
        baseline: calendar(),
        policy: oldPolicy,
        ruleTimeline: [
          {
            'effectiveDate': '2026-08-16',
            'policy': nextPolicy.toJson(),
            'calendar': calendarJson(calendar())
          }
        ]);
    await tester.runAsync(() async {
      await db.saveCalendarState('f', jsonEncode(state.toJson()));
      for (var day = 17; day <= 21; day++) {
        final record =
            entry(nextPolicy, DateTime(2026, 8, day), AttendanceStatus.full);
        await db.upsertAttendance(LocalFirstAttendanceRepository.toRow(
            record, attendanceId(record.date, 'org', 'global'),
            pendingSync: false));
      }
    });
    final ctrl = AttendanceController(repo, engine, oldPolicy, calendar(),
        calendarRepository: calendars, clock: () => DateTime(2026, 8, 21));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      ctrl.dispose();
      final closing = db.close();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => closing);
    });
    await tester.runAsync(() => ctrl.ready);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(ctrl.getMonthlySummary(2026, 8).percent, 100);
    expect(ctrl.getMonthlySummary(2026, 8).conductedToDate, 5);
    expect(ctrl.getMonthlyPlanningSummary(2026, 8).totalExpected, 11);
  });

  for (final future in [false, true]) {
    testWidgets(
        'partial hours keep leave and saved data consistent, future=$future',
        (tester) async {
      final db = StandInDatabase.executor(NativeDatabase.memory());
      final p = policy()
          .copyWith(basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4);
      final ctrl = AttendanceController(
          LocalFirstAttendanceRepository(db,
              uid: 'u', organizationId: 'org', scopeId: 'global'),
          engine,
          p,
          calendar().copyWith(weeklyOffs: []),
          planningRepository:
              PlanningRepository(db, organizationId: 'org', scopeId: 'global'));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        ctrl.dispose();
        await tester.runAsync(db.close);
      });
      await tester.runAsync(() => ctrl.ready);
      final now = DateTime.now(),
          day = DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 1);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => future
                          ? showPlanAttendance(context, ctrl, day)
                          : showMarkAttendance(context, ctrl),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      final prefix = future ? 'plan' : 'attendance';
      tester
          .widget<Slider>(find.byKey(ValueKey('$prefix-leave')))
          .onChanged!(4);
      await tester.pumpAndSettle();
      tester
          .widget<Slider>(find.byKey(ValueKey('$prefix-units')))
          .onChanged!(6);
      await tester.pumpAndSettle();
      expect(find.text('Leave: 2.0 hours'), findsOneWidget);
      await tester.tap(find.text(future ? 'Save plan' : 'Save attendance'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pumpAndSettle();
      if (future) {
        expect(ctrl.planFor(day)!.leaveUnits, 2);
      } else {
        expect(ctrl.recordFor(now)!.leaveUnits, 2);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'company once-per-day sheet offers Swiped and reports fit a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    final db = StandInDatabase.executor(NativeDatabase.memory()),
        p = policy(once: true);
    final ctrl = AttendanceController(
        LocalFirstAttendanceRepository(db,
            uid: 'u', organizationId: 'org', scopeId: 'global'),
        engine,
        p,
        calendar().copyWith(weeklyOffs: []),
        isCompany: true);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      ctrl.dispose();
      await tester.runAsync(db.close);
      await tester.binding.setSurfaceSize(null);
    });
    await tester.runAsync(() => ctrl.ready);
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('fix-preview'),
        child: MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showMarkAttendance(context, ctrl),
                        child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Swiped'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Not swiped'), findsOneWidget);
    expect(find.text('One swipe counts as a full day.'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Partial'), findsNothing);
    await preview(tester, 'company-swipe-mobile');
    await tester.tap(find.text('Save attendance'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('fix-preview'),
        child: MaterialApp(
            home: AttendanceReportsPage(
                name: 'Company',
                company: true,
                records: ctrl.watchSavedRecords()))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(find.text('Copy CSV'), findsOneWidget);
    await preview(tester, 'attendance-reports-mobile');
    expect(tester.takeException(), isNull);
  });
  for (final counts in [false, true]) {
    testWidgets('day off attendance guidance matches its rule: $counts',
        (tester) async {
      final db = StandInDatabase.executor(NativeDatabase.memory());
      final ctrl = AttendanceController(
          LocalFirstAttendanceRepository(db,
              uid: 'u', organizationId: 'org', scopeId: 'global'),
          engine,
          policy(once: true, weekends: counts),
          calendar(),
          isCompany: true);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        ctrl.dispose();
        final closing = db.close();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() => closing);
      });
      await tester.runAsync(() => ctrl.ready);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showMarkAttendance(context, ctrl,
                          date: DateTime(2026, 11, 7)),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
          find.text(counts
              ? 'Attendance today counts toward your percentage. Working days stay the same.'
              : 'Attendance on this day off does not count with your current rules.'),
          findsOneWidget);
    });
  }
  testWidgets(
      'Home says on track at 100 percent so far and hides an empty forecast',
      (tester) async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final ctrl = AttendanceController(
        LocalFirstAttendanceRepository(db,
            uid: 'u', organizationId: 'org', scopeId: 'global'),
        engine,
        policy(),
        calendar(),
        clock: () => DateTime(2026, 11, 2));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      ctrl.dispose();
      await tester.runAsync(db.close);
    });
    await tester.runAsync(() => ctrl.ready);
    await tester.runAsync(() => ctrl.mark(AttendanceStatus.full));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HomePage(controller: ctrl, onNavigateToCalendar: () {}))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(find.text('On track so far'), findsOneWidget);
    expect(find.text('With plans'), findsNothing);
    expect(find.text('Attention needed'), findsNothing);
  });
  testWidgets(
      'backup status distinguishes an offline save from confirmed backup',
      (tester) async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    var closed = false;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (!closed) {
        final closing = db.close();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() => closing);
      }
    });
    final repo = LocalFirstAttendanceRepository(db,
        uid: 'u', organizationId: 'org', scopeId: 'global');
    await tester.runAsync(() => repo
        .save(entry(policy(), DateTime(2026, 5, 29), AttendanceStatus.full)));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DataBackupStatus(database: db, uid: 'u'))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(find.text('Saved on this device'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await db.acknowledgeOperation((await db.getOperation(
          'attendance:${attendanceId(DateTime(2026, 5, 29), 'org', 'global')}'))!);
      await db.setLastSyncAt('backup:u', DateTime(2026, 11, 4));
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DataBackupStatus(database: db, uid: 'u'))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(find.text('Backed up'), findsOneWidget);
    // Drift closes query streams on the next frame. Flush those cancellations
    // before closing the in-memory database.
    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => closing);
    closed = true;
  });
  testWidgets('a failed plan backup is visible and can be retried',
      (tester) async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final repo =
        PlanningRepository(db, organizationId: 'org', scopeId: 'global');
    final now = DateTime.now(),
        date = DateTime(now.year, now.month, now.day + 1);
    final id = attendanceId(date, 'org', 'global');
    await tester.runAsync(() async {
      await repo.save(AttendancePlan(
          id: id,
          organizationId: 'org',
          scopeId: 'global',
          date: date,
          status: AttendanceStatus.full,
          units: 1));
      await db.rescheduleUnchangedOperation(
          (await db.getOperation('plan:$id'))!,
          1,
          DateTime.now().add(const Duration(hours: 1)),
          'Connection unavailable');
    });
    var closed = false;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (!closed) {
        final closing = db.close();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() => closing);
      }
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AttendanceSyncStatus(
                database: db,
                remote: FirestoreAttendanceRemote(FakeFirebaseFirestore()),
                uid: 'u'))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(find.text('Plan backup failed'), findsOneWidget);
    expect(find.text('Your plan is kept on this device.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pumpAndSettle();
    expect(
        (await tester.runAsync(() => db.getOperation('plan:$id')))!.lastError,
        isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => closing);
    closed = true;
  });
}

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_PREVIEWS')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('fix-preview')));
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/widget-previews').create(recursive: true);
    await File('build/widget-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
