import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/local/standin_database.dart';
import '../../data/organization_repository.dart';
import '../../data/user_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/app_errors.dart';
import '../../domain/shared_rules.dart';
import 'rules_editor_page.dart';
import '../../data/calendar_repository.dart';
import '../../domain/calendar_updates.dart';

Future<void> confirmPersonalRuleStart(
    BuildContext context,
    CalendarRepository calendars,
    PersonalCalendarState state,
    AttendancePolicy policy,
    AttendanceCalendar calendar) async {
  final preview =
      calendars.scheduleRules(state, policy, calendar, DateTime.now());
  final start = preview.ruleTimeline.last['effectiveDate'];
  final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
              title: const Text('Save future rules?'),
              content: Text(
                  'These rules will start on $start. Already-marked attendance stays unchanged.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Save rules'))
              ]));
  if (yes != true) {
    throw StateError('Rules were not saved. Your draft is still here.');
  }
  final current = await calendars.read();
  if (current == null || !sameCalendarValue(current.toJson(), state.toJson())) {
    throw StateError('Your rules changed. Reopen the editor before saving.');
  }
}

Future<void> editPersonalRules(
    BuildContext context,
    String uid,
    UserRepository repository,
    Follow follow,
    AttendancePolicy? policy,
    AttendanceCalendar calendar) async {
  final calendars = CalendarRepository(repository.database, repository.remote,
      uid: uid, followId: follow.id);
  final current = await calendars.read();
  if (!context.mounted) return;
  await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RulesEditorPage(
                title: 'My attendance rules',
                policy: policy,
                calendar: current?.calendar ?? calendar,
                onSave: (draft) async {
                  final nextPolicy = draft.policy(follow.organizationId,
                      follow.scopeId, 'personal-${follow.id}', 1);
                  final nextCalendar = draft.calendar(follow.organizationId,
                      follow.scopeId, 'personal-cal-${follow.id}', 1);
                  if (current?.policy != null) {
                    await confirmPersonalRuleStart(
                        context, calendars, current!, nextPolicy, nextCalendar);
                  }
                  await repository.database.transaction(() async {
                    final latest = await calendars.read();
                    if (current != null &&
                        (latest == null ||
                            !sameCalendarValue(
                                current.toJson(), latest.toJson()))) {
                      throw StateError(
                          'Your rules changed. Reopen the editor before saving.');
                    }
                    await calendars.ensure(calendar, policy: policy);
                    await calendars.setSettings(
                        draft.calendar(follow.organizationId, follow.scopeId,
                            'personal-cal-${follow.id}', 1),
                        policy: draft.policy(follow.organizationId,
                            follow.scopeId, 'personal-${follow.id}', 1));
                    await repository.saveFollow(
                        uid,
                        Follow(
                          id: follow.id,
                          organizationId: follow.organizationId,
                          scopeId: follow.scopeId,
                          status: follow.status,
                          followedAt: follow.followedAt,
                          personalTargetPercent: draft.target,
                          personalBasis: draft.basis,
                          personalEvaluationPeriod: draft.period,
                          personalFullUnit: draft.fullUnit,
                          personalHalfUnit: draft.halfUnit,
                          personalStartDate: draft.start,
                          personalEndDate: draft.end,
                          personalWeeklyOffs: jsonEncode(draft.weeklyOffs),
                          personalOffSaturdays: jsonEncode(draft.offSaturdays),
                          personalHolidays: jsonEncode({
                            'replace': true,
                            'holidays':
                                draft.holidays.map((h) => h.toJson()).toList()
                          }),
                          isPersonalCalendarConfigured: true,
                        ));
                  });
                },
              )));
}

