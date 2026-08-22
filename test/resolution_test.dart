import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:drift/native.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:drift/drift.dart';

class ManualMockOrgRemote implements FirestoreOrgRemote {
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override Future<AttendancePolicy?> getPolicy(String orgId, String policyId) async => null;
  @override Future<void> putMembership(Membership membership) async {}
  @override Future<void> putOrganization(Organization org, String uid) async {}
  @override Future<Organization?> getOrganization(String orgId) async => null;
}

void main() {
  late StandInDatabase database;
  late OrganizationRepository repository;
  late ManualMockOrgRemote mockRemote;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    mockRemote = ManualMockOrgRemote();
    repository = OrganizationRepository(database, mockRemote);
  });

  tearDown(() async {
    await database.close();
  });

  group('Policy Resolution', () {
    test('Hierarchy resolution: Scope -> Parent -> Org', () async {
      // 1. Setup Org Policy
      final orgPolicy = _makePolicy(id: 'policy-global', scopeId: 'global', min: 75);
      await repository.cachePolicy('org-1', orgPolicy);

      // 2. Resolve for a scope with no policy
      // Should fallback to Org
      final resolved = await repository.getResolvedPolicy(uid: 'u1', organizationId: 'org-1', scopeId: 's1');
      expect(resolved?.minimumPercent, 75);
      expect(resolved?.scopeId, 'global');

      // 3. Setup Scope Policy
      final scopePolicy = _makePolicy(id: 'scope-s1', scopeId: 's1', min: 80);
      await repository.cachePolicy('org-1', scopePolicy);

      // 4. Resolve again
      final resolved2 = await repository.getResolvedPolicy(uid: 'u1', organizationId: 'org-1', scopeId: 's1');
      expect(resolved2?.minimumPercent, 80);
      expect(resolved2?.scopeId, 's1');
    });

    test('Personal override wins over organization policy', () async {
      final orgPolicy = _makePolicy(id: 'policy-global', scopeId: 'global', min: 75);
      await repository.cachePolicy('org-1', orgPolicy);

      // Setup Follow with personal target
      await database.upsertFollow(FollowRowsCompanion.insert(
        id: 'f1', 
        organizationId: 'org-1', 
        scopeId: 's1', 
        status: 'active', 
        followedAt: DateTime.now(),
        personalTargetPercent: const Value(90.0),
      ));

      final resolved = await repository.getResolvedPolicy(uid: 'u1', organizationId: 'org-1', scopeId: 's1', followId: 'f1');
      expect(resolved?.minimumPercent, 90);
      // Basis should still come from the cached org policy (Hours)
      expect(resolved?.basis, CalculationBasis.hours);

      // Ensure we didn't change the cached org policy
      final cached = await database.policyAt('org-1', 'global', DateTime.now());
      expect(cached?.minimumPercent, 75);
    });

    test('Personal basis override only', () async {
      final orgPolicy = _makePolicy(id: 'policy-global', scopeId: 'global', min: 75);
      await repository.cachePolicy('org-2', orgPolicy);

      await database.upsertFollow(FollowRowsCompanion.insert(
        id: 'f2', organizationId: 'org-2', scopeId: 's2', status: 'active', followedAt: DateTime.now(),
        personalBasis: const Value('days'),
        personalTargetPercent: const Value(null),
      ));

      final resolved = await repository.getResolvedPolicy(uid: 'u2', organizationId: 'org-2', scopeId: 's2', followId: 'f2');
      expect(resolved?.minimumPercent, 75);
      expect(resolved?.basis, CalculationBasis.days);
    });

    test('Both target and basis overrides', () async {
      final orgPolicy = _makePolicy(id: 'policy-global', scopeId: 'global', min: 75);
      await repository.cachePolicy('org-3', orgPolicy);

      await database.upsertFollow(FollowRowsCompanion.insert(
        id: 'f3', organizationId: 'org-3', scopeId: 's3', status: 'active', followedAt: DateTime.now(),
        personalBasis: const Value('periods'),
        personalTargetPercent: const Value(85.0),
      ));

      final resolved = await repository.getResolvedPolicy(uid: 'u3', organizationId: 'org-3', scopeId: 's3', followId: 'f3');
      expect(resolved?.minimumPercent, 85.0);
      expect(resolved?.basis, CalculationBasis.periods);
    });
  });
}

AttendancePolicy _makePolicy({
  required String id,
  required String scopeId,
  double min = 75,
}) => AttendancePolicy(
  id: id,
  version: 1,
  effectiveFrom: DateTime(2026, 1, 1),
  state: PolicyState.official,
  evaluationPeriod: EvaluationPeriod.monthly,
  minimumPercent: min,
  basis: CalculationBasis.hours,
  fullUnit: 8,
  halfUnit: 4,
  scopeId: scopeId,
);
