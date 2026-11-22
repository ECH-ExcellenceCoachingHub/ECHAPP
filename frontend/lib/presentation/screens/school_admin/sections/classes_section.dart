import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/pickers.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Classes of the school grouped by level, with streams and combinations.
class ClassesSection extends StatefulWidget {
  const ClassesSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<ClassesSection> createState() => _ClassesSectionState();
}

class _ClassesSectionState extends State<ClassesSection> {
  final _key = GlobalKey<AsyncBodyState<List<Map<String, dynamic>>>>();

  Future<void> _add() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _AddClassesDialog(c: widget.c));
    if (ok == true) _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<Map<String, dynamic>>>(
      key: _key,
      load: () => widget.c.svc.classes(widget.c.schoolId),
      builder: (context, classes, reload) {
        final byLevel = <String, List<Map<String, dynamic>>>{};
        for (final cl in classes) {
          byLevel.putIfAbsent('${cl['level']}', () => []).add(cl);
        }
        final levels = byLevel.keys.toList()..sort((a, b) => _levelOrder(a).compareTo(_levelOrder(b)));
        return SchoolPage(onRefresh: reload, children: [
          Row(children: [
            Expanded(
              child: T('${classes.length} class${classes.length == 1 ? '' : 'es'} · ${classes.fold<int>(0, (n, c) => n + ((c['studentCount'] as num?)?.toInt() ?? 0))} students',
                  style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            ),
            OutlinedButton.icon(
              onPressed: classes.isEmpty
                  ? null
                  : () async {
                      final done = await context.push<bool>('/school-admin/promotion?school=${widget.c.schoolId}');
                      if (done == true) reload();
                    },
              icon: const Icon(Icons.upgrade),
              label: const T('Year-end promotion'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const T('Add classes')),
          ]),
          if (classes.isEmpty)
            EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'No classes yet',
              message: 'Create your classes and streams (e.g. S3 A, S3 B) or A-level combinations (S5 MPC). Then assign subjects and teachers.',
              action: FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const T('Add classes')),
            ),
          for (final level in levels)
            SectionCard(
              title: level,
              subtitle: '${byLevel[level]!.length} stream(s)',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(children: [for (final cl in byLevel[level]!) _classTile(context, cl, reload)]),
            ),
        ]);
      },
    );
  }

  Widget _classTile(BuildContext context, Map<String, dynamic> cl, Future<void> Function() reload) {
    final subjects = SchoolService.list(cl['subjects']);
    final noTeacher = subjects.where((s) => s['teacherId'] == null).length;
    final ct = cl['classTeacher'] as Map?;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
        child: T('${cl['stream'] == '' ? cl['level'] : cl['stream']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark, fontSize: 13)),
      ),
      title: T('${cl['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        '${cl['studentCount']} students',
        '${subjects.length} subjects',
        ct != null ? 'Class teacher: ${ct['fullName']}' : 'No class teacher',
      ].join(' · ')),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (noTeacher > 0) const Padding(padding: EdgeInsets.only(right: 6), child: StatusPill('Needs teachers', tone: Tone.warn)),
        const Icon(Icons.chevron_right),
      ]),
      onTap: () async {
        await context.push('/school/class/${cl['id']}');
        reload();
      },
    );
  }

  static int _levelOrder(String l) {
    final i = schoolLevels.indexOf(l);
    return i < 0 ? 999 : i;
  }
}

class _AddClassesDialog extends StatefulWidget {
  const _AddClassesDialog({required this.c});
  final SchoolCtx c;

  @override
  State<_AddClassesDialog> createState() => _AddClassesDialogState();
}

class _AddClassesDialogState extends State<_AddClassesDialog> {
  String? _level;
  String _combination = '';
  final _streams = <String>{'A'};
  final _year = TextEditingController(text: '${DateTime.now().year}');
  Map<String, dynamic>? _teacher;
  bool _busy = false;

