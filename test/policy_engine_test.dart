import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();

  group('PolicyEngine Unit Combinations', () {
    test('Calculates by Hours correctly', () {
      final policy = _makePolicy(basis: CalculationBasis.hours, full: 8, min: 75);
      final now = DateTime(2026, 1, 10);
      final records = [
        _makeRecord(DateTime(2026, 1, 1), AttendanceStatus.full, 8, 8),
        _makeRecord(DateTime(2026, 1, 2), AttendanceStatus.half, 4, 8),
      ];
      final summary = engine.summarize(policy, records, now);
      expect(summary.actual, 12.0);
      expect(summary.expected, 16.0);
      expect(summary.percent, 75.0);
      expect(summary.isSafe, isTrue);
    });

    test('Calculates by Days correctly', () {
      final policy = _makePolicy(basis: CalculationBasis.days, full: 1, min: 80);
      final now = DateTime(2026, 1, 10);
      final records = [
        _makeRecord(DateTime(2026, 1, 1), AttendanceStatus.full, 1, 1),
        _makeRecord(DateTime(2026, 1, 2), AttendanceStatus.absent, 0, 1),
        _makeRecord(DateTime(2026, 1, 3), AttendanceStatus.full, 1, 1),
      ];
      final summary = engine.summarize(policy, records, now);
      expect(summary.actual, 2.0);
      expect(summary.expected, 3.0);
      expect(summary.percent, closeTo(66.66, 0.1));
      expect(summary.isSafe, isFalse);
    });
  });

  group('Prospective Safe-to-Miss & Recovery', () {
    test('Safe-to-miss accounts for future capacity', () {
      final policy = _makePolicy(min: 75, full: 8, weeklyOffs: [7]);
      final now = DateTime(2026, 1, 15);
      final records = List.generate(14, (i) {
        final date = DateTime(2026, 1, i + 1);
        final isSun = date.weekday == 7;
        return _makeRecord(date, isSun ? AttendanceStatus.weeklyOff : AttendanceStatus.full, isSun ? 0 : 8, isSun ? 0 : 8);
      });

      final summary = engine.summarize(policy, records, now, isHolidayCalendarConfigured: true);
      expect(summary.totalExpectedInPeriod, 216.0);
      expect(summary.safeToMiss, 54.0);
      expect(summary.isEstimation, isFalse);
    });

    test('Recovery calculates units needed immediately', () {
      final policy = _makePolicy(min: 80, full: 8);
      final now = DateTime(2026, 1, 2);
      final records = [_makeRecord(DateTime(2026, 1, 1), AttendanceStatus.absent, 0, 8)];
      
      final summary = engine.summarize(policy, records, now);
      expect(summary.unitsToRecover, closeTo(32.0, 0.0001));
      expect(summary.recoveryMessage, 'Attend the next 32 hours');
    });

    test('Recovery message uses correct units', () {
      final policy = _makePolicy(min: 80, full: 1, basis: CalculationBasis.days);
      final now = DateTime(2026, 1, 2);
      final records = [_makeRecord(DateTime(2026, 1, 1), AttendanceStatus.absent, 0, 1)];
      
      final summary = engine.summarize(policy, records, now);
      expect(summary.recoveryMessage, 'Attend the next 4 working days');
    });
  });

  group('Evaluation Periods & Explicit Dates', () {
    test('Custom semester dates work correctly', () {
      final policy = _makePolicy(
        period: EvaluationPeriod.semester,
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 5, 31),
      );
      final now = DateTime(2026, 3, 15);
      final summary = engine.summarize(policy, [], now);
      expect(summary.isPolicyIncomplete, isFalse);
      expect(summary.periodLabel, 'Current Semester');
    });

    test('Missing semester dates return incomplete', () {
      final policy = _makePolicy(period: EvaluationPeriod.semester, start: null, end: null);
      final summary = engine.summarize(policy, [], DateTime(2026, 1, 15));
      expect(summary.isPolicyIncomplete, isTrue);
      expect(summary.periodLabel, 'Incomplete Period');
    });
  });

  group('Holiday Awareness & Estimation', () {
    test('Projections marked as estimation when calendar is incomplete', () {
      final policy = _makePolicy(min: 75);
      final summary = engine.summarize(policy, [], DateTime(2026, 1, 15), isHolidayCalendarConfigured: false);
      expect(summary.isEstimation, isTrue);
    });

    test('Percentage still available when projections are estimated', () {
      final policy = _makePolicy(min: 75, full: 8);
      final records = [_makeRecord(DateTime(2026, 1, 1), AttendanceStatus.full, 8, 8)];
      final summary = engine.summarize(policy, records, DateTime(2026, 1, 2), isHolidayCalendarConfigured: false);
      expect(summary.percent, 100.0);
      expect(summary.isEstimation, isTrue);
    });
  });
}

AttendancePolicy _makePolicy({
  CalculationBasis basis = CalculationBasis.hours,
  double full = 8,
  double? min = 75,
  List<int> weeklyOffs = const [7],
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
  weeklyOffs: weeklyOffs,
  startDate: start,
  endDate: end,
);

AttendanceRecord _makeRecord(DateTime date, AttendanceStatus status, double actual, double expected) => 
  AttendanceRecord(date: date, status: status, actualUnits: actual, expectedUnits: expected);
