import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  const engine = PolicyEngine();
  
  // Configuration from user
  final policy = AttendancePolicy(
    id: 'test-policy',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    state: PolicyState.official,
    evaluationPeriod: EvaluationPeriod.monthly,
    basis: CalculationBasis.hours,
    fullUnit: 7.0,
    halfUnit: 3.5,
    minimumPercent: 75,
    weeklyOffs: [7], // Sunday only as per "Saturday: Working"
  );

  final calendar = AttendanceCalendar(
    id: 'test-cal',
    version: 1,
    effectiveFrom: DateTime(2026, 8, 1),
    weeklyOffs: [7],
    saturdayPattern: SaturdayPattern.everyWorking,
    isConfigured: true,
  );

  // Simulation: Today is Aug 14, 2026
  final now = DateTime(2026, 8, 14);

  // Let's assume the user has marked some records.
  // User said "marked several days Absent". 
  // But to get 180% they must have marked some "Full" or "Present" too?
  // Or maybe duplicates?
  
  final records = [
    // Past working days
    AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 4), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 5), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 6), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 7), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 10), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 11), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 12), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 13), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 14), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    
    // Future working days?
    AttendanceRecord(date: DateTime(2026, 8, 17), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 18), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
  ];

  print('--- Policy Engine Trace ---');
  final summary = engine.summarize(policy, calendar, records, now);
  
  print('1. Period: ${policy.evaluationPeriod.name}');
  print('2. Now: $now');
  print('3. A (Actual Attended): ${summary.actual}');
  print('4. Cd (Conducted to Date): ${summary.conductedToDate}');
  print('5. Ct (Total Conducted): ${summary.totalConducted}');
  print('6. F (Future Capacity): ${summary.totalConducted - summary.conductedToDate}');
  print('7. M (Maximum Possible): ${summary.maximumPossible}');
  print('8. Current %: ${summary.percent}%');
  print('9. Safe-to-Miss: ${summary.safeToMiss}');
  print('10. Required Units (R): ${summary.totalConducted * 0.75}');
  
  print('\n--- Record Count Verification ---');
  Map<String, int> dateCounts = {};
  for (var r in records) {
    String d = r.date.toIso8601String().substring(0, 10);
    dateCounts[d] = (dateCounts[d] ?? 0) + 1;
  }
  dateCounts.forEach((date, count) {
    if (count > 1) print('DUPLICATE FOUND for $date: $count times');
  });
}
