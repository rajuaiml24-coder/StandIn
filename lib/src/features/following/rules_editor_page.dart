import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/attendance.dart';
import '../../domain/app_errors.dart';

String periodName(EvaluationPeriod period) => switch (period) {
      EvaluationPeriod.weekly => 'Weekly',
      EvaluationPeriod.monthly => 'Monthly',
      EvaluationPeriod.quarterly => 'Quarterly',
      EvaluationPeriod.semester => 'Semester',
      EvaluationPeriod.academicYear => 'Academic year',
      EvaluationPeriod.halfYear => 'Half year',
      EvaluationPeriod.custom => 'Custom dates',
    };

class RulesDraft {
  const RulesDraft(
      {required this.basis,
      required this.period,
      required this.target,
      required this.fullUnit,
      required this.halfUnit,
      required this.weeklyOffs,
      required this.offSaturdays,
      required this.holidays,
      this.start,
      this.end,
      this.leaveTreatment = LeaveTreatment.noCredit,
      this.weekOffCredit = false,
      this.holidayCredit = false,
      this.oneVisitFullDay = false});
  final CalculationBasis basis;
  final EvaluationPeriod period;
  final double target, fullUnit, halfUnit;
  final List<int> weeklyOffs, offSaturdays;
  final List<Holiday> holidays;
  final DateTime? start, end;
  final LeaveTreatment leaveTreatment;
  final bool weekOffCredit, holidayCredit;
  final bool oneVisitFullDay;

  AttendancePolicy policy(
          String orgId, String scopeId, String id, int version) =>
      AttendancePolicy(
        id: id,
        organizationId: orgId,
        scopeId: scopeId,
        version: version,
        effectiveFrom: DateTime.now(),
        state: PolicyState.community,
        evaluationPeriod: period,
        basis: basis,
        minimumPercent: target,
        fullUnit: fullUnit,
        halfUnit: halfUnit,
        weeklyOffs: weeklyOffs,
        startDate: start,
        endDate: end,
        leaveTreatment: leaveTreatment,
        weekOffCredit: weekOffCredit,
        holidayCredit: holidayCredit,
        oneVisitFullDay: oneVisitFullDay,
      );

  AttendanceCalendar calendar(
          String orgId, String scopeId, String id, int version) =>
      AttendanceCalendar(
        id: id,
        organizationId: orgId,
        scopeId: scopeId,
        version: version,
        effectiveFrom: DateTime.now(),
        weeklyOffs: weeklyOffs,
        offSaturdays: offSaturdays,
        holidays: holidays,
        isConfigured: true,
      );
}

class RulesEditorPage extends StatefulWidget {
  const RulesEditorPage(
      {super.key,
      required this.title,
      required this.calendar,
      required this.onSave,
      this.policy,
      this.initialDraft,
      this.onDraftChanged,
      this.onDiscardDraft,
      this.saveLabel = 'Save rules',
      this.notice});
  final String title;
  final AttendancePolicy? policy;
  final AttendanceCalendar calendar;
  final Future<void> Function(RulesDraft) onSave;
  final String saveLabel;
  final String? notice;
  final Map<String, dynamic>? initialDraft;
  final ValueChanged<Map<String, dynamic>>? onDraftChanged;
  final Future<void> Function()? onDiscardDraft;
  @override
  State<RulesEditorPage> createState() => _RulesEditorPageState();
}

