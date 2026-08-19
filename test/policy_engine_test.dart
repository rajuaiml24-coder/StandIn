import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();

  group('PolicyEngine Unit Combinations', () {
    test('Calculates by Hours correctly', () {
      final policy = _makePolicy(basis: CalculationBasis.hours, full: 8, min: 75);
      final calendar = AttendanceCalendar(id: 'c', version: 1, effectiveFrom: DateTime(2026, 1, 1), weeklyOffs: [6, 7], isConfigured: true);
      final now = DateTime(2026, 1, 2); // Friday
      final records = [
        _makeRecord(DateTime(2026, 1, 1), AttendanceStatus.full, 8, 8),
        _makeRecord(DateTime(2026, 1, 2), AttendanceStatus.half, 4, 8),
      ];
      final summary = engine.summarize(policy, calendar, records, now);
      expect(summary.actual, 12.0);
      expect(summary.conductedToDate, 16.0);
      expect(summary.percent, 75.0);
    });
  });

  group('Prospective Safe-to-Miss & Recovery', () {
    test('Safe-to-miss accounts for full period capacity', () {
      final policy = _makePolicy(min: 75, full: 8);
      final calendar = AttendanceCalendar(id: 'c', version: 1, effectiveFrom: DateTime(2026, 1, 1), weeklyOffs: [7], isConfigured: true);
      final now = DateTime(2026, 1, 15);
      // Jan 2026 has 27 working days. Total Conducted = 216.
      final records = List.generate(14, (i) {
        final date = DateTime(2026, 1, i + 1);
        final isSun = date.weekday == 7;
        return _makeRecord(date, isSun ? AttendanceStatus.weeklyOff : AttendanceStatus.full, isSun ? 0 : 8, isSun ? 0 : 8);
      });

      final summary = engine.summarize(policy, calendar, records, now, isHolidayCalendarConfigured: true);
      expect(summary.totalExpectedInPeriod, 216.0);
      expect(summary.safeToMiss, 54.0);
    });
  });

  group('Dashboard Unit Consistency (DAYS, HOURS, CLASSES)', () {
    final augustStart = DateTime(2026, 8, 1);
    final calendar = AttendanceCalendar(
      id: 'aug-2026',
      version: 1,
      effectiveFrom: augustStart,
      weeklyOffs: [7], // Sundays off
      isConfigured: true,
    );
    // Aug 17 is a Monday. 14 working days elapsed (1-17 excluding Sundays 2, 9, 16).
    final now = DateTime(2026, 8, 17);

    test('DAYS basis: 14/14 present, 75% target, verifies 6 day recovery', () {
      final policy = AttendancePolicy(
        id: 'p-days', version: 1, effectiveFrom: augustStart, state: PolicyState.official,
        evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.days,
        fullUnit: 1.0, halfUnit: 0.5, minimumPercent: 75,
      );
      final records = List.generate(17, (i) {
        final date = augustStart.add(Duration(days: i));
        if (calendar.isNonWorkingDay(date)) return null;
        return _makeRecord(date, AttendanceStatus.full, 1.0, 1.0);
      }).whereType<AttendanceRecord>().toList();

      final summary = engine.summarize(policy, calendar, records, now);
      
      // Total working days in Aug 2026: 31 days - 5 Sundays = 26.
      expect(summary.totalConducted, 26.0);
      expect(summary.actual, 14.0);
      expect(summary.percent, 100.0);
      expect(summary.progressLabel, '14 of 14 working days so far');
      
      // Required = 26 * 0.75 = 19.5 days.
      // Recover = 19.5 - 14 = 5.5 days. 
      // UI should show ceiling: 6 days.
      expect(summary.recoveryMessage, contains('Attend 6 more days'));
    });

    test('HOURS basis: 14/14 present (8h/day), 75% target, verifies 44 hour recovery', () {
      final policy = AttendancePolicy(
        id: 'p-hours', version: 1, effectiveFrom: augustStart, state: PolicyState.official,
        evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.hours,
        fullUnit: 8.0, halfUnit: 4.0, minimumPercent: 75,
      );
      final records = List.generate(17, (i) {
        final date = augustStart.add(Duration(days: i));
        if (calendar.isNonWorkingDay(date)) return null;
        return _makeRecord(date, AttendanceStatus.full, 8.0, 8.0);
      }).whereType<AttendanceRecord>().toList();

      final summary = engine.summarize(policy, calendar, records, now);
      
      // Total: 26 * 8 = 208. Required: 156. Actual: 14 * 8 = 112.
      // Recover: 156 - 112 = 44.
      expect(summary.actual, 112.0);
      expect(summary.percent, 100.0);
      expect(summary.progressLabel, '112 of 112 hours so far');
      expect(summary.recoveryMessage, contains('Attend 44 more hours'));
    });

    test('CLASSES basis: 14/14 present (6c/day), 75% target, verifies 33 class recovery', () {
      final policy = AttendancePolicy(
        id: 'p-classes', version: 1, effectiveFrom: augustStart, state: PolicyState.official,
        evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.periods,
        fullUnit: 6.0, halfUnit: 3.0, minimumPercent: 75,
      );
      final records = List.generate(17, (i) {
        final date = augustStart.add(Duration(days: i));
        if (calendar.isNonWorkingDay(date)) return null;
        return _makeRecord(date, AttendanceStatus.full, 6.0, 6.0);
      }).whereType<AttendanceRecord>().toList();

      final summary = engine.summarize(policy, calendar, records, now);
      
      // Total: 26 * 6 = 156. Required: 117. Actual: 14 * 6 = 84.
      // Recover: 117 - 84 = 33.
      expect(summary.actual, 84.0);
      expect(summary.progressLabel, '84 of 84 classes so far');
      expect(summary.recoveryMessage, contains('Attend 33 more classes'));
    });
  });

  group('Dashboard Hero Achievability Scenarios (85% Target)', () {
    final augustStart = DateTime(2026, 8, 1);
    final calendar = AttendanceCalendar(
      id: 'aug-2026', version: 1, effectiveFrom: augustStart, 
      weeklyOffs: [7], isConfigured: true,
    );
    final now = DateTime(2026, 8, 17);

    test('Scenario 1: ON TRACK (17 attended, 9 remaining)', () {
      final policy = _makePolicy(min: 85, basis: CalculationBasis.days, full: 1.0);
      
      // We need 17 working days to have occurred. 
      // Aug 20 is the 17th working day (1, 3-8, 10-15, 17-20).
      final nowAug20 = DateTime(2026, 8, 20);
      final records = <AttendanceRecord>[];
      int count = 0;
      for (int i = 0; i < 31 && count < 17; i++) {
        final d = DateTime(2026, 8, i + 1);
        if (!calendar.isNonWorkingDay(d)) {
          records.add(_makeRecord(d, AttendanceStatus.full, 1.0, 1.0));
          count++;
        }
      }

      final summary = engine.summarize(policy, calendar, records, nowAug20);
      
      expect(summary.totalConducted, 26.0);
      expect(summary.actual, 17.0);
      expect(summary.status, PeriodStatus.onTrack);
      expect(summary.recoveryMessage, contains('Attend 6 more days'));
    });

    test('Scenario 2: AT RISK (8 attended, 15 remaining capacity total)', () {
      final policy = _makePolicy(min: 85, basis: CalculationBasis.days, full: 1.0);
      
      final records = <AttendanceRecord>[];
      int fullCount = 0;
      int absentCount = 0;
      for (int i = 0; i < 31; i++) {
        final d = augustStart.add(Duration(days: i));
        if (!calendar.isNonWorkingDay(d) && d.isBefore(DateTime(2026, 8, 18))) {
          if (fullCount < 8) {
            records.add(_makeRecord(d, AttendanceStatus.full, 1.0, 1.0));
            fullCount++;
          } else if (absentCount < 3) {
            records.add(_makeRecord(d, AttendanceStatus.absent, 0.0, 1.0));
            absentCount++;
          }
        }
      }
      
      final summary = engine.summarize(policy, calendar, records, now);
      // Gap 14.1. Capacity 15 (12 future + 3 unmarked).
      // 14.1 / 15 = 0.94.
      expect(summary.status, PeriodStatus.atRisk);
    });

    test('Scenario 3: IMPOSSIBLE (8 attended, 9 remaining)', () {
      final policy = _makePolicy(min: 85, basis: CalculationBasis.days, full: 1.0);
      
      final records = <AttendanceRecord>[];
      int fullCount = 0;
      for (int i = 0; i < 31; i++) {
        final d = augustStart.add(Duration(days: i));
        if (!calendar.isNonWorkingDay(d) && d.isBefore(DateTime(2026, 8, 18))) {
          if (fullCount < 8) {
            records.add(_makeRecord(d, AttendanceStatus.full, 1.0, 1.0));
            fullCount++;
          } else {
            records.add(_makeRecord(d, AttendanceStatus.absent, 0.0, 1.0));
          }
        }
      }
      
      final summary = engine.summarize(policy, calendar, records, now); 
      expect(summary.status, PeriodStatus.impossible);
      expect(summary.recoveryMessage, contains('Target no longer achievable'));
    });

    test('Scenario 4: ALREADY SAFE', () {
      final policy = _makePolicy(min: 50, basis: CalculationBasis.days, full: 1.0);
      final records = <AttendanceRecord>[];
      int count = 0;
      for (int i = 0; i < 31 && count < 14; i++) {
        final d = DateTime(2026, 8, i + 1);
        if (!calendar.isNonWorkingDay(d)) {
          records.add(_makeRecord(d, AttendanceStatus.full, 1.0, 1.0));
          count++;
        }
      }

      final summary = engine.summarize(policy, calendar, records, now);
      expect(summary.status, PeriodStatus.onTrack);
      expect(summary.isSafe, true);
    });
  });
}

AttendancePolicy _makePolicy({
  CalculationBasis basis = CalculationBasis.hours,
  double full = 8,
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
