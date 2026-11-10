import 'attendance.dart';
import 'planning.dart';

/// Pure, deterministic policy calculations. Widgets must never recreate these.
class PolicyEngine {
  const PolicyEngine();
  AttendanceDayType dayType(AttendanceCalendar calendar, DateTime date) {
    final key = date.toIso8601String().substring(0, 10);
    if (calendar.workingDates.contains(key)) return AttendanceDayType.working;
    if (calendar.holidays
        .any((h) => h.date.toIso8601String().substring(0, 10) == key)) {
      return AttendanceDayType.holiday;
    }
    return calendar.isNonWorkingDay(date)
        ? AttendanceDayType.weeklyOff
        : AttendanceDayType.working;
  }

  AttendanceSnapshot contribution(AttendancePolicy policy,
      AttendanceDayType type, DateTime date, double attended, double leave,
      {bool excluded = false}) {
    if (!policy.hasValidUnits ||
        !attended.isFinite ||
        !leave.isFinite ||
        attended < 0 ||
        leave < 0 ||
        attended + leave > policy.fullUnit + 1e-9 ||
        policy.oneVisitFullDay && attended > 0 && leave > 0) {
      throw ArgumentError('Attendance and leave cannot exceed a full day');
    }
    final range = periodRange(policy, date);
    if (range == null) throw StateError('Set an attendance period first');
    final working = type == AttendanceDayType.working && !excluded;
    final extraAllowed = !excluded &&
        (type == AttendanceDayType.weeklyOff
            ? policy.weekOffCredit
            : type == AttendanceDayType.holiday && policy.holidayCredit);
    final creditedAttendance =
        policy.oneVisitFullDay && attended > 0 ? policy.fullUnit : attended;
    return AttendanceSnapshot(
        policy: policy,
        dayType: type,
        physical: working ? creditedAttendance : 0,
        leaveCredit: working &&
                policy.leaveTreatment == LeaveTreatment.countsTowardTarget
            ? leave
            : 0,
        extraCredit: extraAllowed ? creditedAttendance : 0,
        requiredUnits: working
            ? policy.fullUnit -
                (policy.leaveTreatment == LeaveTreatment.excluded ? leave : 0)
            : 0,
        periodStart: range.start,
        periodEnd: range.end);
  }

  AttendanceRecord freezeLegacy(AttendanceRecord record,
      AttendancePolicy policy, AttendanceCalendar calendar) {
    if (record.snapshot != null) return record;
    // Legacy entries predate this rule; protect their original contribution.
    policy = policy.copyWith(oneVisitFullDay: false);
    if (record.expectedUnits > 0 && record.expectedUnits != policy.fullUnit) {
      return record; // Recover original units before assigning a historical basis.
    }
    final range = periodRange(policy, record.date);
    if (range == null) return record;
    final excluded =
        dayType(calendar, record.date) == AttendanceDayType.holiday;
    return record.copyWith(
        snapshot: AttendanceSnapshot(
            policy: policy,
            dayType: dayType(calendar, record.date),
            physical: excluded ? 0 : record.actualUnits,
            leaveCredit: 0,
            extraCredit: 0,
            requiredUnits: excluded ? 0 : record.expectedUnits,
            periodStart: range.start,
            periodEnd: range.end,
            legacy: true));
  }

  ({DateTime start, DateTime end})? periodRange(
          AttendancePolicy policy, DateTime now) =>
      _getPeriodRange(policy, now);

  ({DateTime start, DateTime end}) _monthRange(
      AttendancePolicy policy, int year, int month) {
    final monthStart = DateTime(year, month);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final bounded = [
      EvaluationPeriod.semester,
      EvaluationPeriod.custom,
      EvaluationPeriod.halfYear,
      EvaluationPeriod.academicYear
    ].contains(policy.evaluationPeriod);
    final period = bounded ? _getPeriodRange(policy, monthStart) : null;
    return (
      start: period != null && period.start.isAfter(monthStart)
          ? period.start
          : monthStart,
      end: period != null && period.end.isBefore(monthEnd)
          ? period.end
          : monthEnd
    );
  }

