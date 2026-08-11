import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/attendance.dart';

/// The only Firestore boundary used by attendance repositories and sync.
class FirestoreAttendanceRemote {
  FirestoreAttendanceRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> putAttendance(String uid, String id, String organizationId, AttendanceRecord record) =>
      _firestore.collection('users').doc(uid).collection('attendance').doc(id).set({
        'organizationId': organizationId,
        'date': Timestamp.fromDate(record.date),
        'status': record.status.name,
        'actualUnits': record.actualUnits,
        'expectedUnits': record.expectedUnits,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> putPolicy(String organizationId, AttendancePolicy policy) =>
      _firestore.collection('organizations').doc(organizationId).collection('policyVersions').doc(policy.id).set({
        'version': policy.version,
        'effectiveFrom': Timestamp.fromDate(policy.effectiveFrom),
        'minimumPercent': policy.minimumPercent,
        'basis': policy.basis.name,
        'fullUnit': policy.fullUnit,
        'halfUnit': policy.halfUnit,
      }, SetOptions(merge: true));
}
