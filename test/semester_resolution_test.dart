import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' hide isNotNull;

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}

void main() {
  late StandInDatabase database;
  late MockFirestoreOrgRemote mockRemote;
  late OrganizationRepository repository;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    mockRemote = MockFirestoreOrgRemote();
    repository = OrganizationRepository(database, mockRemote);
    when(() => mockRemote.getPolicy(any(), any())).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await database.close();
  });

  group('Semester Resolution E2E', () {
    test('Resolves Semester rules when following a specific Semester', () async {
      const orgId = 'college_1';
      const semId = 'semester_3';
      
      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);

      // 1. Save a Semester Policy in local DB (simulating synced or created policy)
      await database.savePolicy(OrganizationPolicyRowsCompanion.insert(
        policyId: 'p1',
        organizationId: orgId,
        scopeId: semId,
        version: 1,
        effectiveFrom: DateTime(2026, 1, 1),
        state: 'official',
        evaluationPeriod: 'semester',
        minimumPercent: const Value(75.0),
        calculationBasis: 'periods',
        fullUnit: 1.0,
        halfUnit: 0.5,
        startDate: Value(startDate),
        endDate: Value(endDate),
        updatedAt: DateTime.now(),
      ));

      // 2. Resolve policy for this semester
      final policy = await repository.getResolvedPolicy(
        uid: 'user1', 
        organizationId: orgId, 
        scopeId: semId
      );

      expect(policy, isNotNull);
      expect(policy!.evaluationPeriod, EvaluationPeriod.semester);
      expect(policy.startDate, startDate);
      expect(policy.endDate, endDate);
      expect(policy.basis, CalculationBasis.periods);
    });
  });
}
