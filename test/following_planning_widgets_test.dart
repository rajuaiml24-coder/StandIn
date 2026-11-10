import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/app.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:standin/src/features/following/following_page.dart';
import 'package:standin/src/features/following/rules_editor_page.dart';
import 'package:standin/src/features/profile/profile_page.dart';

const previewKey = ValueKey('preview');
Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_PREVIEWS')) return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(previewKey));
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/widget-previews').create(recursive: true);
    await File('build/widget-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('WRITE_PREVIEWS')) {
      final font = File('C:/Windows/Fonts/arial.ttf');
      if (await font.exists()) {
        await (FontLoader('Roboto')
              ..addFont(font
                  .readAsBytes()
                  .then((bytes) => ByteData.sublistView(bytes))))
            .load();
        await (FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
            .load();
      }
    }
  });
  for (final size in [const Size(360, 780), const Size(1024, 900)]) {
    final label = size.width == 360 ? 'mobile' : 'desktop';
    testWidgets('profile editing and private custom calculation fit $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final database = StandInDatabase.executor(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      var databaseClosed = false;
      final users = UserRepository(database, FirestoreUserRemote(firestore));
      final organizations =
          OrganizationRepository(database, FirestoreOrgRemote(firestore));
      await users.createProfile(const UserProfile(
          uid: 'user',
          displayName: 'Student name',
          mobile: '9876543210',
          role: AppRole.student));
      addTearDown(() async {
        if (!databaseClosed) await database.close();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: previewKey,
              child: Scaffold(
                  body: ProfileView(
                      uid: 'user',
                      database: database,
                      users: users,
                      organizations: organizations,
                      onManageFollowing: () {},
                      onLogout: () {},
                      onDeleteAccount: () {})))));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pumpAndSettle();
      expect(find.text('SHARED ATTENDANCE RULES'), findsNothing);
      expect(find.text('MY ATTENDANCE SETTINGS'), findsNothing);
      await preview(tester, 'profile-$label');
      expect(find.text('Manage following'), findsNothing);
      expect(find.text('Choose organization'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Updated name');
      await tester.enterText(find.byType(TextFormField).at(1), '0012-CSC');
      await tester.enterText(find.byType(TextFormField).at(2), '');
      await tester.tap(find.text('Save profile'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pumpAndSettle();
      final profile = await users.getProfile('user');
      expect(profile!.displayName, 'Updated name');
      expect(profile.mobile, isNull);
      expect(profile.registrationNumber, '0012-CSC');
      await tester.tap(find.text('Calculation settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom calculation'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Save rules'), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Save rules'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save rules'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pumpAndSettle();
      expect((await users.getProfile('user'))!.activeFollowId,
          'personal-calculation');
      final calculation = await database.getFollow('personal-calculation');
      expect(calculation!.organizationId, 'personal:user');
      expect(calculation.personalTargetPercent, 75);
      expect((await firestore.collection('organizations').get()).docs, isEmpty);
      expect(tester.takeException(), isNull);
      final closing = database.close();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => closing);
      databaseClosed = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    testWidgets('planning calendar is interactive and fits $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final database = StandInDatabase.executor(NativeDatabase.memory());
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + 1);
      final policy = AttendancePolicy(
          id: 'p',
          version: 1,
          effectiveFrom: DateTime(2000),
          state: PolicyState.community,
          evaluationPeriod: EvaluationPeriod.monthly,
          basis: CalculationBasis.days,
          fullUnit: 1,
          halfUnit: .5,
          minimumPercent: 75);
      final calendar = AttendanceCalendar(
          id: 'c',
          version: 1,
          effectiveFrom: DateTime(2000),
          weeklyOffs: [],
          isConfigured: true);
      final controller = AttendanceController(
          LocalFirstAttendanceRepository(database,
              uid: 'u', organizationId: 'org', scopeId: 'csc'),
          const PolicyEngine(),
          policy,
          calendar,
          planningRepository: PlanningRepository(database,
              organizationId: 'org', scopeId: 'csc'));
      addTearDown(() async {
        controller.dispose();
        await database.close();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: previewKey,
              child: Scaffold(body: CalendarPage(controller: controller)))));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      expect(find.text('As of now'), findsOneWidget);
      expect(find.text('With plans'), findsNothing);
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      await preview(tester, 'planning-$label');
      expect(tester.takeException(), isNull);
      if (date.month != now.month) {
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();
      }
      await tester.tap(find
          .byKey(ValueKey(
              'calendar-day-${date.toIso8601String().substring(0, 10)}'))
          .first);
      await tester.pumpAndSettle();
      expect(find.text('${date.day} ${monthName(date.month)} ${date.year}'),
          findsOneWidget);
      await preview(tester, 'plan-sheet-$label');
      await tester.tap(find.text('Save plan'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      expect(
          await tester
              .runAsync(() => database.select(database.attendanceTable).get()),
          isEmpty);
      expect(
          await tester.runAsync(
              () => database.select(database.attendancePlanRows).get()),
          hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('group discovery and personal rule editor fit $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final database = StandInDatabase.executor(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final remote = FirestoreOrgRemote(firestore);
      final organizations = OrganizationRepository(database, remote);
      final users = UserRepository(database, FirestoreUserRemote(firestore));
      addTearDown(() async {
        await database.close();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.runAsync(() async {
        await remote.putOrganization(
            const Organization(
                id: 'org',
                name: 'XYZ College of Engineering and Technology',
                type: OrganizationType.college),
            'creator');
        await users.createProfile(const UserProfile(
            uid: 'u', displayName: 'User', role: AppRole.student));
      });
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: previewKey,
              child: Scaffold(
                  body: FollowingPage(
                      database: database,
                      userRepository: users,
                      organizationRepository: organizations,
                      uid: 'u')))));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      expect(find.text('XYZ College of Engineering and Technology'),
          findsOneWidget);
      await preview(tester, 'following-$label');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: previewKey,
              child: RulesEditorPage(
                  title: 'My attendance rules',
                  calendar: AttendanceCalendar.unconfigured,
                  onSave: (_) async {}))));
      await tester.pumpAndSettle();
      await preview(tester, 'rules-$label');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
