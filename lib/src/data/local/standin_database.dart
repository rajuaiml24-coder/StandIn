import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'connection/connection.dart'
    if (dart.library.js_interop) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart' as impl;

part 'standin_database.g.dart';

String scopedCacheId(String organizationId, String id) =>
    'standin-cache:${jsonEncode([organizationId, id])}';

String remoteCacheId(String id) {
  if (!id.startsWith('standin-cache:')) return id;
  final parts = jsonDecode(id.substring('standin-cache:'.length)) as List;
  return parts[1] as String;
}

class AttendanceTable extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  DateTimeColumn get attendanceDate => dateTime()();
  TextColumn get status => text()();
  RealColumn get actualUnits => real()();
  RealColumn get expectedUnits => real()();
  TextColumn get policyVersionId => text().nullable()();
  TextColumn get calendarVersionId => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get protectedData => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OrganizationRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get branch => text().nullable()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  BoolColumn get isHolidayCalendarConfigured =>
      boolean().withDefault(const Constant(false))();
  IntColumn get followerCount => integer().withDefault(const Constant(0))();
  TextColumn get activePolicyId => text().nullable()();
  TextColumn get activeCalendarId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ScopeRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get activePolicyId => text().nullable()();
  TextColumn get activeCalendarId => text().nullable()();
  IntColumn get followerCount => integer().withDefault(const Constant(0))();
  TextColumn get createdBy => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FollowRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  RealColumn get personalTargetPercent => real().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get followedAt => dateTime()();
  TextColumn get personalBasis => text().nullable()();
  TextColumn get personalEvaluationPeriod => text().nullable()();
  RealColumn get personalFullUnit => real().nullable()();
  RealColumn get personalHalfUnit => real().nullable()();
  DateTimeColumn get personalStartDate => dateTime().nullable()();
  DateTimeColumn get personalEndDate => dateTime().nullable()();
  TextColumn get personalWeeklyOffs => text().nullable()(); // JSON string [7]
  TextColumn get personalOffSaturdays =>
      text().nullable()(); // JSON string [2, 4]
  TextColumn get personalHolidays => text().nullable()(); // JSON string list
  BoolColumn get isPersonalCalendarConfigured =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  IntColumn get version => integer()();
  DateTimeColumn get effectiveFrom => dateTime()();
  TextColumn get weeklyOffs => text()(); // JSON string
  TextColumn get offSaturdays => text()(); // JSON string
  TextColumn get holidays => text().nullable()(); // JSON string list
  BoolColumn get isConfigured => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MembershipRows extends Table {
  TextColumn get uid => text()();
  TextColumn get organizationId => text()();
  TextColumn get status => text()();
  TextColumn get idNumber => text().nullable()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {uid, organizationId};
}

class OrganizationPolicyRows extends Table {
  TextColumn get policyId => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  IntColumn get version => integer()();
  DateTimeColumn get effectiveFrom => dateTime()();
  TextColumn get state => text()();
  TextColumn get evaluationPeriod => text()();
  RealColumn get minimumPercent => real().nullable()();
  TextColumn get calculationBasis => text()();
  RealColumn get fullUnit => real()();
  RealColumn get halfUnit => real()();
  TextColumn get weeklyOffs =>
      text().withDefault(const Constant('[]'))(); // JSON string
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get creditRules => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {policyId};
}

class SyncQueueRows extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserProfileRows extends Table {
  TextColumn get uid => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()();
  TextColumn get mobile => text().nullable()();
  TextColumn get registrationNumber => text().nullable()();
  TextColumn get activeFollowId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {uid};
}

