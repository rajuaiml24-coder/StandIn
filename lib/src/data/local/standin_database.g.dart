// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standin_database.dart';

// ignore_for_file: type=lint
class $AttendanceTableTable extends AttendanceTable
    with TableInfo<$AttendanceTableTable, AttendanceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orgIdMeta = const VerificationMeta('orgId');
  @override
  late final GeneratedColumn<String> orgId = GeneratedColumn<String>(
      'org_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contextIdMeta =
      const VerificationMeta('contextId');
  @override
  late final GeneratedColumn<String> contextId = GeneratedColumn<String>(
      'context_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attendanceDateMeta =
      const VerificationMeta('attendanceDate');
  @override
  late final GeneratedColumn<DateTime> attendanceDate =
      GeneratedColumn<DateTime>('attendance_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actualUnitsMeta =
      const VerificationMeta('actualUnits');
  @override
  late final GeneratedColumn<double> actualUnits = GeneratedColumn<double>(
      'actual_units', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _expectedUnitsMeta =
      const VerificationMeta('expectedUnits');
  @override
  late final GeneratedColumn<double> expectedUnits = GeneratedColumn<double>(
      'expected_units', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _policyVersionIdMeta =
      const VerificationMeta('policyVersionId');
  @override
  late final GeneratedColumn<String> policyVersionId = GeneratedColumn<String>(
      'policy_version_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _calendarVersionIdMeta =
      const VerificationMeta('calendarVersionId');
  @override
  late final GeneratedColumn<String> calendarVersionId =
      GeneratedColumn<String>('calendar_version_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orgId,
        contextId,
        attendanceDate,
        status,
        actualUnits,
        expectedUnits,
        policyVersionId,
        calendarVersionId,
        pendingSync,
        syncError,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttendanceTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('org_id')) {
      context.handle(
          _orgIdMeta, orgId.isAcceptableOrUnknown(data['org_id']!, _orgIdMeta));
    } else if (isInserting) {
      context.missing(_orgIdMeta);
    }
    if (data.containsKey('context_id')) {
      context.handle(_contextIdMeta,
          contextId.isAcceptableOrUnknown(data['context_id']!, _contextIdMeta));
    } else if (isInserting) {
      context.missing(_contextIdMeta);
    }
    if (data.containsKey('attendance_date')) {
      context.handle(
          _attendanceDateMeta,
          attendanceDate.isAcceptableOrUnknown(
              data['attendance_date']!, _attendanceDateMeta));
    } else if (isInserting) {
      context.missing(_attendanceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('actual_units')) {
      context.handle(
          _actualUnitsMeta,
          actualUnits.isAcceptableOrUnknown(
              data['actual_units']!, _actualUnitsMeta));
    } else if (isInserting) {
      context.missing(_actualUnitsMeta);
    }
    if (data.containsKey('expected_units')) {
      context.handle(
          _expectedUnitsMeta,
          expectedUnits.isAcceptableOrUnknown(
              data['expected_units']!, _expectedUnitsMeta));
    } else if (isInserting) {
      context.missing(_expectedUnitsMeta);
    }
    if (data.containsKey('policy_version_id')) {
      context.handle(
          _policyVersionIdMeta,
          policyVersionId.isAcceptableOrUnknown(
              data['policy_version_id']!, _policyVersionIdMeta));
    }
    if (data.containsKey('calendar_version_id')) {
      context.handle(
          _calendarVersionIdMeta,
          calendarVersionId.isAcceptableOrUnknown(
              data['calendar_version_id']!, _calendarVersionIdMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_id'])!,
      contextId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}context_id'])!,
      attendanceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}attendance_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      actualUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_units'])!,
      expectedUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_units'])!,
      policyVersionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}policy_version_id']),
      calendarVersionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calendar_version_id']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AttendanceTableTable createAlias(String alias) {
    return $AttendanceTableTable(attachedDatabase, alias);
  }
}

class AttendanceTableData extends DataClass
    implements Insertable<AttendanceTableData> {
  final String id;
  final String orgId;
  final String contextId;
  final DateTime attendanceDate;
  final String status;
  final double actualUnits;
  final double expectedUnits;
  final String? policyVersionId;
  final String? calendarVersionId;
  final bool pendingSync;
  final String? syncError;
  final DateTime updatedAt;
  const AttendanceTableData(
      {required this.id,
      required this.orgId,
      required this.contextId,
      required this.attendanceDate,
      required this.status,
      required this.actualUnits,
      required this.expectedUnits,
      this.policyVersionId,
      this.calendarVersionId,
      required this.pendingSync,
      this.syncError,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['org_id'] = Variable<String>(orgId);
    map['context_id'] = Variable<String>(contextId);
    map['attendance_date'] = Variable<DateTime>(attendanceDate);
    map['status'] = Variable<String>(status);
    map['actual_units'] = Variable<double>(actualUnits);
    map['expected_units'] = Variable<double>(expectedUnits);
    if (!nullToAbsent || policyVersionId != null) {
      map['policy_version_id'] = Variable<String>(policyVersionId);
    }
    if (!nullToAbsent || calendarVersionId != null) {
      map['calendar_version_id'] = Variable<String>(calendarVersionId);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AttendanceTableCompanion toCompanion(bool nullToAbsent) {
    return AttendanceTableCompanion(
      id: Value(id),
      orgId: Value(orgId),
      contextId: Value(contextId),
      attendanceDate: Value(attendanceDate),
      status: Value(status),
      actualUnits: Value(actualUnits),
      expectedUnits: Value(expectedUnits),
      policyVersionId: policyVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(policyVersionId),
      calendarVersionId: calendarVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarVersionId),
      pendingSync: Value(pendingSync),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttendanceTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceTableData(
      id: serializer.fromJson<String>(json['id']),
      orgId: serializer.fromJson<String>(json['orgId']),
      contextId: serializer.fromJson<String>(json['contextId']),
      attendanceDate: serializer.fromJson<DateTime>(json['attendanceDate']),
      status: serializer.fromJson<String>(json['status']),
      actualUnits: serializer.fromJson<double>(json['actualUnits']),
      expectedUnits: serializer.fromJson<double>(json['expectedUnits']),
      policyVersionId: serializer.fromJson<String?>(json['policyVersionId']),
      calendarVersionId:
          serializer.fromJson<String?>(json['calendarVersionId']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orgId': serializer.toJson<String>(orgId),
      'contextId': serializer.toJson<String>(contextId),
      'attendanceDate': serializer.toJson<DateTime>(attendanceDate),
      'status': serializer.toJson<String>(status),
      'actualUnits': serializer.toJson<double>(actualUnits),
      'expectedUnits': serializer.toJson<double>(expectedUnits),
      'policyVersionId': serializer.toJson<String?>(policyVersionId),
      'calendarVersionId': serializer.toJson<String?>(calendarVersionId),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttendanceTableData copyWith(
          {String? id,
          String? orgId,
          String? contextId,
          DateTime? attendanceDate,
          String? status,
          double? actualUnits,
          double? expectedUnits,
          Value<String?> policyVersionId = const Value.absent(),
          Value<String?> calendarVersionId = const Value.absent(),
          bool? pendingSync,
          Value<String?> syncError = const Value.absent(),
          DateTime? updatedAt}) =>
      AttendanceTableData(
        id: id ?? this.id,
        orgId: orgId ?? this.orgId,
        contextId: contextId ?? this.contextId,
        attendanceDate: attendanceDate ?? this.attendanceDate,
        status: status ?? this.status,
        actualUnits: actualUnits ?? this.actualUnits,
        expectedUnits: expectedUnits ?? this.expectedUnits,
        policyVersionId: policyVersionId.present
            ? policyVersionId.value
            : this.policyVersionId,
        calendarVersionId: calendarVersionId.present
            ? calendarVersionId.value
            : this.calendarVersionId,
        pendingSync: pendingSync ?? this.pendingSync,
        syncError: syncError.present ? syncError.value : this.syncError,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AttendanceTableData copyWithCompanion(AttendanceTableCompanion data) {
    return AttendanceTableData(
      id: data.id.present ? data.id.value : this.id,
      orgId: data.orgId.present ? data.orgId.value : this.orgId,
      contextId: data.contextId.present ? data.contextId.value : this.contextId,
      attendanceDate: data.attendanceDate.present
          ? data.attendanceDate.value
          : this.attendanceDate,
      status: data.status.present ? data.status.value : this.status,
      actualUnits:
          data.actualUnits.present ? data.actualUnits.value : this.actualUnits,
      expectedUnits: data.expectedUnits.present
          ? data.expectedUnits.value
          : this.expectedUnits,
      policyVersionId: data.policyVersionId.present
          ? data.policyVersionId.value
          : this.policyVersionId,
      calendarVersionId: data.calendarVersionId.present
          ? data.calendarVersionId.value
          : this.calendarVersionId,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceTableData(')
          ..write('id: $id, ')
          ..write('orgId: $orgId, ')
          ..write('contextId: $contextId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('status: $status, ')
          ..write('actualUnits: $actualUnits, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('policyVersionId: $policyVersionId, ')
          ..write('calendarVersionId: $calendarVersionId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orgId,
      contextId,
      attendanceDate,
      status,
      actualUnits,
      expectedUnits,
      policyVersionId,
      calendarVersionId,
      pendingSync,
      syncError,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceTableData &&
          other.id == this.id &&
          other.orgId == this.orgId &&
          other.contextId == this.contextId &&
          other.attendanceDate == this.attendanceDate &&
          other.status == this.status &&
          other.actualUnits == this.actualUnits &&
          other.expectedUnits == this.expectedUnits &&
          other.policyVersionId == this.policyVersionId &&
          other.calendarVersionId == this.calendarVersionId &&
          other.pendingSync == this.pendingSync &&
          other.syncError == this.syncError &&
          other.updatedAt == this.updatedAt);
}

class AttendanceTableCompanion extends UpdateCompanion<AttendanceTableData> {
  final Value<String> id;
  final Value<String> orgId;
  final Value<String> contextId;
  final Value<DateTime> attendanceDate;
  final Value<String> status;
  final Value<double> actualUnits;
  final Value<double> expectedUnits;
  final Value<String?> policyVersionId;
  final Value<String?> calendarVersionId;
  final Value<bool> pendingSync;
  final Value<String?> syncError;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AttendanceTableCompanion({
    this.id = const Value.absent(),
    this.orgId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.attendanceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.actualUnits = const Value.absent(),
    this.expectedUnits = const Value.absent(),
    this.policyVersionId = const Value.absent(),
    this.calendarVersionId = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceTableCompanion.insert({
    required String id,
    required String orgId,
    required String contextId,
    required DateTime attendanceDate,
    required String status,
    required double actualUnits,
    required double expectedUnits,
    this.policyVersionId = const Value.absent(),
    this.calendarVersionId = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orgId = Value(orgId),
        contextId = Value(contextId),
        attendanceDate = Value(attendanceDate),
        status = Value(status),
        actualUnits = Value(actualUnits),
        expectedUnits = Value(expectedUnits),
        updatedAt = Value(updatedAt);
  static Insertable<AttendanceTableData> custom({
    Expression<String>? id,
    Expression<String>? orgId,
    Expression<String>? contextId,
    Expression<DateTime>? attendanceDate,
    Expression<String>? status,
    Expression<double>? actualUnits,
    Expression<double>? expectedUnits,
    Expression<String>? policyVersionId,
    Expression<String>? calendarVersionId,
    Expression<bool>? pendingSync,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orgId != null) 'org_id': orgId,
      if (contextId != null) 'context_id': contextId,
      if (attendanceDate != null) 'attendance_date': attendanceDate,
      if (status != null) 'status': status,
      if (actualUnits != null) 'actual_units': actualUnits,
      if (expectedUnits != null) 'expected_units': expectedUnits,
      if (policyVersionId != null) 'policy_version_id': policyVersionId,
      if (calendarVersionId != null) 'calendar_version_id': calendarVersionId,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? orgId,
      Value<String>? contextId,
      Value<DateTime>? attendanceDate,
      Value<String>? status,
      Value<double>? actualUnits,
      Value<double>? expectedUnits,
      Value<String?>? policyVersionId,
      Value<String?>? calendarVersionId,
      Value<bool>? pendingSync,
      Value<String?>? syncError,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AttendanceTableCompanion(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      contextId: contextId ?? this.contextId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      actualUnits: actualUnits ?? this.actualUnits,
      expectedUnits: expectedUnits ?? this.expectedUnits,
      policyVersionId: policyVersionId ?? this.policyVersionId,
      calendarVersionId: calendarVersionId ?? this.calendarVersionId,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orgId.present) {
      map['org_id'] = Variable<String>(orgId.value);
    }
    if (contextId.present) {
      map['context_id'] = Variable<String>(contextId.value);
    }
    if (attendanceDate.present) {
      map['attendance_date'] = Variable<DateTime>(attendanceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (actualUnits.present) {
      map['actual_units'] = Variable<double>(actualUnits.value);
    }
    if (expectedUnits.present) {
      map['expected_units'] = Variable<double>(expectedUnits.value);
    }
    if (policyVersionId.present) {
      map['policy_version_id'] = Variable<String>(policyVersionId.value);
    }
    if (calendarVersionId.present) {
      map['calendar_version_id'] = Variable<String>(calendarVersionId.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceTableCompanion(')
          ..write('id: $id, ')
          ..write('orgId: $orgId, ')
          ..write('contextId: $contextId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('status: $status, ')
          ..write('actualUnits: $actualUnits, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('policyVersionId: $policyVersionId, ')
          ..write('calendarVersionId: $calendarVersionId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizationRowsTable extends OrganizationRows
    with TableInfo<$OrganizationRowsTable, OrganizationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizationRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
      'is_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isHolidayCalendarConfiguredMeta =
      const VerificationMeta('isHolidayCalendarConfigured');
  @override
  late final GeneratedColumn<bool> isHolidayCalendarConfigured =
      GeneratedColumn<bool>(
          'is_holiday_calendar_configured', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("is_holiday_calendar_configured" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _activePolicyIdMeta =
      const VerificationMeta('activePolicyId');
  @override
  late final GeneratedColumn<String> activePolicyId = GeneratedColumn<String>(
      'active_policy_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeCalendarIdMeta =
      const VerificationMeta('activeCalendarId');
  @override
  late final GeneratedColumn<String> activeCalendarId = GeneratedColumn<String>(
      'active_calendar_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        isVerified,
        isHolidayCalendarConfigured,
        activePolicyId,
        activeCalendarId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organization_rows';
  @override
  VerificationContext validateIntegrity(Insertable<OrganizationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    if (data.containsKey('is_holiday_calendar_configured')) {
      context.handle(
          _isHolidayCalendarConfiguredMeta,
          isHolidayCalendarConfigured.isAcceptableOrUnknown(
              data['is_holiday_calendar_configured']!,
              _isHolidayCalendarConfiguredMeta));
    }
    if (data.containsKey('active_policy_id')) {
      context.handle(
          _activePolicyIdMeta,
          activePolicyId.isAcceptableOrUnknown(
              data['active_policy_id']!, _activePolicyIdMeta));
    }
    if (data.containsKey('active_calendar_id')) {
      context.handle(
          _activeCalendarIdMeta,
          activeCalendarId.isAcceptableOrUnknown(
              data['active_calendar_id']!, _activeCalendarIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrganizationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizationRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_verified'])!,
      isHolidayCalendarConfigured: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}is_holiday_calendar_configured'])!,
      activePolicyId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_policy_id']),
      activeCalendarId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_calendar_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OrganizationRowsTable createAlias(String alias) {
    return $OrganizationRowsTable(attachedDatabase, alias);
  }
}

class OrganizationRow extends DataClass implements Insertable<OrganizationRow> {
  final String id;
  final String name;
  final String type;
  final bool isVerified;
  final bool isHolidayCalendarConfigured;
  final String? activePolicyId;
  final String? activeCalendarId;
  final DateTime updatedAt;
  const OrganizationRow(
      {required this.id,
      required this.name,
      required this.type,
      required this.isVerified,
      required this.isHolidayCalendarConfigured,
      this.activePolicyId,
      this.activeCalendarId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['is_verified'] = Variable<bool>(isVerified);
    map['is_holiday_calendar_configured'] =
        Variable<bool>(isHolidayCalendarConfigured);
    if (!nullToAbsent || activePolicyId != null) {
      map['active_policy_id'] = Variable<String>(activePolicyId);
    }
    if (!nullToAbsent || activeCalendarId != null) {
      map['active_calendar_id'] = Variable<String>(activeCalendarId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrganizationRowsCompanion toCompanion(bool nullToAbsent) {
    return OrganizationRowsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      isVerified: Value(isVerified),
      isHolidayCalendarConfigured: Value(isHolidayCalendarConfigured),
      activePolicyId: activePolicyId == null && nullToAbsent
          ? const Value.absent()
          : Value(activePolicyId),
      activeCalendarId: activeCalendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeCalendarId),
      updatedAt: Value(updatedAt),
    );
  }

  factory OrganizationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizationRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      isHolidayCalendarConfigured:
          serializer.fromJson<bool>(json['isHolidayCalendarConfigured']),
      activePolicyId: serializer.fromJson<String?>(json['activePolicyId']),
      activeCalendarId: serializer.fromJson<String?>(json['activeCalendarId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'isVerified': serializer.toJson<bool>(isVerified),
      'isHolidayCalendarConfigured':
          serializer.toJson<bool>(isHolidayCalendarConfigured),
      'activePolicyId': serializer.toJson<String?>(activePolicyId),
      'activeCalendarId': serializer.toJson<String?>(activeCalendarId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OrganizationRow copyWith(
          {String? id,
          String? name,
          String? type,
          bool? isVerified,
          bool? isHolidayCalendarConfigured,
          Value<String?> activePolicyId = const Value.absent(),
          Value<String?> activeCalendarId = const Value.absent(),
          DateTime? updatedAt}) =>
      OrganizationRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        isVerified: isVerified ?? this.isVerified,
        isHolidayCalendarConfigured:
            isHolidayCalendarConfigured ?? this.isHolidayCalendarConfigured,
        activePolicyId:
            activePolicyId.present ? activePolicyId.value : this.activePolicyId,
        activeCalendarId: activeCalendarId.present
            ? activeCalendarId.value
            : this.activeCalendarId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OrganizationRow copyWithCompanion(OrganizationRowsCompanion data) {
    return OrganizationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      isVerified:
          data.isVerified.present ? data.isVerified.value : this.isVerified,
      isHolidayCalendarConfigured: data.isHolidayCalendarConfigured.present
          ? data.isHolidayCalendarConfigured.value
          : this.isHolidayCalendarConfigured,
      activePolicyId: data.activePolicyId.present
          ? data.activePolicyId.value
          : this.activePolicyId,
      activeCalendarId: data.activeCalendarId.present
          ? data.activeCalendarId.value
          : this.activeCalendarId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isVerified: $isVerified, ')
          ..write('isHolidayCalendarConfigured: $isHolidayCalendarConfigured, ')
          ..write('activePolicyId: $activePolicyId, ')
          ..write('activeCalendarId: $activeCalendarId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, isVerified,
      isHolidayCalendarConfigured, activePolicyId, activeCalendarId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.isVerified == this.isVerified &&
          other.isHolidayCalendarConfigured ==
              this.isHolidayCalendarConfigured &&
          other.activePolicyId == this.activePolicyId &&
          other.activeCalendarId == this.activeCalendarId &&
          other.updatedAt == this.updatedAt);
}

class OrganizationRowsCompanion extends UpdateCompanion<OrganizationRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> isVerified;
  final Value<bool> isHolidayCalendarConfigured;
  final Value<String?> activePolicyId;
  final Value<String?> activeCalendarId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrganizationRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.isHolidayCalendarConfigured = const Value.absent(),
    this.activePolicyId = const Value.absent(),
    this.activeCalendarId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizationRowsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.isVerified = const Value.absent(),
    this.isHolidayCalendarConfigured = const Value.absent(),
    this.activePolicyId = const Value.absent(),
    this.activeCalendarId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        updatedAt = Value(updatedAt);
  static Insertable<OrganizationRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? isVerified,
    Expression<bool>? isHolidayCalendarConfigured,
    Expression<String>? activePolicyId,
    Expression<String>? activeCalendarId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (isVerified != null) 'is_verified': isVerified,
      if (isHolidayCalendarConfigured != null)
        'is_holiday_calendar_configured': isHolidayCalendarConfigured,
      if (activePolicyId != null) 'active_policy_id': activePolicyId,
      if (activeCalendarId != null) 'active_calendar_id': activeCalendarId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizationRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<bool>? isVerified,
      Value<bool>? isHolidayCalendarConfigured,
      Value<String?>? activePolicyId,
      Value<String?>? activeCalendarId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return OrganizationRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isVerified: isVerified ?? this.isVerified,
      isHolidayCalendarConfigured:
          isHolidayCalendarConfigured ?? this.isHolidayCalendarConfigured,
      activePolicyId: activePolicyId ?? this.activePolicyId,
      activeCalendarId: activeCalendarId ?? this.activeCalendarId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (isHolidayCalendarConfigured.present) {
      map['is_holiday_calendar_configured'] =
          Variable<bool>(isHolidayCalendarConfigured.value);
    }
    if (activePolicyId.present) {
      map['active_policy_id'] = Variable<String>(activePolicyId.value);
    }
    if (activeCalendarId.present) {
      map['active_calendar_id'] = Variable<String>(activeCalendarId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isVerified: $isVerified, ')
          ..write('isHolidayCalendarConfigured: $isHolidayCalendarConfigured, ')
          ..write('activePolicyId: $activePolicyId, ')
          ..write('activeCalendarId: $activeCalendarId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScopeRowsTable extends ScopeRows
    with TableInfo<$ScopeRowsTable, ScopeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScopeRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activePolicyIdMeta =
      const VerificationMeta('activePolicyId');
  @override
  late final GeneratedColumn<String> activePolicyId = GeneratedColumn<String>(
      'active_policy_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeCalendarIdMeta =
      const VerificationMeta('activeCalendarId');
  @override
  late final GeneratedColumn<String> activeCalendarId = GeneratedColumn<String>(
      'active_calendar_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        organizationId,
        parentId,
        type,
        name,
        activePolicyId,
        activeCalendarId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scope_rows';
  @override
  VerificationContext validateIntegrity(Insertable<ScopeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active_policy_id')) {
      context.handle(
          _activePolicyIdMeta,
          activePolicyId.isAcceptableOrUnknown(
              data['active_policy_id']!, _activePolicyIdMeta));
    }
    if (data.containsKey('active_calendar_id')) {
      context.handle(
          _activeCalendarIdMeta,
          activeCalendarId.isAcceptableOrUnknown(
              data['active_calendar_id']!, _activeCalendarIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScopeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScopeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      activePolicyId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_policy_id']),
      activeCalendarId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_calendar_id']),
    );
  }

  @override
  $ScopeRowsTable createAlias(String alias) {
    return $ScopeRowsTable(attachedDatabase, alias);
  }
}

class ScopeRow extends DataClass implements Insertable<ScopeRow> {
  final String id;
  final String organizationId;
  final String? parentId;
  final String type;
  final String name;
  final String? activePolicyId;
  final String? activeCalendarId;
  const ScopeRow(
      {required this.id,
      required this.organizationId,
      this.parentId,
      required this.type,
      required this.name,
      this.activePolicyId,
      this.activeCalendarId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || activePolicyId != null) {
      map['active_policy_id'] = Variable<String>(activePolicyId);
    }
    if (!nullToAbsent || activeCalendarId != null) {
      map['active_calendar_id'] = Variable<String>(activeCalendarId);
    }
    return map;
  }

  ScopeRowsCompanion toCompanion(bool nullToAbsent) {
    return ScopeRowsCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      type: Value(type),
      name: Value(name),
      activePolicyId: activePolicyId == null && nullToAbsent
          ? const Value.absent()
          : Value(activePolicyId),
      activeCalendarId: activeCalendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeCalendarId),
    );
  }

  factory ScopeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScopeRow(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      activePolicyId: serializer.fromJson<String?>(json['activePolicyId']),
      activeCalendarId: serializer.fromJson<String?>(json['activeCalendarId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'parentId': serializer.toJson<String?>(parentId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'activePolicyId': serializer.toJson<String?>(activePolicyId),
      'activeCalendarId': serializer.toJson<String?>(activeCalendarId),
    };
  }

  ScopeRow copyWith(
          {String? id,
          String? organizationId,
          Value<String?> parentId = const Value.absent(),
          String? type,
          String? name,
          Value<String?> activePolicyId = const Value.absent(),
          Value<String?> activeCalendarId = const Value.absent()}) =>
      ScopeRow(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        parentId: parentId.present ? parentId.value : this.parentId,
        type: type ?? this.type,
        name: name ?? this.name,
        activePolicyId:
            activePolicyId.present ? activePolicyId.value : this.activePolicyId,
        activeCalendarId: activeCalendarId.present
            ? activeCalendarId.value
            : this.activeCalendarId,
      );
  ScopeRow copyWithCompanion(ScopeRowsCompanion data) {
    return ScopeRow(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      activePolicyId: data.activePolicyId.present
          ? data.activePolicyId.value
          : this.activePolicyId,
      activeCalendarId: data.activeCalendarId.present
          ? data.activeCalendarId.value
          : this.activeCalendarId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScopeRow(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('activePolicyId: $activePolicyId, ')
          ..write('activeCalendarId: $activeCalendarId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organizationId, parentId, type, name,
      activePolicyId, activeCalendarId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScopeRow &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.parentId == this.parentId &&
          other.type == this.type &&
          other.name == this.name &&
          other.activePolicyId == this.activePolicyId &&
          other.activeCalendarId == this.activeCalendarId);
}

class ScopeRowsCompanion extends UpdateCompanion<ScopeRow> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String?> parentId;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> activePolicyId;
  final Value<String?> activeCalendarId;
  final Value<int> rowid;
  const ScopeRowsCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.activePolicyId = const Value.absent(),
    this.activeCalendarId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScopeRowsCompanion.insert({
    required String id,
    required String organizationId,
    this.parentId = const Value.absent(),
    required String type,
    required String name,
    this.activePolicyId = const Value.absent(),
    this.activeCalendarId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        type = Value(type),
        name = Value(name);
  static Insertable<ScopeRow> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? parentId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? activePolicyId,
    Expression<String>? activeCalendarId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (parentId != null) 'parent_id': parentId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (activePolicyId != null) 'active_policy_id': activePolicyId,
      if (activeCalendarId != null) 'active_calendar_id': activeCalendarId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScopeRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String?>? parentId,
      Value<String>? type,
      Value<String>? name,
      Value<String?>? activePolicyId,
      Value<String?>? activeCalendarId,
      Value<int>? rowid}) {
    return ScopeRowsCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      name: name ?? this.name,
      activePolicyId: activePolicyId ?? this.activePolicyId,
      activeCalendarId: activeCalendarId ?? this.activeCalendarId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (activePolicyId.present) {
      map['active_policy_id'] = Variable<String>(activePolicyId.value);
    }
    if (activeCalendarId.present) {
      map['active_calendar_id'] = Variable<String>(activeCalendarId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScopeRowsCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('activePolicyId: $activePolicyId, ')
          ..write('activeCalendarId: $activeCalendarId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FollowRowsTable extends FollowRows
    with TableInfo<$FollowRowsTable, FollowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personalTargetPercentMeta =
      const VerificationMeta('personalTargetPercent');
  @override
  late final GeneratedColumn<double> personalTargetPercent =
      GeneratedColumn<double>('personal_target_percent', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _followedAtMeta =
      const VerificationMeta('followedAt');
  @override
  late final GeneratedColumn<DateTime> followedAt = GeneratedColumn<DateTime>(
      'followed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, organizationId, scopeId, personalTargetPercent, status, followedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_rows';
  @override
  VerificationContext validateIntegrity(Insertable<FollowRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('personal_target_percent')) {
      context.handle(
          _personalTargetPercentMeta,
          personalTargetPercent.isAcceptableOrUnknown(
              data['personal_target_percent']!, _personalTargetPercentMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('followed_at')) {
      context.handle(
          _followedAtMeta,
          followedAt.isAcceptableOrUnknown(
              data['followed_at']!, _followedAtMeta));
    } else if (isInserting) {
      context.missing(_followedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FollowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      personalTargetPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}personal_target_percent']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      followedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}followed_at'])!,
    );
  }

  @override
  $FollowRowsTable createAlias(String alias) {
    return $FollowRowsTable(attachedDatabase, alias);
  }
}

class FollowRow extends DataClass implements Insertable<FollowRow> {
  final String id;
  final String organizationId;
  final String scopeId;
  final double? personalTargetPercent;
  final String status;
  final DateTime followedAt;
  const FollowRow(
      {required this.id,
      required this.organizationId,
      required this.scopeId,
      this.personalTargetPercent,
      required this.status,
      required this.followedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['scope_id'] = Variable<String>(scopeId);
    if (!nullToAbsent || personalTargetPercent != null) {
      map['personal_target_percent'] = Variable<double>(personalTargetPercent);
    }
    map['status'] = Variable<String>(status);
    map['followed_at'] = Variable<DateTime>(followedAt);
    return map;
  }

  FollowRowsCompanion toCompanion(bool nullToAbsent) {
    return FollowRowsCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      scopeId: Value(scopeId),
      personalTargetPercent: personalTargetPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(personalTargetPercent),
      status: Value(status),
      followedAt: Value(followedAt),
    );
  }

  factory FollowRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowRow(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      personalTargetPercent:
          serializer.fromJson<double?>(json['personalTargetPercent']),
      status: serializer.fromJson<String>(json['status']),
      followedAt: serializer.fromJson<DateTime>(json['followedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'scopeId': serializer.toJson<String>(scopeId),
      'personalTargetPercent':
          serializer.toJson<double?>(personalTargetPercent),
      'status': serializer.toJson<String>(status),
      'followedAt': serializer.toJson<DateTime>(followedAt),
    };
  }

  FollowRow copyWith(
          {String? id,
          String? organizationId,
          String? scopeId,
          Value<double?> personalTargetPercent = const Value.absent(),
          String? status,
          DateTime? followedAt}) =>
      FollowRow(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
        personalTargetPercent: personalTargetPercent.present
            ? personalTargetPercent.value
            : this.personalTargetPercent,
        status: status ?? this.status,
        followedAt: followedAt ?? this.followedAt,
      );
  FollowRow copyWithCompanion(FollowRowsCompanion data) {
    return FollowRow(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      personalTargetPercent: data.personalTargetPercent.present
          ? data.personalTargetPercent.value
          : this.personalTargetPercent,
      status: data.status.present ? data.status.value : this.status,
      followedAt:
          data.followedAt.present ? data.followedAt.value : this.followedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowRow(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('scopeId: $scopeId, ')
          ..write('personalTargetPercent: $personalTargetPercent, ')
          ..write('status: $status, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, organizationId, scopeId, personalTargetPercent, status, followedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowRow &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.scopeId == this.scopeId &&
          other.personalTargetPercent == this.personalTargetPercent &&
          other.status == this.status &&
          other.followedAt == this.followedAt);
}

class FollowRowsCompanion extends UpdateCompanion<FollowRow> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> scopeId;
  final Value<double?> personalTargetPercent;
  final Value<String> status;
  final Value<DateTime> followedAt;
  final Value<int> rowid;
  const FollowRowsCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.personalTargetPercent = const Value.absent(),
    this.status = const Value.absent(),
    this.followedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowRowsCompanion.insert({
    required String id,
    required String organizationId,
    required String scopeId,
    this.personalTargetPercent = const Value.absent(),
    required String status,
    required DateTime followedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        scopeId = Value(scopeId),
        status = Value(status),
        followedAt = Value(followedAt);
  static Insertable<FollowRow> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? scopeId,
    Expression<double>? personalTargetPercent,
    Expression<String>? status,
    Expression<DateTime>? followedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (scopeId != null) 'scope_id': scopeId,
      if (personalTargetPercent != null)
        'personal_target_percent': personalTargetPercent,
      if (status != null) 'status': status,
      if (followedAt != null) 'followed_at': followedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<String>? scopeId,
      Value<double?>? personalTargetPercent,
      Value<String>? status,
      Value<DateTime>? followedAt,
      Value<int>? rowid}) {
    return FollowRowsCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      scopeId: scopeId ?? this.scopeId,
      personalTargetPercent:
          personalTargetPercent ?? this.personalTargetPercent,
      status: status ?? this.status,
      followedAt: followedAt ?? this.followedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (personalTargetPercent.present) {
      map['personal_target_percent'] =
          Variable<double>(personalTargetPercent.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (followedAt.present) {
      map['followed_at'] = Variable<DateTime>(followedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowRowsCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('scopeId: $scopeId, ')
          ..write('personalTargetPercent: $personalTargetPercent, ')
          ..write('status: $status, ')
          ..write('followedAt: $followedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembershipRowsTable extends MembershipRows
    with TableInfo<$MembershipRowsTable, MembershipRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembershipRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idNumberMeta =
      const VerificationMeta('idNumber');
  @override
  late final GeneratedColumn<String> idNumber = GeneratedColumn<String>(
      'id_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
      'joined_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _verifiedAtMeta =
      const VerificationMeta('verifiedAt');
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
      'verified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, organizationId, status, idNumber, joinedAt, verifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'membership_rows';
  @override
  VerificationContext validateIntegrity(Insertable<MembershipRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('id_number')) {
      context.handle(_idNumberMeta,
          idNumber.isAcceptableOrUnknown(data['id_number']!, _idNumberMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('verified_at')) {
      context.handle(
          _verifiedAtMeta,
          verifiedAt.isAcceptableOrUnknown(
              data['verified_at']!, _verifiedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, organizationId};
  @override
  MembershipRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MembershipRow(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      idNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id_number']),
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joined_at'])!,
      verifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}verified_at']),
    );
  }

  @override
  $MembershipRowsTable createAlias(String alias) {
    return $MembershipRowsTable(attachedDatabase, alias);
  }
}

class MembershipRow extends DataClass implements Insertable<MembershipRow> {
  final String uid;
  final String organizationId;
  final String status;
  final String? idNumber;
  final DateTime joinedAt;
  final DateTime? verifiedAt;
  const MembershipRow(
      {required this.uid,
      required this.organizationId,
      required this.status,
      this.idNumber,
      required this.joinedAt,
      this.verifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['organization_id'] = Variable<String>(organizationId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || idNumber != null) {
      map['id_number'] = Variable<String>(idNumber);
    }
    map['joined_at'] = Variable<DateTime>(joinedAt);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    return map;
  }

  MembershipRowsCompanion toCompanion(bool nullToAbsent) {
    return MembershipRowsCompanion(
      uid: Value(uid),
      organizationId: Value(organizationId),
      status: Value(status),
      idNumber: idNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(idNumber),
      joinedAt: Value(joinedAt),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
    );
  }

  factory MembershipRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MembershipRow(
      uid: serializer.fromJson<String>(json['uid']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      status: serializer.fromJson<String>(json['status']),
      idNumber: serializer.fromJson<String?>(json['idNumber']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'organizationId': serializer.toJson<String>(organizationId),
      'status': serializer.toJson<String>(status),
      'idNumber': serializer.toJson<String?>(idNumber),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
    };
  }

  MembershipRow copyWith(
          {String? uid,
          String? organizationId,
          String? status,
          Value<String?> idNumber = const Value.absent(),
          DateTime? joinedAt,
          Value<DateTime?> verifiedAt = const Value.absent()}) =>
      MembershipRow(
        uid: uid ?? this.uid,
        organizationId: organizationId ?? this.organizationId,
        status: status ?? this.status,
        idNumber: idNumber.present ? idNumber.value : this.idNumber,
        joinedAt: joinedAt ?? this.joinedAt,
        verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
      );
  MembershipRow copyWithCompanion(MembershipRowsCompanion data) {
    return MembershipRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      status: data.status.present ? data.status.value : this.status,
      idNumber: data.idNumber.present ? data.idNumber.value : this.idNumber,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      verifiedAt:
          data.verifiedAt.present ? data.verifiedAt.value : this.verifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MembershipRow(')
          ..write('uid: $uid, ')
          ..write('organizationId: $organizationId, ')
          ..write('status: $status, ')
          ..write('idNumber: $idNumber, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, organizationId, status, idNumber, joinedAt, verifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MembershipRow &&
          other.uid == this.uid &&
          other.organizationId == this.organizationId &&
          other.status == this.status &&
          other.idNumber == this.idNumber &&
          other.joinedAt == this.joinedAt &&
          other.verifiedAt == this.verifiedAt);
}

class MembershipRowsCompanion extends UpdateCompanion<MembershipRow> {
  final Value<String> uid;
  final Value<String> organizationId;
  final Value<String> status;
  final Value<String?> idNumber;
  final Value<DateTime> joinedAt;
  final Value<DateTime?> verifiedAt;
  final Value<int> rowid;
  const MembershipRowsCompanion({
    this.uid = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.status = const Value.absent(),
    this.idNumber = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembershipRowsCompanion.insert({
    required String uid,
    required String organizationId,
    required String status,
    this.idNumber = const Value.absent(),
    required DateTime joinedAt,
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        organizationId = Value(organizationId),
        status = Value(status),
        joinedAt = Value(joinedAt);
  static Insertable<MembershipRow> custom({
    Expression<String>? uid,
    Expression<String>? organizationId,
    Expression<String>? status,
    Expression<String>? idNumber,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? verifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (organizationId != null) 'organization_id': organizationId,
      if (status != null) 'status': status,
      if (idNumber != null) 'id_number': idNumber,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembershipRowsCompanion copyWith(
      {Value<String>? uid,
      Value<String>? organizationId,
      Value<String>? status,
      Value<String?>? idNumber,
      Value<DateTime>? joinedAt,
      Value<DateTime?>? verifiedAt,
      Value<int>? rowid}) {
    return MembershipRowsCompanion(
      uid: uid ?? this.uid,
      organizationId: organizationId ?? this.organizationId,
      status: status ?? this.status,
      idNumber: idNumber ?? this.idNumber,
      joinedAt: joinedAt ?? this.joinedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (idNumber.present) {
      map['id_number'] = Variable<String>(idNumber.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembershipRowsCompanion(')
          ..write('uid: $uid, ')
          ..write('organizationId: $organizationId, ')
          ..write('status: $status, ')
          ..write('idNumber: $idNumber, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileRowsTable extends UserProfileRows
    with TableInfo<$UserProfileRowsTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
      'mobile', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeFollowIdMeta =
      const VerificationMeta('activeFollowId');
  @override
  late final GeneratedColumn<String> activeFollowId = GeneratedColumn<String>(
      'active_follow_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, displayName, role, mobile, activeFollowId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile_rows';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(_mobileMeta,
          mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta));
    }
    if (data.containsKey('active_follow_id')) {
      context.handle(
          _activeFollowIdMeta,
          activeFollowId.isAcceptableOrUnknown(
              data['active_follow_id']!, _activeFollowIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      mobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mobile']),
      activeFollowId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_follow_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserProfileRowsTable createAlias(String alias) {
    return $UserProfileRowsTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final String uid;
  final String displayName;
  final String role;
  final String? mobile;
  final String? activeFollowId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileRow(
      {required this.uid,
      required this.displayName,
      required this.role,
      this.mobile,
      this.activeFollowId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || activeFollowId != null) {
      map['active_follow_id'] = Variable<String>(activeFollowId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfileRowsCompanion toCompanion(bool nullToAbsent) {
    return UserProfileRowsCompanion(
      uid: Value(uid),
      displayName: Value(displayName),
      role: Value(role),
      mobile:
          mobile == null && nullToAbsent ? const Value.absent() : Value(mobile),
      activeFollowId: activeFollowId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeFollowId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      uid: serializer.fromJson<String>(json['uid']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      activeFollowId: serializer.fromJson<String?>(json['activeFollowId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'mobile': serializer.toJson<String?>(mobile),
      'activeFollowId': serializer.toJson<String?>(activeFollowId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileRow copyWith(
          {String? uid,
          String? displayName,
          String? role,
          Value<String?> mobile = const Value.absent(),
          Value<String?> activeFollowId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserProfileRow(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        mobile: mobile.present ? mobile.value : this.mobile,
        activeFollowId:
            activeFollowId.present ? activeFollowId.value : this.activeFollowId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserProfileRow copyWithCompanion(UserProfileRowsCompanion data) {
    return UserProfileRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      activeFollowId: data.activeFollowId.present
          ? data.activeFollowId.value
          : this.activeFollowId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('uid: $uid, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('mobile: $mobile, ')
          ..write('activeFollowId: $activeFollowId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, displayName, role, mobile, activeFollowId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.uid == this.uid &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.mobile == this.mobile &&
          other.activeFollowId == this.activeFollowId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfileRowsCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<String> uid;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String?> mobile;
  final Value<String?> activeFollowId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfileRowsCompanion({
    this.uid = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.mobile = const Value.absent(),
    this.activeFollowId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileRowsCompanion.insert({
    required String uid,
    required String displayName,
    required String role,
    this.mobile = const Value.absent(),
    this.activeFollowId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        displayName = Value(displayName),
        role = Value(role),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UserProfileRow> custom({
    Expression<String>? uid,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? mobile,
    Expression<String>? activeFollowId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (mobile != null) 'mobile': mobile,
      if (activeFollowId != null) 'active_follow_id': activeFollowId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileRowsCompanion copyWith(
      {Value<String>? uid,
      Value<String>? displayName,
      Value<String>? role,
      Value<String?>? mobile,
      Value<String?>? activeFollowId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserProfileRowsCompanion(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      mobile: mobile ?? this.mobile,
      activeFollowId: activeFollowId ?? this.activeFollowId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (activeFollowId.present) {
      map['active_follow_id'] = Variable<String>(activeFollowId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRowsCompanion(')
          ..write('uid: $uid, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('mobile: $mobile, ')
          ..write('activeFollowId: $activeFollowId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizationPolicyRowsTable extends OrganizationPolicyRows
    with TableInfo<$OrganizationPolicyRowsTable, OrganizationPolicyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizationPolicyRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _policyIdMeta =
      const VerificationMeta('policyId');
  @override
  late final GeneratedColumn<String> policyId = GeneratedColumn<String>(
      'policy_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _effectiveFromMeta =
      const VerificationMeta('effectiveFrom');
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>('effective_from', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evaluationPeriodMeta =
      const VerificationMeta('evaluationPeriod');
  @override
  late final GeneratedColumn<String> evaluationPeriod = GeneratedColumn<String>(
      'evaluation_period', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minimumPercentMeta =
      const VerificationMeta('minimumPercent');
  @override
  late final GeneratedColumn<double> minimumPercent = GeneratedColumn<double>(
      'minimum_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _calculationBasisMeta =
      const VerificationMeta('calculationBasis');
  @override
  late final GeneratedColumn<String> calculationBasis = GeneratedColumn<String>(
      'calculation_basis', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullUnitMeta =
      const VerificationMeta('fullUnit');
  @override
  late final GeneratedColumn<double> fullUnit = GeneratedColumn<double>(
      'full_unit', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _halfUnitMeta =
      const VerificationMeta('halfUnit');
  @override
  late final GeneratedColumn<double> halfUnit = GeneratedColumn<double>(
      'half_unit', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        policyId,
        organizationId,
        scopeId,
        version,
        effectiveFrom,
        state,
        evaluationPeriod,
        minimumPercent,
        calculationBasis,
        fullUnit,
        halfUnit,
        startDate,
        endDate,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organization_policy_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<OrganizationPolicyRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('policy_id')) {
      context.handle(_policyIdMeta,
          policyId.isAcceptableOrUnknown(data['policy_id']!, _policyIdMeta));
    } else if (isInserting) {
      context.missing(_policyIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
          _effectiveFromMeta,
          effectiveFrom.isAcceptableOrUnknown(
              data['effective_from']!, _effectiveFromMeta));
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('evaluation_period')) {
      context.handle(
          _evaluationPeriodMeta,
          evaluationPeriod.isAcceptableOrUnknown(
              data['evaluation_period']!, _evaluationPeriodMeta));
    } else if (isInserting) {
      context.missing(_evaluationPeriodMeta);
    }
    if (data.containsKey('minimum_percent')) {
      context.handle(
          _minimumPercentMeta,
          minimumPercent.isAcceptableOrUnknown(
              data['minimum_percent']!, _minimumPercentMeta));
    }
    if (data.containsKey('calculation_basis')) {
      context.handle(
          _calculationBasisMeta,
          calculationBasis.isAcceptableOrUnknown(
              data['calculation_basis']!, _calculationBasisMeta));
    } else if (isInserting) {
      context.missing(_calculationBasisMeta);
    }
    if (data.containsKey('full_unit')) {
      context.handle(_fullUnitMeta,
          fullUnit.isAcceptableOrUnknown(data['full_unit']!, _fullUnitMeta));
    } else if (isInserting) {
      context.missing(_fullUnitMeta);
    }
    if (data.containsKey('half_unit')) {
      context.handle(_halfUnitMeta,
          halfUnit.isAcceptableOrUnknown(data['half_unit']!, _halfUnitMeta));
    } else if (isInserting) {
      context.missing(_halfUnitMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {policyId};
  @override
  OrganizationPolicyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizationPolicyRow(
      policyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policy_id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      effectiveFrom: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}effective_from'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      evaluationPeriod: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}evaluation_period'])!,
      minimumPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}minimum_percent']),
      calculationBasis: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calculation_basis'])!,
      fullUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}full_unit'])!,
      halfUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}half_unit'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OrganizationPolicyRowsTable createAlias(String alias) {
    return $OrganizationPolicyRowsTable(attachedDatabase, alias);
  }
}

class OrganizationPolicyRow extends DataClass
    implements Insertable<OrganizationPolicyRow> {
  final String policyId;
  final String organizationId;
  final String scopeId;
  final int version;
  final DateTime effectiveFrom;
  final String state;
  final String evaluationPeriod;
  final double? minimumPercent;
  final String calculationBasis;
  final double fullUnit;
  final double halfUnit;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime updatedAt;
  const OrganizationPolicyRow(
      {required this.policyId,
      required this.organizationId,
      required this.scopeId,
      required this.version,
      required this.effectiveFrom,
      required this.state,
      required this.evaluationPeriod,
      this.minimumPercent,
      required this.calculationBasis,
      required this.fullUnit,
      required this.halfUnit,
      this.startDate,
      this.endDate,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['policy_id'] = Variable<String>(policyId);
    map['organization_id'] = Variable<String>(organizationId);
    map['scope_id'] = Variable<String>(scopeId);
    map['version'] = Variable<int>(version);
    map['effective_from'] = Variable<DateTime>(effectiveFrom);
    map['state'] = Variable<String>(state);
    map['evaluation_period'] = Variable<String>(evaluationPeriod);
    if (!nullToAbsent || minimumPercent != null) {
      map['minimum_percent'] = Variable<double>(minimumPercent);
    }
    map['calculation_basis'] = Variable<String>(calculationBasis);
    map['full_unit'] = Variable<double>(fullUnit);
    map['half_unit'] = Variable<double>(halfUnit);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrganizationPolicyRowsCompanion toCompanion(bool nullToAbsent) {
    return OrganizationPolicyRowsCompanion(
      policyId: Value(policyId),
      organizationId: Value(organizationId),
      scopeId: Value(scopeId),
      version: Value(version),
      effectiveFrom: Value(effectiveFrom),
      state: Value(state),
      evaluationPeriod: Value(evaluationPeriod),
      minimumPercent: minimumPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumPercent),
      calculationBasis: Value(calculationBasis),
      fullUnit: Value(fullUnit),
      halfUnit: Value(halfUnit),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory OrganizationPolicyRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizationPolicyRow(
      policyId: serializer.fromJson<String>(json['policyId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      version: serializer.fromJson<int>(json['version']),
      effectiveFrom: serializer.fromJson<DateTime>(json['effectiveFrom']),
      state: serializer.fromJson<String>(json['state']),
      evaluationPeriod: serializer.fromJson<String>(json['evaluationPeriod']),
      minimumPercent: serializer.fromJson<double?>(json['minimumPercent']),
      calculationBasis: serializer.fromJson<String>(json['calculationBasis']),
      fullUnit: serializer.fromJson<double>(json['fullUnit']),
      halfUnit: serializer.fromJson<double>(json['halfUnit']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'policyId': serializer.toJson<String>(policyId),
      'organizationId': serializer.toJson<String>(organizationId),
      'scopeId': serializer.toJson<String>(scopeId),
      'version': serializer.toJson<int>(version),
      'effectiveFrom': serializer.toJson<DateTime>(effectiveFrom),
      'state': serializer.toJson<String>(state),
      'evaluationPeriod': serializer.toJson<String>(evaluationPeriod),
      'minimumPercent': serializer.toJson<double?>(minimumPercent),
      'calculationBasis': serializer.toJson<String>(calculationBasis),
      'fullUnit': serializer.toJson<double>(fullUnit),
      'halfUnit': serializer.toJson<double>(halfUnit),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OrganizationPolicyRow copyWith(
          {String? policyId,
          String? organizationId,
          String? scopeId,
          int? version,
          DateTime? effectiveFrom,
          String? state,
          String? evaluationPeriod,
          Value<double?> minimumPercent = const Value.absent(),
          String? calculationBasis,
          double? fullUnit,
          double? halfUnit,
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          DateTime? updatedAt}) =>
      OrganizationPolicyRow(
        policyId: policyId ?? this.policyId,
        organizationId: organizationId ?? this.organizationId,
        scopeId: scopeId ?? this.scopeId,
        version: version ?? this.version,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        state: state ?? this.state,
        evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
        minimumPercent:
            minimumPercent.present ? minimumPercent.value : this.minimumPercent,
        calculationBasis: calculationBasis ?? this.calculationBasis,
        fullUnit: fullUnit ?? this.fullUnit,
        halfUnit: halfUnit ?? this.halfUnit,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OrganizationPolicyRow copyWithCompanion(
      OrganizationPolicyRowsCompanion data) {
    return OrganizationPolicyRow(
      policyId: data.policyId.present ? data.policyId.value : this.policyId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      version: data.version.present ? data.version.value : this.version,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      state: data.state.present ? data.state.value : this.state,
      evaluationPeriod: data.evaluationPeriod.present
          ? data.evaluationPeriod.value
          : this.evaluationPeriod,
      minimumPercent: data.minimumPercent.present
          ? data.minimumPercent.value
          : this.minimumPercent,
      calculationBasis: data.calculationBasis.present
          ? data.calculationBasis.value
          : this.calculationBasis,
      fullUnit: data.fullUnit.present ? data.fullUnit.value : this.fullUnit,
      halfUnit: data.halfUnit.present ? data.halfUnit.value : this.halfUnit,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationPolicyRow(')
          ..write('policyId: $policyId, ')
          ..write('organizationId: $organizationId, ')
          ..write('scopeId: $scopeId, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('state: $state, ')
          ..write('evaluationPeriod: $evaluationPeriod, ')
          ..write('minimumPercent: $minimumPercent, ')
          ..write('calculationBasis: $calculationBasis, ')
          ..write('fullUnit: $fullUnit, ')
          ..write('halfUnit: $halfUnit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      policyId,
      organizationId,
      scopeId,
      version,
      effectiveFrom,
      state,
      evaluationPeriod,
      minimumPercent,
      calculationBasis,
      fullUnit,
      halfUnit,
      startDate,
      endDate,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizationPolicyRow &&
          other.policyId == this.policyId &&
          other.organizationId == this.organizationId &&
          other.scopeId == this.scopeId &&
          other.version == this.version &&
          other.effectiveFrom == this.effectiveFrom &&
          other.state == this.state &&
          other.evaluationPeriod == this.evaluationPeriod &&
          other.minimumPercent == this.minimumPercent &&
          other.calculationBasis == this.calculationBasis &&
          other.fullUnit == this.fullUnit &&
          other.halfUnit == this.halfUnit &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.updatedAt == this.updatedAt);
}

class OrganizationPolicyRowsCompanion
    extends UpdateCompanion<OrganizationPolicyRow> {
  final Value<String> policyId;
  final Value<String> organizationId;
  final Value<String> scopeId;
  final Value<int> version;
  final Value<DateTime> effectiveFrom;
  final Value<String> state;
  final Value<String> evaluationPeriod;
  final Value<double?> minimumPercent;
  final Value<String> calculationBasis;
  final Value<double> fullUnit;
  final Value<double> halfUnit;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrganizationPolicyRowsCompanion({
    this.policyId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.version = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.state = const Value.absent(),
    this.evaluationPeriod = const Value.absent(),
    this.minimumPercent = const Value.absent(),
    this.calculationBasis = const Value.absent(),
    this.fullUnit = const Value.absent(),
    this.halfUnit = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizationPolicyRowsCompanion.insert({
    required String policyId,
    required String organizationId,
    required String scopeId,
    required int version,
    required DateTime effectiveFrom,
    required String state,
    required String evaluationPeriod,
    this.minimumPercent = const Value.absent(),
    required String calculationBasis,
    required double fullUnit,
    required double halfUnit,
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : policyId = Value(policyId),
        organizationId = Value(organizationId),
        scopeId = Value(scopeId),
        version = Value(version),
        effectiveFrom = Value(effectiveFrom),
        state = Value(state),
        evaluationPeriod = Value(evaluationPeriod),
        calculationBasis = Value(calculationBasis),
        fullUnit = Value(fullUnit),
        halfUnit = Value(halfUnit),
        updatedAt = Value(updatedAt);
  static Insertable<OrganizationPolicyRow> custom({
    Expression<String>? policyId,
    Expression<String>? organizationId,
    Expression<String>? scopeId,
    Expression<int>? version,
    Expression<DateTime>? effectiveFrom,
    Expression<String>? state,
    Expression<String>? evaluationPeriod,
    Expression<double>? minimumPercent,
    Expression<String>? calculationBasis,
    Expression<double>? fullUnit,
    Expression<double>? halfUnit,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (policyId != null) 'policy_id': policyId,
      if (organizationId != null) 'organization_id': organizationId,
      if (scopeId != null) 'scope_id': scopeId,
      if (version != null) 'version': version,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (state != null) 'state': state,
      if (evaluationPeriod != null) 'evaluation_period': evaluationPeriod,
      if (minimumPercent != null) 'minimum_percent': minimumPercent,
      if (calculationBasis != null) 'calculation_basis': calculationBasis,
      if (fullUnit != null) 'full_unit': fullUnit,
      if (halfUnit != null) 'half_unit': halfUnit,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizationPolicyRowsCompanion copyWith(
      {Value<String>? policyId,
      Value<String>? organizationId,
      Value<String>? scopeId,
      Value<int>? version,
      Value<DateTime>? effectiveFrom,
      Value<String>? state,
      Value<String>? evaluationPeriod,
      Value<double?>? minimumPercent,
      Value<String>? calculationBasis,
      Value<double>? fullUnit,
      Value<double>? halfUnit,
      Value<DateTime?>? startDate,
      Value<DateTime?>? endDate,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return OrganizationPolicyRowsCompanion(
      policyId: policyId ?? this.policyId,
      organizationId: organizationId ?? this.organizationId,
      scopeId: scopeId ?? this.scopeId,
      version: version ?? this.version,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      state: state ?? this.state,
      evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
      minimumPercent: minimumPercent ?? this.minimumPercent,
      calculationBasis: calculationBasis ?? this.calculationBasis,
      fullUnit: fullUnit ?? this.fullUnit,
      halfUnit: halfUnit ?? this.halfUnit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (policyId.present) {
      map['policy_id'] = Variable<String>(policyId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (evaluationPeriod.present) {
      map['evaluation_period'] = Variable<String>(evaluationPeriod.value);
    }
    if (minimumPercent.present) {
      map['minimum_percent'] = Variable<double>(minimumPercent.value);
    }
    if (calculationBasis.present) {
      map['calculation_basis'] = Variable<String>(calculationBasis.value);
    }
    if (fullUnit.present) {
      map['full_unit'] = Variable<double>(fullUnit.value);
    }
    if (halfUnit.present) {
      map['half_unit'] = Variable<double>(halfUnit.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationPolicyRowsCompanion(')
          ..write('policyId: $policyId, ')
          ..write('organizationId: $organizationId, ')
          ..write('scopeId: $scopeId, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('state: $state, ')
          ..write('evaluationPeriod: $evaluationPeriod, ')
          ..write('minimumPercent: $minimumPercent, ')
          ..write('calculationBasis: $calculationBasis, ')
          ..write('fullUnit: $fullUnit, ')
          ..write('halfUnit: $halfUnit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueRowsTable extends SyncQueueRows
    with TableInfo<$SyncQueueRowsTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operation,
        entityId,
        payload,
        attemptCount,
        nextAttemptAt,
        lastError,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_rows';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueRowsTable createAlias(String alias) {
    return $SyncQueueRowsTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final String id;
  final String operation;
  final String entityId;
  final String payload;
  final int attemptCount;
  final DateTime nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const SyncQueueRow(
      {required this.id,
      required this.operation,
      required this.entityId,
      required this.payload,
      required this.attemptCount,
      required this.nextAttemptAt,
      this.lastError,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation'] = Variable<String>(operation);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueRowsCompanion(
      id: Value(id),
      operation: Value(operation),
      entityId: Value(entityId),
      payload: Value(payload),
      attemptCount: Value(attemptCount),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<String>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operation': serializer.toJson<String>(operation),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueRow copyWith(
          {String? id,
          String? operation,
          String? entityId,
          String? payload,
          int? attemptCount,
          DateTime? nextAttemptAt,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt}) =>
      SyncQueueRow(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        entityId: entityId ?? this.entityId,
        payload: payload ?? this.payload,
        attemptCount: attemptCount ?? this.attemptCount,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueRow copyWithCompanion(SyncQueueRowsCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operation, entityId, payload,
      attemptCount, nextAttemptAt, lastError, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncQueueRowsCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<String> id;
  final Value<String> operation;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<int> attemptCount;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncQueueRowsCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueRowsCompanion.insert({
    required String id,
    required String operation,
    required String entityId,
    required String payload,
    this.attemptCount = const Value.absent(),
    required DateTime nextAttemptAt,
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operation = Value(operation),
        entityId = Value(entityId),
        payload = Value(payload),
        nextAttemptAt = Value(nextAttemptAt),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<String>? id,
    Expression<String>? operation,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? operation,
      Value<String>? entityId,
      Value<String>? payload,
      Value<int>? attemptCount,
      Value<DateTime>? nextAttemptAt,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SyncQueueRowsCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRowsCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataRowsTable extends SyncMetadataRows
    with TableInfo<$SyncMetadataRowsTable, SyncMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_rows';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetadataRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at'])!,
    );
  }

  @override
  $SyncMetadataRowsTable createAlias(String alias) {
    return $SyncMetadataRowsTable(attachedDatabase, alias);
  }
}

class SyncMetadataRow extends DataClass implements Insertable<SyncMetadataRow> {
  final String key;
  final DateTime lastSyncAt;
  const SyncMetadataRow({required this.key, required this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    return map;
  }

  SyncMetadataRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataRowsCompanion(
      key: Value(key),
      lastSyncAt: Value(lastSyncAt),
    );
  }

  factory SyncMetadataRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataRow(
      key: serializer.fromJson<String>(json['key']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
    };
  }

  SyncMetadataRow copyWith({String? key, DateTime? lastSyncAt}) =>
      SyncMetadataRow(
        key: key ?? this.key,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
  SyncMetadataRow copyWithCompanion(SyncMetadataRowsCompanion data) {
    return SyncMetadataRow(
      key: data.key.present ? data.key.value : this.key,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRow(')
          ..write('key: $key, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataRow &&
          other.key == this.key &&
          other.lastSyncAt == this.lastSyncAt);
}

class SyncMetadataRowsCompanion extends UpdateCompanion<SyncMetadataRow> {
  final Value<String> key;
  final Value<DateTime> lastSyncAt;
  final Value<int> rowid;
  const SyncMetadataRowsCompanion({
    this.key = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataRowsCompanion.insert({
    required String key,
    required DateTime lastSyncAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        lastSyncAt = Value(lastSyncAt);
  static Insertable<SyncMetadataRow> custom({
    Expression<String>? key,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataRowsCompanion copyWith(
      {Value<String>? key, Value<DateTime>? lastSyncAt, Value<int>? rowid}) {
    return SyncMetadataRowsCompanion(
      key: key ?? this.key,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRowsCompanion(')
          ..write('key: $key, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StandInDatabase extends GeneratedDatabase {
  _$StandInDatabase(QueryExecutor e) : super(e);
  $StandInDatabaseManager get managers => $StandInDatabaseManager(this);
  late final $AttendanceTableTable attendanceTable =
      $AttendanceTableTable(this);
  late final $OrganizationRowsTable organizationRows =
      $OrganizationRowsTable(this);
  late final $ScopeRowsTable scopeRows = $ScopeRowsTable(this);
  late final $FollowRowsTable followRows = $FollowRowsTable(this);
  late final $MembershipRowsTable membershipRows = $MembershipRowsTable(this);
  late final $UserProfileRowsTable userProfileRows =
      $UserProfileRowsTable(this);
  late final $OrganizationPolicyRowsTable organizationPolicyRows =
      $OrganizationPolicyRowsTable(this);
  late final $SyncQueueRowsTable syncQueueRows = $SyncQueueRowsTable(this);
  late final $SyncMetadataRowsTable syncMetadataRows =
      $SyncMetadataRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        attendanceTable,
        organizationRows,
        scopeRows,
        followRows,
        membershipRows,
        userProfileRows,
        organizationPolicyRows,
        syncQueueRows,
        syncMetadataRows
      ];
}

typedef $$AttendanceTableTableCreateCompanionBuilder = AttendanceTableCompanion
    Function({
  required String id,
  required String orgId,
  required String contextId,
  required DateTime attendanceDate,
  required String status,
  required double actualUnits,
  required double expectedUnits,
  Value<String?> policyVersionId,
  Value<String?> calendarVersionId,
  Value<bool> pendingSync,
  Value<String?> syncError,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AttendanceTableTableUpdateCompanionBuilder = AttendanceTableCompanion
    Function({
  Value<String> id,
  Value<String> orgId,
  Value<String> contextId,
  Value<DateTime> attendanceDate,
  Value<String> status,
  Value<double> actualUnits,
  Value<double> expectedUnits,
  Value<String?> policyVersionId,
  Value<String?> calendarVersionId,
  Value<bool> pendingSync,
  Value<String?> syncError,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AttendanceTableTableFilterComposer
    extends Composer<_$StandInDatabase, $AttendanceTableTable> {
  $$AttendanceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgId => $composableBuilder(
      column: $table.orgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contextId => $composableBuilder(
      column: $table.contextId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualUnits => $composableBuilder(
      column: $table.actualUnits, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedUnits => $composableBuilder(
      column: $table.expectedUnits, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policyVersionId => $composableBuilder(
      column: $table.policyVersionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calendarVersionId => $composableBuilder(
      column: $table.calendarVersionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AttendanceTableTableOrderingComposer
    extends Composer<_$StandInDatabase, $AttendanceTableTable> {
  $$AttendanceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgId => $composableBuilder(
      column: $table.orgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contextId => $composableBuilder(
      column: $table.contextId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualUnits => $composableBuilder(
      column: $table.actualUnits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedUnits => $composableBuilder(
      column: $table.expectedUnits,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policyVersionId => $composableBuilder(
      column: $table.policyVersionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calendarVersionId => $composableBuilder(
      column: $table.calendarVersionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AttendanceTableTableAnnotationComposer
    extends Composer<_$StandInDatabase, $AttendanceTableTable> {
  $$AttendanceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orgId =>
      $composableBuilder(column: $table.orgId, builder: (column) => column);

  GeneratedColumn<String> get contextId =>
      $composableBuilder(column: $table.contextId, builder: (column) => column);

  GeneratedColumn<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get actualUnits => $composableBuilder(
      column: $table.actualUnits, builder: (column) => column);

  GeneratedColumn<double> get expectedUnits => $composableBuilder(
      column: $table.expectedUnits, builder: (column) => column);

  GeneratedColumn<String> get policyVersionId => $composableBuilder(
      column: $table.policyVersionId, builder: (column) => column);

  GeneratedColumn<String> get calendarVersionId => $composableBuilder(
      column: $table.calendarVersionId, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AttendanceTableTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $AttendanceTableTable,
    AttendanceTableData,
    $$AttendanceTableTableFilterComposer,
    $$AttendanceTableTableOrderingComposer,
    $$AttendanceTableTableAnnotationComposer,
    $$AttendanceTableTableCreateCompanionBuilder,
    $$AttendanceTableTableUpdateCompanionBuilder,
    (
      AttendanceTableData,
      BaseReferences<_$StandInDatabase, $AttendanceTableTable,
          AttendanceTableData>
    ),
    AttendanceTableData,
    PrefetchHooks Function()> {
  $$AttendanceTableTableTableManager(
      _$StandInDatabase db, $AttendanceTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orgId = const Value.absent(),
            Value<String> contextId = const Value.absent(),
            Value<DateTime> attendanceDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> actualUnits = const Value.absent(),
            Value<double> expectedUnits = const Value.absent(),
            Value<String?> policyVersionId = const Value.absent(),
            Value<String?> calendarVersionId = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceTableCompanion(
            id: id,
            orgId: orgId,
            contextId: contextId,
            attendanceDate: attendanceDate,
            status: status,
            actualUnits: actualUnits,
            expectedUnits: expectedUnits,
            policyVersionId: policyVersionId,
            calendarVersionId: calendarVersionId,
            pendingSync: pendingSync,
            syncError: syncError,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orgId,
            required String contextId,
            required DateTime attendanceDate,
            required String status,
            required double actualUnits,
            required double expectedUnits,
            Value<String?> policyVersionId = const Value.absent(),
            Value<String?> calendarVersionId = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceTableCompanion.insert(
            id: id,
            orgId: orgId,
            contextId: contextId,
            attendanceDate: attendanceDate,
            status: status,
            actualUnits: actualUnits,
            expectedUnits: expectedUnits,
            policyVersionId: policyVersionId,
            calendarVersionId: calendarVersionId,
            pendingSync: pendingSync,
            syncError: syncError,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttendanceTableTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $AttendanceTableTable,
    AttendanceTableData,
    $$AttendanceTableTableFilterComposer,
    $$AttendanceTableTableOrderingComposer,
    $$AttendanceTableTableAnnotationComposer,
    $$AttendanceTableTableCreateCompanionBuilder,
    $$AttendanceTableTableUpdateCompanionBuilder,
    (
      AttendanceTableData,
      BaseReferences<_$StandInDatabase, $AttendanceTableTable,
          AttendanceTableData>
    ),
    AttendanceTableData,
    PrefetchHooks Function()>;
typedef $$OrganizationRowsTableCreateCompanionBuilder
    = OrganizationRowsCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<bool> isVerified,
  Value<bool> isHolidayCalendarConfigured,
  Value<String?> activePolicyId,
  Value<String?> activeCalendarId,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$OrganizationRowsTableUpdateCompanionBuilder
    = OrganizationRowsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<bool> isVerified,
  Value<bool> isHolidayCalendarConfigured,
  Value<String?> activePolicyId,
  Value<String?> activeCalendarId,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OrganizationRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $OrganizationRowsTable> {
  $$OrganizationRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHolidayCalendarConfigured => $composableBuilder(
      column: $table.isHolidayCalendarConfigured,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OrganizationRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $OrganizationRowsTable> {
  $$OrganizationRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHolidayCalendarConfigured => $composableBuilder(
      column: $table.isHolidayCalendarConfigured,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrganizationRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $OrganizationRowsTable> {
  $$OrganizationRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => column);

  GeneratedColumn<bool> get isHolidayCalendarConfigured => $composableBuilder(
      column: $table.isHolidayCalendarConfigured, builder: (column) => column);

  GeneratedColumn<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId, builder: (column) => column);

  GeneratedColumn<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrganizationRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $OrganizationRowsTable,
    OrganizationRow,
    $$OrganizationRowsTableFilterComposer,
    $$OrganizationRowsTableOrderingComposer,
    $$OrganizationRowsTableAnnotationComposer,
    $$OrganizationRowsTableCreateCompanionBuilder,
    $$OrganizationRowsTableUpdateCompanionBuilder,
    (
      OrganizationRow,
      BaseReferences<_$StandInDatabase, $OrganizationRowsTable, OrganizationRow>
    ),
    OrganizationRow,
    PrefetchHooks Function()> {
  $$OrganizationRowsTableTableManager(
      _$StandInDatabase db, $OrganizationRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizationRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizationRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizationRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<bool> isVerified = const Value.absent(),
            Value<bool> isHolidayCalendarConfigured = const Value.absent(),
            Value<String?> activePolicyId = const Value.absent(),
            Value<String?> activeCalendarId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrganizationRowsCompanion(
            id: id,
            name: name,
            type: type,
            isVerified: isVerified,
            isHolidayCalendarConfigured: isHolidayCalendarConfigured,
            activePolicyId: activePolicyId,
            activeCalendarId: activeCalendarId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<bool> isVerified = const Value.absent(),
            Value<bool> isHolidayCalendarConfigured = const Value.absent(),
            Value<String?> activePolicyId = const Value.absent(),
            Value<String?> activeCalendarId = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OrganizationRowsCompanion.insert(
            id: id,
            name: name,
            type: type,
            isVerified: isVerified,
            isHolidayCalendarConfigured: isHolidayCalendarConfigured,
            activePolicyId: activePolicyId,
            activeCalendarId: activeCalendarId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrganizationRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $OrganizationRowsTable,
    OrganizationRow,
    $$OrganizationRowsTableFilterComposer,
    $$OrganizationRowsTableOrderingComposer,
    $$OrganizationRowsTableAnnotationComposer,
    $$OrganizationRowsTableCreateCompanionBuilder,
    $$OrganizationRowsTableUpdateCompanionBuilder,
    (
      OrganizationRow,
      BaseReferences<_$StandInDatabase, $OrganizationRowsTable, OrganizationRow>
    ),
    OrganizationRow,
    PrefetchHooks Function()>;
typedef $$ScopeRowsTableCreateCompanionBuilder = ScopeRowsCompanion Function({
  required String id,
  required String organizationId,
  Value<String?> parentId,
  required String type,
  required String name,
  Value<String?> activePolicyId,
  Value<String?> activeCalendarId,
  Value<int> rowid,
});
typedef $$ScopeRowsTableUpdateCompanionBuilder = ScopeRowsCompanion Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String?> parentId,
  Value<String> type,
  Value<String> name,
  Value<String?> activePolicyId,
  Value<String?> activeCalendarId,
  Value<int> rowid,
});

class $$ScopeRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $ScopeRowsTable> {
  $$ScopeRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId,
      builder: (column) => ColumnFilters(column));
}

class $$ScopeRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $ScopeRowsTable> {
  $$ScopeRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId,
      builder: (column) => ColumnOrderings(column));
}

class $$ScopeRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $ScopeRowsTable> {
  $$ScopeRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get activePolicyId => $composableBuilder(
      column: $table.activePolicyId, builder: (column) => column);

  GeneratedColumn<String> get activeCalendarId => $composableBuilder(
      column: $table.activeCalendarId, builder: (column) => column);
}

class $$ScopeRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $ScopeRowsTable,
    ScopeRow,
    $$ScopeRowsTableFilterComposer,
    $$ScopeRowsTableOrderingComposer,
    $$ScopeRowsTableAnnotationComposer,
    $$ScopeRowsTableCreateCompanionBuilder,
    $$ScopeRowsTableUpdateCompanionBuilder,
    (ScopeRow, BaseReferences<_$StandInDatabase, $ScopeRowsTable, ScopeRow>),
    ScopeRow,
    PrefetchHooks Function()> {
  $$ScopeRowsTableTableManager(_$StandInDatabase db, $ScopeRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScopeRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScopeRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScopeRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> activePolicyId = const Value.absent(),
            Value<String?> activeCalendarId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScopeRowsCompanion(
            id: id,
            organizationId: organizationId,
            parentId: parentId,
            type: type,
            name: name,
            activePolicyId: activePolicyId,
            activeCalendarId: activeCalendarId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            Value<String?> parentId = const Value.absent(),
            required String type,
            required String name,
            Value<String?> activePolicyId = const Value.absent(),
            Value<String?> activeCalendarId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScopeRowsCompanion.insert(
            id: id,
            organizationId: organizationId,
            parentId: parentId,
            type: type,
            name: name,
            activePolicyId: activePolicyId,
            activeCalendarId: activeCalendarId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScopeRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $ScopeRowsTable,
    ScopeRow,
    $$ScopeRowsTableFilterComposer,
    $$ScopeRowsTableOrderingComposer,
    $$ScopeRowsTableAnnotationComposer,
    $$ScopeRowsTableCreateCompanionBuilder,
    $$ScopeRowsTableUpdateCompanionBuilder,
    (ScopeRow, BaseReferences<_$StandInDatabase, $ScopeRowsTable, ScopeRow>),
    ScopeRow,
    PrefetchHooks Function()>;
typedef $$FollowRowsTableCreateCompanionBuilder = FollowRowsCompanion Function({
  required String id,
  required String organizationId,
  required String scopeId,
  Value<double?> personalTargetPercent,
  required String status,
  required DateTime followedAt,
  Value<int> rowid,
});
typedef $$FollowRowsTableUpdateCompanionBuilder = FollowRowsCompanion Function({
  Value<String> id,
  Value<String> organizationId,
  Value<String> scopeId,
  Value<double?> personalTargetPercent,
  Value<String> status,
  Value<DateTime> followedAt,
  Value<int> rowid,
});

class $$FollowRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $FollowRowsTable> {
  $$FollowRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get personalTargetPercent => $composableBuilder(
      column: $table.personalTargetPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => ColumnFilters(column));
}

class $$FollowRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $FollowRowsTable> {
  $$FollowRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get personalTargetPercent => $composableBuilder(
      column: $table.personalTargetPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => ColumnOrderings(column));
}

class $$FollowRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $FollowRowsTable> {
  $$FollowRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<double> get personalTargetPercent => $composableBuilder(
      column: $table.personalTargetPercent, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get followedAt => $composableBuilder(
      column: $table.followedAt, builder: (column) => column);
}

class $$FollowRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $FollowRowsTable,
    FollowRow,
    $$FollowRowsTableFilterComposer,
    $$FollowRowsTableOrderingComposer,
    $$FollowRowsTableAnnotationComposer,
    $$FollowRowsTableCreateCompanionBuilder,
    $$FollowRowsTableUpdateCompanionBuilder,
    (FollowRow, BaseReferences<_$StandInDatabase, $FollowRowsTable, FollowRow>),
    FollowRow,
    PrefetchHooks Function()> {
  $$FollowRowsTableTableManager(_$StandInDatabase db, $FollowRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> scopeId = const Value.absent(),
            Value<double?> personalTargetPercent = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> followedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FollowRowsCompanion(
            id: id,
            organizationId: organizationId,
            scopeId: scopeId,
            personalTargetPercent: personalTargetPercent,
            status: status,
            followedAt: followedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required String scopeId,
            Value<double?> personalTargetPercent = const Value.absent(),
            required String status,
            required DateTime followedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FollowRowsCompanion.insert(
            id: id,
            organizationId: organizationId,
            scopeId: scopeId,
            personalTargetPercent: personalTargetPercent,
            status: status,
            followedAt: followedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FollowRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $FollowRowsTable,
    FollowRow,
    $$FollowRowsTableFilterComposer,
    $$FollowRowsTableOrderingComposer,
    $$FollowRowsTableAnnotationComposer,
    $$FollowRowsTableCreateCompanionBuilder,
    $$FollowRowsTableUpdateCompanionBuilder,
    (FollowRow, BaseReferences<_$StandInDatabase, $FollowRowsTable, FollowRow>),
    FollowRow,
    PrefetchHooks Function()>;
typedef $$MembershipRowsTableCreateCompanionBuilder = MembershipRowsCompanion
    Function({
  required String uid,
  required String organizationId,
  required String status,
  Value<String?> idNumber,
  required DateTime joinedAt,
  Value<DateTime?> verifiedAt,
  Value<int> rowid,
});
typedef $$MembershipRowsTableUpdateCompanionBuilder = MembershipRowsCompanion
    Function({
  Value<String> uid,
  Value<String> organizationId,
  Value<String> status,
  Value<String?> idNumber,
  Value<DateTime> joinedAt,
  Value<DateTime?> verifiedAt,
  Value<int> rowid,
});

class $$MembershipRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $MembershipRowsTable> {
  $$MembershipRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idNumber => $composableBuilder(
      column: $table.idNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnFilters(column));
}

class $$MembershipRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $MembershipRowsTable> {
  $$MembershipRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idNumber => $composableBuilder(
      column: $table.idNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnOrderings(column));
}

class $$MembershipRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $MembershipRowsTable> {
  $$MembershipRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get idNumber =>
      $composableBuilder(column: $table.idNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => column);
}

class $$MembershipRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $MembershipRowsTable,
    MembershipRow,
    $$MembershipRowsTableFilterComposer,
    $$MembershipRowsTableOrderingComposer,
    $$MembershipRowsTableAnnotationComposer,
    $$MembershipRowsTableCreateCompanionBuilder,
    $$MembershipRowsTableUpdateCompanionBuilder,
    (
      MembershipRow,
      BaseReferences<_$StandInDatabase, $MembershipRowsTable, MembershipRow>
    ),
    MembershipRow,
    PrefetchHooks Function()> {
  $$MembershipRowsTableTableManager(
      _$StandInDatabase db, $MembershipRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembershipRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembershipRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembershipRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> idNumber = const Value.absent(),
            Value<DateTime> joinedAt = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembershipRowsCompanion(
            uid: uid,
            organizationId: organizationId,
            status: status,
            idNumber: idNumber,
            joinedAt: joinedAt,
            verifiedAt: verifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String organizationId,
            required String status,
            Value<String?> idNumber = const Value.absent(),
            required DateTime joinedAt,
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembershipRowsCompanion.insert(
            uid: uid,
            organizationId: organizationId,
            status: status,
            idNumber: idNumber,
            joinedAt: joinedAt,
            verifiedAt: verifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MembershipRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $MembershipRowsTable,
    MembershipRow,
    $$MembershipRowsTableFilterComposer,
    $$MembershipRowsTableOrderingComposer,
    $$MembershipRowsTableAnnotationComposer,
    $$MembershipRowsTableCreateCompanionBuilder,
    $$MembershipRowsTableUpdateCompanionBuilder,
    (
      MembershipRow,
      BaseReferences<_$StandInDatabase, $MembershipRowsTable, MembershipRow>
    ),
    MembershipRow,
    PrefetchHooks Function()>;
typedef $$UserProfileRowsTableCreateCompanionBuilder = UserProfileRowsCompanion
    Function({
  required String uid,
  required String displayName,
  required String role,
  Value<String?> mobile,
  Value<String?> activeFollowId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UserProfileRowsTableUpdateCompanionBuilder = UserProfileRowsCompanion
    Function({
  Value<String> uid,
  Value<String> displayName,
  Value<String> role,
  Value<String?> mobile,
  Value<String?> activeFollowId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserProfileRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $UserProfileRowsTable> {
  $$UserProfileRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeFollowId => $composableBuilder(
      column: $table.activeFollowId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserProfileRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $UserProfileRowsTable> {
  $$UserProfileRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeFollowId => $composableBuilder(
      column: $table.activeFollowId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserProfileRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $UserProfileRowsTable> {
  $$UserProfileRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get activeFollowId => $composableBuilder(
      column: $table.activeFollowId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $UserProfileRowsTable,
    UserProfileRow,
    $$UserProfileRowsTableFilterComposer,
    $$UserProfileRowsTableOrderingComposer,
    $$UserProfileRowsTableAnnotationComposer,
    $$UserProfileRowsTableCreateCompanionBuilder,
    $$UserProfileRowsTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$StandInDatabase, $UserProfileRowsTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()> {
  $$UserProfileRowsTableTableManager(
      _$StandInDatabase db, $UserProfileRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> mobile = const Value.absent(),
            Value<String?> activeFollowId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfileRowsCompanion(
            uid: uid,
            displayName: displayName,
            role: role,
            mobile: mobile,
            activeFollowId: activeFollowId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String displayName,
            required String role,
            Value<String?> mobile = const Value.absent(),
            Value<String?> activeFollowId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfileRowsCompanion.insert(
            uid: uid,
            displayName: displayName,
            role: role,
            mobile: mobile,
            activeFollowId: activeFollowId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfileRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $UserProfileRowsTable,
    UserProfileRow,
    $$UserProfileRowsTableFilterComposer,
    $$UserProfileRowsTableOrderingComposer,
    $$UserProfileRowsTableAnnotationComposer,
    $$UserProfileRowsTableCreateCompanionBuilder,
    $$UserProfileRowsTableUpdateCompanionBuilder,
    (
      UserProfileRow,
      BaseReferences<_$StandInDatabase, $UserProfileRowsTable, UserProfileRow>
    ),
    UserProfileRow,
    PrefetchHooks Function()>;
typedef $$OrganizationPolicyRowsTableCreateCompanionBuilder
    = OrganizationPolicyRowsCompanion Function({
  required String policyId,
  required String organizationId,
  required String scopeId,
  required int version,
  required DateTime effectiveFrom,
  required String state,
  required String evaluationPeriod,
  Value<double?> minimumPercent,
  required String calculationBasis,
  required double fullUnit,
  required double halfUnit,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$OrganizationPolicyRowsTableUpdateCompanionBuilder
    = OrganizationPolicyRowsCompanion Function({
  Value<String> policyId,
  Value<String> organizationId,
  Value<String> scopeId,
  Value<int> version,
  Value<DateTime> effectiveFrom,
  Value<String> state,
  Value<String> evaluationPeriod,
  Value<double?> minimumPercent,
  Value<String> calculationBasis,
  Value<double> fullUnit,
  Value<double> halfUnit,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OrganizationPolicyRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $OrganizationPolicyRowsTable> {
  $$OrganizationPolicyRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get policyId => $composableBuilder(
      column: $table.policyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evaluationPeriod => $composableBuilder(
      column: $table.evaluationPeriod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minimumPercent => $composableBuilder(
      column: $table.minimumPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calculationBasis => $composableBuilder(
      column: $table.calculationBasis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fullUnit => $composableBuilder(
      column: $table.fullUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get halfUnit => $composableBuilder(
      column: $table.halfUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OrganizationPolicyRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $OrganizationPolicyRowsTable> {
  $$OrganizationPolicyRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get policyId => $composableBuilder(
      column: $table.policyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evaluationPeriod => $composableBuilder(
      column: $table.evaluationPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minimumPercent => $composableBuilder(
      column: $table.minimumPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calculationBasis => $composableBuilder(
      column: $table.calculationBasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fullUnit => $composableBuilder(
      column: $table.fullUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get halfUnit => $composableBuilder(
      column: $table.halfUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OrganizationPolicyRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $OrganizationPolicyRowsTable> {
  $$OrganizationPolicyRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get policyId =>
      $composableBuilder(column: $table.policyId, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get evaluationPeriod => $composableBuilder(
      column: $table.evaluationPeriod, builder: (column) => column);

  GeneratedColumn<double> get minimumPercent => $composableBuilder(
      column: $table.minimumPercent, builder: (column) => column);

  GeneratedColumn<String> get calculationBasis => $composableBuilder(
      column: $table.calculationBasis, builder: (column) => column);

  GeneratedColumn<double> get fullUnit =>
      $composableBuilder(column: $table.fullUnit, builder: (column) => column);

  GeneratedColumn<double> get halfUnit =>
      $composableBuilder(column: $table.halfUnit, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OrganizationPolicyRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $OrganizationPolicyRowsTable,
    OrganizationPolicyRow,
    $$OrganizationPolicyRowsTableFilterComposer,
    $$OrganizationPolicyRowsTableOrderingComposer,
    $$OrganizationPolicyRowsTableAnnotationComposer,
    $$OrganizationPolicyRowsTableCreateCompanionBuilder,
    $$OrganizationPolicyRowsTableUpdateCompanionBuilder,
    (
      OrganizationPolicyRow,
      BaseReferences<_$StandInDatabase, $OrganizationPolicyRowsTable,
          OrganizationPolicyRow>
    ),
    OrganizationPolicyRow,
    PrefetchHooks Function()> {
  $$OrganizationPolicyRowsTableTableManager(
      _$StandInDatabase db, $OrganizationPolicyRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizationPolicyRowsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizationPolicyRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizationPolicyRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> policyId = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> scopeId = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> effectiveFrom = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<String> evaluationPeriod = const Value.absent(),
            Value<double?> minimumPercent = const Value.absent(),
            Value<String> calculationBasis = const Value.absent(),
            Value<double> fullUnit = const Value.absent(),
            Value<double> halfUnit = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrganizationPolicyRowsCompanion(
            policyId: policyId,
            organizationId: organizationId,
            scopeId: scopeId,
            version: version,
            effectiveFrom: effectiveFrom,
            state: state,
            evaluationPeriod: evaluationPeriod,
            minimumPercent: minimumPercent,
            calculationBasis: calculationBasis,
            fullUnit: fullUnit,
            halfUnit: halfUnit,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String policyId,
            required String organizationId,
            required String scopeId,
            required int version,
            required DateTime effectiveFrom,
            required String state,
            required String evaluationPeriod,
            Value<double?> minimumPercent = const Value.absent(),
            required String calculationBasis,
            required double fullUnit,
            required double halfUnit,
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OrganizationPolicyRowsCompanion.insert(
            policyId: policyId,
            organizationId: organizationId,
            scopeId: scopeId,
            version: version,
            effectiveFrom: effectiveFrom,
            state: state,
            evaluationPeriod: evaluationPeriod,
            minimumPercent: minimumPercent,
            calculationBasis: calculationBasis,
            fullUnit: fullUnit,
            halfUnit: halfUnit,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrganizationPolicyRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$StandInDatabase,
        $OrganizationPolicyRowsTable,
        OrganizationPolicyRow,
        $$OrganizationPolicyRowsTableFilterComposer,
        $$OrganizationPolicyRowsTableOrderingComposer,
        $$OrganizationPolicyRowsTableAnnotationComposer,
        $$OrganizationPolicyRowsTableCreateCompanionBuilder,
        $$OrganizationPolicyRowsTableUpdateCompanionBuilder,
        (
          OrganizationPolicyRow,
          BaseReferences<_$StandInDatabase, $OrganizationPolicyRowsTable,
              OrganizationPolicyRow>
        ),
        OrganizationPolicyRow,
        PrefetchHooks Function()>;
typedef $$SyncQueueRowsTableCreateCompanionBuilder = SyncQueueRowsCompanion
    Function({
  required String id,
  required String operation,
  required String entityId,
  required String payload,
  Value<int> attemptCount,
  required DateTime nextAttemptAt,
  Value<String?> lastError,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SyncQueueRowsTableUpdateCompanionBuilder = SyncQueueRowsCompanion
    Function({
  Value<String> id,
  Value<String> operation,
  Value<String> entityId,
  Value<String> payload,
  Value<int> attemptCount,
  Value<DateTime> nextAttemptAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SyncQueueRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $SyncQueueRowsTable,
    SyncQueueRow,
    $$SyncQueueRowsTableFilterComposer,
    $$SyncQueueRowsTableOrderingComposer,
    $$SyncQueueRowsTableAnnotationComposer,
    $$SyncQueueRowsTableCreateCompanionBuilder,
    $$SyncQueueRowsTableUpdateCompanionBuilder,
    (
      SyncQueueRow,
      BaseReferences<_$StandInDatabase, $SyncQueueRowsTable, SyncQueueRow>
    ),
    SyncQueueRow,
    PrefetchHooks Function()> {
  $$SyncQueueRowsTableTableManager(
      _$StandInDatabase db, $SyncQueueRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueRowsCompanion(
            id: id,
            operation: operation,
            entityId: entityId,
            payload: payload,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String operation,
            required String entityId,
            required String payload,
            Value<int> attemptCount = const Value.absent(),
            required DateTime nextAttemptAt,
            Value<String?> lastError = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueRowsCompanion.insert(
            id: id,
            operation: operation,
            entityId: entityId,
            payload: payload,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $SyncQueueRowsTable,
    SyncQueueRow,
    $$SyncQueueRowsTableFilterComposer,
    $$SyncQueueRowsTableOrderingComposer,
    $$SyncQueueRowsTableAnnotationComposer,
    $$SyncQueueRowsTableCreateCompanionBuilder,
    $$SyncQueueRowsTableUpdateCompanionBuilder,
    (
      SyncQueueRow,
      BaseReferences<_$StandInDatabase, $SyncQueueRowsTable, SyncQueueRow>
    ),
    SyncQueueRow,
    PrefetchHooks Function()>;
typedef $$SyncMetadataRowsTableCreateCompanionBuilder
    = SyncMetadataRowsCompanion Function({
  required String key,
  required DateTime lastSyncAt,
  Value<int> rowid,
});
typedef $$SyncMetadataRowsTableUpdateCompanionBuilder
    = SyncMetadataRowsCompanion Function({
  Value<String> key,
  Value<DateTime> lastSyncAt,
  Value<int> rowid,
});

class $$SyncMetadataRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $SyncMetadataRowsTable> {
  $$SyncMetadataRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$SyncMetadataRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $SyncMetadataRowsTable> {
  $$SyncMetadataRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetadataRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $SyncMetadataRowsTable> {
  $$SyncMetadataRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$SyncMetadataRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $SyncMetadataRowsTable,
    SyncMetadataRow,
    $$SyncMetadataRowsTableFilterComposer,
    $$SyncMetadataRowsTableOrderingComposer,
    $$SyncMetadataRowsTableAnnotationComposer,
    $$SyncMetadataRowsTableCreateCompanionBuilder,
    $$SyncMetadataRowsTableUpdateCompanionBuilder,
    (
      SyncMetadataRow,
      BaseReferences<_$StandInDatabase, $SyncMetadataRowsTable, SyncMetadataRow>
    ),
    SyncMetadataRow,
    PrefetchHooks Function()> {
  $$SyncMetadataRowsTableTableManager(
      _$StandInDatabase db, $SyncMetadataRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<DateTime> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataRowsCompanion(
            key: key,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required DateTime lastSyncAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataRowsCompanion.insert(
            key: key,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetadataRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $SyncMetadataRowsTable,
    SyncMetadataRow,
    $$SyncMetadataRowsTableFilterComposer,
    $$SyncMetadataRowsTableOrderingComposer,
    $$SyncMetadataRowsTableAnnotationComposer,
    $$SyncMetadataRowsTableCreateCompanionBuilder,
    $$SyncMetadataRowsTableUpdateCompanionBuilder,
    (
      SyncMetadataRow,
      BaseReferences<_$StandInDatabase, $SyncMetadataRowsTable, SyncMetadataRow>
    ),
    SyncMetadataRow,
    PrefetchHooks Function()>;

class $StandInDatabaseManager {
  final _$StandInDatabase _db;
  $StandInDatabaseManager(this._db);
  $$AttendanceTableTableTableManager get attendanceTable =>
      $$AttendanceTableTableTableManager(_db, _db.attendanceTable);
  $$OrganizationRowsTableTableManager get organizationRows =>
      $$OrganizationRowsTableTableManager(_db, _db.organizationRows);
  $$ScopeRowsTableTableManager get scopeRows =>
      $$ScopeRowsTableTableManager(_db, _db.scopeRows);
  $$FollowRowsTableTableManager get followRows =>
      $$FollowRowsTableTableManager(_db, _db.followRows);
  $$MembershipRowsTableTableManager get membershipRows =>
      $$MembershipRowsTableTableManager(_db, _db.membershipRows);
  $$UserProfileRowsTableTableManager get userProfileRows =>
      $$UserProfileRowsTableTableManager(_db, _db.userProfileRows);
  $$OrganizationPolicyRowsTableTableManager get organizationPolicyRows =>
      $$OrganizationPolicyRowsTableTableManager(
          _db, _db.organizationPolicyRows);
  $$SyncQueueRowsTableTableManager get syncQueueRows =>
      $$SyncQueueRowsTableTableManager(_db, _db.syncQueueRows);
  $$SyncMetadataRowsTableTableManager get syncMetadataRows =>
      $$SyncMetadataRowsTableTableManager(_db, _db.syncMetadataRows);
}
