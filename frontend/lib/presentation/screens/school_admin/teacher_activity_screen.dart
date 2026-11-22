import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';

/// Head teacher view of one teacher: what they teach, lessons marked (and
/// flagged), homework given, marking backlog, contacts and address.
class TeacherActivityScreen extends StatefulWidget {
  const TeacherActivityScreen({super.key, required this.schoolId, required this.teacherId});
  final String schoolId;
  final String teacherId;

  @override
  State<TeacherActivityScreen> createState() => _TeacherActivityScreenState();
}

class _TeacherActivityScreenState extends State<TeacherActivityScreen> {
  final _svc = SchoolService();
  int _days = 30;
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Teacher activity')),
      body: AsyncBody<Map<String, dynamic>>(
        key: _key,
        load: () => _svc.teacherActivity(widget.schoolId, widget.teacherId, days: _days),
        builder: (context, d, reload) {
          final t = Map<String, dynamic>.from(d['teacher'] as Map);
          final st = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
          final lessons = SchoolService.list(d['recentLessons']);
          final homework = SchoolService.list(d['recentHomework']);
          final subjects = SchoolService.list(d['subjects']);
          final classOf = SchoolService.list(d['classTeacherOf']);
          final profile = Map<String, dynamic>.from(t['teacherProfile'] as Map? ?? {});
          final muted = AppTheme.getSecondaryTextColor(context);
          return SchoolPage(onRefresh: reload, children: [
            SectionCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 26, child: T('${t['fullName']}'.isNotEmpty ? '${t['fullName']}'[0] : '?', style: const TextStyle(fontSize: 20))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    T('${t['fullName']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context))),
                    const SizedBox(height: 4),
                    Text([t['email'], t['phone']].where((e) => e != null).join(' · '), style: TextStyle(color: muted)),
                    if (addressLine(t['address']).isNotEmpty) Text(addressLine(t['address']), style: TextStyle(color: muted)),
                    if (profile['qualification'] != null && '${profile['qualification']}'.isNotEmpty)
                      T('${profile['qualification']}${profile['yearsExperience'] != null ? ' · ${profile['yearsExperience']} years teaching' : ''}', style: TextStyle(color: muted)),
                    T('Last active: ${t['lastActive'] == null ? 'never' : fmtDateTime(t['lastActive'])}', style: TextStyle(color: muted)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final c in classOf) StatusPill('Class teacher ${c['name']}', tone: Tone.good),
                      for (final s in subjects) StatusPill('${s['subject']} ${s['className']}', tone: Tone.info),
                    ]),
                  ]),
                ),
              ]),
            ),
            Row(children: [
              T('Last', style: TextStyle(color: muted)),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 7, label: T('7 days')), ButtonSegment(value: 30, label: T('30 days')), ButtonSegment(value: 90, label: T('90 days'))],
                selected: {_days},
                onSelectionChanged: (v) { setState(() => _days = v.first); _key.currentState?.reload(); },
              ),
            ]),
            StatGrid(children: [
              StatTile(label: 'Lessons marked taught', value: '${st['lessonsMarked'] ?? 0}', icon: Icons.fact_check_outlined, tone: Tone.good),
              StatTile(label: 'Flagged', value: '${st['flagged'] ?? 0}', icon: Icons.flag_outlined, tone: (st['flagged'] ?? 0) > 0 ? Tone.bad : Tone.good),
              StatTile(label: 'Recorded not taught', value: '${st['confirmedNotTaught'] ?? 0}', icon: Icons.block, tone: (st['confirmedNotTaught'] ?? 0) > 0 ? Tone.bad : Tone.good),
              StatTile(label: 'Homework given', value: '${st['homeworkGiven'] ?? 0}', icon: Icons.assignment_outlined),
              StatTile(label: 'Waiting to be marked', value: '${st['waitingToBeMarked'] ?? 0}', icon: Icons.pending_actions_outlined, tone: (st['waitingToBeMarked'] ?? 0) > 20 ? Tone.warn : Tone.neutral),
            ]),
            SectionCard(
              title: 'Lessons taught',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: lessons.isEmpty
                  ? T('No lessons marked in this period.', style: TextStyle(color: muted))
                  : Column(children: [
                      for (final l in lessons)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            l['status'] == 'flagged' || l['status'] == 'confirmed' ? Icons.flag : Icons.check_circle_outline,
                            color: l['status'] == 'flagged' || l['status'] == 'confirmed' ? AppTheme.errorColor : AppTheme.successColor,
                          ),
                          title: T('${l['subject']} · ${l['className']} — ${l['topic']}'),
                          subtitle: T('${fmtDay(l['taughtOn'])}${SchoolService.list(l['flags']).isNotEmpty ? ' · ${SchoolService.list(l['flags']).map((f) => f['message']).join(' ')}' : ''}'),
                        ),
                    ]),
            ),
            SectionCard(
              title: 'Homework given',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: homework.isEmpty
                  ? T('No homework in this period.', style: TextStyle(color: muted))
                  : Column(children: [
                      for (final h in homework)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.assignment_outlined),
                          title: T('${h['title']}'),
                          subtitle: T('${h['subject']} · ${h['className']} · due ${fmtDay(h['dueAt'])}'),
                        ),
                    ]),
            ),
          ]);
        },
      ),
    );
  }
}
