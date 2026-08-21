
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}

void main() {
  test('Policy resolution fails if clock is slightly behind', () async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final remote = MockFirestoreOrgRemote();
    final repo = OrganizationRepository(db, remote);

    final orgId = 'org1';
    
    // 1. Creator creates policy at 10:00:05
    final creatorTime = DateTime(2026, 1, 1, 10, 0, 5);
    final officialPolicy = AttendancePolicy(
      id: 'policy1',
      version: 1,
      effectiveFrom: creatorTime,
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.monthly,
      minimumPercent: 85.0,
      basis: CalculationBasis.hours,
      fullUnit: 8.0,
      halfUnit: 4.0,
      organizationId: orgId,
    );
    await repo.cachePolicy(orgId, officialPolicy);

    // 2. Follower tries to resolve at 10:00:00 (due to clock skew or rapid local transition)
    final followerTime = DateTime(2026, 1, 1, 10, 0, 0);
    
    // Simulate getResolvedPolicy logic but with controlled time
    // First, let's see if policyAt finds it
    final cached = await db.policyAt(orgId, 'global', followerTime);
    print('Cached policy at follower time: ${cached?.policyId}');
    
    expect(cached, isNull); // This confirms the failure mode

    await db.close();
  });
}
