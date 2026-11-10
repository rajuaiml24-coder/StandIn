import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/calendar_repository.dart';
import '../../data/organization_repository.dart';
import '../../domain/app_errors.dart';
import '../../domain/calendar_updates.dart';
import '../../domain/shared_rules.dart';
import 'calendar_updates_page.dart';
import 'rules_editor_page.dart';

class SharedRulesEditor extends StatefulWidget {
  const SharedRulesEditor(
      {super.key,
      required this.organizations,
      required this.organizationId,
      required this.uid});
  final OrganizationRepository organizations;
  final String organizationId, uid;
  @override
  State<SharedRulesEditor> createState() => _SharedRulesEditorState();
}

class _SharedRulesEditorState extends State<SharedRulesEditor> {
  Map<String, dynamic>? _draft;
  bool _publishingEnabled = false;
  Future<void> _draftWrites = Future.value();
  Future<(SharedRules, int)> _load() async {
    try {
      _publishingEnabled =
          await widget.organizations.sharedRulePublishingEnabled();
    } catch (_) {
      _publishingEnabled = false;
    }
    final shared =
        await widget.organizations.sharedRulesSnapshot(widget.organizationId);
    _draft = await widget.organizations
        .readRulesDraft(widget.uid, widget.organizationId);
    if (_draft != null) {
      return (
        SharedRules.fromJson(
            Map<String, dynamic>.from(_draft!['before'] as Map)),
        _draft!['version'] as int
      );
    }
    return shared;
  }

  late Future<(SharedRules, int)> _loading = _load();
  @override
  Widget build(BuildContext context) => FutureBuilder<(SharedRules, int)>(
      future: _loading,
      builder: (context, data) {
        if (data.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text('Shared rules')),
              body: Center(
                  child: TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload rules'),
                      onPressed: () => setState(() {
                            _loading = widget.organizations
                                .sharedRulesSnapshot(widget.organizationId);
                          }))));
        }
        if (!data.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final (before, version) = data.data!;
        return RulesEditorPage(
            key: ValueKey(_loading),
            title: 'Shared rules',
            notice: _publishingEnabled
                ? null
                : 'Sharing updates is temporarily unavailable. Your changes will be saved as a draft.',
            policy: before.policy,
            calendar: before.calendar,
            initialDraft: _draft?['draft'] == null
                ? null
                : Map<String, dynamic>.from(_draft!['draft'] as Map),
            onDraftChanged: (draft) {
              _draftWrites = _draftWrites.then((_) => widget.organizations
                      .saveRulesDraft(widget.uid, widget.organizationId, {
                    'before': before.toJson(),
                    'version': version,
                    'draft': draft
                  }));
            },
            onDiscardDraft: () async {
              await _draftWrites;
              await widget.organizations
                  .removeRulesDraft(widget.uid, widget.organizationId);
              if (mounted) {
                setState(() {
                  _draft = null;
                  _loading = _load();
                });
              }
            },
            saveLabel: _publishingEnabled ? 'Review changes' : 'Save draft',
            onSave: (draft) async {
              await _draftWrites;
              if (!_publishingEnabled) return;
              if (!context.mounted) return;
              final next = SharedRules(
                  draft.policy(widget.organizationId, 'global',
                      'rules-${version + 1}', version + 1),
                  draft.calendar(widget.organizationId, 'global',
                      'rules-${version + 1}', version + 1));
              next.validate();
              final changes = next.changesFrom(before);
              if (changes.isEmpty) throw StateError('No changes to publish');
              final now = DateTime.now();
              final earliest =
                  ruleActivationDate(before.policy, next.policy, now, now);
              final published = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PublishRulesReview(
                          before: before,
                          next: next,
                          earliest: earliest,
                          publish: (date) => widget.organizations.publishRules(
                              widget.organizationId,
                              widget.uid,
                              before,
                              next,
                              version,
                              date))));
              if (published != true) {
                throw StateError('Not published. Your draft is still here.');
              }
              await _draftWrites;
              await widget.organizations
                  .removeRulesDraft(widget.uid, widget.organizationId);
            });
      });
}

class PublishRulesReview extends StatefulWidget {
  const PublishRulesReview(
      {super.key,
      required this.before,
      required this.next,
      required this.earliest,
      required this.publish});
  final SharedRules before, next;
  final DateTime earliest;
  final Future<RuleRevision> Function(DateTime) publish;
  @override
  State<PublishRulesReview> createState() => _PublishRulesReviewState();
}

class _PublishRulesReviewState extends State<PublishRulesReview> {
  late DateTime _date = widget.earliest;
  bool _saving = false;
  String? _error;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Review shared update')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Already-marked attendance stays unchanged.'),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Effective from'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            onTap: _saving
                ? null
                : () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: widget.earliest,
                        lastDate: DateTime(2100));
                    if (date != null && mounted) setState(() => _date = date);
                  }),
        for (final entry in widget.next.changesFrom(widget.before).entries) ...[
          const Divider(),
          Text(ruleLabel(entry.key),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
              'Before: ${ruleValue(entry.key, widget.before.fields[entry.key])}'),
          Text('Proposed: ${ruleValue(entry.key, entry.value)}'),
        ],
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 24),
        FilledButton.icon(
            icon: const Icon(Icons.publish_outlined),
            label: Text(_saving ? 'Publishing...' : 'Publish update'),
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    try {
                      await widget.publish(_date);
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _saving = false;
                          _error = actionError(e);
                        });
                      }
                    }
                  }),
      ]));
}

