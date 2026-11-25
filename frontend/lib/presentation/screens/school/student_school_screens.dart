import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../services/api/eexams_service.dart';
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
              if (v == 'labs') context.push('/labs');
              if (v == 'library') context.push('/library');
              if (v == 'courses') context.push('/courses');
              if (v == 'pin') showChangePinDialog(context);
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth-selection');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'labs', child: T('Virtual laboratory')),
              PopupMenuItem(value: 'library', child: T('Library')),
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
          onJoinExam: (a) => joinClassExam(context, a),
          onLessonCheck: _check,
        ),
      ),
    );
  }
}

/// Shared by the student home and the parent's child page.
class StudentOverviewView extends StatelessWidget {
  const StudentOverviewView({super.key, required this.data, required this.onRefresh, this.onOpenHomework, this.onJoinExam, this.onLessonCheck, this.forParent = false, this.groups});
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>)? onOpenHomework;
  /// "Join exam" on an exam the teacher sent from eexams.
  final void Function(Map<String, dynamic>)? onJoinExam;
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
    final courses = SchoolService.list(data['courses']);
    final checks = SchoolService.list(data['lessonChecks']);
    final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
    final muted = AppTheme.getSecondaryTextColor(context);
    final unreadGroups = (groups ?? const []).fold<int>(0, (n, g) => n + ((g['unread'] as num?)?.toInt() ?? 0));

    final ct = classroom?['classTeacher'] as Map?;
    final firstName = '${student['fullName']}'.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      PageHero(
        colors: forParent ? null : const [Color(0xFF0E9F6E), Color(0xFF0B6E99)],
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(initialsOfName('${student['fullName']}'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        ),
        title: forParent ? '${student['fullName']}' : '$greeting, $firstName',
        subtitle: '${school['name'] ?? ''}',
        chips: [
          HeroChip(classroom?['name'] != null ? '${classroom!['name']}' : 'Not in a class yet', icon: Icons.meeting_room_outlined),
          if (student['studentCode'] != null) HeroChip('${student['studentCode']}', icon: Icons.badge_outlined),
          if (ct != null) HeroChip('${ct['fullName']}${forParent && ct['phone'] != null ? ' · ${ct['phone']}' : ''}', icon: Icons.person_pin_outlined),
        ],
      ),
      MiniStats(items: [
        MiniStat('${stats['todo'] ?? 0}', 'To do', tone: Tone.info),
        MiniStat('${stats['overdue'] ?? 0}', 'Overdue', tone: (stats['overdue'] ?? 0) > 0 ? Tone.bad : Tone.neutral),
        MiniStat('${stats['missed'] ?? 0}', 'Missed', tone: (stats['missed'] ?? 0) > 0 ? Tone.warn : Tone.neutral),
        MiniStat('${stats['submitted'] ?? 0}', 'Handed in', tone: Tone.good),
      ]),
      // Labs, library and the other learning tools, so students find them.
      if (!forParent) StudentToolsPanel(unreadGroups: unreadGroups),
      // Work the teachers gave
      SectionCard(
        icon: Icons.assignment_outlined,
        title: forParent ? 'Homework and exams to do' : 'Homework and exams',
        subtitle: todo.isEmpty ? null : forParent ? 'Tap one to help your child read it and hand it in.' : 'Tap one to read it and hand it in.',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: todo.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const Icon(Icons.celebration_outlined, color: AppTheme.successColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: T('Nothing due. Well done!', style: TextStyle(color: muted))),
                ]),
              )
            : Column(children: [
                for (var i = 0; i < todo.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _AssessmentTile(a: todo[i], onTap: onOpenHomework, onJoin: onJoinExam),
                ],
              ]),
      ),
      if (!forParent && checks.isNotEmpty)
        SectionCard(
          icon: Icons.fact_check_outlined,
          tone: Tone.warn,
          title: 'Was this lesson taught?',
          subtitle: 'Your answer is private and helps the school.',
          child: Column(children: [
            for (var i = 0; i < checks.length; i++) ...[
              if (i > 0) const RowDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${checks[i]['subject']}: ${checks[i]['topic']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  T(fmtDay(checks[i]['taughtOn']), style: TextStyle(color: muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => onLessonCheck?.call(checks[i], true), icon: const Icon(Icons.check, size: 18), label: const T('Yes, taught'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5))),
                        onPressed: () => onLessonCheck?.call(checks[i], false),
                        icon: const Icon(Icons.close, size: 18),
                        label: const T('No'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ],
          ]),
        ),
      if (!forParent && courses.isNotEmpty)
        SectionCard(
          icon: Icons.play_lesson_outlined,
          tone: Tone.good,
          title: 'My courses',
          subtitle: school['hasCourseAccess'] == true
              ? 'Free for your class. Your school pays for them this term.'
              : 'Your school has not paid this term yet. Ask your school to open them.',
          child: LayoutBuilder(builder: (context, c) {
            void open(Map<String, dynamic> course) => school['hasCourseAccess'] == true
                ? context.push('/course/${course['id']}')
                : showSnack(context, 'Your school has not paid this term yet.', error: true);
            // Phones: swipe through the courses; wider screens: a grid.
            if (c.maxWidth < 560) {
              return SizedBox(
                height: 212,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: 236, child: CourseCard(course: courses[i], onTap: () => open(courses[i]))),
                ),
              );
            }
            final cols = c.maxWidth >= 720 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final course in courses) SizedBox(width: w, child: CourseCard(course: course, onTap: () => open(course))),
            ]);
          }),
        ),
      if (!forParent && groups != null)
        SectionCard(
          icon: Icons.forum_outlined,
          title: 'Class groups',
          subtitle: unreadGroups > 0 ? '$unreadGroups new message${unreadGroups == 1 ? '' : 's'}' : 'Discuss with your teachers and classmates.',
          trailing: TextButton(onPressed: () => context.push('/school/groups'), child: const T('See all')),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: groups!.isEmpty
              ? Padding(padding: const EdgeInsets.only(bottom: 8), child: T('No groups yet. Your teachers can add you to one.', style: TextStyle(color: muted)))
              : Column(children: [for (final g in groups!.take(4)) GroupTile(g: g, onReturn: onRefresh)]),
        ),
      if (subjects.isNotEmpty)
        SectionCard(
          icon: Icons.menu_book_outlined,
          title: forParent ? 'Subjects' : 'My subjects',
          child: Column(children: [
            for (var i = 0; i < subjects.length; i++) ...[
              if (i > 0) const RowDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: T('${subjects[i]['subject']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    if (subjects[i]['averagePercent'] != null)
                      StatusPill('Average ${subjects[i]['averagePercent']}%',
                          tone: (subjects[i]['averagePercent'] as num) >= 70 ? Tone.good : (subjects[i]['averagePercent'] as num) >= 50 ? Tone.warn : Tone.bad),
                  ]),
                  const SizedBox(height: 2),
                  T('${subjects[i]['teacher']?['fullName'] ?? 'No teacher yet'} · ${subjects[i]['lessonsTaught']} lessons taught${subjects[i]['lastTaughtOn'] != null ? ', last ${relativeDay(subjects[i]['lastTaughtOn'])}' : ''}',
                      style: TextStyle(fontSize: 12.5, color: muted)),
                  if (subjects[i]['coveragePercent'] != null) ...[const SizedBox(height: 8), ProgressLine(percent: (subjects[i]['coveragePercent'] as num).toInt())],
                ]),
              ),
            ],
          ]),
        ),
      if (recent.isNotEmpty)
        SectionCard(
          icon: Icons.grading_outlined,
          tone: Tone.good,
          title: 'Recent work and marks',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(children: [
            for (var i = 0; i < recent.take(15).length; i++) ...[
              if (i > 0) const RowDivider(),
              _AssessmentTile(a: recent[i], onTap: onOpenHomework),
            ],
          ]),
        ),
    ]);
  }
}

