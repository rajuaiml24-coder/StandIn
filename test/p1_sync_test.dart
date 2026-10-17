import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/data/attendance_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/sync/sync_engine.dart';
import 'package:standin/src/domain/attendance.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockAttendanceRemote extends Mock implements FirestoreAttendanceRemote {}

class MockUserRemote extends Mock implements FirestoreUserRemote {}

class MockOrgRemote extends Mock implements FirestoreOrgRemote {}

class MockDatabase extends Mock implements StandInDatabase {}

AttendanceRecord record(DateTime date,
        {AttendanceStatus status = AttendanceStatus.full,
        DateTime? updatedAt}) =>
    AttendanceRecord(
      date: date,
      status: status,
      actualUnits: status == AttendanceStatus.full ? 7 : 0,
      expectedUnits: 7,
      organizationId: 'org',
      scopeId: 'global',
      updatedAt: updatedAt,
    );

void main() {
  group('Durable sync', () {
    late StandInDatabase database;
    late LocalFirstAttendanceRepository repository;
    late MockConnectivity connectivity;
    late MockAttendanceRemote attendanceRemote;
    late MockUserRemote userRemote;
    late MockOrgRemote orgRemote;
    late SyncEngine engine;

    setUpAll(() {
      registerFallbackValue(DateTime(2000));
      registerFallbackValue(record(DateTime(2000)));
    });
    setUp(() {
      database = StandInDatabase.executor(NativeDatabase.memory());
      repository = LocalFirstAttendanceRepository(database,
          uid: 'user', organizationId: 'org', scopeId: 'global');
      connectivity = MockConnectivity();
      attendanceRemote = MockAttendanceRemote();
      userRemote = MockUserRemote();
      orgRemote = MockOrgRemote();
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => connectivity.onConnectivityChanged)
          .thenAnswer((_) => const Stream.empty());
      when(() => attendanceRemote.putAttendance(any(), any(), any()))
          .thenAnswer((_) async {});
      when(() => attendanceRemote.getAttendanceDelta('user', any()))
          .thenAnswer((_) async => []);
      when(() => userRemote.watchProfile('user'))
          .thenAnswer((_) => Stream.value(null));
      engine = SyncEngine(database, attendanceRemote, userRemote, orgRemote,
          OrganizationRepository(database, orgRemote),
          uid: 'user', connectivity: connectivity);
    });
    tearDown(() async {
      await engine.stop();
      await database.close();
    });

    test('a single sync drains more than 25 queued records', () async {
      for (var day = 1; day <= 61; day++) {
        await repository.save(record(DateTime(2026, 1, day)));
      }
      await engine.syncNow();
      verify(() => attendanceRemote.putAttendance('user', any(), any()))
          .called(61);
      expect(await database.select(database.syncQueueRows).get(), isEmpty);
      final rows = await database.select(database.attendanceTable).get();
      expect(rows, hasLength(61));
      expect(rows.every((row) => !row.pendingSync), isTrue);
    });

    test('concurrent syncs serialize and an edit during upload is not lost',
        () async {
      final date = DateTime(2026, 1, 1);
      await repository.save(record(date));
      final entered = Completer<void>();
      final release = Completer<void>();
      final uploaded = <AttendanceRecord>[];
      when(() => attendanceRemote.putAttendance(any(), any(), any()))
          .thenAnswer((call) async {
        uploaded.add(call.positionalArguments[2] as AttendanceRecord);
        if (uploaded.length == 1) {
          entered.complete();
          await release.future;
        }
      });
      final first = engine.syncNow();
      await entered.future;
      final second = engine.syncNow();
      expect(identical(first, second), isTrue);
      await repository.save(record(date, status: AttendanceStatus.absent));
      release.complete();
      await first;
      expect(uploaded.map((row) => row.status),
          [AttendanceStatus.full, AttendanceStatus.absent]);
      expect(await database.select(database.syncQueueRows).get(), isEmpty);
      final saved =
          await database.getAttendance(attendanceId(date, 'org', 'global'));
      expect(saved!.actualUnits, 0);
      expect(saved.pendingSync, isFalse);
    });

    test(
        'failed uploads keep local edits, and checkpoints use the server timestamp',
        () async {
      final date = DateTime(2026, 1, 1);
      final stamp = DateTime(2026, 1, 2, 12, 34, 56);
      await repository.save(record(date, status: AttendanceStatus.absent));
      when(() => attendanceRemote.putAttendance(any(), any(), any()))
          .thenThrow(StateError('Offline'));
      when(() => attendanceRemote.getAttendanceDelta('user', any()))
          .thenAnswer((_) async => [record(date, updatedAt: stamp)]);
      await engine.syncNow();
      final saved =
          await database.getAttendance(attendanceId(date, 'org', 'global'));
      expect(saved!.actualUnits, 0);
      expect(saved.pendingSync, isTrue);
      final queued =
          (await database.select(database.syncQueueRows).get()).single;
      expect(queued.attemptCount, 1);
      expect(queued.nextAttemptAt.isAfter(DateTime.now()), isTrue);
      expect(await database.getLastSyncAt('attendance:user'), stamp);
      await engine.syncNow();
      verify(() => attendanceRemote.getAttendanceDelta('user', stamp))
          .called(1);
    });

    test('a local edit made during a remote pull remains pending', () async {
      final date = DateTime(2026, 1, 1);
      final entered = Completer<void>();
      final release = Completer<List<AttendanceRecord>>();
      when(() => attendanceRemote.getAttendanceDelta('user', any()))
          .thenAnswer((_) {
        entered.complete();
        return release.future;
      });
      final sync = engine.syncNow();
      await entered.future;
      await repository.save(record(date, status: AttendanceStatus.absent));
      release.complete([record(date, updatedAt: DateTime(2026, 1, 2))]);
      await sync;
      final saved =
          await database.getAttendance(attendanceId(date, 'org', 'global'));
      expect(saved!.status, 'absent');
      expect(saved.pendingSync, isTrue);
      expect(await database.select(database.syncQueueRows).get(), hasLength(1));
    });

    test(
        'unknown operations are retained with a retry instead of silently discarded',
        () async {
      await database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'unknown',
        operation: 'unsupported',
        entityId: 'unknown',
        payload: '{}',
        nextAttemptAt: DateTime(2000),
        createdAt: DateTime(2000),
      ));
      await engine.syncNow();
      final queued = await database.getOperation('unknown');
      expect(queued, isNotNull);
      expect(queued!.attemptCount, 1);
      expect(queued.lastError, contains('Unknown sync operation'));
    });

    test('stopping waits for an in-flight upload before deletion can continue',
        () async {
      await repository.save(record(DateTime(2026, 1, 1)));
      final entered = Completer<void>();
      final release = Completer<void>();
      when(() => attendanceRemote.putAttendance(any(), any(), any()))
          .thenAnswer((_) async {
        entered.complete();
        await release.future;
      });
      final sync = engine.syncNow();
      await entered.future;
      var stopped = false;
      final stop = engine.stop().then((_) => stopped = true);
      await Future<void>.delayed(Duration.zero);
      expect(stopped, isFalse);
      release.complete();
      await stop;
      await sync;
      verifyNever(() => attendanceRemote.getAttendanceDelta(any(), any()));
    });
  });

  test('startup and retry timers run without a new connectivity event',
      () async {
    final connectivity = MockConnectivity();
    final attendanceRemote = MockAttendanceRemote();
    final userRemote = MockUserRemote();
    final orgRemote = MockOrgRemote();
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => userRemote.watchProfile('user'))
        .thenAnswer((_) => Stream.value(null));
    final mockDb = MockDatabase();
    var attempts = 0;
    final startup = Completer<void>();
    final retry = Completer<void>();
    when(() => mockDb.onEnqueue).thenAnswer((_) => const Stream.empty());
    when(() => mockDb.dueSyncOperations(any())).thenAnswer((_) async => []);
    when(() => mockDb.nextSyncAttemptAt()).thenAnswer(
        (_) async => DateTime.now().add(const Duration(milliseconds: 20)));
    when(() => mockDb.getLastSyncAt(any())).thenAnswer((_) async => null);
    when(() => attendanceRemote.getAttendanceDelta('user', any()))
        .thenAnswer((_) async {
      attempts++;
      if (attempts == 1) startup.complete();
      if (attempts == 2) retry.complete();
      return [];
    });
    final automatic = SyncEngine(mockDb, attendanceRemote, userRemote,
        orgRemote, OrganizationRepository(mockDb, orgRemote),
        uid: 'user', connectivity: connectivity);
    addTearDown(automatic.stop);
    automatic.start();
    await startup.future.timeout(const Duration(seconds: 5));
    expect(attempts, 1);
    await retry.future.timeout(const Duration(seconds: 5));
    expect(attempts, 2);
    await automatic.stop();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(attempts, 2);
  });
}
