import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../services/api/teacher_tools_service.dart' show saveAndOpenDocument;
import '../../../widgets/school/login_cards_pdf.dart';
import '../../../widgets/school/pickers.dart';
import '../../../widgets/school/school_ui.dart';
import 'student_form_screen.dart';

/// One class: roster and subjects. Used by the school admin (everything),
/// the class teacher (roster) and subject teachers (view + their subjects).
class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _svc = SchoolService();
  Map<String, dynamic>? _d;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.classDetail(widget.classId);
      if (mounted) setState(() { _d = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Map<String, dynamic> get _class => Map<String, dynamic>.from(_d!['class'] as Map);
  Map<String, dynamic> get _access => Map<String, dynamic>.from(_d!['access'] as Map);
  bool get _isAdmin => _access['isAdmin'] == true;
  bool get _canRoster => _access['canManageRoster'] == true;
  String get _schoolId => '${_class['schoolId']}';

  Future<void> _addStudent() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => StudentFormScreen(schoolId: _schoolId, fixedClass: {'id': _class['id'], 'name': _class['name']}),
    ));
    if (added == true) _load();
  }

  Future<void> _addExisting() async {
    final s = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _ExistingStudentDialog(svc: _svc, schoolId: _schoolId));
    if (s == null) return;
    try {
      await _svc.enrollStudent(_schoolId, '${s['id']}', '${_class['id']}');
      if (mounted) showSnack(context, '${s['fullName']} added to ${_class['name']}');
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _import() async {
    final done = await showDialog<bool>(context: context, builder: (_) => ImportStudentsDialog(svc: _svc, schoolId: _schoolId, classroomId: '${_class['id']}', className: '${_class['name']}'));
    if (done == true) _load();
  }

  Future<void> _setClassTeacher() async {
    final t = await pickTeacher(context, _svc, _schoolId, title: 'Class teacher of ${_class['name']}');
    if (t == null) return;
    try {
      await _svc.updateClass('${_class['id']}', {'classTeacherId': t['id']});
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_d == null) {
      return Scaffold(appBar: AppBar(title: const T('Class')), body: _error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _load));
    }
    final ct = _class['classTeacher'] as Map?;
    final students = SchoolService.list(_d!['students']);
    final subjects = SchoolService.list(_d!['subjects']);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          title: T('${_class['name']}'),
          actions: [
            if (narrow)
              IconButton(tooltip: trSchool(context, 'Class code'), onPressed: () => context.push('/school/code?classId=${_class['id']}'), icon: const Icon(Icons.pin_outlined))
            else
              TextButton.icon(onPressed: () => context.push('/school/code?classId=${_class['id']}'), icon: const Icon(Icons.pin_outlined), label: const T('Class code')),
            if (_isAdmin)
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'teacher') _setClassTeacher();
                  if (v == 'archive') {
                    if (!await confirm(context, title: 'Remove ${_class['name']}?', message: 'Only possible when the class has no students. Classes with history are archived.', confirmLabel: 'Remove', destructive: true)) return;
                    try {
                      await _svc.deleteClass('${_class['id']}');
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (context.mounted) showSnack(context, e.toString(), error: true);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'teacher', child: T('Change class teacher')),
                  PopupMenuItem(value: 'archive', child: T('Remove class')),
                ],
              ),
          ],
        ),
        body: Column(children: [
          // Class header: year, size, class teacher (tap to change).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              HeroChip(plural(students.length, 'student'), icon: Icons.groups_outlined),
              HeroChip(plural(subjects.length, 'subject'), icon: Icons.menu_book_outlined),
              HeroChip('Year ${_class['academicYear']}', icon: Icons.event_outlined),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isAdmin ? _setClassTeacher : null,
                child: HeroChip(ct != null ? '${ct['fullName']}' : 'No class teacher', icon: _isAdmin ? Icons.edit_outlined : Icons.person_pin_outlined),
              ),
              if (_access['isClassTeacher'] == true) const HeroChip('You are the class teacher', icon: Icons.star_outline),
            ]),
          ),
          Material(
            color: AppTheme.getCardColor(context),
            child: TabBar(tabs: [
              Tab(text: trSchool(context, 'Students (${students.length})')),
              Tab(text: trSchool(context, 'Subjects (${subjects.length})')),
            ]),
          ),
          Expanded(child: TabBarView(children: [_studentsTab(), _subjectsTab()])),
        ]),
      ),
    );
  }

  String _search = '';

  Widget _studentsTab() {
    final all = SchoolService.list(_d!['students']);
    final q = _search.trim().toLowerCase();
    final students = q.isEmpty ? all : all.where((s) => '${s['fullName']} ${s['studentCode']}'.toLowerCase().contains(q)).toList();
    return SchoolPage(onRefresh: _load, children: [
      if (_canRoster)
        ActionBar(
          primary: BarAction('Register student', Icons.person_add_alt_1_outlined, _addStudent),
          more: [
            BarAction('Add existing student', Icons.person_search_outlined, _addExisting),
            BarAction('Import a list', Icons.playlist_add_outlined, _import),
            BarAction('Print login cards', Icons.badge_outlined, all.isEmpty ? null : () => printClassLoginCards(context, _svc, classId: '${_class['id']}', className: '${_class['name']}')),
          ],
        )
      else
        const InfoBanner(text: 'Only the class teacher or the school office can add students to this class.'),
      if (all.length > 8)
        TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: trSchool(context, 'Search by name or code'), isDense: true),
          onChanged: (v) => setState(() => _search = v),
        ),
      if (all.isEmpty)
        EmptyState(
          icon: Icons.groups_outlined,
          title: 'No students in this class yet',
          message: _canRoster ? 'Register students one by one, or import the whole class list at once.' : null,
        )
      else
        SectionCard(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Column(children: [
            for (var i = 0; i < students.length; i++) ...[
              if (i > 0) const RowDivider(),
              EntityTile(
                leading: InitialsAvatar('${students[i]['fullName']}'),
                title: '${students[i]['fullName']}',
                subtitle: '${students[i]['studentCode'] ?? ''}',
                pills: [
                  if ((students[i]['guardians'] as List?)?.isNotEmpty == true)
                    StatusPill('Parent: ${(students[i]['guardians'] as List).first['name'] ?? (students[i]['guardians'] as List).first['phone'] ?? ''}', tone: Tone.neutral, icon: Icons.family_restroom_outlined),
                ],
                trailing: _canRoster ? _studentMenu(students[i]) : null,
              ),
            ],
          ]),
        ),
    ]);
  }

  Widget _studentMenu(Map<String, dynamic> s) => PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'edit') {
            final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => StudentFormScreen(schoolId: _schoolId, existing: s, fixedClass: {'id': _class['id'], 'name': _class['name']})));
            if (ok == true) _load();
          } else if (v == 'pin') {
            if (!await confirm(context, title: 'New PIN for ${s['fullName']}?', message: 'The old PIN stops working and the student is signed out on every device.', confirmLabel: 'Create new PIN')) return;
            try {
              final r = await _svc.resetCredentials(_schoolId, '${s['id']}');
              final c = Map<String, dynamic>.from(r['credentials'] as Map);
              if (mounted) {
                await showCredentialsDialog(context, title: 'New sign-in for ${s['fullName']}', rows: [MapEntry('Student code', '${c['studentCode']}'), MapEntry('PIN', '${c['pin']}')]);
              }
            } catch (e) {
              if (mounted) showSnack(context, e.toString(), error: true);
            }
          } else if (v == 'move') {
            final classes = await _svc.classes(_schoolId);
            if (!mounted) return;
            final to = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => SimpleDialog(
              title: T('Move ${s['fullName']} to'),
              children: [for (final c in classes.where((c) => c['id'] != _class['id'])) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, c), child: T('${c['name']}'))],
            ));
            if (to == null) return;
            try {
              await _svc.updateMember(_schoolId, '${s['id']}', {'classroomId': to['id']});
              _load();
            } catch (e) {
              if (mounted) showSnack(context, e.toString(), error: true);
            }
          } else if (v == 'deactivate') {
            if (!await confirm(context, title: 'Remove ${s['fullName']} from the school?', message: 'The account is deactivated and frees a paid place. History is kept and it can be reactivated.', confirmLabel: 'Remove', destructive: true)) return;
            try {
              await _svc.updateMember(_schoolId, '${s['id']}', {'isActive': false});
              _load();
            } catch (e) {
              if (mounted) showSnack(context, e.toString(), error: true);
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: T('Edit details')),
          const PopupMenuItem(value: 'pin', child: T('New PIN')),
          if (_isAdmin) const PopupMenuItem(value: 'move', child: T('Move to another class')),
          if (_isAdmin) const PopupMenuItem(value: 'deactivate', child: T('Remove from school')),
        ],
      );

  Future<void> _addSubject(List<Map<String, dynamic>> subjects) async {
    final name = await pickSubjectName(context, exclude: subjects.map((s) => '${s['subject']}').toList());
    if (name == null || name.isEmpty || !mounted) return;
    final t = await pickTeacher(context, _svc, _schoolId, title: 'Who teaches $name in ${_class['name']}?');
    try {
      await _svc.addSubjects('${_class['id']}', [{'subject': name, if (t?['id'] != null) 'teacherId': t!['id']}]);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Widget _subjectsTab() {
    final subjects = SchoolService.list(_d!['subjects']);
    final mine = ((_access['mySubjects'] as List?) ?? const []).map((e) => '$e').toSet();
    return SchoolPage(onRefresh: _load, children: [
      if (_isAdmin) ActionBar(primary: BarAction('Add subject', Icons.add, () => _addSubject(subjects))),
      if (subjects.isEmpty)
        const EmptyState(icon: Icons.menu_book_outlined, title: 'No subjects yet', message: 'Add the subjects taught in this class and who teaches each one.')
      else
        SectionCard(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Column(children: [
            for (var i = 0; i < subjects.length; i++) ...[
              if (i > 0) const RowDivider(),
              _subjectRow(subjects[i], mine),
            ],
          ]),
        ),
    ]);
  }

  Widget _subjectRow(Map<String, dynamic> s, Set<String> mine) {
    final isMine = mine.contains('${s['id']}');
    return EntityTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
        child: const Icon(Icons.menu_book_outlined, color: AppTheme.primary, size: 21),
      ),
      title: '${s['subject']}',
      subtitle: s['teacher'] != null ? '${s['teacher']['fullName']}' : null,
      pills: [
        if (s['teacher'] == null) const StatusPill('No teacher assigned', tone: Tone.warn),
        if (s['course'] != null) StatusPill('Syllabus: ${s['course']['title']}', tone: Tone.info, icon: Icons.link),
        if (isMine) const StatusPill('You teach this', tone: Tone.good),
      ],
      trailing: _isAdmin
          ? PopupMenuButton<String>(
              onSelected: (v) async {
                try {
                  if (v == 'teacher') {
                    final t = await pickTeacher(context, _svc, _schoolId, title: '${s['subject']} teacher');
                    if (t == null) return;
                    await _svc.updateSubject('${s['id']}', {'teacherId': t['id']});
                  } else if (v == 'course') {
                    final c = await pickCourse(context, _svc);
                    if (c == null) return;
                    await _svc.updateSubject('${s['id']}', {'courseId': c['id'] ?? c['_id']});
                  } else if (v == 'remove') {
                    if (!await confirm(context, title: 'Remove ${s['subject']}?', message: 'Lessons and homework already recorded are kept.', confirmLabel: 'Remove', destructive: true)) return;
                    await _svc.removeSubject('${s['id']}');
                  }
                  _load();
                } catch (e) {
                  if (mounted) showSnack(context, e.toString(), error: true);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'teacher', child: T('Change teacher')),
                PopupMenuItem(value: 'course', child: T('Link ECH course (syllabus)')),
                PopupMenuItem(value: 'remove', child: T('Remove subject')),
              ],
            )
          : null,
      onTap: isMine ? () => context.push('/teacher/class-subject/${s['id']}') : null,
    );
  }
}

