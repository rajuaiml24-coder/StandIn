import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../local/standin_database.dart';
import '../remote/firestore_attendance_remote.dart';
import '../attendance_repository.dart';
import '../../domain/attendance.dart';

class SyncEngine {
  SyncEngine(this._database, this._remote, {required this.uid, Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();
  final StandInDatabase _database;
  final FirestoreAttendanceRemote _remote;
  final String uid;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void start() { _subscription = _connectivity.onConnectivityChanged.listen((results) { if (!results.contains(ConnectivityResult.none)) syncNow(); }); }
  Future<void> stop() async => _subscription?.cancel();

  Future<void> syncNow() async {
    final connection = await _connectivity.checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) return;
    
    await _pushLocalChanges();
    await _pullRemoteChanges();
  }

  Future<void> _pushLocalChanges() async {
    for (final operation in await _database.dueSyncOperations(DateTime.now())) {
      try {
        if (operation.operation == 'upsertAttendance') {
          final json = jsonDecode(operation.payload) as Map<String, dynamic>;
          final record = AttendanceRecord(
            date: DateTime.parse(json['date'] as String), 
            status: AttendanceStatus.values.byName(json['status'] as String), 
            actualUnits: (json['actualUnits'] as num).toDouble(), 
            expectedUnits: (json['expectedUnits'] as num).toDouble(),
            organizationId: json['organizationId'] as String?,
            scopeId: json['scopeId'] as String?,
            policyVersionId: json['policyVersionId'] as String?,
            calendarVersionId: json['calendarVersionId'] as String?,
            source: json['source'] as String? ?? 'manual',
          );
          await _remote.putAttendance(uid, operation.entityId, record);
        }
        await _database.deleteOperation(operation.id);
      } catch (error) {
        final attempts = operation.attemptCount + 1;
        final delay = Duration(minutes: 1 << attempts.clamp(0, 6).toInt());
        await _database.rescheduleOperation(operation.id, attempts, DateTime.now().add(delay), error.toString());
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    final lastSync = await _database.getLastSyncAt('attendance:$uid') ?? DateTime(2000);
    final delta = await _remote.getAttendanceDelta(uid, lastSync);
    
    if (delta.isNotEmpty) {
      await _database.transaction(() async {
        for (final record in delta) {
          final id = attendanceId(record.date, record.organizationId ?? 'unknown', record.scopeId ?? 'global');
          await _database.upsertAttendance(AttendanceTableCompanion(
            id: Value(id),
            orgId: Value(record.organizationId ?? 'unknown'),
            contextId: Value(record.scopeId ?? 'global'),
            attendanceDate: Value(record.date),
            status: Value(record.status.name),
            actualUnits: Value(record.actualUnits),
            expectedUnits: Value(record.expectedUnits),
            policyVersionId: Value(record.policyVersionId),
            calendarVersionId: Value(record.calendarVersionId),
            pendingSync: const Value(false),
            updatedAt: Value(DateTime.now()),
          ));
        }
      });
      await _database.setLastSyncAt('attendance:$uid', DateTime.now());
    }
  }
}
