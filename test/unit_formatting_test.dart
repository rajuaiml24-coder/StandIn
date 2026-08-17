import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';

void main() {
  group('CalculationBasis Label Formatting', () {
    test('Handles Periods (Classes) correctly', () {
      expect(CalculationBasis.periods.label(1.0), 'class');
      expect(CalculationBasis.periods.label(2.0), 'classes');
      expect(CalculationBasis.periods.label(0.0), 'classes');
      expect(CalculationBasis.periods.label(-1.0), 'class');
    });

    test('Handles Hours correctly', () {
      expect(CalculationBasis.hours.label(1.0), 'hour');
      expect(CalculationBasis.hours.label(7.5), 'hours');
      expect(CalculationBasis.hours.label(0.0), 'hours');
    });

    test('Handles Days correctly', () {
      expect(CalculationBasis.days.label(1.0), 'day');
      expect(CalculationBasis.days.label(5.0), 'days');
    });
  });
}
