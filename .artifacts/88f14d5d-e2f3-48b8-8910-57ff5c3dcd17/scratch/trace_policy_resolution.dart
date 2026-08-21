
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}

void main() {
  test('Trace Policy Resolution for Follower', () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final remote = MockFirestoreOrgRemote();
    final repo = OrganizationRepository(db, remote);

    final orgId = 'org1';
    final policyId = 'policy1';
    
    // 1. Seed Official Policy in Drift (simulating cache from selectOrganization)
    final officialPolicy = AttendancePolicy(
      id: policyId,
      version: 1,
      effectiveFrom: DateTime.now().subtract(const Duration(minutes: 1)),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.semester,
      minimumPercent: 85.0,
      basis: CalculationBasis.hours,
      fullUnit: 8.0,
      halfUnit: 4.0,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 30),
      organizationId: orgId,
    );
    await repo.cachePolicy(orgId, officialPolicy);

    // 2. Seed Follow record (simulating followOrganization)
    final followId = 'f1';
    await db.upsertFollow(FollowRowsCompanion.insert(
      id: followId,
      organizationId: orgId,
      scopeId: 'global',
      status: 'active',
      followedAt: DateTime.now(),
      // Follower flow currently sets personalEvaluationPeriod but NOT personalTargetPercent
      personalEvaluationPeriod: Value(EvaluationPeriod.semester.name),
      personalBasis: Value(CalculationBasis.hours.name),
      personalTargetPercent: const Value(null),
      isPersonalCalendarConfigured: const Value(false),
    ));

    // 3. Resolve Policy for Home Screen
    final resolved = await repo.getResolvedPolicy(
      uid: 'u1',
      organizationId: orgId,
      scopeId: 'global',
      followId: followId,
    );

    print('Resolved Policy ID: ${resolved?.id}');
    print('Resolved Target: ${resolved?.minimumPercent}');
    print('Resolved Period: ${resolved?.evaluationPeriod}');
    print('Resolved Start Date: ${resolved?.startDate}');
    
    expect(resolved?.minimumPercent, 85.0);
    expect(resolved?.evaluationPeriod, EvaluationPeriod.semester);
    expect(resolved?.startDate, isNotNull);

    await db.close();
  });
}
