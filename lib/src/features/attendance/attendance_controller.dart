import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/attendance_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/policy_engine.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController(this._repository, this._engine, this.policy) {
    _subscription = _repository.watchRecords().listen((records) {
      this.records = records;
      summary = _engine.summarize(policy, records);
      notifyListeners();
    });
  }

  final AttendanceRepository _repository;
  final PolicyEngine _engine;
  final AttendancePolicy policy;
  late final StreamSubscription<List<AttendanceRecord>> _subscription;
  List<AttendanceRecord> records = const [];
  AttendanceSummary? summary;

  Future<void> mark(AttendanceStatus status, {double? actualUnits, DateTime? date}) =>
      _repository.save(_engine.createRecord(
        date: date ?? DateTime.now(),
        status: status,
        policy: policy,
        actualUnits: actualUnits,
      ));

  AttendanceRecord? recordFor(DateTime date) {
    for (final record in records) {
      if (record.date.year == date.year && record.date.month == date.month && record.date.day == date.day) return record;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
