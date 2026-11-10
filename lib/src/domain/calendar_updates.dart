import 'dart:convert';
import 'attendance.dart';

String calendarDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

Object? _ordered(Object? value) {
  if (value is Map) {
    return {
      for (final key in value.keys.cast<String>().toList()..sort())
        key: _ordered(value[key])
    };
  }
  if (value is List) return value.map(_ordered).toList();
  return value;
}

bool sameCalendarValue(Object? a, Object? b) =>
    jsonEncode(_ordered(a)) == jsonEncode(_ordered(b));

Map<String, dynamic> calendarJson(AttendanceCalendar calendar) => {
      'id': calendar.id,
      'version': calendar.version,
      'effectiveFrom': calendar.effectiveFrom.toIso8601String(),
      'weeklyOffs': calendar.weeklyOffs,
      'offSaturdays': calendar.offSaturdays,
      'holidays': calendar.holidays.map((h) => h.toJson()).toList(),
      'isConfigured': calendar.isConfigured,
      'organizationId': calendar.organizationId,
      'scopeId': calendar.scopeId,
      'workingDates': calendar.workingDates,
    };

AttendanceCalendar calendarFromJson(Map<String, dynamic> json) =>
    AttendanceCalendar(
      id: json['id'] as String,
      version: (json['version'] as num).toInt(),
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      weeklyOffs: (json['weeklyOffs'] as List).cast<int>(),
      offSaturdays: (json['offSaturdays'] as List).cast<int>(),
      holidays: (json['holidays'] as List)
          .map((h) => Holiday.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList(),
      isConfigured: json['isConfigured'] as bool,
      organizationId: json['organizationId'] as String?,
      scopeId: json['scopeId'] as String?,
      workingDates: (json['workingDates'] as List? ?? []).cast<String>(),
    );

class PersonalCalendarState {
  const PersonalCalendarState(
      {required this.baseline,
      this.reviewedVersion = 0,
      this.dates = const {},
      this.policy,
      this.ruleTimeline = const [],
      this.reviewedRuleVersion = 0});
  final AttendanceCalendar baseline;
  final int reviewedVersion;
  final Map<String, Map<String, dynamic>> dates;
  final AttendancePolicy? policy;
  final List<Map<String, dynamic>> ruleTimeline;
  int get ruleSchema => policy?.oneVisitFullDay == true ||
          ruleTimeline.any(
              (entry) => (entry['policy'] as Map)['oneVisitFullDay'] == true)
      ? 2
      : 1;
  final int reviewedRuleVersion;

  PersonalCalendarState copyWith(
          {AttendancePolicy? policy,
          List<Map<String, dynamic>>? ruleTimeline,
          int? reviewedRuleVersion}) =>
      PersonalCalendarState(
          baseline: baseline,
          reviewedVersion: reviewedVersion,
          dates: dates,
          policy: policy ?? this.policy,
          ruleTimeline: ruleTimeline ?? this.ruleTimeline,
          reviewedRuleVersion: reviewedRuleVersion ?? this.reviewedRuleVersion);

  AttendancePolicy? policyAt(DateTime day) {
    AttendancePolicy? result = policy;
    for (final entry in ruleTimeline) {
      if (calendarDayKey(day).compareTo(entry['effectiveDate'] as String) >=
          0) {
        result = AttendancePolicy.fromJson(
            Map<String, dynamic>.from(entry['policy'] as Map));
      }
    }
    return result;
  }

  AttendanceCalendar calendarAt(DateTime day) {
    var result = baseline;
    final overrides = {...dates};
    for (final entry in ruleTimeline) {
      if (calendarDayKey(day).compareTo(entry['effectiveDate'] as String) >=
          0) {
        result = calendarFromJson(
            Map<String, dynamic>.from(entry['calendar'] as Map));
        for (final key in (entry['dateResets'] as List? ?? []).cast<String>()) {
          overrides.remove(key);
        }
      }
    }
    return _materialize(result, overrides);
  }

  Map<String, dynamic> toJson() => {
        'baseline': calendarJson(baseline),
        'reviewedVersion': reviewedVersion,
        'dates': dates,
        if (policy != null) 'policy': policy!.toJson(),
        if (ruleTimeline.isNotEmpty) 'ruleTimeline': ruleTimeline,
        if (policy != null) 'ruleSchema': ruleSchema,
        if (reviewedRuleVersion > 0) 'reviewedRuleVersion': reviewedRuleVersion,
      };
  factory PersonalCalendarState.fromJson(Map<String, dynamic> json) =>
      PersonalCalendarState(
        baseline: calendarFromJson(
            Map<String, dynamic>.from(json['baseline'] as Map)),
        reviewedVersion: (json['reviewedVersion'] as num).toInt(),
        dates: (json['dates'] as Map).map((k, v) =>
            MapEntry(k as String, Map<String, dynamic>.from(v as Map))),
        policy: json['policy'] == null
            ? null
            : AttendancePolicy.fromJson(
                Map<String, dynamic>.from(json['policy'] as Map)),
        ruleTimeline: (json['ruleTimeline'] as List? ?? [])
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList(),
        reviewedRuleVersion:
            (json['reviewedRuleVersion'] as num?)?.toInt() ?? 0,
      );

  AttendanceCalendar get calendar => calendarAt(DateTime.now());
  AttendanceCalendar _materialize(AttendanceCalendar baseline,
      Map<String, Map<String, dynamic>> overrides) {
    final holidays = {
      for (final h in baseline.holidays) calendarDayKey(h.date): h
    };
    final working = baseline.workingDates.toSet();
    for (final entry in overrides.entries) {
      if (entry.value['inherit'] == true) continue;
      final value = entry.value['holiday'];
      if (value == null) {
        holidays.remove(entry.key);
        working.add(entry.key);
      } else {
        holidays[entry.key] =
            Holiday.fromJson(Map<String, dynamic>.from(value as Map));
        working.remove(entry.key);
      }
    }
    return AttendanceCalendar(
        id: 'accepted-${baseline.id}',
        version: reviewedVersion,
        effectiveFrom: baseline.effectiveFrom,
        weeklyOffs: baseline.weeklyOffs,
        offSaturdays: baseline.offSaturdays,
        holidays: holidays.values.toList(),
        workingDates: working.toList(),
        isConfigured: baseline.isConfigured,
        organizationId: baseline.organizationId,
        scopeId: baseline.scopeId);
  }

  PersonalCalendarState withDate(DateTime day, Holiday? holiday) =>
      PersonalCalendarState(
        baseline: baseline,
        reviewedVersion: reviewedVersion,
        dates: {
          ...dates,
          calendarDayKey(day): {'holiday': holiday?.toJson(), 'personal': true}
        },
        policy: policy,
        ruleTimeline: ruleTimeline
            .map((entry) => {
                  ...entry,
                  if (entry.containsKey('dateResets'))
                    'dateResets': (entry['dateResets'] as List)
                        .where((key) => key != calendarDayKey(day))
                        .toList(),
                })
            .toList(),
        reviewedRuleVersion: reviewedRuleVersion,
      );

  PersonalCalendarState review(
      CalendarRevision revision, Map<String, bool> choices) {
    if (revision.version != reviewedVersion + 1 ||
        choices.length != revision.changes.length ||
        !revision.changes.keys.every(choices.containsKey)) {
      throw StateError('Review all changed dates in order');
    }
    final next = {...dates};
    for (final key in revision.changes.keys) {
      final today = DateTime.now();
      final past = !DateTime.parse(key)
          .isAfter(DateTime(today.year, today.month, today.day));
      if (choices[key] == true && (policy == null || !past)) {
        next[key] = {
          'holiday': revision.changes[key],
          'personal': false,
          'revision': revision.version
        };
      } else {
        next[key] = {
          ...?next[key],
          if (next[key] == null) 'inherit': true,
          'reviewedRevision': revision.version
        };
      }
    }
    return PersonalCalendarState(
        baseline: baseline,
        reviewedVersion: revision.version,
        dates: next,
        policy: policy,
        ruleTimeline: ruleTimeline
            .map((entry) => {
                  ...entry,
                  if (entry.containsKey('dateResets'))
                    'dateResets': (entry['dateResets'] as List)
                        .where((key) => choices[key] != true)
                        .toList(),
                })
            .toList(),
        reviewedRuleVersion: reviewedRuleVersion);
  }

  // Merge unrelated device edits; conflicting decisions never overwrite silently.
  static PersonalCalendarState merge(PersonalCalendarState? base,
      PersonalCalendarState local, PersonalCalendarState? remote) {
    if (remote == null) return local;
    if (base == null) {
      if (sameCalendarValue(local.toJson(), remote.toJson())) return remote;
      throw StateError(
          'Calendar changed on another device. Review sync conflict in Profile.');
    }
    final localRules = {
      'policy': local.policy?.toJson(),
      'timeline': local.ruleTimeline,
      'reviewed': local.reviewedRuleVersion
    };
    final baseRules = {
      'policy': base.policy?.toJson(),
      'timeline': base.ruleTimeline,
      'reviewed': base.reviewedRuleVersion
    };
    final remoteRules = {
      'policy': remote.policy?.toJson(),
      'timeline': remote.ruleTimeline,
      'reviewed': remote.reviewedRuleVersion
    };
    if (!sameCalendarValue(baseRules, localRules) &&
        !sameCalendarValue(baseRules, remoteRules) &&
        !sameCalendarValue(localRules, remoteRules)) {
      throw StateError(
          'Rules changed on another device. Review the conflict in Profile.');
    }
    final useRemoteRules = sameCalendarValue(baseRules, localRules);
    if (!sameCalendarValue(
            calendarJson(base.baseline), calendarJson(local.baseline)) &&
        !sameCalendarValue(
            calendarJson(base.baseline), calendarJson(remote.baseline)) &&
        !sameCalendarValue(
            calendarJson(local.baseline), calendarJson(remote.baseline))) {
      throw StateError(
          'Calendar settings changed on another device. Review sync conflict in Profile.');
    }
    final merged = {...remote.dates};
    for (final key in {...base.dates.keys, ...local.dates.keys}) {
      if (sameCalendarValue(base.dates[key], local.dates[key])) continue;
      if (!sameCalendarValue(base.dates[key], remote.dates[key]) &&
          !sameCalendarValue(local.dates[key], remote.dates[key])) {
        throw StateError(
            'Calendar date $key changed on another device. Review sync conflict in Profile.');
      }
      final value = local.dates[key];
      if (value == null) {
        merged.remove(key);
      } else {
        merged[key] = value;
      }
    }
    if (base.reviewedVersion != local.reviewedVersion &&
        remote.reviewedVersion != base.reviewedVersion &&
        !sameCalendarValue(local.toJson(), remote.toJson())) {
      throw StateError(
          'Calendar update was reviewed on another device. Review sync conflict in Profile.');
    }
    return PersonalCalendarState(
        baseline: sameCalendarValue(
                calendarJson(base.baseline), calendarJson(local.baseline))
            ? remote.baseline
            : local.baseline,
        reviewedVersion: local.reviewedVersion > remote.reviewedVersion
            ? local.reviewedVersion
            : remote.reviewedVersion,
        dates: merged,
        policy: useRemoteRules ? remote.policy : local.policy,
        ruleTimeline: useRemoteRules ? remote.ruleTimeline : local.ruleTimeline,
        reviewedRuleVersion: useRemoteRules
            ? remote.reviewedRuleVersion
            : local.reviewedRuleVersion);
  }
}

class CalendarRevision {
  const CalendarRevision(
      {required this.id,
      required this.version,
      required this.author,
      required this.calendar,
      required this.changes});
  final String id, author;
  final int version;
  final AttendanceCalendar calendar;
  final Map<String, Object?> changes;
  factory CalendarRevision.fromJson(String id, Map<String, dynamic> json) =>
      CalendarRevision(
        id: id,
        version: (json['version'] as num).toInt(),
        author: json['author'] as String,
        calendar: calendarFromJson(
            Map<String, dynamic>.from(json['calendar'] as Map)),
        changes: Map<String, Object?>.from(json['changes'] as Map),
      );
}