/// "Explore and learn" on the school student home: the virtual lab and the
/// library as two big cards, then the other tools as a launcher grid.
class StudentToolsPanel extends StatelessWidget {
  const StudentToolsPanel({super.key, this.unreadGroups = 0});
  final int unreadGroups;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final labCard = _FeatureToolCard(
      icon: Icons.science_rounded,
      tag: '3D · VR',
      title: 'Virtual laboratory',
      caption: 'Do real science experiments in 3D and VR — safely, at your own level.',
      action: 'Open the lab',
      colors: const [Color(0xFF6D28D9), Color(0xFF2563EB)],
      onTap: () => context.push('/labs'),
    );
    final libraryCard = _FeatureToolCard(
      icon: Icons.local_library_rounded,
      tag: 'Books',
      title: 'Library',
      caption: 'Read books and study materials for your class.',
      action: 'Open the library',
      colors: const [Color(0xFFEA580C), Color(0xFFDB2777)],
      onTap: () => context.push('/library'),
    );
    final tools = <_ToolItem>[
      _ToolItem(Icons.forum_rounded, 'Class groups', 'Chat with your class', const Color(0xFF0EA5E9), () => context.push('/school/groups'), badge: unreadGroups),
      _ToolItem(Icons.videocam_rounded, 'Live classes', 'Join online lessons', const Color(0xFFEF4444), () => context.push('/upcoming-sessions')),
      _ToolItem(Icons.chat_bubble_rounded, 'Messages', 'Talk to your teachers', const Color(0xFF8B5CF6), () => context.push('/messages')),
      _ToolItem(Icons.notifications_rounded, 'Notifications', 'News for you', const Color(0xFFF59E0B), () => context.push('/notifications')),
      _ToolItem(Icons.download_for_offline_rounded, 'Downloads', 'Study offline', const Color(0xFF10B981), () => context.push('/downloads')),
      _ToolItem(Icons.workspace_premium_rounded, 'Certificates', 'Your awards', const Color(0xFFD97706), () => context.push('/certificates')),
      _ToolItem(Icons.explore_rounded, 'All courses', 'Learn more topics', const Color(0xFF14B8A6), () => context.push('/courses')),
      _ToolItem(Icons.help_rounded, 'Help', 'Get support', const Color(0xFF64748B), () => context.push('/help')),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: T('Explore and learn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context)))),
          const SizedBox(height: 2),
          T('Your learning tools in one place.', style: TextStyle(fontSize: 13, color: muted)),
        ]),
      ),
      LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 560) return Column(children: [labCard, const SizedBox(height: 12), libraryCard]);
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: labCard),
            const SizedBox(width: 12),
            Expanded(child: libraryCard),
          ]),
        );
      }),
      const SizedBox(height: 12),
      Container(
        decoration: cardDecoration(context),
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: T('More tools', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context))),
          ),
          LayoutBuilder(builder: (context, c) {
            const cols = 4;
            final w = c.maxWidth / cols;
            return Wrap(children: [for (final t in tools) SizedBox(width: w, child: _ToolTile(item: t, showCaption: w >= 130))]);
          }),
        ]),
      ),
    ]);
  }
}

