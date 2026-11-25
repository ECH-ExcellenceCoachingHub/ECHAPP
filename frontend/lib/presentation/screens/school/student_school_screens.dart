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
import '../../../widgets/school/student_nav_bar.dart';
import '../../../widgets/search/search_suggestions.dart';
import '../../providers/auth_provider.dart';
import 'group_screens.dart';

/// Home of a school student, split into four tabs so no page gets long:
///   Home  — today: what is due next, lesson checks, quick shortcuts, latest marks
///   Work  — all homework and exams, marks, subjects
///   Learn — virtual lab, library, courses and other learning tools
///   Class — teachers, class groups, messages
/// Personal things (PIN, certificates, downloads, help, sign out) open from the avatar.
class StudentSchoolHomeScreen extends ConsumerStatefulWidget {
  const StudentSchoolHomeScreen({super.key, this.initialTab = 0, this.tabRequest});
  /// 0 Home, 1 Work, 2 Learn, 3 Class (`/school/home?tab=2`).
  final int initialTab;
  /// Changes on every tap of the school bar on another page (`&at=`).
  final String? tabRequest;

  @override
  ConsumerState<StudentSchoolHomeScreen> createState() => _StudentSchoolHomeScreenState();
}

class _StudentSchoolHomeScreenState extends ConsumerState<StudentSchoolHomeScreen> {
  final _svc = SchoolService();
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  late int _tab = widget.initialTab.clamp(0, 3);

  @override
  void didUpdateWidget(StudentSchoolHomeScreen old) {
    super.didUpdateWidget(old);
    // Coming back from a shared page through its bottom bar.
    if (old.initialTab != widget.initialTab || old.tabRequest != widget.tabRequest) _tab = widget.initialTab.clamp(0, 3);
  }
  /// Sub-view of the Work tab: 0 to do, 1 done and marks, 2 subjects.
  int _workView = 0;
  /// Last loaded data, for the app bar avatar and the tab badges.
  Map<String, dynamic>? _data;

  static const _titles = ['My school', 'My work', 'Learn', 'My class'];

  Future<Map<String, dynamic>> _load() async {
    final r = await Future.wait<dynamic>([_svc.studentHome(), _svc.groups().catchError((_) => <Map<String, dynamic>>[])]);
    final d = {...(r[0] as Map<String, dynamic>), '_groups': r[1]};
    if (mounted) setState(() => _data = d);
    return d;
  }

  Future<void> _reload() async => _key.currentState?.reload();

