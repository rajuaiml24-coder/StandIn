// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standin_database.dart';

// ignore_for_file: type=lint
class $AttendanceRowsTable extends AttendanceRows
    with TableInfo<$AttendanceRowsTable, AttendanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRowsTable(this.attachedDatabase, [this._alias]);
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
        organizationId,
        attendanceDate,
        status,
        actualUnits,
        expectedUnits,
        pendingSync,
        syncError,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_rows';
  @override
  VerificationContext validateIntegrity(Insertable<AttendanceRow> instance,
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
  AttendanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      attendanceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}attendance_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      actualUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_units'])!,
      expectedUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_units'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AttendanceRowsTable createAlias(String alias) {
    return $AttendanceRowsTable(attachedDatabase, alias);
  }
}

class AttendanceRow extends DataClass implements Insertable<AttendanceRow> {
  final String id;
  final String organizationId;
  final DateTime attendanceDate;
  final String status;
  final double actualUnits;
  final double expectedUnits;
  final bool pendingSync;
  final String? syncError;
  final DateTime updatedAt;
  const AttendanceRow(
      {required this.id,
      required this.organizationId,
      required this.attendanceDate,
      required this.status,
      required this.actualUnits,
      required this.expectedUnits,
      required this.pendingSync,
      this.syncError,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['attendance_date'] = Variable<DateTime>(attendanceDate);
    map['status'] = Variable<String>(status);
    map['actual_units'] = Variable<double>(actualUnits);
    map['expected_units'] = Variable<double>(expectedUnits);
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AttendanceRowsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRowsCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      attendanceDate: Value(attendanceDate),
      status: Value(status),
      actualUnits: Value(actualUnits),
      expectedUnits: Value(expectedUnits),
      pendingSync: Value(pendingSync),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttendanceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRow(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      attendanceDate: serializer.fromJson<DateTime>(json['attendanceDate']),
      status: serializer.fromJson<String>(json['status']),
      actualUnits: serializer.fromJson<double>(json['actualUnits']),
      expectedUnits: serializer.fromJson<double>(json['expectedUnits']),
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
      'organizationId': serializer.toJson<String>(organizationId),
      'attendanceDate': serializer.toJson<DateTime>(attendanceDate),
      'status': serializer.toJson<String>(status),
      'actualUnits': serializer.toJson<double>(actualUnits),
      'expectedUnits': serializer.toJson<double>(expectedUnits),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttendanceRow copyWith(
          {String? id,
          String? organizationId,
          DateTime? attendanceDate,
          String? status,
          double? actualUnits,
          double? expectedUnits,
          bool? pendingSync,
          Value<String?> syncError = const Value.absent(),
          DateTime? updatedAt}) =>
      AttendanceRow(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        attendanceDate: attendanceDate ?? this.attendanceDate,
        status: status ?? this.status,
        actualUnits: actualUnits ?? this.actualUnits,
        expectedUnits: expectedUnits ?? this.expectedUnits,
        pendingSync: pendingSync ?? this.pendingSync,
        syncError: syncError.present ? syncError.value : this.syncError,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AttendanceRow copyWithCompanion(AttendanceRowsCompanion data) {
    return AttendanceRow(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      attendanceDate: data.attendanceDate.present
          ? data.attendanceDate.value
          : this.attendanceDate,
      status: data.status.present ? data.status.value : this.status,
      actualUnits:
          data.actualUnits.present ? data.actualUnits.value : this.actualUnits,
      expectedUnits: data.expectedUnits.present
          ? data.expectedUnits.value
          : this.expectedUnits,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRow(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('status: $status, ')
          ..write('actualUnits: $actualUnits, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organizationId, attendanceDate, status,
      actualUnits, expectedUnits, pendingSync, syncError, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRow &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.attendanceDate == this.attendanceDate &&
          other.status == this.status &&
          other.actualUnits == this.actualUnits &&
          other.expectedUnits == this.expectedUnits &&
          other.pendingSync == this.pendingSync &&
          other.syncError == this.syncError &&
          other.updatedAt == this.updatedAt);
}

class AttendanceRowsCompanion extends UpdateCompanion<AttendanceRow> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<DateTime> attendanceDate;
  final Value<String> status;
  final Value<double> actualUnits;
  final Value<double> expectedUnits;
  final Value<bool> pendingSync;
  final Value<String?> syncError;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AttendanceRowsCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.attendanceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.actualUnits = const Value.absent(),
    this.expectedUnits = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRowsCompanion.insert({
    required String id,
    required String organizationId,
    required DateTime attendanceDate,
    required String status,
    required double actualUnits,
    required double expectedUnits,
    this.pendingSync = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        organizationId = Value(organizationId),
        attendanceDate = Value(attendanceDate),
        status = Value(status),
        actualUnits = Value(actualUnits),
        expectedUnits = Value(expectedUnits),
        updatedAt = Value(updatedAt);
  static Insertable<AttendanceRow> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<DateTime>? attendanceDate,
    Expression<String>? status,
    Expression<double>? actualUnits,
    Expression<double>? expectedUnits,
    Expression<bool>? pendingSync,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (attendanceDate != null) 'attendance_date': attendanceDate,
      if (status != null) 'status': status,
      if (actualUnits != null) 'actual_units': actualUnits,
      if (expectedUnits != null) 'expected_units': expectedUnits,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? organizationId,
      Value<DateTime>? attendanceDate,
      Value<String>? status,
      Value<double>? actualUnits,
      Value<double>? expectedUnits,
      Value<bool>? pendingSync,
      Value<String?>? syncError,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AttendanceRowsCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      actualUnits: actualUnits ?? this.actualUnits,
      expectedUnits: expectedUnits ?? this.expectedUnits,
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
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
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
    return (StringBuffer('AttendanceRowsCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('status: $status, ')
          ..write('actualUnits: $actualUnits, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncError: $syncError, ')
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

abstract class _$StandInDatabase extends GeneratedDatabase {
  _$StandInDatabase(QueryExecutor e) : super(e);
  $StandInDatabaseManager get managers => $StandInDatabaseManager(this);
  late final $AttendanceRowsTable attendanceRows = $AttendanceRowsTable(this);
  late final $OrganizationPolicyRowsTable organizationPolicyRows =
      $OrganizationPolicyRowsTable(this);
  late final $SyncQueueRowsTable syncQueueRows = $SyncQueueRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [attendanceRows, organizationPolicyRows, syncQueueRows];
}

typedef $$AttendanceRowsTableCreateCompanionBuilder = AttendanceRowsCompanion
    Function({
  required String id,
  required String organizationId,
  required DateTime attendanceDate,
  required String status,
  required double actualUnits,
  required double expectedUnits,
  Value<bool> pendingSync,
  Value<String?> syncError,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AttendanceRowsTableUpdateCompanionBuilder = AttendanceRowsCompanion
    Function({
  Value<String> id,
  Value<String> organizationId,
  Value<DateTime> attendanceDate,
  Value<String> status,
  Value<double> actualUnits,
  Value<double> expectedUnits,
  Value<bool> pendingSync,
  Value<String?> syncError,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AttendanceRowsTableFilterComposer
    extends Composer<_$StandInDatabase, $AttendanceRowsTable> {
  $$AttendanceRowsTableFilterComposer({
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

  ColumnFilters<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualUnits => $composableBuilder(
      column: $table.actualUnits, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedUnits => $composableBuilder(
      column: $table.expectedUnits, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AttendanceRowsTableOrderingComposer
    extends Composer<_$StandInDatabase, $AttendanceRowsTable> {
  $$AttendanceRowsTableOrderingComposer({
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

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AttendanceRowsTableAnnotationComposer
    extends Composer<_$StandInDatabase, $AttendanceRowsTable> {
  $$AttendanceRowsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get actualUnits => $composableBuilder(
      column: $table.actualUnits, builder: (column) => column);

  GeneratedColumn<double> get expectedUnits => $composableBuilder(
      column: $table.expectedUnits, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AttendanceRowsTableTableManager extends RootTableManager<
    _$StandInDatabase,
    $AttendanceRowsTable,
    AttendanceRow,
    $$AttendanceRowsTableFilterComposer,
    $$AttendanceRowsTableOrderingComposer,
    $$AttendanceRowsTableAnnotationComposer,
    $$AttendanceRowsTableCreateCompanionBuilder,
    $$AttendanceRowsTableUpdateCompanionBuilder,
    (
      AttendanceRow,
      BaseReferences<_$StandInDatabase, $AttendanceRowsTable, AttendanceRow>
    ),
    AttendanceRow,
    PrefetchHooks Function()> {
  $$AttendanceRowsTableTableManager(
      _$StandInDatabase db, $AttendanceRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<DateTime> attendanceDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> actualUnits = const Value.absent(),
            Value<double> expectedUnits = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRowsCompanion(
            id: id,
            organizationId: organizationId,
            attendanceDate: attendanceDate,
            status: status,
            actualUnits: actualUnits,
            expectedUnits: expectedUnits,
            pendingSync: pendingSync,
            syncError: syncError,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String organizationId,
            required DateTime attendanceDate,
            required String status,
            required double actualUnits,
            required double expectedUnits,
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendanceRowsCompanion.insert(
            id: id,
            organizationId: organizationId,
            attendanceDate: attendanceDate,
            status: status,
            actualUnits: actualUnits,
            expectedUnits: expectedUnits,
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

typedef $$AttendanceRowsTableProcessedTableManager = ProcessedTableManager<
    _$StandInDatabase,
    $AttendanceRowsTable,
    AttendanceRow,
    $$AttendanceRowsTableFilterComposer,
    $$AttendanceRowsTableOrderingComposer,
    $$AttendanceRowsTableAnnotationComposer,
    $$AttendanceRowsTableCreateCompanionBuilder,
    $$AttendanceRowsTableUpdateCompanionBuilder,
    (
      AttendanceRow,
      BaseReferences<_$StandInDatabase, $AttendanceRowsTable, AttendanceRow>
    ),
    AttendanceRow,
    PrefetchHooks Function()>;
typedef $$OrganizationPolicyRowsTableCreateCompanionBuilder
    = OrganizationPolicyRowsCompanion Function({
  required String policyId,
  required String organizationId,
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

class $StandInDatabaseManager {
  final _$StandInDatabase _db;
  $StandInDatabaseManager(this._db);
  $$AttendanceRowsTableTableManager get attendanceRows =>
      $$AttendanceRowsTableTableManager(_db, _db.attendanceRows);
  $$OrganizationPolicyRowsTableTableManager get organizationPolicyRows =>
      $$OrganizationPolicyRowsTableTableManager(
          _db, _db.organizationPolicyRows);
  $$SyncQueueRowsTableTableManager get syncQueueRows =>
      $$SyncQueueRowsTableTableManager(_db, _db.syncQueueRows);
}
