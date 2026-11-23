import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';

/// Year-end promotion: every class of the closing year goes to its next class
/// (S3 A → S4 A), graduates, or is skipped; repeaters stay at their level and
/// leavers are removed. Subjects and teachers can be copied to the new classes.
class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key, this.schoolId = 'me'});
  final String schoolId;

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _Plan {
  _Plan(Map<String, dynamic> c)
      : classId = '${c['id']}',
        name = '${c['name']}',
        level = '${c['level']}',
        studentCount = (c['studentCount'] as num?)?.toInt() ?? 0,
        needsCombination = c['needsCombination'] == true,
        action = '${c['suggested']?['action'] ?? 'promote'}',
        toLevel = c['suggested']?['level'] as String?,
        toCombination = '${c['suggested']?['combination'] ?? c['combination'] ?? ''}',
        toStream = '${c['suggested']?['stream'] ?? c['stream'] ?? ''}';
  final String classId;
  final String name;
  final String level;
  final int studentCount;
  final bool needsCombination;
  String action;
  String? toLevel;
  String toCombination;
  String toStream;
  final Set<String> repeaters = {};
  final Set<String> leavers = {};

  String get targetName => [toLevel ?? '?', toCombination, toStream].where((p) => p.isNotEmpty).join(' ');
  int get moving => studentCount - repeaters.length - leavers.length;
}

