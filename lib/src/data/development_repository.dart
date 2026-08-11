import 'dart:async';

import '../domain/attendance.dart';
import 'attendance_repository.dart';

/// Local-only seed data used until Firebase and Drift platform configuration is supplied.
class DevelopmentAttendanceRepository implements AttendanceRepository {
  final _records = <AttendanceRecord>[];
  final _changes = StreamController<List<AttendanceRecord>>.broadcast();

  DevelopmentAttendanceRepository() {
    final now = DateTime.now();
    for (var i = 1; i < 9; i++) {
      final day = now.subtract(Duration(days: i));
      _records.add(AttendanceRecord(
        date: day,
        status: i == 3 ? AttendanceStatus.half : AttendanceStatus.full,
        actualUnits: i == 3 ? 3.5 : 7,
        expectedUnits: 7,
      ));
    }
  }

  @override
  Stream<List<AttendanceRecord>> watchRecords() async* {
    yield List.unmodifiable(_records);
    yield* _changes.stream;
  }

  @override
  Future<void> save(AttendanceRecord record) async {
    _records.removeWhere((item) => _sameDay(item.date, record.date));
    _records.add(record);
    _changes.add(List.unmodifiable(_records));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