class SyncMetadataRows extends Table {
  TextColumn get key => text()();
  DateTimeColumn get lastSyncAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

class AttendancePlanRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  RealColumn get units => real()();
  RealColumn get leaveUnits => real().withDefault(const Constant(0))();
  TextColumn get policyVersionId => text().nullable()();
  TextColumn get calendarVersionId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarStateRows extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  AttendanceTable,
  OrganizationRows,
  ScopeRows,
  FollowRows,
  MembershipRows,
  UserProfileRows,
  OrganizationPolicyRows,
  CalendarRows,
  SyncQueueRows,
  SyncMetadataRows,
  AttendancePlanRows,
  CalendarStateRows
])
class StandInDatabase extends _$StandInDatabase {
  StandInDatabase(String dbName) : super(impl.connect(dbName));
  StandInDatabase.executor(super.e);
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(scopeRows, scopeRows.followerCount);
          await m.addColumn(scopeRows, scopeRows.createdBy);
          await m.addColumn(scopeRows, scopeRows.isArchived);
          await m.createTable(attendancePlanRows);
        }
        if (from < 3) {
          await m.addColumn(
              userProfileRows, userProfileRows.registrationNumber);
          await m.createTable(calendarStateRows);
        }
        if (from < 4) {
          final tables = await customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table'")
              .get();
          final names = tables.map((r) => r.read<String>('name')).toSet();
          if (from >= 2) {
            if (names.contains('attendance_plan_rows')) {
              await m.addColumn(
                  attendancePlanRows, attendancePlanRows.leaveUnits);
            } else {
              await m.createTable(attendancePlanRows);
            }
          }
          if (names.contains('attendance_table')) {
            await m.addColumn(attendanceTable, attendanceTable.protectedData);
          } else {
            await m.createTable(attendanceTable);
          }
          if (names.contains('organization_policy_rows')) {
            await m.addColumn(
                organizationPolicyRows, organizationPolicyRows.creditRules);
          } else {
            await m.createTable(organizationPolicyRows);
          }
        }
      });

  Future<CalendarStateRow?> getCalendarState(String id) =>
      (select(calendarStateRows)..where((row) => row.id.equals(id)))
          .getSingleOrNull();
  Stream<CalendarStateRow?> watchCalendarState(String id) =>
      (select(calendarStateRows)..where((row) => row.id.equals(id)))
          .watchSingleOrNull();
  Future<void> saveCalendarState(String id, String payload) =>
      into(calendarStateRows).insertOnConflictUpdate(
          CalendarStateRowsCompanion.insert(id: id, payload: payload));

  Future<void> upsertPlan(AttendancePlanRowsCompanion row) =>
      into(attendancePlanRows).insertOnConflictUpdate(row);
  Future<AttendancePlanRow?> getPlan(String id) =>
      (select(attendancePlanRows)..where((row) => row.id.equals(id)))
          .getSingleOrNull();
  Stream<List<AttendancePlanRow>> watchPlans(
          String organizationId, String scopeId) =>
      (select(attendancePlanRows)
            ..where((row) =>
                row.organizationId.equals(organizationId) &
                row.scopeId.equals(scopeId) &
                row.isDeleted.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.date)]))
          .watch();

  Stream<List<FollowRow>> watchFollows() =>
      (select(followRows)..where((row) => row.status.equals('active'))).watch();

  Stream<List<AttendanceTableData>> watchAttendance(String organizationId,
          {String? scopeId}) =>
      (select(attendanceTable)
            ..where((row) =>
                row.organizationId.equals(organizationId) &
                (scopeId == null
                    ? const Constant(true)
                    : row.scopeId.equals(scopeId)))
            ..orderBy([(row) => OrderingTerm.desc(row.attendanceDate)]))
          .watch();

  Future<void> upsertAttendance(AttendanceTableCompanion row) =>
      into(attendanceTable).insertOnConflictUpdate(row);

  Future<void> upsertUserProfile(UserProfileRowsCompanion row) =>
      into(userProfileRows).insertOnConflictUpdate(row);

  Future<void> upsertOrganization(OrganizationRowsCompanion row) =>
      into(organizationRows).insertOnConflictUpdate(row);

  Future<void> upsertScope(ScopeRowsCompanion row) =>
      into(scopeRows).insertOnConflictUpdate(row);

  Future<void> upsertFollow(FollowRowsCompanion row) =>
      into(followRows).insertOnConflictUpdate(row);

  Future<void> upsertMembership(MembershipRowsCompanion row) =>
      into(membershipRows).insertOnConflictUpdate(row);

  Future<void> savePolicy(OrganizationPolicyRowsCompanion row) =>
      into(organizationPolicyRows).insertOnConflictUpdate(row.copyWith(
        policyId:
            Value(scopedCacheId(row.organizationId.value, row.policyId.value)),
      ));

  Future<void> saveCalendar(CalendarRowsCompanion row) =>
      into(calendarRows).insertOnConflictUpdate(row.copyWith(
        id: Value(scopedCacheId(row.organizationId.value, row.id.value)),
      ));

  Future<CalendarRow?> getCalendarById(String id,
      {required String organizationId}) async {
    final scoped = await (select(calendarRows)
          ..where((row) =>
              row.id.equals(scopedCacheId(organizationId, id)) &
              row.organizationId.equals(organizationId)))
        .getSingleOrNull();
    return scoped ??
        await (select(calendarRows)
              ..where((row) =>
                  row.id.equals(id) &
                  row.organizationId.equals(organizationId)))
            .getSingleOrNull();
  }

  Future<CalendarRow?> calendarAt(
          String organizationId, String scopeId, DateTime date) =>
      (select(calendarRows)
            ..where((row) =>
                row.organizationId.equals(organizationId) &
                row.scopeId.equals(scopeId) &
                row.effectiveFrom.isSmallerOrEqualValue(date))
            ..orderBy([
              (row) => OrderingTerm.desc(row.effectiveFrom),
              (row) => OrderingTerm.desc(row.id.like('standin-cache:%')),
              (row) => OrderingTerm.desc(row.updatedAt)
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<OrganizationPolicyRow?> policyAt(
          String organizationId, String scopeId, DateTime date) =>
      (select(organizationPolicyRows)
            ..where((row) =>
                row.organizationId.equals(organizationId) &
                row.scopeId.equals(scopeId) &
                row.effectiveFrom.isSmallerOrEqualValue(date))
            ..orderBy([
              (row) => OrderingTerm.desc(row.effectiveFrom),
              (row) => OrderingTerm.desc(row.policyId.like('standin-cache:%')),
              (row) => OrderingTerm.desc(row.updatedAt)
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<OrganizationPolicyRow?> getPolicyById(String id,
      {required String organizationId}) async {
    final scoped = await (select(organizationPolicyRows)
          ..where((row) =>
              row.policyId.equals(scopedCacheId(organizationId, id)) &
              row.organizationId.equals(organizationId)))
        .getSingleOrNull();
    return scoped ??
        await (select(organizationPolicyRows)
              ..where((row) =>
                  row.policyId.equals(id) &
                  row.organizationId.equals(organizationId)))
            .getSingleOrNull();
  }

  Future<AttendanceTableData?> getAttendance(String id) =>
      (select(attendanceTable)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Future<SyncQueueRow?> getOperation(String id) =>
      (select(syncQueueRows)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Stream<SyncQueueRow?> watchOperation(String id) =>
      (select(syncQueueRows)..where((row) => row.id.equals(id)))
          .watchSingleOrNull();

  Future<DateTime?> nextSyncAttemptAt() => (select(syncQueueRows)
        ..orderBy([(row) => OrderingTerm.asc(row.nextAttemptAt)])
        ..limit(1))
      .getSingleOrNull()
      .then((row) => row?.nextAttemptAt);

  Future<OrganizationRow?> getOrganization(String id) =>
      (select(organizationRows)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Future<ScopeRow?> getScope(String id) =>
      (select(scopeRows)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<FollowRow?> getFollow(String id) =>
      (select(followRows)..where((row) => row.id.equals(id))).getSingleOrNull();

  Stream<FollowRow?> watchFollow(String id) =>
      (select(followRows)..where((row) => row.id.equals(id)))
          .watchSingleOrNull();

  Future<UserProfileRow?> getUserProfile(String uid) =>
      (select(userProfileRows)..where((row) => row.uid.equals(uid)))
          .getSingleOrNull();

  Stream<UserProfileRow?> watchUserProfile(String uid) =>
      (select(userProfileRows)..where((row) => row.uid.equals(uid)))
          .watchSingleOrNull();

  final _enqueueController = StreamController<void>.broadcast();
  Stream<void> get onEnqueue => _enqueueController.stream;

  Future<void> enqueue(SyncQueueRowsCompanion row) async {
    await into(syncQueueRows).insertOnConflictUpdate(row);
    _enqueueController.add(null);
  }

  Future<List<SyncQueueRow>> dueSyncOperations(DateTime now,
          {int limit = 25}) =>
      (select(syncQueueRows)
            ..where((row) => row.nextAttemptAt.isSmallerOrEqualValue(now))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
            ..limit(limit))
          .get();

  Future<void> deleteOperation(String id) =>
      (delete(syncQueueRows)..where((row) => row.id.equals(id))).go();

  Future<void> acknowledgeOperation(SyncQueueRow operation) =>
      transaction(() async {
        final deleted = await (delete(syncQueueRows)
              ..where((row) =>
                  row.id.equals(operation.id) &
                  row.payload.equals(operation.payload)))
            .go();
        if (deleted > 0 && operation.operation == 'upsertAttendance') {
          await (update(attendanceTable)
                ..where((row) => row.id.equals(operation.entityId)))
              .write(const AttendanceTableCompanion(
                  pendingSync: Value(false), syncError: Value(null)));
        }
        if (deleted > 0 && operation.operation == 'putPlan') {
          await (update(attendancePlanRows)
                ..where((row) => row.id.equals(operation.entityId)))
              .write(
                  const AttendancePlanRowsCompanion(pendingSync: Value(false)));
        }
      });

  Future<void> rescheduleUnchangedOperation(SyncQueueRow operation,
          int attempts, DateTime nextAttemptAt, String error) =>
      (update(syncQueueRows)
            ..where((row) =>
                row.id.equals(operation.id) &
                row.payload.equals(operation.payload)))
          .write(SyncQueueRowsCompanion(
              attemptCount: Value(attempts),
              nextAttemptAt: Value(nextAttemptAt),
              lastError: Value(error)));

  /// A retry must never replace an edit made after the status was displayed.
  Future<bool> retryUnchangedOperation(SyncQueueRow operation) async {
    final updated = await (update(syncQueueRows)
          ..where((row) =>
              row.id.equals(operation.id) &
              row.payload.equals(operation.payload)))
        .write(SyncQueueRowsCompanion(
            attemptCount: const Value(0),
            lastError: const Value(null),
            nextAttemptAt: Value(DateTime.now())));
    if (updated > 0) _enqueueController.add(null);
    return updated > 0;
  }

  Future<void> clearPersonalData() => transaction(() async {
        await delete(syncQueueRows).go();
        await delete(attendanceTable).go();
        await delete(attendancePlanRows).go();
        await delete(calendarStateRows).go();
        await delete(followRows).go();
        await delete(membershipRows).go();
        await delete(userProfileRows).go();
        await delete(syncMetadataRows).go();
      });

  @override
  Future<void> close() async {
    await _enqueueController.close();
    await super.close();
  }

  Future<void> rescheduleOperation(
          String id, int attemptCount, DateTime nextAttemptAt, String error) =>
      (update(syncQueueRows)..where((row) => row.id.equals(id))).write(
          SyncQueueRowsCompanion(
              attemptCount: Value(attemptCount),
              nextAttemptAt: Value(nextAttemptAt),
              lastError: Value(error)));

  Future<DateTime?> getLastSyncAt(String key) =>
      (select(syncMetadataRows)..where((row) => row.key.equals(key)))
          .getSingleOrNull()
          .then((row) => row?.lastSyncAt);

  Future<void> setLastSyncAt(String key, DateTime at) =>
      into(syncMetadataRows).insertOnConflictUpdate(
          SyncMetadataRowsCompanion.insert(key: key, lastSyncAt: at));
}
