import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/calendar_repository.dart';
import '../../data/local/standin_database.dart';
import '../../data/attendance_repository.dart';
import '../../data/organization_repository.dart';
import '../../domain/attendance.dart';
import '../../domain/calendar_updates.dart';
import '../../domain/app_errors.dart';

class CalendarUpdatesPanel extends StatefulWidget {
  const CalendarUpdatesPanel(
      {super.key,
      required this.repository,
      required this.organizations,
      required this.organizationId});
  final CalendarRepository repository;
  final OrganizationRepository organizations;
  final String organizationId;
  @override
  State<CalendarUpdatesPanel> createState() => _CalendarUpdatesPanelState();
}

class _CalendarUpdatesPanelState extends State<CalendarUpdatesPanel> {
  StreamSubscription<int>? _subscription;
  int? _seen;
  @override
  void initState() {
    super.initState();
    _subscription = widget.organizations
        .watchCalendarRevisionVersion(widget.organizationId)
        .listen((version) {
      if (_seen != null && _seen != version && mounted) {
        setState(() { _pending = _load(); });
      }
      _seen = version;
    }, onError: (Object error) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  late Future<CalendarRevision?> _pending = _load();
  Future<CalendarRevision?> _load() async {
    await widget.repository.refresh();
    final state = await widget.repository.read();
    if (state == null) return null;
    return widget.organizations
        .nextCalendarRevision(widget.organizationId, state.reviewedVersion);
  }

  Future<void> _review(CalendarRevision revision) async {
    final state = await widget.repository.read();
    if (state == null || !mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CalendarReviewPage(
                repository: widget.repository,
                presented: state,
                revision: revision)));
    if (mounted) setState(() { _pending = _load(); });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CalendarRevision?>(
      future: _pending,
      builder: (context, data) {
        if (data.hasError) {
          return ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Calendar updates unavailable'),
              trailing: IconButton(
                  tooltip: 'Check calendar updates',
                  onPressed: () => setState(() { _pending = _load(); }),
                  icon: const Icon(Icons.refresh)));
        }
        if (data.data == null) {
          return Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  tooltip: 'Check calendar updates',
                  onPressed: () => setState(() { _pending = _load(); }),
                  icon: const Icon(Icons.sync)));
        }
        return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Your organization updated its calendar'),
            subtitle: Text('${data.data!.changes.length} changed dates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _review(data.data!));
      });
}

class CalendarReviewPage extends StatefulWidget {
  const CalendarReviewPage(
      {super.key,
      required this.repository,
      required this.presented,
      required this.revision});
  final CalendarRepository repository;
  final PersonalCalendarState presented;
  final CalendarRevision revision;
  @override
  State<CalendarReviewPage> createState() => _CalendarReviewPageState();
}

