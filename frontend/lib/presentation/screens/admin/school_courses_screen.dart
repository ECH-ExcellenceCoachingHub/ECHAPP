import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';

/// Super admin: which ECH courses school students get for free, by class
/// level. A student sees the courses marked for their class level (plus the
/// syllabus course of each class subject) while the school's term is paid.
class SchoolCoursesScreen extends StatefulWidget {
  const SchoolCoursesScreen({super.key});

  @override
  State<SchoolCoursesScreen> createState() => _SchoolCoursesScreenState();
}

class _SchoolCoursesScreenState extends State<SchoolCoursesScreen> {
  final _svc = SchoolService();
  final _search = TextEditingController();
  Timer? _debounce;
  bool _onlyMarked = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _svc.schoolCourses(search: _search.text.trim(), onlyMarked: _onlyMarked);
      if (mounted) setState(() => _courses = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> c) async {
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AccessSheet(course: c, svc: _svc),
    );
    if (updated != null && mounted) {
      setState(() => _courses = [for (final x in _courses) x['id'] == updated['id'] ? updated : x]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final marked = _courses.where((c) => c['schoolAccess']?['enabled'] == true).length;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const T('Courses for schools'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/admin/schools')),
      ),
      body: SchoolPage(onRefresh: _load, maxWidth: 900, children: [
        const InfoBanner(
          icon: Icons.school_outlined,
          text: 'Mark the courses school students get for free, and for which class levels. Students see them on their school page while their school has paid the term.',
        ),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search courses', isDense: true),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), _load);
              },
            ),
          ),
          const SizedBox(width: 10),
          FilterChip(label: const T('Marked only'), selected: _onlyMarked, onSelected: (v) { setState(() => _onlyMarked = v); _load(); }),
        ]),
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load courses', message: _error!, action: OutlinedButton(onPressed: _load, child: const T('Try again')))
        else if (_courses.isEmpty)
          const EmptyState(icon: Icons.menu_book_outlined, title: 'No courses found', message: 'Try another search.')
        else ...[
          T('$marked of ${_courses.length} courses are offered to schools', style: TextStyle(color: muted, fontSize: 13)),
          for (final c in _courses) _CourseRow(c: c, onTap: () => _edit(c)),
        ],
      ]),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.c, required this.onTap});
  final Map<String, dynamic> c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sa = Map<String, dynamic>.from(c['schoolAccess'] as Map? ?? {});
    final on = sa['enabled'] == true;
    final levels = (sa['levels'] as List? ?? const []).map((e) => '$e').toList();
    final muted = AppTheme.getSecondaryTextColor(context);
    return Semantics(
      container: true,
      child: Material(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
            ),
            child: Row(children: [
              CourseThumb(url: c['thumbnail'] as String?, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (on) ...[
                      const StatusPill('Free for schools', tone: Tone.good),
                      for (final l in levels) StatusPill(l, tone: Tone.info),
                    ] else
                      Text(trSchool(context, 'Not offered to schools'), style: TextStyle(color: muted, fontSize: 12.5)),
                    if (c['isPublished'] == false) const StatusPill('Not published', tone: Tone.warn),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AccessSheet extends StatefulWidget {
  const _AccessSheet({required this.course, required this.svc});
  final Map<String, dynamic> course;
  final SchoolService svc;

  @override
  State<_AccessSheet> createState() => _AccessSheetState();
}

class _AccessSheetState extends State<_AccessSheet> {
  late final Map<String, dynamic> _sa = Map<String, dynamic>.from(widget.course['schoolAccess'] as Map? ?? {});
  late bool _enabled = _sa['enabled'] == true;
  late Set<String> _levels = {...((_sa['levels'] as List?) ?? const []).map((e) => '$e')};
  late final _subject = TextEditingController(text: '${_sa['subject'] ?? ''}');
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_enabled && _levels.isEmpty) return showSnack(context, 'Choose at least one class level.', error: true);
    setState(() => _busy = true);
    try {
      final c = await widget.svc.setCourseSchoolAccess('${widget.course['id']}', enabled: _enabled, levels: _levels.toList(), subject: _subject.text.trim());
      if (mounted) Navigator.pop(context, c);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('${widget.course['title']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const T('Free for school students'),
            subtitle: const T('Only for the class levels below, while the school has paid the term.'),
          ),
          if (_enabled) ...[
            const SizedBox(height: 8),
            T('Class levels', style: TextStyle(fontSize: 13, color: muted)),
            const SizedBox(height: 6),
            ChipPicker(options: schoolLevels, selected: _levels, onChanged: (v) => setState(() => _levels = v)),
            const SizedBox(height: 14),
            TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject (optional)', hintText: 'e.g. Biology')),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _save,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: const T('Save'),
          ),
        ]),
      ),
    );
  }
}
