import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/sync/sync_engine.dart';
import 'package:standin/src/features/onboarding/onboarding_controller.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:standin/src/data/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';

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
  late SyncEngine syncEngine;

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
    );

    syncEngine = SyncEngine(
      database, 
      FirestoreAttendanceRemote(firestore), 
      uid: 'test_uid_123',
      connectivity: mockConnectivity,
    );
  });

  setUpAll(() {
    registerFallbackValue(auth.GoogleAuthProvider.credential(accessToken: 'a', idToken: 'b'));
  });

  tearDown(() async {
    await database.close();
  });

  test('E2E Logical Flow: Google Login -> Signup -> Org -> Attendance -> Sync', () async {
    print('STEP 0: Google Sign-In');
    expect(onboarding.step, OnboardingStep.welcome);
    await onboarding.signInWithGoogle();
    expect(onboarding.step, OnboardingStep.roleSelection);
    expect(onboarding.displayName, 'Test User');

    print('STEP 1: Profile Setup');
    await onboarding.completeProfile('Test User Renamed', '9876543210');
    expect(onboarding.displayName, 'Test User Renamed');
    expect(onboarding.mobile, '9876543210');

    print('STEP 2: Username Uniqueness (Logical)');
    // Onboarding generated a suggestion
    expect(onboarding.username, isNotNull);
    final isAvailable = await onboarding.checkUsernameAvailability(onboarding.username!);
    expect(isAvailable, true);

    print('STEP 3: Organization Creation');
    final policy = AttendancePolicy(
      id: 'p1', version: 1, effectiveFrom: DateTime.now(), 
      state: PolicyState.official, evaluationPeriod: EvaluationPeriod.monthly, 
      minimumPercent: 75, basis: CalculationBasis.hours, fullUnit: 8, halfUnit: 4
    );
    onboarding.start(AppRole.student);
    onboarding.createOrganization('Test College', 'Computer Science', policy);
    expect(onboarding.selectedOrganization?.name, 'Test College');

    print('STEP 4: Following & Membership');
    // Pre-seed organization in Firestore (since createOrganization in controller is currently mock-heavy)
    await firestore.collection('organizations').doc(onboarding.selectedOrganization!.id).set({
      'name': 'Test College',
      'type': 'college',
    });

    await onboarding.followOrganization();
    
    // Verify Local Drift state
    final localProfile = await userRepo.getProfile('test_uid_123');
    expect(localProfile?.displayName, 'Test User Renamed');
    expect(localProfile?.activeFollowId, isNotNull);
    
    final followId = localProfile!.activeFollowId!;
    final localFollow = await database.getFollow(followId);
    expect(localFollow, isNotNull);
    expect(localFollow!.organizationId, onboarding.selectedOrganization!.id);

    print('STEP 5: Attendance Creation (Local-First)');
    final attendanceRepo = LocalFirstAttendanceRepository(
      database, uid: 'test_uid_123', 
      organizationId: onboarding.selectedOrganization!.id, 
      scopeId: onboarding.selectedOrganization!.id
    );
    final attendanceController = AttendanceController(attendanceRepo, const PolicyEngine(), policy);
    
    await attendanceController.mark(AttendanceStatus.full, date: DateTime(2026, 8, 10));
    
    // Verify Drift
    final records = await attendanceRepo.watchRecords().first;
    expect(records.length, 1);
    expect(records.first.status, AttendanceStatus.full);
    expect(records.first.pendingSync, true);

    print('STEP 6: Background Sync');
    await syncEngine.syncNow();
    
    // Verify Firestore
    final remoteDocs = await firestore.collection('users').doc('test_uid_123').collection('attendance').get();
    expect(remoteDocs.docs.length, 1);
    expect(remoteDocs.docs.first.data()['status'], 'full');

    print('STEP 7: App Restart Recovery');
    // Simulate re-initializing with same database
    final newSyncEngine = SyncEngine(
      database, 
      FirestoreAttendanceRemote(firestore), 
      uid: 'test_uid_123',
      connectivity: mockConnectivity,
    );
    final newRecords = await attendanceRepo.watchRecords().first;
    expect(newRecords.length, 1);

    print('STEP 8: Offline Attendance -> Sync');
    // Mark another day while "offline" (simply don't call sync yet)
    await attendanceController.mark(AttendanceStatus.absent, date: DateTime(2026, 8, 11));
    
    // Verify Drift has both
    final localRecords = await attendanceRepo.watchRecords().first;
    expect(localRecords.length, 2);
    
    // Sync now
    await newSyncEngine.syncNow();
    
    // Verify Firestore has both
    final finalRemoteDocs = await firestore.collection('users').doc('test_uid_123').collection('attendance').get();
    expect(finalRemoteDocs.docs.length, 2);

    print('STEP 9: Two-User Isolation');
    final userBFirestore = firestore; // Same instance
    final userBRepo = UserRepository(database, FirestoreUserRemote(userBFirestore));
    await userBRepo.createProfile(const UserProfile(uid: 'user_b', displayName: 'User B', role: AppRole.student));
    
    // User B marks attendance for SAME org
    final userBAttendanceRepo = LocalFirstAttendanceRepository(
      database, uid: 'user_b', 
      organizationId: onboarding.selectedOrganization!.id, 
      scopeId: onboarding.selectedOrganization!.id
    );
    await userBAttendanceRepo.save(AttendanceRecord(
      date: DateTime(2026, 8, 10), 
      status: AttendanceStatus.half, 
      actualUnits: 4, 
      expectedUnits: 8
    ));

    final syncEngineB = SyncEngine(
      database, 
      FirestoreAttendanceRemote(firestore), 
      uid: 'user_b',
      connectivity: mockConnectivity,
    );
    await syncEngineB.syncNow();

    // Verify User A and User B records are isolated in Firestore
    final userADocs = await firestore.collection('users').doc('test_uid_123').collection('attendance').get();
    final userBDocs = await firestore.collection('users').doc('user_b').collection('attendance').get();
    
    expect(userADocs.docs.length, 2);
    expect(userBDocs.docs.length, 1);
    expect(userADocs.docs.any((d) => d.id.contains('user_b')), false);

    print('SUCCESS: E2E Logical Flow complete');
  });
}
