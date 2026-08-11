import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/validators.dart';

void main() {
  group('NameValidator', () {
    final validator = NameValidator();
    test('valid name', () => expect(validator.validate('John Doe').isValid, isTrue));
    test('too short', () => expect(validator.validate('J').isValid, isFalse));
    test('too long', () => expect(validator.validate('a' * 51).isValid, isFalse));
    test('empty', () => expect(validator.validate('').isValid, isFalse));
    test('invalid characters', () => expect(validator.validate('John123').isValid, isFalse));
  });

  group('MobileValidator', () {
    final validator = MobileValidator();
    test('valid mobile', () => expect(validator.validate('9876543210').isValid, isTrue));
    test('too short', () => expect(validator.validate('987654321').isValid, isFalse));
    test('too long', () => expect(validator.validate('98765432101').isValid, isFalse));
    test('invalid characters', () => expect(validator.validate('987654321a').isValid, isFalse));
  });

  group('PinValidator', () {
    final validator = PinValidator();
    test('valid pin', () => expect(validator.validate('1234').isValid, isTrue));
    test('too short', () => expect(validator.validate('123').isValid, isFalse));
    test('too long', () => expect(validator.validate('12345').isValid, isFalse));
    test('invalid characters', () => expect(validator.validate('123a').isValid, isFalse));
  });

  group('UsernameValidator', () {
    final validator = UsernameValidator();
    test('valid username', () => expect(validator.validate('john_doe.01').isValid, isTrue));
    test('too short', () => expect(validator.validate('jo').isValid, isFalse));
    test('too long', () => expect(validator.validate('john_doe_very_long').isValid, isFalse));
    test('invalid characters', () => expect(validator.validate('john@doe').isValid, isFalse));
  });

  group('IdValidator', () {
    final validator = IdValidator();
    test('valid roll number', () => expect(validator.validate('2024-CS-01').isValid, isTrue));
    test('too short', () => expect(validator.validate('12').isValid, isFalse));
    test('too long', () => expect(validator.validate('a' * 21).isValid, isFalse));
    test('invalid characters', () => expect(validator.validate('Roll!123').isValid, isFalse));
  });

  group('OrganizationNameValidator', () {
    final validator = OrganizationNameValidator();
    test('valid name', () => expect(validator.validate('Stanford University').isValid, isTrue));
    test('too short', () => expect(validator.validate('SU').isValid, isFalse));
    test('too long', () => expect(validator.validate('a' * 101).isValid, isFalse));
  });
}
