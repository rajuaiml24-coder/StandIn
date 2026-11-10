import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import '../domain/policy_engine.dart';
import 'attendance_repository.dart';
import 'local/standin_database.dart';
import 'planning_repository.dart';
import 'remote/firestore_attendance_remote.dart';
import 'organization_repository.dart';

class LocalFirstAttendanceRepository implements SyncQueueRepository {
  LocalFirstAttendanceRepository(this._database,
      {required this.uid, required this.organizationId, required this.scopeId});
  final StandInDatabase _database;
  StandInDatabase get database => _database;
  final String uid, organizationId, scopeId;

  @override
  Stream<List<AttendanceRecord>> watchRecords() => _database
      .watchAttendance(organizationId, scopeId: scopeId)
      .map((rows) => rows.map(toDomain).toList(growable: false));

  Future<void> protectHistory(
          AttendancePolicy policy, AttendanceCalendar calendar,
          {AttendancePolicy Function(DateTime)? policyFor,
          AttendanceCalendar Function(DateTime)? calendarFor}) =>
      _database.transaction(() async {
        final rows = await (_database.select(_database.attendanceTable)
              ..where((r) =>
                  r.organizationId.equals(organizationId) &
                  r.scopeId.equals(scopeId)))
            .get();
        for (final row in rows) {
          if (row.protectedData != null) continue;
          final original = toDomain(row);
          var originalPolicy = policyFor?.call(original.date) ?? policy;
          if (original.expectedUnits > 0 && original.expectedUnits != originalPolicy.fullUnit &&
              original.policyVersionId != null) {
            final saved = await _database.getPolicyById(original.policyVersionId!, organizationId: organizationId);
            if (saved != null) originalPolicy = OrganizationRepository.policyFromRow(saved);
          }
          final frozen = const PolicyEngine().freezeLegacy(
              original,
              originalPolicy,
              calendarFor?.call(original.date) ?? calendar);
          if (frozen.snapshot == null) continue;
          await _write(frozen, original, migration: true);
        }
      });

  @override
  Future<void> save(AttendanceRecord record) async {
    if (organizationId.isEmpty ||
        organizationId == 'unknown' ||
        scopeId.isEmpty) {
      throw StateError('Choose an organization before marking attendance');
    }
    final now = DateTime.now();
    if (record.date.isAfter(DateTime(now.year, now.month, now.day))) {
      throw ArgumentError('Cannot mark attendance for future dates');
    }
    await _database.transaction(() async {
      final id = attendanceId(record.date, organizationId, scopeId);
      final row = await _database.getAttendance(id);
      final previous = row == null ? null : toDomain(row);
      if (record.baseRevision != previous?.fingerprint) {
        throw StateError(
            'This entry changed. Reopen it before saving your correction.');
      }
      if (previous?.snapshot != null &&
          (record.snapshot == null ||
              record.snapshot!.policy.basis !=
                  previous!.snapshot!.policy.basis ||
              record.snapshot!.policy.fullUnit !=
                  previous.snapshot!.policy.fullUnit)) {
        throw StateError('A correction must use the original attendance units');
      }
      await _write(record, previous);
      await PlanningRepository(_database,
              organizationId: organizationId, scopeId: scopeId)
          .remove(record.date);
    });
  }