Future<void> openCustomCalculation(
    BuildContext context,
    String uid,
    StandInDatabase database,
    UserRepository users,
    OrganizationRepository organizations) async {
  final id = 'personal-calculation';
  final organizationId = Follow.personalOrganizationId(uid);
  final existing = await database.getFollow(id);
  final policy = existing == null
      ? null
      : await organizations.getResolvedPolicy(
          uid: uid,
          organizationId: organizationId,
          scopeId: 'global',
          followId: id);
  final calendar = existing == null
      ? AttendanceCalendar.unconfigured
      : await organizations.getResolvedCalendar(
          uid: uid,
          organizationId: organizationId,
          scopeId: 'global',
          followId: id);
  if (!context.mounted) return;
  await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RulesEditorPage(
              title: 'Custom calculation',
              policy: policy,
              calendar: calendar,
              onSave: (draft) async {
                final calendars = CalendarRepository(database, users.remote,
                    uid: uid, followId: id);
                final state = await calendars.read();
                if (!context.mounted) return;
                if (state?.policy != null) {
                  await confirmPersonalRuleStart(
                      context,
                      calendars,
                      state!,
                      draft.policy(organizationId, 'global', 'personal-$id', 1),
                      draft.calendar(
                          organizationId, 'global', 'personal-cal-$id', 1));
                }
                await users.usePersonalCalculation(
                    uid,
                    Follow(
                        id: id,
                        organizationId: organizationId,
                        scopeId: 'global',
                        status: 'active',
                        followedAt: existing?.followedAt ?? DateTime.now(),
                        personalTargetPercent: draft.target,
                        personalBasis: draft.basis,
                        personalEvaluationPeriod: draft.period,
                        personalFullUnit: draft.fullUnit,
                        personalHalfUnit: draft.halfUnit,
                        personalStartDate: draft.start,
                        personalEndDate: draft.end,
                        personalWeeklyOffs: jsonEncode(draft.weeklyOffs),
                        personalOffSaturdays: jsonEncode(draft.offSaturdays),
                        personalHolidays: jsonEncode({
                          'replace': true,
                          'holidays':
                              draft.holidays.map((h) => h.toJson()).toList()
                        }),
                        isPersonalCalendarConfigured: true),
                    organizations,
                    presented: state,
                    policy: draft.policy(
                        organizationId, 'global', 'personal-$id', 1),
                    calendar: draft.calendar(
                        organizationId, 'global', 'personal-cal-$id', 1));
              })));
}

class FollowingPage extends StatefulWidget {
  const FollowingPage(
      {super.key,
      required this.database,
      required this.userRepository,
      required this.organizationRepository,
      required this.uid,
      this.activeFollowId,
      this.discoveryOnly = false,
      this.onDeleteAccount,
      this.onLogout});
  final StandInDatabase database;
  final UserRepository userRepository;
  final OrganizationRepository organizationRepository;
  final String uid;
  final String? activeFollowId;
  final bool discoveryOnly;
  final VoidCallback? onLogout;
  final void Function(BuildContext)? onDeleteAccount;
  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class OrganizationFollowPreview extends StatefulWidget {
  const OrganizationFollowPreview(
      {super.key,
      required this.organization,
      required this.organizations,
      required this.users,
      required this.database,
      required this.uid});
  final Organization organization;
  final OrganizationRepository organizations;
  final UserRepository users;
  final StandInDatabase database;
  final String uid;
  @override
  State<OrganizationFollowPreview> createState() =>
      _OrganizationFollowPreviewState();
}

class _OrganizationFollowPreviewState extends State<OrganizationFollowPreview> {
  late Future<((AttendanceCalendar, int), AttendancePolicy?)> _details =
      _load();
  bool _busy = false;
  bool _followed = false;
  String? _error;
  RuleRevision? _publishedRules;
  Future<((AttendanceCalendar, int), AttendancePolicy?)> _load() async {
    final snapshot = await widget.organizations
        .sharedCalendarSnapshot(widget.organization.id);
    final policy = await widget.organizations
        .getOfficialPolicyForScope(widget.organization.id, 'global');
    if (policy == null) return (snapshot, null);
    final (rules, version) =
        await widget.organizations.sharedRulesSnapshot(widget.organization.id);
    if (version > 0) {
      _publishedRules = await widget.organizations
          .nextRuleRevision(widget.organization.id, version - 1);
      final current = _publishedRules!.effectiveDate
              .isAfter(DateUtils.dateOnly(DateTime.now()))
          ? _publishedRules!.before
          : rules;
      return ((current.calendar, snapshot.$2), current.policy);
    }
    return (snapshot, policy);
  }

