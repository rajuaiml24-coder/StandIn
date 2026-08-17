import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();
  final now = DateTime(2026, 8, 14); // Friday

  group('Scenario A: Employee - Hours + Monthly', () {
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
      weeklyOffs: [6, 7], // Sat, Sun
    );

    test('Calculates 100% attendance correctly', () {
      final records = [
        AttendanceRecord(date: DateTime(2026, 8, 10), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0),
        AttendanceRecord(date: DateTime(2026, 8, 11), status: AttendanceStatus.full, actualUnits: 8.0, expectedUnits: 8.0),
      ];
      final summary = engine.summarize(policy, records, now);
      
      expect(summary.actual, 16.0);
      expect(summary.expected, 16.0);
      expect(summary.percent, 100.0);
      expect(summary.periodLabel, 'August');
    });

    test('Calculates safeToMiss correctly', () {
      // August 2026 has 21 working days (Mon-Fri).
      // Total Expected = 21 * 8 = 168 hours.
      // Required (75%) = 126 hours.
      // If worked 10 days full (80 hours), remaining expected = 11 days (88 hours).
      // Total Capacity = 80 + 88 = 168.
      // Safe to miss = 168 - 126 = 42 hours.
      
      final records = List.generate(10, (i) => AttendanceRecord(
        date: DateTime(2026, 8, i + 3), // Aug 3 (Mon) to Aug 12
        status: AttendanceStatus.full, 
        actualUnits: 8.0, 
        expectedUnits: 8.0,
      )).where((r) => r.date.weekday < 6).toList();

      final summary = engine.summarize(policy, records, now);
      expect(summary.actual, 64.0); // 8 days * 8h (Aug 3-7, 10-12)
      expect(summary.expected, 64.0);
      
      // Future working days from Aug 14 to Aug 31:
      // 14 (Fri), 17-21 (5), 24-28 (5), 31 (Mon) = 12 days.
      // Future Expected = 12 * 8 = 96.
      // Total expected = 64 + 96 = 160 (August 2026 actually has 21 working days. Aug 1, 2 are Sat/Sun).
      // Required = 160 * 0.75 = 120.
      // Remaining to attend = 120 - 64 = 56.
      // Safe to miss = 96 - 56 = 40 hours.
      expect(summary.safeToMiss, 40.0);
    });
  });

  group('Scenario B: Employee - Hours + Quarterly', () {
    final policy = AttendancePolicy(
      id: 'emp-hours-q3',
      version: 1,
      effectiveFrom: DateTime(2026, 7, 1),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.quarterly,
      basis: CalculationBasis.hours,
      fullUnit: 8.0,
      halfUnit: 4.0,
      minimumPercent: 75,
      weeklyOffs: [7], // Sunday only
    );

    test('Primary calculation uses quarter range', () {
      final summary = engine.summarize(policy, [], now);
      expect(summary.periodLabel, 'Quarter 3');
      // Q3 (July, Aug, Sep) is 92 days.
      // Sundays in Q3 2026: 13.
      // Working days = 79.
      // Expected = 79 * 8 = 632.
      expect(summary.totalExpectedInPeriod, 632.0);
    });
  });

  group('Scenario C: Student - Classes + Semester', () {
    final policy = AttendancePolicy(
      id: 'student-classes-s1',
      version: 1,
      effectiveFrom: DateTime(2026, 8, 1),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.semester,
      basis: CalculationBasis.periods,
      fullUnit: 4.0, // 4 classes per day
      halfUnit: 2.0,
      minimumPercent: 75,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 11, 30),
      weeklyOffs: [7],
    );

    test('Calculates unitsToRecover correctly', () {
      // Aug 3-7 (5 days): Expected 20 classes.
      // Attended 10 classes.
      // Current % = 50%.
      // Formula: ((0.75 * 20) - 10) / (1 - 0.75) = (15 - 10) / 0.25 = 5 / 0.25 = 20 classes.
      final records = List.generate(5, (i) => AttendanceRecord(
        date: DateTime(2026, 8, i + 3),
        status: AttendanceStatus.half, 
        actualUnits: 2.0, 
        expectedUnits: 4.0,
      ));

      final summary = engine.summarize(policy, records, now);
      expect(summary.percent, 50.0);
      expect(summary.unitsToRecover, 20.0);
      expect(summary.recoveryMessage, 'Attend the next 20 classes');
    });
  });

  group('Scenario F: Missing Target', () {
    final policy = AttendancePolicy(
      id: 'no-target',
      version: 1,
      effectiveFrom: DateTime(2026, 8, 1),
      state: PolicyState.personal,
      evaluationPeriod: EvaluationPeriod.monthly,
      basis: CalculationBasis.days,
      fullUnit: 1.0,
      halfUnit: 0.5,
      minimumPercent: null,
    );

    test('Shows history but hides projections', () {
      final records = [
        AttendanceRecord(date: DateTime(2026, 8, 10), status: AttendanceStatus.full, actualUnits: 1.0, expectedUnits: 1.0),
      ];
      final summary = engine.summarize(policy, records, now);
      expect(summary.percent, 100.0);
      expect(summary.isPolicyIncomplete, true);
      expect(summary.safeToMiss, 0);
      expect(summary.unitsToRecover, 0);
    });
  });

  group('Scenario G: Missing Holiday Calendar', () {
    test('Projections marked as Estimated', () {
      final policy = AttendancePolicy(
        id: 'est-test',
        version: 1,
        effectiveFrom: DateTime(2026, 8, 1),
        state: PolicyState.official,
        evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.days,
        fullUnit: 1.0,
        halfUnit: 0.5,
        minimumPercent: 75,
      );
      final summary = engine.summarize(policy, [], now, isHolidayCalendarConfigured: false);
      expect(summary.isEstimation, true);
    });
  });
}
