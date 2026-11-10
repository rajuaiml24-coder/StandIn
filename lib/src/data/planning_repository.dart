import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import '../domain/planning.dart';
import 'local/standin_database.dart';
import 'attendance_repository.dart';

class PlanningRepository {
  PlanningRepository(this.database,
      {required this.organizationId, required this.scopeId});
  final StandInDatabase database;
  final String organizationId;
  final String scopeId;

  Stream<List<AttendancePlan>> watchPlans() => database
      .watchPlans(organizationId, scopeId)
      .map((rows) => rows.map(fromRow).toList());

  Future<void> save(AttendancePlan plan) async {
    if (![
      AttendanceStatus.full,
      AttendanceStatus.half,
      AttendanceStatus.partial,
      AttendanceStatus.leave,
      AttendanceStatus.absent
    ].contains(plan.status)) {
      throw ArgumentError('Invalid plan status');
    }
    if (plan.organizationId != organizationId ||
        plan.scopeId != scopeId ||
        plan.id != attendanceId(plan.date, organizationId, scopeId)) {
      throw ArgumentError('Plan does not match the selected group');
    }
    if (!plan.units.isFinite ||
        plan.units < 0 ||
        !plan.leaveUnits.isFinite ||
        plan.leaveUnits < 0) {
      throw ArgumentError('Invalid planned units');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!plan.isDeleted && !plan.date.isAfter(today)) {
      throw ArgumentError('Only future dates can be planned');
    }
    await database.transaction(() async {
      await database.upsertPlan(toRow(plan, pendingSync: true));
      await database.enqueue(SyncQueueRowsCompanion.insert(
        id: 'plan:${plan.id}',
        operation: 'putPlan',
        entityId: plan.id,
        payload: jsonEncode(plan.toJson()),
        nextAttemptAt: now,
        createdAt: now,
      ));
    });
  }

  Future<void> remove(DateTime date) async {
    final row =
        await database.getPlan(attendanceId(date, organizationId, scopeId));
    if (row == null || row.isDeleted) return;
    await save(AttendancePlan(
      id: row.id,
      organizationId: row.organizationId,
      scopeId: row.scopeId,
      date: row.date,
      status: AttendanceStatus.values.byName(row.status),
      units: row.units,
      leaveUnits: row.leaveUnits,
      policyVersionId: row.policyVersionId,
      calendarVersionId: row.calendarVersionId,
      isDeleted: true,
    ));
  }

  Future<void> revalidateUnchangedDates(AttendanceCalendar before,
          AttendanceCalendar after, AttendancePolicy policy,
          {AttendanceCalendar Function(DateTime)? beforeFor,
          AttendanceCalendar Function(DateTime)? afterFor,
          AttendancePolicy Function(DateTime)? policyFor}) =>
      database.transaction(() async {
        if (beforeFor == null &&
            afterFor == null &&
            planningCalendarKey(before) == planningCalendarKey(after)) {
          return;
        }
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final rows = await (database.select(database.attendancePlanRows)
              ..where((r) =>
                  r.organizationId.equals(organizationId) &
                  r.scopeId.equals(scopeId) &
                  r.isDeleted.equals(false)))
            .get();
        for (final row in rows) {
          final previous = beforeFor?.call(row.date) ?? before;
          final next = afterFor?.call(row.date) ?? after;
          final previousKey = planningCalendarKey(previous);
          final nextKey = planningCalendarKey(next);
          if (!row.date.isAfter(today) ||
              previousKey == nextKey ||
              row.calendarVersionId != previousKey ||
              row.policyVersionId !=
                  planningPolicyKey(policyFor?.call(row.date) ?? policy) ||
              previous.isNonWorkingDay(row.date) !=
                  next.isNonWorkingDay(row.date)) {
            continue;
          }
          await save(AttendancePlan(
              id: row.id,
              organizationId: organizationId,
              scopeId: scopeId,
              date: row.date,
              status: AttendanceStatus.values.byName(row.status),
              units: row.units,
              leaveUnits: row.leaveUnits,
              policyVersionId: row.policyVersionId,
              calendarVersionId: nextKey));
        }
      });

  static AttendancePlan fromRow(AttendancePlanRow row) => AttendancePlan(
        id: row.id,
        organizationId: row.organizationId,
        scopeId: row.scopeId,
        date: row.date,
        status: AttendanceStatus.values.byName(row.status),
        units: row.units,
        leaveUnits: row.leaveUnits,
        policyVersionId: row.policyVersionId,
        calendarVersionId: row.calendarVersionId,
        isDeleted: row.isDeleted,
        pendingSync: row.pendingSync,
        updatedAt: row.updatedAt,
      );

  static AttendancePlanRowsCompanion toRow(AttendancePlan plan,
          {required bool pendingSync}) =>
      AttendancePlanRowsCompanion.insert(
        id: plan.id,
        organizationId: plan.organizationId,
        scopeId: plan.scopeId,
        date: plan.date,
        status: plan.status.name,
        units: plan.units,
        leaveUnits: Value(plan.leaveUnits),
        policyVersionId: Value(plan.policyVersionId),
        calendarVersionId: Value(plan.calendarVersionId),
        isDeleted: Value(plan.isDeleted),
        pendingSync: Value(pendingSync),
        updatedAt: plan.updatedAt ?? DateTime.now(),
      );
}
