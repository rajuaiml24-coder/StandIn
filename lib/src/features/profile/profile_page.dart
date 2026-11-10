import 'package:flutter/material.dart';
import '../../data/local/standin_database.dart';
import '../../data/organization_repository.dart';
import '../../data/user_repository.dart';
import '../../domain/app_errors.dart';
import '../../domain/attendance.dart';
import '../following/following_page.dart';
import '../../data/calendar_repository.dart';
import '../following/shared_rules_page.dart';
import '../../domain/calendar_updates.dart';
import '../../data/remote/firestore_attendance_remote.dart';
import 'attendance_sync_status.dart';
import 'attendance_history_page.dart';
import 'data_backup_status.dart';

class ProfileView extends StatelessWidget {
  const ProfileView(
      {super.key,
      required this.uid,
      required this.database,
      required this.users,
      required this.organizations,
      required this.onManageFollowing,
      required this.onLogout,
      required this.onDeleteAccount,
      this.follow,
      this.attendanceRemote,
      this.policy,
      this.calendar});
  final String uid;
  final StandInDatabase database;
  final UserRepository users;
  final OrganizationRepository organizations;
  final VoidCallback onManageFollowing, onLogout, onDeleteAccount;
  final Follow? follow;
  final AttendancePolicy? policy;
  final AttendanceCalendar? calendar;
  final FirestoreAttendanceRemote? attendanceRemote;

