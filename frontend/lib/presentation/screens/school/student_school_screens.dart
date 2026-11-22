import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../widgets/eexams_section.dart';
import '../../../widgets/forms/password_field.dart';
import '../../../widgets/school/attachments.dart';
import '../../../widgets/school/school_ui.dart';
import '../../providers/auth_provider.dart';
import 'group_screens.dart';

/// Home of a school student: homework to do, "was this lesson taught?",
/// subjects with progress and marks.
class StudentSchoolHomeScreen extends ConsumerStatefulWidget {
  const StudentSchoolHomeScreen({super.key});

  @override
  ConsumerState<StudentSchoolHomeScreen> createState() => _StudentSchoolHomeScreenState();
}

class _StudentSchoolHomeScreenState extends ConsumerState<StudentSchoolHomeScreen> {
  final _svc = SchoolService();
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();

  Future<void> _check(Map<String, dynamic> c, bool taught) async {
    try {
      await _svc.checkLesson('${c['id']}', taught);
      _key.currentState?.reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const T('My school'),
        actions: [
          IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'groups') context.push('/school/groups');
              if (v == 'courses') context.go('/dashboard');
              if (v == 'pin') showChangePinDialog(context);
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth-selection');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'groups', child: T('Class groups')),
              PopupMenuItem(value: 'courses', child: T('ECH courses')),
              PopupMenuItem(value: 'pin', child: T('Change my PIN')),
              PopupMenuItem(value: 'logout', child: T('Sign out')),
            ],
          ),
        ],
      ),
      body: AsyncBody<Map<String, dynamic>>(
        key: _key,
        load: () async {
          final r = await Future.wait<dynamic>([_svc.studentHome(), _svc.groups().catchError((_) => <Map<String, dynamic>>[])]);
          return {...(r[0] as Map<String, dynamic>), '_groups': r[1]};
        },
        builder: (context, d, reload) => StudentOverviewView(
          data: d,
          groups: SchoolService.list(d['_groups']),
          onRefresh: reload,
          onOpenHomework: (a) async {
            await context.push('/school/homework/${a['id']}');
            reload();
          },
          onLessonCheck: _check,
        ),
      ),
    );
  }
}

