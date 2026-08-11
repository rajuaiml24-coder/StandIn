import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'remote/firestore_org_remote.dart';

class OrganizationRepository {
  OrganizationRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreOrgRemote _remote;

  Future<AttendancePolicy?> getResolvedPolicy(String orgId, String policyId) async {
    final row = await _database.policyAt(orgId, DateTime.now());
    if (row != null && row.policyId == policyId) {
      return _toPolicy(row);
    }
    
    // Remote fetch if missing or outdated
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
