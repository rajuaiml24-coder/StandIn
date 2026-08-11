import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/attendance_repository.dart';

void main() {
  test('attendance IDs are stable for idempotent per-day cloud writes', () {
    final first = attendanceId(DateTime(2026, 8, 10, 8), 'org-1', 'scope-1');
    final second = attendanceId(DateTime(2026, 8, 10, 21), 'org-1', 'scope-1');
    expect(first, '2026-08-10_org-1_scope-1');
    expect(second, first);
  });

  test('attendance IDs change across organization history', () {
    expect(
      attendanceId(DateTime(2026, 8, 10), 'org-a', 'scope-1'),
      isNot(attendanceId(DateTime(2026, 8, 10), 'org-b', 'scope-1')),
    );
  });
}