class _PromotionScreenState extends State<PromotionScreen> {
  final _svc = SchoolService();
  Map<String, dynamic>? _d;
  List<_Plan> _plans = [];
  String? _fromYear;
  late final _toYear = TextEditingController();
  bool _copySubjects = true;
  bool _archiveOld = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _toYear.dispose();
    super.dispose();
  }

  Future<void> _load({String? fromYear}) async {
    setState(() { _error = null; });
    try {
      final d = await _svc.promotionPreview(widget.schoolId, fromYear: fromYear);
      setState(() {
        _d = d;
        _fromYear = '${d['fromYear']}';
        _toYear.text = '${d['toYear']}';
        _plans = SchoolService.list(d['classes']).map(_Plan.new).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _people(_Plan p) async {
    Map<String, dynamic> detail;
    try {
      detail = await _svc.classDetail(p.classId);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
      return;
    }
    if (!mounted) return;
    final students = SchoolService.list(detail['students']);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        String state(String id) => p.repeaters.contains(id) ? 'repeat' : p.leavers.contains(id) ? 'leave' : 'move';
        return AlertDialog(
          title: T('${p.name}: who repeats or leaves?'),
          content: SizedBox(
            width: 520,
            height: 460,
            child: ListView(children: [
              T('Everyone else ${p.action == 'graduate' ? 'graduates' : 'moves to ${p.targetName}'}.', style: TextStyle(color: AppTheme.getSecondaryTextColor(ctx))),
              const SizedBox(height: 8),
              for (final s in students)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(child: T('${s['fullName']}')),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: schoolSegmentStyle(context).copyWith(visualDensity: VisualDensity.compact),
                      segments: [
                        ButtonSegment(value: 'move', label: Text(p.action == 'graduate' ? 'Graduates' : 'Moves')),
                        const ButtonSegment(value: 'repeat', label: T('Repeats')),
                        const ButtonSegment(value: 'leave', label: T('Leaves')),
                      ],
                      selected: {state('${s['id']}')},
                      onSelectionChanged: (v) => set(() {
                        final id = '${s['id']}';
                        p.repeaters.remove(id);
                        p.leavers.remove(id);
                        if (v.first == 'repeat') p.repeaters.add(id);
                        if (v.first == 'leave') p.leavers.add(id);
                      }),
                    ),
                  ]),
                ),
            ]),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const T('Done'))],
        );
      }),
    );
    setState(() {});
  }

  Future<void> _run() async {
    final toYear = _toYear.text.trim();
    if (toYear.isEmpty || toYear == _fromYear) return showSnack(context, 'Enter the new school year', error: true);
    final active = _plans.where((p) => p.action != 'skip').toList();
    if (active.isEmpty) return showSnack(context, 'Every class is skipped.', error: true);
    final bad = active.where((p) => p.action == 'promote' && (p.toLevel == null || p.toLevel!.isEmpty)).toList();
    if (bad.isNotEmpty) return showSnack(context, 'Choose the next level for ${bad.first.name}', error: true);
    final promoted = active.where((p) => p.action == 'promote').fold<int>(0, (n, p) => n + p.moving);
    final graduated = active.where((p) => p.action == 'graduate').fold<int>(0, (n, p) => n + p.moving);
    final repeat = active.fold<int>(0, (n, p) => n + p.repeaters.length);
    final leave = active.fold<int>(0, (n, p) => n + p.leavers.length);
    final ok = await confirm(
      context,
      title: 'Start $toYear?',
      message: '$promoted students move up, $repeat repeat, $graduated graduate and $leave leave.\n'
          '${_archiveOld ? 'The $_fromYear classes are archived (history is kept). ' : ''}'
          'Graduates and leavers are removed from the school and free their paid places. This cannot be undone automatically.',
      confirmLabel: 'Start new year',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final r = await _svc.runPromotion(widget.schoolId, {
        'fromYear': _fromYear,
        'toYear': toYear,
        'copySubjects': _copySubjects,
        'archiveOld': _archiveOld,
        'plan': [
          for (final p in _plans)
            {
              'classId': p.classId,
              'action': p.action,
              if (p.action == 'promote') ...{'toLevel': p.toLevel, 'toCombination': p.toCombination, 'toStream': p.toStream},
              'repeaterIds': p.repeaters.toList(),
              'leaverIds': p.leavers.toList(),
            },
        ],
      });
      if (!mounted) return;
      final s = Map<String, dynamic>.from(r['summary'] as Map);
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: T('$toYear is ready'),
        content: Text(
          '${s['promoted']} moved up · ${s['repeated']} repeating · ${s['graduated']} graduated · ${s['left']} left\n'
          '${s['classesCreated']} classes created · ${s['subjectsCopied']} subjects copied · ${s['classesArchived']} old classes archived\n\n'
          'Next: check each new class (class teacher, subjects, syllabus course) and add the new school terms.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const T('OK'))],
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final combos = {...((_d?['combinations'] as List?) ?? const []).map((e) => '$e'), ...commonCombinations}.toList();
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Year-end promotion')),
      bottomNavigationBar: _d == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy || _plans.isEmpty ? null : _run,
                  icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rocket_launch_outlined),
                  label: T('Start ${_toYear.text}'),
                ),
              ),
            ),
      body: _d == null
          ? (_error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _load))
          : SchoolPage(maxWidth: 900, children: [
              SectionCard(
                title: 'From one school year to the next',
                subtitle: 'Check each class, mark who repeats or leaves, then start the new year.',
                child: Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _fromYear,
                      decoration: const InputDecoration(labelText: 'Closing year'),
                      items: [for (final y in ((_d!['years'] as List?) ?? const [])) DropdownMenuItem(value: '$y', child: T('$y'))],
                      onChanged: (v) => v == null ? null : _load(fromYear: v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _toYear, decoration: const InputDecoration(labelText: 'New year'), onChanged: (_) => setState(() {}))),
                ]),
              ),
              if (_plans.isEmpty) const EmptyState(icon: Icons.meeting_room_outlined, title: 'No active classes in this year'),
              for (final p in _plans)
                SectionCard(
                  title: p.name,
                  subtitle: '${p.studentCount} students',
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: schoolSegmentStyle(context).copyWith(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 'promote', label: T('Move up')),
                      ButtonSegment(value: 'graduate', label: T('Graduate')),
                      ButtonSegment(value: 'skip', label: T('Skip')),
                    ],
                    selected: {p.action},
                    onSelectionChanged: (v) => setState(() {
                      p.action = v.first;
                      if (p.action == 'promote' && p.toLevel == null) {
                        final i = schoolLevels.indexOf(p.level);
                        p.toLevel = i >= 0 && i + 1 < schoolLevels.length ? schoolLevels[i + 1] : null;
                      }
                    }),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.action == 'promote')
                      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<String>(
                            initialValue: schoolLevels.contains(p.toLevel) ? p.toLevel : null,
                            isDense: true,
                            decoration: const InputDecoration(labelText: 'To level', isDense: true),
                            items: [for (final l in schoolLevels) DropdownMenuItem(value: l, child: Text(l))],
                            onChanged: (v) => setState(() => p.toLevel = v),
                          ),
                        ),
                        if (['S4', 'S5', 'S6', 'L3', 'L4', 'L5'].contains(p.toLevel))
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<String>(
                              initialValue: ['', ...combos].contains(p.toCombination) ? p.toCombination : '',
                              isDense: true,
                              decoration: const InputDecoration(labelText: 'Combination', isDense: true),
                              items: [const DropdownMenuItem(value: '', child: T('None')), for (final c in combos) DropdownMenuItem(value: c, child: Text(c))],
                              onChanged: (v) => setState(() => p.toCombination = v ?? ''),
                            ),
                          ),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            initialValue: p.toStream,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Stream', isDense: true),
                            onChanged: (v) => setState(() => p.toStream = v.trim().toUpperCase()),
                          ),
                        ),
                        StatusPill('→ ${p.targetName}', tone: Tone.info),
                      ])
                    else
                      Text(p.action == 'graduate' ? 'These students finish at this school.' : 'Nothing changes for this class.', style: TextStyle(color: muted)),
                    if (p.action == 'promote' && p.needsCombination) ...[
                      const SizedBox(height: 8),
                      T('Students choose different combinations? Move the class to one combination here, then move the others from the new class page.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.warningColor)),
                    ],
                    if (p.action != 'skip') ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        OutlinedButton.icon(onPressed: () => _people(p), icon: const Icon(Icons.people_outline), label: const T('Repeaters & leavers')),
                        const SizedBox(width: 10),
                        if (p.repeaters.isNotEmpty || p.leavers.isNotEmpty)
                          T('${p.repeaters.length} repeat · ${p.leavers.length} leave', style: TextStyle(color: muted)),
                      ]),
                    ],
                  ]),
                ),
              SectionCard(
                child: Column(children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _copySubjects,
                    onChanged: (v) => setState(() => _copySubjects = v),
                    title: const T('Copy subjects and teachers to the new classes'),
                    subtitle: const T('You can change them afterwards. The syllabus course is kept only for repeaters.'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _archiveOld,
                    onChanged: (v) => setState(() => _archiveOld = v),
                    title: T('Archive the ${_fromYear ?? ''} classes'),
                    subtitle: const T('Their homework, lessons and results stay in the reports.'),
                  ),
                ]),
              ),
            ]),
    );
  }
}