  Future<void> _check(Map<String, dynamic> c, bool taught) async {
    try {
      await _svc.checkLesson('${c['id']}', taught);
      _reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openHomework(Map<String, dynamic> a) async {
    await context.push('/school/homework/${a['id']}');
    _reload();
  }

  void _goTo(int tab, [int? workView]) => setState(() {
        _tab = tab;
        if (workView != null) _workView = workView;
      });

  void _openMe() {
    final d = _data ?? const {};
    final student = Map<String, dynamic>.from(d['student'] as Map? ?? {});
    final school = Map<String, dynamic>.from(d['school'] as Map? ?? {});
    final classroom = d['classroom'] as Map?;
    final outer = context;
    void go(String route) {
      Navigator.pop(outer);
      outer.push(route);
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.getCardColor(context),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              _GradientAvatar(name: '${student['fullName'] ?? ''}', radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${student['fullName'] ?? ''}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(ctx))),
                  const SizedBox(height: 2),
                  Text(
                    [if (classroom?['name'] != null) '${classroom!['name']}', if (student['studentCode'] != null) '${student['studentCode']}'].join(' · '),
                    style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(ctx)),
                  ),
                  if (school['name'] != null) Text('${school['name']}', style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(ctx))),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _MenuRow(icon: Icons.workspace_premium_rounded, color: const Color(0xFFD97706), label: 'My certificates', onTap: () => go('/certificates')),
            _MenuRow(icon: Icons.download_for_offline_rounded, color: const Color(0xFF10B981), label: 'Downloads', caption: 'Study offline', onTap: () => go('/downloads')),
            _MenuRow(icon: Icons.lock_reset_rounded, color: const Color(0xFF6366F1), label: 'Change my PIN', onTap: () {
              Navigator.pop(ctx);
              showChangePinDialog(outer);
            }),
            _MenuRow(icon: Icons.help_rounded, color: const Color(0xFF64748B), label: 'Help', caption: 'Get support', onTap: () => go('/help')),
            const SizedBox(height: 6),
            const RowDivider(),
            const SizedBox(height: 6),
            _MenuRow(
              icon: Icons.logout_rounded,
              color: AppTheme.errorColor,
              label: 'Sign out',
              danger: true,
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (outer.mounted) outer.go('/auth-selection');
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? const <String, dynamic>{};
    final student = Map<String, dynamic>.from(d['student'] as Map? ?? {});
    final stats = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
    final groups = SchoolService.list(d['_groups']);
    final unread = groups.fold<int>(0, (n, g) => n + ((g['unread'] as num?)?.toInt() ?? 0));
    final pending = ((stats['todo'] as num?) ?? 0).toInt() + ((stats['overdue'] as num?) ?? 0).toInt();

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: T(_titles[_tab]),
        actions: [
          IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 2),
            child: Semantics(
              button: true,
              label: trSchool(context, 'My account'),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openMe,
                child: _GradientAvatar(name: '${student['fullName'] ?? ''}', radius: 17),
              ),
            ),
          ),
        ],
      ),
      body: AsyncBody<Map<String, dynamic>>(
        key: _key,
        load: _load,
        builder: (context, data, reload) {
          final groups = SchoolService.list(data['_groups']);
          return IndexedStack(index: _tab, children: [
            _HomeTab(data: data, unreadGroups: unread, onRefresh: reload, onOpenHomework: _openHomework, onJoinExam: (a) => joinClassExam(context, a), onLessonCheck: _check, onGoTo: _goTo),
            _WorkTab(data: data, view: _workView, onView: (v) => setState(() => _workView = v), onRefresh: reload, onOpenHomework: _openHomework, onJoinExam: (a) => joinClassExam(context, a)),
            _LearnTab(data: data, onRefresh: reload),
            _ClassTab(data: data, groups: groups, onRefresh: reload),
          ]);
        },
      ),
      bottomNavigationBar: SchoolStudentNavBar(selected: _tab, onSelect: (i) => setState(() => _tab = i), workBadge: pending, classBadge: unread),
    );
  }
}

