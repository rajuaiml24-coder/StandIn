import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../local/standin_database.dart';
import '../remote/firestore_attendance_remote.dart';
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
    for (final operation in await _database.dueSyncOperations(DateTime.now())) {
      try {
        if (operation.operation == 'upsertAttendance') {
          final json = jsonDecode(operation.payload) as Map<String, dynamic>;
          final record = AttendanceRecord(date: DateTime.parse(json['date'] as String), status: AttendanceStatus.values.byName(json['status'] as String), actualUnits: (json['actualUnits'] as num).toDouble(), expectedUnits: (json['expectedUnits'] as num).toDouble());
          await _remote.putAttendance(uid, operation.entityId, json['organizationId'] as String, record);
        }
        await _database.deleteOperation(operation.id);
      } catch (error) {
        final attempts = operation.attemptCount + 1;
        final delay = Duration(minutes: 1 << attempts.clamp(0, 6).toInt());
        await _database.rescheduleOperation(operation.id, attempts, DateTime.now().add(delay), error.toString());
      }
    }
  }
}
