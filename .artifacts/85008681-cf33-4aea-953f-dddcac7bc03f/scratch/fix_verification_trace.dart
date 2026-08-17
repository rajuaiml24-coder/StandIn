import 'package:standin/src/domain/attendance.dart';

// Mocking refined summarize logic
Map<String, dynamic> refinedSummarize(AttendancePolicy policy, AttendanceCalendar calendar, List<AttendanceRecord> records, DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0);

  // 1. Filter records for this month
  final periodRecords = records.where((r) => !r.date.isBefore(start) && !r.date.isAfter(end)).toList();

  // 2. Deduplicate records by date (Authoritative record per day)
  final Map<String, AttendanceRecord> dailyRecords = {};
  for (var r in periodRecords) {
    final key = r.date.toIso8601String().substring(0, 10);
    // Overwrite with latest/first - ideally repository prevents this, but engine should be safe
    dailyRecords[key] = r; 
  }

  double actualPastAndToday = 0;
  double unmarkedUnits = 0;
  int unmarkedCount = 0;
  double conductedToDate = 0;
  double futureCapacity = 0;
  double totalConducted = 0;

  DateTime current = start;
  while (!current.isAfter(end)) {
    final key = current.toIso8601String().substring(0, 10);
    final record = dailyRecords[key];
    final isNonWorking = calendar.isNonWorkingDay(current);

    if (current.isAfter(todayStart)) {
      // Future
      if (!isNonWorking) {
        totalConducted += policy.fullUnit;
        futureCapacity += policy.fullUnit;
      }
    } else {
      // Past or Today
      if (record != null) {
        actualPastAndToday += record.actualUnits;
        conductedToDate += record.expectedUnits;
        totalConducted += record.expectedUnits;
      } else if (!isNonWorking) {
        unmarkedUnits += policy.fullUnit;
        unmarkedCount++;
        conductedToDate += policy.fullUnit;
        totalConducted += policy.fullUnit;
      } else {
        // Non-working day without record: totalConducted doesn't increase
      }
    }
    current = current.add(const Duration(days: 1));
  }

  final percent = conductedToDate == 0 ? 0.0 : (actualPastAndToday / conductedToDate * 100);
  final maximumPossible = actualPastAndToday + unmarkedUnits + futureCapacity;

  return {
    'actual': actualPastAndToday,
    'conductedToDate': conductedToDate,
    'totalConducted': totalConducted,
    'percent': percent,
    'maximumPossible': maximumPossible,
    'unmarkedCount': unmarkedCount,
  };
}

void main() {
  final policy = AttendancePolicy(
    id: 'p', version: 1, effectiveFrom: DateTime(2026, 8, 1), 
    state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly, 
    basis: CalculationBasis.hours, fullUnit: 7.0, halfUnit: 3.5, minimumPercent: 75,
    weeklyOffs: [7],
  );
  final calendar = AttendanceCalendar(
    id: 'c', version: 1, effectiveFrom: DateTime(2026, 8, 1), 
    weeklyOffs: [7], isConfigured: true,
  );
  final now = DateTime(2026, 8, 14);

  // Scenario: Today is Aug 14. 
  // User marked Aug 3-7 (5 days) as Full (35h).
  // User marked Aug 17 (Future) as Full (7h).
  // User has duplicate for Aug 4 (Another 7h).
  final records = [
    AttendanceRecord(date: DateTime(2026, 8, 3), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 4), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 4), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0), // DUPLICATE
    AttendanceRecord(date: DateTime(2026, 8, 5), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 6), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 7), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0),
    AttendanceRecord(date: DateTime(2026, 8, 17), status: AttendanceStatus.full, actualUnits: 7.0, expectedUnits: 7.0), // FUTURE
  ];

  final result = refinedSummarize(policy, calendar, records, now);
  print('Refined Results:');
  print('Actual (A): ${result['actual']} (Expected: 35.0 - excludes duplicate and future)');
  print('Conducted (Cd): ${result['conductedToDate']} (Expected: 84.0 - 12 working days @ 7h)');
  print('Percent: ${result['percent']}% (Expected: 35/84 = 41.6%)');
  print('Max Possible (M): ${result['maximumPossible']} (Expected: 182.0 - whole month capacity)');
}
