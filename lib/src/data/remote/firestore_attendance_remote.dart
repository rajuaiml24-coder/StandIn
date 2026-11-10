import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/attendance.dart';
import '../../domain/planning.dart';

/// The only Firestore boundary used by attendance repositories and sync.
class FirestoreAttendanceRemote {
  FirestoreAttendanceRemote(this._firestore);
  final FirebaseFirestore _firestore;

  Future<AttendanceRecord?> getAttendance(String uid, String id) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists
        ? AttendanceRecord.fromJson(doc.data()!, pendingSync: false)
        : null;
  }

  Future<void> putPlan(String uid, AttendancePlan plan) => _firestore
      .collection('users')
      .doc(uid)
      .collection('plans')
      .doc(plan.id)
      .set({...plan.toJson(), 'updatedAt': FieldValue.serverTimestamp()});

  Future<List<AttendancePlan>> getPlansDelta(String uid, DateTime since) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('plans')
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    return snapshot.docs
        .map((doc) => AttendancePlan.fromJson({...doc.data(), 'id': doc.id},
            updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate(),
            pendingSync: false))
        .toList();
  }

  /// Rebuild only the unsynchronized suffix. Each correction must append the
  /// record currently on the server, including after a partially completed retry.
  static List<AttendanceRecord> uploadSequence(AttendanceRecord record) {
    final anchor = record.history.lastIndexWhere((entry) =>
        AttendanceRecord.fromJson(entry).fingerprint == record.baseRevision);
    var base = record.baseRevision;
    final result = <AttendanceRecord>[];
    for (var i = anchor + 1; i < record.history.length; i++) {
      final entry = record.history[i];
      if (entry['revisionId'] == null) continue;
      final step = AttendanceRecord.fromJson({
        ...entry,
        'baseRevision': base,
        'history': record.history.take(i).toList()
      });
      result.add(step);
      base = step.fingerprint;
    }
    result.add(AttendanceRecord.fromJson(
        {...record.toJson(), 'baseRevision': base, 'history': record.history}));
    return result;
  }

  Future<void> putAttendance(
      String uid, String id, AttendanceRecord record) async {
    final sequence = uploadSequence(record);
    for (var index = 0; index < sequence.length; index++) {
      final step = sequence[index];
      await _firestore.runTransaction((tx) async {
        final ref = _firestore
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .doc(id);
        final doc = await tx.get(ref);
        final previous =
            doc.exists ? AttendanceRecord.fromJson(doc.data()!) : null;
        if (step.revisionId != null &&
            previous?.revisionId == step.revisionId) {
          return;
        }
        // A retry or concurrent upload may already have advanced this chain.
        if (previous?.revisionId != null &&
            sequence
                .skip(index + 1)
                .any((later) => later.revisionId == previous!.revisionId)) {
          return;
        }
        final sameLegacyMigration = step.snapshot?.legacy == true &&
            previous?.snapshot == null &&
            previous?.legacyFingerprint == step.legacyFingerprint &&
            step.baseRevision == null;
        if (previous?.fingerprint != step.baseRevision &&
            !sameLegacyMigration) {
          throw StateError(
              'Attendance changed on another device. Your correction is kept on this device; review the sync conflict.');
        }
        if (previous?.snapshot != null && step.snapshot == null) {
          throw StateError(
              'Update StandIn before editing protected attendance');
        }
        tx.set(
            ref, {...step.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
      });
    }
  }

  Future<List<AttendanceRecord>> getAttendanceDelta(
      String uid, DateTime since) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AttendanceRecord.fromJson(
        data,
        pendingSync: false,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Future<void> deleteAllAttendance(String uid) async {
    for (final collection in ['attendance', 'plans']) {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .get();
      for (var offset = 0; offset < snapshot.docs.length; offset += 450) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs.skip(offset).take(450)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
  }
}
