import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';

void main() {
  test('attendance IDs are stable for idempotent per-day cloud writes', () {
    final first = attendanceId('user-1', 'org-1', DateTime(2026, 8, 10, 8));
    final second = attendanceId('user-1', 'org-1', DateTime(2026, 8, 10, 21));
    expect(first, 'user-1-org-1-20260810');
    expect(second, first);
  });

  test('attendance IDs change across organization history', () {
    expect(
      attendanceId('user-1', 'org-a', DateTime(2026, 8, 10)),
      isNot(attendanceId('user-1', 'org-b', DateTime(2026, 8, 10))),
    );
  });
}
