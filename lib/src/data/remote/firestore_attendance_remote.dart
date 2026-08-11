import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/attendance.dart';

/// The only Firestore boundary used by attendance repositories and sync.
class FirestoreAttendanceRemote {
  FirestoreAttendanceRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> putAttendance(String uid, String id, AttendanceRecord record) =>
      _firestore.collection('users').doc(uid).collection('attendance').doc(id).set({
        'date': record.date.toIso8601String().substring(0, 10), 
        'organizationId': record.organizationId,
        'scopeId': record.scopeId,
        'status': record.status.name,
        'actualUnits': record.actualUnits,
        'expectedUnits': record.expectedUnits,
        'policyVersionId': record.policyVersionId,
        'calendarVersionId': record.calendarVersionId,
        'source': record.source,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<List<AttendanceRecord>> getAttendanceDelta(String uid, DateTime since) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AttendanceRecord(
        date: DateTime.parse(data['date'] as String),
        status: AttendanceStatus.values.byName(data['status'] as String),
        actualUnits: (data['actualUnits'] as num).toDouble(),
        expectedUnits: (data['expectedUnits'] as num).toDouble(),
        organizationId: data['organizationId'] as String?,
        scopeId: data['scopeId'] as String?,
        policyVersionId: data['policyVersionId'] as String?,
        calendarVersionId: data['calendarVersionId'] as String?,
        source: data['source'] as String? ?? 'manual',
        pendingSync: false,
      );
    }).toList();
  }
}
