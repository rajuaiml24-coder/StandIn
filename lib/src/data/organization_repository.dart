import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'remote/firestore_org_remote.dart';

class OrganizationRepository {
  OrganizationRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreOrgRemote _remote;

  /// Deterministic Policy Resolution:
  /// Personal Override -> Specific Scope -> Parent Scope -> Org
  Future<AttendancePolicy?> getResolvedPolicy({
    required String uid,
    required String organizationId,
    required String scopeId,
    String? followId,
  }) async {
    // 1. Check Personal Override (cached in Follow)
    if (followId != null) {
      final follow = await _database.getFollow(followId);
      if (follow?.personalTargetPercent != null) {
        final basePolicy = await _getPolicyHierarchy(organizationId, scopeId);
        if (basePolicy != null) {
          return AttendancePolicy(
            id: basePolicy.id,
            version: basePolicy.version,
            effectiveFrom: basePolicy.effectiveFrom,
            state: basePolicy.state,
            evaluationPeriod: basePolicy.evaluationPeriod,
            minimumPercent: follow!.personalTargetPercent, // Personal goal wins
            basis: basePolicy.basis,
            fullUnit: basePolicy.fullUnit,
            halfUnit: basePolicy.halfUnit,
            startDate: basePolicy.startDate,
            endDate: basePolicy.endDate,
            scopeId: basePolicy.scopeId,
          );
        }
      }
    }

    return _getPolicyHierarchy(organizationId, scopeId);
  }

  Future<AttendancePolicy?> _getPolicyHierarchy(String orgId, String scopeId) async {
    // 2. Specific Scope
    var policy = await _getCachedOrRemotePolicy(orgId, scopeId);
    if (policy != null) return policy;

    // 3. Parent Scope (Recursive)
    var currentScope = await _database.getScope(scopeId);
    while (currentScope?.parentId != null) {
      policy = await _getCachedOrRemotePolicy(orgId, currentScope!.parentId!);
      if (policy != null) return policy;
      currentScope = await _database.getScope(currentScope.parentId!);
    }

    // 4. Organization Global
    return _getCachedOrRemotePolicy(orgId, 'global');
  }

  Future<AttendancePolicy?> _getCachedOrRemotePolicy(String orgId, String scopeId) async {
    final cached = await _database.policyAt(orgId, scopeId, DateTime.now());
    if (cached != null) {
      return _toPolicy(cached);
    }
    
    // Remote fetch (only if local missing or scopeId mismatch)
    // For MVP, we useorgId as fallback if scopeId is 'global'
    final policyId = scopeId == 'global' ? 'org-default' : 'scope-$scopeId'; 
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
  );

  Future<void> saveMembership(Membership membership) async {
    await _database.upsertMembership(MembershipRowsCompanion.insert(
      uid: membership.uid,
      organizationId: membership.organizationId,
      status: membership.status,
      idNumber: Value(membership.idNumber),
      joinedAt: membership.joinedAt,
      verifiedAt: Value(membership.verifiedAt),
    ));
    await _remote.putMembership(membership);
  }
}
