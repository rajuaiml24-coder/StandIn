import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../local/standin_database.dart';
import '../remote/firestore_attendance_remote.dart';
import '../remote/firestore_user_remote.dart';
import '../remote/firestore_org_remote.dart';
import '../organization_repository.dart';
import '../attendance_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/planning.dart';
import '../planning_repository.dart';
import '../user_repository.dart';
import '../calendar_repository.dart';
import '../local_first_attendance_repository.dart';
import '../../domain/calendar_updates.dart';

class SyncEngine {
  SyncEngine(this._database, this._attendanceRemote, this._userRemote,
      this._orgRemote, this._orgRepository,
      {required this.uid, Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final StandInDatabase _database;
  final FirestoreAttendanceRemote _attendanceRemote;
  final FirestoreUserRemote _userRemote;
  final FirestoreOrgRemote _orgRemote;
  final OrganizationRepository _orgRepository;
  final String uid;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<void>? _triggerSubscription;

  Future<void>? _activeSync;
  bool _pendingTrigger = false;
  bool _started = false;
  bool _stopping = false;
  Timer? _retryTimer;

  void start() {
    if (_started) return;
    _started = true;
    _stopping = false;
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) _onTrigger();
    });

    _triggerSubscription = _database.onEnqueue.listen((_) => _onTrigger());
    _onTrigger();
  }

  Future<void> stop() async {
    _started = false;
    _stopping = true;
    _retryTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _triggerSubscription?.cancel();
    try {
      await _activeSync;
    } catch (_) {
      // Failed operations remain in the durable queue for the next session.
    }
  }

  void _onTrigger() {
    if (!_started || _stopping) return;
    unawaited(syncNow().catchError((Object error) {
      debugPrint('Attendance sync failed: $error');
    }));
  }

  Future<void> syncNow() {
    if (_stopping) return Future.value();
    if (_activeSync != null) {
      _pendingTrigger = true;
      return _activeSync!;
    }
    _activeSync = _runSync().whenComplete(() => _activeSync = null);
    return _activeSync!;
  }

  Future<void> _runSync() async {
    _retryTimer?.cancel();
    var failed = false;
    try {
      do {
        _pendingTrigger = false;
        final connection = await _connectivity.checkConnectivity();
        if (connection.contains(ConnectivityResult.none) || _stopping) return;
        await _pushLocalChanges();
        if (!_stopping) await _pullRemoteChanges();
        if (!_stopping && await _database.nextSyncAttemptAt() == null) {
          await _database.setLastSyncAt('backup:$uid', DateTime.now());
        }
      } while (_pendingTrigger && !_stopping);
    } catch (_) {
      failed = true;
      rethrow;
    } finally {
      if (_started && !_stopping) {
        final next = await _database.nextSyncAttemptAt();
        if (_started && !_stopping && (next != null || failed)) {
          final delay =
              next?.difference(DateTime.now()) ?? const Duration(minutes: 1);
          _retryTimer = Timer(
              delay < const Duration(seconds: 1)
                  ? const Duration(seconds: 1)
                  : delay,
              _onTrigger);
        }
      }
    }
  }

  Future<void> _pushLocalChanges() async {
    while (!_stopping) {
      final operations = await _database.dueSyncOperations(DateTime.now());
      if (operations.isEmpty) return;
      for (final operation in operations) {
        if (_stopping) return;
        try {
          switch (operation.operation) {
            case 'putCalendarState':
              final payload =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final base = payload['base'] == null
                  ? null
                  : PersonalCalendarState.fromJson(
                      Map<String, dynamic>.from(payload['base'] as Map));
              final next = PersonalCalendarState.fromJson(
                  Map<String, dynamic>.from(payload['next'] as Map));
              final merged = await _userRemote.putCalendarState(
                  uid, operation.entityId, base, next);
              await _database.transaction(() async {
                final current = await _database.getOperation(operation.id);
                if (current?.payload == operation.payload) {
                  await _database.saveCalendarState(
                      operation.entityId, jsonEncode(merged.toJson()));
                } else if (current != null) {
                  final newer =
                      jsonDecode(current.payload) as Map<String, dynamic>;
                  final local = PersonalCalendarState.fromJson(
                      Map<String, dynamic>.from(newer['next'] as Map));
                  final rebased =
                      PersonalCalendarState.merge(next, local, merged);
                  await _database.saveCalendarState(
                      operation.entityId, jsonEncode(rebased.toJson()));
                  await _database.enqueue(SyncQueueRowsCompanion.insert(
                      id: current.id,
                      operation: current.operation,
                      entityId: current.entityId,
                      payload: jsonEncode(
                          {'base': merged.toJson(), 'next': rebased.toJson()}),
                      nextAttemptAt: DateTime.now(),
                      createdAt: current.createdAt));
                }
              });
              break;
            case 'putPlan':
              await _attendanceRemote.putPlan(
                  uid,
                  AttendancePlan.fromJson(
                      jsonDecode(operation.payload) as Map<String, dynamic>));
              break;
            case 'putOrganization':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final createdByUid = json['uid'] as String? ?? uid;
              final org = Organization(
                id: json['id'] as String,
                name: json['name'] as String,
                type: OrganizationType.values.byName(json['type'] as String),
                branch: json['branch'] as String?,
                isVerified: json['isVerified'] as bool? ?? false,
                isHolidayCalendarConfigured:
                    json['isHolidayCalendarConfigured'] as bool? ?? false,
                followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
                activePolicyId: json['activePolicyId'] as String?,
                activeCalendarId: json['activeCalendarId'] as String?,
                createdBy: createdByUid,
              );
              await _orgRemote.putOrganization(org, createdByUid);
              break;

            case 'putPolicy':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final orgId = json['organizationId'] as String;
              final pJson = json['policy'] as Map<String, dynamic>;
              final policy = AttendancePolicy(
                id: pJson['id'] as String,
                version: pJson['version'] as int,
                effectiveFrom: DateTime.parse(pJson['effectiveFrom'] as String),
                state: PolicyState.values.byName(pJson['state'] as String),
                evaluationPeriod: EvaluationPeriod.values
                    .byName(pJson['evaluationPeriod'] as String),
                minimumPercent: (pJson['minimumPercent'] as num?)?.toDouble(),
                basis: CalculationBasis.values.byName(pJson['basis'] as String),
                fullUnit: (pJson['fullUnit'] as num).toDouble(),
                halfUnit: (pJson['halfUnit'] as num).toDouble(),
                leaveTreatment: LeaveTreatment.values
                    .byName(pJson['leaveTreatment'] as String? ?? 'noCredit'),
                weekOffCredit: pJson['weekOffCredit'] as bool? ?? false,
                holidayCredit: pJson['holidayCredit'] as bool? ?? false,
                oneVisitFullDay: pJson['oneVisitFullDay'] as bool? ?? false,
                weeklyOffs: (pJson['weeklyOffs'] as List).cast<int>(),
                startDate: pJson['startDate'] != null
                    ? DateTime.parse(pJson['startDate'] as String)
                    : null,
                endDate: pJson['endDate'] != null
                    ? DateTime.parse(pJson['endDate'] as String)
                    : null,
                organizationId: orgId,
                scopeId: pJson['scopeId'] as String? ?? 'global',
              );
              await _orgRemote.putPolicy(orgId, policy);
              break;

            case 'putCalendar':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final orgId = json['organizationId'] as String;
              final cJson = json['calendar'] as Map<String, dynamic>;
              final calendar = AttendanceCalendar(
                id: cJson['id'] as String,
                version: cJson['version'] as int,
                effectiveFrom: DateTime.parse(cJson['effectiveFrom'] as String),
                weeklyOffs: (cJson['weeklyOffs'] as List).cast<int>(),
                offSaturdays: (cJson['offSaturdays'] as List).cast<int>(),
                holidays: (cJson['holidays'] as List)
                    .map((h) => Holiday.fromJson(h as Map<String, dynamic>))
                    .toList(),
                isConfigured: cJson['isConfigured'] as bool? ?? false,
                organizationId: orgId,
                scopeId: cJson['scopeId'] as String? ?? 'global',
              );
              await _orgRemote.putCalendar(orgId, calendar);
              break;

            case 'upsertAttendance':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final record = AttendanceRecord.fromJson(json);
              await _attendanceRemote.putAttendance(
                  uid, operation.entityId, record);
              await _database.transaction(() async {
                final newer = await _database.getOperation(operation.id);
                if (newer != null && newer.payload != operation.payload) {
                  final payload =
                      jsonDecode(newer.payload) as Map<String, dynamic>;
                  payload['baseRevision'] = record.fingerprint;
                  await _database.enqueue(newer
                      .toCompanion(false)
                      .copyWith(payload: Value(jsonEncode(payload))));
                }
              });
              break;

            case 'createUserProfile':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final profile = UserProfile(
                uid: json['uid'] as String,
                displayName: json['displayName'] as String,
                role: AppRole.values.byName(json['role'] as String),
                mobile: json['mobile'] as String?,
                registrationNumber: json['registrationNumber'] as String?,
                activeFollowId: json['activeFollowId'] as String?,
              );
              await _userRemote.createUserProfile(profile);
              break;

            case 'putFollow':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final follow = Follow(
                id: json['id'] as String,
                organizationId: json['organizationId'] as String,
                scopeId: json['scopeId'] as String,
                personalTargetPercent:
                    (json['personalTargetPercent'] as num?)?.toDouble(),
                status: json['status'] as String,
                followedAt: DateTime.parse(json['followedAt'] as String),
                personalBasis: json['personalBasis'] != null
                    ? CalculationBasis.values
                        .byName(json['personalBasis'] as String)
                    : null,
                personalEvaluationPeriod:
                    json['personalEvaluationPeriod'] != null
                        ? EvaluationPeriod.values
                            .byName(json['personalEvaluationPeriod'] as String)
                        : null,
                personalFullUnit:
                    (json['personalFullUnit'] as num?)?.toDouble(),
                personalHalfUnit:
                    (json['personalHalfUnit'] as num?)?.toDouble(),
                personalStartDate: json['personalStartDate'] != null
                    ? DateTime.parse(json['personalStartDate'] as String)
                    : null,
                personalEndDate: json['personalEndDate'] != null
                    ? DateTime.parse(json['personalEndDate'] as String)
                    : null,
                personalWeeklyOffs: json['personalWeeklyOffs'] as String?,
                personalOffSaturdays: json['personalOffSaturdays'] as String?,
                personalHolidays: json['personalHolidays'] as String?,
                isPersonalCalendarConfigured:
                    json['isPersonalCalendarConfigured'] as bool? ?? false,
              );
              await _userRemote.putFollow(uid, follow);
              break;

            case 'putMembership':
            case 'joinOrganizationAtomic':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final membership = Membership(
                uid: json['uid'] as String,
                organizationId: json['organizationId'] as String,
                status: json['status'] as String,
                idNumber: json['idNumber'] as String?,
                joinedAt: DateTime.parse(json['joinedAt'] as String),
                verifiedAt: json['verifiedAt'] != null
                    ? DateTime.parse(json['verifiedAt'] as String)
                    : null,
              );
              if (operation.operation == 'joinOrganizationAtomic') {
                await _orgRemote.joinOrganizationAtomic(
                    orgId: membership.organizationId, membership: membership);
              } else {
                await _orgRemote.putMembership(membership);
              }
              break;

            case 'leaveOrganizationAtomic':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              await _orgRemote.leaveOrganizationAtomic(
                  orgId: json['organizationId'] as String, uid: uid);
              break;

            case 'putScope':
              final json =
                  jsonDecode(operation.payload) as Map<String, dynamic>;
              final orgId = json['organizationId'] as String;
              final scope = Scope(
                id: json['id'] as String,
                organizationId: orgId,
                parentId: json['parentId'] as String?,
                type: json['type'] as String,
                name: json['name'] as String,
                activePolicyId: json['activePolicyId'] as String?,
                activeCalendarId: json['activeCalendarId'] as String?,
                createdBy: json['createdBy'] as String? ?? uid,
                followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
                isArchived: json['isArchived'] as bool? ?? false,
              );
              await _orgRemote.putScope(orgId, scope);
              break;
            default:
              throw UnsupportedError(
                  'Unknown sync operation: ${operation.operation}');
          }
          await _database.acknowledgeOperation(operation);
        } catch (error) {
          final attempts = operation.attemptCount + 1;
          final delay = Duration(minutes: 1 << attempts.clamp(0, 6).toInt());
          await _database.rescheduleUnchangedOperation(
              operation, attempts, DateTime.now().add(delay), error.toString());
        }
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    final lastPlanSync =
        await _database.getLastSyncAt('plans:$uid') ?? DateTime(2000);
    final planDelta = await _attendanceRemote.getPlansDelta(uid, lastPlanSync);
    var planCheckpoint = lastPlanSync;
    if (planDelta.isNotEmpty) {
      await _database.transaction(() async {
        for (final plan in planDelta) {
          if (plan.updatedAt != null &&
              plan.updatedAt!.isAfter(planCheckpoint)) {
            planCheckpoint = plan.updatedAt!;
          }
          final local = await _database.getPlan(plan.id);
          if (local?.pendingSync == true ||
              await _database.getOperation('plan:${plan.id}') != null) {
            continue;
          }
          await _database
              .upsertPlan(PlanningRepository.toRow(plan, pendingSync: false));
        }
        if (planDelta.isNotEmpty) {
          await _database.setLastSyncAt('plans:$uid', planCheckpoint);
        }
      });
    }
    await UserRepository(_database, _userRemote).syncFollows(uid);
    // 1. Recover Following Context if local state is empty (New Device path)
    final profile = await _userRemote.watchProfile(uid).first;
    if (profile?.activeFollowId != null) {
      await CalendarRepository(_database, _userRemote,
              uid: uid, followId: profile!.activeFollowId!)
          .refresh();
      final follow = await _database.getFollow(profile.activeFollowId!);
      final org =
          await _database.getOrganization(follow?.organizationId ?? 'none');

      if (org == null ||
          await _database.getOperation('follow:${profile.activeFollowId!}') ==
              null) {
        // Essential metadata missing, perform hierarchical recovery
        await _orgRepository.syncFollowContext(uid, profile.activeFollowId!,
            userRemote: _userRemote);
      }
    }

    // 2. Sync Attendance Delta
    final lastSync =
        await _database.getLastSyncAt('attendance:$uid') ?? DateTime(2000);
    final delta = await _attendanceRemote.getAttendanceDelta(uid, lastSync);

    if (delta.isNotEmpty) {
      var checkpoint = lastSync;
      await _database.transaction(() async {
        for (final record in delta) {
          if (record.updatedAt != null &&
              record.updatedAt!.isAfter(checkpoint)) {
            checkpoint = record.updatedAt!;
          }
          if (record.organizationId == null || record.scopeId == null) continue;
          final id = attendanceId(
              record.date, record.organizationId!, record.scopeId!);
          final local = await _database.getAttendance(id);
          final pending = await _database.getOperation('attendance:$id');
          if (local?.pendingSync == true || pending != null) continue;
          if (local?.protectedData != null && record.snapshot == null) continue;
          await _database.upsertAttendance(AttendanceTableCompanion.insert(
            id: id,
            organizationId: record.organizationId ?? 'unknown',
            scopeId: record.scopeId ?? 'global',
            attendanceDate: record.date,
            status: record.status.name,
            actualUnits: record.actualUnits,
            expectedUnits: record.expectedUnits,
            policyVersionId: Value(record.policyVersionId),
            calendarVersionId: Value(record.calendarVersionId),
            pendingSync: const Value(false),
            updatedAt: record.updatedAt ?? DateTime.now(),
            protectedData: Value(
                record.snapshot == null && record.revisionId == null
                    ? null
                    : jsonEncode(record.toJson())),
          ));
        }
      });
      await _database.setLastSyncAt('attendance:$uid', checkpoint);
      final contexts = await _database.select(_database.followRows).get();
      for (final follow in contexts) {
        if (!delta.any((r) =>
            r.snapshot == null &&
            r.organizationId == follow.organizationId &&
            r.scopeId == follow.scopeId)) {
          continue;
        }
        final state = await CalendarRepository(_database, _userRemote,
                uid: uid, followId: follow.id)
            .read();
        if (state?.policy == null) continue;
        await LocalFirstAttendanceRepository(_database,
                uid: uid,
                organizationId: follow.organizationId,
                scopeId: follow.scopeId)
            .protectHistory(state!.policy!, state.calendar,
                policyFor: (date) => state.policyAt(date)!,
                calendarFor: state.calendarAt);
      }
    }
  }
}
