import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'standin_database.g.dart';

class AttendanceRows extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  DateTimeColumn get attendanceDate => dateTime()();
  TextColumn get status => text()();
  RealColumn get actualUnits => real()();
  RealColumn get expectedUnits => real()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class OrganizationPolicyRows extends Table {
  TextColumn get policyId => text()();
  TextColumn get organizationId => text()();
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

@DriftDatabase(tables: [AttendanceRows, OrganizationPolicyRows, SyncQueueRows])
class StandInDatabase extends _$StandInDatabase {
  StandInDatabase() : super(driftDatabase(name: 'standin'));
  @override int get schemaVersion => 1;

  Stream<List<AttendanceRow>> watchAttendance(String organizationId) =>
      (select(attendanceRows)..where((row) => row.organizationId.equals(organizationId))..orderBy([(row) => OrderingTerm.desc(row.attendanceDate)])).watch();

  Future<void> upsertAttendance(AttendanceRowsCompanion row) =>
      into(attendanceRows).insertOnConflictUpdate(row);

  Future<void> savePolicy(OrganizationPolicyRowsCompanion row) =>
      into(organizationPolicyRows).insertOnConflictUpdate(row);

  Future<OrganizationPolicyRow?> policyAt(String organizationId, DateTime date) =>
      (select(organizationPolicyRows)..where((row) => row.organizationId.equals(organizationId) & row.effectiveFrom.isSmallerOrEqualValue(date))..orderBy([(row) => OrderingTerm.desc(row.effectiveFrom)])..limit(1)).getSingleOrNull();

  Future<void> enqueue(SyncQueueRowsCompanion row) => into(syncQueueRows).insertOnConflictUpdate(row);

  Future<List<SyncQueueRow>> dueSyncOperations(DateTime now, {int limit = 25}) =>
      (select(syncQueueRows)..where((row) => row.nextAttemptAt.isSmallerOrEqualValue(now))..orderBy([(row) => OrderingTerm.asc(row.createdAt)])..limit(limit)).get();

  Future<void> deleteOperation(String id) => (delete(syncQueueRows)..where((row) => row.id.equals(id))).go();

  Future<void> rescheduleOperation(String id, int attemptCount, DateTime nextAttemptAt, String error) =>
      (update(syncQueueRows)..where((row) => row.id.equals(id))).write(SyncQueueRowsCompanion(attemptCount: Value(attemptCount), nextAttemptAt: Value(nextAttemptAt), lastError: Value(error)));
}
