import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:standin/src/data/local/standin_database.dart';
import 'package:standin/src/data/organization_repository.dart';
import 'package:standin/src/data/remote/firestore_org_remote.dart';
import 'package:standin/src/domain/attendance.dart';

AttendancePolicy policy(double target) => AttendancePolicy(
      id: 'policy-global',
      version: 1,
      effectiveFrom: DateTime(2000),
      state: PolicyState.official,
      evaluationPeriod: EvaluationPeriod.monthly,
      minimumPercent: target,
      basis: CalculationBasis.hours,
      fullUnit: 7,
      halfUnit: 3.5,
      scopeId: 'global',
    );

AttendanceCalendar calendar(int day) => AttendanceCalendar(
      id: 'cal-global',
      version: 1,
      effectiveFrom: DateTime(2000),
      weeklyOffs: [day],
      isConfigured: true,
    );

void main() {
  late StandInDatabase database;
  late OrganizationRepository repository;

  setUp(() {
    database = StandInDatabase.executor(NativeDatabase.memory());
    repository = OrganizationRepository(
        database, FirestoreOrgRemote(FakeFirebaseFirestore()));
  });
  tearDown(() => database.close());

  test('identical policy and calendar IDs cannot collide across organizations',
      () async {
    await repository.cachePolicy('college', policy(75));
    await repository.cachePolicy('company', policy(90));
    await repository.saveCalendar('college', calendar(DateTime.sunday));
    await repository.saveCalendar('company', calendar(DateTime.saturday));

    for (final org in ['college', 'company']) {
      await database.upsertOrganization(OrganizationRowsCompanion.insert(
        id: org,
        name: org,
        type: 'college',
        updatedAt: DateTime.now(),
        activePolicyId: const Value('policy-global'),
        activeCalendarId: const Value('cal-global'),
      ));
      final resolvedPolicy = await repository.getResolvedPolicy(
          uid: 'user', organizationId: org, scopeId: 'global');
      final resolvedCalendar = await repository.getResolvedCalendar(
          uid: 'user', organizationId: org, scopeId: 'global');
      expect(resolvedPolicy!.id, 'policy-global');
      expect(resolvedPolicy.organizationId, org);
      expect(resolvedPolicy.minimumPercent, org == 'college' ? 75 : 90);
      expect(resolvedCalendar.id, 'cal-global');
      expect(resolvedCalendar.weeklyOffs,
          [org == 'college' ? DateTime.sunday : DateTime.saturday]);
    }
    expect(await database.select(database.organizationPolicyRows).get(),
        hasLength(2));
    expect(await database.select(database.calendarRows).get(), hasLength(2));
  });

  test(
      'legacy cache is readable only within its organization and refreshed rows win',
      () async {
    await database
        .into(database.organizationPolicyRows)
        .insert(OrganizationPolicyRowsCompanion.insert(
          policyId: 'policy-global',
          organizationId: 'college',
          scopeId: 'global',
          version: 1,
          effectiveFrom: DateTime(2000),
          state: 'official',
          evaluationPeriod: 'monthly',
          minimumPercent: const Value(65),
          calculationBasis: 'hours',
          fullUnit: 7,
          halfUnit: 3.5,
          updatedAt: DateTime.now(),
        ));
    await database
        .into(database.calendarRows)
        .insert(CalendarRowsCompanion.insert(
          id: 'cal-global',
          organizationId: 'college',
          scopeId: 'global',
          version: 1,
          effectiveFrom: DateTime(2000),
          weeklyOffs: '[7]',
          offSaturdays: '[]',
          updatedAt: DateTime.now(),
        ));
    expect(
        (await database.getPolicyById('policy-global',
                organizationId: 'college'))!
            .minimumPercent,
        65);
    expect(
        await database.getPolicyById('policy-global',
            organizationId: 'company'),
        isNull);
    expect(
        await database.getCalendarById('cal-global', organizationId: 'company'),
        isNull);

    await repository.cachePolicy('college', policy(80));
    await repository.saveCalendar('college', calendar(DateTime.saturday));
    expect(
        (await database.policyAt('college', 'global', DateTime.now()))!
            .minimumPercent,
        80);
    expect(
        (await database.calendarAt('college', 'global', DateTime.now()))!
            .weeklyOffs,
        '[6]');
    expect(
        (await database.getPolicyById('policy-global',
                organizationId: 'college'))!
            .minimumPercent,
        80);
    expect(await database.select(database.organizationPolicyRows).get(),
        hasLength(2));
  });

  test(
      'personal schedules retain inherited holidays, including legacy empty holiday lists',
      () async {
    final holiday =
        Holiday(date: DateTime(2026, 1, 26), name: 'Official holiday');
    await repository.saveCalendar(
        'college', calendar(DateTime.sunday).copyWith(holidays: [holiday]));
    await database.upsertFollow(FollowRowsCompanion.insert(
      id: 'follow',
      organizationId: 'college',
      scopeId: 'global',
      status: 'active',
      followedAt: DateTime(2000),
      personalWeeklyOffs: const Value('[6]'),
      personalOffSaturdays: const Value('[]'),
      personalHolidays: const Value('[]'),
      isPersonalCalendarConfigured: const Value(true),
    ));
    var resolved = await repository.getResolvedCalendar(
        uid: 'user',
        organizationId: 'college',
        scopeId: 'global',
        followId: 'follow');
    expect(resolved.weeklyOffs, [DateTime.saturday]);
    expect(resolved.holidays.single.name, 'Official holiday');
    expect(resolved.holidays.any((item) => item.date == holiday.date), isTrue);

    await (database.update(database.followRows)
          ..where((row) => row.id.equals('follow')))
        .write(
      FollowRowsCompanion(
          personalHolidays: Value(jsonEncode([
        Holiday(date: holiday.date, name: 'Personal label').toJson(),
        Holiday(date: DateTime(2026, 2, 1), name: 'Personal holiday').toJson(),
      ]))),
    );
    resolved = await repository.getResolvedCalendar(
        uid: 'user',
        organizationId: 'college',
        scopeId: 'global',
        followId: 'follow');
    expect(resolved.holidays, hasLength(2));
    expect(resolved.holidays.first.name, 'Personal label');
  });

  test(
      'missing official policies get personal context and basis-appropriate units',
      () async {
    await database.upsertFollow(FollowRowsCompanion.insert(
      id: 'follow',
      organizationId: 'college',
      scopeId: 'semester',
      status: 'active',
      followedAt: DateTime(2000),
      personalBasis: const Value('days'),
    ));
    final resolved = await repository.getResolvedPolicy(
        uid: 'user',
        organizationId: 'college',
        scopeId: 'semester',
        followId: 'follow');
    expect(resolved!.organizationId, 'college');
    expect(resolved.scopeId, 'semester');
    expect(resolved.fullUnit, 1);
    expect(resolved.halfUnit, 0.5);
    expect(resolved.hasValidTarget, isFalse);
    expect(
        await repository.getResolvedPolicy(
            uid: 'user',
            organizationId: 'company',
            scopeId: 'semester',
            followId: 'follow'),
        isNull);
  });
}
