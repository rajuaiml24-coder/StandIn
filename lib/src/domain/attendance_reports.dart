import 'attendance.dart';
import 'calendar_updates.dart';
import 'policy_engine.dart';

enum ReportGrouping { period, week, month, year }

class AttendanceReport {
  const AttendanceReport(
      {required this.start,
      required this.end,
      required this.policy,
      required this.summary,
      required this.records});
  final DateTime start, end;
  final AttendancePolicy policy;
  final AttendanceSummary summary;
  final List<AttendanceRecord> records;
}

String _unitsKey(AttendancePolicy policy) =>
    '${policy.basis.name}:${policy.fullUnit}:${policy.oneVisitFullDay}';

List<AttendanceReport> buildAttendanceReports(List<AttendanceRecord> records,
    PersonalCalendarState? accepted, ReportGrouping grouping, DateTime now) {
  const engine = PolicyEngine();
  final byDate = {for (final r in records) calendarDayKey(r.date): r};
  final grouped = <String, List<AttendanceRecord>>{};
  final ranges = <String, ({DateTime start, DateTime end})>{};
  for (final record in records) {
    final snapshot = record.snapshot;
    if (snapshot == null) continue;
    final date = record.date;
    final range = switch (grouping) {
      ReportGrouping.period => (
          start: snapshot.periodStart,
          end: snapshot.periodEnd
        ),
      ReportGrouping.week => engine.periodRange(
          snapshot.policy.copyWith(evaluationPeriod: EvaluationPeriod.weekly),
          date)!,
      ReportGrouping.month => (
          start: DateTime(date.year, date.month),
          end: DateTime(date.year, date.month + 1, 0, 23, 59, 59)
        ),
      ReportGrouping.year => (
          start: DateTime(date.year),
          end: DateTime(date.year, 12, 31, 23, 59, 59)
        ),
    };
    final key =
        '${calendarDayKey(range.start)}:${calendarDayKey(range.end)}:${_unitsKey(snapshot.policy)}';
    (grouped[key] ??= []).add(record);
    ranges[key] = range;
  }
  final result = <AttendanceReport>[];
  for (final entry in grouped.entries) {
    final saved = [...entry.value]..sort((a, b) => a.date.compareTo(b.date));
    final policy = saved.last.snapshot!.policy;
    final range = ranges[entry.key]!;
    AttendancePolicy originalPolicy(DateTime date) =>
        byDate[calendarDayKey(date)]?.snapshot?.policy ??
        accepted?.policyAt(date) ??
        policy;
    bool includes(DateTime date) {
      final daily = originalPolicy(date);
      if (_unitsKey(daily) != _unitsKey(policy)) return false;
      final period = engine.periodRange(daily, date);
      if (period == null ||
          date.isBefore(period.start) ||
          date.isAfter(period.end)) {
        return false;
      }
      if (accepted == null && !byDate.containsKey(calendarDayKey(date))) {
        return false;
      }
      if (grouping == ReportGrouping.period) {
        return calendarDayKey(period.start) == calendarDayKey(range.start) &&
            calendarDayKey(period.end) == calendarDayKey(range.end);
      }
      // Without the accepted rule timeline, only stored contributions are known.
      return accepted != null || byDate.containsKey(calendarDayKey(date));
    }

    final calendar =
        accepted?.calendarAt(range.start) ?? AttendanceCalendar.unconfigured;
    final summary = engine.summarizeRange(
        policy, calendar, records, range.start, range.end, now,
        policyFor: originalPolicy,
        calendarFor: (date) => accepted?.calendarAt(date) ?? calendar,
        includeDate: includes);
    result.add(AttendanceReport(
        start: range.start,
        end: range.end,
        policy: policy,
        summary: summary,
        records: saved));
  }
  result.sort((a, b) => b.start.compareTo(a.start));
  return result;
}

String attendanceCsv(String name, Iterable<AttendanceRecord> records,
    {bool company = false}) {
  String cell(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';
  final rows = <List<Object?>>[
    [
      'Organization',
      'Date',
      'Status',
      'Attended',
      'Leave',
      'Counts toward target',
      'Required',
      'Unit',
      'Period start',
      'Period end',
      'Revision',
      'Previous edits'
    ],
    for (final r in records)
      [
        name,
        calendarDayKey(r.date),
        attendanceStatusLabel(r.status,
            company: company,
            oneVisit: r.snapshot?.policy.oneVisitFullDay ?? false),
        r.actualUnits,
        r.leaveUnits,
        r.snapshot?.credited ?? r.actualUnits,
        r.snapshot?.requiredUnits ?? r.expectedUnits,
        r.snapshot?.policy.basis.name ?? 'original units',
        r.snapshot == null ? null : calendarDayKey(r.snapshot!.periodStart),
        r.snapshot == null ? null : calendarDayKey(r.snapshot!.periodEnd),
        r.revisionId,
        r.history.length
      ],
  ];
  return rows.map((row) => row.map(cell).join(',')).join('\r\n');
}
