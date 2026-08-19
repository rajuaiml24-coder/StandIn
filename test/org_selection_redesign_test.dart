import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/features/onboarding/onboarding_controller.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:standin/src/data/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';

class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}
class MockUser extends Mock implements auth.User {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAttendanceRemote extends Mock implements FirestoreAttendanceRemote {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StandInDatabase database;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late UserRepository userRepo;
  late OrganizationRepository orgRepo;
  late OnboardingController onboarding;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user_tester');
    
    userRepo = UserRepository(database, FirestoreUserRemote(firestore));
    orgRepo = OrganizationRepository(database, FirestoreOrgRemote(firestore));
    
    onboarding = OnboardingController(
      authService: AuthService(mockAuth, MockSecureStorage()),
      userRepository: userRepo,
      organizationRepository: orgRepo,
      attendanceRemote: MockAttendanceRemote(),
    );
  });

  tearDown(() async => await database.close());

  group('Organization Selection Redesign', () {
    test('Requirement C/D: Anonymous Creator ID is deterministic and private', () {
      const uid1 = 'user_12345';
      const uid2 = 'user_67890';
      
      final org1 = Organization(
        id: 'org1', name: 'Org 1', type: OrganizationType.college, createdBy: uid1
      );
      final org1Again = Organization(
        id: 'org1_alt', name: 'Org 1 Alt', type: OrganizationType.college, createdBy: uid1
      );
      final org2 = Organization(
        id: 'org2', name: 'Org 2', type: OrganizationType.college, createdBy: uid2
      );

      // Deterministic
      expect(org1.anonymousCreatorId, org1Again.anonymousCreatorId);
      expect(org1.anonymousCreatorId, isNot(org2.anonymousCreatorId));
      
      // Format USR-XXXXXX (6 chars after USR-)
      expect(org1.anonymousCreatorId, startsWith('USR-'));
      expect(org1.anonymousCreatorId.length, 10);
      
      // Privacy: UID is not in the anonymous ID
      expect(org1.anonymousCreatorId, isNot(contains(uid1)));
    });

    test('Requirement A/B/I: Resolution using activePolicyId and Follow association', () async {
      const orgId = 'org_custom_policy';
      const creatorUid = 'creator_456';
      
      // 1. Setup Org in Firestore with custom policy ID
      final orgData = {
        'name': 'Custom Policy Org',
        'type': 'college',
        'createdBy': creatorUid,
        'activePolicyId': 'policy-2026-v2',
        'activeCalendarId': 'cal-2026-v2',
        'name_lowercase': 'custom policy org',
        'name_tokens': ['custom', 'policy', 'org'],
      };
      await firestore.collection('organizations').doc(orgId).set(orgData);

      final policyData = {
        'version': 2,
        'effectiveFrom': DateTime(2026, 6, 1),
        'state': 'official',
        'evaluationPeriod': 'academicYear',
        'minimumPercent': 85.0,
        'basis': 'hours',
        'fullUnit': 8.0,
        'halfUnit': 4.0,
        'weeklyOffs': [7],
      };
      await firestore.collection('organizations').doc(orgId).collection('policies').doc('policy-2026-v2').set(policyData);

      final calData = {
        'version': 2,
        'effectiveFrom': DateTime(2026, 6, 1),
        'weeklyOffs': [7],
        'offSaturdays': [2, 4],
        'holidays': [],
        'isConfigured': true,
      };
      await firestore.collection('organizations').doc(orgId).collection('calendars').doc('cal-2026-v2').set(calData);

      // 2. Search and Select
      onboarding.start(AppRole.student);
      final results = await onboarding.searchOrganizations('Custom');
      expect(results.first.id, orgId);
      expect(results.first.activePolicyId, 'policy-2026-v2');
      expect(results.first.anonymousCreatorId, isNotEmpty);

      await onboarding.selectOrganization(results.first);
      expect(onboarding.step, OnboardingStep.policyPreview);
      expect(onboarding.officialPolicy?.id, 'policy-2026-v2');
      expect(onboarding.officialPolicy?.minimumPercent, 85.0);
      expect(onboarding.officialCalendar?.id, 'cal-2026-v2');
      expect(onboarding.officialCalendar?.offSaturdays, [2, 4]);

      // 3. Follow
      await onboarding.useOfficialPolicy();
      if (onboarding.error != null) {
        print('Follow Error: ${onboarding.error}');
      }
      expect(onboarding.step, OnboardingStep.complete);

      // 4. Verify DB association
      final profile = await userRepo.getProfile('user_tester');
      final follow = await database.getFollow(profile!.activeFollowId!);
      expect(follow?.organizationId, orgId);
      
      final resolved = await orgRepo.getResolvedPolicy(
        uid: 'user_tester', 
        organizationId: orgId, 
        scopeId: 'global',
        followId: profile.activeFollowId
      );
      expect(resolved?.id, 'policy-2026-v2');
      expect(resolved?.minimumPercent, 85.0);
    });

    test('Requirement F/G: Role filtering remains intact', () async {
      await firestore.collection('organizations').doc('col1').set({
        'name': 'College A', 
        'type': 'college', 
        'name_lowercase': 'college a',
        'name_tokens': ['college', 'a'],
      });
      await firestore.collection('organizations').doc('com1').set({
        'name': 'Company B', 
        'type': 'company', 
        'name_lowercase': 'company b',
        'name_tokens': ['company', 'b'],
      });

      // Student -> Colleges only
      onboarding.start(AppRole.student);
      final studentResults = await onboarding.searchOrganizations('College');
      expect(studentResults.any((o) => o.type == OrganizationType.college), isTrue);
      expect(studentResults.any((o) => o.type == OrganizationType.company), isFalse);

      // Employee -> Companies only
      onboarding = OnboardingController(
        authService: AuthService(mockAuth, MockSecureStorage()),
        userRepository: userRepo,
        organizationRepository: orgRepo,
        attendanceRemote: MockAttendanceRemote(),
      );
      onboarding.start(AppRole.employee);
      final empResults = await onboarding.searchOrganizations('Company');
      expect(empResults.any((o) => o.type == OrganizationType.company), isTrue);
      expect(empResults.any((o) => o.type == OrganizationType.college), isFalse);
    });

    test('Requirement H: Missing policy proper state', () async {
      const orgId = 'org_no_policy';
      await firestore.collection('organizations').doc(orgId).set({
        'name': 'No Policy Org',
        'type': 'college',
        'name_lowercase': 'no policy org',
        'followerCount': 5,
        'createdBy': 'creator123',
      });

      onboarding.start(AppRole.student);
      final results = await onboarding.searchOrganizations('No Policy');
      await onboarding.selectOrganization(results.first);

      expect(onboarding.step, OnboardingStep.policyPreview);
      expect(onboarding.officialPolicy, isNull);
      expect(onboarding.selectedOrganization?.followerCount, 5);
    });

    test('Requirement B/F/L: Popular organizations and follower count', () async {
      // 1. Setup multiple organizations with different follower counts
      await firestore.collection('organizations').doc('pop1').set({
        'name': 'Popular A', 'type': 'college', 'followerCount': 100, 'name_lowercase': 'popular a'
      });
      await firestore.collection('organizations').doc('pop2').set({
        'name': 'Popular B', 'type': 'college', 'followerCount': 200, 'name_lowercase': 'popular b'
      });
      await firestore.collection('organizations').doc('pop3').set({
        'name': 'Popular C', 'type': 'company', 'followerCount': 150, 'name_lowercase': 'popular c'
      });

      onboarding.start(AppRole.student);
      
      // Empty query should return popular colleges sorted by followerCount
      final results = await onboarding.searchOrganizations('');
      expect(results.length, 2);
      expect(results[0].name, 'Popular B'); // 200 followers
      expect(results[1].name, 'Popular A'); // 100 followers
      
      // 2. Test Creator Follower Count
      onboarding.createOrganization('New Org', null, null);
      onboarding.selectBasis(CalculationBasis.hours);
      onboarding.selectPeriod(EvaluationPeriod.monthly);
      onboarding.setTarget(85.0);
      await onboarding.completeSchedule(fullUnit: 8.0);
      onboarding.selectDaysOff([7]);
      onboarding.selectSaturdayOption(false, specificSaturdays: [2, 4]);
      
      final newOrgId = onboarding.selectedOrganization!.id;
      final localOrg = await database.getOrganization(newOrgId);
      expect(localOrg?.followerCount, 1);
      
      // 3. Test Follower Increment
      onboarding = OnboardingController(
        authService: AuthService(mockAuth, MockSecureStorage()),
        userRepository: userRepo,
        organizationRepository: orgRepo,
        attendanceRemote: MockAttendanceRemote(),
      );
      onboarding.start(AppRole.student);
      final searchRes = await onboarding.searchOrganizations('Popular B');
      await onboarding.selectOrganization(searchRes.first);
      await onboarding.useOfficialPolicy();
      
      final updatedPop2 = await firestore.collection('organizations').doc('pop2').get();
      expect(updatedPop2.data()?['followerCount'], 201);
      
      final localPop2 = await database.getOrganization('pop2');
      expect(localPop2?.followerCount, 201);
    });
    test('Requirement: Inherit vs Customize period on Follow', () async {
      const orgId = 'org_period_test';
      await firestore.collection('organizations').doc(orgId).set({
        'name': 'Period Org',
        'type': 'college',
        'name_lowercase': 'period org',
        'activePolicyId': 'p-default',
      });
      await firestore.collection('organizations').doc(orgId).collection('policies').doc('p-default').set({
        'version': 1,
        'effectiveFrom': DateTime(2026),
        'state': 'official',
        'evaluationPeriod': 'monthly',
        'basis': 'hours',
        'fullUnit': 8.0,
        'halfUnit': 4.0,
        'minimumPercent': 85.0,
        'weeklyOffs': [7],
      });

      // Scenario 1: Keep default period -> Zero click finish
      onboarding.start(AppRole.student);
      final org = (await onboarding.searchOrganizations('Period')).first;
      await onboarding.selectOrganization(org);
      expect(onboarding.evaluationPeriod, EvaluationPeriod.monthly);
      
      await onboarding.useOfficialPolicy();
      expect(onboarding.step, OnboardingStep.complete);

      // Scenario 2: Customize period -> Final setups
      onboarding = OnboardingController(
        authService: AuthService(mockAuth, MockSecureStorage()),
        userRepository: userRepo,
        organizationRepository: orgRepo,
        attendanceRemote: MockAttendanceRemote(),
      );
      onboarding.start(AppRole.student);
      await onboarding.selectOrganization(org);
      onboarding.selectPeriod(EvaluationPeriod.semester);
      
      await onboarding.useOfficialPolicy();
      expect(onboarding.step, OnboardingStep.setupTarget); // Should go to Target setup
      
      await onboarding.setTarget(90.0);
      // Since it's semester, it should go to Dates
      expect(onboarding.step, OnboardingStep.setupDates);
      
      await onboarding.setDates(DateTime(2026, 6, 1), DateTime(2026, 12, 31));
      expect(onboarding.step, OnboardingStep.complete);

      // Scenario 3: Customize period to Monthly (No dates needed) -> Setup Target then finish
      onboarding = OnboardingController(
        authService: AuthService(mockAuth, MockSecureStorage()),
        userRepository: userRepo,
        organizationRepository: orgRepo,
        attendanceRemote: MockAttendanceRemote(),
      );
      onboarding.start(AppRole.student);
      // Change org to have Semester default
      await firestore.collection('organizations').doc('org_sem').set({
        'name': 'Semester Org', 'type': 'college', 'activePolicyId': 'p-sem',
      });
      await firestore.collection('organizations').doc('org_sem').collection('policies').doc('p-sem').set({
        'version': 1, 'effectiveFrom': DateTime(2026), 'state': 'official', 
        'evaluationPeriod': 'semester', 'basis': 'hours', 'fullUnit': 8.0, 'halfUnit': 4.0, 'minimumPercent': 85.0, 'weeklyOffs': [7],
      });
      
      final orgSem = (await onboarding.searchOrganizations('Semester')).first;
      await onboarding.selectOrganization(orgSem);
      expect(onboarding.evaluationPeriod, EvaluationPeriod.semester);
      
      onboarding.selectPeriod(EvaluationPeriod.monthly);
      await onboarding.useOfficialPolicy();
      expect(onboarding.step, OnboardingStep.setupTarget);
      
      await onboarding.setTarget(80.0);
      expect(onboarding.step, OnboardingStep.complete); // Finish after target because Monthly doesn't need dates
    });
  });
}
