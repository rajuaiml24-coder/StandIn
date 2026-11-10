import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:standin/src/app.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_attendance_remote.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/data/sync/sync_engine.dart';
import 'package:standin/src/data/user_repository.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/calendar_updates.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:standin/src/features/following/calendar_updates_page.dart';
import 'package:standin/src/features/onboarding/onboarding_controller.dart';

class _Onboarding extends Mock implements OnboardingController {}

const _preview = ValueKey('simplified-preview');
Future<void> _settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pumpAndSettle();
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_PREVIEWS')) return;
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
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
      await (FontLoader('Roboto')
            ..addFont(File('C:/Windows/Fonts/arial.ttf')
                .readAsBytes()
                .then((b) => ByteData.sublistView(b))))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  for (final size in [const Size(360, 780), const Size(1024, 900)]) {
    final label = size.width == 360 ? 'mobile' : 'desktop';
    testWidgets(
        'one calendar, partial defaults, future holidays and Home fit $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final db = StandInDatabase.executor(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final users = UserRepository(db, FirestoreUserRemote(firestore));
      final orgRemote = FirestoreOrgRemote(firestore);
      final orgs = OrganizationRepository(db, orgRemote);
      final now = DateTime.now();
      final planDate = DateTime(now.year, now.month, now.day + 1);
      final personalDate = DateTime(now.year, now.month, now.day + 2);
      final sharedDate = DateTime(now.year, now.month, now.day + 3);
      final policy = AttendancePolicy(
          id: 'p',
          version: 1,
          effectiveFrom: DateTime(2000),
          state: PolicyState.personal,
          evaluationPeriod: EvaluationPeriod.monthly,
          basis: CalculationBasis.hours,
          fullUnit: 8,
          halfUnit: 4,
          minimumPercent: 75);
      final calendar = AttendanceCalendar(
          id: 'c',
          version: 1,
          effectiveFrom: DateTime(2000),
          organizationId: 'org',
          scopeId: 'global',
          isConfigured: true,
          holidays: [Holiday(date: sharedDate, name: 'Shared holiday')]);
      final follow = Follow(
          id: 'f',
          organizationId: 'org',
          scopeId: 'global',
          status: 'active',
          followedAt: now);
      await users.createProfile(const UserProfile(
          uid: 'u', displayName: 'User', role: AppRole.student));
      await users.saveFollow('u', follow);
      await users.activateFollow('u', 'f');
      final org = const Organization(
          id: 'org',
          name: 'XYZ College',
          type: OrganizationType.college,
          createdBy: 'creator',
          activeCalendarId: 'c');
      await orgRemote.putOrganization(org, 'creator');
      await orgRemote.putCalendar('org', calendar);
      await orgs.saveOrganizationMetadata(org);
      final calendars =
          CalendarRepository(db, users.remote, uid: 'u', followId: 'f');
      await calendars.ensure(calendar);
      final controller = AttendanceController(
          LocalFirstAttendanceRepository(db,
              uid: 'u', organizationId: 'org', scopeId: 'global'),
          const PolicyEngine(),
          policy,
          calendar,
          planningRepository:
              PlanningRepository(db, organizationId: 'org', scopeId: 'global'),
          calendarRepository: calendars);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await tester.binding.setSurfaceSize(null);
      });
      Widget screen(Widget child) =>
          RepaintBoundary(key: _preview, child: MaterialApp(home: child));
      await tester.pumpWidget(
          screen(Scaffold(body: CalendarPage(controller: controller))));
      await _settle(tester);
      expect(find.text('As of now'), findsOneWidget);
      expect(find.text('Projected'), findsNothing);
      await tester.tap(find
          .byKey(ValueKey('calendar-day-${calendarDayKey(planDate)}'))
          .first);
      await _settle(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byKey(const ValueKey('plan-units'))).value, 4);
      expect(find.text('Partial: 4.0 hours of 8.0'), findsOneWidget);
      await _snapshot(tester, 'partial-plan-$label');
      await tester.tap(find.text('Save plan'));
      await _settle(tester);
      expect(controller.planFor(planDate)!.units, 4);
      await controller.plan(AttendanceStatus.partial, planDate, units: 3);
      await _settle(tester);
      await tester.tap(find
          .byKey(ValueKey('calendar-day-${calendarDayKey(planDate)}'))
          .first);
      await _settle(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byKey(const ValueKey('plan-units'))).value, 3);
      await tester.tap(find.text('Save plan'));
      await _settle(tester);
      await controller.plan(AttendanceStatus.partial, planDate, units: 4);
      await _settle(tester);
      await tester.tap(find
          .byKey(ValueKey('calendar-day-${calendarDayKey(personalDate)}'))
          .first);
      await _settle(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Holiday'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'My future holiday');
      await tester.tap(find.text('Save holiday'));
      await _settle(tester);
      expect(controller.calendar.holidays.map((h) => h.name),
          contains('My future holiday'));
      expect(controller.planFor(planDate)!.units, 4);
      expect(
          (await orgRemote.getCalendar('org', 'c'))!
              .holidays
              .map((h) => h.name),
          ['Shared holiday']);
      for (final date in [personalDate, sharedDate]) {
        expect(
            find.descendant(
                of: find
                    .byKey(ValueKey('calendar-day-${calendarDayKey(date)}'))
                    .first,
                matching: find.byIcon(Icons.beach_access_outlined)),
            findsOneWidget);
      }
      await _snapshot(tester, 'unified-calendar-$label');
      await tester.pumpWidget(screen(Scaffold(
          body:
              HomePage(controller: controller, onNavigateToCalendar: () {}))));
      await _settle(tester);
      expect(find.text('As of now'), findsOneWidget);
      expect(find.text('With plans'), findsOneWidget);
      await _snapshot(tester, 'simplified-home-top-$label');
      await tester.ensureVisible(find.text('Upcoming plans'));
      expect(find.text('4.0 hours planned'), findsOneWidget);
      await _snapshot(tester, 'simplified-home-$label');
      final marking =
          showMarkAttendance(tester.element(find.byType(HomePage)), controller);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byKey(const ValueKey('attendance-units'))).value, 4);
      await _snapshot(tester, 'partial-attendance-$label');
      await tester.tap(find.text('Save attendance'));
      await _settle(tester);
      await marking;
      await controller.mark(AttendanceStatus.partial, actualUnits: 3);
      await _settle(tester);
      final editing =
          showMarkAttendance(tester.element(find.byType(HomePage)), controller);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byKey(const ValueKey('attendance-units'))).value, 3);
      await tester.tap(find.text('Save attendance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save correction'));
      await _settle(tester);
      await editing;
      final sync = SyncEngine(db, FirestoreAttendanceRemote(firestore),
          users.remote, orgRemote, orgs,
          uid: 'u');
      final session = UserSession(
          uid: 'u',
          database: db,
          userRepo: users,
          orgRepo: orgs,
          syncEngine: sync,
          onboardingController: _Onboarding());
      await tester.pumpWidget(screen(DashboardShell(
          session: session,
          controller: controller,
          policy: policy,
          calendar: calendar,
          followRow: (await db.getFollow('f'))!)));
      await _settle(tester);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Following'), findsNothing);
      await tester.tap(find.text('Profile'));
      await _settle(tester);
      expect(find.text('XYZ College'), findsOneWidget);
      expect(find.text('Edit shared calendar'), findsNothing);
      await _snapshot(tester, 'simplified-profile-$label');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('per-date update review fits $label and keeps personal edits',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final db = StandInDatabase.executor(NativeDatabase.memory());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await tester.binding.setSurfaceSize(null);
      });
      final repo = CalendarRepository(
          db, FirestoreUserRemote(FakeFirebaseFirestore()),
          uid: 'u', followId: 'f');
      final day = DateTime(DateTime.now().year, 12, 25);
      final calendar = AttendanceCalendar(
          id: 'c',
          version: 1,
          effectiveFrom: DateTime(2000),
          organizationId: 'org',
          scopeId: 'global',
          isConfigured: true,
          holidays: [Holiday(date: day, name: 'Original')]);
      await repo.ensure(calendar);
      await repo.setHoliday(day, Holiday(date: day, name: 'My holiday'));
      final state = (await repo.read())!;
      final revision = CalendarRevision(
          id: 'r1',
          version: 1,
          author: 'creator',
          calendar: calendar,
          changes: {
            calendarDayKey(day): Holiday(date: day, name: 'Proposed').toJson(),
            calendarDayKey(DateTime(day.year, 12, 26)):
                Holiday(date: DateTime(day.year, 12, 26), name: 'New holiday')
                    .toJson()
          });
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: _preview,
              child: CalendarReviewPage(
                  repository: repo, presented: state, revision: revision))));
      await _settle(tester);
      expect(
          find.text('Applying replaces your personal edit.'), findsOneWidget);
      await tester.tap(find.text('Apply all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep mine').first);
      await tester.pumpAndSettle();
      await _snapshot(tester, 'calendar-review-$label');
      await tester.ensureVisible(find.text('Save choices'));
      await tester.tap(find.text('Save choices'));
      await _settle(tester);
      expect((await repo.read())!.reviewedVersion, 1);
      expect((await repo.read())!.calendar.holidays.map((h) => h.name),
          containsAll(['My holiday', 'New holiday']));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