  Future<void> _write(AttendanceRecord record, AttendanceRecord? previous,
      {bool migration = false,
      List<Map<String, dynamic>> historyExtras = const []}) async {
    final id = attendanceId(record.date, organizationId, scopeId);
    final pending = await _database.getOperation('attendance:$id');
    final queued = pending == null
        ? null
        : jsonDecode(pending.payload) as Map<String, dynamic>;
    final token =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    final audit = previous?.toJson();
    audit?.remove('history');
    final payload = {
      ...record.toJson(),
      'organizationId': organizationId,
      'scopeId': scopeId,
      'policyVersionId':
          previous == null ? record.policyVersionId : previous.policyVersionId,
      'calendarVersionId': previous == null
          ? record.calendarVersionId
          : previous.calendarVersionId,
      'revisionId': token,
      'baseRevision':
          queued == null ? previous?.fingerprint : queued['baseRevision'],
      'history': [
        ...?previous?.history,
        ...historyExtras,
        if (audit != null && !migration)
          {
            ...audit,
            'correctedAt': DateTime.now().toUtc().toIso8601String(),
          },
      ]
    };
    final enriched = AttendanceRecord.fromJson(payload);
    await _database.upsertAttendance(toRow(enriched, id, pendingSync: true));
    await _database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'attendance:$id',
        operation: 'upsertAttendance',
        entityId: id,
        payload: jsonEncode(payload),
        nextAttemptAt: DateTime.now(),
        createdAt: pending?.createdAt ?? DateTime.now()));
  }

  Future<void> resolveConflict(AttendanceRecord presentedLocal,
      AttendanceRecord presentedRemote, FirestoreAttendanceRemote remote,
      {required bool useLocal}) async {
    final id = attendanceId(presentedLocal.date, organizationId, scopeId);
    final cloud = await remote.getAttendance(uid, id);
    if (cloud?.fingerprint != presentedRemote.fingerprint ||
        cloud?.organizationId != organizationId ||
        cloud?.scopeId != scopeId) {
      throw StateError('Attendance changed again. Reopen the comparison.');
    }
    final original = cloud!.snapshot;
    if (original == null) {
      throw StateError(
          'The original rules are unavailable. Keep both entries and retry after updating StandIn.');
    }
    if (useLocal &&
        (presentedLocal.snapshot?.policy.basis != original.policy.basis ||
            presentedLocal.snapshot?.policy.fullUnit !=
                original.policy.fullUnit)) {
      throw StateError(
          'The entries use different units. Choose the synchronized entry, then correct that date using its original units. Both edits stay in history.');
    }
    final chosen = useLocal
        ? const PolicyEngine().createRecord(
            date: cloud.date,
            status: presentedLocal.status,
            policy: original.policy,
            actualUnits: presentedLocal.actualUnits,
            leaveUnits: presentedLocal.leaveUnits,
            recordedDayType: original.dayType)
        : cloud;
    await _database.transaction(() async {
      final row = await _database.getAttendance(id);
      if (row == null ||
          toDomain(row).fingerprint != presentedLocal.fingerprint) {
        throw StateError('Your local entry changed. Reopen the comparison.');
      }
      final pending = await _database.getOperation('attendance:$id');
      if (pending == null) {
        throw StateError('This entry has already synchronized.');
      }
      final archived = presentedLocal.toJson()..remove('history');
      await _database.deleteOperation(pending.id);
      await _write(chosen, cloud, historyExtras: [
        ...presentedLocal.history.where((entry) => !cloud.history
            .any((other) => jsonEncode(other) == jsonEncode(entry))),
        {
          ...archived,
          'resolution': 'Preserved device edit',
          'correctedAt': DateTime.now().toUtc().toIso8601String()
        },
      ]);
    });
  }

  @override
  Future<void> syncPending() async {}

  static AttendanceTableCompanion toRow(AttendanceRecord record, String id,
          {required bool pendingSync}) =>
      AttendanceTableCompanion.insert(
          id: id,
          organizationId: record.organizationId!,
          scopeId: record.scopeId!,
          attendanceDate: record.date,
          status: record.status.name,
          actualUnits: record.actualUnits,
          expectedUnits: record.expectedUnits,
          policyVersionId: Value(record.policyVersionId),
          calendarVersionId: Value(record.calendarVersionId),
          protectedData: Value(
              record.snapshot == null && record.revisionId == null
                  ? null
                  : jsonEncode(record.toJson())),
          pendingSync: Value(pendingSync),
          updatedAt: record.updatedAt ?? DateTime.now());

  static AttendanceRecord toDomain(AttendanceTableData row) =>
      AttendanceRecord.fromJson({
        if (row.protectedData != null)
          ...jsonDecode(row.protectedData!) as Map<String, dynamic>,
        'date': row.attendanceDate.toIso8601String(),
        'status': row.status,
        'actualUnits': row.actualUnits,
        'expectedUnits': row.expectedUnits,
        'organizationId': row.organizationId,
        'scopeId': row.scopeId,
        'policyVersionId': row.policyVersionId,
        'calendarVersionId': row.calendarVersionId,
      }, pendingSync: row.pendingSync, updatedAt: row.updatedAt);
}
