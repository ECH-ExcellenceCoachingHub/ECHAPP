import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// What was taught: syllabus coverage per class/subject, and lesson marks
/// that ECH flagged as possibly not taught (for the head teacher to review).
class ProgressSection extends StatefulWidget {
  const ProgressSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection> {
  String _tab = 'flagged';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Scrollable chips: fit any phone width (a 3-part toggle did not).
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Row(children: [
          for (final (key, label, icon) in const [
            ('flagged', 'To review', Icons.flag_outlined),
            ('coverage', 'Syllabus coverage', Icons.stacked_bar_chart),
            ('all', 'All lessons', Icons.list_alt),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillChoice(icon: icon, label: label, selected: _tab == key, onTap: () => setState(() => _tab = key)),
            ),
        ]),
      ),
      Expanded(
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: _tab == 'coverage' ? _Coverage(c: widget.c) : _Marks(c: widget.c, flaggedOnly: _tab == 'flagged'),
        ),
      ),
    ]);
  }
}

class _Coverage extends StatelessWidget {
  const _Coverage({required this.c});
  final SchoolCtx c;

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      load: () => c.svc.progress(c.schoolId),
      builder: (context, d, reload) {
        final classes = SchoolService.list(d['classes']);
        final muted = AppTheme.getSecondaryTextColor(context);
        return SchoolPage(onRefresh: reload, children: [
          const InfoBanner(icon: Icons.stacked_bar_chart, text: 'Coverage = lessons marked taught ÷ lessons in the linked ECH course. Link a course to each subject (Classes → class → Subjects) to see percentages.'),
          if (classes.isEmpty) const EmptyState(icon: Icons.meeting_room_outlined, title: 'No classes yet'),
          for (final cl in classes)
            SectionCard(
              icon: Icons.meeting_room_outlined,
              title: '${cl['name']}',
              child: SchoolService.list(cl['subjects']).isEmpty
                  ? T('No subjects assigned', style: TextStyle(color: muted))
                  : Column(children: [
                      for (final s in SchoolService.list(cl['subjects']))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ProgressLine(percent: (s['coveragePercent'] as num?)?.toInt(), label: '${s['subject']} — ${s['teacher']?['fullName'] ?? 'no teacher'}'),
                            const SizedBox(height: 4),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              Text(
                                '${s['lessonsMarked']}${(s['syllabusLessons'] ?? 0) > 0 ? '/${s['syllabusLessons']}' : ''} lessons · last ${s['lastTaughtOn'] == null ? 'never' : relativeDay(s['lastTaughtOn'])}',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                              if ((s['daysSinceLastLesson'] ?? 0) > 10) StatusPill('${s['daysSinceLastLesson']} days without a lesson', tone: Tone.warn),
                              if ((s['flagged'] ?? 0) > 0) StatusPill('${s['flagged']} flagged', tone: Tone.bad),
                              if ((s['confirmedNotTaught'] ?? 0) > 0) StatusPill('${s['confirmedNotTaught']} not taught', tone: Tone.bad),
                            ]),
                          ]),
                        ),
                    ]),
            ),
        ]);
      },
    );
  }
}

class _Marks extends StatefulWidget {
  const _Marks({required this.c, required this.flaggedOnly});
  final SchoolCtx c;
  final bool flaggedOnly;

  @override
  State<_Marks> createState() => _MarksState();
}

class _MarksState extends State<_Marks> {
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();

  Future<void> _review(Map<String, dynamic> m, String status) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'confirmed' ? 'Record as NOT taught' : 'Confirm it was taught'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          T('${m['subject']} · ${m['className']} — ${m['topic']}'),
          const SizedBox(height: 12),
          TextField(controller: note, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Checked the class register / spoke with the teacher')),
          if (status == 'confirmed') ...[
            const SizedBox(height: 8),
            const T('The teacher is notified and the lesson no longer counts as covered.', style: TextStyle(fontSize: 12.5)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')),
          FilledButton(
            style: status == 'confirmed' ? FilledButton.styleFrom(backgroundColor: AppTheme.errorColor) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'confirmed' ? 'Not taught' : 'It was taught'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.c.svc.reviewCoverage(widget.c.schoolId, '${m['id']}', status, note: note.text.trim());
      _key.currentState?.reload();
      widget.c.reloadSchool();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Tone _tone(String? s) => switch (s) { 'flagged' => Tone.bad, 'confirmed' => Tone.bad, 'dismissed' => Tone.good, _ => Tone.neutral };
  String _label(String? s) => switch (s) { 'flagged' => 'Flagged', 'confirmed' => 'Not taught', 'dismissed' => 'Checked: taught', _ => 'OK' };

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.coverage(widget.c.schoolId, status: widget.flaggedOnly ? 'flagged' : null),
      builder: (context, d, reload) {
        final items = SchoolService.list(d['coverage']);
        final muted = AppTheme.getSecondaryTextColor(context);
        return SchoolPage(onRefresh: reload, children: [
          if (widget.flaggedOnly)
            const InfoBanner(icon: Icons.flag_outlined, tone: Tone.warn, text: 'ECH flags a lesson mark when it was marked in bulk, dated in the future or on a weekend, has no evidence, or when most students say it was not taught.'),
          if (items.isEmpty)
            EmptyState(icon: Icons.task_alt, title: widget.flaggedOnly ? 'Nothing to review' : 'No lessons marked yet')
          else
            for (final m in items)
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: T('${m['subject']} · ${m['className']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.getTextColor(context)))),
                    StatusPill(_label(m['status'] as String?), tone: _tone(m['status'] as String?)),
                  ]),
                  const SizedBox(height: 4),
                  T('${m['chapterTitle'] != null ? '${m['chapterTitle']} › ' : ''}${m['topic']}', style: TextStyle(color: AppTheme.getTextColor(context))),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: m['teacher'] == null ? null : () => context.push('/school-admin/teachers/${m['teacher']['id']}?school=${widget.c.schoolId}'),
                    child: T('${m['teacher']?['fullName'] ?? ''} · taught ${fmtDay(m['taughtOn'])} · marked ${fmtDateTime(m['markedAt'])}', style: TextStyle(fontSize: 12.5, color: muted)),
                  ),
                  if ((m['notes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    T('Teacher note: ${m['notes']}', style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final f in SchoolService.list(m['flags']))
                      StatusPill('${f['message']}', tone: f['severity'] == 'high' ? Tone.bad : f['severity'] == 'medium' ? Tone.warn : Tone.neutral, icon: Icons.flag_outlined),
                    if (((m['studentChecks'] as Map?)?['yes'] ?? 0) + ((m['studentChecks'] as Map?)?['no'] ?? 0) > 0)
                      StatusPill('Students: ${m['studentChecks']['yes']} yes / ${m['studentChecks']['no']} no', tone: Tone.info, icon: Icons.how_to_vote_outlined),
                  ]),
                  if (m['status'] == 'flagged' || m['status'] == 'ok') ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), side: BorderSide(color: AppTheme.successColor.withValues(alpha: 0.6)), foregroundColor: AppTheme.successColor),
                          onPressed: () => _review(m, 'dismissed'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const T('It was taught'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.6)), foregroundColor: AppTheme.errorColor),
                          onPressed: () => _review(m, 'confirmed'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const T('Not taught'),
                        ),
                      ),
                    ]),
                  ],
                  if (m['review'] != null && (m['review']['note'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    T('Review note: ${m['review']['note']}', style: TextStyle(fontSize: 12.5, color: muted)),
                  ],
                ]),
              ),
        ]);
      },
    );
  }
}
