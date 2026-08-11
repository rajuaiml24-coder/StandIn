import 'attendance.dart';

/// Pure, deterministic policy calculations. Widgets must never recreate these.
class PolicyEngine {
  const PolicyEngine();

  AttendanceSummary summarize(
    AttendancePolicy policy,
    Iterable<AttendanceRecord> records,
    DateTime now, {
    bool isHolidayCalendarConfigured = false,
  }) {
    final periodRange = _getPeriodRange(policy, now);
    
    if (periodRange == null) {
      return AttendanceSummary(
        actual: 0,
        expected: 0,
        percent: 0,
        isSafe: true,
        safeToMiss: 0,
        unitsToRecover: 0,
        periodLabel: 'Incomplete Period',
        isPolicyIncomplete: true,
      );
    }

    // Past and current records in this period
    final periodRecords = records.where((r) => 
      !r.date.isBefore(periodRange.start) && 
      !r.date.isAfter(periodRange.end)
    ).toList();

    // Actual stats based on records so far
    final countablePast = periodRecords.where((r) => 
      r.status != AttendanceStatus.holiday && r.status != AttendanceStatus.weeklyOff
    );

    final actual = countablePast.fold<double>(0.0, (sum, r) => sum + r.actualUnits);
    final expectedToDate = countablePast.fold<double>(0.0, (sum, r) => sum + r.expectedUnits);
    
    final percent = expectedToDate == 0 ? 0.0 : actual / expectedToDate * 100;
    final periodLabel = _getPeriodLabel(policy.evaluationPeriod, now, periodRange);

    if (policy.minimumPercent == null) {
      return AttendanceSummary(
        actual: actual,
        expected: expectedToDate,
        percent: percent,
        isSafe: true,
        safeToMiss: 0,
        unitsToRecover: 0,
        periodLabel: periodLabel,
        totalExpectedInPeriod: 0,
        isPolicyIncomplete: true,
        isEstimation: !isHolidayCalendarConfigured,
      );
    }

    // Capacity calculation: past countable + future working days
    final todayStart = DateTime(now.year, now.month, now.day);
    final futureExpected = _calculateFutureExpectedUnits(todayStart, periodRange.end, policy, periodRecords);
    final totalExpectedInPeriod = expectedToDate + futureExpected;
    
    final target = policy.minimumPercent! / 100;
    
    final totalRequired = totalExpectedInPeriod * target;
    final remainingToAttend = (totalRequired - actual).clamp(0, double.infinity);
    final safeToMiss = (futureExpected - remainingToAttend).clamp(0, double.infinity).toDouble();

    final unitsToRecover = target >= 1 
        ? (actual < totalExpectedInPeriod ? double.infinity : 0.0) 
        : ((target * expectedToDate - actual) / (1 - target)).clamp(0, double.infinity).toDouble();

    return AttendanceSummary(
      actual: actual,
      expected: expectedToDate,
      percent: percent,
      isSafe: percent >= policy.minimumPercent!,
      safeToMiss: safeToMiss,
      unitsToRecover: unitsToRecover,
      periodLabel: periodLabel,
      totalExpectedInPeriod: totalExpectedInPeriod,
      isEstimation: !isHolidayCalendarConfigured,
      recoveryMessage: _generateRecoveryMessage(unitsToRecover, policy.basis),
    );
  }

  String _generateRecoveryMessage(double units, CalculationBasis basis) {
    if (units <= 0) return '';
    final unitName = switch (basis) {
      CalculationBasis.hours => 'hours',
      CalculationBasis.days => 'working days',
      CalculationBasis.periods => 'classes',
    };
    final value = units.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return 'Attend the next $value $unitName';
  }

  double _calculateFutureExpectedUnits(
    DateTime from, 
    DateTime to, 
    AttendancePolicy policy,
    List<AttendanceRecord> records,
  ) {
    double total = 0;
    // Start from today, but only count if NOT already in records
    DateTime current = from;
    while (!current.isAfter(to)) {
      final isWeeklyOff = policy.weeklyOffs.contains(current.weekday);
      
      final hasRecord = records.any((r) => 
        r.date.year == current.year && 
        r.date.month == current.month && 
        r.date.day == current.day
      );

      if (!isWeeklyOff && !hasRecord) {
        total += policy.fullUnit;
      }
      current = current.add(const Duration(days: 1));
    }
    return total;
  }

  ({DateTime start, DateTime end})? _getPeriodRange(AttendancePolicy policy, DateTime now) {
    final period = policy.evaluationPeriod;
    switch (period) {
      case EvaluationPeriod.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(start.year, start.month, start.day), 
          end: DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6))
        );
      case EvaluationPeriod.monthly:
        return (
          start: DateTime(now.year, now.month, 1), 
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59)
        );
      case EvaluationPeriod.quarterly:
        final quarter = ((now.month - 1) / 3).floor();
        return (
          start: DateTime(now.year, quarter * 3 + 1, 1),
          end: DateTime(now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59)
        );
      case EvaluationPeriod.semester:
      case EvaluationPeriod.academicYear:
      case EvaluationPeriod.halfYear:
        if (policy.startDate == null || policy.endDate == null) return null;
        return (start: policy.startDate!, end: policy.endDate!);
      case EvaluationPeriod.custom:
        if (policy.startDate == null || policy.endDate == null) {
          return (
            start: DateTime(now.year, 1, 1), 
            end: DateTime(now.year, 12, 31, 23, 59, 59)
          );
        }
        return (start: policy.startDate!, end: policy.endDate!);
    }
  }

  String _getPeriodLabel(EvaluationPeriod period, DateTime now, ({DateTime start, DateTime end}) range) {
    switch (period) {
      case EvaluationPeriod.weekly:
        return 'This Week';
      case EvaluationPeriod.monthly:
        return _monthName(now.month);
      case EvaluationPeriod.quarterly:
        final quarter = ((now.month - 1) / 3).floor() + 1;
        return 'Quarter $quarter';
      case EvaluationPeriod.semester:
        return 'Current Semester';
      case EvaluationPeriod.academicYear:
        return 'Academic Year';
      case EvaluationPeriod.halfYear:
        return 'Current Half';
      default:
        return 'Current Period';
    }
  }

  String _monthName(int month) => const [
    'January', 'February', 'March', 'April', 'May', 'June', 
    'July', 'August', 'September', 'October', 'November', 'December'
  ][month - 1];

  AttendanceRecord createRecord({
    required DateTime date,
    required AttendanceStatus status,
    required AttendancePolicy policy,
    double? actualUnits,
  }) {
    final expected = (status == AttendanceStatus.holiday || status == AttendanceStatus.weeklyOff) ? 0.0 : policy.fullUnit;
    final actual = switch (status) {
      AttendanceStatus.full => policy.fullUnit,
      AttendanceStatus.half => policy.halfUnit,
      AttendanceStatus.partial => actualUnits == null ? 0.0 : actualUnits.clamp(0, policy.fullUnit).toDouble(),
      AttendanceStatus.absent || AttendanceStatus.holiday || AttendanceStatus.none || AttendanceStatus.leave || AttendanceStatus.weeklyOff => 0.0,
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