  Future<void> _editProfile(BuildContext context, UserProfile profile) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfilePage(
                profile: profile,
                onSave: (name, mobile) => users.updateProfileDetails(
                    uid, name, mobile,
                    registrationNumber: profile.registrationNumber),
                onSaveDetails: (name, mobile, registration) =>
                    users.updateProfileDetails(uid, name, mobile,
                        registrationNumber: registration))));
  }

  Future<void> _calculationOptions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
        context: context,
        builder: (sheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Calculation settings',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700))),
              if (follow != null) ...[
                ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Customize for me'),
                    onTap: () => Navigator.pop(sheet, 'personal')),
                if (follow!.hasPersonalSettings &&
                    !follow!.isPersonalCalculation)
                  ListTile(
                      leading: const Icon(Icons.rule_outlined),
                      title: const Text('Use shared rules'),
                      onTap: () => Navigator.pop(sheet, 'shared')),
              ],
              ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: const Text('Custom calculation'),
                  onTap: () => Navigator.pop(sheet, 'custom')),
              const SizedBox(height: 12),
            ])));
    if (!context.mounted || action == null) return;
    try {
      if (action == 'custom') {
        await openCustomCalculation(
            context, uid, database, users, organizations);
      } else if (action == 'personal') {
        await editPersonalRules(context, uid, users, follow!, policy,
            calendar ?? AttendanceCalendar.unconfigured);
      } else if (follow!.hasPersonalSettings) {
        final calendars = CalendarRepository(database, users.remote,
            uid: uid, followId: follow!.id);
        final state = await calendars.read();
        if (state == null) throw StateError('Rules are still loading');
        final (shared, version) =
            await organizations.sharedRulesSnapshot(follow!.organizationId);
        final latest = version == 0
            ? null
            : await organizations.nextRuleRevision(
                follow!.organizationId, version - 1);
        final proposed = latest?.effectiveDate ?? DateTime.now();
        final preview = calendars.scheduleRules(
            state, shared.policy, shared.calendar, proposed);
        final start = preview.ruleTimeline.last['effectiveDate'];
        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialog) => AlertDialog(
                    title: const Text('Use shared rules?'),
                    content: Text(
                        'Shared rules will start on $start. Already-marked attendance stays unchanged.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: const Text('Use shared rules'))
                    ]));
        if (confirmed == true) {
          await database.transaction(() async {
            await calendars.replaceWithSharedRules(
                state, shared, version, proposed);
            await users.saveFollow(uid, follow!.withoutPersonalSettings);
          });
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(actionError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile?>(
      stream: users.watchProfile(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.displayName.trim() ?? '';
        return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text('Profile',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      child: Text(name.isEmpty
                          ? 'S'
                          : name.characters.first.toUpperCase())),
                  title: Text(name.isEmpty ? 'StandIn member' : name),
                  subtitle: Text(profile?.role == AppRole.employee
                      ? 'Employee'
                      : 'Student'),
                  trailing: IconButton(
                      tooltip: 'Edit profile',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: profile == null
                          ? null
                          : () => _editProfile(context, profile))),
              const Divider(height: 32),
              if (follow != null)
                FutureBuilder<Organization?>(
                    future:
                        organizations.getOrganization(follow!.organizationId),
                    builder: (context, org) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.business_outlined),
                                  title: Text(follow!.isPersonalCalculation
                                      ? 'Custom calculation'
                                      : org.data?.name ?? 'Organization'),
                                  subtitle: Text(follow!.isPersonalCalculation
                                      ? 'Private calendar'
                                      : 'Following | ${org.data?.followerCount ?? 0} followers'),
                                  trailing: IconButton(
                                      tooltip: 'Change organization',
                                      icon: const Icon(Icons.swap_horiz),
                                      onPressed: () =>
                                          _chooseOrganization(context))),
                              if (org.data?.createdBy == uid &&
                                  !follow!.isPersonalCalculation)
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                        Icons.edit_calendar_outlined),
                                    title: const Text('Shared rules'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => SharedRulesEditor(
                                                organizations: organizations,
                                                organizationId:
                                                    follow!.organizationId,
                                                uid: uid)))),
                              StreamBuilder<SyncQueueRow?>(
                                  stream: database
                                      .watchOperation('follow:${follow!.id}'),
                                  builder: (_, sync) => sync.data == null
                                      ? const SizedBox.shrink()
                                      : ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                              sync.data!.lastError == null
                                                  ? 'Following: pending sync'
                                                  : 'Following: sync failed'),
                                          trailing: IconButton(
                                              tooltip: 'Retry follow sync',
                                              icon: const Icon(Icons.refresh),
                                              onPressed: () => database
                                                  .retryUnchangedOperation(
                                                      sync.data!)))),
                              _CalendarSyncStatus(
                                  repository: CalendarRepository(
                                      database, users.remote,
                                      uid: uid, followId: follow!.id)),
                            ]))
              else
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Choose organization'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _chooseOrganization(context)),
              StreamBuilder<List<FollowRow>>(
                  stream: database.select(database.followRows).watch(),
                  builder: (_, saved) =>
                      !(saved.data?.any((r) => r.id != follow?.id) ?? false)
                          ? const SizedBox.shrink()
                          : ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history),
                              title: const Text('Saved calendars'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  _savedCalendars(context, saved.data!))),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: const Text('Calculation settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _calculationOptions(context)),
              if (follow != null)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: const Text('Attendance history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final row = await database.getFollow(follow!.id);
                      final org = await organizations
                          .getOrganization(follow!.organizationId);
                      if (row != null && context.mounted) {
                        await _history(context, row, org?.name);
                      }
                    }),
              if (follow != null)
                StreamBuilder<PersonalCalendarState?>(
                    stream: CalendarRepository(database, users.remote,
                            uid: uid, followId: follow!.id)
                        .watch(),
                    builder: (_, state) {
                      final today = calendarDayKey(DateTime.now());
                      final pending = state.data?.ruleTimeline
                              .where((entry) =>
                                  (entry['effectiveDate'] as String)
                                      .compareTo(today) >
                                  0)
                              .toList() ??
                          [];
                      return Column(children: [
                        for (final entry in pending)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.schedule),
                              title: const Text('Rules scheduled'),
                              subtitle: Text('From ${entry['effectiveDate']}'))
                      ]);
                    }),
              const Divider(height: 32),
              if (attendanceRemote != null)
                DataBackupStatus(database: database, uid: uid),
              if (attendanceRemote != null)
                AttendanceSyncStatus(
                    database: database,
                    remote: attendanceRemote!,
                    uid: uid,
                    activeFollowId: follow?.id),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: onLogout),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: Colors.red),
                  title: const Text('Delete account',
                      style: TextStyle(color: Colors.red)),
                  onTap: onDeleteAccount),
            ]);
      });

  Future<void> _chooseOrganization(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => Scaffold(
              appBar: AppBar(),
              body: FollowingPage(
                  database: database,
                  userRepository: users,
                  organizationRepository: organizations,
                  uid: uid,
                  activeFollowId: follow?.id,
                  discoveryOnly: true))));

  Future<void> _savedCalendars(
      BuildContext context, List<FollowRow> rows) async {
    final selected = await showModalBottomSheet<FollowRow>(
        context: context,
        builder: (sheet) => SafeArea(
            child: ListView(
                shrinkWrap: true,
                children: rows
                    .map((row) => FutureBuilder<Organization?>(
                        future:
                            organizations.getOrganization(row.organizationId),
                        builder: (_, org) => ListTile(
                            title: Text(org.data?.name ?? 'Saved calendar'),
                            trailing: IconButton(
                                tooltip: 'View saved attendance',
                                icon: const Icon(Icons.history),
                                onPressed: () {
                                  Navigator.pop(sheet);
                                  _history(context, row, org.data?.name);
                                }),
                            leading: Icon(row.id == follow?.id
                                ? Icons.radio_button_checked
                                : Icons.history),
                            onTap: () => Navigator.pop(sheet, row))))
                    .toList())));
    if (selected != null) {
      try {
        if (selected.status != 'active') {
          final saved = UserRepository.followFromRow(selected);
          if (saved.isPersonalCalculation) {
            await users.saveFollow(uid, saved.copyWith(status: 'active'));
          } else {
            final org =
                await organizations.getOrganization(saved.organizationId);
            if (org == null) {
              if (context.mounted) await _history(context, selected, null);
              return;
            }
            await users.followScope(uid, org, saved.scopeId, organizations);
          }
        }
        await users.prepareFollowContext(uid, selected.id, organizations);
        await users.activateFollow(uid, selected.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(actionError(e))));
        }
      }
    }
  }

  Future<void> _history(
      BuildContext context, FollowRow row, String? name) async {
    final org = await organizations.getOrganization(row.organizationId);
    if (!context.mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AttendanceHistoryPage(
                database: database,
                uid: uid,
                organizationId: row.organizationId,
                scopeId: row.scopeId,
                followId: row.id,
                remote: users.remote,
                company: org?.type == OrganizationType.company,
                name: name ?? 'Saved calendar')));
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage(
      {super.key,
      required this.profile,
      required this.onSave,
      this.onSaveDetails});
  final UserProfile profile;
  final Future<void> Function(String name, String? mobile) onSave;
  final Future<void> Function(
      String name, String? mobile, String? registration)? onSaveDetails;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.displayName);
  late final TextEditingController _mobile =
      TextEditingController(text: widget.profile.mobile ?? '');
  late final TextEditingController _registration =
      TextEditingController(text: widget.profile.registrationNumber ?? '');
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _registration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.onSaveDetails != null) {
        await widget.onSaveDetails!(
            _name.text.trim(), _mobile.text.trim(), _registration.text.trim());
      } else {
        await widget.onSave(_name.text.trim(), _mobile.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = actionError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name'
                        : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _registration,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'Registration number (optional)')),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: const InputDecoration(
                        labelText: 'Mobile number', hintText: 'Optional'),
                    validator: (value) => value == null ||
                            value.trim().isEmpty ||
                            RegExp(r'^\+?[0-9 ()-]{6,20}$')
                                .hasMatch(value.trim())
                        ? null
                        : 'Enter a valid mobile number'),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 24),
                FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save profile')),
              ]))));
}