  Future<void> _follow((AttendanceCalendar, int) snapshot,
      {RulesDraft? draft}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final org = widget.organization;
      final settings = draft == null
          ? null
          : Follow(
              id: Scope.generateId(org.id, 'follow', 'global'),
              organizationId: org.id,
              scopeId: 'global',
              status: 'active',
              followedAt: DateTime.now(),
              personalBasis: draft.basis,
              personalEvaluationPeriod: draft.period,
              personalTargetPercent: draft.target,
              personalFullUnit: draft.fullUnit,
              personalHalfUnit: draft.halfUnit,
              personalStartDate: draft.start,
              personalEndDate: draft.end,
              personalWeeklyOffs: jsonEncode(draft.weeklyOffs),
              personalOffSaturdays: jsonEncode(draft.offSaturdays),
              personalHolidays: jsonEncode({
                'replace': true,
                'holidays': draft.holidays.map((h) => h.toJson()).toList()
              }),
              isPersonalCalendarConfigured: true);
      await widget.users
          .followScope(widget.uid, org, 'global', widget.organizations,
              acceptedCalendar:
                  draft?.calendar(org.id, 'global', 'personal-calendar', 1) ??
                      snapshot.$1,
              reviewedVersion: snapshot.$2,
              personalSettings: settings,
              acceptedPolicy:
                  draft?.policy(org.id, 'global', 'personal-calendar', 1) ??
                      await widget.organizations
                          .getOfficialPolicyForScope(org.id, 'global'),
              initialRuleRevision: draft == null ? _publishedRules : null);
      _followed = true;
      if (mounted && draft == null) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = actionError(e));
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.organization.name)),
      body: FutureBuilder<((AttendanceCalendar, int), AttendancePolicy?)>(
          future: _details,
          builder: (context, data) {
            if (data.hasError) {
              return Center(
                  child: TextButton.icon(
                      onPressed: () => setState(() => _details = _load()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry')));
            }
            if (!data.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final snapshot = data.data!.$1;
            final policy = data.data!.$2;
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text('${widget.organization.followerCount} followers'),
              const SizedBox(height: 20),
              if (policy != null) ...[
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Attendance target'),
                    subtitle: Text('${policy.minimumPercent ?? 0}%')),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Full day'),
                    subtitle: Text(
                        '${policy.fullUnit} ${policy.basis.label(policy.fullUnit)}')),
              ] else
                const Text('No shared attendance rules published'),
              const Divider(height: 32),
              for (final h in snapshot.$1.holidays)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.beach_access_outlined),
                    title: Text(h.name),
                    subtitle:
                        Text('${h.date.day}/${h.date.month}/${h.date.year}')),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (policy != null) {
                            try {
                              await _follow(snapshot);
                            } catch (_) {}
                          } else {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RulesEditorPage(
                                        title: 'My calculation',
                                        calendar: snapshot.$1,
                                        onSave: (draft) =>
                                            _follow(snapshot, draft: draft))));
                            if (context.mounted && _followed) {
                              Navigator.pop(context, true);
                            }
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: Text(_busy
                      ? 'Following...'
                      : policy == null
                          ? 'Follow and set my calculation'
                          : 'Follow organization')),
            ]);
          }));
}

