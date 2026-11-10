import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/attendance.dart';
import '../../domain/attendance_reports.dart';
import '../../domain/calendar_updates.dart';

class AttendanceReportsPage extends StatefulWidget {
  const AttendanceReportsPage(
      {super.key,
      required this.records,
      required this.name,
      this.rules,
      this.company = false});
  final Stream<List<AttendanceRecord>> records;
  final Stream<PersonalCalendarState?>? rules;
  final String name;
  final bool company;
  @override
  State<AttendanceReportsPage> createState() => _AttendanceReportsPageState();
}

class _AttendanceReportsPageState extends State<AttendanceReportsPage> {
  ReportGrouping _grouping = ReportGrouping.period;
  String dates(DateTime start, DateTime end) =>
      '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Attendance reports')),
        body: StreamBuilder<List<AttendanceRecord>>(
            stream: widget.records,
            builder: (_, saved) => StreamBuilder<PersonalCalendarState?>(
                stream: widget.rules,
                builder: (_, rules) {
                  if (!saved.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final records = saved.data!;
                  final reports = buildAttendanceReports(
                      records, rules.data, _grouping, DateTime.now());
                  return Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<ReportGrouping>(
                                  initialValue: _grouping,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'View by'),
                                  items: ReportGrouping.values
                                      .map((group) => DropdownMenuItem(
                                          value: group,
                                          child: Text(switch (group) {
                                            ReportGrouping.period =>
                                              'Saved attendance periods',
                                            ReportGrouping.week => 'Week',
                                            ReportGrouping.month => 'Month',
                                            ReportGrouping.year => 'Year'
                                          })))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _grouping = value!)),
                              if (rules.data == null)
                                const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                        'Saved entries only. The original calendar is not available yet.')),
                            ])),
                    Expanded(
                        child: reports.isEmpty
                            ? const Center(child: Text('No saved reports yet'))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: reports.length,
                                itemBuilder: (_, index) {
                                  final report = reports[index],
                                      summary = report.summary;
                                  return Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    dates(report.start,
                                                        report.end),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 8),
                                                Text(
                                                    '${summary.percent.toStringAsFixed(1)}%',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium),
                                                Text(
                                                    '${formatAttendanceUnits(summary.actual)} of ${formatAttendanceUnits(summary.conductedToDate)} '
                                                    '${report.policy.basis.label(summary.conductedToDate)}'),
                                                Text(
                                                    'Target: ${formatAttendanceUnits(report.policy.minimumPercent ?? 0)}%'),
                                                if (summary.unmarkedCount > 0)
                                                  Text(
                                                      '${summary.unmarkedCount} days not marked'),
                                                if (summary.leaveCredit > 0 ||
                                                    summary.extraCredit > 0)
                                                  Text(
                                                      '${formatAttendanceUnits(summary.physicalUnits)} attended · '
                                                      '${formatAttendanceUnits(summary.leaveCredit)} leave · '
                                                      '${formatAttendanceUnits(summary.extraCredit)} on days off or holidays'),
                                                TextButton.icon(
                                                    icon: const Icon(
                                                        Icons.copy_outlined),
                                                    label:
                                                        const Text('Copy CSV'),
                                                    onPressed: () async {
                                                      await Clipboard.setData(
                                                          ClipboardData(
                                                              text: attendanceCsv(
                                                                  widget.name,
                                                                  report
                                                                      .records,
                                                                  company: widget
                                                                      .company)));
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'Copied. Paste into a text file and save it as .csv.')));
                                                      }
                                                    }),
                                              ])));
                                })),
                  ]);
                })),
      );
}