class _ToolItem {
  const _ToolItem(this.icon, this.label, this.caption, this.color, this.onTap, {this.badge = 0});
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;
  final int badge;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.item, required this.showCaption});
  final _ToolItem item;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: trSchool(context, item.label),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: item.color, size: 25),
              ),
              if (item.badge > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.getCardColor(context), width: 2),
                    ),
                    child: Text(item.badge > 99 ? '99+' : '${item.badge}',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
            const SizedBox(height: 7),
            T(item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2, color: AppTheme.getTextColor(context))),
            if (showCaption) ...[
              const SizedBox(height: 2),
              T(item.caption,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppTheme.getSecondaryTextColor(context))),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Big gradient card for a headline tool (virtual lab, library).
class _FeatureToolCard extends StatelessWidget {
  const _FeatureToolCard({required this.icon, required this.tag, required this.title, required this.caption, required this.action, required this.colors, required this.onTap});
  final IconData icon;
  final String tag;
  final String title;
  final String caption;
  final String action;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: '${trSchool(context, title)}. ${trSchool(context, caption)}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(children: [
                // Large faded icon as decoration in the corner.
                Positioned(right: -18, bottom: -22, child: Icon(icon, size: 130, color: Colors.white.withValues(alpha: 0.12))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(13)),
                        child: Icon(icon, color: Colors.white, size: 25),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: T(tag, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    T(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 4),
                    T(caption, style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        T(action, style: TextStyle(color: colors.first, fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 17, color: colors.first),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

String initialsOfName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.a, this.onTap, this.onJoin});
  final Map<String, dynamic> a;
  final void Function(Map<String, dynamic>)? onTap;
  final void Function(Map<String, dynamic>)? onJoin;

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
    final joinable = a['submissionMode'] == 'eexams' && a['eexamsPath'] != null && (state == 'todo' || state == 'overdue') && onJoin != null;
    final isExam = a['type'] != 'homework';
    return EntityTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: toneColor(context, isExam ? Tone.warn : Tone.info).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
        child: Icon(isExam ? Icons.quiz_outlined : Icons.assignment_outlined, color: toneColor(context, isExam ? Tone.warn : Tone.info), size: 21),
      ),
      title: '${a['title']}',
      subtitle: '${a['subject']} · ${fmtDay(a['dueAt'])}',
      pills: [
        StatusPill(label, tone: tone),
        if (sub?['submittedVia'] == 'parent') const StatusPill('From parent account', tone: Tone.neutral),
        if (sub?['submittedVia'] == 'eexams') const StatusPill('eexams', tone: Tone.neutral),
      ],
      trailing: joinable ? FilledButton(onPressed: () => onJoin!(a), child: const T('Join')) : null,
      onTap: onTap == null ? null : () => onTap!(a),
    );
  }
}