class _FollowingPageState extends State<FollowingPage> {
  final _search = TextEditingController();
  late Future<List<Organization>> _results;
  OrganizationType _type = OrganizationType.college;
  bool _busy = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _results = _initialResults();
  }

  Future<List<Organization>> _initialResults() async {
    final profile = await widget.userRepository.getProfile(widget.uid);
    _type = profile?.role == AppRole.employee
        ? OrganizationType.company
        : OrganizationType.college;
    if (mounted) setState(() {});
    return widget.organizationRepository.searchOrganizations('', _type);
  }

  void _find() => setState(() => _results =
      widget.organizationRepository.searchOrganizations(_search.text, _type));

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(actionError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openOrganization(Organization org) async {
    final followed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => OrganizationFollowPreview(
                organization: org,
                organizations: widget.organizationRepository,
                users: widget.userRepository,
                database: widget.database,
                uid: widget.uid)));
    if (mounted && widget.discoveryOnly && followed == true) {
      Navigator.pop(context);
      return;
    }
    if (mounted) _find();
  }

  Future<void> _followMenu(FollowRow row, String action) => _run(() async {
        final follow = UserRepository.followFromRow(row);
        if (action == 'switch') {
          await widget.userRepository.prepareFollowContext(
              widget.uid, row.id, widget.organizationRepository);
          await widget.userRepository.activateFollow(widget.uid, row.id);
        } else if (action == 'retry') {
          await widget.userRepository.saveFollow(widget.uid, follow);
        } else if (action == 'personal') {
          final policy = await widget.organizationRepository.getResolvedPolicy(
              uid: widget.uid,
              organizationId: row.organizationId,
              scopeId: row.scopeId,
              followId: row.id);
          final calendar = await widget.organizationRepository
              .getResolvedCalendar(
                  uid: widget.uid,
                  organizationId: row.organizationId,
                  scopeId: row.scopeId,
                  followId: row.id);
          if (mounted) {
            await editPersonalRules(context, widget.uid, widget.userRepository,
                follow, policy, calendar);
          }
        } else if (action == 'reset') {
          final reset = await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                      title: const Text('Use shared rules?'),
                      content: const Text(
                          'Your personal rules for this group will be removed. Attendance history stays unchanged.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialog, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(dialog, true),
                            child: const Text('Use shared rules'))
                      ]));
          if (reset == true) {
            await widget.userRepository
                .saveFollow(widget.uid, follow.withoutPersonalSettings);
          }
        } else if (action == 'unfollow') {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                      title: const Text('Unfollow this group?'),
                      content:
                          const Text('Your attendance and plans will be kept.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialog, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(dialog, true),
                            child: const Text('Unfollow'))
                      ]));
          if (confirmed == true) {
            await widget.userRepository.unfollow(widget.uid, follow);
          }
        }
      });

  Future<void> _createOrganization() async {
    var name = '';
    final title = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: Text(_type == OrganizationType.college
                    ? 'Create college'
                    : 'Create company'),
                content: TextFormField(
                    onChanged: (value) => name = value,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (name.trim().length >= 2) {
                          Navigator.pop(dialog, name.trim());
                        }
                      },
                      child: const Text('Set rules'))
                ]));
    if (title == null || !mounted) return;
    final org = Organization(
        id: 'org-${DateTime.now().microsecondsSinceEpoch}',
        name: title,
        type: _type,
        createdBy: widget.uid);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RulesEditorPage(
                title: '$title rules',
                calendar: AttendanceCalendar.unconfigured,
                onSave: (draft) async {
                  final profile =
                      await widget.userRepository.getProfile(widget.uid);
                  if (profile == null) {
                    throw StateError('Profile is unavailable');
                  }
                  final policy =
                      draft.policy(org.id, 'global', 'policy-global', 1);
                  final calendar =
                      draft.calendar(org.id, 'global', 'cal-global', 1);
                  final follow = Follow(
                      id: Scope.generateId(org.id, 'follow', 'global'),
                      organizationId: org.id,
                      scopeId: 'global',
                      status: 'active',
                      followedAt: DateTime.now());
                  await widget.organizationRepository.setupOrganization(
                      org: org,
                      policy: policy,
                      calendar: calendar,
                      membership: Membership(
                          uid: widget.uid,
                          organizationId: org.id,
                          status: 'follower',
                          joinedAt: DateTime.now()),
                      follow: follow,
                      uid: widget.uid);
                  await widget.userRepository
                      .activateFollow(widget.uid, follow.id);
                })));
    if (mounted &&
        widget.discoveryOnly &&
        (await widget.userRepository.getProfile(widget.uid))?.activeFollowId ==
            Scope.generateId(org.id, 'follow', 'global') &&
        mounted) {
      Navigator.pop(context);
      return;
    }
    if (mounted) _find();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(children: [
            const Expanded(
                child: Text('Choose organization',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
            IconButton(
                tooltip: 'Custom calculation',
                onPressed: () => _run(() => openCustomCalculation(
                    context,
                    widget.uid,
                    widget.database,
                    widget.userRepository,
                    widget.organizationRepository)),
                icon: const Icon(Icons.calculate_outlined)),
            IconButton(
                tooltip: 'Create organization',
                onPressed: _createOrganization,
                icon: const Icon(Icons.add_business_outlined)),
            if (widget.onDeleteAccount != null)
              IconButton(
                  tooltip: 'Delete account',
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () => widget.onDeleteAccount!(context)),
            if (widget.onLogout != null)
              IconButton(
                  tooltip: 'Sign out',
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout))
          ]),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          if (!widget.discoveryOnly)
            StreamBuilder<List<FollowRow>>(
                stream: widget.database.watchFollows(),
                builder: (context, snapshot) {
                  final follows = snapshot.data ?? [];
                  if (follows.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No groups followed yet.'));
                  }
                  return Column(
                      children: follows
                          .map((row) =>
                              FutureBuilder<(Organization?, ScopeRow?)>(
                                future: (() async => (
                                      await widget.organizationRepository
                                          .getOrganization(row.organizationId),
                                      await widget.database
                                          .getScope(row.scopeId)
                                    ))(),
                                builder: (context, details) {
                                  final active =
                                      row.id == widget.activeFollowId;
                                  final follow =
                                      UserRepository.followFromRow(row);
                                  return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                          active
                                              ? Icons.radio_button_checked
                                              : Icons.groups_outlined,
                                          color: active
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null),
                                      title: Text(details.data?.$1?.name ??
                                          'Organization'),
                                      subtitle: StreamBuilder<SyncQueueRow?>(
                                          stream: widget.database
                                              .watchOperation(
                                                  'follow:${row.id}'),
                                          builder: (_, upload) => Text(
                                              '${follow.isPersonalCalculation ? 'Private settings' : details.data?.$2?.name ?? 'Organization rules'}'
                                              '${!follow.isPersonalCalculation && follow.hasPersonalSettings ? ' | My rules' : ''}'
                                              '${upload.data == null ? '' : upload.data!.lastError == null ? ' | Pending sync' : ' | Sync failed'}')),
                                      onTap: active
                                          ? null
                                          : () => _followMenu(row, 'switch'),
                                      trailing: PopupMenuButton<String>(
                                          tooltip: 'Follow options',
                                          onSelected: (action) =>
                                              _followMenu(row, action),
                                          itemBuilder: (_) => [
                                                if (!active)
                                                  PopupMenuItem(
                                                      value: 'switch',
                                                      child: Text(follow
                                                              .isPersonalCalculation
                                                          ? 'Use calculation'
                                                          : 'Use this group')),
                                                const PopupMenuItem(
                                                    value: 'personal',
                                                    child: Text('My rules')),
                                                const PopupMenuItem(
                                                    value: 'retry',
                                                    child: Text('Retry sync')),
                                                if (follow
                                                        .hasPersonalSettings &&
                                                    !follow
                                                        .isPersonalCalculation)
                                                  const PopupMenuItem(
                                                      value: 'reset',
                                                      child: Text(
                                                          'Use shared rules')),
                                                PopupMenuItem(
                                                    value: 'unfollow',
                                                    child: Text(follow
                                                            .isPersonalCalculation
                                                        ? 'Stop using calculation'
                                                        : 'Unfollow')),
                                              ]));
                                },
                              ))
                          .toList());
                }),
          const Divider(height: 32),
          const Text('Find a college or company',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SegmentedButton<OrganizationType>(
              segments: const [
                ButtonSegment(
                    value: OrganizationType.college,
                    label: Text('Colleges'),
                    icon: Icon(Icons.school_outlined)),
                ButtonSegment(
                    value: OrganizationType.company,
                    label: Text('Companies'),
                    icon: Icon(Icons.business_outlined)),
              ],
              selected: {
                _type
              },
              onSelectionChanged: (types) {
                _type = types.first;
                _find();
              }),
          const SizedBox(height: 16),
          TextField(
              controller: _search,
              onChanged: (_) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 300), _find);
              },
              onSubmitted: (_) => _find(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _find,
                      icon: const Icon(Icons.arrow_forward)))),
          const SizedBox(height: 16),
          FutureBuilder<List<Organization>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(children: [
                    const Text('Organizations could not be loaded.'),
                    TextButton.icon(
                        onPressed: _find,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'))
                  ]);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Text('No matching organizations.');
                }
                return Column(
                    children: snapshot.data!
                        .map((org) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(org.type == OrganizationType.college
                                ? Icons.school_outlined
                                : Icons.business_outlined),
                            title: Text(org.name),
                            subtitle: Text(
                                '${org.followerCount} followers${org.branch == null ? '' : ' | ${org.branch}'}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openOrganization(org)))
                        .toList());
              }),
        ],
      ));
}