/// Shared by the student home and the parent's child page.
class StudentOverviewView extends StatelessWidget {
  const StudentOverviewView({super.key, required this.data, required this.onRefresh, this.onOpenHomework, this.onLessonCheck, this.forParent = false, this.groups});
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>)? onOpenHomework;
  final void Function(Map<String, dynamic>, bool)? onLessonCheck;
  final bool forParent;
  /// Class groups of the student (null for parents).
  final List<Map<String, dynamic>>? groups;

  @override
  Widget build(BuildContext context) {
    final student = Map<String, dynamic>.from(data['student'] as Map? ?? {});
    final school = Map<String, dynamic>.from(data['school'] as Map? ?? {});
    final classroom = data['classroom'] as Map?;
    final todo = SchoolService.list(data['todo']);
    final recent = SchoolService.list(data['recent']);
    final subjects = SchoolService.list(data['subjects']);
    final checks = SchoolService.list(data['lessonChecks']);
    final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
    final muted = AppTheme.getSecondaryTextColor(context);
    final unreadGroups = (groups ?? const []).fold<int>(0, (n, g) => n + ((g['unread'] as num?)?.toInt() ?? 0));

    Widget detail(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: Text(label, style: TextStyle(color: muted, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
          ]),
        );

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      // Who and where
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: Text(initialsOfName('${student['fullName']}'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(forParent ? '${student['fullName']}' : 'Hello, ${'${student['fullName']}'.split(' ').first}',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context))),
                T('${school['name'] ?? ''}', style: TextStyle(color: muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          detail(Icons.meeting_room_outlined, 'Class', '${classroom?['name'] ?? 'Not in a class yet'}'),
          if (classroom?['academicYear'] != null) detail(Icons.event_outlined, 'Academic year', '${classroom!['academicYear']}'),
          detail(Icons.badge_outlined, 'Student code', '${student['studentCode'] ?? '—'}'),
          if (classroom?['classTeacher'] != null)
            detail(Icons.person_pin_outlined, 'Class teacher',
                '${classroom!['classTeacher']['fullName']}${forParent && classroom['classTeacher']['phone'] != null ? ' · ${classroom['classTeacher']['phone']}' : ''}'),
          detail(Icons.menu_book_outlined, 'Subjects', subjects.isEmpty ? '—' : subjects.map((s) => '${s['subject']}').join(', ')),
        ]),
      ),
      StatGrid(children: [
        StatTile(label: 'To do', value: '${stats['todo'] ?? 0}', icon: Icons.assignment_outlined, tone: Tone.info),
        StatTile(label: 'Overdue', value: '${stats['overdue'] ?? 0}', icon: Icons.schedule, tone: (stats['overdue'] ?? 0) > 0 ? Tone.bad : Tone.good),
        StatTile(label: 'Missed', value: '${stats['missed'] ?? 0}', icon: Icons.event_busy_outlined, tone: (stats['missed'] ?? 0) > 0 ? Tone.warn : Tone.good),
        StatTile(label: 'Handed in', value: '${stats['submitted'] ?? 0}', icon: Icons.task_alt, tone: Tone.good),
      ]),
      // Work the teachers gave
      SectionCard(
        title: forParent ? 'Homework to do' : 'Homework & work to do',
        subtitle: todo.isEmpty ? null : 'Tap one to read it and hand it in.',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: todo.isEmpty
            ? Padding(padding: const EdgeInsets.only(bottom: 12), child: T('Nothing due. Well done!', style: TextStyle(color: muted)))
            : Column(children: [for (final a in todo) _AssessmentTile(a: a, onTap: onOpenHomework)]),
      ),
      if (!forParent && groups != null)
        SectionCard(
          title: 'Class groups',
          subtitle: unreadGroups > 0 ? '$unreadGroups new message${unreadGroups == 1 ? '' : 's'}' : 'Discuss with your teachers and classmates.',
          trailing: TextButton(onPressed: () => context.push('/school/groups'), child: const T('All')),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: groups!.isEmpty
              ? Padding(padding: const EdgeInsets.only(bottom: 8), child: T('No groups yet. Your teachers can add you to one.', style: TextStyle(color: muted)))
              : Column(children: [for (final g in groups!.take(4)) GroupTile(g: g, onReturn: onRefresh)]),
        ),
      if (!forParent && checks.isNotEmpty)
        SectionCard(
          title: 'Was this lesson taught?',
          subtitle: 'Your answer is private and helps the school.',
          child: Column(children: [
            for (final c in checks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: T('${c['subject']}: ${c['topic']} (${fmtDay(c['taughtOn'])})')),
                  TextButton(onPressed: () => onLessonCheck?.call(c, true), child: const T('Yes')),
                  TextButton(style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor), onPressed: () => onLessonCheck?.call(c, false), child: const T('No')),
                ]),
              ),
          ]),
        ),
      if (subjects.isNotEmpty)
        SectionCard(
          title: 'My subjects',
          child: Column(children: [
            for (final s in subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: T('${s['subject']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (s['averagePercent'] != null)
                      StatusPill('Average ${s['averagePercent']}%', tone: (s['averagePercent'] as num) >= 70 ? Tone.good : (s['averagePercent'] as num) >= 50 ? Tone.warn : Tone.bad),
                  ]),
                  T('${s['teacher']?['fullName'] ?? 'No teacher yet'} · ${s['lessonsTaught']} lessons taught${s['lastTaughtOn'] != null ? ', last ${relativeDay(s['lastTaughtOn'])}' : ''}',
                      style: TextStyle(fontSize: 12.5, color: muted)),
                  if (s['coveragePercent'] != null) ...[const SizedBox(height: 6), ProgressLine(percent: (s['coveragePercent'] as num).toInt())],
                ]),
              ),
          ]),
        ),
      if (recent.isNotEmpty)
        SectionCard(
          title: 'Recent work and marks',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(children: [for (final a in recent.take(15)) _AssessmentTile(a: a, onTap: onOpenHomework)]),
        ),
      if (!forParent && school['hasCourseAccess'] == true)
        SectionCard(
          title: 'All ECH courses are free for you',
          subtitle: 'Your school pays for them this term.',
          trailing: FilledButton(onPressed: () => context.go('/courses'), child: const T('Browse')),
          child: const SizedBox.shrink(),
        ),
    ]);
  }
}

String initialsOfName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.a, this.onTap});
  final Map<String, dynamic> a;
  final void Function(Map<String, dynamic>)? onTap;

  @override
  Widget build(BuildContext context) {
    final state = a['state'] as String?;
    final sub = a['submission'] as Map?;
    final (label, tone) = switch (state) {
      'todo' => ('Due ${relativeDay(a['dueAt'])}', Tone.info),
      'overdue' => ('Late — hand in now', Tone.bad),
      'missed' => ('Missed', Tone.bad),
      'submitted' => ('Handed in', Tone.good),
      'graded' => ('${sub?['score']}/${a['maxScore']}', Tone.good),
      _ => ('Done', Tone.neutral),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(a['type'] == 'homework' ? Icons.assignment_outlined : Icons.quiz_outlined),
      title: T('${a['title']}'),
      subtitle: T('${a['subject']} · due ${fmtDay(a['dueAt'])}'),
      trailing: StatusPill(label, tone: tone),
      onTap: onTap == null ? null : () => onTap!(a),
    );
  }
}

