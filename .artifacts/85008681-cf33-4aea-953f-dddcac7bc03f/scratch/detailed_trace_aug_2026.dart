import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();
  
  final policy = AttendancePolicy(
    id: 'trace-policy',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    state: PolicyState.official,
    evaluationPeriod: EvaluationPeriod.monthly,
    basis: CalculationBasis.hours,
    fullUnit: 7.0,
    halfUnit: 3.5,
    minimumPercent: 75,
    weeklyOffs: [7], // Sunday off, Saturday working
  );

  final calendar = AttendanceCalendar(
    id: 'trace-cal',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    weeklyOffs: [7],
    saturdayPattern: SaturdayPattern.everyWorking,
    isConfigured: true,
  );

  // Today is Aug 14, 2026 (Friday)
  final now = DateTime(2026, 8, 14);

  // Creating a scenario that might lead to >100%
  // 1. Future records
  // 2. Duplicate records for same day (different scopeIds)
  final records = [
    // Past working days
    AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope1'),
    AttendanceRecord(date: DateTime(2026, 8, 4), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope1'),
    
    // DUPLICATE for Aug 5
    AttendanceRecord(date: DateTime(2026, 8, 5), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope1'),
    AttendanceRecord(date: DateTime(2026, 8, 5), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope2'),
    
    // Future records
    AttendanceRecord(date: DateTime(2026, 8, 17), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope1'),
    AttendanceRecord(date: DateTime(2026, 8, 18), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0, scopeId: 'scope1'),
  ];

  print('--- Policy Engine Trace: August 2026 ---');
  final summary = engine.summarize(policy, calendar, records, now);
  
  print('1. Now: $now');
  print('2. Actual Attended (A): ${summary.actual}');
  print('3. Conducted to Date (Cd): ${summary.conductedToDate}');
  print('4. Total Conducted (Ct): ${summary.totalConducted}');
  print('5. Current %: ${summary.percent}%');
  print('6. Maximum Possible (M): ${summary.maximumPossible}');
  print('7. Unmarked Count: ${summary.unmarkedCount}');
  print('8. Required Units (R): ${summary.totalConducted * 0.75}');
  print('9. Safe to Miss: ${summary.safeToMiss}');

  double sumActual = 0;
  for (var r in records) sumActual += r.actualUnits;
  print('\nSum of ALL actualUnits in input: $sumActual');
  
  // Checking Cd calculation
  // Aug 1 (Sat) - Working
  // Aug 2 (Sun) - Off
  // Aug 3-8 (Mon-Sat) - Working (6)
  // Aug 9 (Sun) - Off
  // Aug 10-14 (Mon-Fri) - Working (5)
  // Total = 1 + 6 + 5 = 12 days. 12 * 7 = 84.
  print('Manual Cd calc: 12 days * 7h = 84.0');
}
