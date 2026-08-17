import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';

void main() {
  group('Scope Identity & Normalization', () {
    test('Normalizes names correctly (trim, case, internal spaces)', () {
      expect(Scope.normalizeName('CSE'), 'cse');
      expect(Scope.normalizeName('  cse  '), 'cse');
      expect(Scope.normalizeName('Computer   Science'), 'computer science');
      expect(Scope.normalizeName('C S E'), 'c s e'); // Preserves meaningful internal spaces
    });

    test('Generates deterministic IDs', () {
      final id1 = Scope.generateId('org1', 'branch', 'CSE');
      final id2 = Scope.generateId('org1', 'branch', '  cse  ');
      final id3 = Scope.generateId('org1', 'branch', 'C S E');
      
      expect(id1, 'org1_branch_cse');
      expect(id2, 'org1_branch_cse');
      expect(id1, id2);
      expect(id3, 'org1_branch_c s e');
      expect(id1, isNot(id3));
    });

    test('Differentiates same scope names under different parents', () {
      final idA = Scope.generateId('org1', 'semester', 'Sem 3', 'branch_A');
      final idB = Scope.generateId('org1', 'semester', 'Sem 3', 'branch_B');
      
      expect(idA, isNot(idB));
      expect(idA.contains('branch_A'), true);
      expect(idB.contains('branch_B'), true);
    });
  });
}
