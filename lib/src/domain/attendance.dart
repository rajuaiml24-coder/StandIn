import 'dart:convert';
import 'package:crypto/crypto.dart';

enum AttendanceStatus {
  full,
  half,
  partial,
  absent,
  holiday,
  none,
  leave,
  weeklyOff
}

enum CalculationBasis {
  hours,
  days,
  periods;

  String label(double value, {bool isContext = false}) {
    final isPlural = value.abs() != 1.0;
    return switch (this) {
      CalculationBasis.hours => isPlural ? 'hours' : 'hour',
      CalculationBasis.days => isContext
          ? (isPlural ? 'working days' : 'working day')
          : (isPlural ? 'days' : 'day'),
      CalculationBasis.periods => isPlural ? 'classes' : 'class',
    };
  }
}

enum AppRole { student, employee }

enum OrganizationType { college, company }

enum PolicyState { draft, community, confirmed, official, personal }

enum EvaluationPeriod {
  weekly,
  monthly,
  quarterly,
  semester,
  academicYear,
  halfYear,
  custom
}

enum PeriodStatus { onTrack, atRisk, impossible }

enum LeaveTreatment { noCredit, countsTowardTarget, excluded }

enum AttendanceDayType { working, weeklyOff, holiday }

String formatAttendanceUnits(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

String attendanceStatusLabel(AttendanceStatus status,
        {bool company = false, bool oneVisit = false}) =>
    switch (status) {
      AttendanceStatus.full =>
        company ? 'Swiped' : (oneVisit ? 'Attended' : 'Full'),
      AttendanceStatus.half => 'Half day',
      AttendanceStatus.partial => 'Partial',
      AttendanceStatus.absent => company ? 'Not swiped' : 'Absent',
      AttendanceStatus.holiday => 'Holiday',
      AttendanceStatus.leave => 'Leave',
      AttendanceStatus.weeklyOff => 'Day off',
      AttendanceStatus.none => 'Not marked',
    };

class Holiday {
  const Holiday({
    required this.date,
    required this.name,
    this.isOptional = false,
  });

  final DateTime date;
  final String name;
  final bool isOptional;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'name': name,
        'isOptional': isOptional,
      };

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
        date: DateTime.parse(json['date'] as String),
        name: json['name'] as String,
        isOptional: json['isOptional'] as bool? ?? false,
      );
}

class AttendanceCalendar {
  const AttendanceCalendar({
    required this.id,
    required this.version,
    required this.effectiveFrom,
    this.weeklyOffs = const [],
    this.offSaturdays = const [],
    this.holidays = const [],
    this.isConfigured = false,
    this.organizationId,
    this.scopeId,
    this.workingDates = const [],
  });

  static final unconfigured = AttendanceCalendar(
    id: 'unconfigured',
    version: 0,
    effectiveFrom: DateTime(2000),
    weeklyOffs: const [],
    offSaturdays: const [],
    holidays: const [],
    isConfigured: false,
  );

  final String id;
  final int version;
  final DateTime effectiveFrom;
  final List<int> weeklyOffs;
  final List<int> offSaturdays; // [1, 2, 3, 4, 5]
  final List<Holiday> holidays;
  final bool isConfigured;
  final String? organizationId;
  final String? scopeId;
  final List<String> workingDates;

  bool isNonWorkingDay(DateTime date) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (workingDates.contains(key)) return false;
    if (!isConfigured) {
      return holidays.any((h) =>
          h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day);
    }

    // Check Weekly Offs
    final weekday = date.weekday;
    if (weeklyOffs.contains(weekday)) return true;

    // Check Saturday specific logic if Saturday (6) is NOT already a weekly off
    if (weekday == DateTime.saturday) {
      final weekIndex = ((date.day - 1) / 7).floor() + 1;
      if (offSaturdays.contains(weekIndex)) return true;
    }

