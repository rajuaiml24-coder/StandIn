import 'attendance.dart';
import 'calendar_updates.dart';
import 'policy_engine.dart';

DateTime ruleActivationDate(AttendancePolicy before, AttendancePolicy next,
    DateTime proposed, DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  var date = proposed.isAfter(tomorrow)
      ? DateTime(proposed.year, proposed.month, proposed.day)
      : tomorrow;
  final structural = before.basis != next.basis ||
      before.oneVisitFullDay != next.oneVisitFullDay ||
      before.fullUnit != next.fullUnit ||
      before.halfUnit != next.halfUnit ||
      before.evaluationPeriod != next.evaluationPeriod ||
      before.startDate != next.startDate ||
      before.endDate != next.endDate;
  if (!structural) return date;
  const engine = PolicyEngine();
  final oldRange = engine.periodRange(before, now);
  if (oldRange == null) {
    throw StateError('Complete the current attendance period first');
  }
  final oldEnd =
      DateTime(oldRange.end.year, oldRange.end.month, oldRange.end.day + 1);
  if (date.isBefore(oldEnd)) date = oldEnd;
  if ([
    EvaluationPeriod.custom,
    EvaluationPeriod.semester,
    EvaluationPeriod.academicYear,
    EvaluationPeriod.halfYear
  ].contains(next.evaluationPeriod)) {
    if (next.startDate == null ||
        next.endDate == null ||
        next.startDate!.isBefore(date) ||
        next.endDate!.isBefore(next.startDate!)) {
      throw StateError(
          'Choose a new period starting after the current period ends');
    }
    return next.startDate!;
  }
  final newRange = engine.periodRange(next, date)!;
  if (newRange.start.isBefore(date)) {
    date =
        DateTime(newRange.end.year, newRange.end.month, newRange.end.day + 1);
  }
  return date;
}

class SharedRules {
  const SharedRules(this.policy, this.calendar);
  final AttendancePolicy policy;
  final AttendanceCalendar calendar;
  Map<String, dynamic> toJson() =>
      {'policy': policy.toJson(), 'calendar': calendarJson(calendar)};
  factory SharedRules.fromJson(Map<String, dynamic> json) => SharedRules(
      AttendancePolicy.fromJson(
          Map<String, dynamic>.from(json['policy'] as Map)),
      calendarFromJson(Map<String, dynamic>.from(json['calendar'] as Map)));

  Map<String, Object?> get fields => {
        for (final key in [
          'minimumPercent',
          'basis',
          'fullUnit',
          'halfUnit',
          'evaluationPeriod',
          'startDate',
          'endDate',
          'leaveTreatment',
          'weekOffCredit',
          'holidayCredit'
        ])
          key: policy.toJson()[key],
        'oneVisitFullDay': policy.oneVisitFullDay,
        'weeklyOffs': calendar.weeklyOffs,
        'offSaturdays': calendar.offSaturdays,
        for (final h in calendar.holidays)
          'holiday:${calendarDayKey(h.date)}': h.toJson(),
      };
  Map<String, Object?> changesFrom(SharedRules before) => {
        for (final key in {...before.fields.keys, ...fields.keys})
          if (!sameCalendarValue(before.fields[key], fields[key]))
            key: fields[key],
      };

  SharedRules apply(Map<String, Object?> changes) {
    final p = policy.toJson(), c = calendarJson(calendar);
    final holidays = {
      for (final h in calendar.holidays) calendarDayKey(h.date): h.toJson()
    };
    for (final change in changes.entries) {
      if (change.key.startsWith('holiday:')) {
        final date = change.key.substring(8);
        c['workingDates'] =
            (c['workingDates'] as List).where((d) => d != date).toList();
        if (change.value == null) {
          holidays.remove(date);
        } else {
          holidays[date] = Map<String, dynamic>.from(change.value as Map);
        }
      } else if (change.key == 'weeklyOffs' || change.key == 'offSaturdays') {
        c[change.key] = change.value;
        if (change.key == 'weeklyOffs') p[change.key] = change.value;
      } else if (p.containsKey(change.key) || change.key == 'oneVisitFullDay') {
        p[change.key] = change.value;
      } else {
        throw ArgumentError('Unknown attendance rule');
      }
    }
    c['holidays'] = holidays.values.toList();
    final result =
        SharedRules(AttendancePolicy.fromJson(p), calendarFromJson(c));
    result.validate();
    return result;
  }

  void validate() {
    if (!policy.hasValidUnits ||
        !policy.hasValidTarget ||
        calendar.weeklyOffs.any((d) => d < 1 || d > 7) ||
        calendar.offSaturdays.any((d) => d < 1 || d > 5) ||
        const PolicyEngine().periodRange(policy, DateTime.now()) == null) {
      throw ArgumentError(
          'Selected rules are incompatible. Review units, target and date range.');
    }
  }
}

class RuleRevision {
  const RuleRevision(
      {required this.id,
      required this.version,
      required this.author,
      required this.before,
      required this.rules,
      required this.effectiveDate,
      required this.changes});
  final String id, author;
  final int version;
  final SharedRules before, rules;
  final DateTime effectiveDate;
  final Map<String, Object?> changes;
  int get schema =>
      rules.policy.oneVisitFullDay || before.policy.oneVisitFullDay ? 2 : 1;
  Map<String, dynamic> toJson() => {
        'schema': schema,
        'version': version,
        'author': author,
        'before': before.toJson(),
        'rules': rules.toJson(),
        'effectiveDate': calendarDayKey(effectiveDate),
        'changes': changes,
      };
  factory RuleRevision.fromJson(String id, Map<String, dynamic> json) {
    if (json['schema'] != 1 && json['schema'] != 2) {
      throw StateError('Update StandIn to review these rules');
    }
    return RuleRevision(
        id: id,
        version: (json['version'] as num).toInt(),
        author: json['author'] as String,
        before: SharedRules.fromJson(
            Map<String, dynamic>.from(json['before'] as Map)),
        rules: SharedRules.fromJson(
            Map<String, dynamic>.from(json['rules'] as Map)),
        effectiveDate: DateTime.parse(json['effectiveDate'] as String),
        changes: Map<String, Object?>.from(json['changes'] as Map));
  }
}

String ruleLabel(String field) => switch (field) {
      'minimumPercent' => 'Target',
      'basis' => 'Calculate by',
      'fullUnit' => 'Full day units',
      'halfUnit' => 'Half day units',
      'evaluationPeriod' => 'Attendance period',
      'startDate' => 'Start date',
      'endDate' => 'End date',
      'leaveTreatment' => 'Leave',
      'weekOffCredit' => 'Count attendance on days off',
      'holidayCredit' => 'Count attendance on holidays',
      'oneVisitFullDay' => 'One class or swipe counts as a full day',
      'weeklyOffs' => 'Weekly days off',
      'offSaturdays' => 'Saturdays off',
      _ => field.startsWith('holiday:') ? field.substring(8) : field,
    };

String ruleValue(String field, Object? value) {
  if (value == null) return 'Not set';
  if (value is bool) return value ? 'On' : 'Off';
  if (field.startsWith('holiday:')) return (value as Map)['name'] as String;
  if (field == 'weeklyOffs') {
    return (value as List)
        .map((v) => const [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun'
            ][(v as int) - 1])
        .join(', ');
  }
  if (value is List) return value.isEmpty ? 'None' : value.join(', ');
  return switch (value) {
    'noCredit' => 'No attendance credit',
    'countsTowardTarget' => 'Counts toward target',
    'excluded' => 'Excluded from required attendance',
    _ => value.toString(),
  };
}
