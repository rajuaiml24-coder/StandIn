import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attendance.dart';
import 'attendance_repository.dart';
import 'local/standin_database.dart';

class LocalFirstAttendanceRepository implements SyncQueueRepository {
  LocalFirstAttendanceRepository(this._database, {required this.uid, required this.organizationId});
  final StandInDatabase _database;
  final String uid;
  final String organizationId;

  @override
  Stream<List<AttendanceRecord>> watchRecords() => _database.watchAttendance(organizationId).map((rows) => rows.map(_toDomain).toList(growable: false));

  @override
  Future<void> save(AttendanceRecord record) async {
    final id = attendanceId(uid, organizationId, record.date);
    await _database.transaction(() async {
      await _database.upsertAttendance(AttendanceRowsCompanion.insert(id: id, organizationId: organizationId, attendanceDate: record.date, status: record.status.name, actualUnits: record.actualUnits, expectedUnits: record.expectedUnits, pendingSync: const Value(true), syncError: const Value(null), updatedAt: DateTime.now()));
      await _database.enqueue(SyncQueueRowsCompanion.insert(id: 'attendance:$id', operation: 'upsertAttendance', entityId: id, payload: jsonEncode(_payload(record)), nextAttemptAt: DateTime.now(), createdAt: DateTime.now()));
    });
  }

  @override
  Future<void> syncPending() async {}

  Map<String, Object> _payload(AttendanceRecord record) => {'organizationId': organizationId, 'date': record.date.toIso8601String(), 'status': record.status.name, 'actualUnits': record.actualUnits, 'expectedUnits': record.expectedUnits};
  AttendanceRecord _toDomain(AttendanceRow row) => AttendanceRecord(date: row.attendanceDate, status: AttendanceStatus.values.byName(row.status), actualUnits: row.actualUnits, expectedUnits: row.expectedUnits, pendingSync: row.pendingSync);
}

String attendanceId(String uid, String organizationId, DateTime date) => '$uid-$organizationId-${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
