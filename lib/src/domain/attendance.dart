enum AttendanceStatus { full, half, partial, absent, holiday, none, leave, weeklyOff }
enum CalculationBasis { hours, days, periods }
enum AppRole { student, employee }
enum OrganizationType { college, company }
enum PolicyState { draft, community, confirmed, official }
enum EvaluationPeriod { weekly, monthly, quarterly, semester, academicYear, halfYear, custom }

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
}

class Follow {
  const Follow({
    required this.id,
    required this.organizationId,
    required this.scopeId,
    this.personalTargetPercent,
    required this.status,
    required this.followedAt,
  });

  final String id;
  final String organizationId;
  final String scopeId;
  final double? personalTargetPercent;
  final String status; // Enum-like: active, archived
  final DateTime followedAt;
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

  bool get isSure => minimumPercent != null;
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
    required this.percent,
    required this.isSafe,
    required this.safeToMiss,
    required this.unitsToRecover,
    required this.periodLabel,
    this.totalExpectedInPeriod = 0,
    this.isPolicyIncomplete = false,
    this.isEstimation = false,
    this.recoveryMessage = '',
  });

  final double actual;
  final double expected;
  final double percent;
  final bool isSafe;
  final double safeToMiss;
  final double unitsToRecover;
  final String periodLabel;
  final double totalExpectedInPeriod;
  final bool isPolicyIncomplete;
  final bool isEstimation;
  final String recoveryMessage;
}
