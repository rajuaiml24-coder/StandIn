import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/standin_database.dart';
import '../../data/local_first_attendance_repository.dart';
import '../../domain/attendance.dart';
import '../../data/calendar_repository.dart';
import '../../data/remote/firestore_user_remote.dart';
import 'attendance_reports_page.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage(
      {super.key,
      required this.database,
      required this.uid,
      required this.organizationId,
      required this.scopeId,
      required this.name,
      this.followId,
      this.remote,
      this.company = false});
  final String? followId;
  final FirestoreUserRemote? remote;
  final bool company;
  final StandInDatabase database;
  final String uid, organizationId, scopeId, name;
  String describe(AttendanceRecord record) =>
      '${attendanceStatusLabel(record.status, company: company, oneVisit: record.snapshot?.policy.oneVisitFullDay ?? false)} | ${formatAttendanceUnits(record.actualUnits)} ${record.snapshot?.policy.basis.label(record.actualUnits) ?? 'original units'}'
      '${record.leaveUnits > 0 ? ' | Leave: ${record.leaveUnits}' : ''}';
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('$name history'), actions: [
        IconButton(
            tooltip: 'Attendance reports',
            icon: const Icon(Icons.insert_chart_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AttendanceReportsPage(
                        name: name,
                        company: company,
                        records: LocalFirstAttendanceRepository(database,
                                uid: uid,
                                organizationId: organizationId,
                                scopeId: scopeId)
                            .watchRecords(),
                        rules: remote == null || followId == null
                            ? null
                            : CalendarRepository(database, remote!,
                                    uid: uid, followId: followId!)
                                .watch())))),
      ]),
      body: StreamBuilder<List<AttendanceRecord>>(
          stream: LocalFirstAttendanceRepository(database,
                  uid: uid, organizationId: organizationId, scopeId: scopeId)
              .watchRecords(),
          builder: (_, data) {
            if (!data.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = [...data.data!]
              ..sort((a, b) => b.date.compareTo(a.date));
            if (records.isEmpty) {
              return const Center(child: Text('No saved attendance yet'));
            }
            return ListView(children: [
              for (final record in records)
                ExpansionTile(
                    title: Text(DateFormat.yMMMd().format(record.date)),
                    subtitle: Text(describe(record)),
                    children: [
                      if (record.snapshot != null)
                        ListTile(
                            title: Text(
                                'Counts: ${formatAttendanceUnits(record.snapshot!.credited)} | Required: ${formatAttendanceUnits(record.snapshot!.requiredUnits)}')),
                      for (final revision in record.history.reversed)
                        ListTile(
                            title: const Text('Previous saved edit'),
                            subtitle: Text(
                                describe(AttendanceRecord.fromJson(revision)))),
                    ])
            ]);
          }));
}