    // Check Holidays
    return holidays.any((h) =>
        h.date.year == date.year &&
        h.date.month == date.month &&
        h.date.day == date.day);
  }

  bool isOffDay(DateTime date) => isNonWorkingDay(date);

  AttendanceCalendar copyWith({
    String? organizationId,
    String? scopeId,
    List<int>? weeklyOffs,
    List<int>? offSaturdays,
    bool? isConfigured,
    List<Holiday>? holidays,
    List<String>? workingDates,
  }) =>
      AttendanceCalendar(
        id: id,
        version: version,
        effectiveFrom: effectiveFrom,
        weeklyOffs: weeklyOffs ?? this.weeklyOffs,
        offSaturdays: offSaturdays ?? this.offSaturdays,
        holidays: holidays ?? this.holidays,
        isConfigured: isConfigured ?? this.isConfigured,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
        workingDates: workingDates ?? this.workingDates,
      );
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.mobile,
    this.registrationNumber,
    required this.role,
    this.activeFollowId,
    this.pinEnabled = false,
  });

  final String uid;
  final String displayName;
  final String? mobile;
  final String? registrationNumber;
  final AppRole role;
  final String? activeFollowId;
  final bool pinEnabled;

  UserProfile copyWith({
    String? displayName,
    String? mobile,
    String? registrationNumber,
    AppRole? role,
    String? activeFollowId,
    bool? pinEnabled,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        mobile: mobile ?? this.mobile,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        role: role ?? this.role,
        activeFollowId: activeFollowId ?? this.activeFollowId,
        pinEnabled: pinEnabled ?? this.pinEnabled,
      );
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.type,
    this.branch,
    this.isVerified = false,
    this.isHolidayCalendarConfigured = false,
    this.followerCount = 0,
    this.confidenceScore = 0.0,
    this.activePolicyId,
    this.activeCalendarId,
    this.createdBy,
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String? branch;
  final bool isVerified;
  final bool isHolidayCalendarConfigured;
  final int followerCount;
  final double confidenceScore;
  final String? activePolicyId;
  final String? activeCalendarId;
  final String? createdBy;

  String get anonymousCreatorId {
    if (createdBy == null || createdBy!.isEmpty) return 'USR-UNKNOWN';
    final bytes = utf8.encode(createdBy!);
    final digest = sha256.convert(bytes);
    return 'USR-${digest.toString().substring(0, 6).toUpperCase()}';
  }

  Organization copyWith({
    String? id,
    String? name,
    OrganizationType? type,
    String? branch,
    bool? isVerified,
    bool? isHolidayCalendarConfigured,
    int? followerCount,
    double? confidenceScore,
    String? activePolicyId,
    String? activeCalendarId,
    String? createdBy,
  }) =>
      Organization(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        branch: branch ?? this.branch,
        isVerified: isVerified ?? this.isVerified,
        isHolidayCalendarConfigured:
            isHolidayCalendarConfigured ?? this.isHolidayCalendarConfigured,
        followerCount: followerCount ?? this.followerCount,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        activePolicyId: activePolicyId ?? this.activePolicyId,
        activeCalendarId: activeCalendarId ?? this.activeCalendarId,
        createdBy: createdBy ?? this.createdBy,
      );
}

class Scope {
  const Scope({
    required this.id,
    required this.organizationId,
    this.parentId,
    required this.type,
    required this.name,
    this.activePolicyId,
    this.activeCalendarId,
    this.followerCount = 0,
    this.createdBy,
    this.isArchived = false,
  });

  final String id;
  final String organizationId;
  final String? parentId;
  final String type; // Enum-like: branch, department, semester, team
  final String name;
  final String? activePolicyId;
  final String? activeCalendarId;
  final int followerCount;
  final String? createdBy;
  final bool isArchived;

  Scope copyWith(
          {String? activePolicyId,
          String? activeCalendarId,
          int? followerCount,
          bool? isArchived}) =>
      Scope(
        id: id,
        organizationId: organizationId,
        parentId: parentId,
        type: type,
        name: name,
        activePolicyId: activePolicyId ?? this.activePolicyId,
        activeCalendarId: activeCalendarId ?? this.activeCalendarId,
        followerCount: followerCount ?? this.followerCount,
        createdBy: createdBy,
        isArchived: isArchived ?? this.isArchived,
      );

  static String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String generateId(String orgId, String type, String name,
      [String? parentId]) {
    final normalized = normalizeName(name);
    final base = '${orgId}_${type}_$normalized';
    return parentId != null ? '${base}_$parentId' : base;
  }
}