class RuleUpdatesPanel extends StatefulWidget {
  const RuleUpdatesPanel(
      {super.key,
      required this.repository,
      required this.organizations,
      required this.organizationId});
  final CalendarRepository repository;
  final OrganizationRepository organizations;
  final String organizationId;
  @override
  State<RuleUpdatesPanel> createState() => _RuleUpdatesPanelState();
}

class _RuleUpdatesPanelState extends State<RuleUpdatesPanel> {
  late Future<RuleRevision?> _pending = _load();
  StreamSubscription<int>? _subscription;
  Future<RuleRevision?> _load() async {
    await widget.repository.refresh();
    final state = await widget.repository.read();
    if (state?.policy == null) return null;
    return widget.organizations
        .nextRuleRevision(widget.organizationId, state!.reviewedRuleVersion);
  }

  @override
  void initState() {
    super.initState();
    _subscription = widget.organizations
        .watchRuleVersion(widget.organizationId)
        .listen((_) {
      if (mounted) {
        setState(() {
          _pending = _load();
        });
      }
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        CalendarUpdatesPanel(
            repository: widget.repository,
            organizations: widget.organizations,
            organizationId: widget.organizationId),
        FutureBuilder<RuleRevision?>(
            future: _pending,
            builder: (_, result) {
              if (result.hasError) {
                return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rule updates unavailable'),
                    trailing: IconButton(
                        tooltip: 'Check rule updates',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() {
                              _pending = _load();
                            })));
              }
              final revision = result.data;
              if (revision == null) return const SizedBox.shrink();
              return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_outlined),
                  title: const Text('Your organization updated its rules'),
                  subtitle: Text(
                      'Effective from ${DateFormat.yMMMd().format(revision.effectiveDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final state = await widget.repository.read();
                    if (state == null || !context.mounted) return;
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RuleReviewPage(
                                repository: widget.repository,
                                presented: state,
                                revision: revision)));
                    if (mounted) {
                      setState(() {
                        _pending = _load();
                      });
                    }
                  });
            }),
      ]);
}

class RuleReviewPage extends StatefulWidget {
  const RuleReviewPage(
      {super.key,
      required this.repository,
      required this.presented,
      required this.revision});
  final CalendarRepository repository;
  final PersonalCalendarState presented;
  final RuleRevision revision;
  @override
  State<RuleReviewPage> createState() => _RuleReviewPageState();
}

class _RuleReviewPageState extends State<RuleReviewPage> {
  final Map<String, bool> _choices = {};
  bool _saving = false;
  String? _error;
  bool _past(String key) =>
      key.startsWith('holiday:') &&
      !DateTime.parse(key.substring(8))
          .isAfter(DateUtils.dateOnly(DateTime.now()));
  @override
  Widget build(BuildContext context) {
    final keys = widget.revision.changes.keys.toList();
    final state = widget.presented;
    final last = state.ruleTimeline.isEmpty
        ? DateTime.now()
        : DateTime.parse(state.ruleTimeline.last['effectiveDate'] as String);
    final mine = SharedRules(state.policyAt(last)!, state.calendarAt(last));
    String? activation, invalid;
    if (_choices.length == keys.length) {
      final selected = <String, Object?>{
        for (final key in keys)
          if (_choices[key] == true && !_past(key))
            key: widget.revision.changes[key]
      };
      if (selected.isEmpty) {
        activation = 'Your rules stay unchanged.';
      } else {
        try {
          final rules = mine.apply(selected);
          final preview = widget.repository.scheduleRules(state, rules.policy,
              rules.calendar, widget.revision.effectiveDate);
          activation =
              'Applies from ${preview.ruleTimeline.last['effectiveDate']}';
        } catch (e) {
          invalid = actionError(e);
        }
      }
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Review rule changes')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Already-marked attendance stays unchanged.'),
          Text(
              'Proposed from ${DateFormat.yMMMd().format(widget.revision.effectiveDate)}'),
          if (activation != null) Text(activation),
          if (invalid != null)
            Text(invalid, style: const TextStyle(color: Colors.red)),
          Wrap(children: [
            TextButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text('Apply all'),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          for (final key in keys) {
                            _choices[key] = !_past(key);
                          }
                        })),
            TextButton.icon(
                icon: const Icon(Icons.lock_outline),
                label: const Text('Keep all'),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          for (final key in keys) {
                            _choices[key] = false;
                          }
                        })),
          ]),
          for (final key in keys) ...[
            const Divider(height: 32),
            Text(ruleLabel(key),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Mine: ${ruleValue(key, mine.fields[key])}'),
            Text('Proposed: ${ruleValue(key, widget.revision.changes[key])}'),
            if (_past(key))
              const Text('Past date - existing attendance unchanged'),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
                emptySelectionAllowed: true,
                selected: _choices.containsKey(key) ? {_choices[key]!} : {},
                segments: [
                  ButtonSegment(
                      value: true,
                      enabled: !_past(key),
                      icon: const Icon(Icons.check),
                      label: const Text('Apply')),
                  const ButtonSegment(
                      value: false,
                      icon: Icon(Icons.lock_outline),
                      label: Text('Keep mine'))
                ],
                onSelectionChanged: _saving
                    ? null
                    : (values) => setState(() {
                          if (values.isEmpty) {
                            _choices.remove(key);
                          } else {
                            _choices[key] = values.first;
                          }
                        })),
          ],
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save choices'),
              onPressed: _saving ||
                      _choices.length != keys.length ||
                      invalid != null
                  ? null
                  : () async {
                      setState(() {
                        _saving = true;
                        _error = null;
                      });
                      try {
                        await widget.repository
                            .applyRuleReview(state, widget.revision, _choices);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _saving = false;
                            _error = actionError(e);
                          });
                        }
                      }
                    }),
        ]));
  }
}
