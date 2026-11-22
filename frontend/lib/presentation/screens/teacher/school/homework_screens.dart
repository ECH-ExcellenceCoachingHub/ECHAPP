import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../services/api/teacher_tools_service.dart';
import '../../../../widgets/school/attachments.dart';
import '../../../../widgets/school/school_ui.dart';

/// Give homework (or link an eexams quiz/exam) to a whole class.
class HomeworkFormScreen extends StatefulWidget {
  const HomeworkFormScreen({super.key, required this.classSubjectId, required this.subject, required this.className});
  final String classSubjectId;
  final String subject;
  final String className;

  @override
  State<HomeworkFormScreen> createState() => _HomeworkFormScreenState();
}

class _HomeworkFormScreenState extends State<HomeworkFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = SchoolService();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  final _maxScore = TextEditingController(text: '10');
  String _type = 'homework';
  String _mode = 'photo';
  DateTime _due = DateTime.now().add(const Duration(days: 2));
  bool _allowLate = true;
  final List<Map<String, dynamic>> _files = [];
  EexamsExamSummary? _exam;
  bool _busy = false;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    _maxScore.dispose();
    super.dispose();
  }

  Future<void> _pickExam() async {
    List<EexamsExamSummary> exams;
    try {
      exams = await TeacherToolsService().listExams();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not load your eexams exams: $e', error: true);
      return;
    }
    if (!mounted) return;
    final e = await showDialog<EexamsExamSummary>(context: context, builder: (ctx) => SimpleDialog(
      title: const T('Your exams on eexams'),
      children: [
        if (exams.isEmpty) const Padding(padding: EdgeInsets.all(16), child: T('No exams yet. Create one in Teacher tools → Create exam.')),
        for (final x in exams) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, x), child: T('${x.title}  (${x.status})')),
      ],
    ));
    if (e != null) setState(() { _exam = e; if (_title.text.isEmpty) _title.text = e.title; });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_type != 'homework' && _mode == 'eexams' && _exam == null) return showSnack(context, 'Choose the eexams exam', error: true);
    setState(() => _busy = true);
    try {
      final r = await _svc.createAssessment(widget.classSubjectId, {
        'type': _type,
        'title': _title.text.trim(),
        'instructions': _instructions.text.trim(),
        'submissionMode': _type == 'homework' ? _mode : (_exam != null ? 'eexams' : _mode),
        'maxScore': num.tryParse(_maxScore.text.trim()) ?? 10,
        'dueAt': _due.toUtc().toIso8601String(),
        'allowLate': _allowLate,
        'attachments': _files,
        if (_exam != null) 'eexamsExamId': _exam!.id,
      });
      if (!mounted) return;
      showSnack(context, 'Sent to ${widget.className} — ${(r['assessment'] as Map)['notified']} students notified');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: T('Homework · ${widget.subject} ${widget.className}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _save,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
            label: T('Send to ${widget.className}'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SchoolPage(maxWidth: 720, children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'homework', label: T('Homework'), icon: Icon(Icons.assignment_outlined)),
              ButtonSegment(value: 'quiz', label: T('Quiz'), icon: Icon(Icons.quiz_outlined)),
              ButtonSegment(value: 'exam', label: T('Exam'), icon: Icon(Icons.fact_check_outlined)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextFormField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Read chapter 3 and summarise'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Give it a title' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _instructions, minLines: 4, maxLines: 10, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Instructions', hintText: 'What students must do, pages, questions…', alignLabelWithHint: true)),
              const SizedBox(height: 12),
              AttachmentStrip(items: _files, onRemove: (i) => setState(() => _files.removeAt(i))),
              TextButton.icon(
                onPressed: _uploading ? null : () async {
                  setState(() => _uploading = true);
                  final p = await pickAndUploadPhoto(context, _svc);
                  if (mounted) setState(() { if (p != null) _files.add(p); _uploading = false; });
                },
                icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_photo_alternate_outlined),
                label: const T('Attach a photo (worksheet, page…)'),
              ),
            ]),
          ),
          SectionCard(
            title: 'How students answer',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_type != 'homework') ...[
                OutlinedButton.icon(
                  onPressed: _pickExam,
                  icon: const Icon(Icons.link),
                  label: Text(_exam == null ? 'Link an exam from eexams (optional)' : 'eexams: ${_exam!.title}'),
                ),
                const SizedBox(height: 6),
                T('Linked eexams exams open from the student\'s homework list. Results come back to ECH automatically.', style: TextStyle(fontSize: 12.5, color: muted)),
                const SizedBox(height: 12),
              ],
              if (_exam == null)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(label: const T('Photo of their work'), selected: _mode == 'photo', onSelected: (_) => setState(() => _mode = 'photo')),
                  ChoiceChip(label: const T('Typed answer'), selected: _mode == 'text', onSelected: (_) => setState(() => _mode = 'text')),
                  ChoiceChip(label: const T('Nothing to hand in'), selected: _mode == 'none', onSelected: (_) => setState(() => _mode = 'none')),
                ]),
            ]),
          ),
          SectionCard(
            title: 'Due date and marks',
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: T('Due ${fmtDateTime(_due)}'),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 180)), initialDate: _due);
                      if (d == null || !context.mounted) return;
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
                      setState(() => _due = DateTime(d.year, d.month, d.day, t?.hour ?? 18, t?.minute ?? 0));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    controller: _maxScore,
                    enabled: _mode != 'none' || _type != 'homework',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Out of'),
                    validator: (v) => (num.tryParse(v ?? '') == null) ? 'Number' : null,
                  ),
                ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowLate,
                onChanged: (v) => setState(() => _allowLate = v),
                title: const T('Accept late hand-ins'),
                subtitle: const T('Late work is labelled as late.'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Teacher view of one homework: who handed in, mark each submission.
class HomeworkDetailScreen extends StatefulWidget {
  const HomeworkDetailScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  State<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends State<HomeworkDetailScreen> {
  final _svc = SchoolService();
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  String _filter = 'all';

  Future<void> _grade(Map<String, dynamic> a, Map<String, dynamic> st) async {
    final sub = Map<String, dynamic>.from(st['submission'] as Map);
    final score = TextEditingController(text: sub['score'] != null ? '${sub['score']}' : '');
    final feedback = TextEditingController(text: '${sub['feedback'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: T('${st['fullName']}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              T('Handed in ${fmtDateTime(sub['submittedAt'])}${sub['isLate'] == true ? ' (late)' : ''}', style: TextStyle(color: AppTheme.getSecondaryTextColor(ctx))),
              const SizedBox(height: 10),
              if ((sub['text'] ?? '').toString().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.getBorderColor(ctx).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: SelectableText('${sub['text']}'),
                ),
                const SizedBox(height: 10),
              ],
              AttachmentStrip(items: SchoolService.list(sub['attachments']), size: 110),
              const SizedBox(height: 14),
              TextField(controller: score, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Score (out of ${a['maxScore']})')),
              const SizedBox(height: 10),
              TextField(controller: feedback, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Feedback for the student')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const T('Save mark')),
        ],
      ),
    );
    if (ok != true) return;
    final v = num.tryParse(score.text.trim());
    if (v == null) return showSnack(context, 'Enter a score', error: true);
    try {
      await _svc.grade(widget.assessmentId, '${sub['id']}', v, feedback: feedback.text.trim());
      _key.currentState?.reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Homework')),
      body: AsyncBody<Map<String, dynamic>>(
        key: _key,
        load: () => _svc.assessment(widget.assessmentId),
        builder: (context, d, reload) {
          final a = Map<String, dynamic>.from(d['assessment'] as Map);
          final students = SchoolService.list(d['students']);
          final handed = students.where((s) => s['submission'] != null).toList();
          final missing = students.where((s) => s['submission'] == null).toList();
          final toMark = handed.where((s) => s['submission']['status'] != 'graded').toList();
          final shown = switch (_filter) { 'tomark' => toMark, 'missing' => missing, _ => students };
          final muted = AppTheme.getSecondaryTextColor(context);
          return SchoolPage(onRefresh: reload, children: [
            SectionCard(
              title: '${a['title']}',
              subtitle: '${a['subject']} · ${a['className'] ?? ''} · due ${fmtDateTime(a['dueAt'])} · out of ${a['maxScore']}',
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  try {
                    if (v == 'close') await _svc.updateAssessment(widget.assessmentId, {'status': a['status'] == 'closed' ? 'published' : 'closed'});
                    if (v == 'delete') {
                      if (!await confirm(context, title: 'Delete this homework?', message: 'Only possible before anyone hands in.', confirmLabel: 'Delete', destructive: true)) return;
                      await _svc.deleteAssessment(widget.assessmentId);
                      if (context.mounted) Navigator.pop(context);
                      return;
                    }
                    reload();
                  } catch (e) {
                    if (context.mounted) showSnack(context, e.toString(), error: true);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'close', child: Text(a['status'] == 'closed' ? 'Reopen' : 'Close (stop hand-ins)')),
                  const PopupMenuItem(value: 'delete', child: T('Delete')),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ('${a['instructions']}'.isNotEmpty) T('${a['instructions']}'),
                const SizedBox(height: 8),
                AttachmentStrip(items: SchoolService.list(a['attachments'])),
              ]),
            ),
            StatGrid(children: [
              StatTile(label: 'Handed in', value: '${handed.length}/${students.length}', icon: Icons.upload_file_outlined, tone: Tone.info),
              StatTile(label: 'To mark', value: '${toMark.length}', icon: Icons.pending_actions_outlined, tone: toMark.isEmpty ? Tone.good : Tone.warn),
              StatTile(label: 'Missing', value: '${missing.length}', icon: Icons.person_off_outlined, tone: missing.isEmpty ? Tone.good : Tone.bad),
            ]),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'all', label: T('All')), ButtonSegment(value: 'tomark', label: T('To mark')), ButtonSegment(value: 'missing', label: T('Missing'))],
              selected: {_filter},
              onSelectionChanged: (v) => setState(() => _filter = v.first),
            ),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: shown.isEmpty
                  ? const Padding(padding: EdgeInsets.all(16), child: T('Nobody here.'))
                  : Column(children: [
                      for (final st in shown)
                        ListTile(
                          leading: Icon(
                            st['submission'] == null ? Icons.radio_button_unchecked : st['submission']['status'] == 'graded' ? Icons.check_circle : Icons.inbox_outlined,
                            color: st['submission'] == null ? muted : st['submission']['status'] == 'graded' ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                          title: T('${st['fullName']}'),
                          subtitle: Text(st['submission'] == null
                              ? 'Not handed in'
                              : '${st['submission']['status'] == 'graded' ? 'Marked ${st['submission']['score']}/${a['maxScore']}' : 'Handed in ${fmtDateTime(st['submission']['submittedAt'])}'}${st['submission']['isLate'] == true ? ' · late' : ''}'),
                          trailing: st['submission'] == null ? null : const Icon(Icons.chevron_right),
                          onTap: st['submission'] == null ? null : () => _grade(a, st),
                        ),
                    ]),
            ),
          ]);
        },
      ),
    );
  }
}
