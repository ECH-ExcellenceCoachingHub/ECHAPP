import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/teacher_access_provider.dart';
import 'package:excellencecoachinghub/services/api/teacher_access_service.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/widgets/eexams_section.dart';

/// Teacher home: what is happening today, my courses (with their teacher's
/// guides), and the teaching tools grouped by what the teacher wants to do.
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  final TeacherService _teacherService = TeacherService();
  final LiveSessionService _liveSessionService = LiveSessionService();

  bool _isLoading = true;
  TeacherDashboardStats? _stats;
  List<TeacherCourse> _courses = [];
  List<LiveSession> _upcoming = [];
  List<LiveSession> _startNow = [];
  String? _errorMessage;

  /// At least one course ECH assigned (with students, live classes, community).
  bool get _hasStaffCourses => _courses.any((c) => !c.isGuideOnly);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _teacherService.getDashboardStats(),
        _teacherService.getAssignedCourses(limit: 50),
      ]);
      final stats = results[0] as TeacherDashboardStats;
      final courses = (results[1] as TeacherCoursesResponse).courses;

      var upcoming = <LiveSession>[];
      var startNow = <LiveSession>[];
      if (courses.any((c) => !c.isGuideOnly)) {
        try {
          final r = await _liveSessionService.getTeacherSessions(limit: 10);
          final now = DateTime.now();
          upcoming = r.sessions
              .where((s) => s.status == 'live' || (s.status == 'scheduled' && s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)))))
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          startNow = r.sessions
              .where((s) => s.status == 'live' || (s.status == 'scheduled' && s.scheduledAt.isBefore(now.add(const Duration(minutes: 5))) && !s.isEnded))
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          await PushNotificationService.scheduleLiveSessionNotifications(r.sessions, isTeacher: true);
        } catch (e) {
          debugPrint('Failed to load sessions: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _courses = courses;
        _upcoming = upcoming.where((s) => !startNow.contains(s)).toList();
        _startNow = startNow;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard loading error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e is TeacherAccessException ? e.message : 'Could not load your dashboard. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(teacherAccessProvider);
    await _loadDashboardData();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        final isDesktop = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
        context.go(isDesktop ? '/email-auth-option' : '/auth-selection');
      }
    }
  }

  void _openCommunity() {
    final staff = _courses.where((c) => !c.isGuideOnly).toList();
    context.push(staff.length == 1 ? '/community/${staff.first.course.id}' : '/community');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final access = ref.watch(teacherAccessProvider).valueOrNull;
    final firstName = (user?.fullName ?? '').split(' ').first;
    final profile = access?.profile;
    final subtitle = [
      if ((profile?.school ?? '').isNotEmpty) profile!.school,
      if ((profile?.levels ?? const []).isNotEmpty) profile!.levels.join(', '),
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 150,
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              title: const Text('Teacher Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              actions: [
                IconButton(tooltip: "Teacher's guides", icon: const Icon(Icons.auto_stories), onPressed: () => context.push('/teacher/guides')),
                PopupMenuButton<String>(
                  tooltip: 'Account',
                  icon: const Icon(Icons.account_circle),
                  onSelected: (v) {
                    if (v == 'profile') context.push('/teacher/onboarding');
                    if (v == 'refresh') _refreshAll();
                    if (v == 'logout') _handleLogout();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.badge_outlined), title: Text('My teacher profile'))),
                    PopupMenuItem(value: 'refresh', child: ListTile(leading: Icon(Icons.refresh), title: Text('Refresh'))),
                    PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Log out'))),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF047857), Color(0xFF10B981)]),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  alignment: Alignment.bottomLeft,
                  child: SafeArea(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        firstName.isEmpty ? 'Welcome back' : 'Welcome back, $firstName',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              SliverFillRemaining(child: _ErrorView(message: _errorMessage!, onRetry: _loadDashboardData))
            else
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if ((access?.pendingRequests ?? 0) > 0)
                          _Banner(
                            color: const Color(0xFFF59E0B),
                            icon: Icons.hourglass_top_rounded,
                            text: '${access!.pendingRequests} course request(s) waiting for admin approval.',
                            actionLabel: 'View',
                            onAction: () => context.push('/teacher/guides'),
                          ),
                        if (_startNow.isNotEmpty) ...[
                          const _SectionTitle('Start now', icon: Icons.notifications_active, color: Colors.red),
                          _SessionStrip(sessions: _startNow, urgent: true),
                          const SizedBox(height: 20),
                        ],
                        if (_stats != null) _StatsRow(stats: _stats!.overview, courses: _courses, showStudents: _hasStaffCourses),
                        const SizedBox(height: 16),
                        const _AssessmentsCard(),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          'My courses',
                          icon: Icons.school,
                          trailing: TextButton.icon(
                            onPressed: () => context.push('/teacher/guides'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Get more courses'),
                          ),
                        ),
                        _CoursesGrid(courses: _courses),
                        const SizedBox(height: 28),
                        _ToolGroups(
                          hasStaffCourses: _hasStaffCourses,
                          onCommunity: _openCommunity,
                        ),
                        if (_hasStaffCourses) ...[
                          const SizedBox(height: 28),
                          _SectionTitle(
                            'Upcoming live classes',
                            icon: Icons.event,
                            trailing: TextButton(onPressed: () => context.push('/teacher/sessions'), child: const Text('See all')),
                          ),
                          if (_upcoming.isEmpty)
                            _EmptyCard(
                              icon: Icons.event_available,
                              text: 'No live class scheduled.',
                              actionLabel: 'Schedule a class',
                              onAction: () => context.push('/teacher/sessions/create', extra: {'courseId': null}),
                            )
                          else
                            _SessionStrip(sessions: _upcoming),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Pieces ──────────────────────────────────────────────────────────────────

/// Opens eexams already signed in, on the page where the teacher creates
/// exams, homework and quizzes and assigns them to students.
class _AssessmentsCard extends StatefulWidget {
  const _AssessmentsCard();
  @override
  State<_AssessmentsCard> createState() => _AssessmentsCardState();
}

class _AssessmentsCardState extends State<_AssessmentsCard> {
  String? _opening;

  Future<void> _open(String section) async {
    if (_opening != null) return;
    setState(() => _opening = section);
    await openEexams(context, redirect: '/teacher?section=$section');
    if (mounted) setState(() => _opening = null);
  }

  Widget _busy() => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D406C), Color(0xFF0CBD73)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 700;
        final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Row(children: [
            Icon(Icons.assignment_turned_in, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text('Exams, homework & quizzes',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ]),
          SizedBox(height: 4),
          Text(
            'Create them on eexams (you are signed in automatically), then assign them to your students: '
            'Publish → Private / Invite.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ]);
        final buttons = Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D406C)),
            onPressed: () => _open('createExam'),
            icon: _opening == 'createExam'
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_task, size: 18),
            label: const Text('Create & assign'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
            onPressed: () => _open('exams'),
            icon: _opening == 'exams' ? _busy() : const Icon(Icons.list_alt, size: 18),
            label: const Text('My assessments'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
            onPressed: () => _open('results'),
            icon: _opening == 'results' ? _busy() : const Icon(Icons.bar_chart, size: 18),
            label: const Text('Results'),
          ),
        ]);
        return wide
            ? Row(children: [Expanded(child: text), const SizedBox(width: 16), buttons])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [text, const SizedBox(height: 12), buttons]);
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ]),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _Banner({required this.color, required this.icon, required this.text, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.35))),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final Widget? trailing;
  const _SectionTitle(this.text, {required this.icon, this.color, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 22, color: color ?? AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyCard({required this.icon, required this.text, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(icon, size: 32, color: Theme.of(context).hintColor),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
          if (actionLabel != null) FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ]),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TeacherOverview stats;
  final List<TeacherCourse> courses;
  final bool showStudents;
  const _StatsRow({required this.stats, required this.courses, required this.showStudents});

  @override
  Widget build(BuildContext context) {
    final guides = courses.where((c) => c.guideAvailable).length;
    final tiles = [
      _StatTile(icon: Icons.school, label: 'My courses', value: '${courses.length}', color: Colors.blue),
      showStudents
          ? _StatTile(icon: Icons.people, label: 'Students', value: '${stats.totalStudents}', color: Colors.green)
          : _StatTile(icon: Icons.auto_stories, label: "Teacher's guides", value: '$guides', color: Colors.green),
      _StatTile(icon: Icons.video_call, label: 'Upcoming classes', value: '${stats.upcomingSessions}', color: Colors.orange),
      _StatTile(icon: Icons.timer, label: 'Teaching hours', value: stats.totalTeachingHours.toStringAsFixed(1), color: Colors.purple),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 4 : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ]),
        ),
      ]),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  final List<TeacherCourse> courses;
  const _CoursesGrid({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return _EmptyCard(
        icon: Icons.menu_book_outlined,
        text: "You don't have a course yet. Choose the course(s) you teach to get their teacher's guides.",
        actionLabel: 'Choose a course',
        onAction: () => context.push('/teacher/guides'),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1000 ? 3 : c.maxWidth > 640 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [for (final tc in courses) SizedBox(width: w, child: _CourseCard(course: tc))]);
    });
  }
}

