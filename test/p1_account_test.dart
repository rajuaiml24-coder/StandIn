import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/data/auth/auth_service.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/sync/sync_engine.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/features/onboarding/onboarding_controller.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}

class MockUser extends Mock implements auth.User {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late StandInDatabase database;
  late FakeFirebaseFirestore firestore;
  late FirestoreUserRemote remote;
  late FirestoreAttendanceRemote attendance;
  late UserRepository userRepository;
  late MockAuthService authService;
  late MockSyncEngine sync;
  late OrganizationRepository organizations;
  late OnboardingController controller;

  const profile =
      UserProfile(uid: 'user', displayName: 'Name', role: AppRole.student);

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    remote = FirestoreUserRemote(firestore);
    attendance = FirestoreAttendanceRemote(firestore);
    userRepository = UserRepository(database, remote);
    authService = MockAuthService();
    sync = MockSyncEngine();
    organizations =
        OrganizationRepository(database, FirestoreOrgRemote(firestore));
    when(() => authService.uid).thenReturn('user');
    when(() => authService.reauthenticateWithGoogle()).thenAnswer((_) async {});
    when(() => authService.deleteCurrentUser()).thenAnswer((_) async {});
    when(() => sync.stop()).thenAnswer((_) async {});
    controller = OnboardingController(
        authService: authService,
        userRepository: userRepository,
        organizationRepository: organizations,
        attendanceRemote: attendance,
        syncEngine: sync);
  });
  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test(
      'profile creation is non-admin and retries preserve role, creation time and admin flags',
      () async {
    await remote.createUserProfile(profile);
    final reference = firestore.collection('users').doc('user');
    final created = (await reference.get()).data()!;
    expect(created['isAdmin'], isFalse);
    await reference
        .update({'isAdmin': true, 'isVerified': true, 'role': 'employee'});
    await remote.createUserProfile(const UserProfile(
        uid: 'user',
        displayName: 'Updated',
        role: AppRole.student,
        activeFollowId: 'follow'));
    final updated = (await reference.get()).data()!;
    expect(updated['displayName'], 'Updated');
    expect(updated['activeFollowId'], 'follow');
    expect(updated['role'], 'employee');
    expect(updated['createdAt'], created['createdAt']);
    expect(updated['isAdmin'], isTrue);
    expect(updated['isVerified'], isTrue);
  });

  test(
      'username claims are case-insensitive, idempotent and cannot overwrite another user',
      () async {
    await remote.claimUsername('UserName', 'user');
    await remote.claimUsername('USERNAME', 'user');
    await expectLater(
        remote.claimUsername('username', 'other'), throwsStateError);
    expect(
        (await firestore.collection('usernames').doc('username').get())
            .data()!['uid'],
        'user');
  });

  test('cancelling reauthentication prevents remote or local deletion',
      () async {
    await userRepository.createProfile(profile);
    await remote.createUserProfile(profile);
    when(() => authService.reauthenticateWithGoogle())
        .thenThrow(StateError('Account deletion cancelled'));
    expect(await controller.deleteAccount(), isFalse);
    expect(controller.error, contains('cancelled'));
    expect(await database.getUserProfile('user'), isNotNull);
    expect(
        (await firestore.collection('users').doc('user').get()).exists, isTrue);
    verifyNever(() => sync.stop());
    verifyNever(() => authService.deleteCurrentUser());
  });

  test('native Google sign-in cancellation is reported by AuthService',
      () async {
    final firebaseAuth = MockFirebaseAuth();
    final google = MockGoogleSignIn();
    when(() => firebaseAuth.currentUser).thenReturn(MockUser());
    when(() => google.signIn()).thenAnswer((_) async => null);
    final service =
        AuthService(firebaseAuth, MockStorage(), googleSignIn: google);
    await expectLater(service.reauthenticateWithGoogle(), throwsStateError);
  });

  test(
      'membership removal errors stop deletion and preserve the remaining account',
      () async {
    await remote.createUserProfile(profile);
    await remote.putFollow(
        'user',
        Follow(
            id: 'follow',
            organizationId: 'org',
            scopeId: 'global',
            status: 'active',
            followedAt: DateTime(2000)));
    final failingOrganizations = MockOrganizationRepository();
    when(() => failingOrganizations.removeMembership('org', 'user'))
        .thenThrow(StateError('Permission denied'));
    final failingController = OnboardingController(
        authService: authService,
        userRepository: userRepository,
        organizationRepository: failingOrganizations,
        attendanceRemote: attendance,
        syncEngine: sync);
    expect(await failingController.deleteAccount(), isFalse);
    expect(failingController.error, contains('Permission denied'));
    expect(
        (await firestore.collection('users').doc('user').get()).exists, isTrue);
    expect(await remote.getFollows('user'), hasLength(1));
    verifyNever(() => authService.deleteCurrentUser());
    verify(() => sync.start()).called(1);
    failingController.dispose();
  });

  test(
      'account deletion stops sync, clears personal data and preserves shared organizations',
      () async {
    await remote.createUserProfile(profile);
    await userRepository.createProfile(profile);
    await firestore
        .collection('organizations')
        .doc('org')
        .set({'name': 'Shared', 'followerCount': 1});
    await firestore
        .collection('organizations')
        .doc('org')
        .collection('members')
        .doc('user')
        .set({'status': 'follower'});
    await remote.putFollow(
        'user',
        Follow(
            id: 'follow',
            organizationId: 'org',
            scopeId: 'global',
            status: 'active',
            followedAt: DateTime(2000)));
    await remote.claimUsername('username', 'user');
    final localAttendance = LocalFirstAttendanceRepository(database,
        uid: 'user', organizationId: 'org', scopeId: 'global');
    await localAttendance.save(AttendanceRecord(
        date: DateTime(2026, 1, 1),
        status: AttendanceStatus.full,
        actualUnits: 7,
        expectedUnits: 7));
    var stopped = false;
    when(() => sync.stop()).thenAnswer((_) async => stopped = true);
    when(() => authService.deleteCurrentUser()).thenAnswer((_) async {
      expect(stopped, isTrue);
      expect((await firestore.collection('users').doc('user').get()).exists,
          isFalse);
      expect(await database.select(database.syncQueueRows).get(), isEmpty);
      expect(await database.select(database.attendanceTable).get(), isEmpty);
    });
    expect(await controller.deleteAccount(), isTrue);
    final org =
        (await firestore.collection('organizations').doc('org').get()).data()!;
    expect(org['name'], 'Shared');
    expect(org['followerCount'], 0);
    expect(
        (await firestore
                .collection('organizations')
                .doc('org')
                .collection('members')
                .doc('user')
                .get())
            .exists,
        isFalse);
    expect(await remote.getFollows('user'), isEmpty);
    expect((await firestore.collection('usernames').get()).docs, isEmpty);
    expect(await database.getUserProfile('user'), isNull);
    verifyNever(() => sync.start());
  });

  test('deletion includes a membership whose follow has not uploaded',
      () async {
    await remote.createUserProfile(profile);
    await firestore
        .collection('organizations')
        .doc('org')
        .set({'name': 'Shared', 'followerCount': 1});
    await firestore
        .collection('organizations')
        .doc('org')
        .collection('members')
        .doc('user')
        .set({'status': 'follower'});
    await organizations.saveMembership(Membership(
        uid: 'user',
        organizationId: 'org',
        status: 'follower',
        joinedAt: DateTime(2000)));
    expect(await remote.getFollows('user'), isEmpty);
    expect(await controller.deleteAccount(), isTrue);
    expect(
        (await firestore
                .collection('organizations')
                .doc('org')
                .collection('members')
                .doc('user')
                .get())
            .exists,
        isFalse);
    expect(
        (await firestore.collection('organizations').doc('org').get())
            .data()!['followerCount'],
        0);
  });

  test('large attendance and follow histories are deleted in multiple batches',
      () async {
    for (var offset = 0; offset < 901; offset += 200) {
      final batch = firestore.batch();
      for (var i = offset; i < offset + 200 && i < 901; i++) {
        batch.set(
            firestore
                .collection('users')
                .doc('user')
                .collection('attendance')
                .doc('$i'),
            {'date': Timestamp.fromDate(DateTime(2026, 1, 1))});
        batch.set(
            firestore
                .collection('users')
                .doc('user')
                .collection('follows')
                .doc('$i'),
            {'organizationId': 'org'});
      }
      await batch.commit();
    }
    await remote.createUserProfile(profile);
    await attendance.deleteAllAttendance('user');
    await remote.deleteProfile('user');
    expect(
        (await firestore
                .collection('users')
                .doc('user')
                .collection('attendance')
                .get())
            .docs,
        isEmpty);
    expect(
        (await firestore
                .collection('users')
                .doc('user')
                .collection('follows')
                .get())
            .docs,
        isEmpty);
    expect((await firestore.collection('users').doc('user').get()).exists,
        isFalse);
  });
}