class _CalendarReviewPageState extends State<CalendarReviewPage> {
  final Map<String, bool> _choices = {};
  bool _saving = false;
  String? _error;
  String _description(Object? value) =>
      value == null ? 'Working day' : (value as Map)['name'] as String;
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository
          .applyReview(widget.presented, widget.revision, _choices);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = actionError(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendar = widget.presented.calendar;
    final keys = widget.revision.changes.keys.toList()..sort();
    return Scaffold(
        appBar: AppBar(title: const Text('Review calendar changes')),
        body: AbsorbPointer(
            absorbing: _saving,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Text('Update ${widget.revision.version}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(spacing: 12, children: [
                TextButton.icon(
                    onPressed: () => setState(() {
                          for (final k in keys) {
                            _choices[k] = true;
                          }
                        }),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Apply all')),
                TextButton.icon(
                    onPressed: () => setState(() {
                          for (final k in keys) {
                            _choices[k] = false;
                          }
                        }),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Keep all'))
              ]),
              for (final key in keys) ...[
                const Divider(height: 32),
                Text(DateFormat('d MMM yyyy').format(DateTime.parse(key)),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Proposed: ${_description(widget.revision.changes[key])}'),
                Text(
                    'Mine: ${calendar.holidays.where((h) => calendarDayKey(h.date) == key).map((h) => h.name).firstOrNull ?? (calendar.isNonWorkingDay(DateTime.parse(key)) ? 'Day off' : 'Working day')}'),
                if (widget.presented.dates[key]?['personal'] == true)
                  const Text('Applying replaces your personal edit.',
                      style: TextStyle(color: Colors.deepOrange)),
                FutureBuilder<AttendanceTableData?>(
                    future: widget.repository.database.getAttendance(
                        attendanceId(
                            DateTime.parse(key),
                            calendar.organizationId!,
                            calendar.scopeId ?? 'global')),
                    builder: (_, record) => record.data == null
                        ? const SizedBox.shrink()
                        : const Text(
                            'Recorded attendance is preserved. Applying may change the calculation.',
                            style: TextStyle(color: Colors.deepOrange))),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                          value: true,
                          icon: Icon(Icons.check),
                          label: Text('Apply')),
                      ButtonSegment(
                          value: false,
                          icon: Icon(Icons.lock_outline),
                          label: Text('Keep mine'))
                    ],
                    selected: _choices.containsKey(key) ? {_choices[key]!} : {},
                    onSelectionChanged: (values) => setState(() {
                          if (values.isEmpty) {
                            _choices.remove(key);
                          } else {
                            _choices[key] = values.first;
                          }
                        })),
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed:
                      _saving || _choices.length != keys.length ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save choices')),
            ])));
  }
}

class SharedHolidayEditor extends StatefulWidget {
  const SharedHolidayEditor(
      {super.key,
      required this.organizations,
      required this.organizationId,
      required this.uid});
  final OrganizationRepository organizations;
  final String organizationId, uid;
  @override
  State<SharedHolidayEditor> createState() => _SharedHolidayEditorState();
}

class _SharedHolidayEditorState extends State<SharedHolidayEditor> {
  late Future<AttendanceCalendar> _loading =
      widget.organizations.sharedCalendar(widget.organizationId);
  AttendanceCalendar? _base;
  List<Holiday>? _holidays;
  bool _saving = false;
  String? _error;
  Future<void> _add() async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    var name = '';
    final value = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Holiday name'),
                content: TextFormField(
                    onChanged: (value) => name = value,
                    maxLength: 80,
                    autofocus: true),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog,
                          name.trim().isEmpty ? 'Holiday' : name.trim()),
                      child: const Text('Add'))
                ]));
    if (value != null && mounted) {
      setState(() {
        _holidays!
            .removeWhere((h) => calendarDayKey(h.date) == calendarDayKey(date));
        _holidays!.add(Holiday(date: date, name: value));
        _holidays!.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  Future<void> _publish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.organizations.publishCalendarHolidays(
          widget.organizationId, widget.uid, _base!, _holidays!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = actionError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Edit shared calendar')),
      body: FutureBuilder<AttendanceCalendar>(
          future: _loading,
          builder: (context, data) {
            if (data.hasError) {
              return Center(
                  child: TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload calendar'),
                      onPressed: () => setState(() {
                            _base = null;
                            _holidays = null;
                            _loading = widget.organizations
                                .sharedCalendar(widget.organizationId);
                          })));
            }
            if (!data.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            _base ??= data.data;
            _holidays ??= [..._base!.holidays];
            return AbsorbPointer(
                absorbing: _saving,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  for (final h in _holidays!)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.beach_access_outlined),
                        title: Text(h.name),
                        subtitle: Text(DateFormat('d MMM yyyy').format(h.date)),
                        trailing: IconButton(
                            tooltip: 'Remove holiday',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _holidays!.remove(h)))),
                  TextButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Add holiday')),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                      onPressed: _publish,
                      icon: const Icon(Icons.publish_outlined),
                      label:
                          Text(_saving ? 'Publishing...' : 'Publish changes')),
                ]));
          }));
}
