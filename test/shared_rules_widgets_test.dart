import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/app.dart';
import 'package:standin/src/data/calendar_repository.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/local_first_attendance_repository.dart';
import 'package:standin/src/data/planning_repository.dart';
import 'package:standin/src/data/remote/firestore_user_remote.dart';
import 'package:standin/src/domain/attendance.dart';
import 'package:standin/src/domain/policy_engine.dart';
import 'package:standin/src/domain/shared_rules.dart';
import 'package:standin/src/features/attendance/attendance_controller.dart';
import 'package:standin/src/features/following/rules_editor_page.dart';
import 'package:standin/src/features/following/shared_rules_page.dart';

const previewKey = ValueKey('rules-preview');
final p = AttendancePolicy(
    id: 'p',
    version: 1,
    effectiveFrom: DateTime(2000),
    organizationId: 'org',
    scopeId: 'global',
    state: PolicyState.community,
    evaluationPeriod: EvaluationPeriod.monthly,
    basis: CalculationBasis.hours,
    fullUnit: 8,
    halfUnit: 4,
    minimumPercent: 85,
    leaveTreatment: LeaveTreatment.countsTowardTarget,
    weekOffCredit: true);
final c = AttendanceCalendar(
    id: 'c',
    version: 1,
    effectiveFrom: DateTime(2000),
    organizationId: 'org',
    scopeId: 'global',
    weeklyOffs: const [6, 7],
    isConfigured: true);
Future<void> settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_PREVIEWS')) return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(previewKey));
    final img = await boundary.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/widget-previews').create(recursive: true);
    await File('build/widget-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    img.dispose();
  });
}

