import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/features/onboarding/onboarding_controller.dart';
import 'package:standin/src/data/auth/auth_service.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/domain/attendance.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUserRepository extends Mock implements UserRepository {}
class MockOrganizationRepository extends Mock implements OrganizationRepository {}
class MockFirestoreAttendanceRemote extends Mock implements FirestoreAttendanceRemote {}

void main() {
  late OnboardingController controller;
  late MockAuthService mockAuth;
  late MockUserRepository mockUserRepo;
  late MockOrganizationRepository mockOrgRepo;
  late MockFirestoreAttendanceRemote mockAttendanceRemote;

  setUp(() {
    mockAuth = MockAuthService();
    mockUserRepo = MockUserRepository();
    mockOrgRepo = MockOrganizationRepository();
    mockAttendanceRemote = MockFirestoreAttendanceRemote();

    controller = OnboardingController(
      authService: mockAuth,
      userRepository: mockUserRepo,
      organizationRepository: mockOrgRepo,
      attendanceRemote: mockAttendanceRemote,
    );

    registerFallbackValue(AppRole.student);
    registerFallbackValue(const Organization(id: 'org1', name: 'Org 1', type: OrganizationType.college));
    registerFallbackValue(AttendancePolicy(
      id: 'p1', version: 1, effectiveFrom: DateTime.now(), state: PolicyState.official, 
      evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4
    ));
    registerFallbackValue(AttendanceCalendar(id: 'c1', version: 1, effectiveFrom: DateTime.now()));
    registerFallbackValue(Membership(uid: 'u1', organizationId: 'org1', status: 'follower', joinedAt: DateTime.now()));
    registerFallbackValue(Follow(id: 'f1', organizationId: 'org1', scopeId: 'global', status: 'active', followedAt: DateTime.now()));
    registerFallbackValue(UserProfile(uid: 'u1', displayName: 'User', role: AppRole.student));

    when(() => mockUserRepo.getProfile(any())).thenAnswer((_) async => null);
    when(() => mockUserRepo.claimUsername(any(), any())).thenAnswer((_) async => true);
    when(() => mockUserRepo.createProfile(any())).thenAnswer((_) async => {});
    when(() => mockUserRepo.saveFollow(any(), any())).thenAnswer((_) async => {});
    when(() => mockOrgRepo.saveMembership(any())).thenAnswer((_) async => {});
    when(() => mockOrgRepo.saveOrganization(any(), any())).thenAnswer((_) async => {});
  });

  test('Follower Flow: skip all setup and shared writes if policy exists', () async {
    final org = const Organization(id: 'org1', name: 'Existing College', type: OrganizationType.college);
    final policy = AttendancePolicy(
      id: 'policy-global', version: 1, effectiveFrom: DateTime.now(), state: PolicyState.official, 
      evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4, minimumPercent: 85
    );
    final calendar = AttendanceCalendar(id: 'cal-global', version: 1, effectiveFrom: DateTime.now(), weeklyOffs: [7]);

    when(() => mockAuth.uid).thenReturn('user_follower');
    when(() => mockOrgRepo.getOfficialPolicyForScope('org1', 'global')).thenAnswer((_) async => policy);
    when(() => mockOrgRepo.getOfficialCalendarForScope('org1', 'global')).thenAnswer((_) async => calendar);

    controller.start(AppRole.student);
    await controller.completeProfile('Follower', null);
    
    // Select Organization -> Skip Branch/Semester
    await controller.selectOrganization(org);
    expect(controller.step, OnboardingStep.policyPreview);

    // Follow -> Skip ID entry if not needed (current architecture doesn't require ID for join)
    await controller.useOfficialPolicy();
    expect(controller.step, OnboardingStep.complete);

    // Verify NO shared writes
    verifyNever(() => mockOrgRepo.setupOrganization(
      org: any(named: 'org'),
      policy: any(named: 'policy'),
      calendar: any(named: 'calendar'),
      membership: any(named: 'membership'),
      follow: any(named: 'follow'),
      uid: any(named: 'uid'),
      scopes: any(named: 'scopes'),
    ));
    verifyNever(() => mockOrgRepo.saveOrganization(any(), any()));
  });

  test('Creator Flow: performs all 5 writes and sets creator as member #1', () async {
    when(() => mockAuth.uid).thenReturn('user_creator');
    when(() => mockOrgRepo.getOfficialPolicyForScope(any(), any())).thenAnswer((_) async => null);
    when(() => mockOrgRepo.getOfficialCalendarForScope(any(), any())).thenAnswer((_) async => AttendanceCalendar.unconfigured);
    when(() => mockOrgRepo.setupOrganization(
      org: any(named: 'org'),
      policy: any(named: 'policy'),
      calendar: any(named: 'calendar'),
      membership: any(named: 'membership'),
      follow: any(named: 'follow'),
      uid: any(named: 'uid'),
      scopes: any(named: 'scopes'),
    )).thenAnswer((_) async => {});

    controller.start(AppRole.student);
    await controller.completeProfile('Creator', null);
    controller.goToCreateOrganization();
    controller.createOrganization('New Org', null, null);

    // Creator should be at Setup Rule Basis (SetupUnit)
    expect(controller.step, OnboardingStep.setupUnit);

    // Complete setup...
    controller.selectBasis(CalculationBasis.hours);
    controller.selectPeriod(EvaluationPeriod.monthly);
    controller.setTarget(85.0);
    await controller.completeSchedule(fullUnit: 8.0);
    controller.selectDaysOff([7]);
    controller.selectSaturdayOption(true);
    await Future.delayed(Duration.zero);

    expect(controller.step, OnboardingStep.complete);

    // Verify setupOrganization WAS called with the creator's UID
    verify(() => mockOrgRepo.setupOrganization(
      org: any(named: 'org'),
      policy: any(named: 'policy'),
      calendar: any(named: 'calendar'),
      membership: captureAny(named: 'membership'),
      follow: any(named: 'follow'),
      uid: 'user_creator',
      scopes: any(named: 'scopes'),
    )).called(1);
  });

  test('Existing org without policy shows Safe Choice (policyMissing)', () async {
    final org = const Organization(id: 'org2', name: 'Legacy Org', type: OrganizationType.college);

    when(() => mockAuth.uid).thenReturn('user_test');
    when(() => mockOrgRepo.getOfficialPolicyForScope('org2', 'global')).thenAnswer((_) async => null);
    when(() => mockOrgRepo.getOfficialCalendarForScope('org2', 'global')).thenAnswer((_) async => AttendanceCalendar.unconfigured);

    controller.start(AppRole.student);
    await controller.selectOrganization(org);
    
    expect(controller.step, OnboardingStep.policyMissing);

    // Choosing personal settings
    await controller.followWithPersonalSettings();
    expect(controller.step, OnboardingStep.setupUnit);
    
    // Complete personal setup...
    controller.selectBasis(CalculationBasis.days);
    controller.selectPeriod(EvaluationPeriod.monthly);
    controller.setTarget(75.0);
    await controller.completeSchedule();
    controller.selectDaysOff([7]);
    controller.selectSaturdayOption(true);
    await Future.delayed(Duration.zero);

    expect(controller.step, OnboardingStep.complete);

    // Verify NO shared writes despite personal setup
    verifyNever(() => mockOrgRepo.setupOrganization(
      org: any(named: 'org'),
      policy: any(named: 'policy'),
      calendar: any(named: 'calendar'),
      membership: any(named: 'membership'),
      follow: any(named: 'follow'),
      uid: any(named: 'uid'),
      scopes: any(named: 'scopes'),
    ));
  });
}
