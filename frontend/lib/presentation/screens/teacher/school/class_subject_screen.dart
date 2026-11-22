import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/attachments.dart';
import '../../../../widgets/school/school_ui.dart';
import 'homework_screens.dart';

/// One subject in one class, for its teacher: lessons taught (syllabus),
/// homework, and the class list.
class ClassSubjectScreen extends StatefulWidget {
  const ClassSubjectScreen({super.key, required this.classSubjectId});
  final String classSubjectId;

  @override
  State<ClassSubjectScreen> createState() => _ClassSubjectScreenState();
}

class _ClassSubjectScreenState extends State<ClassSubjectScreen> {
  final _svc = SchoolService();
  Map<String, dynamic>? _syl;
  Map<String, dynamic>? _hw;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([_svc.syllabus(widget.classSubjectId), _svc.assessments(widget.classSubjectId)]);
      if (mounted) setState(() { _syl = r[0]; _hw = r[1]; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Map<String, dynamic> get _cs => Map<String, dynamic>.from(_syl!['classSubject'] as Map);
  bool get _canTeach => _syl!['canTeach'] == true;

  Future<void> _mark({Map<String, dynamic>? lesson}) async {
    final r = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _MarkTaughtDialog(svc: _svc, lesson: lesson));
    if (r == null) return;
    try {
      final res = await _svc.markTaught(widget.classSubjectId, r);
      final cov = Map<String, dynamic>.from(res['coverage'] as Map);
      if (mounted) {
        if (cov['status'] == 'flagged') {
          await showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const T('Marked — flagged for review'),
            content: T('ECH saved the lesson but flagged it for the head teacher:\n\n${SchoolService.list(cov['flags']).map((f) => '• ${f['message']}').join('\n')}\n\nAdd notes or a photo of the board next time so it is clear the lesson happened.'),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const T('OK'))],
          ));
        } else {
          showSnack(context, 'Marked as taught');
        }
      }
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _unmark(Map<String, dynamic> cov) async {
    if (!await confirm(context, title: 'Undo this mark?', message: 'Only possible within 48 hours.', confirmLabel: 'Undo')) return;
    try {
      await _svc.unmarkTaught('${cov['id']}');
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syl == null) {
      return Scaffold(appBar: AppBar(title: const T('Subject')), body: _error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _load));
    }
    final cs = _cs;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          title: T('${cs['subject']} · ${cs['className']}'),
          actions: [
            IconButton(tooltip: 'Class code (sign-in)', icon: const Icon(Icons.pin_outlined), onPressed: () => context.push('/school/code?classId=${cs['classroomId']}')),
            IconButton(tooltip: 'Class list', icon: const Icon(Icons.groups_outlined), onPressed: () => context.push('/school/class/${cs['classroomId']}')),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Lessons taught'), Tab(text: 'Homework')]),
        ),
        floatingActionButton: _canTeach
            ? Builder(builder: (ctx) {
                final tab = DefaultTabController.of(ctx);
                return AnimatedBuilder(
                  animation: tab,
                  builder: (_, __) => tab.index == 0
                      ? FloatingActionButton.extended(onPressed: () => _mark(), icon: const Icon(Icons.check), label: const T('Mark a lesson'))
                      : FloatingActionButton.extended(
                          onPressed: () async {
                            final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => HomeworkFormScreen(classSubjectId: widget.classSubjectId, subject: '${cs['subject']}', className: '${cs['className']}')));
                            if (ok == true) _load();
                          },
                          icon: const Icon(Icons.add_task),
                          label: const T('Give homework'),
                        ),
                );
              })
            : null,
        body: TabBarView(children: [_lessonsTab(), _homeworkTab()]),
      ),
    );
  }

  Widget _lessonsTab() {
    final s = Map<String, dynamic>.from(_syl!['summary'] as Map? ?? {});
    final chapters = SchoolService.list(_syl!['chapters']);
    final others = SchoolService.list(_syl!['otherTopics']);
    final muted = AppTheme.getSecondaryTextColor(context);
    return SchoolPage(onRefresh: _load, children: [
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProgressLine(percent: (s['percent'] as num?)?.toInt(), label: _cs['course'] != null ? 'Syllabus: ${_cs['course']['title']} — ${s['taught']}/${s['total']} lessons' : 'No ECH course linked — mark topics you taught'),
          if ((s['flagged'] ?? 0) > 0) ...[const SizedBox(height: 8), StatusPill('${s['flagged']} mark(s) flagged for review', tone: Tone.bad)],
          const SizedBox(height: 8),
          T('Mark a lesson on the day you teach it. Add a short note or a photo of the board — marks without evidence, in bulk, or that students say did not happen are flagged to the head teacher.', style: TextStyle(fontSize: 12.5, color: muted)),
        ]),
      ),
      for (final ch in chapters)
        SectionCard(
          title: '${ch['title']}',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [
            for (final l in SchoolService.list(ch['lessons'])) _lessonTile(l),
          ]),
        ),
      if (others.isNotEmpty || chapters.isEmpty)
        SectionCard(
          title: chapters.isEmpty ? 'Topics taught' : 'Other topics taught',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: others.isEmpty
              ? Padding(padding: const EdgeInsets.only(bottom: 12), child: T('Nothing marked yet.', style: TextStyle(color: muted)))
              : Column(children: [for (final c in others) _coverageTile(c)]),
        ),
      const SizedBox(height: 70),
    ]);
  }

  Widget _lessonTile(Map<String, dynamic> l) {
    final cov = l['coverage'] as Map<String, dynamic>?;
    if (cov != null) return _coverageTile(cov, title: '${l['title']}');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.radio_button_unchecked, color: AppTheme.getSecondaryTextColor(context)),
      title: T('${l['title']}'),
      trailing: _canTeach ? TextButton(onPressed: () => _mark(lesson: l), child: const T('Mark taught')) : null,
    );
  }

  Widget _coverageTile(Map<String, dynamic> c, {String? title}) {
    final flagged = c['status'] == 'flagged' || c['status'] == 'confirmed';
    final flags = SchoolService.list(c['flags']);
    final canUndo = _canTeach && c['review'] == null && DateTime.now().difference(parseDate(c['markedAt']) ?? DateTime(2000)).inHours < 48;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(flagged ? Icons.flag : Icons.check_circle, color: flagged ? AppTheme.errorColor : AppTheme.successColor),
      title: Text(title ?? '${c['topic']}'),
      subtitle: Text([
        'Taught ${fmtDay(c['taughtOn'])}',
        if (c['status'] == 'confirmed') 'Recorded as NOT taught by the school',
        if (c['status'] == 'dismissed') 'Checked by the school',
        if (flags.isNotEmpty && c['status'] == 'flagged') flags.map((f) => f['message']).join(' '),
      ].join(' · ')),
      trailing: canUndo ? IconButton(tooltip: 'Undo', icon: const Icon(Icons.undo), onPressed: () => _unmark(c)) : null,
    );
  }

  Widget _homeworkTab() {
    final list = SchoolService.list(_hw?['assessments']);
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No homework yet',
        message: _canTeach ? 'Give homework to the whole class. Students are notified and see it on their dashboard; parents see it too.' : null,
      );
    }
    return SchoolPage(onRefresh: _load, children: [
      for (final a in list)
        Material(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeworkDetailScreen(assessmentId: '${a['id']}')));
              _load();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6))),
              child: Row(children: [
                Icon(a['type'] == 'homework' ? Icons.assignment_outlined : Icons.quiz_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    T('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    T('Due ${fmtDay(a['dueAt'])} (${relativeDay(a['dueAt'])}) · ${a['submitted']}/${a['classSize']} handed in · ${a['graded']} marked${a['averageScore'] != null ? ' · average ${a['averageScore']}/${a['maxScore']}' : ''}',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
                  ]),
                ),
                if ((a['submitted'] ?? 0) - (a['graded'] ?? 0) > 0) StatusPill('${(a['submitted'] ?? 0) - (a['graded'] ?? 0)} to mark', tone: Tone.warn),
                if (a['status'] == 'closed') const Padding(padding: EdgeInsets.only(left: 6), child: StatusPill('Closed')),
              ]),
            ),
          ),
        ),
      const SizedBox(height: 70),
    ]);
  }
}

