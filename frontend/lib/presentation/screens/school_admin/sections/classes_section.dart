import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/pickers.dart';
import '../../../../widgets/school/combinations.dart';
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
        final studentTotal = classes.fold<int>(0, (n, c) => n + ((c['studentCount'] as num?)?.toInt() ?? 0));
        final needTeachers = classes.where((c) => SchoolService.list(c['subjects']).any((s) => s['teacherId'] == null) || c['classTeacher'] == null).length;
        Future<void> promote() async {
          final done = await context.push<bool>('/school-admin/promotion?school=${widget.c.schoolId}');
          if (done == true) reload();
        }

        return SchoolPage(onRefresh: reload, children: [
          if (classes.isNotEmpty)
            MiniStats(items: [
              MiniStat('${classes.length}', 'Classes'),
              MiniStat('$studentTotal', 'Students', tone: Tone.info),
              MiniStat('${levels.length}', 'Levels'),
              MiniStat('$needTeachers', 'Need teachers', tone: needTeachers > 0 ? Tone.warn : Tone.good),
            ]),
          ActionBar(
            primary: BarAction('Add classes', Icons.add, _add),
            more: [BarAction('Year-end promotion', Icons.upgrade, classes.isEmpty ? null : promote)],
          ),
          if (classes.isEmpty)
            EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'No classes yet',
              message: 'Create your classes and streams (e.g. S3 A, S3 B) or A-level combinations (S5 MPC). Then assign subjects and teachers.',
              action: FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const T('Add classes')),
            ),
          for (final level in levels)
            SectionCard(
              icon: Icons.layers_outlined,
              title: level,
              subtitle: '${plural(byLevel[level]!.length, 'class', 'classes')} · ${plural(byLevel[level]!.fold<int>(0, (n, c) => n + ((c['studentCount'] as num?)?.toInt() ?? 0)), 'student')}',
              child: LayoutBuilder(builder: (context, box) {
                final cols = box.maxWidth >= 760 ? 3 : box.maxWidth >= 480 ? 2 : 1;
                final w = (box.maxWidth - (cols - 1) * 12) / cols;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final cl in byLevel[level]!) SizedBox(width: w, child: _ClassCard(cl: cl, onOpen: () async {
                    await context.push('/school/class/${cl['id']}');
                    reload();
                  })),
                ]);
              }),
            ),
        ]);
      },
    );
  }

  static int _levelOrder(String l) {
    final i = schoolLevels.indexOf(l);
    return i < 0 ? 999 : i;
  }
}

/// One class as a card: stream badge, name, students, class teacher, warnings.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.cl, required this.onOpen});
  final Map<String, dynamic> cl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subjects = SchoolService.list(cl['subjects']);
    final noTeacher = subjects.where((s) => s['teacherId'] == null).length;
    final ct = cl['classTeacher'] as Map?;
    final muted = AppTheme.getSecondaryTextColor(context);
    final badge = '${cl['stream'] == '' || cl['stream'] == null ? cl['level'] : cl['stream']}';
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor(context).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${cl['name']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.getTextColor(context))),
                  if (combinationName('${cl['combination'] ?? ''}') != null)
                    Text(trSchool(context, combinationName('${cl['combination']}')!), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Wrap(spacing: 10, runSpacing: 2, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.groups_outlined, size: 15, color: muted),
                      const SizedBox(width: 4),
                      T(plural(cl['studentCount'] as num?, 'student'), style: TextStyle(fontSize: 12.5, color: muted)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.menu_book_outlined, size: 15, color: muted),
                      const SizedBox(width: 4),
                      T(plural(subjects.length, 'subject'), style: TextStyle(fontSize: 12.5, color: muted)),
                    ]),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (ct != null)
                      StatusPill('${ct['fullName']}', tone: Tone.neutral, icon: Icons.person_pin_outlined)
                    else
                      const StatusPill('No class teacher', tone: Tone.warn, icon: Icons.person_off_outlined),
                    if (noTeacher > 0) StatusPill('$noTeacher subject${noTeacher == 1 ? '' : 's'} without teacher', tone: Tone.warn),
                  ]),
                ]),
              ),
              Icon(Icons.chevron_right, color: muted),
            ]),
          ),
        ),
      ),
    );
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
    final schoolCombos = ((widget.c.school['combinations'] as List?) ?? const []).map((e) => '$e').toList();
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
              T('Combination or trade (optional)', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
              const SizedBox(height: 6),
              CombinationField(
                multi: false,
                level: _level,
                extra: schoolCombos,
                selected: {if (_combination.isNotEmpty) _combination},
                onChanged: (v) => setState(() => _combination = v.isEmpty ? '' : v.first),
              ),
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
