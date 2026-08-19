import 'dart:convert';
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

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:google_sign_in/google_sign_in.dart';

class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}
class MockUser extends Mock implements auth.User {}
class MockUserCredential extends Mock implements auth.UserCredential {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockConnectivity extends Mock implements Connectivity {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockAttendanceRemote extends Mock implements FirestoreAttendanceRemote {}

void main() {
  late StandInDatabase database;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockConnectivity mockConnectivity;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleAccount;
  late MockGoogleSignInAuthentication mockGoogleAuth;
  late AuthService authService;
  late UserRepository userRepo;
  late OrganizationRepository orgRepo;
  late OnboardingController onboarding;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockConnectivity = MockConnectivity();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleAccount = MockGoogleSignInAccount();
    mockGoogleAuth = MockGoogleSignInAuthentication();
    
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_uid_123');
    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUserCredential.user).thenReturn(mockUser);
    when(() => mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
    
    when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
    when(() => mockGoogleAccount.authentication).thenAnswer((_) async => mockGoogleAuth);
    when(() => mockGoogleAuth.accessToken).thenReturn('fake_access_token');
    when(() => mockGoogleAuth.idToken).thenReturn('fake_id_token');
    when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => mockUserCredential);

    authService = AuthService(mockAuth, MockSecureStorage(), googleSignIn: mockGoogleSignIn);
    userRepo = UserRepository(database, FirestoreUserRemote(firestore));
    orgRepo = OrganizationRepository(database, FirestoreOrgRemote(firestore));
    
    onboarding = OnboardingController(
      authService: authService,
      userRepository: userRepo,
      organizationRepository: orgRepo,
      attendanceRemote: MockAttendanceRemote(),
    );
  });

  setUpAll(() {
    registerFallbackValue(auth.GoogleAuthProvider.credential(accessToken: 'a', idToken: 'b'));
  });

  tearDown(() async {
    await database.close();
  });

  test('E2E Logical Flow: Google Login -> Signup -> Org -> Setup -> Home', () async {
    // STEP 0: Google Sign-In
    expect(onboarding.step, OnboardingStep.welcome);
    await onboarding.signInWithGoogle();
    
    // In production, StandInApp would now replace the controller with a session-aware one.
    // We simulate this by creating a new controller for the authenticated state.
    final authOnboarding = OnboardingController(
      authService: authService,
      userRepository: userRepo,
      organizationRepository: orgRepo,
      attendanceRemote: MockAttendanceRemote(),
      initialStep: OnboardingStep.roleSelection,
    );
    expect(authOnboarding.step, OnboardingStep.roleSelection);
    expect(authOnboarding.displayName, ''); // New user starts with empty display name in controller

    // STEP 1: Profile Setup
    authOnboarding.start(AppRole.student);
    await authOnboarding.completeProfile('Test User Renamed', '9876543210');
    expect(authOnboarding.displayName, 'Test User Renamed');
    expect(authOnboarding.mobile, '9876543210');

    // STEP 2: Username Uniqueness (Logical)
    expect(authOnboarding.username, isNotNull);
    final isAvailable = await authOnboarding.checkUsernameAvailability(authOnboarding.username!);
    expect(isAvailable, true);
    authOnboarding.confirmUsername();

    // STEP 3: Organization Creation
    authOnboarding.goToCreateOrganization();
    authOnboarding.createOrganization('Test College', 'Computer Science', null);
    expect(authOnboarding.selectedOrganization?.name, 'Test College');

    // STEP 4: Identification & Policy Detection
    await authOnboarding.completeOrganizationId('TEST-ID-1');
    // Since it's a new org, it should branch to setupUnit
    expect(authOnboarding.step, OnboardingStep.setupUnit);

    // STEP 5: Progressive Policy Setup
    authOnboarding.selectBasis(CalculationBasis.hours);
    expect(authOnboarding.step, OnboardingStep.setupPeriod);
    
    authOnboarding.selectPeriod(EvaluationPeriod.monthly);
    expect(authOnboarding.step, OnboardingStep.setupTarget);
    
    authOnboarding.setTarget(75.0);
    expect(authOnboarding.step, OnboardingStep.setupSchedule);
    
    await authOnboarding.completeSchedule(fullUnit: 8.0);
    expect(authOnboarding.step, OnboardingStep.setupDaysOff);

    authOnboarding.selectDaysOff([7]); // Sunday off
    expect(authOnboarding.step, OnboardingStep.setupSaturday);

    authOnboarding.selectSaturdayOption(false, specificSaturdays: [2, 4]); // 2nd & 4th Sat off
    expect(authOnboarding.step, OnboardingStep.complete);
    
    // Wait for async followOrganization to complete
    while (authOnboarding.isLoading) {
      await Future.delayed(Duration.zero);
    }
    
    // STEP 6: Verify Local Drift state
    final localProfile = await userRepo.getProfile('test_uid_123');
    expect(localProfile?.activeFollowId, isNotNull);
    
    final followId = localProfile!.activeFollowId!;
    final localFollow = await database.getFollow(followId);
    expect(localFollow, isNotNull);
    expect(localFollow!.personalBasis, CalculationBasis.hours.name);
    expect(localFollow.personalTargetPercent, 75.0);
    expect(localFollow.personalOffSaturdays, jsonEncode([2, 4]));

    // SUCCESS: E2E Logical Flow complete
  });
}