class _CalendarSyncStatus extends StatelessWidget {
  const _CalendarSyncStatus({required this.repository});
  final CalendarRepository repository;
  @override
  Widget build(BuildContext context) => StreamBuilder<SyncQueueRow?>(
      stream: repository.database.watchOperation(repository.operationId),
      builder: (context, data) {
        if (data.data == null) return const SizedBox.shrink();
        final failed = data.data!.lastError != null;
        final conflict =
            data.data!.lastError?.contains('another device') == true;
        return ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(failed ? Icons.sync_problem : Icons.cloud_upload_outlined),
            title: Text(conflict
                ? 'Calendar sync conflict'
                : failed
                    ? 'Calendar sync failed'
                    : 'Calendar pending sync'),
            trailing: IconButton(
                tooltip: conflict
                    ? 'Resolve calendar conflict'
                    : 'Retry calendar sync',
                icon: Icon(conflict ? Icons.rule : Icons.refresh),
                onPressed: () async {
                  if (!conflict) {
                    await repository.retry();
                    return;
                  }
                  final latest = await showDialog<bool>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                              title: const Text(
                                  'Calendar changed on another device'),
                              content: const Text(
                                  'Using the synced calendar replaces your unsynced calendar edits. Attendance and plans are preserved.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialog, false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialog, true),
                                    child: const Text('Use synced calendar'))
                              ]));
                  if (latest == true) {
                    try {
                      await repository.useRemoteAfterConflict();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(actionError(e))));
                      }
                    }
                  }
                }));
      });
}