class _CourseCard extends StatelessWidget {
  final TeacherCourse course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final c = course.course;
    final hint = Theme.of(context).hintColor;
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/teacher/courses/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: (c.thumbnail ?? '').isNotEmpty
                      ? NetworkImageWidget(imageUrl: c.thumbnail!, width: 64, height: 64, fit: BoxFit.cover)
                      : Container(color: AppTheme.primaryGreen.withOpacity(0.12), child: Icon(Icons.school, color: AppTheme.primaryGreen)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _Tag(course.isGuideOnly ? "Teacher's guide" : 'Assigned by ECH', course.isGuideOnly ? const Color(0xFF3B82F6) : AppTheme.primaryGreen),
                    for (final l in course.guideClassLevels.take(3)) _Tag(l, Colors.blueGrey),
                  ]),
                  if (!course.isGuideOnly) ...[
                    const SizedBox(height: 4),
                    Text('${course.enrollmentCount} students · ${course.upcomingSessions} upcoming classes', style: TextStyle(fontSize: 12, color: hint)),
                  ],
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (course.guideAvailable)
                FilledButton.icon(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => context.push('/teacher/guides/${c.id}'),
                  icon: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('Guide'),
                )
              else if (course.isGuideOnly)
                Text('Guide coming soon', style: TextStyle(fontSize: 12, color: hint)),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () => context.push('/teacher/courses/${c.id}'),
                icon: Icon(course.isGuideOnly ? Icons.menu_book : Icons.people, size: 16),
                label: Text(course.isGuideOnly ? 'Lessons' : 'Lessons & students'),
              ),
              if (!course.isGuideOnly) ...[
                IconButton(
                  tooltip: 'Schedule a live class',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.push('/teacher/sessions/create', extra: {'courseId': c.id}),
                  icon: const Icon(Icons.event, color: Color(0xFF10B981)),
                ),
                IconButton(
                  tooltip: 'Course community',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.push('/community/${c.id}'),
                  icon: const Icon(Icons.groups_rounded, color: Color(0xFF7C4DFF)),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

class _Tool {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _Tool(this.icon, this.label, this.subtitle, this.color, this.onTap);
}

/// Tools grouped by what the teacher wants to do.
class _ToolGroups extends StatelessWidget {
  final bool hasStaffCourses;
  final VoidCallback onCommunity;
  const _ToolGroups({required this.hasStaffCourses, required this.onCommunity});

  @override
  Widget build(BuildContext context) {
    final groups = <(String, IconData, List<_Tool>)>[
      ('Plan', Icons.edit_calendar, [
        _Tool(Icons.auto_stories, "Teacher's guides", 'How to teach each lesson', const Color(0xFF2563EB), () => context.push('/teacher/guides')),
        _Tool(Icons.menu_book, 'Lesson planner', 'REB/CBC lesson plans', const Color(0xFF10B981), () => context.push('/teacher/lesson-planner')),
        _Tool(Icons.calendar_month, 'Scheme of work', 'Whole-term plan', const Color(0xFF0891B2), () => context.push('/teacher/scheme-of-work')),
      ]),
      ('Create', Icons.auto_awesome, [
        _Tool(Icons.slideshow, 'Slides', 'PowerPoint decks', const Color(0xFFC43E1C), () => context.push('/teacher/slides')),
        _Tool(Icons.fact_check, 'Exercises', 'Question sheets + answer key', const Color(0xFF7C3AED), () => context.push('/teacher/exercises')),
        _Tool(Icons.assignment, 'Exams', 'Create, saved on eexams', const Color(0xFF0D406C), () => context.push('/teacher/exams')),
      ]),
      if (hasStaffCourses)
        ('Teach', Icons.co_present, [
          _Tool(Icons.video_call, 'Live classes', 'Schedule and start', const Color(0xFFEA580C), () => context.push('/teacher/sessions')),
          _Tool(Icons.groups_rounded, 'Community', 'Discuss with your students', const Color(0xFF7C4DFF), onCommunity),
        ]),
      ('Students', Icons.people, [
        _Tool(Icons.person_add, 'Add Students', 'Add students from your school', Colors.green, () => context.push('/teacher/add-students')),
      ]),
      ('Results', Icons.insights, [
        _Tool(Icons.add_task, 'Create & assign', 'Exams, homework, quizzes on eexams', const Color(0xFF0CBD73), () => openEexams(context, redirect: '/teacher?section=createExam')),
        _Tool(Icons.bar_chart, 'Results', "Your students' marks on eexams", const Color(0xFF0D406C), () => openEexams(context, redirect: '/teacher?section=results')),
      ]),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _SectionTitle('Teaching tools', icon: Icons.handyman),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 1000 ? 4 : c.maxWidth > 640 ? 2 : 1;
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final g in groups)
            SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Icon(g.$2, size: 18, color: Theme.of(context).hintColor),
                    const SizedBox(width: 6),
                    Text(g.$1.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor)),
                  ]),
                  const SizedBox(height: 8),
                  for (final t in g.$3) _ToolRow(tool: t),
                ]),
              ),
            ),
        ]);
      }),
    ]);
  }
}

