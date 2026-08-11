import '../domain/attendance.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchRecords();
  Future<void> save(AttendanceRecord record);
}

/// Composition boundary for the production repository:
/// local Drift write -> durable sync queue -> idempotent Firestore upload.
abstract class SyncQueueRepository implements AttendanceRepository {
  Future<void> syncPending();
}
