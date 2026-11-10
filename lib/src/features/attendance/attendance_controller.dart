import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/attendance_repository.dart';
import '../../data/local_first_attendance_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/policy_engine.dart';
import '../../domain/planning.dart';
import '../../data/planning_repository.dart';
import '../../data/calendar_repository.dart';
import '../../data/local/standin_database.dart';
import '../../domain/calendar_updates.dart';

class AttendanceController extends ChangeNotifier with WidgetsBindingObserver {
  AttendanceController(
      this._repository, this._engine, this.policy, this.calendar,
      {this.planningRepository,
      this.calendarRepository,
      this.isCompany = false,
      DateTime Function()? clock,
      bool refreshAtMidnight = false})
      : _clock = clock ?? DateTime.now,
        _observeDay = refreshAtMidnight {
    if (_observeDay) {
      WidgetsBinding.instance.addObserver(this);
      _scheduleDayRefresh();
    }
    ready = _initializeHistory();
    _subscription = _repository.watchRecords().listen((records) {
      this.records = records;
      summary = _engine.summarize(
        policy,
        calendar,
        records,
        _clock(),
        isHolidayCalendarConfigured: false,
        policyFor: policyFor,
        calendarFor: calendarFor,
      );
      notifyListeners();
    });
    _planSubscription = planningRepository?.watchPlans().listen((plans) {
      this.plans = plans;
      notifyListeners();
    });
    _calendarSubscription = calendarRepository?.watch().listen((state) {
      if (state == null) return;
      final before = calendar;
      final previous = _accepted;
      _accepted = state;
      policy = state.policyAt(_clock()) ?? policy;
      calendar = state.calendarAt(_clock());
      unawaited(planningRepository
              ?.revalidateUnchangedDates(before, calendar, policy,
                  beforeFor: (date) => previous?.calendarAt(date) ?? before,
                  afterFor: calendarFor,
                  policyFor: policyFor)
              .catchError((Object error) =>
                  debugPrint('Plan calendar refresh failed: $error')) ??
          Future<void>.value());
      summary = _engine.summarize(policy, calendar, records, _clock(),
          policyFor: policyFor, calendarFor: calendarFor);
      notifyListeners();
    });
    _remoteCalendarSubscription = calendarRepository?.watchRemote().listen(
        (state) {
      unawaited(calendarRepository!.receive(state).catchError(
          (Object error) => debugPrint('Calendar receive failed: $error')));
    },
        onError: (Object error) =>
            debugPrint('Calendar connection unavailable: $error'));
  }

