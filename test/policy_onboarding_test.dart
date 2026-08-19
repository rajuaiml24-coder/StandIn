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
    when(() => mockUser.uid).thenReturn('user_123');
    
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

  test('Scenario A: Existing Official Policy found', () async {
    const orgId = 'org_official';
    final officialPolicy = AttendancePolicy(
      id: 'official-p1', version: 1, effectiveFrom: DateTime.now(), 
      state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly, 
      minimumPercent: 80, basis: CalculationBasis.days, fullUnit: 1, halfUnit: 0.5
    );

    // Pre-seed official policy
    await orgRepo.cachePolicy(orgId, officialPolicy);
    
    onboarding.start(AppRole.student);
    await onboarding.selectOrganization(const Organization(id: orgId, name: 'Official Org', type: OrganizationType.college));
    await onboarding.completeOrganizationId('ID-123');

    expect(onboarding.step, OnboardingStep.policyPreview);
    expect(onboarding.officialPolicy?.id, 'official-p1');
    
    await onboarding.followOrganization();
    expect(onboarding.step, OnboardingStep.complete);
    
    final resolvedPolicy = await orgRepo.getResolvedPolicy(uid: 'user_123', organizationId: orgId, scopeId: orgId);
    expect(resolvedPolicy?.minimumPercent, 80);
    expect(resolvedPolicy?.state, PolicyState.official);

    final resolvedCalendar = await orgRepo.getResolvedCalendar(uid: 'user_123', organizationId: orgId, scopeId: orgId);
    expect(resolvedCalendar.isConfigured, isFalse); // Not pre-seeded in this test
  });

  test('Scenario E: Conflict Resolution - Personal exists, then follow Official', () async {
    const orgId = 'org_conflict';
    
    // 1. Setup Personal tracking first
    onboarding.start(AppRole.student);
    await onboarding.selectOrganization(const Organization(id: orgId, name: 'Conflict Org', type: OrganizationType.college));
    await onboarding.completeOrganizationId('ID-1');
    
    onboarding.selectBasis(CalculationBasis.hours);
    onboarding.selectPeriod(EvaluationPeriod.weekly);
    onboarding.setTarget(70.0);
    await onboarding.completeSchedule(fullUnit: 8.0);
    onboarding.selectDaysOff([7]); // Sunday
    onboarding.selectSaturdayOption(false); // Saturday working
    expect(onboarding.step, OnboardingStep.complete);

    // 2. Official policy appears later
    final officialPolicy = AttendancePolicy(
      id: 'official-p2', version: 1, effectiveFrom: DateTime.now(), 
      state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly, 
      minimumPercent: 85, basis: CalculationBasis.days, fullUnit: 1, halfUnit: 0.5
    );
    await orgRepo.cachePolicy(orgId, officialPolicy);

    // Reset onboarding manually instead of logout() to avoid channel issues in unit test
    onboarding = OnboardingController(
      authService: AuthService(mockAuth, MockSecureStorage()),
      userRepository: userRepo,
      organizationRepository: orgRepo,
      attendanceRemote: MockAttendanceRemote(),
    );
    onboarding.start(AppRole.student);
    await onboarding.selectOrganization(const Organization(id: orgId, name: 'Conflict Org', type: OrganizationType.college));
    await onboarding.completeOrganizationId('ID-1');

    // Should detect conflict because personal settings exist in Drift for this follow
    expect(onboarding.step, OnboardingStep.policyConflict);

    // 3. Choose Official
    await onboarding.useOfficialPolicy();
    expect(onboarding.step, OnboardingStep.complete);
    
    final profile = await userRepo.getProfile('user_123');
    final resolved = await orgRepo.getResolvedPolicy(
      uid: 'user_123', 
      organizationId: orgId, 
      scopeId: orgId, 
      followId: profile!.activeFollowId
    );
    // Official should win after choice
    expect(resolved?.minimumPercent, 85);
    expect(resolved?.state, PolicyState.official);
  });
}
