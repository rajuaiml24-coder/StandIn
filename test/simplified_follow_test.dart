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
  });

  test('Student following existing college should skip branch/semester and reach Dashboard', () async {
    final org = const Organization(id: 'org1', name: 'Swarnaandhra', type: OrganizationType.college);
    final policy = AttendancePolicy(
      id: 'p1', version: 1, effectiveFrom: DateTime.now(), state: PolicyState.official, 
      evaluationPeriod: EvaluationPeriod.monthly, basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4, minimumPercent: 85
    );
    final calendar = AttendanceCalendar(id: 'cal-global', version: 1, effectiveFrom: DateTime.now(), weeklyOffs: [7]);

    when(() => mockAuth.uid).thenReturn('user_b');
    when(() => mockOrgRepo.getOfficialPolicyForScope('org1', 'global')).thenAnswer((_) async => policy);
    when(() => mockOrgRepo.getOfficialCalendarForScope('org1', 'global')).thenAnswer((_) async => calendar);

    // 0. Start and Profile
    controller.start(AppRole.student);
    await controller.completeProfile('Student B', null);

    // 1. Select Organization
    await controller.selectOrganization(org);
    
    // Should be at Policy Preview
    expect(controller.step, OnboardingStep.policyPreview);
    expect(controller.officialPolicy?.minimumPercent, 85);

    // 2. Follow
    await controller.useOfficialPolicy();

    // Verify error and step
    expect(controller.error, isNull);
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

    // Verify user-specific writes
    verify(() => mockUserRepo.saveFollow('user_b', any())).called(1);
    verify(() => mockOrgRepo.saveMembership(any())).called(1);
  });

  test('Existing org without official policy should allow personal setup without shared writes', () async {
    final org = const Organization(id: 'org2', name: 'Legacy College', type: OrganizationType.college);

    when(() => mockAuth.uid).thenReturn('user_c');
    when(() => mockOrgRepo.getOfficialPolicyForScope('org2', 'global')).thenAnswer((_) async => null);
    when(() => mockOrgRepo.getOfficialCalendarForScope('org2', 'global')).thenAnswer((_) async => AttendanceCalendar.unconfigured);

    // 0. Start and Profile
    controller.start(AppRole.student);
    await controller.completeProfile('Student C', null);

    // 1. Select Organization
    await controller.selectOrganization(org);
    
    // Should be at Setup Unit (Personal)
    expect(controller.step, OnboardingStep.setupUnit);

    // Complete personal setup
    controller.selectBasis(CalculationBasis.days);
    controller.selectPeriod(EvaluationPeriod.monthly);
    controller.setTarget(75.0);
    await controller.completeSchedule();
    controller.selectDaysOff([7]);
    controller.selectSaturdayOption(true);
    await Future.delayed(Duration.zero);

    // Verify error and step
    expect(controller.error, isNull);
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
  });

  test('Personal calendar changes should be independent (Initialization Check)', () async {
    const org = Organization(id: 'org1', name: 'College', type: OrganizationType.college);
    final calendar = AttendanceCalendar(id: 'cal-global', version: 1, effectiveFrom: DateTime.now(), weeklyOffs: [7], offSaturdays: [2, 4]);

    when(() => mockAuth.uid).thenReturn('user_d');
    when(() => mockOrgRepo.getOfficialPolicyForScope(any(), any())).thenAnswer((_) async => null);
    when(() => mockOrgRepo.getOfficialCalendarForScope(any(), any())).thenAnswer((_) async => calendar);

    controller.start(AppRole.student);
    await controller.completeProfile('Student D', null);
    await controller.selectOrganization(org);
    
    // Complete personal setup...
    controller.selectBasis(CalculationBasis.hours);
    controller.selectPeriod(EvaluationPeriod.monthly);
    controller.setTarget(75.0);
    await controller.completeSchedule();
    
    await controller.followOrganization();

    final capturedFollow = verify(() => mockUserRepo.saveFollow('user_d', captureAny())).captured.first as Follow;
    expect(capturedFollow.personalWeeklyOffs, '[7]');
    expect(capturedFollow.personalOffSaturdays, '[2,4]');
  });

  test('New organization creator can still complete full setup with all writes', () async {
    when(() => mockAuth.uid).thenReturn('creator_1');
    when(() => mockOrgRepo.saveOrganization(any(), any())).thenAnswer((_) async => {});
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
    controller.createOrganization('New College', 'Main', null);
    
    // Skip branch/semester/ID for creator
    controller.selectBranch(null);
    controller.selectSemester(null);
    await controller.completeOrganizationId('C123');

    // Complete setup...
    controller.selectBasis(CalculationBasis.hours);
    controller.selectPeriod(EvaluationPeriod.monthly);
    controller.setTarget(85.0);
    await controller.completeSchedule();
    controller.selectDaysOff([7]);
    controller.selectSaturdayOption(true);
    await Future.delayed(Duration.zero); // Await the un-awaited followOrganization call

    expect(controller.error, isNull);
    expect(controller.step, OnboardingStep.complete);

    // Verify setupOrganization WAS called
    verify(() => mockOrgRepo.setupOrganization(
      org: any(named: 'org'),
      policy: any(named: 'policy'),
      calendar: any(named: 'calendar'),
      membership: any(named: 'membership'),
      follow: any(named: 'follow'),
      uid: 'creator_1',
      scopes: any(named: 'scopes'),
    )).called(1);
  });
}
