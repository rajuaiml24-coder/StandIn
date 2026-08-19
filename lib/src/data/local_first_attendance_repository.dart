import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attendance.dart';
import 'attendance_repository.dart';
import 'local/standin_database.dart';

class LocalFirstAttendanceRepository implements SyncQueueRepository {
  LocalFirstAttendanceRepository(this._database, {required this.uid, required this.organizationId, required this.scopeId});
        
  final StandInDatabase _database;
  final String uid;
  final String organizationId;
  final String scopeId;

  @override
  Stream<List<AttendanceRecord>> watchRecords() => _database.watchAttendance(organizationId).map((rows) => rows.map(_toDomain).toList(growable: false));

  @override
  Future<void> save(AttendanceRecord record) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (record.date.isAfter(todayDate)) {
      throw ArgumentError('Cannot mark attendance for future dates');
    }

    final recordId = attendanceId(record.date, organizationId, scopeId);
    final enriched = record.copyWith(organizationId: organizationId, scopeId: scopeId);
    await _database.transaction(() async {
      await _database.upsertAttendance(AttendanceTableCompanion.insert(
        id: recordId,
        organizationId: organizationId,
        scopeId: scopeId,
        attendanceDate: record.date,
        status: record.status.name,
        actualUnits: record.actualUnits,
        expectedUnits: record.expectedUnits,
        updatedAt: DateTime.now(),
        policyVersionId: Value(record.policyVersionId),
        calendarVersionId: Value(record.calendarVersionId),
      ));
      await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'attendance:$recordId', 
        operation: 'upsertAttendance', 
        entityId: recordId, 
        payload: jsonEncode(_payload(enriched)), 
        nextAttemptAt: DateTime.now(), 
        createdAt: DateTime.now()
      ));
    });
  }

  @override
  Future<void> syncPending() async {}

  Map<String, Object?> _payload(AttendanceRecord record) => {
    'organizationId': record.organizationId, 
    'scopeId': record.scopeId,
    'date': record.date.toIso8601String(), 
    'status': record.status.name, 
    'actualUnits': record.actualUnits, 
    'expectedUnits': record.expectedUnits,
    'policyVersionId': record.policyVersionId,
    'calendarVersionId': record.calendarVersionId,
    'source': record.source,
  };
  
  AttendanceRecord _toDomain(AttendanceTableData row) => AttendanceRecord(
    date: row.attendanceDate, 
    status: AttendanceStatus.values.byName(row.status), 
    actualUnits: row.actualUnits, 
    expectedUnits: row.expectedUnits, 
    organizationId: row.organizationId,
    scopeId: row.scopeId,
    policyVersionId: row.policyVersionId,
    calendarVersionId: row.calendarVersionId,
    pendingSync: row.pendingSync
  );
}