// ───────────────────────────── Home tab ─────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.data, required this.unreadGroups, required this.onRefresh, required this.onOpenHomework, required this.onJoinExam, required this.onLessonCheck, required this.onGoTo});
  final Map<String, dynamic> data;
  final int unreadGroups;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpenHomework;
  final void Function(Map<String, dynamic>) onJoinExam;
  final void Function(Map<String, dynamic>, bool) onLessonCheck;
  final void Function(int tab, [int? workView]) onGoTo;

  @override
  Widget build(BuildContext context) {
    final todo = SchoolService.list(data['todo']);
    final recent = SchoolService.list(data['recent']);
    final checks = SchoolService.list(data['lessonChecks']);
    final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
    final marks = recent.where((a) => a['state'] == 'graded').take(2).toList();
    final next = todo.take(3).toList();
    final courses = SchoolService.list(data['courses']);
    final paid = (data['school'] as Map?)?['hasCourseAccess'] == true;
    final resume = paid ? _continueCourse(courses) : null;

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      _StudentHero(data: data),
      MiniStats(items: [
        MiniStat('${stats['todo'] ?? 0}', 'To do', tone: Tone.info, onTap: () => onGoTo(1, 0)),
        MiniStat('${stats['overdue'] ?? 0}', 'Overdue', tone: (stats['overdue'] ?? 0) > 0 ? Tone.bad : Tone.neutral, onTap: () => onGoTo(1, 0)),
        MiniStat('${stats['missed'] ?? 0}', 'Missed', tone: (stats['missed'] ?? 0) > 0 ? Tone.warn : Tone.neutral, onTap: () => onGoTo(1, 1)),
        MiniStat('${stats['submitted'] ?? 0}', 'Handed in', tone: Tone.good, onTap: () => onGoTo(1, 1)),
      ]),
      // Homework first: the one thing a student must not miss.
      if (todo.isEmpty)
        Container(decoration: cardDecoration(context), padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: const _AllCaughtUp())
      else
        SectionCard(
          icon: Icons.event_note_rounded,
          title: 'Up next',
          subtitle: 'Tap one to read it and hand it in.',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < next.length; i++) ...[
              if (i > 0) const RowDivider(),
              _AssessmentTile(a: next[i], onTap: onOpenHomework, onJoin: onJoinExam),
            ],
            if (todo.length > next.length) _SeeAllButton(label: 'See all ${todo.length}', onTap: () => onGoTo(1, 0)),
          ]),
        ),
      if (resume != null) _ContinueCard(course: resume, onTap: () => openClassCourse(context, resume, paid)),
      _QuickAccess(items: [
        _ToolItem(Icons.play_lesson_rounded, 'My courses', courses.isEmpty ? 'Lessons' : plural(courses.length, 'course'), const Color(0xFF0E9F6E), () => context.push('/school/courses')),
        _ToolItem(Icons.science_rounded, 'Virtual lab', '3D · VR', const Color(0xFF7C3AED), () => context.push('/labs')),
        _ToolItem(Icons.local_library_rounded, 'Library', 'Books', const Color(0xFFEA580C), () => context.push('/library')),
        _ToolItem(Icons.forum_rounded, 'Groups', 'Class chat', const Color(0xFF0EA5E9), () => onGoTo(3), badge: unreadGroups),
      ]),
      if (checks.isNotEmpty) _LessonChecksCard(checks: checks, onLessonCheck: onLessonCheck),
      if (marks.isNotEmpty)
        SectionCard(
          icon: Icons.grading_rounded,
          tone: Tone.good,
          title: 'Latest marks',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < marks.length; i++) ...[
              if (i > 0) const RowDivider(),
              _AssessmentTile(a: marks[i], onTap: onOpenHomework),
            ],
            _SeeAllButton(label: 'All my marks', onTap: () => onGoTo(1, 1)),
          ]),
        ),
    ]);
  }
}

/// Short greeting card: name, school, class and class teacher.
class _StudentHero extends StatelessWidget {
  const _StudentHero({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final student = Map<String, dynamic>.from(data['student'] as Map? ?? {});
    final school = Map<String, dynamic>.from(data['school'] as Map? ?? {});
    final classroom = data['classroom'] as Map?;
    final ct = classroom?['classTeacher'] as Map?;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return PageHero(
      colors: const [Color(0xFF0E9F6E), Color(0xFF0B6E99)],
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child: Text(initialsOfName('${student['fullName']}'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
      ),
      title: '$greeting, ${'${student['fullName']}'.split(' ').first}',
      subtitle: '${school['name'] ?? ''}',
      chips: [
        HeroChip(classroom?['name'] != null ? '${classroom!['name']}' : 'Not in a class yet', icon: Icons.meeting_room_outlined),
        if (ct != null) HeroChip('${ct['fullName']}', icon: Icons.person_pin_outlined),
      ],
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final c = toneColor(context, Tone.good);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.13), shape: BoxShape.circle),
          child: Icon(Icons.celebration_rounded, color: c, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            T('You are all caught up!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getTextColor(context))),
            const SizedBox(height: 2),
            T('Nothing due. A good time to visit the lab or the library.', style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
          ]),
        ),
      ]),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TextButton(
          onPressed: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            T(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 17),
          ]),
        ),
      );
}