/// Student: read homework, hand in photos or a typed answer, see the mark.
class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  final _svc = SchoolService();
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  final _text = TextEditingController();
  final List<Map<String, dynamic>> _photos = [];
  bool _prefilled = false;
  bool _busy = false;
  bool _uploading = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await _svc.submitAssessment(widget.assessmentId, text: _text.text.trim(), attachments: _photos);
      if (mounted) showSnack(context, 'Handed in');
      _key.currentState?.reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Homework')),
      body: AsyncBody<Map<String, dynamic>>(
        key: _key,
        load: () => _svc.studentAssessment(widget.assessmentId),
        builder: (context, a, reload) {
          final sub = a['submission'] as Map?;
          if (!_prefilled && sub != null) {
            _prefilled = true;
            _text.text = '${sub['text'] ?? ''}';
            _photos..clear()..addAll(SchoolService.list(sub['attachments']));
          }
          final graded = sub?['status'] == 'graded';
          final due = parseDate(a['dueAt']);
          final late = due != null && DateTime.now().isAfter(due);
          final closed = a['status'] == 'closed' || (late && a['allowLate'] != true);
          final mode = a['submissionMode'] as String?;
          final canHandIn = !graded && !closed && mode != 'none' && mode != 'eexams';
          final muted = AppTheme.getSecondaryTextColor(context);

          return SchoolPage(onRefresh: reload, maxWidth: 760, children: [
            SectionCard(
              title: '${a['title']}',
              subtitle: '${a['subject']} · ${a['teacher']?['fullName'] ?? ''} · due ${fmtDateTime(a['dueAt'])}${late ? ' (passed)' : ''}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ('${a['instructions'] ?? ''}'.isNotEmpty) SelectableText('${a['instructions']}', style: const TextStyle(height: 1.45)),
                const SizedBox(height: 10),
                AttachmentStrip(items: SchoolService.list(a['attachments']), size: 100),
              ]),
            ),
            if (mode == 'eexams' && a['eexamsPath'] != null)
              SectionCard(
                title: 'This is done on eexams',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(onPressed: () => openEexams(context, redirect: '${a['eexamsPath']}'), icon: const Icon(Icons.open_in_new), label: const T('Open on eexams')),
                ),
              ),
            if (graded)
              SectionCard(
                title: 'Your mark: ${sub!['score']}/${a['maxScore']}',
                child: T('${sub['feedback'] ?? ''}'.isEmpty ? 'No comment from the teacher.' : '${sub['feedback']}'),
              ),
            if (mode != 'none' && mode != 'eexams')
              SectionCard(
                title: sub == null ? 'Your work' : 'You handed in ${fmtDateTime(sub['submittedAt'])}${sub['isLate'] == true ? ' (late)' : ''}',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (mode == 'text' || _text.text.isNotEmpty || canHandIn)
                    TextField(
                      controller: _text,
                      enabled: canHandIn,
                      minLines: mode == 'text' ? 6 : 2,
                      maxLines: 14,
                      decoration: InputDecoration(labelText: trSchool(context, mode == 'text' ? 'Your answer' : 'Comment (optional)'), alignLabelWithHint: true),
                    ),
                  const SizedBox(height: 10),
                  AttachmentStrip(items: _photos, onRemove: canHandIn ? (i) => setState(() => _photos.removeAt(i)) : null, size: 100),
                  if (canHandIn) ...[
                    TextButton.icon(
                      onPressed: _uploading ? null : () async {
                        setState(() => _uploading = true);
                        final p = await pickAndUploadPhoto(context, _svc);
                        if (mounted) setState(() { if (p != null) _photos.add(p); _uploading = false; });
                      },
                      icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo_outlined),
                      label: Text(_photos.isEmpty ? 'Add a photo of your work' : 'Add another photo'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: _busy ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: Text(sub == null ? (late ? 'Hand in late' : 'Hand in') : 'Hand in again (replaces)'),
                    ),
                  ] else if (closed && sub == null)
                    T('This homework is closed.', style: TextStyle(color: muted)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}

/// Students and parents choose their own PIN.
Future<void> showChangePinDialog(BuildContext context) async {
  final current = TextEditingController();
  final next = TextEditingController();
  final again = TextEditingController();
  final form = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const T('Change my PIN'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            PasswordField.pin(controller: current, label: 'Current PIN'),
            const SizedBox(height: 12),
            PasswordField.pin(controller: next, label: 'New PIN', helper: '6 digits, not all the same or in a row', validator: (v) => (v == null || v.length != 6) ? '6 digits' : null),
            const SizedBox(height: 12),
            PasswordField.pin(controller: again, label: 'New PIN again', validator: (v) => v != next.text ? 'PINs do not match' : null),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            try {
              await SchoolService().changePin(current.text, next.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                showSnack(context, 'PIN changed');
              }
            } catch (e) {
              if (ctx.mounted) showSnack(ctx, e.toString(), error: true);
            }
          },
          child: const T('Change PIN'),
        ),
      ],
    ),
  );
}
