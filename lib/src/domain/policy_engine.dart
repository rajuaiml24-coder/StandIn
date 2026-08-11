import 'attendance.dart';

/// Pure, deterministic policy calculations. Widgets must never recreate these.
class PolicyEngine {
  const PolicyEngine();

  AttendanceSummary summarize(
    AttendancePolicy policy,
    Iterable<AttendanceRecord> records,
  ) {
    final countable = records.where((r) => r.status != AttendanceStatus.holiday);
    final actual = countable.fold<double>(0, (sum, r) => sum + r.actualUnits);
    final expected = countable.fold<double>(0, (sum, r) => sum + r.expectedUnits);
    final percent = expected == 0 ? 0.0 : actual / expected * 100;
    final target = policy.minimumPercent / 100;
    final safeToMiss = target == 0 ? 0.0 : (actual / target - expected).clamp(0, double.infinity).toDouble();
    final unitsToRecover = target >= 1 ? double.infinity : ((target * expected - actual) / (1 - target)).clamp(0, double.infinity).toDouble();
    return AttendanceSummary(
      actual: actual,
      expected: expected,
      percent: percent,
      isSafe: percent >= policy.minimumPercent,
      safeToMiss: safeToMiss,
      unitsToRecover: unitsToRecover,
    );
  }

  AttendanceRecord createRecord({
    required DateTime date,
    required AttendanceStatus status,
    required AttendancePolicy policy,
    double? actualUnits,
  }) {
    final expected = status == AttendanceStatus.holiday ? 0.0 : policy.fullUnit;
    final actual = switch (status) {
      AttendanceStatus.full => policy.fullUnit,
      AttendanceStatus.half => policy.halfUnit,
      AttendanceStatus.partial => actualUnits == null ? 0.0 : actualUnits.clamp(0, policy.fullUnit).toDouble(),
      AttendanceStatus.absent || AttendanceStatus.holiday || AttendanceStatus.none => 0.0,
    };
    return AttendanceRecord(
      date: DateTime(date.year, date.month, date.day),
      status: status,
      actualUnits: actual,
      expectedUnits: expected,
      pendingSync: true,
    );
  }
}