class _MarkTaughtDialog extends StatefulWidget {
  const _MarkTaughtDialog({required this.svc, this.lesson});
  final SchoolService svc;
  final Map<String, dynamic>? lesson;

  @override
  State<_MarkTaughtDialog> createState() => _MarkTaughtDialogState();
}

class _MarkTaughtDialogState extends State<_MarkTaughtDialog> {
  final _topic = TextEditingController();
  final _notes = TextEditingController();
  DateTime _day = DateTime.now();
  final List<Map<String, dynamic>> _photos = [];
  bool _uploading = false;

  @override
  void dispose() {
    _topic.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLesson = widget.lesson != null;
    return AlertDialog(
      title: Text(isLesson ? 'Mark "${widget.lesson!['title']}" as taught' : 'Mark a topic as taught'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isLesson) ...[
              TextField(controller: _topic, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Topic taught *')),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: T('Taught on ${fmtDay(_day)}'),
              onPressed: () async {
                final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now(), initialDate: _day);
                if (d != null) setState(() => _day = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _notes, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'What you did (recommended)', hintText: 'e.g. Explained osmosis, demo with potato strips, exercise 3.2 in class')),
            const SizedBox(height: 12),
            AttachmentStrip(items: _photos, onRemove: (i) => setState(() => _photos.removeAt(i)), size: 64),
            TextButton.icon(
              onPressed: _uploading ? null : () async {
                setState(() => _uploading = true);
                final p = await pickAndUploadPhoto(context, widget.svc);
                if (mounted) setState(() { if (p != null) _photos.add(p); _uploading = false; });
              },
              icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo_outlined),
              label: const T('Add photo of the board / class work'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const T('Cancel')),
        FilledButton(
          onPressed: () {
            if (!isLesson && _topic.text.trim().isEmpty) return showSnack(context, 'Type the topic', error: true);
            Navigator.pop(context, {
              if (isLesson) 'lessonId': widget.lesson!['id'] else 'topic': _topic.text.trim(),
              'taughtOn': DateTime(_day.year, _day.month, _day.day, 12).toIso8601String(),
              'notes': _notes.text.trim(),
              'attachments': _photos,
            });
          },
          child: const T('Mark taught'),
        ),
      ],
    );
  }
}
