import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/standin_database.dart';

class DataBackupStatus extends StatelessWidget {
  const DataBackupStatus(
      {super.key, required this.database, required this.uid});
  final StandInDatabase database;
  final String uid;
  @override
  Widget build(BuildContext context) => StreamBuilder<List<SyncQueueRow>>(
      stream: database.select(database.syncQueueRows).watch(),
      builder: (_, queue) => StreamBuilder<SyncMetadataRow?>(
          stream: (database.select(database.syncMetadataRows)
                ..where((row) => row.key.equals('backup:$uid')))
              .watchSingleOrNull(),
          builder: (_, metadata) {
            if (!queue.hasData) return const SizedBox.shrink();
            final pending = queue.data!.isNotEmpty;
            final failed = queue.data!.any((row) => row.lastError != null);
            final backedUp = !pending && metadata.data != null;
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          failed
                              ? Icons.sync_problem
                              : backedUp
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_upload_outlined,
                          size: 18,
                          color: failed
                              ? Colors.orange.shade800
                              : Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                failed
                                    ? 'Backup needs attention'
                                    : pending
                                        ? 'Saved on this device'
                                        : backedUp
                                            ? 'Backed up'
                                            : 'Backup not confirmed yet',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                            Text(
                                failed
                                    ? 'Your local data is kept. Open Profile to review.'
                                    : pending
                                        ? 'Waiting to back up when connected.'
                                        : backedUp
                                            ? 'Last backup: ${DateFormat.yMMMd().add_jm().format(metadata.data!.lastSyncAt)}'
                                            : 'Connect to confirm your backup.',
                                style: const TextStyle(fontSize: 11)),
                          ])),
                    ]));
          }));
}
