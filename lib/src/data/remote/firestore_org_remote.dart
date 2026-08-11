import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/attendance.dart';

class FirestoreOrgRemote {
  FirestoreOrgRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> putOrganization(Organization org) =>
      _firestore.collection('organizations').doc(org.id).set({
        'name': org.name,
        'type': org.type.name,
        'isVerified': org.isVerified,
        'isHolidayCalendarConfigured': org.isHolidayCalendarConfigured,
        'activePolicyId': org.activePolicyId,
        'activeCalendarId': org.activeCalendarId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> putMembership(Membership membership) =>
      _firestore.collection('organizations').doc(membership.organizationId).collection('members').doc(membership.uid).set({
        'status': membership.status,
        'idNumber': membership.idNumber,
        'joinedAt': Timestamp.fromDate(membership.joinedAt),
        'verifiedAt': membership.verifiedAt != null ? Timestamp.fromDate(membership.verifiedAt!) : null,
      });

  Future<AttendancePolicy?> getPolicy(String orgId, String policyId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).collection('policies').doc(policyId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AttendancePolicy(
      id: doc.id,
      version: data['version'] as int,
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      state: PolicyState.values.byName(data['state'] as String),
      evaluationPeriod: EvaluationPeriod.values.byName(data['evaluationPeriod'] as String),
      minimumPercent: (data['minimumPercent'] as num?)?.toDouble(),
      basis: CalculationBasis.values.byName(data['basis'] as String),
      fullUnit: (data['fullUnit'] as num).toDouble(),
      halfUnit: (data['halfUnit'] as num).toDouble(),
      weeklyOffs: (data['weeklyOffs'] as List).cast<int>(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }
}