/// Four colourful shortcuts in one row.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.items, this.title = 'Quick access'});
  final List<_ToolItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(context),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Semantics(header: true, child: T(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)))),
        ),
        LayoutBuilder(builder: (context, c) {
          final cols = items.length < 4 ? items.length : 4;
          final w = c.maxWidth / cols;
          return Wrap(children: [for (final t in items) SizedBox(width: w, child: _ToolTile(item: t, showCaption: true))]);
        }),
      ]),
    );
  }
}

// ───────────────────────────── Work tab ─────────────────────────────

class _WorkTab extends StatelessWidget {
  const _WorkTab({required this.data, required this.view, required this.onView, required this.onRefresh, required this.onOpenHomework, required this.onJoinExam});
  final Map<String, dynamic> data;
  final int view;
  final ValueChanged<int> onView;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpenHomework;
  final void Function(Map<String, dynamic>) onJoinExam;

  @override
  Widget build(BuildContext context) {
    final todo = SchoolService.list(data['todo']);
    final recent = SchoolService.list(data['recent']);
    final subjects = SchoolService.list(data['subjects']);
    final muted = AppTheme.getSecondaryTextColor(context);

    final Widget body = switch (view) {
      1 => SectionCard(
          icon: Icons.grading_rounded,
          tone: Tone.good,
          title: 'Handed in and marks',
          subtitle: recent.isEmpty ? null : 'Tap one to see your answer and the teacher\'s comment.',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: recent.isEmpty
              ? Padding(padding: const EdgeInsets.only(bottom: 10), child: T('Nothing handed in yet.', style: TextStyle(color: muted)))
              : _AssessmentList(items: recent, onTap: onOpenHomework),
        ),
      2 => subjects.isEmpty
          ? const EmptyState(icon: Icons.menu_book_outlined, title: 'No subjects yet', message: 'Your school has not added subjects to your class yet.')
          : _SubjectsCard(subjects: subjects, title: 'My subjects'),
      _ => SectionCard(
          icon: Icons.assignment_rounded,
          title: 'Homework and exams to do',
          subtitle: todo.isEmpty ? null : 'Tap one to read it and hand it in.',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: todo.isEmpty ? const _AllCaughtUp() : _AssessmentList(items: todo, onTap: onOpenHomework, onJoin: onJoinExam),
        ),
    };

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      _Segments(
        selected: view,
        onSelect: onView,
        items: [
          (Icons.pending_actions_rounded, todo.isEmpty ? 'To do' : 'To do · ${todo.length}'),
          (Icons.task_alt_rounded, 'Marks'),
          (Icons.menu_book_rounded, 'Subjects'),
        ],
      ),
      body,
    ]);
  }
}

/// Full-width segmented switch (equal parts, selected one filled green).
class _Segments extends StatelessWidget {
  const _Segments({required this.items, required this.selected, required this.onSelect});
  final List<(IconData, String)> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0E9F6E);
    final muted = AppTheme.getSecondaryTextColor(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: cardDecoration(context, radius: 14),
      child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(color: i == selected ? green : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(items[i].$1, size: 17, color: i == selected ? Colors.white : muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: T(items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: i == selected ? Colors.white : muted)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _AssessmentList extends StatelessWidget {
  const _AssessmentList({required this.items, this.onTap, this.onJoin, this.max = 30});
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>)? onTap;
  final void Function(Map<String, dynamic>)? onJoin;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(max).toList();
    return Column(children: [
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) const RowDivider(),
        _AssessmentTile(a: shown[i], onTap: onTap, onJoin: onJoin),
      ],
    ]);
  }
}

class _SubjectsCard extends StatelessWidget {
  const _SubjectsCard({required this.subjects, required this.title});
  final List<Map<String, dynamic>> subjects;
  final String title;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return SectionCard(
      icon: Icons.menu_book_rounded,
      title: title,
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
    );
  }
}

