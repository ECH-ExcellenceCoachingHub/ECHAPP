import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/pickers.dart';
import '../../../../widgets/school/school_ui.dart';
import '../../school/class_detail_screen.dart';
import '../../school/student_form_screen.dart';
import '../school_admin_dashboard_screen.dart';

/// Every student of the school: search, filter by class, register, move, new PIN.
class StudentsSection extends StatefulWidget {
  const StudentsSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<StudentsSection> createState() => _StudentsSectionState();
}

class _StudentsSectionState extends State<StudentsSection> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  int _total = 0;
  String? _classId;
  String _filter = 'all'; // all | unassigned | removed
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _classes = await widget.c.svc.classes(widget.c.schoolId);
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = _students.isEmpty; _error = null; });
    try {
      final r = await widget.c.svc.students(
        widget.c.schoolId,
        classId: _filter == 'all' ? _classId : null,
        search: _search.text.trim(),
        unassigned: _filter == 'unassigned',
        active: _filter == 'removed' ? 'false' : 'true',
      );
      setState(() {
        _students = SchoolService.list(r['students']);
        _total = (r['total'] as num?)?.toInt() ?? _students.length;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _register() async {
    if (_classes.isEmpty) {
      showSnack(context, 'Create a class first (Classes → Add classes).', error: true);
      widget.c.go('classes');
      return;
    }
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => StudentFormScreen(schoolId: widget.c.schoolId, classes: _classes)));
    if (ok == true) { _init(); widget.c.reloadSchool(); }
  }

  Future<void> _import() async {
    if (_classes.isEmpty) return _register();
    final cl = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => SimpleDialog(
      title: const T('Import into which class?'),
      children: [for (final c in _classes) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, c), child: T('${c['name']}'))],
    ));
    if (cl == null || !mounted) return;
    final done = await showDialog<bool>(context: context, builder: (_) => ImportStudentsDialog(svc: widget.c.svc, schoolId: widget.c.schoolId, classroomId: '${cl['id']}', className: '${cl['name']}'));
    if (done == true) { _init(); widget.c.reloadSchool(); }
  }

  @override
  Widget build(BuildContext context) {
    final sub = Map<String, dynamic>.from(widget.c.school['subscription'] as Map? ?? {});
    return SchoolPage(onRefresh: _load, children: [
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton.icon(onPressed: _register, icon: const Icon(Icons.person_add_alt_1_outlined), label: const T('Register student')),
        OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.playlist_add_outlined), label: const T('Import a list')),
        T('${widget.c.school['studentCount'] ?? 0} of ${sub['studentLimit'] ?? 0} paid places used', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
      ]),
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Name or student code', isDense: true),
            onChanged: (_) { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 350), _load); },
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: _classId,
            isDense: true,
            decoration: const InputDecoration(labelText: 'Class', isDense: true),
            items: [const DropdownMenuItem(value: null, child: T('All classes')), for (final c in _classes) DropdownMenuItem(value: '${c['id']}', child: T('${c['name']}'))],
            onChanged: (v) { setState(() { _classId = v; _filter = 'all'; }); _load(); },
          ),
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: T('Active')),
            ButtonSegment(value: 'unassigned', label: T('No class')),
            ButtonSegment(value: 'removed', label: T('Removed')),
          ],
          selected: {_filter},
          onSelectionChanged: (v) { setState(() => _filter = v.first); _load(); },
        ),
      ]),
      if (_loading)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else if (_error != null)
        ErrorRetry(message: _error!, onRetry: _load)
      else if (_students.isEmpty)
        const EmptyState(icon: Icons.groups_outlined, title: 'No students found')
      else
        SectionCard(
          title: '$_total student${_total == 1 ? '' : 's'}',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [for (final s in _students) _tile(s)]),
        ),
    ]);
  }

  Widget _tile(Map<String, dynamic> s) {
    final g = (s['guardians'] as List?) ?? const [];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(initialsOf(s['fullName']))),
      title: T('${s['fullName']}'),
      subtitle: Text([
        '${s['studentCode'] ?? ''}',
        s['classroom']?['name'] ?? 'No class',
        if (g.isNotEmpty) 'Parent: ${g.first['name']}${g.first['hasAccount'] == true ? ' ✓' : ''}',
      ].where((e) => '$e'.isNotEmpty).join(' · ')),
      onTap: () async {
        final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => StudentFormScreen(schoolId: widget.c.schoolId, existing: s, classes: _classes)));
        if (ok == true) _load();
      },
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          final svc = widget.c.svc;
          try {
            if (v == 'pin') {
              if (!await confirm(context, title: 'New PIN for ${s['fullName']}?', message: 'The old PIN stops working and the student is signed out everywhere.', confirmLabel: 'Create new PIN')) return;
              final r = await svc.resetCredentials(widget.c.schoolId, '${s['id']}');
              final c = Map<String, dynamic>.from(r['credentials'] as Map);
              if (mounted) await showCredentialsDialog(context, title: 'New sign-in for ${s['fullName']}', rows: [MapEntry('Student code', '${c['studentCode']}'), MapEntry('PIN', '${c['pin']}')]);
            } else if (v == 'move') {
              final to = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => SimpleDialog(
                title: T('Class of ${s['fullName']}'),
                children: [for (final c in _classes) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, c), child: T('${c['name']}'))],
              ));
              if (to == null) return;
              await svc.updateMember(widget.c.schoolId, '${s['id']}', {'classroomId': to['id']});
              _load();
            } else if (v == 'toggle') {
              final active = s['isActive'] != false;
              if (active && !await confirm(context, title: 'Remove ${s['fullName']}?', message: 'Frees a paid place. History is kept; you can reactivate later.', confirmLabel: 'Remove', destructive: true)) return;
              await svc.updateMember(widget.c.schoolId, '${s['id']}', {'isActive': !active});
              _load();
              widget.c.reloadSchool();
            }
          } catch (e) {
            if (mounted) showSnack(context, e.toString(), error: true);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'pin', child: T('New PIN')),
          const PopupMenuItem(value: 'move', child: T('Change class')),
          PopupMenuItem(value: 'toggle', child: Text(s['isActive'] == false ? 'Reactivate' : 'Remove from school')),
        ],
      ),
    );
  }
}