/// Student: read homework, hand in photos or a typed answer, see the mark.
///
/// With [childId] a parent opens their child's homework: they can hand it in
/// from home (school-only schools) and open exams on eexams as the child.
class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key, required this.assessmentId, this.childId});
  final String assessmentId;
  final String? childId;

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
      final child = widget.childId;
      if (child != null) {
        await _svc.submitChildAssessment(child, widget.assessmentId, text: _text.text.trim(), attachments: _photos);
      } else {
        await _svc.submitAssessment(widget.assessmentId, text: _text.text.trim(), attachments: _photos);
      }
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
        load: () => widget.childId != null ? _svc.childAssessment(widget.childId!, widget.assessmentId) : _svc.studentAssessment(widget.assessmentId),
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

          final forParent = widget.childId != null;
          return SchoolPage(onRefresh: reload, maxWidth: 760, children: [
            if (forParent)
              const InfoBanner(
                icon: Icons.family_restroom_outlined,
                text: 'You are helping your child. Work you hand in here goes to the teacher, marked "from parent account".',
              ),
            SectionCard(
              title: '${a['title']}',
              subtitle: '${a['subject']} · ${a['teacher']?['fullName'] ?? ''} · due ${fmtDateTime(a['dueAt'])}${late ? ' (passed)' : ''}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ('${a['instructions'] ?? ''}'.isNotEmpty) SelectableText('${a['instructions']}', style: const TextStyle(height: 1.45)),
                const SizedBox(height: 10),
                AttachmentStrip(items: SchoolService.list(a['attachments']), size: 100),
              ]),
            ),
            if (mode == 'eexams' && a['eexamsPath'] != null && !graded)
              SectionCard(
                title: 'This exam is done on eexams',
                subtitle: forParent ? 'It opens signed in as your child. The mark comes back here.' : 'The mark comes back here when it is marked.',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: closed ? null : () => joinClassExam(context, a, childId: widget.childId),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: T(closed ? 'Exam closed' : 'Join exam'),
                  ),
                ),
              ),
            if (graded)
              SectionCard(
                title: '${forParent ? 'Mark' : 'Your mark'}: ${sub!['score']}/${a['maxScore']}',
                child: T('${sub['feedback'] ?? ''}'.isEmpty ? 'No comment from the teacher.' : '${sub['feedback']}'),
              ),
            if (mode != 'none' && mode != 'eexams')
              SectionCard(
                title: sub == null
                    ? (forParent ? 'The work' : 'Your work')
                    : '${sub['submittedVia'] == 'parent' ? 'Handed in from the parent account' : 'Handed in'} ${fmtDateTime(sub['submittedAt'])}${sub['isLate'] == true ? ' (late)' : ''}',
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

/// Opens a class exam on eexams: as the student, or (parent) as their child.
Future<void> joinClassExam(BuildContext context, Map<String, dynamic> a, {String? childId}) async {
  if (childId == null) return openEexams(context, redirect: '${a['eexamsPath']}');
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final link = await SchoolService().childExamLink(childId, '${a['id']}');
    await EexamsService().launch(Uri.parse(link));
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
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
