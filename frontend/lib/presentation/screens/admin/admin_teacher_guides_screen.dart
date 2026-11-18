import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/teacher_access_service.dart';
import 'admin_teacher_approvals_screen.dart' show AdminBackButton;

final _money = NumberFormat.decimalPattern();

/// Admin: every course's teacher's guide — settings (price for teachers,
/// classes), building it from a guide book with the AI builder, and publishing.
class AdminTeacherGuidesScreen extends StatefulWidget {
  const AdminTeacherGuidesScreen({super.key});

  @override
  State<AdminTeacherGuidesScreen> createState() => _AdminTeacherGuidesScreenState();
}

class _AdminTeacherGuidesScreenState extends State<AdminTeacherGuidesScreen> {
  final _svc = TeacherAccessService();
  final _search = TextEditingController();
  List<AdminGuideCourse> _courses = [];
  List<LevelGroup> _groups = LevelGroup.defaults;
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | enabled | draft

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (courses, groups) = await _svc.adminGuides();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _edit(AdminGuideCourse c) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _GuideSettingsDialog(course: c, groups: _groups, service: _svc));
    if (saved == true) _load();
  }

  Future<void> _toggle(AdminGuideCourse c, bool on) async {
    if (on && c.classLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set the price and classes first')));
      return _edit(c);
    }
    try {
      await _svc.updateGuide(c.courseId, enabled: on);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = _courses.where((c) {
      if (_filter == 'enabled' && !c.enabled) return false;
      if (_filter == 'draft' && c.enabled) return false;
      return q.isEmpty || c.title.toLowerCase().contains(q) || c.subject.toLowerCase().contains(q) || c.classLevels.any((l) => l.toLowerCase() == q);
    }).toList();
    final requests = _courses.fold<int>(0, (n, c) => n + c.pendingRequests);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            const AdminBackButton(),
            const SizedBox(width: 4),
            const Expanded(child: Text("Teacher's guides", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
          ]),
          Text(
            "Upload a course's teacher's guide book: the AI splits it into chapters and lessons and writes how to teach each lesson, "
            'with a short video. Set a price for teachers, review, publish — then switch it on so teachers can request it.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          if (requests > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text('$requests teacher request(s) waiting for approval.')),
                TextButton(onPressed: () => context.go('/admin/payments'), child: const Text('Open payments')),
              ]),
            ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search course, subject or class', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            for (final f in const [('all', 'All courses'), ('enabled', 'Available to teachers'), ('draft', 'Not available')])
              ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
          ]),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Center(child: Column(children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
          else if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No course matches.')))
          else
            for (final c in list) _GuideRow(course: c, onEdit: () => _edit(c), onToggle: (v) => _toggle(c, v)),
        ]),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final AdminGuideCourse course;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  const _GuideRow({required this.course, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = course;
    final hint = Theme.of(context).hintColor;
    final build = c.latestBuild;
    final buildStatus = c.latestBuildStatus;
    final busy = ['uploaded', 'extracting', 'analyzing', 'generating'].contains(buildStatus);

    String stateText;
    Color stateColor;
    if (c.publishedAt != null) {
      stateText = 'Published · ${c.publishedLessons} lessons';
      stateColor = Colors.green;
    } else if (busy) {
      stateText = 'Building… ${build?['percent'] ?? 0}%';
      stateColor = Colors.blue;
    } else if (buildStatus == 'outline_ready') {
      stateText = 'Check chapters, then generate';
      stateColor = Colors.orange;
    } else if (buildStatus == 'ready') {
      stateText = 'Ready to review & publish';
      stateColor = Colors.orange;
    } else if (buildStatus == 'failed') {
      stateText = 'Build failed';
      stateColor = Colors.red;
    } else {
      stateText = 'No guide yet';
      stateColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _Pill(stateText, stateColor),
                  _Pill(c.price > 0 ? 'RWF ${_money.format(c.price)}' : 'Free for teachers', const Color(0xFF7C3AED)),
                  for (final l in c.classLevels) _Pill(l, const Color(0xFF3B82F6)),
                  if (c.teachers > 0) _Pill('${c.teachers} teacher(s)', Colors.teal),
                  if (c.pendingRequests > 0) _Pill('${c.pendingRequests} waiting', Colors.orange),
                ]),
              ]),
            ),
            Column(children: [
              Switch(value: c.enabled, onChanged: onToggle),
              Text(c.enabled ? 'Available' : 'Hidden', style: TextStyle(fontSize: 11, color: hint)),
            ]),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.tune, size: 18), label: const Text('Price & classes')),
            FilledButton.icon(
              onPressed: () => context.push('/admin/courses/${c.courseId}/teacher-guide-builder'),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(build == null ? 'Build guide from a book' : 'Guide builder'),
            ),
            if (c.latestBuildId != null)
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/ai-builds/${c.latestBuildId}'),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Review & publish'),
              ),
            if (c.publishedAt != null)
              TextButton.icon(
                onPressed: () => context.push('/teacher/guides/${c.courseId}'),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview as teacher'),
              ),
          ]),
          if (!c.enabled && c.publishedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Published but hidden — switch it on so teachers can request it.', style: TextStyle(fontSize: 12, color: Colors.orange[800])),
            ),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      );
}

class _GuideSettingsDialog extends StatefulWidget {
  final AdminGuideCourse course;
  final List<LevelGroup> groups;
  final TeacherAccessService service;
  const _GuideSettingsDialog({required this.course, required this.groups, required this.service});
  @override
  State<_GuideSettingsDialog> createState() => _GuideSettingsDialogState();
}

class _GuideSettingsDialogState extends State<_GuideSettingsDialog> {
  late final _price = TextEditingController(text: widget.course.price > 0 ? widget.course.price.toString() : '0');
  late final _subject = TextEditingController(text: widget.course.subject);
  late final _description = TextEditingController(text: widget.course.description);
  final _other = TextEditingController();
  late final Set<String> _levels = {...widget.course.classLevels};
  late bool _enabled = widget.course.enabled;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_price, _subject, _description, _other]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text.trim());
    if (price == null || price < 0) return setState(() => _error = 'Enter a price (0 = free)');
    if (_levels.isEmpty) return setState(() => _error = 'Choose at least one class');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateGuide(widget.course.courseId,
          enabled: _enabled, price: price, classLevels: _levels.toList(), subject: _subject.text.trim(), description: _description.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom = _levels.where((l) => !widget.groups.any((g) => g.levels.contains(l))).toList();
    return AlertDialog(
      title: Text(widget.course.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price for teachers (RWF, 0 = free)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description for teachers', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),
            const Text('Classes this guide is for', style: TextStyle(fontWeight: FontWeight.w800)),
            const Text('Teachers of these classes see it as "recommended".', style: TextStyle(fontSize: 12)),
            for (final g in widget.groups) ...[
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(g.group, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final l in g.levels)
                  FilterChip(label: Text(l), selected: _levels.contains(l), onSelected: (on) => setState(() => on ? _levels.add(l) : _levels.remove(l))),
              ]),
            ],
            if (custom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 6, children: [for (final l in custom) InputChip(label: Text(l), onDeleted: () => setState(() => _levels.remove(l)))]),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _other, decoration: const InputDecoration(hintText: 'Other class', isDense: true, border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  final v = _other.text.trim();
                  if (v.isEmpty) return;
                  setState(() => _levels.add(v));
                  _other.clear();
                },
                child: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              title: const Text('Available to teachers'),
              subtitle: const Text('Teachers can see and request it (it says "coming soon" until published).'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
      ],
    );
  }
}