class _ToolRow extends StatelessWidget {
  final _Tool tool;
  const _ToolRow({required this.tool});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: tool.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: tool.color.withOpacity(isDark ? 0.22 : 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(tool.icon, color: tool.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tool.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(tool.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
            ]),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
        ]),
      ),
    );
  }
}

class _SessionStrip extends StatelessWidget {
  final List<LiveSession> sessions;
  final bool urgent;
  const _SessionStrip({required this.sessions, this.urgent = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _SessionCard(session: sessions[i], urgent: urgent),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final bool urgent;
  const _SessionCard({required this.session, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    final live = session.status == 'live';
    final color = urgent || live ? Colors.red : Colors.orange;
    return SizedBox(
      width: 270,
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: urgent ? BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5) : BorderSide.none),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/teacher/sessions'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(live ? 'LIVE' : (urgent ? 'START NOW' : 'SCHEDULED'), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Icon(urgent || live ? Icons.play_circle : Icons.schedule, color: color, size: 20),
              ]),
              const SizedBox(height: 8),
              Text(session.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                [
                  if (session.course != null && (session.course!['title'] ?? '').toString().isNotEmpty) session.course!['title'].toString(),
                  DateFormat('EEE d MMM • HH:mm').format(session.scheduledAt.toLocal()),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