class _LessonChecksCard extends StatelessWidget {
  const _LessonChecksCard({required this.checks, required this.onLessonCheck});
  final List<Map<String, dynamic>> checks;
  final void Function(Map<String, dynamic>, bool)? onLessonCheck;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return SectionCard(
      icon: Icons.fact_check_outlined,
      tone: Tone.warn,
      title: 'Was this lesson taught?',
      subtitle: 'Your answer is private and helps the school.',
      child: Column(children: [
        for (var i = 0; i < checks.length; i++) ...[
          if (i > 0) const RowDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${checks[i]['subject']}: ${checks[i]['topic']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  T(fmtDay(checks[i]['taughtOn']), style: TextStyle(color: muted, fontSize: 12.5)),
                ]),
              ),
              const SizedBox(width: 8),
              _AnswerButton(label: 'Yes', icon: Icons.check_rounded, color: AppTheme.successColor, onTap: () => onLessonCheck?.call(checks[i], true)),
              const SizedBox(width: 6),
              _AnswerButton(label: 'No', icon: Icons.close_rounded, color: AppTheme.errorColor, onTap: () => onLessonCheck?.call(checks[i], false)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// Small coloured "Yes" / "No" pill for a lesson check.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.12),
        shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.45))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 4),
              T(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.5)),
            ]),
          ),
        ),
      );
}

// ───────────────────────────── Learn tab ─────────────────────────────

class _LearnTab extends StatelessWidget {
  const _LearnTab({required this.data, required this.onRefresh});
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final school = Map<String, dynamic>.from(data['school'] as Map? ?? {});
    final classroom = data['classroom'] as Map?;
    final courses = SchoolService.list(data['courses']);
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

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      // Courses first: lessons that follow the class syllabus.
      _MyCoursesSpotlight(courses: courses, paid: school['hasCourseAccess'] == true, className: classroom?['name'] as String?),
      _SectionLabel('Explore and practise'),
      LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 560) return Column(children: [labCard, const SizedBox(height: 12), libraryCard]);
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: labCard), const SizedBox(width: 12), Expanded(child: libraryCard)]),
        );
      }),
      _QuickAccess(title: 'More ways to learn', items: [
        _ToolItem(Icons.videocam_rounded, 'Live classes', 'Online lessons', const Color(0xFFEF4444), () => context.push('/upcoming-sessions')),
        _ToolItem(Icons.explore_rounded, 'ECH catalogue', 'More topics', const Color(0xFF14B8A6), () => context.push('/courses')),
        _ToolItem(Icons.download_for_offline_rounded, 'Downloads', 'Offline', const Color(0xFF10B981), () => context.push('/downloads')),
      ]),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Semantics(
          header: true,
          child: T(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context))),
        ),
      );
}

/// Opens a class course, or explains why it is locked.
void openClassCourse(BuildContext context, Map<String, dynamic> course, bool paid) =>
    paid ? context.push('/course/${course['id']}') : showSnack(context, 'Your school has not paid this term yet.', error: true);

/// The course the student opened last and has not finished.
Map<String, dynamic>? _continueCourse(List<Map<String, dynamic>> courses) {
  final started = courses.where((c) => ((c['progress'] as num?) ?? 0) > 0 && c['completed'] != true && ((c['progress'] as num?) ?? 0) < 100).toList()
    ..sort((a, b) => '${b['lastOpenedAt'] ?? ''}'.compareTo('${a['lastOpenedAt'] ?? ''}'));
  return started.isEmpty ? null : started.first;
}

/// "My courses" at the top of Learn: what the courses are for, where the
/// student left off, the courses themselves and a way to see them all.
class _MyCoursesSpotlight extends StatelessWidget {
  const _MyCoursesSpotlight({required this.courses, required this.paid, this.className});
  final List<Map<String, dynamic>> courses;
  final bool paid;
  final String? className;

  static const _colors = [Color(0xFF0E9F6E), Color(0xFF0B6E99)];

