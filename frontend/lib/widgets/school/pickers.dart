import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/api/school_service.dart';
import 'school_ui.dart';

/// Pick a teacher of the school. Returns {id, fullName} or {'id': null} to clear.
Future<Map<String, dynamic>?> pickTeacher(BuildContext context, SchoolService svc, String schoolId, {String title = 'Choose a teacher', bool allowNone = true}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _SearchDialog(
      title: title,
      allowNone: allowNone,
      noneLabel: 'No teacher',
      load: (q) async => SchoolService.list((await svc.staff(schoolId, search: q))['staff']),
      tile: (t) => ListTile(
        leading: CircleAvatar(child: Text(_initials(t['fullName']))),
        title: T('${t['fullName']}'),
        subtitle: Text([
          if (t['role'] == 'school_admin') 'School admin',
          ...((t['teacherProfile']?['subjects'] as List?) ?? const []).map((e) => '$e'),
        ].join(' · ')),
      ),
    ),
  );
}

/// Pick an ECH course to use as the syllabus of a class subject.
Future<Map<String, dynamic>?> pickCourse(BuildContext context, SchoolService svc) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _SearchDialog(
      title: 'Link an ECH course (syllabus)',
      allowNone: true,
      noneLabel: 'No course',
      hint: 'Search courses, e.g. Biology S3',
      load: (q) => svc.searchCourses(q),
      tile: (c) => ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: T('${c['title']}'),
        subtitle: c['level'] != null ? T('${c['level']}') : null,
      ),
    ),
  );
}

String _initials(dynamic name) {
  final parts = '${name ?? ''}'.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

String initialsOf(dynamic name) => _initials(name);

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.title, required this.load, required this.tile, this.allowNone = false, this.noneLabel = 'None', this.hint = 'Search'});
  final String title;
  final Future<List<Map<String, dynamic>>> Function(String q) load;
  final Widget Function(Map<String, dynamic>) tile;
  final bool allowNone;
  final String noneLabel;
  final String hint;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _q = TextEditingController();
  Timer? _t;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _t?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final r = await widget.load(_q.text.trim());
      if (mounted) setState(() { _items = r; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(children: [
          TextField(
            controller: _q,
            autofocus: true,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.hint),
            onChanged: (_) {
              _t?.cancel();
              _t = Timer(const Duration(milliseconds: 350), _run);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)))
                    : _items.isEmpty
                        ? const EmptyState(icon: Icons.search_off, title: 'Nothing found')
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (_, i) => InkWell(onTap: () => Navigator.pop(context, _items[i]), child: widget.tile(_items[i])),
                          ),
          ),
        ]),
      ),
      actions: [
        if (widget.allowNone) TextButton(onPressed: () => Navigator.pop(context, <String, dynamic>{'id': null}), child: Text(widget.noneLabel)),
        TextButton(onPressed: () => Navigator.pop(context), child: const T('Cancel')),
      ],
    );
  }
}

/// Simple picker for a subject name (common list + custom).
Future<String?> pickSubjectName(BuildContext context, {List<String> exclude = const []}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController();
      final options = commonSubjects.where((s) => !exclude.contains(s)).toList();
      return AlertDialog(
        title: const T('Add a subject'),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject name', hintText: 'Type or pick below'),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final s in options) ActionChip(label: Text(s), onPressed: () => Navigator.pop(ctx, s)),
                ]),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const T('Add')),
        ],
      );
    },
  );
}