class Follow {
  static String personalOrganizationId(String uid) => 'personal:$uid';
  static bool isPersonalOrganization(String organizationId) =>
      organizationId.startsWith('personal:');
  const Follow({
    required this.id,
    required this.organizationId,
    required this.scopeId,
    this.personalTargetPercent,
    required this.status,
    required this.followedAt,
    this.personalBasis,
    this.personalEvaluationPeriod,
    this.personalFullUnit,
    this.personalHalfUnit,
    this.personalStartDate,
    this.personalEndDate,
    this.personalWeeklyOffs,
    this.personalOffSaturdays,
    this.personalHolidays,
    this.isPersonalCalendarConfigured = false,
  });

  final String id;
  final String organizationId;
  final String scopeId;
  final double? personalTargetPercent;
  final String status; // Enum-like: active, archived
  final DateTime followedAt;
  final CalculationBasis? personalBasis;
  final EvaluationPeriod? personalEvaluationPeriod;
  final double? personalFullUnit;
  final double? personalHalfUnit;
  final DateTime? personalStartDate;
  final DateTime? personalEndDate;
  final String? personalWeeklyOffs;
  final String? personalOffSaturdays;
  final String? personalHolidays;
  final bool isPersonalCalendarConfigured;

  bool get isPersonalCalculation => isPersonalOrganization(organizationId);

  bool get hasPersonalSettings =>
      personalBasis != null ||
      personalTargetPercent != null ||
      personalEvaluationPeriod != null ||
      personalFullUnit != null ||
      personalHalfUnit != null ||
      personalStartDate != null ||
      personalEndDate != null ||
      isPersonalCalendarConfigured;

  Follow get withoutPersonalSettings => Follow(
      id: id,
      organizationId: organizationId,
      scopeId: scopeId,
      status: status,
      followedAt: followedAt);

  Follow copyWith({
    String? id,
    String? organizationId,
    String? scopeId,
    double? personalTargetPercent,
    String? status,
    DateTime? followedAt,
    CalculationBasis? personalBasis,
    EvaluationPeriod? personalEvaluationPeriod,
    double? personalFullUnit,
    double? personalHalfUnit,
    DateTime? personalStartDate,
    DateTime? personalEndDate,
    String? personalWeeklyOffs,
    String? personalOffSaturdays,
    String? personalHolidays,
    bool? isPersonalCalendarConfigured,
  }) =>
      Follow(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
        personalTargetPercent:
            personalTargetPercent ?? this.personalTargetPercent,
        status: status ?? this.status,
        followedAt: followedAt ?? this.followedAt,
        personalBasis: personalBasis ?? this.personalBasis,
        personalEvaluationPeriod:
            personalEvaluationPeriod ?? this.personalEvaluationPeriod,
        personalFullUnit: personalFullUnit ?? this.personalFullUnit,
        personalHalfUnit: personalHalfUnit ?? this.personalHalfUnit,
        personalStartDate: personalStartDate ?? this.personalStartDate,
        personalEndDate: personalEndDate ?? this.personalEndDate,
        personalWeeklyOffs: personalWeeklyOffs ?? this.personalWeeklyOffs,
        personalOffSaturdays: personalOffSaturdays ?? this.personalOffSaturdays,
        personalHolidays: personalHolidays ?? this.personalHolidays,
        isPersonalCalendarConfigured:
            isPersonalCalendarConfigured ?? this.isPersonalCalendarConfigured,
      );
}

class Membership {
  const Membership({
    required this.uid,
    required this.organizationId,
    required this.status,
    this.idNumber,
    required this.joinedAt,
    this.verifiedAt,
  });

  final String uid;
  final String organizationId;
  final String status; // Enum-like: follower, applicant, verified_member
  final String? idNumber;
  final DateTime joinedAt;
  final DateTime? verifiedAt;
}