  @override
  Widget build(BuildContext context) {
    final resume = paid ? _continueCourse(courses) : null;
    final done = courses.where((c) => c['completed'] == true || ((c['progress'] as num?) ?? 0) >= 100).length;

    final header = Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: _colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: _colors.last.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(right: -14, top: -14, child: Icon(Icons.play_lesson_rounded, size: 110, color: Colors.white.withValues(alpha: 0.10))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.play_lesson_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: T('My courses', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
                Text(
                  [
                    plural(courses.length, trSchool(context, 'course')),
                    if (done > 0) '$done ${trSchool(context, 'completed')}',
                    if (paid && className != null) '${trSchool(context, 'free for')} $className',
                  ].join(' · '),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          T('Video lessons, notes and quizzes that follow your class subjects. Learn at your own pace and revise before tests and exams.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            HeroChip('Follows your syllabus', icon: Icons.menu_book_rounded),
            HeroChip('Your own pace', icon: Icons.schedule_rounded),
            HeroChip('Exam revision', icon: Icons.emoji_events_rounded),
          ]),
        ]),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      if (!paid && courses.isNotEmpty) ...[
        const SizedBox(height: 12),
        const InfoBanner(icon: Icons.lock_clock_rounded, tone: Tone.warn, text: 'Your school has not paid this term yet, so the courses are locked. Ask your school to open them.'),
      ],
      if (resume != null) ...[
        const SizedBox(height: 12),
        _ContinueCard(course: resume, onTap: () => openClassCourse(context, resume, paid)),
      ],
      const SizedBox(height: 12),
      if (courses.isEmpty)
        Container(
          decoration: cardDecoration(context),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.hourglass_empty_rounded, color: AppTheme.getSecondaryTextColor(context)),
            const SizedBox(width: 12),
            Expanded(child: T('Your school has not opened courses for your class yet. They will appear here.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context)))),
          ]),
        )
      else ...[
        LayoutBuilder(builder: (context, c) {
          // Phones: swipe through the courses; wider screens: a grid of the first ones.
          if (c.maxWidth < 560) {
            return SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 228, child: CourseCard(course: courses[i], onTap: () => openClassCourse(context, courses[i], paid))),
              ),
            );
          }
          final cols = c.maxWidth >= 720 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final course in courses.take(cols * 2)) SizedBox(width: w, child: CourseCard(course: course, onTap: () => openClassCourse(context, course, paid))),
          ]);
        }),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _colors.first,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => context.push('/school/courses'),
          icon: const Icon(Icons.grid_view_rounded),
          label: T('View all my courses (${courses.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    ]);
  }
}

