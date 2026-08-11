enum AttendanceStatus { full, half, partial, absent, holiday, none }
enum CalculationBasis { hours, days, periods }
enum AppRole { student, employee }
enum OrganizationType { college, company }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.mobile,
    required this.role,
    this.currentOrganizationId,
    this.identificationNumber,
    this.isOrganizationVerified = false,
    this.pinEnabled = false,
  });

  final String uid;
  final String displayName;
  final String? mobile;
  final AppRole role;
  final String? currentOrganizationId;
  final String? identificationNumber;
  final bool isOrganizationVerified;
  final bool pinEnabled;

  UserProfile copyWith({
    String? displayName,
    String? mobile,
    AppRole? role,
    String? currentOrganizationId,
    String? identificationNumber,
    bool? isOrganizationVerified,
    bool? pinEnabled,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        mobile: mobile ?? this.mobile,
        role: role ?? this.role,
        currentOrganizationId: currentOrganizationId ?? this.currentOrganizationId,
        identificationNumber: identificationNumber ?? this.identificationNumber,
        isOrganizationVerified: isOrganizationVerified ?? this.isOrganizationVerified,
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
    this.followerCount = 0,
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String? branch;
  final bool isVerified;
  final int followerCount;
}

class AttendancePolicy {
  const AttendancePolicy({
    required this.id,
    required this.version,
    required this.effectiveFrom,
    required this.minimumPercent,
    required this.basis,
    required this.fullUnit,
    required this.halfUnit,
  });

  final String id;
  final int version;
  final DateTime effectiveFrom;
  final double minimumPercent;
  final CalculationBasis basis;
  final double fullUnit;
  final double halfUnit;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    required this.actualUnits,
    required this.expectedUnits,
    this.pendingSync = false,
  });

  final DateTime date;
  final AttendanceStatus status;
  final double actualUnits;
  final double expectedUnits;
  final bool pendingSync;

  AttendanceRecord copyWith({bool? pendingSync}) => AttendanceRecord(
        date: date,
        status: status,
        actualUnits: actualUnits,
        expectedUnits: expectedUnits,
        pendingSync: pendingSync ?? this.pendingSync,
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
  });

  final double actual;
  final double expected;
  final double percent;
  final bool isSafe;
  final double safeToMiss;
  final double unitsToRecover;
}