  bool get _aLevel => _level != null && ['S4', 'S5', 'S6', 'L3', 'L4', 'L5'].contains(_level);

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_level == null) return showSnack(context, 'Choose the level', error: true);
    setState(() => _busy = true);
    try {
      final streams = _streams.toList()..sort();
      final r = await widget.c.svc.createClasses(widget.c.schoolId, {
        'level': _level,
        'combination': _combination,
        if (streams.length == 1) 'stream': streams.first == '—' ? '' : streams.first else 'streams': streams.map((s) => s == '—' ? '' : s).toList(),
        'academicYear': _year.text.trim(),
        if (streams.length == 1 && _teacher?['id'] != null) 'classTeacherId': _teacher!['id'],
      });
      if (!mounted) return;
      final skipped = (r['skipped'] as List?) ?? const [];
      showSnack(context, skipped.isEmpty ? 'Classes created' : 'Created. Already existed: ${skipped.join(', ')}');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolLevelsOffered = ((widget.c.school['levels'] as List?) ?? const []).map((e) => '$e').toList();
    final levels = schoolLevelsOffered.isNotEmpty ? [...schoolLevelsOffered, ...schoolLevels.where((l) => !schoolLevelsOffered.contains(l))] : schoolLevels;
    final combos = {...((widget.c.school['combinations'] as List?) ?? const []).map((e) => '$e'), ...commonCombinations}.toList();
    final preview = (_streams.toList()..sort()).map((s) => [_level ?? '…', _combination, s == '—' ? '' : s].where((p) => p.isNotEmpty).join(' ')).join(', ');

    return AlertDialog(
      title: const T('Add classes'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Level *'),
                  items: [for (final l in levels) DropdownMenuItem(value: l, child: Text(l))],
                  onChanged: (v) => setState(() { _level = v; if (!_aLevel) _combination = ''; }),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 120, child: TextField(controller: _year, decoration: const InputDecoration(labelText: 'Academic year'))),
            ]),
            if (_aLevel) ...[
              const SizedBox(height: 14),
              T('Combination / trade (optional)', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ChoiceChip(label: const T('None'), selected: _combination.isEmpty, onSelected: (_) => setState(() => _combination = '')),
                for (final c in combos) ChoiceChip(label: Text(c), selected: _combination == c, onSelected: (_) => setState(() => _combination = c)),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const T('Other'),
                  onPressed: () async {
                    final t = TextEditingController();
                    final v = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
                      title: const T('Combination'),
                      content: TextField(controller: t, autofocus: true, textCapitalization: TextCapitalization.characters),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, t.text), child: const T('Use'))],
                    ));
                    if (v != null && v.trim().isNotEmpty) setState(() => _combination = v.trim().toUpperCase());
                  },
                ),
              ]),
            ],
            const SizedBox(height: 14),
            T('Streams', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in ['—', 'A', 'B', 'C', 'D', 'E', 'F'])
                FilterChip(
                  label: Text(s == '—' ? 'No stream' : s),
                  selected: _streams.contains(s),
                  onSelected: (v) => setState(() {
                    if (s == '—') { _streams..clear()..add('—'); return; }
                    _streams.remove('—');
                    v ? _streams.add(s) : _streams.remove(s);
                    if (_streams.isEmpty) _streams.add('A');
                  }),
                ),
            ]),
            if (_streams.length == 1) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_outlined),
                label: Text(_teacher?['fullName'] != null ? 'Class teacher: ${_teacher!['fullName']}' : 'Choose class teacher (optional)'),
                onPressed: () async {
                  final t = await pickTeacher(context, widget.c.svc, widget.c.schoolId, title: 'Class teacher');
                  if (t != null) setState(() => _teacher = t['id'] == null ? null : t);
                },
              ),
            ],
            const SizedBox(height: 14),
            T('Will create: $preview', style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const T('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const T('Create')),
      ],
    );
  }
}