/// "Continue learning": the last course the student was working on.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course, required this.onTap});
  final Map<String, dynamic> course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ((course['progress'] as num?) ?? 0).toInt().clamp(0, 100);
    return Material(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(context, borderColor: AppTheme.primary.withValues(alpha: 0.5)),
          child: Row(children: [
            CourseThumb(url: course['thumbnail'] as String?, size: 64, width: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T('Continue learning', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text('${course['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context))),
                const SizedBox(height: 6),
                ProgressLine(percent: p, tone: Tone.good, label: 'Progress'),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}

/// All the class courses of a school student, with search and subject filter
/// (`/school/courses`).
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _searchCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }
  String? _subject;
  /// 0 all, 1 in progress, 2 not started, 3 completed.
  int _status = 0;

  bool _matches(Map<String, dynamic> c) {
    final p = ((c['progress'] as num?) ?? 0).toInt();
    final done = c['completed'] == true || p >= 100;
    if (_status == 1 && (p == 0 || done)) return false;
    if (_status == 2 && p > 0) return false;
    if (_status == 3 && !done) return false;
    if (_subject != null && c['subject'] != _subject) return false;
    final q = _query.trim();
    return q.isEmpty || searchRelevance(q, '${c['title']}', '${c['subject']} ${c['description']}') > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('My courses')),
      bottomNavigationBar: const SchoolStudentNavBar(selected: 2),
      body: AsyncBody<Map<String, dynamic>>(
        load: () => SchoolService().studentHome(),
        builder: (context, d, reload) {
          final school = Map<String, dynamic>.from(d['school'] as Map? ?? {});
          final paid = school['hasCourseAccess'] == true;
          final all = SchoolService.list(d['courses']);
          final subjects = {for (final c in all) if ('${c['subject'] ?? ''}'.isNotEmpty) '${c['subject']}'}.toList()..sort();
          final shown = all.where(_matches).toList();
          final resume = paid ? _continueCourse(all) : null;

          return SchoolPage(onRefresh: reload, maxWidth: 1000, children: [
            if (!paid && all.isNotEmpty)
              const InfoBanner(icon: Icons.lock_clock_rounded, tone: Tone.warn, text: 'Your school has not paid this term yet, so the courses are locked. Ask your school to open them.'),
            if (resume != null) _ContinueCard(course: resume, onTap: () => openClassCourse(context, resume, paid)),
            SearchSuggestions(
              controller: _searchCtl,
              load: (q) async => [
                for (final c in rankByQuery(all, q, (c) => '${c['title']}', extra: (c) => '${c['subject']} ${c['description']}'))
                  SearchSuggestion(id: '${c['id']}', title: '${c['title']}', thumbnail: c['thumbnail'] as String?, subtitle: '${c['subject'] ?? ''}', data: c),
              ],
              onSelected: (s) => openClassCourse(context, s.data! as Map<String, dynamic>, paid),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: trSchool(context, 'Search my courses'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: trSchool(context, 'Clear'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _searchCtl.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: AppTheme.getCardColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6))),
                ),
              ),
            ),
            _Segments(
              selected: _status,
              onSelect: (v) => setState(() => _status = v),
              items: const [(Icons.apps_rounded, 'All'), (Icons.timelapse_rounded, 'Started'), (Icons.fiber_new_rounded, 'New'), (Icons.verified_rounded, 'Done')],
            ),
            if (subjects.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  PillChoice(label: 'All subjects', selected: _subject == null, onTap: () => setState(() => _subject = null)),
                  for (final s in subjects) ...[const SizedBox(width: 8), PillChoice(label: s, selected: _subject == s, onTap: () => setState(() => _subject = s))],
                ]),
              ),
            if (all.isEmpty)
              const EmptyState(icon: Icons.play_lesson_outlined, title: 'No courses yet', message: 'Your school has not opened courses for your class yet.')
            else if (shown.isEmpty)
              const EmptyState(icon: Icons.search_off_rounded, title: 'No course matches', message: 'Try another word, subject or filter.')
            else
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 640 ? 3 : 2;
                final w = (c.maxWidth - (cols - 1) * 12) / cols;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final course in shown) SizedBox(width: w, child: CourseCard(course: course, onTap: () => openClassCourse(context, course, paid))),
                ]);
              }),
          ]);
        },
      ),
    );
  }
}

// ───────────────────────────── Class tab ─────────────────────────────

class _ClassTab extends StatelessWidget {
  const _ClassTab({required this.data, required this.groups, required this.onRefresh});
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> groups;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final classroom = data['classroom'] as Map?;
    final ct = classroom?['classTeacher'] as Map?;
    final subjects = SchoolService.list(data['subjects']);
    final unread = groups.fold<int>(0, (n, g) => n + ((g['unread'] as num?)?.toInt() ?? 0));

