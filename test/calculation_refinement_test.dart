import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();
  final now = DateTime(2026, 8, 14); // Friday

  group('Scenario A: Employee - Hours + Monthly (Safe)', () {
    final policy = AttendancePolicy(
      id: 'emp-hours-monthly',
      version: 1,
      effectiveFrom: DateTime(2026, 8, 1),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.monthly,
      basis: CalculationBasis.hours,
      fullUnit: 8.0,
      halfUnit: 4.0,
      minimumPercent: 75,
    );
    final calendar = AttendanceCalendar(
      id: 'c1', 
      version: 1, 
      effectiveFrom: DateTime(2026, 8, 1), 
      weeklyOffs: [7], // Sunday only, Saturday working
      isConfigured: true
    );

    test('Calculates 100% attendance correctly', () {
      final records = List.generate(14, (i) {
        final date = DateTime(2026, 8, i + 1);
        final isOff = calendar.isOffDay(date);
        return AttendanceRecord(
          date: date,
          status: isOff ? AttendanceStatus.weeklyOff : AttendanceStatus.full, 
          actualUnits: isOff ? 0.0 : 8.0, 
          expectedUnits: isOff ? 0.0 : 8.0,
        );
      });
      final summary = engine.summarize(policy, calendar, records, now);
      
      // Aug 2026 Saturdays: 1, 8. 
      // Aug 2026 Sundays: 2, 9. (Off)
      // Aug 2026 Working thru 14th: 1, 3-8, 10-14. Total = 1 + 6 + 5 = 12 days.
      expect(summary.actual, 12 * 8.0);
      expect(summary.conductedToDate, 12 * 8.0);
      expect(summary.percent, 100.0);
      expect(summary.periodLabel, 'August');
    });

    test('Prevents inflation from future records and duplicates', () {
      // Aug 3 is Monday. Aug 20 is future.
      final records = [
        AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0),
        AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0), // DUPLICATE
        AttendanceRecord(date: DateTime(2026, 8, 20), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0), // FUTURE
      ];
      final summary = engine.summarize(policy, calendar, records, now);
      
      expect(summary.actual, 8.0);
      expect(summary.conductedToDate, 96.0);
      expect(summary.percent, closeTo(8.33, 0.01));
      
      // Total working days in Aug 2026 (Mon-Sat): 26 days.
      // Ct = 26 * 8 = 208.0.
      expect(summary.totalConducted, 208.0);
      expect(summary.maximumPossible, 208.0);
    });

    test('All days Present scenario', () {
      // Generate records up to "now" (Aug 14)
      final records = List.generate(14, (i) {
        final date = DateTime(2026, 8, i + 1);
        if (calendar.isOffDay(date)) return null;
        return AttendanceRecord(date: date, status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0);
      }).whereType<AttendanceRecord>().toList();

      final summary = engine.summarize(policy, calendar, records, now);
      expect(summary.percent, 100.0);
      expect(summary.conductedToDate, summary.actual);
    });

    test('All days Unmarked scenario', () {
      final summary = engine.summarize(policy, calendar, [], now);
      expect(summary.actual, 0.0);
      expect(summary.conductedToDate, 96.0);
      expect(summary.percent, 0.0);
      expect(summary.unmarkedCount, 12);
    });

    test('Some Present, Some Absent, Some Unmarked', () {
      final records = [
        AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0),
        AttendanceRecord(date: DateTime(2026, 8, 4), status: AttendanceStatus.absent, actualUnits: 0.0, expectedUnits: 8.0),
      ];
      final summary = engine.summarize(policy, calendar, records, now);
      
      // 12 working days. 1 full, 1 absent, 10 unmarked.
      // Actual = 8. Conducted = 12 * 8 = 96.
      expect(summary.actual, 8.0);
      expect(summary.conductedToDate, 96.0);
      expect(summary.percent, closeTo(8.33, 0.01));
      expect(summary.unmarkedCount, 10);
    });
  });

  group('Saturday Patterns', () {
    final policy = AttendancePolicy(
      id: 'sat-test', version: 1, effectiveFrom: DateTime(2026, 8, 1), 
      state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly,
      basis: CalculationBasis.days, fullUnit: 1.0, halfUnit: 0.5, minimumPercent: 75,
    );

    test('2nd & 4th Saturday Off works correctly', () {
      final calendar = AttendanceCalendar(
        id: 'c-sat', version: 1, effectiveFrom: DateTime(2026, 8, 1), 
        weeklyOffs: [7], // Sunday only
        offSaturdays: [2, 4],
        isConfigured: true,
      );

      // Aug 2026 Saturdays: 1, 8, 15, 22, 29.
      // 2nd is 8, 4th is 22.
      expect(calendar.isOffDay(DateTime(2026, 8, 1)), isFalse);
      expect(calendar.isOffDay(DateTime(2026, 8, 8)), isTrue);
      expect(calendar.isOffDay(DateTime(2026, 8, 15)), isFalse);
      expect(calendar.isOffDay(DateTime(2026, 8, 22)), isTrue);
      expect(calendar.isOffDay(DateTime(2026, 8, 29)), isFalse);
      
      final summary = engine.summarize(policy, calendar, [], now);
      // Total days in Aug = 31. 
      // Sundays (2, 9, 16, 23, 30) = 5.
      // 2nd/4th Sat (8, 22) = 2.
      // Total Off = 7.
      // Total Conducted = 31 - 7 = 24.
      expect(summary.totalConducted, 24.0);
    });
  });

  group('Scenario G: Unconfigured Calendar', () {
    final policy = AttendancePolicy(
      id: 'no-cal-policy',
      version: 1,
      effectiveFrom: DateTime(2026, 8, 1),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.monthly,
      basis: CalculationBasis.days,
      fullUnit: 1.0,
      halfUnit: 0.5,
      minimumPercent: 75,
    );
    final calendar = AttendanceCalendar.unconfigured;

    test('Projections marked as Estimated', () {
      final summary = engine.summarize(policy, calendar, [], now);
      expect(summary.isEstimation, isTrue);
    });
  });
}
