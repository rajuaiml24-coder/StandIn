import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'attendance.dart';

String planningPolicyKey(AttendancePolicy policy) => sha256
    .convert(utf8.encode(jsonEncode([
      policy.id,
      policy.version,
      policy.basis.name,
      policy.fullUnit,
      policy.halfUnit,
      policy.minimumPercent,
      policy.evaluationPeriod.name,
      policy.startDate?.toIso8601String(),
      policy.endDate?.toIso8601String(),
      if (policy.oneVisitFullDay) 'oneVisitFullDay',
      if (policy.leaveTreatment != LeaveTreatment.noCredit ||
          policy.weekOffCredit ||
          policy.holidayCredit) ...[
        policy.leaveTreatment.name,
        policy.weekOffCredit,
        policy.holidayCredit,
      ],
    ])))
    .toString();

String planningCalendarKey(AttendanceCalendar calendar) => sha256
    .convert(utf8.encode(jsonEncode([
      calendar.id,
      calendar.version,
      [...calendar.weeklyOffs]..sort(),
      [...calendar.offSaturdays]..sort(),
      [...calendar.workingDates]..sort(),
      calendar.holidays
          .map((h) => h.date.toIso8601String().substring(0, 10))
          .toList()
        ..sort(),
    ])))
    .toString();

class AttendancePlan {
  const AttendancePlan(
      {required this.id,
      required this.organizationId,
      required this.scopeId,
      required this.date,
      required this.status,
      required this.units,
      this.leaveUnits = 0,
      this.policyVersionId,
      this.calendarVersionId,
      this.isDeleted = false,
      this.pendingSync = true,
      this.updatedAt});

  final String id;
  final String organizationId;
  final String scopeId;
  final DateTime date;
  final AttendanceStatus status;
  final double units;
  final double leaveUnits;
  final String? policyVersionId;
  final String? calendarVersionId;
  final bool isDeleted;
  final bool pendingSync;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'scopeId': scopeId,
        'date': date.toIso8601String(),
        'status': status.name,
        'units': units,
        if (leaveUnits > 0) 'leaveUnits': leaveUnits,
        'policyVersionId': policyVersionId,
        'calendarVersionId': calendarVersionId,
        'isDeleted': isDeleted,
      };

  factory AttendancePlan.fromJson(Map<String, dynamic> json,
          {DateTime? updatedAt, bool pendingSync = true}) =>
      AttendancePlan(
        id: json['id'] as String,
        organizationId: json['organizationId'] as String,
        scopeId: json['scopeId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatus.values.byName(json['status'] as String),
        units: (json['units'] as num).toDouble(),
        leaveUnits: (json['leaveUnits'] as num?)?.toDouble() ?? 0,
        policyVersionId: json['policyVersionId'] as String?,
        calendarVersionId: json['calendarVersionId'] as String?,
        isDeleted: json['isDeleted'] as bool? ?? false,
        pendingSync: pendingSync,
        updatedAt: updatedAt,
      );
}

class PlanningSummary {
  const PlanningSummary(
      {required this.confirmedUnits,
      required this.plannedUnits,
      required this.totalExpected,
      required this.percent,
      required this.meetsTarget,
      required this.unitsStillNeeded,
      required this.isIncomplete,
      required this.unconfirmedCount,
      required this.changedRuleCount});
  final double confirmedUnits;
  final double plannedUnits;
  final double totalExpected;
  final double percent;
  final bool meetsTarget;
  final double unitsStillNeeded;
  final bool isIncomplete;
  final int unconfirmedCount;
  final int changedRuleCount;
}
