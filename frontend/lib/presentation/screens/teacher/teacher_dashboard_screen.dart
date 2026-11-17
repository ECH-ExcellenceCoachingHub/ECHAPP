import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/widgets/eexams_section.dart';

/// Teacher Dashboard Screen - Modern dashboard for instructors with teacher tools
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
  List<LiveSession> _recentSessions = [];
  List<LiveSession> _readyToStartSessions = [];
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;

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
      final statsAndCourses = await Future.wait([
        _teacherService.getDashboardStats(),
        _teacherService.getAssignedCourses(page: _currentPage),
      ]);

      final stats = statsAndCourses[0] as TeacherDashboardStats;
      final coursesResponse = statsAndCourses[1] as TeacherCoursesResponse;

      List<LiveSession> sessions = [];
      List<LiveSession> readyToStart = [];
      try {
        final sessionsResponse = await _liveSessionService.getTeacherSessions(
          limit: 10,
        );
        final now = DateTime.now();

        sessions = sessionsResponse.sessions.where((session) {
          return session.status == 'scheduled' &&
                  session.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5))) ||
                 session.status == 'live';
        }).toList();
        sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        readyToStart = sessionsResponse.sessions.where((session) {
          return (session.status == 'scheduled' &&
                  session.scheduledAt.isBefore(now.add(const Duration(minutes: 5))) &&
                  !session.isEnded) ||
                 session.status == 'live';
        }).toList();
        readyToStart.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        await PushNotificationService.scheduleLiveSessionNotifications(
          sessionsResponse.sessions,
          isTeacher: true,
        );
      } catch (sessionError) {
        debugPrint('Failed to load sessions: $sessionError');
      }

      setState(() {
        _stats = stats;
        _courses = coursesResponse.courses;
        _totalPages = coursesResponse.totalPages;
        _recentSessions = sessions;
        _readyToStartSessions = readyToStart;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard loading error: $e');
      setState(() {
        _errorMessage = 'Error loading dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSessions() async {
    try {
      final sessionsResponse = await _liveSessionService.getTeacherSessions(
        limit: 5,
      );
      final now = DateTime.now();
      final sessions = sessionsResponse.sessions.where((session) {
        return session.status == 'scheduled' &&
                session.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5))) ||
               session.status == 'live';
      }).toList();
      sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final readyToStart = sessionsResponse.sessions.where((session) {
        return (session.status == 'scheduled' &&
                session.scheduledAt.isBefore(now.add(const Duration(minutes: 5))) &&
                !session.isEnded) ||
               session.status == 'live';
      }).toList();
      readyToStart.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      setState(() {
        _recentSessions = sessions;
        _readyToStartSessions = readyToStart;
      });
    } catch (e) {
      debugPrint('Failed to refresh sessions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh sessions: $e')),
        );
      }
    }
  }

  void _navigateToCourse(String courseId) {
    context.push('/teacher/courses/$courseId');
  }

  void _navigateToScheduleSession([String? courseId]) {
    context.push('/teacher/sessions/create', extra: {'courseId': courseId});
  }

  void _navigateToSessions() {
    context.push('/teacher/sessions');
  }

  void _navigateToCommunity() {
    if (_courses.length == 1) {
      context.push('/community/${_courses.first.course.id}');
    } else {
      context.push('/community');
    }
  }

  void _openCourseCommunity(String courseId) {
    context.push('/community/$courseId');
  }

  void _navigateToLessonPlanner() {
    context.push('/teacher/lesson-planner');
  }

  void _navigateToCourseGuider() {
    context.push('/teacher/course-guider');
  }

  void _navigateToSliderBuilder() {
    context.push('/teacher/slides');
  }

  /// Lays tool tiles out two per row.
  List<Widget> _toolRows(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(Row(children: [
        Expanded(child: tiles[i]),
        const SizedBox(width: 12),
        Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
      ]));
    }
    return rows;
  }

  void _navigateToCreateCourse() {
    context.push('/admin/courses/create');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
                                        defaultTargetPlatform == TargetPlatform.linux ||
                                        defaultTargetPlatform == TargetPlatform.macOS);
        context.go(isDesktop ? '/email-auth-option' : '/auth-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;
    final accent = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: accent,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Welcome, ${user?.fullName?.split(' ').first ?? 'Teacher'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent,
                                accent.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher Dashboard',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadDashboardData,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),

                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_stats != null) ...[
                                  _buildStatsCards(isDark: isDark, cardColor: cardColor, textPrimary: textPrimary),
                                  const SizedBox(height: 24),
                                ],

                                _buildTeacherToolsSection(
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),
                                const SizedBox(height: 24),

                                if (_readyToStartSessions.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    'Ready to Start',
                                    onSeeAll: _navigateToSessions,
                                    onRefresh: _refreshSessions,
                                    textColor: Colors.red,
                                    showWarning: true,
                                  ),
                                  _buildReadyToStartSessionsList(
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                _buildSectionHeader(
                                  'Upcoming Sessions',
                                  onSeeAll: _navigateToSessions,
                                  onRefresh: _refreshSessions,
                                  textColor: textPrimary,
                                ),
                                if (_recentSessions.isNotEmpty) ...[
                                  _buildRecentSessionsList(
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ] else ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Card(
                                      color: cardColor,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.schedule_outlined, size: 48, color: textSecondary),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No upcoming sessions',
                                                style: TextStyle(color: textSecondary),
                                              ),
                                              const SizedBox(height: 8),
                                              TextButton.icon(
                                                onPressed: _refreshSessions,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Refresh'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),

                                _buildSectionHeader(
                                  'My Courses',
                                  onSeeAll: () => context.push('/teacher/courses'),
                                  textColor: textPrimary,
                                ),
                                _buildCoursesList(
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards({
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
  }) {
    final stats = _stats!.overview;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final crossAxisCount = isDesktop ? 4 : 2;
    final childAspectRatio = isDesktop ? 1.5 : 1.4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isDesktop ? 16 : 12,
      mainAxisSpacing: isDesktop ? 16 : 12,
      childAspectRatio: childAspectRatio,
      children: [
        _StatCard(
          icon: Icons.school,
          title: 'My Courses',
          value: stats.totalCourses.toString(),
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.people,
          title: 'Total Students',
          value: stats.totalStudents.toString(),
          color: Colors.green,
        ),
        _StatCard(
          icon: Icons.video_call,
          title: 'Upcoming Sessions',
          value: stats.upcomingSessions.toString(),
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.timer,
          title: 'Teaching Hours',
          value: stats.totalTeachingHours.toStringAsFixed(1),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTeacherToolsSection({
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: const Color(0xFF10B981), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Teacher Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Teaching tools run on the eexams engine; exams are created here,
            // saved on eexams and managed there (see /teacher/exams).
            ..._toolRows([
              _ToolTile(
                icon: Icons.menu_book,
                label: 'Lesson Planner',
                subtitle: 'REB/CBC lesson plans',
                color: const Color(0xFF10B981),
                onTap: _navigateToLessonPlanner,
              ),
              _ToolTile(
                icon: Icons.slideshow,
                label: 'Slides',
                subtitle: 'PowerPoint decks',
                color: const Color(0xFFC43E1C),
                onTap: _navigateToSliderBuilder,
              ),
              _ToolTile(
                icon: Icons.fact_check,
                label: 'Exercises',
                subtitle: 'Question sheets + key',
                color: const Color(0xFF7C3AED),
                onTap: () => context.push('/teacher/exercises'),
              ),
              _ToolTile(
                icon: Icons.calendar_month,
                label: 'Scheme of Work',
                subtitle: 'Whole-term plan',
                color: const Color(0xFF0891B2),
                onTap: () => context.push('/teacher/scheme-of-work'),
              ),
              _ToolTile(
                icon: Icons.assignment,
                label: 'Create Exam',
                subtitle: 'Saved on eexams',
                color: const Color(0xFF0D406C),
                onTap: () => context.push('/teacher/exams'),
              ),
              _ToolTile(
                icon: Icons.open_in_new,
                label: 'eexams Dashboard',
                subtitle: 'Publish, results, students',
                color: const Color(0xFF0CBD73),
                onTap: () => openEexams(context, redirect: '/teacher'),
              ),
              _ToolTile(
                icon: Icons.add_circle,
                label: 'Create Course',
                subtitle: 'Create a new course',
                color: Colors.purple,
                onTap: _navigateToCreateCourse,
              ),
              _ToolTile(
                icon: Icons.school,
                label: 'Course Guider',
                subtitle: 'Guide your courses',
                color: Colors.blue,
                onTap: _navigateToCourseGuider,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll, VoidCallback? onRefresh, Color? textColor, bool showWarning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showWarning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Urgent',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (showWarning) const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSessionsList({required bool isDark, required Color cardColor, required Color textPrimary, required Color textSecondary}) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentSessions.length,
        itemBuilder: (context, index) {
          final session = _recentSessions[index];
          return _SessionCard(
            session: session,
            onTap: () => context.push('/teacher/sessions'),
            isDark: isDark,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        },
      ),
    );
  }

  Widget _buildReadyToStartSessionsList({required bool isDark, required Color cardColor, required Color textPrimary, required Color textSecondary}) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _readyToStartSessions.length,
        itemBuilder: (context, index) {
          final session = _readyToStartSessions[index];
          return _SessionCard(
            session: session,
            onTap: () => context.push('/teacher/sessions'),
            isDark: isDark,
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isUrgent: true,
          );
        },
      ),
    );
  }

  Widget _buildCoursesList({required bool isDark, required Color cardColor, required Color textPrimary, required Color textSecondary}) {
    if (_courses.isEmpty) {
      return Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 48, color: textSecondary),
                const SizedBox(height: 8),
                Text(
                  'No courses assigned yet',
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return _CourseCard(
          course: course,
          onTap: () => _navigateToCourse(course.course.id),
          onSchedule: () => _navigateToScheduleSession(course.course.id),
          onCommunity: () => _openCourseCommunity(course.course.id),
          isDark: isDark,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      },
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    return Card(
      elevation: 2,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tool Tile Widget for teacher tools
class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Session Card Widget
class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isUrgent;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.scheduledAt.isAfter(DateTime.now());
    final statusBgColor = isUrgent
        ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red[50])
        : (isUpcoming
            ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[50])
            : (isDark ? Colors.green.withOpacity(0.2) : Colors.green[50]));
    final statusColor = isUrgent ? Colors.red : (isUpcoming ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(right: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? BorderSide(color: Colors.red.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'START NOW',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    isUrgent ? Icons.play_circle : (isUpcoming ? Icons.schedule : Icons.play_circle),
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (session.course != null)
                Text(
                  session.course!['title'] ?? '',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(session.scheduledAt),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Course Card Widget
class _CourseCard extends StatelessWidget {
  final TeacherCourse course;
  final VoidCallback onTap;
  final VoidCallback onSchedule;
  final VoidCallback onCommunity;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onSchedule,
    required this.onCommunity,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: course.course.thumbnail != null
                    ? NetworkImageWidget(
                        imageUrl: course.course.thumbnail!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: isDark ? AppTheme.darkSurface : Colors.grey[300],
                        child: Icon(Icons.school, color: textSecondary),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.course.level} • ${course.enrollmentCount} students',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.people,
                          value: course.enrollmentCount.toString(),
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          icon: Icons.play_circle,
                          value: course.upcomingSessions.toString(),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.schedule, color: Color(0xFF10B981)),
                    onPressed: onSchedule,
                    tooltip: 'Schedule Session',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.groups_rounded, color: Color(0xFF7C4DFF)),
                    onPressed: onCommunity,
                    tooltip: 'Open course community',
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(Icons.chevron_right, color: textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
