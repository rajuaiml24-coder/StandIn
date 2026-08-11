import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';

void main() {
  final policy = AttendancePolicy(
    id: 'policy-v1', version: 1, effectiveFrom: DateTime(2026, 1, 1),
    minimumPercent: 75, basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4,
  );
  const engine = PolicyEngine();

  test('calculates safe-to-miss time without counting holidays', () {
    final result = engine.summarize(policy, [
      AttendanceRecord(date: DateTime(2026, 1, 1), status: AttendanceStatus.full, actualUnits: 8, expectedUnits: 8),
      AttendanceRecord(date: DateTime(2026, 1, 2), status: AttendanceStatus.holiday, actualUnits: 0, expectedUnits: 0),
    ]);
    expect(result.percent, 100);
    expect(result.isSafe, isTrue);
    expect(result.safeToMiss, closeTo(2.6667, .001));
  });

  test('calculates recovery time when below the policy threshold', () {
    final result = engine.summarize(policy, [
      AttendanceRecord(date: DateTime(2026, 1, 1), status: AttendanceStatus.absent, actualUnits: 0, expectedUnits: 8),
    ]);
    expect(result.isSafe, isFalse);
    expect(result.unitsToRecover, 24);
  });
}
