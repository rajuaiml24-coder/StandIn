import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../local/standin_database.dart';
import '../remote/firestore_attendance_remote.dart';
import '../remote/firestore_user_remote.dart';
import '../remote/firestore_org_remote.dart';
import '../organization_repository.dart';
import '../attendance_repository.dart';
import '../../domain/attendance.dart';

class SyncEngine {
  SyncEngine(
    this._database, 
    this._attendanceRemote,
    this._userRemote,
    this._orgRemote,
    this._orgRepository,
    {required this.uid, Connectivity? connectivity}
  ) : _connectivity = connectivity ?? Connectivity();

  final StandInDatabase _database;
  final FirestoreAttendanceRemote _attendanceRemote;
  final FirestoreUserRemote _userRemote;
  final FirestoreOrgRemote _orgRemote;
  final OrganizationRepository _orgRepository;
  final String uid;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<void>? _triggerSubscription;

  bool _isSyncing = false;
  bool _pendingTrigger = false;

  void start() { 
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) { 
      if (!results.contains(ConnectivityResult.none)) _onTrigger(); 
    }); 
    
    _triggerSubscription = _database.onEnqueue.listen((_) => _onTrigger());
  }

  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    await _triggerSubscription?.cancel();
  }

  void _onTrigger() async {
    if (_isSyncing) {
      _pendingTrigger = true;
      return;
    }
    
    _isSyncing = true;
    try {
      do {
        _pendingTrigger = false;
        await syncNow();
      } while (_pendingTrigger);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncNow() async {
    final connection = await _connectivity.checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) return;
    
    await _pushLocalChanges();
    await _pullRemoteChanges();
  }

  Future<void> _pushLocalChanges() async {
    for (final operation in await _database.dueSyncOperations(DateTime.now())) {
      try {
        switch (operation.operation) {
          case 'putOrganization':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final org = Organization(
              id: json['id'] as String,
              name: json['name'] as String,
              type: OrganizationType.values.byName(json['type'] as String),
              branch: json['branch'] as String?,
              activePolicyId: json['activePolicyId'] as String?,
              activeCalendarId: json['activeCalendarId'] as String?,
            );
            final createdByUid = json['uid'] as String? ?? uid;
            await _orgRemote.putOrganization(org, createdByUid);
            break;

          case 'putPolicy':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final orgId = json['organizationId'] as String;
            final pJson = json['policy'] as Map<String, dynamic>;
            final policy = AttendancePolicy(
              id: pJson['id'] as String,
              version: pJson['version'] as int,
              effectiveFrom: DateTime.parse(pJson['effectiveFrom'] as String),
              state: PolicyState.values.byName(pJson['state'] as String),
              evaluationPeriod: EvaluationPeriod.values.byName(pJson['evaluationPeriod'] as String),
              minimumPercent: (pJson['minimumPercent'] as num?)?.toDouble(),
              basis: CalculationBasis.values.byName(pJson['basis'] as String),
              fullUnit: (pJson['fullUnit'] as num).toDouble(),
              halfUnit: (pJson['halfUnit'] as num).toDouble(),
              weeklyOffs: (pJson['weeklyOffs'] as List).cast<int>(),
              startDate: pJson['startDate'] != null ? DateTime.parse(pJson['startDate'] as String) : null,
              endDate: pJson['endDate'] != null ? DateTime.parse(pJson['endDate'] as String) : null,
            );
            await _orgRemote.putPolicy(orgId, policy);
            break;

          case 'putCalendar':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final orgId = json['organizationId'] as String;
            final cJson = json['calendar'] as Map<String, dynamic>;
            final calendar = AttendanceCalendar(
              id: cJson['id'] as String,
              version: cJson['version'] as int,
              effectiveFrom: DateTime.parse(cJson['effectiveFrom'] as String),
              weeklyOffs: (cJson['weeklyOffs'] as List).cast<int>(),
              offSaturdays: (cJson['offSaturdays'] as List).cast<int>(),
              holidays: (cJson['holidays'] as List).map((h) => Holiday.fromJson(h as Map<String, dynamic>)).toList(),
              isConfigured: cJson['isConfigured'] as bool? ?? false,
            );
            await _orgRemote.putCalendar(orgId, calendar);
            break;
            
          case 'upsertAttendance':
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
            await _attendanceRemote.putAttendance(uid, operation.entityId, record);
            break;

          case 'createUserProfile':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final profile = UserProfile(
              uid: json['uid'] as String,
              displayName: json['displayName'] as String,
              role: AppRole.values.byName(json['role'] as String),
              mobile: json['mobile'] as String?,
              activeFollowId: json['activeFollowId'] as String?,
            );
            await _userRemote.createUserProfile(profile);
            break;

          case 'putFollow':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final follow = Follow(
              id: json['id'] as String,
              organizationId: json['organizationId'] as String,
              scopeId: json['scopeId'] as String,
              personalTargetPercent: (json['personalTargetPercent'] as num?)?.toDouble(),
              status: json['status'] as String,
              followedAt: DateTime.parse(json['followedAt'] as String),
              personalBasis: json['personalBasis'] != null ? CalculationBasis.values.byName(json['personalBasis'] as String) : null,
              personalEvaluationPeriod: json['personalEvaluationPeriod'] != null ? EvaluationPeriod.values.byName(json['personalEvaluationPeriod'] as String) : null,
              personalFullUnit: (json['personalFullUnit'] as num?)?.toDouble(),
              personalHalfUnit: (json['personalHalfUnit'] as num?)?.toDouble(),
              personalStartDate: json['personalStartDate'] != null ? DateTime.parse(json['personalStartDate'] as String) : null,
              personalEndDate: json['personalEndDate'] != null ? DateTime.parse(json['personalEndDate'] as String) : null,
              personalWeeklyOffs: json['personalWeeklyOffs'] as String?,
              personalOffSaturdays: json['personalOffSaturdays'] as String?,
              personalHolidays: json['personalHolidays'] as String?,
              isPersonalCalendarConfigured: json['isPersonalCalendarConfigured'] as bool? ?? false,
            );
            await _userRemote.putFollow(uid, follow);
            break;

          case 'putMembership':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final membership = Membership(
              uid: json['uid'] as String,
              organizationId: json['organizationId'] as String,
              status: json['status'] as String,
              idNumber: json['idNumber'] as String?,
              joinedAt: DateTime.parse(json['joinedAt'] as String),
              verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
            );
            await _orgRemote.putMembership(membership);
            break;

          case 'putScope':
            final json = jsonDecode(operation.payload) as Map<String, dynamic>;
            final orgId = json['organizationId'] as String;
            final scope = Scope(
              id: json['id'] as String,
              organizationId: orgId,
              parentId: json['parentId'] as String?,
              type: json['type'] as String,
              name: json['name'] as String,
              activePolicyId: json['activePolicyId'] as String?,
              activeCalendarId: json['activeCalendarId'] as String?,
            );
            await _orgRemote.putScope(orgId, scope);
            break;
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
    // 1. Recover Following Context if local state is empty (New Device path)
    final profile = await _userRemote.watchProfile(uid).first;
    if (profile?.activeFollowId != null) {
      final follow = await _database.getFollow(profile!.activeFollowId!);
      final org = await _database.getOrganization(follow?.organizationId ?? 'none');
      
      if (org == null) {
        // Essential metadata missing, perform hierarchical recovery
        await _orgRepository.syncFollowContext(uid, profile.activeFollowId!, userRemote: _userRemote);
      }
    }

    // 2. Sync Attendance Delta
    final lastSync = await _database.getLastSyncAt('attendance:$uid') ?? DateTime(2000);
    final delta = await _attendanceRemote.getAttendanceDelta(uid, lastSync);
    
    if (delta.isNotEmpty) {
      await _database.transaction(() async {
        for (final record in delta) {
          final id = attendanceId(record.date, record.organizationId ?? 'unknown', record.scopeId ?? 'global');
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
            updatedAt: DateTime.now(),
          ));
        }
      });
      await _database.setLastSyncAt('attendance:$uid', DateTime.now());
    }
  }
}
