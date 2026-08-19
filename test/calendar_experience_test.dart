import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class FakeAttendanceRecord extends Fake implements AttendanceRecord {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAttendanceRecord());
  });

  const engine = PolicyEngine();

  group('Monthly Attendance Percentage', () {
    final policy = _makePolicy(basis: CalculationBasis.days, full: 1, min: 75);
    final calendar = AttendanceCalendar(
      id: 'c', 
      version: 1, 
      effectiveFrom: DateTime(2026, 1, 1), 
      weeklyOffs: [7], // Sunday off
      isConfigured: true
    );
    final now = DateTime(2026, 8, 17); // Monday

    test('Past month (July) shows percentage based on ALL working days', () {
      final records = [
        _makeRecord(DateTime(2026, 7, 1), AttendanceStatus.full, 1, 1),
        _makeRecord(DateTime(2026, 7, 2), AttendanceStatus.absent, 0, 1),
      ];
      final summary = engine.summarizeMonth(policy, calendar, records, 2026, 7, now);
      expect(summary.actual, 1.0);
      // July 2026 has 27 working days (31 total - 4 Sundays)
      expect(summary.conductedToDate, 27.0); 
      expect(summary.percent, closeTo(3.7, 0.1));
    });

    test('Current month (August) calculates up to today including unmarked', () {
      final records = [
        _makeRecord(DateTime(2026, 8, 3), AttendanceStatus.full, 1, 1),
        _makeRecord(DateTime(2026, 8, 4), AttendanceStatus.full, 1, 1),
      ];
      // Aug 17 is today. 
      // Working days in Aug thru 17th: 1 (Sat), 3-8 (6), 10-15 (6), 17 (1) = 14 days.
      final summary = engine.summarizeMonth(policy, calendar, records, 2026, 8, now);
      expect(summary.actual, 2.0);
      expect(summary.conductedToDate, 14.0);
      expect(summary.percent, closeTo(14.28, 0.1));
    });

    test('Future month (September) shows Not started', () {
      final summary = engine.summarizeMonth(policy, calendar, [], 2026, 9, now);
      expect(summary.periodLabel, 'Not started');
    });

    test('No attendance marked yet shows 0% and month name', () {
      final summary = engine.summarizeMonth(policy, calendar, [], 2026, 8, now);
      expect(summary.periodLabel, 'August');
      expect(summary.percent, 0.0);
      expect(summary.conductedToDate, 14.0);
    });

    test('Hours basis works correctly', () {
      final hourPolicy = _makePolicy(basis: CalculationBasis.hours, full: 8);
      final records = [_makeRecord(DateTime(2026, 8, 3), AttendanceStatus.half, 4, 8)];
      final summary = engine.summarizeMonth(hourPolicy, calendar, records, 2026, 8, now);
      expect(summary.actual, 4.0);
      // 14 working days * 8 hours = 112.0
      expect(summary.conductedToDate, 112.0);
      expect(summary.percent, closeTo(3.57, 0.1));
    });
  });

  group('Future Attendance Write Rejection', () {
    test('AttendanceController rejects future dates', () async {
      final repo = MockAttendanceRepository();
      when(() => repo.watchRecords()).thenAnswer((_) => Stream.value([]));
      
      final policy = _makePolicy();
      final calendar = AttendanceCalendar.unconfigured;
      final controller = AttendanceController(repo, engine, policy, calendar);
      
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await controller.mark(AttendanceStatus.full, date: tomorrow);
      
      verifyNever(() => repo.save(any()));
    });
  });
  
  group('Isolation Check', () {
    test('SummarizeMonth does not change Dashboard summary', () {
      final semesterPolicy = _makePolicy(period: EvaluationPeriod.semester, start: DateTime(2026, 7, 1), end: DateTime(2026, 12, 31));
      final calendar = AttendanceCalendar(id: 'c', version: 1, effectiveFrom: DateTime(2026, 1, 1), weeklyOffs: [7], isConfigured: true);
      final now = DateTime(2026, 8, 17);
      final records = [
        _makeRecord(DateTime(2026, 7, 1), AttendanceStatus.full, 1, 1),
      ];
      
      final dashboardSummary = engine.summarize(semesterPolicy, calendar, records, now);
      final augustSummary = engine.summarizeMonth(semesterPolicy, calendar, records, 2026, 8, now);
      
      expect(dashboardSummary.periodLabel, 'Current Semester');
      expect(dashboardSummary.actual, 1.0);
      expect(augustSummary.periodLabel, 'August');
      expect(augustSummary.actual, 0.0);
    });
  });
}

AttendancePolicy _makePolicy({
  CalculationBasis basis = CalculationBasis.days,
  double full = 1,
  double? min = 75,
  EvaluationPeriod period = EvaluationPeriod.monthly,
  DateTime? start,
  DateTime? end,
}) => AttendancePolicy(
  id: 'test-policy',
  version: 1,
  effectiveFrom: DateTime(2026, 1, 1),
  state: PolicyState.official,
  evaluationPeriod: period,
  minimumPercent: min,
  basis: basis,
  fullUnit: full,
  halfUnit: full / 2,
  startDate: start,
  endDate: end,
);

AttendanceRecord _makeRecord(DateTime date, AttendanceStatus status, double actual, double expected) => 
  AttendanceRecord(date: date, status: status, actualUnits: actual, expectedUnits: expected);
