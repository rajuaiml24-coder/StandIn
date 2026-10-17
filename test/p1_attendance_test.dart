import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/app.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';

void main() {
  late StandInDatabase database;
  late LocalFirstAttendanceRepository repository;
  const engine = PolicyEngine();
  final policy = AttendancePolicy(
    id: 'policy',
    version: 1,
    effectiveFrom: DateTime(2000),
    state: PolicyState.personal,
    evaluationPeriod: EvaluationPeriod.monthly,
    basis: CalculationBasis.hours,
    fullUnit: 7,
    halfUnit: 3.5,
    minimumPercent: 75,
  );
  final calendar = AttendanceCalendar(
    id: 'calendar',
    version: 1,
    effectiveFrom: DateTime(2000),
    isConfigured: true,
  );

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    repository = LocalFirstAttendanceRepository(database,
        uid: 'user', organizationId: 'org', scopeId: 'global');
  });
  tearDown(() => database.close());

  testWidgets('Mark today sheet saves the selected attendance', (tester) async {
    final controller =
        AttendanceController(repository, engine, policy, calendar);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => FilledButton(
        onPressed: () => showMarkAttendance(context, controller),
        child: const Text('Mark today'),
      ),
    ))));
    await tester.tap(find.text('Mark today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save attendance'));
    await tester.pumpAndSettle();
    final saved = await database
        .getAttendance(attendanceId(DateTime.now(), 'org', 'global'));
    expect(saved?.actualUnits, 7);
    expect(saved?.status, 'full');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.pumpAndSettle();
  });

  test('timestamp later today saves as a date, tomorrow remains rejected',
      () async {
    final controller =
        AttendanceController(repository, engine, policy, calendar);
    final now = DateTime.now();
    await controller.mark(AttendanceStatus.half,
        date: DateTime(now.year, now.month, now.day, 23, 59));
    final id = attendanceId(now, 'org', 'global');
    expect((await database.getAttendance(id))?.actualUnits, 3.5);
    await controller.mark(AttendanceStatus.absent,
        date: DateTime(now.year, now.month, now.day + 1));
    expect((await database.select(database.attendanceTable).get()).length, 1);
    controller.dispose();
  });

  test('records from another semester do not enter the active scope', () async {
    final record = engine.createRecord(
        date: DateTime(2026, 1, 1),
        status: AttendanceStatus.full,
        policy: policy);
    await repository.save(record);
    final other = LocalFirstAttendanceRepository(database,
        uid: 'user', organizationId: 'org', scopeId: 'semester-2');
    await other.save(engine.createRecord(
        date: record.date, status: AttendanceStatus.absent, policy: policy));
    final records = await repository.watchRecords().first;
    expect(records.length, 1);
    expect(records.single.actualUnits, 7);
  });

  test('unknown organization cannot receive new attendance', () async {
    final unknown = LocalFirstAttendanceRepository(database,
        uid: 'user', organizationId: 'unknown', scopeId: 'global');
    final record = engine.createRecord(
        date: DateTime(2026, 1, 1),
        status: AttendanceStatus.full,
        policy: policy);
    await expectLater(unknown.save(record), throwsStateError);
    expect(await database.select(database.attendanceTable).get(), isEmpty);
  });

  test('missing or invalid targets never claim eligibility', () {
    for (final target in [null, double.nan, -1.0, 101.0]) {
      final incomplete = AttendancePolicy(
        id: 'p',
        version: 1,
        effectiveFrom: DateTime(2000),
        state: PolicyState.personal,
        evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.hours,
        fullUnit: 7,
        halfUnit: 3.5,
        minimumPercent: target,
      );
      final summary =
          engine.summarize(incomplete, calendar, [], DateTime(2026, 1, 10));
      expect(summary.isPolicyIncomplete, isTrue);
      expect(summary.isSafe, isFalse);
      expect(summary.safeToMiss, 0);
      expect(summary.percent.isFinite, isTrue);
    }
  });

  test('missing semester dates and invalid units are incomplete', () {
    final semester =
        policy.copyWith(evaluationPeriod: EvaluationPeriod.semester);
    final monthly = engine.summarizeMonth(
        semester, calendar, [], 2026, 1, DateTime(2026, 1, 10));
    expect(monthly.isPolicyIncomplete, isTrue);
    expect(monthly.isSafe, isFalse);
    expect(monthly.safeToMiss, 0);
    expect(
        engine
            .summarize(semester, calendar, [], DateTime(2026, 1, 10))
            .isPolicyIncomplete,
        isTrue);
    final invalid = policy.copyWith(fullUnit: 0);
    expect(
        engine.summarize(invalid, calendar, [], DateTime(2026, 1, 10)).isSafe,
        isFalse);
    expect(
        () => engine.createRecord(
            date: DateTime(2026, 1, 1),
            status: AttendanceStatus.partial,
            policy: invalid),
        throwsStateError);
  });
}
