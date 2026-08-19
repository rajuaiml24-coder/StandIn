import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'remote/firestore_org_remote.dart';
import 'remote/firestore_user_remote.dart';

class OrganizationRepository {
  OrganizationRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreOrgRemote _remote;

  Future<List<Organization>> searchOrganizations(String query, OrganizationType type) async {
    // 1. Check local cache first for empty query (popular orgs might be cached)
    final remote = await _remote.searchOrganizations(query, type);
    for (var org in remote) {
      await _database.upsertOrganization(OrganizationRowsCompanion.insert(
        id: org.id,
        name: org.name,
        type: org.type.name,
        branch: Value(org.branch),
        isVerified: Value(org.isVerified),
        isHolidayCalendarConfigured: Value(org.isHolidayCalendarConfigured),
        followerCount: Value(org.followerCount),
        activePolicyId: Value(org.activePolicyId),
        activeCalendarId: Value(org.activeCalendarId),
        createdBy: Value(org.createdBy),
        updatedAt: DateTime.now(),
      ));
    }
    return remote;
  }

  Future<void> incrementFollowerCount(String orgId) async {
    await _remote.incrementFollowerCount(orgId);
    // Locally increment too
    final local = await _database.getOrganization(orgId);
    if (local != null) {
      await (_database.update(_database.organizationRows)..where((t) => t.id.equals(orgId))).write(
        OrganizationRowsCompanion(
          followerCount: Value(local.followerCount + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> saveOrganization(Organization org, String uid) async {
    await _database.transaction(() async {
      await _database.upsertOrganization(OrganizationRowsCompanion.insert(
        id: org.id,
        name: org.name,
        type: org.type.name,
        branch: Value(org.branch),
        followerCount: Value(org.followerCount),
        activePolicyId: Value(org.activePolicyId),
        activeCalendarId: Value(org.activeCalendarId),
        createdBy: Value(org.createdBy),
        updatedAt: DateTime.now(),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'org:${org.id}',
        operation: 'putOrganization',
        entityId: org.id,
        payload: jsonEncode({
          'id': org.id,
          'name': org.name,
          'type': org.type.name,
          'branch': org.branch,
          'followerCount': org.followerCount,
          'activePolicyId': org.activePolicyId,
          'activeCalendarId': org.activeCalendarId,
          'uid': uid,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<List<Scope>> getScopesForParent(String orgId, String? parentId) async {
    // Try local first
    // Drift doesn't have a specific getScopes method yet, let's use remote for discovery
    // and caching. In a real app we'd pull these in background sync.
    final remote = await _remote.getScopes(orgId, parentId: parentId);
    for (var scope in remote) {
      await _database.upsertScope(ScopeRowsCompanion.insert(
        id: scope.id,
        organizationId: scope.organizationId,
        parentId: Value(scope.parentId),
        type: scope.type,
        name: scope.name,
        activePolicyId: Value(scope.activePolicyId),
        activeCalendarId: Value(scope.activeCalendarId),
      ));
    }
    return remote;
  }

  Future<void> saveScope(Scope scope) async {
    await _database.transaction(() async {
      await _database.upsertScope(ScopeRowsCompanion.insert(
        id: scope.id,
        organizationId: scope.organizationId,
        parentId: Value(scope.parentId),
        type: scope.type,
        name: scope.name,
        activePolicyId: Value(scope.activePolicyId),
        activeCalendarId: Value(scope.activeCalendarId),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'scope:${scope.id}',
        operation: 'putScope',
        entityId: scope.id,
        payload: jsonEncode({
          'id': scope.id,
          'organizationId': scope.organizationId,
          'parentId': scope.parentId,
          'type': scope.type,
          'name': scope.name,
          'activePolicyId': scope.activePolicyId,
          'activeCalendarId': scope.activeCalendarId,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  /// Full transaction for organization setup:
  /// Org + Policy + Calendar + Membership + Follow
  Future<void> setupOrganization({
    required Organization org,
    required AttendancePolicy policy,
    required AttendanceCalendar calendar,
    required Membership membership,
    required Follow follow,
    required String uid,
    List<Scope> scopes = const [],
  }) async {
    await _database.transaction(() async {
      // 1. Save Organization
      await _database.upsertOrganization(OrganizationRowsCompanion.insert(
        id: org.id,
        name: org.name,
        type: org.type.name,
        branch: Value(org.branch),
        followerCount: const Value(1),
        activePolicyId: Value(policy.id),
        activeCalendarId: Value(calendar.id),
        createdBy: Value(uid),
        updatedAt: DateTime.now(),
      ));

      // 1b. Save Scopes
      for (var scope in scopes) {
        await _database.upsertScope(ScopeRowsCompanion.insert(
          id: scope.id,
          organizationId: scope.organizationId,
          parentId: Value(scope.parentId),
          type: scope.type,
          name: scope.name,
          activePolicyId: Value(scope.id == policy.scopeId ? policy.id : scope.activePolicyId),
          activeCalendarId: Value(scope.id == calendar.scopeId ? calendar.id : scope.activeCalendarId),
        ));
      }

      // 2. Save Policy
      await _database.savePolicy(OrganizationPolicyRowsCompanion.insert(
        policyId: policy.id,
        organizationId: org.id,
        scopeId: policy.scopeId ?? 'global',
        version: policy.version,
        effectiveFrom: policy.effectiveFrom,
        state: policy.state.name,
        evaluationPeriod: policy.evaluationPeriod.name,
        minimumPercent: Value(policy.minimumPercent),
        calculationBasis: policy.basis.name,
        fullUnit: policy.fullUnit,
        halfUnit: policy.halfUnit,
        weeklyOffs: Value(jsonEncode(policy.weeklyOffs)),
        startDate: Value(policy.startDate),
        endDate: Value(policy.endDate),
        updatedAt: DateTime.now(),
      ));

      // 3. Save Calendar
      await _database.saveCalendar(CalendarRowsCompanion.insert(
        id: calendar.id,
        organizationId: org.id,
        scopeId: calendar.scopeId ?? 'global',
        version: calendar.version,
        effectiveFrom: calendar.effectiveFrom,
        weeklyOffs: jsonEncode(calendar.weeklyOffs),
        offSaturdays: jsonEncode(calendar.offSaturdays),
        holidays: Value(jsonEncode(calendar.holidays.map((h) => h.toJson()).toList())),
        isConfigured: Value(calendar.isConfigured),
        updatedAt: DateTime.now(),
      ));

      // 4. Save Membership
      await _database.upsertMembership(MembershipRowsCompanion.insert(
        uid: membership.uid,
        organizationId: org.id,
        status: membership.status,
        idNumber: Value(membership.idNumber),
        joinedAt: membership.joinedAt,
      ));

      // 5. Save Follow
      await _database.upsertFollow(FollowRowsCompanion.insert(
        id: follow.id,
        organizationId: follow.organizationId,
        scopeId: follow.scopeId,
        status: follow.status,
        followedAt: follow.followedAt,
        personalTargetPercent: Value(follow.personalTargetPercent),
        personalBasis: Value(follow.personalBasis?.name),
        personalEvaluationPeriod: Value(follow.personalEvaluationPeriod?.name),
        personalFullUnit: Value(follow.personalFullUnit),
        personalHalfUnit: Value(follow.personalHalfUnit),
        personalStartDate: Value(follow.personalStartDate),
        personalEndDate: Value(follow.personalEndDate),
        personalWeeklyOffs: Value(follow.personalWeeklyOffs),
        personalOffSaturdays: Value(follow.personalOffSaturdays),
        personalHolidays: Value(follow.personalHolidays),
        isPersonalCalendarConfigured: Value(follow.isPersonalCalendarConfigured),
      ));

      // 6. Enqueue Sync Operations
      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'org:${org.id}',
        operation: 'putOrganization',
        entityId: org.id,
        payload: jsonEncode({
          'id': org.id,
          'name': org.name,
          'type': org.type.name,
          'branch': org.branch,
          'followerCount': 1,
          'activePolicyId': policy.id,
          'activeCalendarId': calendar.id,
          'uid': uid,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      for (var scope in scopes) {
        await _database.enqueue(SyncQueueRowsCompanion.insert(
          id: 'scope:${scope.id}',
          operation: 'putScope',
          entityId: scope.id,
          payload: jsonEncode({
            'id': scope.id,
            'organizationId': scope.organizationId,
            'parentId': scope.parentId,
            'type': scope.type,
            'name': scope.name,
            'activePolicyId': scope.id == policy.scopeId ? policy.id : scope.activePolicyId,
            'activeCalendarId': scope.id == calendar.scopeId ? calendar.id : scope.activeCalendarId,
          }),
          nextAttemptAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'policy:${policy.id}',
        operation: 'putPolicy',
        entityId: policy.id,
        payload: jsonEncode({
          'organizationId': org.id,
          'policy': {
            'id': policy.id,
            'version': policy.version,
            'effectiveFrom': policy.effectiveFrom.toIso8601String(),
            'state': policy.state.name,
            'evaluationPeriod': policy.evaluationPeriod.name,
            'minimumPercent': policy.minimumPercent,
            'basis': policy.basis.name,
            'fullUnit': policy.fullUnit,
            'halfUnit': policy.halfUnit,
            'weeklyOffs': policy.weeklyOffs,
            'startDate': policy.startDate?.toIso8601String(),
            'endDate': policy.endDate?.toIso8601String(),
          }
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'calendar:${calendar.id}',
        operation: 'putCalendar',
        entityId: calendar.id,
        payload: jsonEncode({
          'organizationId': org.id,
          'calendar': {
            'id': calendar.id,
            'version': calendar.version,
            'effectiveFrom': calendar.effectiveFrom.toIso8601String(),
            'weeklyOffs': calendar.weeklyOffs,
            'offSaturdays': calendar.offSaturdays,
            'holidays': calendar.holidays.map((h) => h.toJson()).toList(),
            'isConfigured': calendar.isConfigured,
          }
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'membership:$uid:${org.id}',
        operation: 'putMembership',
        entityId: '$uid:${org.id}',
        payload: jsonEncode({
          'uid': uid,
          'organizationId': org.id,
          'status': membership.status,
          'idNumber': membership.idNumber,
          'joinedAt': membership.joinedAt.toIso8601String(),
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'follow:${follow.id}',
        operation: 'putFollow',
        entityId: follow.id,
        payload: jsonEncode({
          'uid': uid,
          'id': follow.id,
          'organizationId': follow.organizationId,
          'scopeId': follow.scopeId,
          'personalTargetPercent': follow.personalTargetPercent,
          'status': follow.status,
          'followedAt': follow.followedAt.toIso8601String(),
          'personalBasis': follow.personalBasis?.name,
          'personalEvaluationPeriod': follow.personalEvaluationPeriod?.name,
          'personalFullUnit': follow.personalFullUnit,
          'personalHalfUnit': follow.personalHalfUnit,
          'personalStartDate': follow.personalStartDate?.toIso8601String(),
          'personalEndDate': follow.personalEndDate?.toIso8601String(),
          'personalWeeklyOffs': follow.personalWeeklyOffs,
          'personalOffSaturdays': follow.personalOffSaturdays,
          'personalHolidays': follow.personalHolidays,
          'isPersonalCalendarConfigured': follow.isPersonalCalendarConfigured,
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  /// Deterministic Policy Resolution:
  /// Personal User Settings -> Specific Scope -> Parent Scope -> Org
  Future<AttendancePolicy?> getResolvedPolicy({
    required String uid,
    required String organizationId,
    required String scopeId,
    String? followId,
  }) async {
    // 1. Resolve Official Hierarchy
    var policy = await _getPolicyHierarchy(organizationId, scopeId);

    // 2. Apply Personal Overrides
    if (followId != null) {
      final follow = await _database.getFollow(followId);
      if (follow != null && (follow.personalBasis != null || follow.personalTargetPercent != null || follow.personalEvaluationPeriod != null)) {
        policy = (policy ?? AttendancePolicy(
          id: 'personal-${follow.id}',
          version: 1,
          effectiveFrom: follow.followedAt,
          state: PolicyState.personal,
          evaluationPeriod: follow.personalEvaluationPeriod != null 
              ? EvaluationPeriod.values.byName(follow.personalEvaluationPeriod!) 
              : EvaluationPeriod.monthly,
          basis: follow.personalBasis != null 
              ? CalculationBasis.values.byName(follow.personalBasis!) 
              : CalculationBasis.hours,
          fullUnit: follow.personalFullUnit ?? 8.0,
          halfUnit: follow.personalHalfUnit ?? 4.0,
        )).copyWith(
          state: PolicyState.personal,
          minimumPercent: follow.personalTargetPercent ?? policy?.minimumPercent,
          basis: follow.personalBasis != null 
              ? CalculationBasis.values.byName(follow.personalBasis!) 
              : policy?.basis,
          evaluationPeriod: follow.personalEvaluationPeriod != null 
              ? EvaluationPeriod.values.byName(follow.personalEvaluationPeriod!) 
              : policy?.evaluationPeriod,
          fullUnit: follow.personalFullUnit ?? policy?.fullUnit,
          halfUnit: follow.personalHalfUnit ?? policy?.halfUnit,
          startDate: follow.personalStartDate ?? policy?.startDate,
          endDate: follow.personalEndDate ?? policy?.endDate,
        );
      }
    }

    return policy;
  }

  /// Helper to check if a conflict exists between personal settings and official policy
  Future<AttendancePolicy?> getOfficialPolicyForScope(String orgId, String scopeId, {String? activePolicyId}) async {
    return _getPolicyHierarchy(orgId, scopeId, activePolicyId: activePolicyId);
  }

  Future<AttendancePolicy?> _getPolicyHierarchy(String orgId, String scopeId, {String? activePolicyId}) async {
    // 1. Specific Scope (if provided and not 'global')
    if (scopeId != 'global' && scopeId != orgId) {
      var policy = await _getCachedOrRemotePolicy(orgId, scopeId);
      if (policy != null) return policy.copyWith(organizationId: orgId);

      // 2. Parent Scope (Recursive)
      var currentScope = await _database.getScope(scopeId);
      while (currentScope?.parentId != null) {
        policy = await _getCachedOrRemotePolicy(orgId, currentScope!.parentId!);
        if (policy != null) return policy.copyWith(organizationId: orgId);
        currentScope = await _database.getScope(currentScope.parentId!);
      }
    }

    // 3. Organization Global
    final global = await _getCachedOrRemotePolicy(orgId, 'global', explicitId: activePolicyId);
    return global?.copyWith(organizationId: orgId);
  }

  Future<AttendancePolicy?> _getCachedOrRemotePolicy(String orgId, String scopeId, {String? explicitId}) async {
    final cached = await _database.policyAt(orgId, scopeId, DateTime.now());
    if (cached != null) {
      return _toPolicy(cached);
    }
    
    // Remote fetch (only if local missing or scopeId mismatch)
    final policyId = explicitId ?? (scopeId == 'global' ? 'policy-global' : 'scope-$scopeId'); 
    final remote = await _remote.getPolicy(orgId, policyId);
    if (remote != null) {
      await cachePolicy(orgId, remote);
    }
    return remote;
  }

  Future<void> cachePolicy(String orgId, AttendancePolicy policy) async {
    await _database.savePolicy(OrganizationPolicyRowsCompanion.insert(
      policyId: policy.id,
      organizationId: orgId,
      scopeId: policy.scopeId ?? 'global',
      version: policy.version,
      effectiveFrom: policy.effectiveFrom,
      state: policy.state.name,
      evaluationPeriod: policy.evaluationPeriod.name,
      minimumPercent: Value(policy.minimumPercent),
      calculationBasis: policy.basis.name,
      fullUnit: policy.fullUnit,
      halfUnit: policy.halfUnit,
      weeklyOffs: Value(jsonEncode(policy.weeklyOffs)),
      startDate: Value(policy.startDate),
      endDate: Value(policy.endDate),
      updatedAt: DateTime.now(),
    ));
  }

  AttendancePolicy _toPolicy(OrganizationPolicyRow row) => AttendancePolicy(
    id: row.policyId,
    version: row.version,
    effectiveFrom: row.effectiveFrom,
    state: PolicyState.values.byName(row.state),
    evaluationPeriod: EvaluationPeriod.values.byName(row.evaluationPeriod),
    minimumPercent: row.minimumPercent,
    basis: CalculationBasis.values.byName(row.calculationBasis),
    fullUnit: row.fullUnit,
    halfUnit: row.halfUnit,
    startDate: row.startDate,
    endDate: row.endDate,
    scopeId: row.scopeId,
    organizationId: row.organizationId,
    weeklyOffs: (jsonDecode(row.weeklyOffs) as List).cast<int>(),
  );

  /// Deterministic Calendar Resolution:
  /// Personal User Settings -> Specific Scope -> Parent Scope -> Org
  Future<AttendanceCalendar> getResolvedCalendar({
    required String uid,
    required String organizationId,
    required String scopeId,
    String? followId,
  }) async {
    // 1. Check Personal Configuration (stored in Follow)
    if (followId != null) {
      final follow = await _database.getFollow(followId);
      if (follow != null && follow.isPersonalCalendarConfigured) {
        final personalWeeklyOffs = follow.personalWeeklyOffs != null 
            ? (jsonDecode(follow.personalWeeklyOffs!) as List).cast<int>() 
            : <int>[];
        final personalOffSaturdays = follow.personalOffSaturdays != null 
            ? (jsonDecode(follow.personalOffSaturdays!) as List).cast<int>() 
            : <int>[];
        final personalHolidays = follow.personalHolidays != null 
            ? (jsonDecode(follow.personalHolidays!) as List).map((h) => Holiday.fromJson(h as Map<String, dynamic>)).toList() 
            : <Holiday>[];
            
        return AttendanceCalendar(
          id: 'personal-cal-${follow.id}',
          version: 1,
          effectiveFrom: follow.followedAt,
          weeklyOffs: personalWeeklyOffs,
          offSaturdays: personalOffSaturdays,
          holidays: personalHolidays,
          isConfigured: true,
          organizationId: follow.organizationId,
          scopeId: follow.scopeId,
        );
      }
    }

    return _getCalendarHierarchy(organizationId, scopeId);
  }

  Future<AttendanceCalendar> getOfficialCalendarForScope(String orgId, String scopeId, {String? activeCalendarId}) async {
    return _getCalendarHierarchy(orgId, scopeId, activeCalendarId: activeCalendarId);
  }

  Future<AttendanceCalendar> _getCalendarHierarchy(String orgId, String scopeId, {String? activeCalendarId}) async {
    // 1. Specific Scope (if provided and not 'global')
    if (scopeId != 'global' && scopeId != orgId) {
      var calendar = await _getCachedOrRemoteCalendar(orgId, scopeId);
      if (calendar != null) return calendar.copyWith(organizationId: orgId);

      // 2. Parent Scope (Recursive)
      var currentScope = await _database.getScope(scopeId);
      while (currentScope?.parentId != null) {
        calendar = await _getCachedOrRemoteCalendar(orgId, currentScope!.parentId!);
        if (calendar != null) return calendar.copyWith(organizationId: orgId);
        currentScope = await _database.getScope(currentScope.parentId!);
      }
    }

    // 3. Organization Global
    final global = await _getCachedOrRemoteCalendar(orgId, 'global', explicitId: activeCalendarId);
    if (global != null) return global.copyWith(organizationId: orgId);

    return AttendanceCalendar.unconfigured;
  }

  Future<AttendanceCalendar?> _getCachedOrRemoteCalendar(String orgId, String scopeId, {String? explicitId}) async {
    final cached = await _database.calendarAt(orgId, scopeId, DateTime.now());
    if (cached != null) {
      return _toCalendar(cached);
    }

    // Remote fetch
    final calendarId = explicitId ?? (scopeId == 'global' ? 'cal-global' : 'cal-$scopeId');
    final remote = await _remote.getCalendar(orgId, calendarId);
    if (remote != null) {
      await saveCalendar(orgId, remote);
    }
    return remote;
  }

  /// Recover full hierarchy and rules for a given follow ID (New Device path)
  Future<void> syncFollowContext(String uid, String followId, {required FirestoreUserRemote userRemote}) async {
    final follow = await userRemote.getFollow(uid, followId);
    if (follow == null) return;

    // 1. Save Follow locally
    await _database.upsertFollow(FollowRowsCompanion.insert(
      id: follow.id,
      organizationId: follow.organizationId,
      scopeId: follow.scopeId,
      status: follow.status,
      followedAt: follow.followedAt,
      personalTargetPercent: Value(follow.personalTargetPercent),
      personalBasis: Value(follow.personalBasis?.name),
      personalEvaluationPeriod: Value(follow.personalEvaluationPeriod?.name),
      personalFullUnit: Value(follow.personalFullUnit),
      personalHalfUnit: Value(follow.personalHalfUnit),
      personalStartDate: Value(follow.personalStartDate),
      personalEndDate: Value(follow.personalEndDate),
      personalWeeklyOffs: Value(follow.personalWeeklyOffs),
      personalOffSaturdays: Value(follow.personalOffSaturdays),
      personalHolidays: Value(follow.personalHolidays),
      isPersonalCalendarConfigured: Value(follow.isPersonalCalendarConfigured),
    ));

    // 2. Fetch Organization
    final org = await _remote.getOrganization(follow.organizationId);
    if (org != null) {
      await _database.upsertOrganization(OrganizationRowsCompanion.insert(
        id: org.id,
        name: org.name,
        type: org.type.name,
        branch: Value(org.branch),
        followerCount: Value(org.followerCount),
        activePolicyId: Value(org.activePolicyId),
        activeCalendarId: Value(org.activeCalendarId),
        createdBy: Value(org.createdBy),
        updatedAt: DateTime.now(),
      ));
    }

    // 3. Fetch Scope Hierarchy recursively
    String? currentScopeId = follow.scopeId;
    while (currentScopeId != null && currentScopeId != 'global' && currentScopeId != follow.organizationId) {
      final scope = await _remote.getScope(follow.organizationId, currentScopeId);
      if (scope == null) break;

      await _database.upsertScope(ScopeRowsCompanion.insert(
        id: scope.id,
        organizationId: scope.organizationId,
        parentId: Value(scope.parentId),
        type: scope.type,
        name: scope.name,
        activePolicyId: Value(scope.activePolicyId),
        activeCalendarId: Value(scope.activeCalendarId),
      ));

      // Resolve Policy and Calendar for this specific scope
      if (scope.activePolicyId != null) {
        final policy = await _remote.getPolicy(follow.organizationId, scope.activePolicyId!);
        if (policy != null) await cachePolicy(follow.organizationId, policy);
      }
      if (scope.activeCalendarId != null) {
        final calendar = await _remote.getCalendar(follow.organizationId, scope.activeCalendarId!);
        if (calendar != null) await saveCalendar(follow.organizationId, calendar);
      }

      currentScopeId = scope.parentId;
    }

    // 4. Resolve Organization Global rules as fallback
    final orgRules = await _remote.getPolicy(follow.organizationId, 'policy-global');
    if (orgRules != null) await cachePolicy(follow.organizationId, orgRules);
    
    final orgCal = await _remote.getCalendar(follow.organizationId, 'cal-global');
    if (orgCal != null) await saveCalendar(follow.organizationId, orgCal);
  }

  AttendanceCalendar _toCalendar(CalendarRow row) {
    final weeklyOffs = (jsonDecode(row.weeklyOffs) as List).cast<int>();
    final offSaturdays = (jsonDecode(row.offSaturdays) as List).cast<int>();
    final holidays = row.holidays != null 
        ? (jsonDecode(row.holidays!) as List).map((h) => Holiday.fromJson(h as Map<String, dynamic>)).toList() 
        : <Holiday>[];

    return AttendanceCalendar(
      id: row.id,
      version: row.version,
      effectiveFrom: row.effectiveFrom,
      weeklyOffs: weeklyOffs,
      offSaturdays: offSaturdays,
      holidays: holidays,
      isConfigured: row.isConfigured,
      organizationId: row.organizationId,
      scopeId: row.scopeId,
    );
  }

  Future<void> saveMembership(Membership membership) async {
    await _database.transaction(() async {
      await _database.upsertMembership(MembershipRowsCompanion.insert(
        uid: membership.uid,
        organizationId: membership.organizationId,
        status: membership.status,
        idNumber: Value(membership.idNumber),
        joinedAt: membership.joinedAt,
        verifiedAt: Value(membership.verifiedAt),
      ));

      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'membership:${membership.uid}:${membership.organizationId}',
        operation: 'putMembership',
        entityId: '${membership.uid}:${membership.organizationId}',
        payload: jsonEncode({
          'uid': membership.uid,
          'organizationId': membership.organizationId,
          'status': membership.status,
          'idNumber': membership.idNumber,
          'joinedAt': membership.joinedAt.toIso8601String(),
          'verifiedAt': membership.verifiedAt?.toIso8601String(),
        }),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> saveCalendar(String orgId, AttendanceCalendar calendar) async {
    final weeklyOffsJson = jsonEncode(calendar.weeklyOffs);
    final offSaturdaysJson = jsonEncode(calendar.offSaturdays);
    final holidaysJson = jsonEncode(calendar.holidays.map((h) => h.toJson()).toList());

    await _database.saveCalendar(CalendarRowsCompanion.insert(
      id: calendar.id,
      organizationId: orgId,
      scopeId: calendar.scopeId ?? 'global',
      version: calendar.version,
      effectiveFrom: calendar.effectiveFrom,
      weeklyOffs: weeklyOffsJson,
      offSaturdays: offSaturdaysJson,
      holidays: Value(holidaysJson),
      isConfigured: Value(calendar.isConfigured),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> removeMembership(String orgId, String uid) async {
    await _remote.deleteMembership(orgId, uid);
    // Also remove locally
    await (_database.delete(_database.membershipRows)..where((row) => row.uid.equals(uid) & row.organizationId.equals(orgId))).go();
  }
}
