
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum AttendanceStatus { full, half, partial, absent, holiday, none, leave, weeklyOff }

enum CalculationBasis {
  hours,
  days,
  periods;

  String label(double value, {bool isContext = false}) {
    final isPlural = value.abs() != 1.0;
    return switch (this) {
      CalculationBasis.hours => isPlural ? 'hours' : 'hour',
      CalculationBasis.days => isContext ? (isPlural ? 'working days' : 'working day') : (isPlural ? 'days' : 'day'),
      CalculationBasis.periods => isPlural ? 'classes' : 'class',
    };
  }
}
enum AppRole { student, employee }
enum OrganizationType { college, company }
enum PolicyState { draft, community, confirmed, official, personal }
enum EvaluationPeriod { weekly, monthly, quarterly, semester, academicYear, halfYear, custom }
enum PeriodStatus { onTrack, atRisk, impossible }

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

  bool isNonWorkingDay(DateTime date) {
    if (!isConfigured) return false;
    
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
      h.date.day == date.day
    );
  }

  bool isOffDay(DateTime date) => isNonWorkingDay(date);

  AttendanceCalendar copyWith({
    String? organizationId,
    String? scopeId,
    List<Holiday>? holidays,
  }) => AttendanceCalendar(
    id: id,
    version: version,
    effectiveFrom: effectiveFrom,
    weeklyOffs: weeklyOffs,
    offSaturdays: offSaturdays,
    holidays: holidays ?? this.holidays,
    isConfigured: isConfigured,
    organizationId: organizationId ?? this.organizationId,
    scopeId: scopeId ?? this.scopeId,
  );
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.mobile,
    required this.role,
    this.activeFollowId,
    this.pinEnabled = false,
  });

  final String uid;
  final String displayName;
  final String? mobile;
  final AppRole role;
  final String? activeFollowId;
  final bool pinEnabled;

  UserProfile copyWith({
    String? displayName,
    String? mobile,
    AppRole? role,
    String? activeFollowId,
    bool? pinEnabled,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        mobile: mobile ?? this.mobile,
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
  });

  final String id;
  final String organizationId;
  final String? parentId;
  final String type; // Enum-like: branch, department, semester, team
  final String name;
  final String? activePolicyId;
  final String? activeCalendarId;

  static String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String generateId(String orgId, String type, String name, [String? parentId]) {
    final normalized = normalizeName(name);
    final base = '${orgId}_${type}_$normalized';
    return parentId != null ? '${base}_$parentId' : base;
  }
}

class Follow {
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

  bool get hasPersonalSettings => personalBasis != null;
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

  bool get isSure => minimumPercent != null;

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
  }) => AttendancePolicy(
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
  );
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

  AttendanceRecord copyWith({
    bool? pendingSync,
    String? organizationId,
    String? scopeId,
    String? policyVersionId,
    String? calendarVersionId,
    AttendanceStatus? status,
    double? actualUnits,
  }) =>
      AttendanceRecord(
        date: date,
        status: status ?? this.status,
        actualUnits: actualUnits ?? this.actualUnits,
        expectedUnits: expectedUnits,
        pendingSync: pendingSync ?? this.pendingSync,
        source: source,
        policyVersionId: policyVersionId ?? this.policyVersionId,
        calendarVersionId: calendarVersionId ?? this.calendarVersionId,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
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
  });

  final double actual; // A
  final double expected; // For backward compatibility if needed, same as conductedToDate
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

  bool get needsAttention => unmarkedCount > 0;
}
