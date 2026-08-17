import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();
  
  // 1. Setup Semester Policy
  final startDate = DateTime(2026, 8, 1);
  final endDate = DateTime(2026, 11, 30);
  
  final policy = AttendancePolicy(
    id: 'sem-policy',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    state: PolicyState.official,
    evaluationPeriod: EvaluationPeriod.semester,
    basis: CalculationBasis.periods, // Classes
    fullUnit: 1.0,
    halfUnit: 0.5,
    minimumPercent: 75,
    startDate: startDate,
    endDate: endDate,
  );

  final calendar = AttendanceCalendar(
    id: 'cal-1',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    weeklyOffs: [7], // Sunday off
    isConfigured: true,
  );

  // Today is Aug 15, 2026
  final now = DateTime(2026, 8, 15);

  // 2. Mock Attendance Records
  final records = [
    // Should be included (Inside semester)
    AttendanceRecord(
      date: DateTime(2026, 8, 3), 
      status: AttendanceStatus.full, 
      actualUnits: 1.0, 
      expectedUnits: 1.0
    ),
    AttendanceRecord(
      date: DateTime(2026, 8, 4), 
      status: AttendanceStatus.full, 
      actualUnits: 1.0, 
      expectedUnits: 1.0
    ),
    // Should be excluded (Before semester - though technically unlikely in real use)
    AttendanceRecord(
      date: DateTime(2026, 7, 30), 
      status: AttendanceStatus.full, 
      actualUnits: 1.0, 
      expectedUnits: 1.0
    ),
  ];

  print('--- Semester Audit ---');
  final summary = engine.summarize(policy, calendar, records, now);
  
  print('Period Label: ${summary.periodLabel}');
  print('Actual (A): ${summary.actual}');
  print('Conducted to Date (Cd): ${summary.conductedToDate}');
  print('Total Conducted (Ct): ${summary.totalConducted}');
  print('Current %: ${summary.percent}%');
  print('Unmarked Count: ${summary.unmarkedCount}');
  print('Maximum Possible (M): ${summary.maximumPossible}');
  print('Is Policy Incomplete: ${summary.isPolicyIncomplete}');

  // Manual Check
  // Aug 1 (Sat) to Aug 15 (Sat)
  // Sundays: Aug 2, 9. (2 days)
  // Working days passed: 15 - 2 = 13 days.
  // Records: Aug 3, 4 (2 records)
  // A = 2.0
  // Cd = 13 * 1.0 = 13.0
  // % = 2/13 = 15.38%
  
  print('\nExpected Cd: 13.0');
  print('Expected A: 2.0');
}
