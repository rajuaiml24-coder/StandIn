import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}

void main() {
  late StandInDatabase database;
  late MockFirestoreOrgRemote mockRemote;
  late OrganizationRepository repository;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    mockRemote = MockFirestoreOrgRemote();
    repository = OrganizationRepository(database, mockRemote);
  });

  tearDown(() async {
    await database.close();
  });

  group('Hierarchy Resolution Logic', () {
    test('Resolves rules: Semester > Branch > Org', () async {
      const orgId = 'org1';
      const branchId = 'branch1';
      const semId = 'sem1';

      // 1. Setup Org Rules
      final orgPolicy = AttendancePolicy(
        id: 'p-org', version: 1, effectiveFrom: DateTime.now(),
        state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly,
        basis: CalculationBasis.hours, fullUnit: 7.0, halfUnit: 3.5, minimumPercent: 75,
        organizationId: orgId, scopeId: 'global'
      );
      
      // Save only Org rule initially
      await repository.setupOrganization(
        org: Organization(id: orgId, name: 'Uni', type: OrganizationType.college),
        policy: orgPolicy,
        calendar: AttendanceCalendar(id: 'c-org', version: 1, effectiveFrom: DateTime.now(), isConfigured: true),
        membership: Membership(uid: 'u1', organizationId: orgId, status: 'f', joinedAt: DateTime.now()),
        follow: Follow(id: 'f1', organizationId: orgId, scopeId: semId, status: 'a', followedAt: DateTime.now()),
        uid: 'u1',
      );

      // Resolve for Semester (should fall back to Org)
      var resolved = await repository.getResolvedPolicy(uid: 'u1', organizationId: orgId, scopeId: semId);
      expect(resolved?.id, 'p-org');

      // 2. Add Branch Rules
      final branchPolicy = orgPolicy.copyWith(id: 'p-branch', scopeId: branchId, minimumPercent: 80);
      await database.savePolicy(OrganizationPolicyRowsCompanion.insert(
        policyId: 'p-branch', organizationId: orgId, scopeId: branchId,
        version: 1, effectiveFrom: DateTime.now(), state: 'official',
        evaluationPeriod: 'monthly', minimumPercent: const Value(80),
        calculationBasis: 'hours', fullUnit: 7.0, halfUnit: 3.5, updatedAt: DateTime.now()
      ));
      
      // Link Semester to Branch
      await database.upsertScope(ScopeRowsCompanion.insert(
        id: semId, organizationId: orgId, parentId: const Value(branchId), type: 'semester', name: 'Sem 1'
      ));

      // Resolve for Semester (should fall back to Branch)
      resolved = await repository.getResolvedPolicy(uid: 'u1', organizationId: orgId, scopeId: semId);
      expect(resolved?.id, 'p-branch');
      expect(resolved?.minimumPercent, 80);

      // 3. Add Semester Rules
      await database.savePolicy(OrganizationPolicyRowsCompanion.insert(
        policyId: 'p-sem', organizationId: orgId, scopeId: semId,
        version: 1, effectiveFrom: DateTime.now(), state: 'official',
        evaluationPeriod: 'monthly', minimumPercent: const Value(85),
        calculationBasis: 'hours', fullUnit: 7.0, halfUnit: 3.5, updatedAt: DateTime.now()
      ));

      // Resolve for Semester (should use Semester directly)
      resolved = await repository.getResolvedPolicy(uid: 'u1', organizationId: orgId, scopeId: semId);
      expect(resolved?.id, 'p-sem');
      expect(resolved?.minimumPercent, 85);
    });
  });
}