  final AttendanceRepository _repository;
  StandInDatabase? get database => _repository is LocalFirstAttendanceRepository
      ? _repository.database
      : null;
  Stream<List<AttendanceRecord>> watchSavedRecords() =>
      _repository.watchRecords();
  final PolicyEngine _engine;
  final DateTime Function() _clock;
  final bool _observeDay;
  bool _disposed = false;
  Timer? _dayTimer;
  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = _clock();
    _dayTimer =
        Timer(DateTime(now.year, now.month, now.day + 1).difference(now), () {
      refreshActiveDate();
      if (_observeDay) _scheduleDayRefresh();
    });
  }

  void refreshActiveDate() {
    final now = _clock();
    policy = _accepted?.policyAt(now) ?? policy;
    calendar = _accepted?.calendarAt(now) ?? calendar;
    summary = _engine.summarize(policy, calendar, records, now,
        policyFor: policyFor, calendarFor: calendarFor);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshActiveDate();
      if (_observeDay) _scheduleDayRefresh();
    }
  }

  AttendancePolicy policy;
  bool isCompany;
  String label(AttendanceStatus status, {DateTime? date}) =>
      attendanceStatusLabel(status,
          company: isCompany,
          oneVisit:
              (date == null ? policy : entryPolicy(date)).oneVisitFullDay);
  PersonalCalendarState? _accepted;
  late final Future<void> ready;
  Future<void> _initializeHistory() async {
    if (_repository is LocalFirstAttendanceRepository) {
      final repo = _repository;
      final org = await repo.database.getOrganization(repo.organizationId);
      if (org != null) isCompany = org.type == OrganizationType.company.name;
      if (org == null) {
        final profile = await repo.database.getUserProfile(repo.uid);
        isCompany = profile?.role == AppRole.employee.name || isCompany;
      }
    }
    await calendarRepository?.ensure(calendar, policy: policy);
    final state = await calendarRepository?.read();
    if (_repository is LocalFirstAttendanceRepository) {
      await _repository.protectHistory(
          state?.policy ?? policy, state?.calendar ?? calendar,
          policyFor: (date) => state?.policyAt(date) ?? policy,
          calendarFor: (date) => state?.calendarAt(date) ?? calendar);
    }
    if (!_disposed) notifyListeners();
  }

  AttendancePolicy policyFor(DateTime date) =>
      _accepted?.policyAt(date) ?? policy;
  AttendanceCalendar calendarFor(DateTime date) =>
      _accepted?.calendarAt(date) ?? calendar;
  bool validPlan(AttendancePlan plan) =>
      plan.policyVersionId == planningPolicyKey(policyFor(plan.date)) &&
      plan.calendarVersionId == planningCalendarKey(calendarFor(plan.date));
  String planDescription(AttendancePlan plan) {
    if (!validPlan(plan)) return 'Not counted: review plan';
    final p = policyFor(plan.date), c = calendarFor(plan.date);
    final leave = plan.status == AttendanceStatus.leave && plan.leaveUnits == 0
        ? plan.units
        : plan.leaveUnits;
    final value = _engine.contribution(
        p,
        _engine.dayType(c, plan.date),
        plan.date,
        plan.status == AttendanceStatus.leave ? 0 : plan.units,
        leave);
    if (value.credited == 0 && c.isNonWorkingDay(plan.date)) {
      return 'Not counted: holiday or day off';
    }
    if (plan.status == AttendanceStatus.leave) {
      return '${leave.toStringAsFixed(1)} ${p.basis.label(leave)} leave planned';
    }
    return '${plan.units.toStringAsFixed(1)} ${p.basis.label(plan.units)} planned${value.extraCredit > 0 ? ' | Counts toward your percentage' : ''}';
  }

  AttendancePolicy entryPolicy(DateTime date) =>
      recordFor(date)?.snapshot?.policy ?? policyFor(date);
  AttendanceCalendar calendar;
  final CalendarRepository? calendarRepository;
  StreamSubscription<PersonalCalendarState?>? _calendarSubscription;
  StreamSubscription<PersonalCalendarState?>? _remoteCalendarSubscription;
  final PlanningRepository? planningRepository;
  StreamSubscription<List<AttendancePlan>>? _planSubscription;
  List<AttendancePlan> plans = const [];
  bool hasFuturePlans({int? year, int? month}) {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final range = _engine.periodRange(policy, now);
    return plans.any((plan) =>
        !plan.isDeleted &&
        plan.date.isAfter(today) &&
        (year == null || plan.date.year == year && plan.date.month == month) &&
        (year != null ||
            range != null &&
                !plan.date.isBefore(range.start) &&
                !plan.date.isAfter(range.end)));
  }

  late final StreamSubscription<List<AttendanceRecord>> _subscription;
  List<AttendanceRecord> records = const [];
  AttendanceSummary? summary;

  Future<void> mark(AttendanceStatus status,
      {double? actualUnits,
      double? leaveUnits,
      DateTime? date,
      String? presentedRevision}) async {
    await ready;
    final selectedDate = date ?? _clock();
    final targetDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final today = _clock();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (targetDate.isAfter(todayDate)) return;
    final existing = recordFor(targetDate);
    final originalPolicy = existing?.snapshot?.policy ?? policyFor(targetDate);
    if (originalPolicy.oneVisitFullDay &&
        (status == AttendanceStatus.half ||
            status == AttendanceStatus.partial)) {
      throw ArgumentError('Choose attended or absent for this daily rule');
    }
    if (existing != null &&
        existing.snapshot == null &&
        existing.expectedUnits > 0 &&
        existing.expectedUnits != originalPolicy.fullUnit) {
      throw StateError(
          'The original attendance rules are unavailable. Your saved entry is kept; recover its original rules before correcting it.');
    }
    final range = _engine.periodRange(originalPolicy, targetDate);
    if (range == null ||
        targetDate.isBefore(range.start) ||
        targetDate.isAfter(range.end)) {
      throw ArgumentError('Choose a date in the original attendance period');
    }
    if (status == AttendanceStatus.partial &&
        (actualUnits == null ||
            actualUnits <= 0 ||
            actualUnits >= originalPolicy.fullUnit)) {
      throw ArgumentError(
          'Partial attendance must be between zero and full-day units');
    }

    await _repository.save(_engine
        .createRecord(
          date: targetDate,
          status: status,
          policy: originalPolicy,
          actualUnits: actualUnits,
          leaveUnits: leaveUnits,
          calendar: calendarFor(targetDate),
          recordedDayType: existing?.snapshot?.dayType,
        )
        .copyWith(
            policyVersionId: originalPolicy.id,
            calendarVersionId: calendarFor(targetDate).id,
            baseRevision: presentedRevision ?? existing?.fingerprint));
  }

  Future<void> plan(AttendanceStatus status, DateTime date,
      {double? units, double? leaveUnits}) async {
    await ready;
    final repository = planningRepository;
    if (repository == null) throw StateError('Planning is unavailable');
    final day = DateTime(date.year, date.month, date.day);
    final policy = policyFor(day);
    if (policy.oneVisitFullDay &&
        (status == AttendanceStatus.half ||
            status == AttendanceStatus.partial)) {
      throw ArgumentError('Choose going or not going for this daily rule');
    }
    final calendar = calendarFor(day);
    if (units != null &&
        (!units.isFinite || units < 0 || units > policy.fullUnit)) {
      throw ArgumentError('Choose units between zero and a full day');
    }
    if (status == AttendanceStatus.partial &&
        (units == null || units <= 0 || units >= policy.fullUnit)) {
      throw ArgumentError(
          'Partial plans must be between zero and full-day units');
    }
    final type = _engine.dayType(calendar, day);
    if (calendar.isNonWorkingDay(day) &&
        !(type == AttendanceDayType.holiday
            ? policy.holidayCredit
            : policy.weekOffCredit)) {
      throw ArgumentError('Choose a working day');
    }
    if (status != AttendanceStatus.full &&
        status != AttendanceStatus.half &&
        status != AttendanceStatus.partial &&
        status != AttendanceStatus.absent &&
        status != AttendanceStatus.leave) {
      throw ArgumentError('Invalid plan');
    }
    final bounded = [
      EvaluationPeriod.custom,
      EvaluationPeriod.semester,
      EvaluationPeriod.academicYear,
      EvaluationPeriod.halfYear
    ].contains(policy.evaluationPeriod);
    if (bounded &&
        (policy.startDate == null ||
            policy.endDate == null ||
            day.isBefore(DateTime(policy.startDate!.year,
                policy.startDate!.month, policy.startDate!.day)) ||
            day.isAfter(DateTime(policy.endDate!.year, policy.endDate!.month,
                policy.endDate!.day)))) {
      throw ArgumentError('Choose a date within your attendance period');
    }
    final record = _engine.createRecord(
        date: day,
        status: status,
        policy: policy,
        actualUnits: units,
        calendar: calendar,
        leaveUnits: status == AttendanceStatus.leave
            ? units ?? policy.fullUnit
            : leaveUnits);
    await repository.save(AttendancePlan(
        id: attendanceId(day, repository.organizationId, repository.scopeId),
        organizationId: repository.organizationId,
        scopeId: repository.scopeId,
        date: day,
        status: status,
        units: record.actualUnits,
        leaveUnits: record.leaveUnits,
        policyVersionId: planningPolicyKey(policy),
        calendarVersionId: planningCalendarKey(calendar)));
  }

  AttendancePlan? planFor(DateTime date) {
    for (final plan in plans) {
      if (plan.date.year == date.year &&
          plan.date.month == date.month &&
          plan.date.day == date.day) {
        return plan;
      }
    }
    return null;
  }

  Future<void> removePlan(DateTime date) =>
      planningRepository?.remove(date) ?? Future.value();

  Future<void> setHoliday(DateTime date, String? name) async {
    final repository = calendarRepository;
    if (repository == null) throw StateError('Calendar editing is unavailable');
    await repository.setHoliday(
        date,
        name == null
            ? null
            : Holiday(
                date: DateTime(date.year, date.month, date.day),
                name: name.trim().isEmpty ? 'Holiday' : name.trim()));
  }

  PlanningSummary get planningSummary =>
      _engine.summarizePlans(policy, calendar, records, plans, _clock(),
          policyFor: policyFor, calendarFor: calendarFor);
  PlanningSummary getMonthlyPlanningSummary(int year, int month) =>
      _engine.summarizePlans(
          _monthlyPolicy(year, month), calendar, records, plans, _clock(),
          year: year,
          month: month,
          policyFor: policyFor,
          calendarFor: calendarFor);

  AttendanceRecord? recordFor(DateTime date) {
    for (final record in records) {
      if (record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day) {
        return record;
      }
    }
    return null;
  }

  AttendanceSummary getMonthlySummary(int year, int month) =>
      _engine.summarizeMonth(
        _monthlyPolicy(year, month),
        calendar,
        records,
        year,
        month,
        _clock(),
        isHolidayCalendarConfigured: false,
        policyFor: policyFor,
        calendarFor: calendarFor,
      );

  @override
  void dispose() {
    _disposed = true;
    _dayTimer?.cancel();
    if (_observeDay) WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    _planSubscription?.cancel();
    _calendarSubscription?.cancel();
    _remoteCalendarSubscription?.cancel();
    super.dispose();
  }

  AttendancePolicy _monthlyPolicy(int year, int month) {
    final now = _clock();
    return policyFor(now.year == year && now.month == month
        ? now
        : DateTime(year, month + 1, 0));
  }
}
