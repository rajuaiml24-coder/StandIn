import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'standin_database.g.dart';

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
  @override Set<Column<Object>> get primaryKey => {id};
}

class OrganizationRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  BoolColumn get isHolidayCalendarConfigured => boolean().withDefault(const Constant(false))();
  TextColumn get activePolicyId => text().nullable()();
  TextColumn get activeCalendarId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class ScopeRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get activePolicyId => text().nullable()();
  TextColumn get activeCalendarId => text().nullable()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class FollowRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get scopeId => text()();
  RealColumn get personalTargetPercent => real().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get followedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class MembershipRows extends Table {
  TextColumn get uid => text()();
  TextColumn get organizationId => text()();
  TextColumn get status => text()();
  TextColumn get idNumber => text().nullable()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  @override Set<Column<Object>> get primaryKey => {uid, organizationId};
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
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {policyId};
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
  @override Set<Column<Object>> get primaryKey => {id};
}

class UserProfileRows extends Table {
  TextColumn get uid => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()();
  TextColumn get mobile => text().nullable()();
  TextColumn get activeFollowId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {uid};
}

class SyncMetadataRows extends Table {
  TextColumn get key => text()();
  DateTimeColumn get lastSyncAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [AttendanceTable, OrganizationRows, ScopeRows, FollowRows, MembershipRows, UserProfileRows, OrganizationPolicyRows, SyncQueueRows, SyncMetadataRows])
class StandInDatabase extends _$StandInDatabase {
  StandInDatabase()
      : super(driftDatabase(
          name: 'standin',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));
  StandInDatabase.executor(super.e);
  @override
  int get schemaVersion => 1;

  Stream<List<AttendanceTableData>> watchAttendance(String organizationId) =>
      (select(attendanceTable)..where((row) => row.organizationId.equals(organizationId))..orderBy([(row) => OrderingTerm.desc(row.attendanceDate)])).watch();

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
      into(organizationPolicyRows).insertOnConflictUpdate(row);

  Future<OrganizationPolicyRow?> policyAt(String organizationId, String scopeId, DateTime date) =>
      (select(organizationPolicyRows)..where((row) => 
        row.organizationId.equals(organizationId) & 
        row.scopeId.equals(scopeId) &
        row.effectiveFrom.isSmallerOrEqualValue(date)
      )..orderBy([(row) => OrderingTerm.desc(row.effectiveFrom)])..limit(1)).getSingleOrNull();

  Future<OrganizationRow?> getOrganization(String id) =>
      (select(organizationRows)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<ScopeRow?> getScope(String id) =>
      (select(scopeRows)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<FollowRow?> getFollow(String id) =>
      (select(followRows)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<UserProfileRow?> getUserProfile(String uid) =>
      (select(userProfileRows)..where((row) => row.uid.equals(uid))).getSingleOrNull();

  Future<void> enqueue(SyncQueueRowsCompanion row) => into(syncQueueRows).insertOnConflictUpdate(row);

  Future<List<SyncQueueRow>> dueSyncOperations(DateTime now, {int limit = 25}) =>
      (select(syncQueueRows)..where((row) => row.nextAttemptAt.isSmallerOrEqualValue(now))..orderBy([(row) => OrderingTerm.asc(row.createdAt)])..limit(limit)).get();

  Future<void> deleteOperation(String id) => (delete(syncQueueRows)..where((row) => row.id.equals(id))).go();

  Future<void> rescheduleOperation(String id, int attemptCount, DateTime nextAttemptAt, String error) =>
      (update(syncQueueRows)..where((row) => row.id.equals(id))).write(SyncQueueRowsCompanion(attemptCount: Value(attemptCount), nextAttemptAt: Value(nextAttemptAt), lastError: Value(error)));

  Future<DateTime?> getLastSyncAt(String key) =>
      (select(syncMetadataRows)..where((row) => row.key.equals(key))).getSingleOrNull().then((row) => row?.lastSyncAt);

  Future<void> setLastSyncAt(String key, DateTime at) =>
      into(syncMetadataRows).insertOnConflictUpdate(SyncMetadataRowsCompanion.insert(key: key, lastSyncAt: at));
}
