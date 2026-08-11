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

String attendanceId(DateTime date, String orgId, String scopeId) {
  final dateStr = date.toIso8601String().substring(0, 10);
  return '${dateStr}_${orgId}_$scopeId';
}