  PlanningSummary summarizePlans(
      AttendancePolicy policy,
      AttendanceCalendar calendar,
      Iterable<AttendanceRecord> records,
      Iterable<AttendancePlan> plans,
      DateTime now,
      {int? year,
      int? month,
      AttendancePolicy Function(DateTime)? policyFor,
      AttendanceCalendar Function(DateTime)? calendarFor}) {
    var range = _getPeriodRange(policy, now);
    if (year != null && month != null) {
      range = _monthRange(policy, year, month);
    }
    if (range == null ||
        range.start.isAfter(range.end) ||
        !policy.hasValidUnits) {
      return const PlanningSummary(
          confirmedUnits: 0,
          plannedUnits: 0,
          totalExpected: 0,
          percent: 0,
          meetsTarget: false,
          unitsStillNeeded: 0,
          isIncomplete: true,
          unconfirmedCount: 0,
          changedRuleCount: 0);
    }
    final today = DateTime(now.year, now.month, now.day);
    String key(DateTime date) => date.toIso8601String().substring(0, 10);
    final dailyRecords = {
      for (final record in records) key(record.date): record
    };
    bool incompatible(DateTime date) =>
        (policyFor?.call(date) ?? policy).basis != policy.basis ||
        dailyRecords[key(date)]?.snapshot?.policy.basis != null &&
            dailyRecords[key(date)]!.snapshot!.policy.basis != policy.basis;
    for (var date = range.start;
        !date.isAfter(range.end);
        date = DateTime(date.year, date.month, date.day + 1)) {
      if (incompatible(date)) {
        return const PlanningSummary(
            confirmedUnits: 0,
            plannedUnits: 0,
            totalExpected: 0,
            percent: 0,
            meetsTarget: false,
            unitsStillNeeded: 0,
            isIncomplete: true,
            unconfirmedCount: 0,
            changedRuleCount: 0);
      }
    }
    final dailyPlans = {
      for (final plan in plans.where((p) => !p.isDeleted)) key(plan.date): plan
    };
    double confirmed = 0, planned = 0, expected = 0;
    int unconfirmed = 0, changed = 0;
    for (var date = range.start;
        !date.isAfter(range.end);
        date = DateTime(date.year, date.month, date.day + 1)) {
      final record = dailyRecords[key(date)];
      final plan = dailyPlans[key(date)];
      final dailyPolicy = policyFor?.call(date) ?? policy;
      final dailyCalendar = calendarFor?.call(date) ?? calendar;
      final policyKey = planningPolicyKey(dailyPolicy);
      final calendarKey = planningCalendarKey(dailyCalendar);
      if (!date.isAfter(today)) {
        if (record?.snapshot == null &&
            dailyCalendar.holidays.any((h) => key(h.date) == key(date)) &&
            !dailyCalendar.workingDates.contains(key(date))) {
          continue;
        }
        if (record != null) {
          confirmed += record.snapshot?.credited ?? record.actualUnits;
          expected += record.snapshot?.requiredUnits ?? record.expectedUnits;
        } else if (!dailyCalendar.isNonWorkingDay(date)) {
          expected += dailyPolicy.fullUnit;
          unconfirmed++;
        }
        continue;
      }
      if (plan != null &&
          (plan.policyVersionId != policyKey ||
              plan.calendarVersionId != calendarKey)) {
        changed++;
      }
      if (plan != null &&
          plan.policyVersionId == policyKey &&
          plan.calendarVersionId == calendarKey) {
        final value = contribution(
            dailyPolicy,
            dayType(dailyCalendar, date),
            date,
            plan.status == AttendanceStatus.leave ? 0 : plan.units,
            plan.status == AttendanceStatus.leave && plan.leaveUnits == 0
                ? plan.units
                : plan.leaveUnits);
        planned += value.credited;
        expected += value.requiredUnits;
      } else if (!dailyCalendar.isNonWorkingDay(date)) {
        expected += dailyPolicy.fullUnit;
      }
    }
    final total = confirmed + planned;
    final needed = policy.hasValidTarget
        ? (expected * policy.minimumPercent! / 100 - total)
            .clamp(0, double.infinity)
            .toDouble()
        : 0.0;
    return PlanningSummary(
        confirmedUnits: confirmed,
        plannedUnits: planned,
        totalExpected: expected,
        percent: expected == 0 ? 0 : total / expected * 100,
        meetsTarget: expected > 0 && policy.hasValidTarget && needed == 0,
        unitsStillNeeded: needed,
        isIncomplete: !policy.hasValidTarget ||
            !calendar.isConfigured ||
            _getPeriodRange(policy, now) == null,
        unconfirmedCount: unconfirmed,
        changedRuleCount: changed);
  }

