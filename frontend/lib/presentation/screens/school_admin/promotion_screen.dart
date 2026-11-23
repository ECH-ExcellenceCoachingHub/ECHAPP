import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';
import '../../../widgets/school/combinations.dart';

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
  /// Students who go to another combination / stream next year: id → (combination, stream).
  final Map<String, ({String combination, String stream})> moves = {};

  String get targetName => [toLevel ?? '?', toCombination, toStream].where((p) => p.isNotEmpty).join(' ');
  String nameFor(String combination, String stream) => [toLevel ?? '?', combination, stream].where((p) => p.isNotEmpty).join(' ');
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

  /// Where a group of students goes next year: a combination and a stream at the class's next level.
  Future<({String combination, String stream})?> _pickDestination(_Plan p, {String? combination, String? stream}) {
    var comb = combination ?? p.toCombination;
    var str = stream ?? p.toStream;
    return showModalBottomSheet<({String combination, String stream})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final upper = ['S4', 'S5', 'S6', 'L3', 'L4', 'L5'].contains(p.toLevel);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            T('Class next year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            T(upper
                    ? 'They move up to ${p.toLevel ?? '?'} with this combination and stream. Students from other classes sent to the same place study together.'
                    : 'They move up to ${p.toLevel ?? '?'} in this stream (e.g. S1 A → S2 C). Students from other classes sent to the same stream study together.',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(ctx), fontSize: 13)),
            if (upper) ...[
              const SizedBox(height: 16),
              T('Combination or trade', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(ctx))),
              const SizedBox(height: 6),
              CombinationField(
                multi: false,
                level: p.toLevel,
                extra: ((_d?['combinations'] as List?) ?? const []).map((e) => '$e').toList(),
                selected: {if (comb.isNotEmpty) comb},
                onChanged: (v) => set(() => comb = v.isEmpty ? '' : v.first),
              ),
            ],
            const SizedBox(height: 16),
            T('Stream', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(ctx))),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final x in {'', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', if (str.isNotEmpty) str})
                PillChoice(label: x.isEmpty ? 'No stream' : x, selected: str == x, onTap: () => set(() => str = x)),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 16),
                label: const T('Other…'),
                onPressed: () async {
                  final t = TextEditingController();
                  final v = await showDialog<String>(
                    context: ctx,
                    builder: (dctx) => AlertDialog(
                      title: const T('Stream name'),
                      content: TextField(controller: t, autofocus: true, maxLength: 10, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: trSchool(dctx, 'e.g. J or 2'))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dctx), child: const T('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(dctx, t.text), child: const T('Use')),
                      ],
                    ),
                  );
                  final x = v?.trim().toUpperCase() ?? '';
                  if (x.isNotEmpty) set(() => str = x);
                },
              ),
            ]),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(ctx, (combination: comb, stream: str)),
              icon: const Icon(Icons.arrow_forward),
              label: T('Send to ${p.nameFor(comb, str)}'),
            ),
          ]),
        );
      }),
    );
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
    final selected = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final muted = AppTheme.getSecondaryTextColor(ctx);
        final promote = p.action == 'promote';

        void apply(String id, String what, [({String combination, String stream})? dest]) {
          p.repeaters.remove(id);
          p.leavers.remove(id);
          p.moves.remove(id);
          if (what == 'repeat') p.repeaters.add(id);
          if (what == 'leave') p.leavers.add(id);
          if (what == 'other' && dest != null) {
            // Same place as the whole class: no special move needed.
            if (dest.combination != p.toCombination || dest.stream != p.toStream) p.moves[id] = dest;
          }
        }

        Future<void> choose(Iterable<String> ids, String what) async {
          ({String combination, String stream})? dest;
          if (what == 'other') {
            final first = p.moves[ids.first];
            dest = await _pickDestination(p, combination: first?.combination, stream: first?.stream);
            if (dest == null) return;
          }
          set(() {
            for (final id in ids) {
              apply(id, what, dest);
            }
            selected.clear();
          });
        }

        (String, Tone) status(String id) {
          if (p.repeaters.contains(id)) return ('Repeats ${p.level}', Tone.warn);
          if (p.leavers.contains(id)) return ('Leaves the school', Tone.bad);
          if (!promote) return (p.action == 'graduate' ? 'Graduates' : 'Stays', Tone.neutral);
          final m = p.moves[id];
          if (m != null) return ('→ ${p.nameFor(m.combination, m.stream)}', Tone.info);
          return ('→ ${p.targetName}', Tone.good);
        }

        // Where everyone goes, for the summary at the top.
        final counts = <String, int>{};
        for (final st in students) {
          final label = status('${st['id']}').$1;
          counts[label] = (counts[label] ?? 0) + 1;
        }

        List<PopupMenuEntry<String>> menu() => [
              if (promote) PopupMenuItem(value: 'class', child: T('Moves with the class (${p.targetName})')),
              if (promote) const PopupMenuItem(value: 'other', child: T('Another combination or stream…')),
              if (!promote && p.action == 'graduate') const PopupMenuItem(value: 'class', child: T('Graduates')),
              PopupMenuItem(value: 'repeat', child: T('Repeats ${p.level}')),
              const PopupMenuItem(value: 'leave', child: T('Leaves the school')),
            ];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                T('${p.name}: next year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                T(promote
                    ? 'Everyone moves to ${p.targetName} unless you change it. Tick students to send several to another combination or stream at once.'
                    : 'Mark who repeats or leaves.',
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final e in counts.entries) StatusPill('${e.key}: ${e.value}', tone: e.key.startsWith('→') ? Tone.info : Tone.neutral),
                ]),
              ]),
            ),
            Expanded(
              child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
                for (var i = 0; i < students.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  Builder(builder: (_) {
                    final id = '${students[i]['id']}';
                    final (label, tone) = status(id);
                    return EntityTile(
                      dense: true,
                      leading: Checkbox(value: selected.contains(id), onChanged: (v) => set(() => v == true ? selected.add(id) : selected.remove(id))),
                      title: '${students[i]['fullName']}',
                      pills: [StatusPill(label, tone: tone)],
                      trailing: PopupMenuButton<String>(
                        tooltip: trSchool(ctx, 'Change'),
                        icon: const Icon(Icons.swap_horiz),
                        onSelected: (v) => choose([id], v),
                        itemBuilder: (_) => menu(),
                      ),
                      onTap: () => set(() => selected.contains(id) ? selected.remove(id) : selected.add(id)),
                    );
                  }),
                ],
              ]),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: selected.isEmpty
                    ? FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)), onPressed: () => Navigator.pop(ctx), child: const T('Done'))
                    : Row(children: [
                        Expanded(
                          child: PopupMenuButton<String>(
                            onSelected: (v) => choose(selected.toList(), v),
                            itemBuilder: (_) => menu(),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(24)),
                              child: T('${selected.length} selected: send to…', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(onPressed: () => set(selected.clear), child: const T('Clear')),
                      ]),
              ),
            ),
          ]),
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
      message: '$promoted students move up (${active.fold<int>(0, (n, p) => n + p.moves.length)} into other combinations or streams), $repeat repeat, $graduated graduate and $leave leave.\n'
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
              if (p.action == 'promote') ...{
                'toLevel': p.toLevel,
                'toCombination': p.toCombination,
                'toStream': p.toStream,
                'moves': [for (final e in p.moves.entries) {'studentId': e.key, 'toCombination': e.value.combination, 'toStream': e.value.stream}],
              },
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
          '${s['promoted']} moved up (${s['regrouped'] ?? 0} to other classes) · ${s['repeated']} repeating · ${s['graduated']} graduated · ${s['left']} left\n'
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
    // The school's own combinations first, then the new REB streams.
    final combos = {...((_d?['combinations'] as List?) ?? const []).map((e) => '$e'), 'MS-PURE', 'MS-APPLIED', 'ARTS-HUM', 'LANGUAGES'}.toList();
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
                          CombinationField(
                            multi: false,
                            level: p.toLevel,
                            extra: combos,
                            selected: {if (p.toCombination.isNotEmpty) p.toCombination},
                            onChanged: (v) => setState(() => p.toCombination = v.isEmpty ? '' : v.first),
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
                      T('Students going to different combinations or streams? Choose one for the class here, then open "Students next year" to send others elsewhere.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.warningColor)),
                    ],
                    if (p.action != 'skip') ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        OutlinedButton.icon(onPressed: () => _people(p), icon: const Icon(Icons.people_outline), label: const T('Students next year')),
                        if (p.repeaters.isNotEmpty || p.leavers.isNotEmpty || p.moves.isNotEmpty)
                          T('${p.moves.length} to other classes · ${p.repeaters.length} repeat · ${p.leavers.length} leave', style: TextStyle(color: muted, fontSize: 12.5)),
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