class _RulesEditorPageState extends State<RulesEditorPage> {
  final _form = GlobalKey<FormState>();
  late CalculationBasis _basis;
  late EvaluationPeriod _period;
  late TextEditingController _target, _full, _half;
  late Set<int> _offs, _saturdays;
  late List<Holiday> _holidays;
  DateTime? _start, _end;
  late LeaveTreatment _leave;
  late bool _weekOffCredit, _holidayCredit;
  late bool _oneVisitFullDay;
  bool _saving = false;
  String? _error;
  bool _complete = false;
  Map<String, dynamic> get _draft => {
        'basis': _basis.name,
        'period': _period.name,
        'target': _target.text,
        'full': _full.text,
        'half': _half.text,
        'offs': _offs.toList(),
        'saturdays': _saturdays.toList(),
        'holidays': _holidays.map((h) => h.toJson()).toList(),
        'start': _start?.toIso8601String(),
        'end': _end?.toIso8601String(),
        'leave': _leave.name,
        'weekOffCredit': _weekOffCredit,
        'holidayCredit': _holidayCredit,
        'oneVisitFullDay': _oneVisitFullDay,
      };
  void _notifyDraft() {
    if (!_complete) widget.onDraftChanged?.call(_draft);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _notifyDraft();
  }

  bool get _needsDates => [
        EvaluationPeriod.semester,
        EvaluationPeriod.academicYear,
        EvaluationPeriod.halfYear,
        EvaluationPeriod.custom
      ].contains(_period);

  @override
  void initState() {
    super.initState();
    final policy = widget.policy;
    _basis = policy?.basis ?? CalculationBasis.days;
    _period = policy?.evaluationPeriod ?? EvaluationPeriod.monthly;
    _target = TextEditingController(text: '${policy?.minimumPercent ?? 75}');
    _full = TextEditingController(text: '${policy?.fullUnit ?? 1}');
    _half = TextEditingController(text: '${policy?.halfUnit ?? 0.5}');
    _offs = widget.calendar.weeklyOffs.toSet();
    _saturdays = widget.calendar.offSaturdays.toSet();
    _holidays = [...widget.calendar.holidays];
    _start = policy?.startDate;
    _end = policy?.endDate;
    _leave = policy?.leaveTreatment ?? LeaveTreatment.noCredit;
    _weekOffCredit = policy?.weekOffCredit ?? false;
    _holidayCredit = policy?.holidayCredit ?? false;
    _oneVisitFullDay = policy?.oneVisitFullDay ?? false;
    final draft = widget.initialDraft;
    if (draft != null) {
      _basis = CalculationBasis.values.byName(draft['basis'] as String);
      _period = EvaluationPeriod.values.byName(draft['period'] as String);
      _target.text = draft['target'] as String;
      _full.text = draft['full'] as String;
      _half.text = draft['half'] as String;
      _offs = (draft['offs'] as List).cast<int>().toSet();
      _saturdays = (draft['saturdays'] as List).cast<int>().toSet();
      _holidays = (draft['holidays'] as List)
          .map((h) => Holiday.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList();
      _start = draft['start'] == null
          ? null
          : DateTime.parse(draft['start'] as String);
      _end =
          draft['end'] == null ? null : DateTime.parse(draft['end'] as String);
      _leave = LeaveTreatment.values.byName(draft['leave'] as String);
      _weekOffCredit = draft['weekOffCredit'] as bool;
      _holidayCredit = draft['holidayCredit'] as bool;
      _oneVisitFullDay = draft['oneVisitFullDay'] as bool? ?? false;
    }
    for (final field in [_target, _full, _half]) {
      field.addListener(_notifyDraft);
    }
  }

  @override
  void dispose() {
    _target.dispose();
    _full.dispose();
    _half.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100));