  AttendanceSummary summarize(
    AttendancePolicy policy,
    AttendanceCalendar calendar,
    Iterable<AttendanceRecord> records,
    DateTime now, {
    bool isHolidayCalendarConfigured = false,
    AttendancePolicy Function(DateTime)? policyFor,
    AttendanceCalendar Function(DateTime)? calendarFor,
  }) {
    final periodRange = _getPeriodRange(policy, now);
    if (periodRange == null || !policy.hasValidUnits) {
      return AttendanceSummary(
        actual: 0,
        expected: 0,
        conductedToDate: 0,
        totalConducted: 0,
        percent: 0,
        maximumPossible: 0,
        maximumPercent: 0,
        isSafe: false,
        isAchievable: false,
        safeToMiss: 0,
        unitsToRecover: 0,
        shortfall: 0,
        unmarkedCount: 0,
        periodLabel: 'Attendance period not set',
        isPolicyIncomplete: true,
        status: PeriodStatus.onTrack,
        attendedLabel: '',
        conductedLabel: '',
        recoveryMessage: 'Attendance rules are incomplete.',
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
      policyFor: policyFor,
      calendarFor: calendarFor,
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
    AttendancePolicy Function(DateTime)? policyFor,
    AttendanceCalendar Function(DateTime)? calendarFor,
  }) {
    final monthStart = DateTime(year, month, 1);
    final range = _monthRange(policy, year, month);
    final outsidePeriod = range.start.isAfter(range.end);

    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (outsidePeriod ||
        monthStart.isAfter(currentMonthStart) ||
        !policy.hasValidUnits) {
      return AttendanceSummary(
        actual: 0,
        expected: 0,
        conductedToDate: 0,
        totalConducted: 0,
        percent: 0,
        maximumPossible: 0,
        maximumPercent: 0,
        isSafe: false,
        isAchievable: false,
        safeToMiss: 0,
        unitsToRecover: 0,
        shortfall: 0,
        unmarkedCount: 0,
        periodLabel:
            outsidePeriod ? 'Outside attendance period' : 'Not started',
        progressLabel:
            outsidePeriod ? 'Outside attendance period' : 'Not started',
        status: PeriodStatus.onTrack,
        attendedLabel: '',
        conductedLabel: '',
        recoveryMessage: outsidePeriod ? 'Outside your attendance period.' : '',
        isPolicyIncomplete: outsidePeriod ||
            !policy.hasValidUnits ||
            !policy.hasValidTarget ||
            _getPeriodRange(policy, now) == null,
      );
    }

    return _calculateSummary(
      policy: policy,
      calendar: calendar,
      records: records,
      range: range,
      now: now,
      periodLabel: _monthName(month),
      isHolidayCalendarConfigured: isHolidayCalendarConfigured,
      treatUnmarkedAsAbsent: false,
      policyFor: policyFor,
      calendarFor: calendarFor,
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
    AttendancePolicy Function(DateTime)? policyFor,
    AttendanceCalendar Function(DateTime)? calendarFor,
    bool Function(DateTime)? includeDate,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);

    final Map<String, AttendanceRecord> dailyRecords = {};
    for (var r in records) {
      if (includeDate?.call(r.date) == false) continue;
      if (r.date.isBefore(range.start) || r.date.isAfter(range.end)) continue;
      final key = r.date.toIso8601String().substring(0, 10);
      dailyRecords[key] = r;
    }
    for (var date = range.start;
        !date.isAfter(range.end);
        date = DateTime(date.year, date.month, date.day + 1)) {
      if (includeDate?.call(date) == false) continue;
      final stored =
          dailyRecords[date.toIso8601String().substring(0, 10)]?.snapshot;
      if ((policyFor?.call(date) ?? policy).basis != policy.basis ||
          stored != null && stored.policy.basis != policy.basis) {
        return const AttendanceSummary(
            actual: 0,
            expected: 0,
            conductedToDate: 0,
            totalConducted: 0,
            percent: 0,
            maximumPossible: 0,
            maximumPercent: 0,
            isSafe: false,
            isAchievable: false,
            safeToMiss: 0,
            unitsToRecover: 0,
            shortfall: 0,
            unmarkedCount: 0,
            periodLabel: 'Separate rule periods',
            isPolicyIncomplete: true,
            status: PeriodStatus.onTrack,
            attendedLabel: '',
            conductedLabel: '',
            recoveryMessage:
                'Different attendance units are kept separate. Open the original attendance period.');
      }
    }

    double actual = 0;
    double physical = 0, leaveCredit = 0, extraCredit = 0;
    double conductedToDate = 0;
    double totalConducted = 0;
    double futureCapacity = 0;
    double extraCapacity = 0;
    double unmarkedUnits = 0;
    int unmarkedCount = 0;
    int recordsInMonthToDate = 0;

    DateTime current = range.start;
    while (!current.isAfter(range.end)) {
      if (includeDate?.call(current) == false) {
        current = DateTime(current.year, current.month, current.day + 1);
        continue;
      }
      final key = current.toIso8601String().substring(0, 10);
      final record = dailyRecords[key];
      final dailyPolicy = policyFor?.call(current) ?? policy;
      final dailyCalendar = calendarFor?.call(current) ?? calendar;
      final isNonWorking = dailyCalendar.isNonWorkingDay(current);

      if (current.isAfter(todayStart)) {
        if (!isNonWorking) {
          totalConducted += dailyPolicy.fullUnit;
          futureCapacity += dailyPolicy.fullUnit;
        } else {
          final type = dayType(dailyCalendar, current);
          if (type == AttendanceDayType.holiday
              ? dailyPolicy.holidayCredit
              : dailyPolicy.weekOffCredit) {
            extraCapacity += dailyPolicy.fullUnit;
          }
        }
      } else {
        if (record != null &&
            (record.snapshot != null ||
                !(dailyCalendar.holidays.any((h) =>
                        h.date.year == current.year &&
                        h.date.month == current.month &&
                        h.date.day == current.day) &&
                    !dailyCalendar.workingDates.contains(key)))) {
          actual += record.snapshot?.credited ?? record.actualUnits;
          physical += record.snapshot?.physical ?? record.actualUnits;
          leaveCredit += record.snapshot?.leaveCredit ?? 0;
          extraCredit += record.snapshot?.extraCredit ?? 0;
          conductedToDate +=
              record.snapshot?.requiredUnits ?? record.expectedUnits;
          totalConducted +=
              record.snapshot?.requiredUnits ?? record.expectedUnits;
          recordsInMonthToDate++;
        } else if (!isNonWorking) {
          unmarkedCount++;
          unmarkedUnits += dailyPolicy.fullUnit;
          totalConducted += dailyPolicy.fullUnit;
          conductedToDate += dailyPolicy.fullUnit;
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

    final regularMaximum = actual + unmarkedUnits + futureCapacity;
    final maximumPossible = regularMaximum + extraCapacity;
    final maximumPercent =
        totalConducted == 0 ? 0.0 : (maximumPossible / totalConducted * 100);

    // Natural Labeling
    final unitLabelLong = policy.basis.label(actual);
    final unitLabelContext =
        policy.basis.label(totalConducted, isContext: true);

    final actualVal = formatAttendanceUnits(actual);
    final conductedToDateVal = formatAttendanceUnits(conductedToDate);

    final attendedLabel = '$actualVal $unitLabelLong attended';
    final conductedLabel =
        '$actualVal of $conductedToDateVal $unitLabelContext so far';
    final progressLabel =
        '$actualVal of $conductedToDateVal $unitLabelContext so far';

    // Status Logic
    PeriodStatus status = PeriodStatus.onTrack;
    String recoveryMessage = '';
    double safeToMiss = 0;
    double unitsToRecover = 0;
    double shortfall = 0;
    bool isSafe = false;
    bool isAchievable = false;

    if (policy.hasValidTarget &&
        _getPeriodRange(policy, now) != null &&
        totalConducted > 0) {
      final targetFraction = policy.minimumPercent! / 100;
      final requiredUnits = totalConducted * targetFraction;
      final gap = requiredUnits - actual;
      final capacity = futureCapacity + unmarkedUnits + extraCapacity;

      isSafe = actual >= requiredUnits;
      isAchievable = maximumPossible >= requiredUnits;

      if (gap <= 0) {
        status = PeriodStatus.onTrack;
        isSafe = true;
      } else if (gap > capacity) {
        status = PeriodStatus.impossible;
        isAchievable = false;
        shortfall = gap - capacity;
        recoveryMessage =
            'Target no longer achievable. Maximum possible is ${maximumPercent.toStringAsFixed(1)}%.';
      } else {
        final riskFactor = gap / capacity;
        if (riskFactor >= 0.9) {
          status = PeriodStatus.atRisk;
        } else {
          status = PeriodStatus.onTrack;
        }

        unitsToRecover = gap;
        double displayUnits = unitsToRecover;
        if (policy.basis == CalculationBasis.days ||
            policy.basis == CalculationBasis.periods) {
          final step = policy.oneVisitFullDay ? policy.fullUnit : 0.5;
          displayUnits = (unitsToRecover / step).ceil() * step;
        }

        final value = formatAttendanceUnits(displayUnits);
        final recoveryUnitLabel = policy.basis.label(displayUnits);
        recoveryMessage =
            'Attend $value more $recoveryUnitLabel during this period to reach ${policy.minimumPercent!.toStringAsFixed(0)}%';
        if (regularMaximum < requiredUnits && extraCapacity > 0) {
          recoveryMessage +=
              ' This needs attendance on allowed days off or holidays.';
        }
      }

      if (isAchievable) {
        // Never advise missing a working day based on unplanned extra visits.
        safeToMiss = (regularMaximum - requiredUnits).clamp(0, double.infinity);
      }
    } else {
      recoveryMessage = totalConducted == 0
          ? 'No required attendance'
          : policy.hasValidTarget
              ? 'Attendance period is not set.'
              : 'Required attendance target is not set.';
    }

    // If no records and we are not treating unmarked as absent, show specific state
    final bool noData = !treatUnmarkedAsAbsent &&
        recordsInMonthToDate == 0 &&
        (conductedToDate == 0);

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
      isPolicyIncomplete:
          !policy.hasValidTarget || _getPeriodRange(policy, now) == null,
      isEstimation: !calendar.isConfigured || !isHolidayCalendarConfigured,
      recoveryMessage: recoveryMessage,
      progressLabel: progressLabel,
      status: status,
      attendedLabel: attendedLabel,
      conductedLabel: conductedLabel,
      maxPossiblePercent: maximumPercent,
      physicalUnits: physical,
      leaveCredit: leaveCredit,
      extraCredit: extraCredit,
    );
  }

  AttendanceSummary summarizeRange(
          AttendancePolicy policy,
          AttendanceCalendar calendar,
          Iterable<AttendanceRecord> records,
          DateTime start,
          DateTime end,
          DateTime now,
          {AttendancePolicy Function(DateTime)? policyFor,
          AttendanceCalendar Function(DateTime)? calendarFor,
          bool Function(DateTime)? includeDate}) =>
      _calculateSummary(
          policy: policy,
          calendar: calendar,
          records: records,
          range: (
            start: DateTime(start.year, start.month, start.day),
            end: DateTime(end.year, end.month, end.day, 23, 59, 59)
          ),
          now: now,
          periodLabel: 'Saved period',
          isHolidayCalendarConfigured: calendar.isConfigured,
          treatUnmarkedAsAbsent: false,
          policyFor: policyFor,
          calendarFor: calendarFor,
          includeDate: includeDate);

  ({DateTime start, DateTime end})? _getPeriodRange(
      AttendancePolicy policy, DateTime now) {
    final period = policy.evaluationPeriod;
    switch (period) {
      case EvaluationPeriod.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(start.year, start.month, start.day, 23, 59, 59)
              .add(const Duration(days: 6))
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
      case EvaluationPeriod.custom:
        if (policy.startDate == null || policy.endDate == null) return null;
        final start = policy.startDate!;
        final end = policy.endDate!;
        final firstDay = DateTime(start.year, start.month, start.day);
        final lastDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        if (lastDay.isBefore(firstDay)) return null;
        return (start: firstDay, end: lastDay);
    }
  }

  String _getPeriodLabel(EvaluationPeriod period, DateTime now,
      ({DateTime start, DateTime end}) range) {
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
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][month - 1];

  AttendanceRecord createRecord({
    required DateTime date,
    required AttendanceStatus status,
    required AttendancePolicy policy,
    double? actualUnits,
    double? leaveUnits,
    AttendanceCalendar? calendar,
    AttendanceDayType? recordedDayType,
  }) {
    if (!policy.hasValidUnits) throw StateError('Attendance units are invalid');
    final expected = (status == AttendanceStatus.holiday ||
            status == AttendanceStatus.weeklyOff)
        ? 0.0
        : policy.fullUnit;
    final actual = switch (status) {
      AttendanceStatus.full => policy.fullUnit,
      AttendanceStatus.half => policy.halfUnit,
      AttendanceStatus.partial => actualUnits == null
          ? 0.0
          : actualUnits.clamp(0, policy.fullUnit).toDouble(),
      AttendanceStatus.absent ||
      AttendanceStatus.holiday ||
      AttendanceStatus.none ||
      AttendanceStatus.leave ||
      AttendanceStatus.weeklyOff =>
        0.0,
    };
    final leave = leaveUnits ??
        (status == AttendanceStatus.leave ? policy.fullUnit : 0.0);
    final snapshot = calendar == null && recordedDayType == null
        ? null
        : contribution(policy, recordedDayType ?? dayType(calendar!, date),
            date, actual, leave,
            excluded: status == AttendanceStatus.holiday ||
                status == AttendanceStatus.weeklyOff);
    return AttendanceRecord(
      date: DateTime(date.year, date.month, date.day),
      status: status,
      actualUnits: actual,
      expectedUnits: expected,
      pendingSync: true,
      snapshot: snapshot,
      leaveUnits: leave,
    );
  }
}
