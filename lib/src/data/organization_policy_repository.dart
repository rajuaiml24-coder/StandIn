import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import 'local/standin_database.dart';
import 'remote/firestore_attendance_remote.dart';

/// Reads cached policies first. Cloud refresh is explicit and never rewrites history.
class OrganizationPolicyRepository {
  OrganizationPolicyRepository(this._database, this._remote);
  final StandInDatabase _database;
  final FirestoreAttendanceRemote _remote;

  Future<AttendancePolicy?> policyForDate(String organizationId, DateTime date) async {
    final row = await _database.policyAt(organizationId, date);
    if (row == null) return null;
    return AttendancePolicy(
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
      endDate: row.endDate
    );
  }

  Future<void> cachePolicy(String organizationId, AttendancePolicy policy) => _database.savePolicy(
    OrganizationPolicyRowsCompanion.insert(
      policyId: policy.id, 
      organizationId: organizationId, 
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
      updatedAt: DateTime.now()
    )
  );

  /// Admin-only server workflows call this after approval; clients never overwrite a live policy.
  Future<void> publishApprovedVersion(String organizationId, AttendancePolicy policy) async {
    await _remote.putPolicy(organizationId, policy);
    await cachePolicy(organizationId, policy);
  }
}