Widget wrap(Widget page) => RepaintBoundary(
    key: previewKey,
    child: MaterialApp(
        key: UniqueKey(),
        theme: ThemeData(useMaterial3: true),
        initialRoute: '/screen',
        routes: {'/': (_) => const Scaffold(), '/screen': (_) => page}));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('WRITE_PREVIEWS')) {
      await (FontLoader('Roboto')
            ..addFont(File('C:/Windows/Fonts/arial.ttf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes))))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  for (final size in [const Size(360, 780), const Size(1024, 900)]) {
    final label = size.width == 360 ? 'mobile' : 'desktop';
    testWidgets('full rules editor and follower consent fit $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      RulesDraft? saved;
      await tester.pumpWidget(wrap(RulesEditorPage(
          title: 'Shared rules',
          policy: p,
          calendar: c,
          saveLabel: 'Review changes',
          onSave: (draft) async {
            saved = draft;
          })));
      await tester.pumpAndSettle();
      await screenshot(tester, 'shared-rules-top-$label');
      await tester.scrollUntilVisible(
          find.text('Count attendance on days off'), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await screenshot(tester, 'shared-rules-credit-$label');
      await tester.ensureVisible(find.text('Count attendance on holidays'));
      await tester.tap(find.text('Count attendance on holidays'));
      await tester.ensureVisible(find.text('Review changes'));
      await tester.tap(find.text('Review changes'));
      await tester.pumpAndSettle();
      expect(saved!.holidayCredit, true);
      expect(saved!.leaveTreatment, LeaveTreatment.countsTowardTarget);
      expect(tester.takeException(), isNull);

      final db = StandInDatabase.executor(NativeDatabase.memory());
      addTearDown(db.close);
      final calendars = CalendarRepository(
          db, FirestoreUserRemote(FakeFirebaseFirestore()),
          uid: 'u', followId: 'f');
      await calendars.ensure(c, policy: p);
      final state = (await calendars.read())!;
      final before = SharedRules(p, c),
          next = before.apply({
            'weekOffCredit': false,
            'holidayCredit': true,
            'minimumPercent': 80
          });
      final revision = RuleRevision(
          id: 'r',
          version: 1,
          author: 'owner',
          before: before,
          rules: next,
          effectiveDate: DateTime.now().subtract(const Duration(days: 3)),
          changes: next.changesFrom(before));
      await tester.pumpWidget(wrap(RuleReviewPage(
          repository: calendars, presented: state, revision: revision)));
      await settle(tester);
      await tester.tap(find.text('Apply all'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Applies from'), findsOneWidget);
      await screenshot(tester, 'shared-rule-review-$label');
      await tester.scrollUntilVisible(find.text('Save choices'), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Save choices'));
      await settle(tester);
      final result = (await calendars.read())!;
      expect(result.policyAt(DateTime.now())!.minimumPercent, 85);
      expect(result.policyAt(DateTime(2100))!.minimumPercent, 80);
      expect(result.reviewedRuleVersion, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('half leave and future weekend planning fit $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      final db = StandInDatabase.executor(NativeDatabase.memory());
      final calendars = CalendarRepository(
          db, FirestoreUserRemote(FakeFirebaseFirestore()),
          uid: 'u', followId: 'f');
      await calendars.ensure(c, policy: p);
      final controller = AttendanceController(
          LocalFirstAttendanceRepository(db,
              uid: 'u', organizationId: 'org', scopeId: 'global'),
          const PolicyEngine(),
          p,
          c,
          calendarRepository: calendars,
          planningRepository:
              PlanningRepository(db, organizationId: 'org', scopeId: 'global'));
      addTearDown(() async {
        controller.dispose();
        await db.close();
        await tester.binding.setSurfaceSize(null);
      });
      await controller.ready;
      var day = DateUtils.dateOnly(DateTime.now());
      while (c.isNonWorkingDay(day)) {
        day = day.subtract(const Duration(days: 1));
      }
      await tester.pumpWidget(wrap(Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  onPressed: () =>
                      showMarkAttendance(context, controller, date: day),
                  child: const Text('Mark'))))));
      await settle(tester);
      await tester.tap(find.text('Mark'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Leave'));
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const ValueKey('attendance-leave')));
      await tester.tapAt(tester
          .getRect(find.byKey(const ValueKey('attendance-leave')))
          .center);
      await tester.pumpAndSettle();
      await screenshot(tester, 'half-leave-$label');
      await tester.ensureVisible(find.text('Save attendance'));
      await tester.tap(find.text('Save attendance'));
      await settle(tester);
      expect(controller.recordFor(day)!.leaveUnits, 4);
      expect(controller.recordFor(day)!.snapshot!.credited, 4);
      var future =
          DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
      while (future.weekday != DateTime.saturday) {
        future = future.add(const Duration(days: 1));
      }
      await tester.pumpWidget(wrap(Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  onPressed: () =>
                      showPlanAttendance(context, controller, future),
                  child: const Text('Plan'))))));
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Going'));
      await tester.pumpAndSettle();
      await screenshot(tester, 'weekend-plan-$label');
      await tester.ensureVisible(find.text('Save plan'));
      await tester.tap(find.text('Save plan'));
      await settle(tester);
      expect(controller.planFor(future), isNotNull);
      expect(controller.planDescription(controller.planFor(future)!),
          contains('Counts toward your percentage'));
      expect(controller.recordFor(future), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
      'scheduled rules activate at midnight and when returning to the app',
      (tester) async {
    final db = StandInDatabase.executor(NativeDatabase.memory());
    final calendars = CalendarRepository(
        db, FirestoreUserRemote(FakeFirebaseFirestore()),
        uid: 'u', followId: 'f');
    await calendars.ensure(c, policy: p);
    final today = DateUtils.dateOnly(DateTime.now()),
        nextDay = today.add(const Duration(days: 1));
    final state = (await calendars.read())!;
    final next = calendars.scheduleRules(
        state, p.copyWith(minimumPercent: 80), c, nextDay);
    await db.saveCalendarState('f', const JsonEncoder().convert(next.toJson()));
    var clock = today.add(const Duration(hours: 23));
    final controller = AttendanceController(
        LocalFirstAttendanceRepository(db,
            uid: 'u', organizationId: 'org', scopeId: 'global'),
        const PolicyEngine(),
        p,
        c,
        calendarRepository: calendars,
        clock: () => clock);
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });
    await controller.ready;
    await settle(tester);
    expect(controller.policy.minimumPercent, 85);
    clock = nextDay;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.policy.minimumPercent, 80);
    expect(controller.policyFor(today).minimumPercent, 85);
  });
}
