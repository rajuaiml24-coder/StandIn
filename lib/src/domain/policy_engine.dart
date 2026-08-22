import 'attendance.dart';

/// Pure, deterministic policy calculations. Widgets must never recreate these.
class PolicyEngine {
  const PolicyEngine();

  AttendanceSummary summarize(
    AttendancePolicy policy,
    AttendanceCalendar calendar,
    Iterable<AttendanceRecord> records,
    DateTime now, {
    bool isHolidayCalendarConfigured = false,
  }) {
    final periodRange = _getPeriodRange(policy, now);
    if (periodRange == null) {
      return AttendanceSummary(
        actual: 0,
        expected: 0,
        conductedToDate: 0,
        totalConducted: 0,
        percent: 0,
        maximumPossible: 0,
        maximumPercent: 0,
        isSafe: true,
        isAchievable: true,
        safeToMiss: 0,
        unitsToRecover: 0,
        shortfall: 0,
        unmarkedCount: 0,
        periodLabel: 'Attendance period not set',
        isPolicyIncomplete: false,
        status: PeriodStatus.onTrack,
        attendedLabel: '',
        conductedLabel: '',
      );
    }

    return _calculateSummary(
      policy: policy,
      calendar: calendar,
      records: records,
      range: periodRange,
      now: now,
      periodLabel: _getPeriodLabel(policy.evaluationPeriod, now, periodRange),
      isHolidayCalendarConfigured: isHolidayCalendarConfigured,
      treatUnmarkedAsAbsent: false, 
    );
  }

  AttendanceSummary summarizeMonth(
    AttendancePolicy policy,
    AttendanceCalendar calendar,
    Iterable<AttendanceRecord> records,
    int year,
    int month,
    DateTime now, {
    bool isHolidayCalendarConfigured = false,
  }) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (monthStart.isAfter(currentMonthStart)) {
      return AttendanceSummary(
        actual: 0,
        expected: 0,
        conductedToDate: 0,
        totalConducted: 0,
        percent: 0,
        maximumPossible: 0,
        maximumPercent: 0,
        isSafe: true,
        isAchievable: true,
        safeToMiss: 0,
        unitsToRecover: 0,
        shortfall: 0,
        unmarkedCount: 0,
        periodLabel: 'Not started',
        progressLabel: 'Not started',
        status: PeriodStatus.onTrack,
        attendedLabel: '',
        conductedLabel: '',
      );
    }