class AttendancePolicy {
  const AttendancePolicy({
    required this.id,
    required this.version,
    required this.effectiveFrom,
    required this.state,
    required this.evaluationPeriod,
    this.minimumPercent,
    required this.basis,
    required this.fullUnit,
    required this.halfUnit,
    this.weeklyOffs = const [7], // Default Sunday
    this.startDate,
    this.endDate,
    this.scopeId,
    this.organizationId,
    this.leaveTreatment = LeaveTreatment.noCredit,
    this.weekOffCredit = false,
    this.holidayCredit = false,
    this.oneVisitFullDay = false,
  });

  final String id;
  final int version;
  final DateTime effectiveFrom;
  final PolicyState state;
  final EvaluationPeriod evaluationPeriod;
  final double? minimumPercent;
  final CalculationBasis basis;
  final double fullUnit;
  final double halfUnit;
  final List<int> weeklyOffs;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? scopeId;
  final String? organizationId;
  final LeaveTreatment leaveTreatment;
  final bool weekOffCredit, holidayCredit;

  /// One class or swipe earns one day, independent of duration.
  final bool oneVisitFullDay;

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'state': state.name,
        'evaluationPeriod': evaluationPeriod.name,
        'minimumPercent': minimumPercent,
        'basis': basis.name,
        'fullUnit': fullUnit,
        'halfUnit': halfUnit,
        'weeklyOffs': weeklyOffs,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'organizationId': organizationId,
        'scopeId': scopeId,
        'leaveTreatment': leaveTreatment.name,
        'weekOffCredit': weekOffCredit,
        'holidayCredit': holidayCredit,
        if (oneVisitFullDay) 'oneVisitFullDay': true,
      };

  factory AttendancePolicy.fromJson(Map<String, dynamic> json) =>
      AttendancePolicy(
        id: json['id'] as String,
        version: (json['version'] as num).toInt(),
        effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
        state: PolicyState.values.byName(json['state'] as String),
        evaluationPeriod:
            EvaluationPeriod.values.byName(json['evaluationPeriod'] as String),
        minimumPercent: (json['minimumPercent'] as num?)?.toDouble(),
        basis: CalculationBasis.values.byName(json['basis'] as String),
        fullUnit: (json['fullUnit'] as num).toDouble(),
        halfUnit: (json['halfUnit'] as num).toDouble(),
        weeklyOffs: (json['weeklyOffs'] as List? ?? []).cast<int>(),
        startDate: json['startDate'] == null
            ? null
            : DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null
            ? null
            : DateTime.parse(json['endDate'] as String),
        organizationId: json['organizationId'] as String?,
        scopeId: json['scopeId'] as String?,
        leaveTreatment: LeaveTreatment.values
            .byName(json['leaveTreatment'] as String? ?? 'noCredit'),
        weekOffCredit: json['weekOffCredit'] as bool? ?? false,
        holidayCredit: json['holidayCredit'] as bool? ?? false,
        oneVisitFullDay: json['oneVisitFullDay'] as bool? ?? false,
      );

  bool get isSure => minimumPercent != null;

  bool get hasValidUnits =>
      (!oneVisitFullDay || (basis == CalculationBasis.days && fullUnit == 1)) &&
      fullUnit.isFinite &&
      fullUnit > 0 &&
      halfUnit.isFinite &&
      halfUnit >= 0 &&
      halfUnit <= fullUnit;

  bool get hasValidTarget =>
      minimumPercent != null &&
      minimumPercent!.isFinite &&
      minimumPercent! >= 0 &&
      minimumPercent! <= 100;

  AttendancePolicy copyWith({
    String? id,
    int? version,
    DateTime? effectiveFrom,
    PolicyState? state,
    EvaluationPeriod? evaluationPeriod,
    double? minimumPercent,
    CalculationBasis? basis,
    double? fullUnit,
    double? halfUnit,
    List<int>? weeklyOffs,
    DateTime? startDate,
    DateTime? endDate,
    String? organizationId,
    String? scopeId,
    LeaveTreatment? leaveTreatment,
    bool? weekOffCredit,
    bool? holidayCredit,
    bool? oneVisitFullDay,
  }) =>
      AttendancePolicy(
        id: id ?? this.id,
        version: version ?? this.version,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        state: state ?? this.state,
        evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
        minimumPercent: minimumPercent ?? this.minimumPercent,
        basis: basis ?? this.basis,
        fullUnit: fullUnit ?? this.fullUnit,
        halfUnit: halfUnit ?? this.halfUnit,
        weeklyOffs: weeklyOffs ?? this.weeklyOffs,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        scopeId: scopeId ?? this.scopeId,
        organizationId: organizationId ?? this.organizationId,
        leaveTreatment: leaveTreatment ?? this.leaveTreatment,
        weekOffCredit: weekOffCredit ?? this.weekOffCredit,
        holidayCredit: holidayCredit ?? this.holidayCredit,
        oneVisitFullDay: oneVisitFullDay ?? this.oneVisitFullDay,
      );
}