class _ExistingStudentDialog extends StatefulWidget {
  const _ExistingStudentDialog({required this.svc, required this.schoolId});
  final SchoolService svc;
  final String schoolId;

  @override
  State<_ExistingStudentDialog> createState() => _ExistingStudentDialogState();
}

class _ExistingStudentDialogState extends State<_ExistingStudentDialog> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  Future<void> _search() async {
    if (_q.text.trim().length < 2) return;
    setState(() => _loading = true);
    try {
      final r = await widget.svc.lookupStudents(widget.schoolId, _q.text.trim());
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const T('Add an existing student'),
      content: SizedBox(
        width: 440,
        height: 380,
        child: Column(children: [
          T('Search by student code or name. Students already in another class must be moved by the school office.', style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
          const SizedBox(height: 8),
          TextField(
            controller: _q,
            autofocus: true,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Code or name', suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search)),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(children: [
                    for (final s in _items)
                      ListTile(
                        leading: CircleAvatar(child: Text(initialsOf(s['fullName']))),
                        title: T('${s['fullName']}'),
                        subtitle: T('${s['studentCode'] ?? ''} · ${s['classroom']?['name'] ?? 'No class'}${s['isActive'] == false ? ' · removed' : ''}'),
                        onTap: () => Navigator.pop(context, s),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const T('Cancel'))],
    );
  }
}

/// Paste a class list: one student per line → registered with codes + PINs.
class ImportStudentsDialog extends StatefulWidget {
  const ImportStudentsDialog({super.key, required this.svc, required this.schoolId, required this.classroomId, required this.className});
  final SchoolService svc;
  final String schoolId;
  final String classroomId;
  final String className;

  @override
  State<ImportStudentsDialog> createState() => _ImportStudentsDialogState();
}

class _ImportStudentsDialogState extends State<ImportStudentsDialog> {
  final _text = TextEditingController();
  bool _busy = false;
  List<Map<String, dynamic>>? _results;

  List<Map<String, dynamic>> _parse() {
    final rows = <Map<String, dynamic>>[];
    for (final raw in _text.text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final p = line.split(RegExp(r'[,;\t]')).map((e) => e.trim()).toList();
      String? gender;
      if (p.length > 1) {
        final g = p[1].toLowerCase();
        gender = g.startsWith('f') ? 'female' : g.startsWith('m') ? 'male' : null;
      }
      rows.add({
        'fullName': p[0],
        if (gender != null) 'gender': gender,
        if (p.length > 2 && p[2].isNotEmpty) 'dateOfBirth': p[2],
        if (p.length > 3 && (p[3].isNotEmpty || (p.length > 4 && p[4].isNotEmpty)))
          'guardians': [{'name': p[3], if (p.length > 4) 'phone': p[4]}],
      });
    }
    return rows;
  }

  Future<void> _run() async {
    final rows = _parse();
    if (rows.isEmpty) return showSnack(context, 'Paste at least one student', error: true);
    setState(() => _busy = true);
    try {
      final r = await widget.svc.importStudents(widget.schoolId, widget.classroomId, rows);
      setState(() => _results = SchoolService.list(r['results']));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _sheet() {
    final b = StringBuffer('${widget.className} — ECH sign-in (code + PIN)\n');
    for (final r in _results!.where((r) => r['ok'] == true)) {
      final st = r['student'] as Map;
      final c = r['credentials'] as Map;
      b.writeln('${st['fullName']}\t${c['studentCode']}\t${c['pin']}');
      for (final p in SchoolService.list(r['parents']).where((p) => p['pin'] != null)) {
        b.writeln('   Parent ${p['name']}\t${p['phone']}\t${p['pin']}');
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    if (_results != null) {
      final ok = _results!.where((r) => r['ok'] == true).toList();
      final failed = _results!.where((r) => r['ok'] != true).toList();
      return AlertDialog(
        title: T('${ok.length} registered, ${failed.length} not'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: ListView(children: [
            for (final r in ok)
              ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
                title: T('${(r['student'] as Map)['fullName']}'),
                subtitle: T('Code ${(r['credentials'] as Map)['studentCode']} · PIN ${(r['credentials'] as Map)['pin']}'),
              ),
            for (final r in failed)
              ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline, color: AppTheme.warningColor),
                title: T('Row ${r['row']}: ${r['fullName'] ?? ''}'),
                subtitle: T('${r['message']}${r['code'] == 'POSSIBLE_DUPLICATE' ? ' — register this one alone to confirm.' : ''}'),
              ),
          ]),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.print_outlined),
            label: const T('Print login cards'),
            onPressed: ok.isEmpty
                ? null
                : () async {
                    final cards = [
                      for (final r in ok)
                        LoginCard(fullName: '${(r['student'] as Map)['fullName']}', studentCode: '${(r['credentials'] as Map)['studentCode']}', pin: '${(r['credentials'] as Map)['pin']}'),
                    ];
                    final bytes = await buildLoginCardsPdf(schoolName: '', className: widget.className, cards: cards);
                    await saveAndOpenDocument(bytes, 'login-cards-${widget.className.replaceAll(' ', '-')}.pdf');
                  },
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy_all),
            label: const T('Copy sign-in sheet'),
            onPressed: () async {
              await showCredentialsDialog(context, title: 'Sign-in sheet', rows: [MapEntry('Codes and PINs (tab separated)', _sheet())], note: 'Paste into a spreadsheet or document, print, and give each student their own line. PINs are not shown again.');
            },
          ),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const T('Done')),
        ],
      );
    }
    return AlertDialog(
      title: T('Import students into ${widget.className}'),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          T('One student per line, separated by commas:', style: TextStyle(color: muted)),
          const SizedBox(height: 4),
          T('Full name, Gender (M/F), Date of birth (YYYY-MM-DD), Parent name, Parent phone', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
          const SizedBox(height: 4),
          T('Only the name is required. You can paste straight from Excel.', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(hintText: 'Aline Mukamana, F, 2011-03-02, Paul Habimana, 0788123456\nEric Niyonzima, M'),
          ),
          const SizedBox(height: 8),
          T('Names that already exist in the school are skipped so nobody is registered twice.', style: TextStyle(fontSize: 12, color: muted)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const T('Cancel')),
        FilledButton(onPressed: _busy ? null : _run, child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const T('Import')),
      ],
    );
  }
}
