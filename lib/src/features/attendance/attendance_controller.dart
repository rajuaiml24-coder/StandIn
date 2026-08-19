import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/attendance_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/policy_engine.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController(this._repository, this._engine, this.policy, this.calendar) {
    _subscription = _repository.watchRecords().listen((records) {
      this.records = records;
      summary = _engine.summarize(
        policy, 
        calendar,
        records, 
        DateTime.now(),
        isHolidayCalendarConfigured: false, // Default for now
      );
      notifyListeners();
    });
  }

  final AttendanceRepository _repository;
  final PolicyEngine _engine;
  final AttendancePolicy policy;
  final AttendanceCalendar calendar;
  late final StreamSubscription<List<AttendanceRecord>> _subscription;
  List<AttendanceRecord> records = const [];
  AttendanceSummary? summary;

  Future<void> mark(AttendanceStatus status, {double? actualUnits, DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (targetDate.isAfter(todayDate)) return Future.value();

    return _repository.save(_engine.createRecord(
      date: targetDate,
      status: status,
      policy: policy,
      actualUnits: actualUnits,
    ));
  }

  AttendanceRecord? recordFor(DateTime date) {
    for (final record in records) {
      if (record.date.year == date.year && record.date.month == date.month && record.date.day == date.day) return record;
    }
    return null;
  }

  AttendanceSummary getMonthlySummary(int year, int month) =>
      _engine.summarizeMonth(
        policy,
        calendar,
        records,
        year,
        month,
        DateTime.now(),
        isHolidayCalendarConfigured: false,
      );

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