/// The saved contribution is independent of future policy/calendar changes.
class AttendanceSnapshot {
  const AttendanceSnapshot(
      {required this.policy,
      required this.dayType,
      required this.physical,
      required this.leaveCredit,
      required this.extraCredit,
      required this.requiredUnits,
      required this.periodStart,
      required this.periodEnd,
      this.legacy = false});
  final AttendancePolicy policy;
  final AttendanceDayType dayType;
  final double physical, leaveCredit, extraCredit, requiredUnits;
  final DateTime periodStart, periodEnd;
  final bool legacy;
  double get credited => physical + leaveCredit + extraCredit;
  Map<String, dynamic> toJson() => {
        'schema': policy.oneVisitFullDay ? 2 : 1,
        'policy': policy.toJson(),
        'dayType': dayType.name,
        'physical': physical,
        'leaveCredit': leaveCredit,
        'extraCredit': extraCredit,
        'requiredUnits': requiredUnits,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'legacy': legacy,
      };
  factory AttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 && json['schema'] != 2) {
      throw StateError('Update StandIn to edit this attendance');
    }
    return AttendanceSnapshot(
        policy: AttendancePolicy.fromJson(
            Map<String, dynamic>.from(json['policy'] as Map)),
        dayType: AttendanceDayType.values.byName(json['dayType'] as String),
        physical: (json['physical'] as num).toDouble(),
        leaveCredit: (json['leaveCredit'] as num).toDouble(),
        extraCredit: (json['extraCredit'] as num).toDouble(),
        requiredUnits: (json['requiredUnits'] as num).toDouble(),
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        legacy: json['legacy'] as bool? ?? false);
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    required this.actualUnits,
    required this.expectedUnits,
    this.pendingSync = false,
    this.source = 'manual',
    this.policyVersionId,
    this.calendarVersionId,
    this.organizationId,
    this.scopeId,
    this.updatedAt,
    this.snapshot,
    this.leaveUnits = 0,
    this.revisionId,
    this.baseRevision,
    this.history = const [],
  });

  final DateTime date;
  final AttendanceStatus status;
  final double actualUnits;
  final double expectedUnits;
  final bool pendingSync;
  final String source;
  final String? policyVersionId;
  final String? calendarVersionId;
  final String? organizationId;
  final String? scopeId;
  final DateTime? updatedAt;
  final AttendanceSnapshot? snapshot;
  final double leaveUnits;
  final String? revisionId, baseRevision;
  final List<Map<String, dynamic>> history;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'status': status.name,
        'actualUnits': actualUnits,
        'expectedUnits': expectedUnits,
        'organizationId': organizationId,
        'scopeId': scopeId,
        'policyVersionId': policyVersionId,
        'calendarVersionId': calendarVersionId,
        'source': source,
        'leaveUnits': leaveUnits,
        if (snapshot != null) 'snapshot': snapshot!.toJson(),
        if (revisionId != null) 'revisionId': revisionId,
        if (baseRevision != null) 'baseRevision': baseRevision,
        if (history.isNotEmpty) 'history': history,
      };
  factory AttendanceRecord.fromJson(Map<String, dynamic> json,
          {bool pendingSync = true, DateTime? updatedAt}) =>
      AttendanceRecord(
          date: DateTime.parse(json['date'] as String),
          status: AttendanceStatus.values.byName(json['status'] as String),
          actualUnits: (json['actualUnits'] as num).toDouble(),
          expectedUnits: (json['expectedUnits'] as num).toDouble(),
          organizationId: json['organizationId'] as String?,
          scopeId: json['scopeId'] as String?,
          policyVersionId: json['policyVersionId'] as String?,
          calendarVersionId: json['calendarVersionId'] as String?,
          source: json['source'] as String? ?? 'manual',
          pendingSync: pendingSync,
          updatedAt: updatedAt,
          snapshot: json['snapshot'] == null
              ? null
              : AttendanceSnapshot.fromJson(
                  Map<String, dynamic>.from(json['snapshot'] as Map)),
          leaveUnits: (json['leaveUnits'] as num?)?.toDouble() ?? 0,
          revisionId: json['revisionId'] as String?,
          baseRevision: json['baseRevision'] as String?,
          history: (json['history'] as List? ?? [])
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList());

  String get fingerprint => revisionId ?? legacyFingerprint;
  String get legacyFingerprint => sha256
      .convert(utf8.encode(jsonEncode({
        'date': date.toIso8601String().substring(0, 10),
        'status': status.name,
        'actualUnits': actualUnits,
        'expectedUnits': expectedUnits,
        'organizationId': organizationId,
        'scopeId': scopeId,
        'policyVersionId': policyVersionId,
        'calendarVersionId': calendarVersionId,
      })))
      .toString();

  AttendanceRecord copyWith({
    bool? pendingSync,
    String? organizationId,
    String? scopeId,
    String? policyVersionId,
    String? calendarVersionId,
    AttendanceStatus? status,
    double? actualUnits,
    double? expectedUnits,
    AttendanceSnapshot? snapshot,
    double? leaveUnits,
    String? revisionId,
    String? baseRevision,
    List<Map<String, dynamic>>? history,
  }) =>
      AttendanceRecord(
        date: date,
        status: status ?? this.status,
        actualUnits: actualUnits ?? this.actualUnits,
        expectedUnits: expectedUnits ?? this.expectedUnits,
        pendingSync: pendingSync ?? this.pendingSync,
        source: source,
        policyVersionId: policyVersionId ?? this.policyVersionId,
        calendarVersionId: calendarVersionId ?? this.calendarVersionId,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
        updatedAt: updatedAt,
        snapshot: snapshot ?? this.snapshot,
        leaveUnits: leaveUnits ?? this.leaveUnits,
        revisionId: revisionId ?? this.revisionId,
        baseRevision: baseRevision ?? this.baseRevision,
        history: history ?? this.history,
      );
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.actual,
    required this.expected,
    required this.conductedToDate,
    required this.totalConducted,
    required this.percent,
    required this.maximumPossible,
    required this.maximumPercent,
    required this.isSafe,
    required this.isAchievable,
    required this.safeToMiss,
    required this.unitsToRecover,
    required this.shortfall,
    required this.unmarkedCount,
    required this.periodLabel,
    this.totalExpectedInPeriod = 0,
    this.isPolicyIncomplete = false,
    this.isEstimation = false,
    this.recoveryMessage = '',
    this.progressLabel = '',
    required this.status,
    required this.attendedLabel,
    required this.conductedLabel,
    this.maxPossiblePercent = 0.0,
    this.physicalUnits = 0,
    this.leaveCredit = 0,
    this.extraCredit = 0,
  });

  final double actual; // A
  final double
      expected; // For backward compatibility if needed, same as conductedToDate
  final double conductedToDate; // C_d
  final double totalConducted; // C_t
  final double percent; // (A / C_d) * 100
  final double maximumPossible; // M = A + Unmarked + Future
  final double maximumPercent; // (M / C_t) * 100
  final bool isSafe; // A >= Target Units for whole period
  final bool isAchievable; // M >= Target Units for whole period
  final double safeToMiss;
  final double unitsToRecover;
  final double shortfall;
  final int unmarkedCount; // Count of past working days without records
  final String periodLabel;
  final double totalExpectedInPeriod;
  final bool isPolicyIncomplete;
  final bool isEstimation;
  final String recoveryMessage;
  final String progressLabel;
  final PeriodStatus status;
  final String attendedLabel;
  final String conductedLabel;
  final double maxPossiblePercent;
  final double physicalUnits, leaveCredit, extraCredit;

  bool get needsAttention => unmarkedCount > 0;
}
