import 'dart:async';
import 'dart:convert';

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
import 'package:standin/src/domain/planning.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/domain/calendar_updates.dart';

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
      registerFallbackValue(
          PersonalCalendarState(baseline: AttendanceCalendar.unconfigured));
      registerFallbackValue(AttendancePlan(
          id: 'plan',
          organizationId: 'org',
          scopeId: 'global',
          date: DateTime(2100),
          status: AttendanceStatus.full,
          units: 1));
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
      when(() => attendanceRemote.getPlansDelta('user', any()))
          .thenAnswer((_) async => []);
      when(() => userRemote.getFollows('user')).thenAnswer((_) async => []);
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

    test('retry never replaces an edit made after the error was shown',
        () async {
      final date = DateTime(2026, 1, 1);
      final id = attendanceId(date, 'org', 'global');
      await repository.save(record(date));
      final oldOperation = (await database.getOperation('attendance:$id'))!;
      final previous = LocalFirstAttendanceRepository.toDomain(
          (await database.getAttendance(id))!);
      await repository.save(record(date, status: AttendanceStatus.absent)
          .copyWith(baseRevision: previous.fingerprint));
      expect(await database.retryUnchangedOperation(oldOperation), false);
      final current = (await database.getOperation('attendance:$id'))!;
      expect(AttendanceRecord.fromJson(jsonDecode(current.payload)).status,
          AttendanceStatus.absent);
      expect(await database.retryUnchangedOperation(current), true);
      expect(
          AttendanceRecord.fromJson(jsonDecode(
                  (await database.getOperation('attendance:$id'))!.payload))
              .status,
          AttendanceStatus.absent);
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

    test(
        'calendar edits during upload rebase without losing another device holiday',
        () async {
      final calendars =
          CalendarRepository(database, userRemote, uid: 'user', followId: 'f');
      when(() => userRemote.getCalendarState('user', 'f'))
          .thenAnswer((_) async => null);
      await calendars.ensure(AttendanceCalendar(
          id: 'c',
          version: 1,
          effectiveFrom: DateTime(2000),
          organizationId: 'org',
          scopeId: 'global',
          isConfigured: true));
      final base = (await calendars.read())!;
      await database.acknowledgeOperation(
          (await database.getOperation(calendars.operationId))!);
      PersonalCalendarState server = base.withDate(DateTime(2026, 12, 29),
          Holiday(date: DateTime(2026, 12, 29), name: 'Other device'));
      await calendars.setHoliday(DateTime(2026, 12, 28),
          Holiday(date: DateTime(2026, 12, 28), name: 'First local'));
      final entered = Completer<void>();
      final release = Completer<void>();
      var writes = 0;
      when(() => userRemote.putCalendarState(any(), any(), any(), any()))
          .thenAnswer((call) async {
        if (++writes == 1) {
          entered.complete();
          await release.future;
        }
        server = PersonalCalendarState.merge(
            call.positionalArguments[2] as PersonalCalendarState?,
            call.positionalArguments[3] as PersonalCalendarState,
            server);
        return server;
      });
      final syncing = engine.syncNow();
      await entered.future;
      await calendars.setHoliday(DateTime(2026, 12, 30),
          Holiday(date: DateTime(2026, 12, 30), name: 'New local'));
      release.complete();
      await syncing;
      expect(writes, 2);
      expect((await calendars.read())!.calendar.holidays.map((h) => h.name),
          containsAll(['First local', 'New local', 'Other device']));
      expect(
          sameCalendarValue(
              (await calendars.read())!.toJson(), server.toJson()),
          isTrue);
      expect(await database.getOperation(calendars.operationId), isNull);
    });

    test(
        'a rejected calendar upload and incoming snapshot preserve pending private edits',
        () async {
      final calendars =
          CalendarRepository(database, userRemote, uid: 'user', followId: 'f');
      when(() => userRemote.getCalendarState('user', 'f'))
          .thenAnswer((_) async => null);
      await calendars.ensure(AttendanceCalendar(
          id: 'c',
          version: 1,
          effectiveFrom: DateTime(2000),
          organizationId: 'org',
          scopeId: 'global',
          isConfigured: true));
      final base = (await calendars.read())!;
      await calendars.setHoliday(DateTime(2026, 12, 28),
          Holiday(date: DateTime(2026, 12, 28), name: 'Mine'));
      when(() => userRemote.putCalendarState(any(), any(), any(), any()))
          .thenThrow(StateError('Offline'));
      await engine.syncNow();
      await calendars.receive(base);
      final pending = (await database.getOperation(calendars.operationId))!;
      expect(pending.attemptCount, 1);
      expect((await calendars.read())!.calendar.holidays.single.name, 'Mine');
      expect(jsonDecode(pending.payload)['next']['dates'].keys,
          contains('2026-12-28'));
      when(() => userRemote.putCalendarState(any(), any(), any(), any()))
          .thenAnswer((call) async =>
              call.positionalArguments[3] as PersonalCalendarState);
      await calendars.retry();
      await engine.syncNow();
      expect(await database.getOperation(calendars.operationId), isNull);
      expect((await calendars.read())!.calendar.holidays.single.name, 'Mine');
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
      final previous = LocalFirstAttendanceRepository.toDomain(
          (await database.getAttendance(attendanceId(date, 'org', 'global')))!);
      await repository.save(record(date, status: AttendanceStatus.absent)
          .copyWith(baseRevision: previous.fingerprint));
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
        'a plan edited during upload stays queued until the newest value is synced',
        () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 1);
      final plans = PlanningRepository(database,
          organizationId: 'org', scopeId: 'global');
      AttendancePlan entry(double units) => AttendancePlan(
          id: attendanceId(date, 'org', 'global'),
          organizationId: 'org',
          scopeId: 'global',
          date: date,
          status: AttendanceStatus.partial,
          units: units);
      await plans.save(entry(7));
      final entered = Completer<void>();
      final release = Completer<void>();
      final uploaded = <double>[];
      when(() => attendanceRemote.putPlan(any(), any()))
          .thenAnswer((call) async {
        uploaded.add((call.positionalArguments[1] as AttendancePlan).units);
        if (uploaded.length == 1) {
          entered.complete();
          await release.future;
        }
      });
      final syncing = engine.syncNow();
      await entered.future;
      await plans.save(entry(3));
      release.complete();
      await syncing;
      expect(uploaded, [7, 3]);
      expect((await database.getPlan(entry(3).id))!.pendingSync, isFalse);
      expect(await database.getOperation('plan:${entry(3).id}'), isNull);
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
    when(() => attendanceRemote.getPlansDelta('user', any()))
        .thenAnswer((_) async => []);
    when(() => userRemote.getFollows('user')).thenAnswer((_) async => []);
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
