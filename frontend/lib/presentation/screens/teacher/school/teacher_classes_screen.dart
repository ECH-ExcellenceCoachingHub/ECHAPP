import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/school_ui.dart';

/// "My classes" card on the teacher dashboard (school teachers only).
class MyClassesPanel extends StatelessWidget {
  const MyClassesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      load: () => SchoolService().myTeaching(),
      builder: (context, d, reload) {
        if (d['schoolTeacher'] != true) return const SizedBox.shrink();
        return _MyClassesBody(d: d, compact: true);
      },
    );
  }
}

/// Full page: every class and subject the teacher has, with what needs doing.
class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('My classes')),
      body: AsyncBody<Map<String, dynamic>>(
        load: () => SchoolService().myTeaching(),
        builder: (context, d, reload) => SchoolPage(onRefresh: reload, children: [_MyClassesBody(d: d, compact: false)]),
      ),
    );
  }
}

class _MyClassesBody extends StatelessWidget {
  const _MyClassesBody({required this.d, required this.compact});
  final Map<String, dynamic> d;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subjects = SchoolService.list(d['subjects']);
    final led = SchoolService.list(d['classTeacherOf']);
    final muted = AppTheme.getSecondaryTextColor(context);
    if (subjects.isEmpty && led.isEmpty) {
      return const SectionCard(
        title: 'My classes',
        child: T('The school has not assigned you to a class or subject yet. Ask your head teacher or director of studies.'),
      );
    }
    return SectionCard(
      icon: Icons.co_present_outlined,
      title: 'My classes',
      subtitle: 'Mark lessons you taught, give homework, mark hand-ins.',
      trailing: Wrap(spacing: 4, children: [
        TextButton.icon(onPressed: () => context.push('/school/groups'), icon: const Icon(Icons.forum_outlined, size: 18), label: const T('Groups')),
        TextButton.icon(onPressed: () => context.push('/school/code'), icon: const Icon(Icons.computer_outlined, size: 18), label: const T('Lab code')),
        if (compact) TextButton(onPressed: () => context.push('/teacher/my-classes'), child: const T('Open')),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final c in led)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              child: EntityTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_pin_outlined, color: Colors.white, size: 22),
                ),
                title: 'Class teacher of ${c['name']}',
                subtitle: '${plural(c['studentCount'] as num?, 'student')} · manage the class list',
                onTap: () => context.push('/school/class/${c['id']}'),
              ),
            ),
          ),
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth > 820 ? 3 : box.maxWidth > 520 ? 2 : 1;
          final w = (box.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final s in subjects)
              SizedBox(
                width: w,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/teacher/class-subject/${s['id']}'),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor(context).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: T('${s['subject']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.getTextColor(context)))),
                          StatusPill('${s['className']}', tone: Tone.info),
                        ]),
                        const SizedBox(height: 2),
                        T(plural(s['studentCount'] as num?, 'student'), style: TextStyle(fontSize: 12.5, color: muted)),
                        const SizedBox(height: 10),
                        ProgressLine(percent: (s['coveragePercent'] as num?)?.toInt(), label: (s['syllabusLessons'] ?? 0) > 0 ? '${s['lessonsMarked']}/${s['syllabusLessons']} lessons' : '${s['lessonsMarked']} lessons taught'),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          if ((s['toGrade'] ?? 0) > 0) StatusPill('${s['toGrade']} to mark', tone: Tone.warn, icon: Icons.pending_actions_outlined),
                          if ((s['flagged'] ?? 0) > 0) StatusPill('${s['flagged']} flagged', tone: Tone.bad, icon: Icons.flag_outlined),
                          Text(s['lastTaughtOn'] == null ? 'No lesson marked yet' : 'Last lesson ${relativeDay(s['lastTaughtOn'])}', style: TextStyle(fontSize: 12, color: muted)),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}
