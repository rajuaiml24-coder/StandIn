import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/attendance.dart';
import '../domain/calendar_updates.dart';
import '../domain/shared_rules.dart';
import 'local/standin_database.dart';
import 'remote/firestore_user_remote.dart';

class CalendarRepository {
  CalendarRepository(this.database, this.remote,
      {required this.uid, required this.followId});
  final StandInDatabase database;
  final FirestoreUserRemote remote;
  final String uid, followId;
  String get operationId => 'calendarState:$followId';
  Stream<PersonalCalendarState?> watchRemote() =>
      remote.watchCalendarState(uid, followId);
  Future<void> receive(PersonalCalendarState? state) =>
      database.transaction(() async {
        if (state == null || await database.getOperation(operationId) != null) {
          return;
        }
        final current = await read();
        if (current == null ||
            !sameCalendarValue(current.toJson(), state.toJson())) {
          await database.saveCalendarState(
              followId, jsonEncode(state.toJson()));
        }
      });

  Future<PersonalCalendarState?> read() async {
    final row = await database.getCalendarState(followId);
    return row == null
        ? null
        : PersonalCalendarState.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>);
  }

  Stream<PersonalCalendarState?> watch() =>
      database.watchCalendarState(followId).map((row) => row == null
          ? null
          : PersonalCalendarState.fromJson(
              jsonDecode(row.payload) as Map<String, dynamic>));

  Future<void> ensure(AttendanceCalendar calendar,
      {int reviewedVersion = 0, AttendancePolicy? policy}) async {
    final current = await read();
    if (current != null) {
      if (current.policy == null && policy != null) {
        await database.transaction(() async {
          final latest = await read();
          if (latest != null && latest.policy == null) {
            await _save(latest, latest.copyWith(policy: policy));
          }
        });
      }
      return;
    }
    PersonalCalendarState? recovered;
    try {
      recovered = await remote.getCalendarState(uid, followId);
    } catch (_) {/* Local calendar remains usable offline. */}
    await database.transaction(() async {
      if (await read() != null) return;
      if (recovered != null) {
        await database.saveCalendarState(
            followId, jsonEncode(recovered.toJson()));
        if (recovered.policy == null && policy != null) {
          await _save(recovered, recovered.copyWith(policy: policy));
        }
      } else {
        await _save(
            null,
            PersonalCalendarState(
                baseline: calendar,
                reviewedVersion: reviewedVersion,
                policy: policy));
      }
    });
  }

  Future<void> _save(
      PersonalCalendarState? base, PersonalCalendarState next) async {
    final pending = await database.getOperation(operationId);
    final previous = pending == null
        ? null
        : jsonDecode(pending.payload) as Map<String, dynamic>;
    final original = previous == null ? base?.toJson() : previous['base'];
    await database.saveCalendarState(followId, jsonEncode(next.toJson()));
    await database.enqueue(SyncQueueRowsCompanion.insert(
        id: operationId,
        operation: 'putCalendarState',
        entityId: followId,
        payload: jsonEncode({'base': original, 'next': next.toJson()}),
        attemptCount: const Value(0),
        lastError: const Value(null),
        nextAttemptAt: DateTime.now(),
        createdAt: DateTime.now()));
  }

  Future<void> initializePublishedRules(RuleRevision revision) =>
      database.transaction(() async {
        final current = await read();
        if (current == null || current.policy != null) return;
        final today = DateTime.now();
        final pending = revision.effectiveDate
            .isAfter(DateTime(today.year, today.month, today.day));
        final rules = pending ? revision.before : revision.rules;
        await _save(
            current,
            PersonalCalendarState(
                baseline: rules.calendar,
                reviewedVersion: current.reviewedVersion,
                policy: rules.policy,
                reviewedRuleVersion: revision.version,
                ruleTimeline: pending
                    ? [
                        {
                          'effectiveDate':
                              calendarDayKey(revision.effectiveDate),
                          'policy': revision.rules.policy.toJson(),
                          'calendar': calendarJson(revision.rules.calendar)
                        }
                      ]
                    : []));
      });

  Future<void> setHoliday(DateTime day, Holiday? holiday) =>
      database.transaction(() async {
        final current = await read();
        if (current == null) throw StateError('Calendar is still loading');
        final now = DateTime.now();
        if (current.policy != null &&
            !day.isAfter(DateTime(now.year, now.month, now.day))) {
          throw StateError(
              'Use the attendance editor to correct a past date. Future calendar changes preserve your history.');
        }
        await _save(current, current.withDate(day, holiday));
      });

  Future<void> setSettings(AttendanceCalendar calendar,
          {AttendancePolicy? policy}) =>
      database.transaction(() async {
        final current = await read();
        if (current == null) return;
        final holidays =
            calendar.holidays.map((h) => calendarDayKey(h.date)).toSet();
        final settings = calendar.copyWith(
            workingDates: current.calendar.workingDates
                .where((d) => !holidays.contains(d))
                .toList());
        if (current.policy != null) {
          final before =
              SharedRules(current.policyAt(DateTime.now())!, current.calendar);
          final draft = SharedRules(policy ?? before.policy, settings);
          final resetDates = draft
              .changesFrom(before)
              .keys
              .where((k) => k.startsWith('holiday:'))
              .map((k) => k.substring(8))
              .toList();
          await _save(
              current,
              scheduleRules(
                  current,
                  policy ?? current.policyAt(DateTime.now())!,
                  settings,
                  DateTime.now(),
                  dateResets: resetDates));
          return;
        }
        await _save(
            current,
            PersonalCalendarState(
                baseline: settings, reviewedVersion: current.reviewedVersion));
      });

  PersonalCalendarState scheduleRules(PersonalCalendarState state,
      AttendancePolicy next, AttendanceCalendar calendar, DateTime proposedDate,
      {DateTime? now, List<String> dateResets = const []}) {
    final today = now ?? DateTime.now();
    SharedRules(next, calendar).validate();
    var proposed = proposedDate;
    var baseDate = today;
    if (state.ruleTimeline.isNotEmpty) {
      final last =
          DateTime.parse(state.ruleTimeline.last['effectiveDate'] as String);
      if (last.isAfter(baseDate)) baseDate = last;
      if (!proposed.isAfter(last)) {
        proposed = DateTime(last.year, last.month, last.day + 1);
      }
    }
    final original = state.policyAt(baseDate);
    if (original == null) {
      throw StateError('Attendance rules are still loading');
    }
    final effective = ruleActivationDate(original, next, proposed, baseDate);
    return state.copyWith(ruleTimeline: [
      ...state.ruleTimeline,
      {
        'effectiveDate': calendarDayKey(effective),
        'policy': next.toJson(),
        'calendar': calendarJson(calendar),
        if (dateResets.isNotEmpty) 'dateResets': dateResets,
      }
    ]);
  }

  Future<void> applyReview(PersonalCalendarState presented,
          CalendarRevision revision, Map<String, bool> choices) =>
      database.transaction(() async {
        final current = await read();
        if (current == null ||
            !sameCalendarValue(current.toJson(), presented.toJson())) {
          throw StateError(
              'Your calendar changed. Reopen this review before applying.');
        }
        await _save(current, current.review(revision, choices));
      });

  Future<void> applyRuleReview(PersonalCalendarState presented,
          RuleRevision revision, Map<String, bool> choices) =>
      database.transaction(() async {
        final current = await read();
        if (current == null ||
            !sameCalendarValue(current.toJson(), presented.toJson()) ||
            revision.version != current.reviewedRuleVersion + 1 ||
            choices.length != revision.changes.length ||
            !revision.changes.keys.every(choices.containsKey)) {
          throw StateError(
              'Rules changed. Reopen this review and decide on each change.');
        }
        final today = DateTime.now();
        final future = current.ruleTimeline.isEmpty
            ? today
            : DateTime.parse(
                current.ruleTimeline.last['effectiveDate'] as String);
        final mine =
            SharedRules(current.policyAt(future)!, current.calendarAt(future));
        final selected = <String, Object?>{};
        final resetDates = <String>[];
        for (final entry in choices.entries) {
          if (!entry.value) continue;
          if (entry.key.startsWith('holiday:')) {
            final day = DateTime.parse(entry.key.substring(8));
            if (!day.isAfter(DateTime(today.year, today.month, today.day))) {
              continue;
            }
            resetDates.add(entry.key.substring(8));
          }
          selected[entry.key] = revision.changes[entry.key];
        }
        var next = current;
        if (selected.isNotEmpty) {
          final result = mine.apply(selected);
          next = scheduleRules(
              current, result.policy, result.calendar, revision.effectiveDate,
              dateResets: resetDates);
        }
        await _save(
            current,
            PersonalCalendarState(
                baseline: next.baseline,
                reviewedVersion: next.reviewedVersion,
                dates: current.dates,
                policy: next.policy,
                ruleTimeline: next.ruleTimeline,
                reviewedRuleVersion: revision.version));
      });

  Future<void> replaceWithSharedRules(PersonalCalendarState presented,
          SharedRules rules, int version, DateTime proposed) =>
      database.transaction(() async {
        final current = await read();
        if (current == null ||
            !sameCalendarValue(current.toJson(), presented.toJson())) {
          throw StateError('Your rules changed. Reopen the settings.');
        }
        final next = scheduleRules(
            current, rules.policy, rules.calendar, proposed,
            dateResets: current.dates.keys.toList());
        await _save(current, next.copyWith(reviewedRuleVersion: version));
      });

  Future<void> refresh() async {
    if (await database.getOperation(operationId) != null) return;
    final state = await remote.getCalendarState(uid, followId);
    if (state != null) {
      await database.transaction(() async {
        if (await database.getOperation(operationId) == null) {
          await database.saveCalendarState(
              followId, jsonEncode(state.toJson()));
        }
      });
    }
  }

  Future<void> retry() => database.transaction(() async {
        final pending = await database.getOperation(operationId);
        if (pending != null) {
          await database.enqueue(SyncQueueRowsCompanion.insert(
              id: pending.id,
              operation: pending.operation,
              entityId: pending.entityId,
              payload: pending.payload,
              attemptCount: const Value(0),
              lastError: const Value(null),
              nextAttemptAt: DateTime.now(),
              createdAt: pending.createdAt));
        }
      });

  Future<void> useRemoteAfterConflict() async {
    final pending = await database.getOperation(operationId);
    final latest = await remote.getCalendarState(uid, followId);
    if (latest == null) {
      throw StateError('No synchronized calendar is available');
    }
    await database.transaction(() async {
      if ((await database.getOperation(operationId))?.payload !=
          pending?.payload) {
        throw StateError('Your calendar changed. Reopen the conflict.');
      }
      await database.saveCalendarState(followId, jsonEncode(latest.toJson()));
      if (pending != null) await database.acknowledgeOperation(pending);
    });
  }
}