    // Teacher → the subjects they teach in this class.
    final teachers = <String, List<String>>{};
    for (final s in subjects) {
      final name = s['teacher']?['fullName'];
      if (name != null) teachers.putIfAbsent('$name', () => []).add('${s['subject']}');
    }
    final ctName = ct?['fullName'] == null ? null : '${ct!['fullName']}';
    final names = [if (ctName != null) ctName, ...teachers.keys.where((n) => n != ctName)];

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      SectionCard(
        icon: Icons.forum_rounded,
        title: 'Class groups',
        subtitle: unread > 0 ? '$unread new message${unread == 1 ? '' : 's'}' : 'Discuss with your teachers and classmates.',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: groups.isEmpty
            ? Padding(padding: const EdgeInsets.only(bottom: 8), child: T('No groups yet. Your teachers can add you to one.', style: TextStyle(color: muted)))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final g in groups.take(5)) GroupTile(g: g, onReturn: onRefresh),
                if (groups.length > 5) _SeeAllButton(label: 'See all ${groups.length}', onTap: () => context.push('/school/groups')),
              ]),
      ),
      _MenuCard(children: [
        _MenuRow(icon: Icons.chat_bubble_rounded, color: const Color(0xFF8B5CF6), label: 'Messages', caption: 'Talk to your teachers privately', onTap: () => context.push('/messages')),
        _MenuRow(icon: Icons.videocam_rounded, color: const Color(0xFFEF4444), label: 'Live classes', caption: 'Join online lessons', onTap: () => context.push('/upcoming-sessions')),
      ]),
      SectionCard(
        icon: Icons.co_present_rounded,
        title: classroom?['name'] != null ? 'My teachers · ${classroom!['name']}' : 'My teachers',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: names.isEmpty
            ? Padding(padding: const EdgeInsets.only(bottom: 8), child: T('Your teachers will appear here.', style: TextStyle(color: muted)))
            : Column(children: [
                for (var i = 0; i < names.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  EntityTile(
                    leading: InitialsAvatar(names[i], tone: names[i] == ctName ? Tone.good : Tone.info),
                    title: names[i],
                    subtitle: (teachers[names[i]] ?? const []).join(', '),
                    pills: [if (names[i] == ctName) const StatusPill('Class teacher', tone: Tone.good)],
                  ),
                ],
              ]),
      ),
    ]);
  }
}

// ───────────────────────────── Shared bits ─────────────────────────────

/// Initials on a green-blue gradient circle (app bar and "Me" sheet).
class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.name, this.radius = 18});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF0E9F6E), Color(0xFF0B6E99)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Text(initialsOfName(name), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * 0.72)),
      );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardDecoration(context),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const RowDivider(), children[i]],
        ]),
      );
}

/// Icon in a soft coloured square + label (+ caption) + chevron.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.color, required this.label, required this.onTap, this.caption, this.danger = false});
  final IconData icon;
  final Color color;
  final String label;
  final String? caption;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: trSchool(context, label),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: dark ? 0.22 : 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: danger ? AppTheme.errorColor : AppTheme.getTextColor(context))),
                if (caption != null) T(caption!, style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
              ]),
            ),
            if (!danger) Icon(Icons.chevron_right_rounded, color: AppTheme.getSecondaryTextColor(context)),
          ]),
        ),
      ),
    );
  }
}

/// The parent's page about one child: one page, homework first.
class StudentOverviewView extends StatelessWidget {
  const StudentOverviewView({super.key, required this.data, required this.onRefresh, this.onOpenHomework, this.onJoinExam, this.onLessonCheck, this.forParent = false, this.groups});
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>)? onOpenHomework;
  /// "Join exam" on an exam the teacher sent from eexams.
  final void Function(Map<String, dynamic>)? onJoinExam;
  final void Function(Map<String, dynamic>, bool)? onLessonCheck;
  final bool forParent;
  /// Unused since the student home moved to tabs; kept for callers.
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
    final ct = classroom?['classTeacher'] as Map?;

    return SchoolPage(onRefresh: onRefresh, maxWidth: 900, children: [
      PageHero(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(initialsOfName('${student['fullName']}'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
        ),
        title: '${student['fullName']}',
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
      SectionCard(
        icon: Icons.assignment_rounded,
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
            : _AssessmentList(items: todo, onTap: onOpenHomework, onJoin: onJoinExam),
      ),
      if (!forParent && checks.isNotEmpty) _LessonChecksCard(checks: checks, onLessonCheck: onLessonCheck),
      if (recent.isNotEmpty)
        SectionCard(
          icon: Icons.grading_rounded,
          tone: Tone.good,
          title: 'Recent work and marks',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: _AssessmentList(items: recent, onTap: onOpenHomework, max: 15),
        ),
      if (subjects.isNotEmpty) _SubjectsCard(subjects: subjects, title: forParent ? 'Subjects' : 'My subjects'),
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