    return _calculateSummary(
      policy: policy,
      calendar: calendar,
      records: records,
      range: (start: monthStart, end: monthEnd),
      now: now,
      periodLabel: _monthName(month),
      isHolidayCalendarConfigured: isHolidayCalendarConfigured,
      treatUnmarkedAsAbsent: false,
    );
  }

  AttendanceSummary _calculateSummary({
    required AttendancePolicy policy,
    required AttendanceCalendar calendar,
    required Iterable<AttendanceRecord> records,
    required ({DateTime start, DateTime end}) range,
    required DateTime now,
    required String periodLabel,
    required bool isHolidayCalendarConfigured,
    required bool treatUnmarkedAsAbsent,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final Map<String, AttendanceRecord> dailyRecords = {};
    for (var r in records) {
      if (r.date.isBefore(range.start) || r.date.isAfter(range.end)) continue;
      final key = r.date.toIso8601String().substring(0, 10);
      dailyRecords[key] = r; 
    }

    double actual = 0;
    double conductedToDate = 0;
    double totalConducted = 0;
    double futureCapacity = 0;
    double unmarkedUnits = 0;
    int unmarkedCount = 0;
    int recordsInMonthToDate = 0;

    DateTime current = range.start;
    while (!current.isAfter(range.end)) {
      final key = current.toIso8601String().substring(0, 10);
      final record = dailyRecords[key];
      final isNonWorking = calendar.isNonWorkingDay(current);

      if (current.isAfter(todayStart)) {
        if (!isNonWorking) {
          totalConducted += policy.fullUnit;
          futureCapacity += policy.fullUnit;
        }
      } else {
        if (record != null) {
          actual += record.actualUnits;
          conductedToDate += record.expectedUnits;
          totalConducted += record.expectedUnits;
          recordsInMonthToDate++;
        } else if (!isNonWorking) {
          unmarkedCount++;
          unmarkedUnits += policy.fullUnit;
          totalConducted += policy.fullUnit;
          conductedToDate += policy.fullUnit;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    final double percent;
    if (conductedToDate == 0) {
      percent = 0.0;
    } else {
      percent = (actual / conductedToDate * 100);
    }

    final maximumPossible = actual + unmarkedUnits + futureCapacity;
    final maximumPercent = totalConducted == 0 ? 0.0 : (maximumPossible / totalConducted * 100);

    // Natural Labeling
    final unitLabelLong = policy.basis.label(actual);
    final unitLabelContext = policy.basis.label(totalConducted, isContext: true);
    
    final actualVal = actual.toStringAsFixed(policy.basis == CalculationBasis.hours ? 1 : 0).replaceAll(RegExp(r'\.0$'), '');
    final conductedToDateVal = conductedToDate.toStringAsFixed(policy.basis == CalculationBasis.hours ? 1 : 0).replaceAll(RegExp(r'\.0$'), '');
    
    final attendedLabel = '$actualVal $unitLabelLong attended';
    final conductedLabel = '$actualVal of $conductedToDateVal $unitLabelContext so far';
    final progressLabel = '$actualVal of $conductedToDateVal $unitLabelContext so far';

    // Status Logic
    PeriodStatus status = PeriodStatus.onTrack;
    String recoveryMessage = '';
    double safeToMiss = 0;
    double unitsToRecover = 0;
    double shortfall = 0;
    bool isSafe = true;
    bool isAchievable = true;

    if (policy.minimumPercent != null) {
      final targetFraction = policy.minimumPercent! / 100;
      final requiredUnits = totalConducted * targetFraction;
      final gap = requiredUnits - actual;
      final capacity = futureCapacity + unmarkedUnits;

      isSafe = actual >= requiredUnits;
      isAchievable = maximumPossible >= requiredUnits;

      if (gap <= 0) {
        status = PeriodStatus.onTrack;
        isSafe = true;
      } else if (gap > capacity) {
        status = PeriodStatus.impossible;
        isAchievable = false;
        shortfall = gap - capacity;
        recoveryMessage = 'Target no longer achievable. Maximum possible is ${maximumPercent.toStringAsFixed(1)}%.';
      } else {
        final riskFactor = gap / capacity;
        if (riskFactor >= 0.9) {
          status = PeriodStatus.atRisk;
        } else {
          status = PeriodStatus.onTrack;
        }
        
        unitsToRecover = gap;
        double displayUnits = unitsToRecover;
        if (policy.basis == CalculationBasis.days || policy.basis == CalculationBasis.periods) {
          displayUnits = unitsToRecover.ceilToDouble();
        }

        final value = displayUnits.toStringAsFixed(policy.basis == CalculationBasis.hours ? 1 : 0).replaceAll(RegExp(r'\.0$'), '');
        final recoveryUnitLabel = policy.basis.label(displayUnits);
        recoveryMessage = 'Attend $value more $recoveryUnitLabel during this period to reach ${policy.minimumPercent!.toStringAsFixed(0)}%';
      }

      if (isAchievable) {
        safeToMiss = maximumPossible - requiredUnits;
      }
    }

    // If no records and we are not treating unmarked as absent, show specific state
    final bool noData = !treatUnmarkedAsAbsent && recordsInMonthToDate == 0 && (conductedToDate == 0);

    return AttendanceSummary(
      actual: actual,
      expected: conductedToDate,
      conductedToDate: conductedToDate,
      totalConducted: totalConducted,
      percent: percent,
      maximumPossible: maximumPossible,
      maximumPercent: maximumPercent,
      isSafe: isSafe,
      isAchievable: isAchievable,
      safeToMiss: safeToMiss,
      unitsToRecover: unitsToRecover,
      shortfall: shortfall,
      unmarkedCount: unmarkedCount,
      periodLabel: noData ? 'Attendance not marked' : periodLabel,
      totalExpectedInPeriod: totalConducted,
      isPolicyIncomplete: false,
      isEstimation: !calendar.isConfigured || !isHolidayCalendarConfigured,
      recoveryMessage: recoveryMessage,
      progressLabel: progressLabel,
      status: status,
      attendedLabel: attendedLabel,
      conductedLabel: conductedLabel,
      maxPossiblePercent: maximumPercent,
    );
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
