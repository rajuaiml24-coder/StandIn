import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/standin_database.dart';
import '../../data/local_first_attendance_repository.dart';
import '../../data/remote/firestore_attendance_remote.dart';
import '../../domain/app_errors.dart';
import '../../domain/attendance.dart';

class AttendanceSyncStatus extends StatelessWidget {
  const AttendanceSyncStatus(
      {super.key,
      required this.database,
      required this.remote,
      required this.uid,
      this.activeFollowId});
  final StandInDatabase database;
  final FirestoreAttendanceRemote remote;
  final String uid;
  final String? activeFollowId;

  String describe(AttendanceRecord record) {
    final snapshot = record.snapshot;
    final units = snapshot?.policy.basis.label(record.actualUnits) ?? 'units';
    return '${record.status.name}: ${record.actualUnits} $units attendance, ${record.leaveUnits} leave\n'
        'Credit: ${snapshot?.credited ?? record.actualUnits} | Required: ${snapshot?.requiredUnits ?? record.expectedUnits}';
  }

  Future<void> review(BuildContext context, SyncQueueRow operation) async {
    try {
      final row = await database.getAttendance(operation.entityId);
      if (row == null) throw StateError('This entry is unavailable');
      final local = LocalFirstAttendanceRepository.toDomain(row);
      final cloud = await remote.getAttendance(uid, operation.entityId);
      if (cloud == null) {
        throw StateError(
            'The synchronized entry is unavailable. Your local entry is kept.');
      }
      if (!context.mounted) return;
      final useLocal = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                  title: Text(
                      'Attendance on ${DateFormat.yMMMd().format(local.date)}'),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('This device',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(describe(local)),
                        const SizedBox(height: 16),
                        const Text('Synchronized entry',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(describe(cloud)),
                        const SizedBox(height: 16),
                        const Text(
                            'Choose the correct entry. Both edits will stay in its history.')
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: const Text('Use synced entry')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialog, true),
                        child: const Text('Use this device'))
                  ]));
      if (useLocal == null) return;
      await LocalFirstAttendanceRepository(database,
              uid: uid,
              organizationId: row.organizationId,
              scopeId: row.scopeId)
          .resolveConflict(local, cloud, remote, useLocal: useLocal);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(actionError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SyncQueueRow>>(
      stream: database.select(database.syncQueueRows).watch(),
      builder: (_, data) => Column(children: [
            for (final operation in data.data ?? <SyncQueueRow>[])
              if (operation.lastError != null &&
                  operation.id != 'follow:$activeFollowId' &&
                  operation.id != 'calendarState:$activeFollowId')
                _failedOperation(context, operation),
          ]));

  Widget _failedOperation(BuildContext context, SyncQueueRow operation) {
    final attendance = operation.operation == 'upsertAttendance';
    final plan = operation.operation == 'putPlan';
    final calendar = operation.operation == 'putCalendarState';
    final conflict = operation.lastError!.contains('another device');
    final title = attendance
        ? (conflict ? 'Attendance needs review' : 'Attendance backup failed')
        : plan
            ? 'Plan backup failed'
            : calendar && conflict
                ? 'Calendar needs review'
                : 'Backup needs attention';
    final detail = calendar && conflict
        ? 'Open this saved calendar to review its changes.'
        : plan
            ? 'Your plan is kept on this device.'
            : attendance
                ? 'Your saved entry is kept on this device.'
                : 'Your changes are kept on this device.';
    return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.sync_problem),
        title: Text(title),
        subtitle: Text(detail),
        trailing: calendar && conflict
            ? null
            : TextButton(
                child: Text(attendance && conflict ? 'Review' : 'Retry'),
                onPressed: () async {
                  if (attendance && conflict) {
                    await review(context, operation);
                  } else {
                    await database.retryUnchangedOperation(operation);
                  }
                }));
  }
}
