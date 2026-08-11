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
    return AttendancePolicy(id: row.policyId, version: row.version, effectiveFrom: row.effectiveFrom, minimumPercent: row.minimumPercent, basis: CalculationBasis.values.byName(row.calculationBasis), fullUnit: row.fullUnit, halfUnit: row.halfUnit);
  }

  Future<void> cachePolicy(String organizationId, AttendancePolicy policy) => _database.savePolicy(OrganizationPolicyRowsCompanion.insert(policyId: policy.id, organizationId: organizationId, version: policy.version, effectiveFrom: policy.effectiveFrom, minimumPercent: policy.minimumPercent, calculationBasis: policy.basis.name, fullUnit: policy.fullUnit, halfUnit: policy.halfUnit, updatedAt: DateTime.now()));

  /// Admin-only server workflows call this after approval; clients never overwrite a live policy.
  Future<void> publishApprovedVersion(String organizationId, AttendancePolicy policy) async {
    await _remote.putPolicy(organizationId, policy);
    await cachePolicy(organizationId, policy);
  }
}