class OrganizationGroupsPage extends StatefulWidget {
  const OrganizationGroupsPage(
      {super.key,
      required this.repository,
      required this.organization,
      required this.onFollow,
      this.uid,
      this.parent});
  final OrganizationRepository repository;
  final Organization organization;
  final Scope? parent;
  final String? uid;
  final Future<void> Function(Scope?) onFollow;
  @override
  State<OrganizationGroupsPage> createState() => _OrganizationGroupsPageState();
}

class _OrganizationGroupsPageState extends State<OrganizationGroupsPage> {
  late Future<List<Scope>> _scopes;
  String _filter = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _scopes = widget.repository
        .getScopesForParent(widget.organization.id, widget.parent?.id);
  }

  Future<void> _preview(Scope? scope) async {
    setState(() => _busy = true);
    try {
      final id = scope?.id ?? 'global';
      final policy = await widget.repository.getOfficialPolicyForScope(
          widget.organization.id, id,
          activePolicyId:
              scope == null ? widget.organization.activePolicyId : null);
      final calendar = await widget.repository.getOfficialCalendarForScope(
          widget.organization.id, id,
          activeCalendarId:
              scope == null ? widget.organization.activeCalendarId : null);
      if (!mounted) return;
      final follow = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: Text(scope?.name ?? widget.organization.name),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          '${scope?.followerCount ?? widget.organization.followerCount} followers'),
                      const SizedBox(height: 12),
                      Text(policy == null
                          ? 'Shared rules not set'
                          : '${policy.minimumPercent?.toStringAsFixed(1) ?? 'Not set'}% target | ${periodName(policy.evaluationPeriod)}'),
                      if (policy != null)
                        Text(
                            '${policy.fullUnit} ${policy.basis.label(policy.fullUnit)} per day'),
                      Text(calendar.weeklyOffs.isEmpty
                          ? 'No weekly days off'
                          : 'Days off: ${calendar.weeklyOffs.map((day) => const [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ][day - 1]).join(', ')}'),
                      if (policy?.startDate != null && policy?.endDate != null)
                        Text(
                            '${policy!.startDate!.day}/${policy.startDate!.month}/${policy.startDate!.year} to ${policy.endDate!.day}/${policy.endDate!.month}/${policy.endDate!.year}'),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(dialog, true),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Follow'))
                ],
              ));
      if (follow != true) return;
      await widget.onFollow(scope);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(actionError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editGroup({Scope? existing}) async {
    Scope? scope = existing;
    if (scope == null) {
      var name = '';
      String type = widget.organization.type == OrganizationType.college
          ? 'branch'
          : 'location';
      final result = await showDialog<(String, String)>(
          context: context,
          builder: (dialog) => StatefulBuilder(
              builder: (_, update) => AlertDialog(
                    title: const Text('Create a group'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          onChanged: (value) => name = value,
                          maxLength: 100,
                          decoration:
                              const InputDecoration(labelText: 'Group name')),
                      DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration:
                              const InputDecoration(labelText: 'Group type'),
                          items: const [
                            DropdownMenuItem(
                                value: 'branch', child: Text('Branch')),
                            DropdownMenuItem(
                                value: 'department', child: Text('Department')),
                            DropdownMenuItem(
                                value: 'location', child: Text('Location')),
                            DropdownMenuItem(
                                value: 'semester', child: Text('Semester'))
                          ],
                          onChanged: (value) => update(() => type = value!)),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            if (name.trim().length >= 2) {
                              Navigator.pop(dialog, (name.trim(), type));
                            }
                          },
                          child: const Text('Set rules'))
                    ],
                  )));
      if (result == null || !mounted) return;
      scope = Scope(
          id: Scope.generateId(
              widget.organization.id, result.$2, result.$1, widget.parent?.id),
          organizationId: widget.organization.id,
          parentId: widget.parent?.id,
          name: result.$1,
          type: result.$2,
          createdBy: widget.uid);
    }
    final selected = scope;
    setState(() => _busy = true);
    try {
      final policy = await widget.repository
          .getOfficialPolicyForScope(widget.organization.id, selected.id);
      final calendar = await widget.repository
          .getOfficialCalendarForScope(widget.organization.id, selected.id);
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RulesEditorPage(
                  title: '${selected.name} rules',
                  policy: policy,
                  calendar: calendar,
                  onSave: (draft) async {
                    final version = DateTime.now().microsecondsSinceEpoch;
                    final p = draft.policy(widget.organization.id, selected.id,
                        'scope-${selected.id}-$version', version);
                    final c = draft.calendar(widget.organization.id,
                        selected.id, 'cal-${selected.id}-$version', version);
                    await widget.repository.publishScopeRules(
                        selected.copyWith(
                            activePolicyId: p.id, activeCalendarId: c.id),
                        p,
                        c);
                  })));
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group rules could not be loaded: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.parent?.name ?? widget.organization.name),
            actions: [
              if (widget.uid != null)
                IconButton(
                    tooltip: 'Create group',
                    onPressed: _busy ? null : _editGroup,
                    icon: const Icon(Icons.group_add_outlined)),
            ]),
        body: AbsorbPointer(
            absorbing: _busy,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (_busy) const LinearProgressIndicator(),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_outlined),
                  title: Text(widget.parent == null
                      ? 'Organization rules'
                      : '${widget.parent!.name} rules'),
                  subtitle: Text(
                      '${widget.parent?.followerCount ?? widget.organization.followerCount} followers'),
                  trailing: const Icon(Icons.person_add_alt_1),
                  onTap: () => _preview(widget.parent)),
              const Divider(height: 32),
              TextField(
                  onChanged: (value) =>
                      setState(() => _filter = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                      hintText: 'Find a branch, group or location',
                      prefixIcon: Icon(Icons.search))),
              const SizedBox(height: 20),
              FutureBuilder<List<Scope>>(
                  future: _scopes,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(children: [
                        const Text('Groups could not be loaded.'),
                        TextButton.icon(
                            onPressed: () => setState(_reload),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'))
                      ]);
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final scopes = snapshot.data!
                        .where((scope) =>
                            scope.name.toLowerCase().contains(_filter))
                        .toList();
                    if (scopes.isEmpty) {
                      return const Text('No matching groups yet.');
                    }
                    return Column(
                        children: scopes
                            .map((scope) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(scope.type == 'location'
                                    ? Icons.location_on_outlined
                                    : Icons.groups_outlined),
                                title: Text(scope.name),
                                subtitle: Text(
                                    '${scope.followerCount} followers | ${scope.type}'),
                                trailing: PopupMenuButton<String>(
                                    tooltip: 'Group options',
                                    onSelected: (action) {
                                      if (action == 'follow') _preview(scope);
                                      if (action == 'edit') {
                                        _editGroup(existing: scope);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                          const PopupMenuItem(
                                              value: 'follow',
                                              child:
                                                  Text('Preview and follow')),
                                          if (scope.createdBy == widget.uid &&
                                              widget.uid != null)
                                            const PopupMenuItem(
                                                value: 'edit',
                                                child:
                                                    Text('Edit shared rules'))
                                        ]),
                                onTap: () async {
                                  final followed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              OrganizationGroupsPage(
                                                  repository: widget.repository,
                                                  organization:
                                                      widget.organization,
                                                  parent: scope,
                                                  uid: widget.uid,
                                                  onFollow: widget.onFollow)));
                                  if (followed == true && context.mounted) {
                                    Navigator.pop(context, true);
                                    return;
                                  }
                                  if (mounted) setState(_reload);
                                }))
                            .toList());
                  }),
            ])),
      );
}