  Future<void> _addHoliday() async {
    final date = await _pickDate(null);
    if (date == null || !mounted) return;
    var input = '';
    final name = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: const Text('Holiday'),
              content: TextFormField(
                  onChanged: (value) => input = value,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Name')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (input.trim().isNotEmpty) {
                        Navigator.pop(dialog, input.trim());
                      }
                    },
                    child: const Text('Add'))
              ],
            ));
    if (name != null && mounted) {
      setState(() {
        _holidays
            .removeWhere((holiday) => DateUtils.isSameDay(holiday.date, date));
        _holidays.add(Holiday(date: date, name: name));
        _holidays.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_needsDates &&
        (_start == null || _end == null || _end!.isBefore(_start!))) {
      setState(() => _error = 'Choose a valid start and end date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(RulesDraft(
          basis: _basis,
          period: _period,
          target: double.parse(_target.text),
          fullUnit: double.parse(_full.text),
          halfUnit: double.parse(_half.text),
          weeklyOffs: _offs.toList()..sort(),
          offSaturdays: _offs.contains(6) ? [] : (_saturdays.toList()..sort()),
          holidays: _holidays,
          start: _needsDates ? _start : null,
          end: _needsDates ? _end : null,
          leaveTreatment: _leave,
          weekOffCredit: _weekOffCredit,
          holidayCredit: _holidayCredit,
          oneVisitFullDay: _oneVisitFullDay));
      _complete = true;
      if (mounted) Navigator.pop(context, true);
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
        appBar: AppBar(title: Text(widget.title), actions: [
          if (widget.onDiscardDraft != null)
            IconButton(
                tooltip: 'Discard draft and reload',
                icon: const Icon(Icons.refresh),
                onPressed: _saving
                    ? null
                    : () async {
                        final discard = await showDialog<bool>(
                            context: context,
                            builder: (dialog) => AlertDialog(
                                    title: const Text('Discard this draft?'),
                                    content: const Text(
                                        'Reload the latest shared rules. Published rules and attendance stay unchanged.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialog, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(dialog, true),
                                          child: const Text('Discard draft'))
                                    ]));
                        if (discard == true) {
                          _complete = true;
                          try {
                            await widget.onDiscardDraft!();
                          } catch (error) {
                            _complete = false;
                            if (mounted) {
                              setState(() => _error = actionError(error));
                            }
                          }
                        }
                      })
        ]),
        body: AbsorbPointer(
            absorbing: _saving,
            child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (widget.notice != null) ...[
                      Text(widget.notice!),
                      const SizedBox(height: 16),
                    ],
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'One class or swipe counts as a full day'),
                        subtitle: const Text(
                            'Count one day when you attend, even briefly.'),
                        value: _oneVisitFullDay,
                        onChanged: (value) => setState(() {
                              _oneVisitFullDay = value;
                              if (value) {
                                _basis = CalculationBasis.days;
                                _full.text = '1';
                                _half.text = '0.5';
                              }
                            })),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CalculationBasis>(
                        key: ValueKey('basis-$_basis'),
                        initialValue: _basis,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Track attendance by'),
                        items: CalculationBasis.values
                            .map((basis) => DropdownMenuItem(
                                value: basis,
                                child: Text(switch (basis) {
                                  CalculationBasis.days => 'Days',
                                  CalculationBasis.hours => 'Hours',
                                  CalculationBasis.periods => 'Classes'
                                })))
                            .toList(),
                        onChanged: (basis) => setState(() {
                              _basis = basis!;
                              if (basis != CalculationBasis.days) {
                                _oneVisitFullDay = false;
                              }
                              _full.text = basis == CalculationBasis.days
                                  ? '1'
                                  : (basis == CalculationBasis.hours
                                      ? '8'
                                      : '6');
                              _half.text = '${double.parse(_full.text) / 2}';
                            })),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EvaluationPeriod>(
                        initialValue: _period,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Attendance period'),
                        items: EvaluationPeriod.values
                            .map((period) => DropdownMenuItem(
                                value: period, child: Text(periodName(period))))
                            .toList(),
                        onChanged: (period) =>
                            setState(() => _period = period!)),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _target,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Target', suffixText: '%'),
                        validator: (value) {
                          final number = double.tryParse(value ?? '');
                          return number == null ||
                                  !number.isFinite ||
                                  number < 0 ||
                                  number > 100
                              ? 'Enter 0 to 100'
                              : null;
                        }),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                              controller: _full,
                              readOnly: _basis == CalculationBasis.days,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Full day units'),
                              validator: (value) {
                                final number = double.tryParse(value ?? '');
                                return number == null ||
                                        !number.isFinite ||
                                        number <= 0
                                    ? 'Must be above zero'
                                    : null;
                              })),
                      const SizedBox(width: 16),
                      Expanded(
                          child: TextFormField(
                              controller: _half,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Half day units'),
                              validator: (value) {
                                final number = double.tryParse(value ?? '');
                                final full = double.tryParse(_full.text) ?? 0;
                                return number == null ||
                                        !number.isFinite ||
                                        number < 0 ||
                                        number > full
                                    ? 'Enter 0 to $full'
                                    : null;
                              })),
                    ]),
                    if (_needsDates) ...[
                      const SizedBox(height: 20),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.date_range),
                          title: const Text('Start date'),
                          subtitle: Text(_start == null
                              ? 'Not set'
                              : DateFormat.yMMMd().format(_start!)),
                          onTap: () async {
                            final date = await _pickDate(_start);
                            if (date != null && mounted) {
                              setState(() => _start = date);
                            }
                          }),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event),
                          title: const Text('End date'),
                          subtitle: Text(_end == null
                              ? 'Not set'
                              : DateFormat.yMMMd().format(_end!)),
                          onTap: () async {
                            final date = await _pickDate(_end);
                            if (date != null && mounted) {
                              setState(() => _end = date);
                            }
                          }),
                    ],
                    const SizedBox(height: 24),
                    const Text('Weekly days off',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Wrap(children: [
                      for (var day = 1; day <= 7; day++)
                        SizedBox(
                            width: 94,
                            child: Row(children: [
                              Checkbox(
                                  value: _offs.contains(day),
                                  onChanged: (off) => setState(() {
                                        if (off!) {
                                          _offs.add(day);
                                        } else {
                                          _offs.remove(day);
                                        }
                                      })),
                              Text(const [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ][day - 1]),
                            ]))
                    ]),
                    if (!_offs.contains(6)) ...[
                      const SizedBox(height: 16),
                      const Text('Saturdays off',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Wrap(children: [
                        for (var week = 1; week <= 5; week++)
                          SizedBox(
                              width: 94,
                              child: Row(children: [
                                Checkbox(
                                    value: _saturdays.contains(week),
                                    onChanged: (off) => setState(() {
                                          if (off!) {
                                            _saturdays.add(week);
                                          } else {
                                            _saturdays.remove(week);
                                          }
                                        })),
                                Text(const [
                                  '1st',
                                  '2nd',
                                  '3rd',
                                  '4th',
                                  '5th'
                                ][week - 1]),
                              ]))
                      ]),
                    ],
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(
                          child: Text('Holidays',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                      IconButton(
                          tooltip: 'Add holiday',
                          onPressed: _addHoliday,
                          icon: const Icon(Icons.add))
                    ]),
                    for (final holiday in _holidays)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(holiday.name),
                          subtitle:
                              Text(DateFormat.yMMMd().format(holiday.date)),
                          trailing: IconButton(
                              tooltip: 'Remove holiday',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _holidays.remove(holiday)))),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<LeaveTreatment>(
                        initialValue: _leave,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Leave'),
                        items: const [
                          DropdownMenuItem(
                              value: LeaveTreatment.noCredit,
                              child: Text('No attendance credit')),
                          DropdownMenuItem(
                              value: LeaveTreatment.countsTowardTarget,
                              child: Text('Counts toward target')),
                          DropdownMenuItem(
                              value: LeaveTreatment.excluded,
                              child: Text('Excluded from required attendance')),
                        ],
                        onChanged: (v) => setState(() => _leave = v!)),
                    const SizedBox(height: 16),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Count attendance on days off'),
                        subtitle: const Text(
                            'If you attend, it counts toward your percentage. Working days stay the same.'),
                        value: _weekOffCredit,
                        onChanged: (v) => setState(() => _weekOffCredit = v)),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Count attendance on holidays'),
                        subtitle: const Text(
                            'If you attend, it counts toward your percentage. Working days stay the same.'),
                        value: _holidayCredit,
                        onChanged: (v) => setState(() => _holidayCredit = v)),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving...' : widget.saveLabel)),
                    const SizedBox(height: 24),
                  ],
                ))),
      );
}
