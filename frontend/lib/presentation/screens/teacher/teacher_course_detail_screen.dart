import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/student_performance.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Teacher Course Detail Screen - Shows course content and students
class TeacherCourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const TeacherCourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<TeacherCourseDetailScreen> createState() => _TeacherCourseDetailScreenState();
}

class _TeacherCourseDetailScreenState extends ConsumerState<TeacherCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final TeacherService _teacherService = TeacherService();
  final LiveSessionService _liveSessionService = LiveSessionService();
  late TabController _tabController;

  bool _isLoading = true;
  CourseContent? _courseContent;
  List<StudentPerformance> _students = [];
  List<LiveSession> _sessions = [];
  String? _errorMessage;

  int _studentsPage = 1;
  int _studentsTotalPages = 1;
  String? _studentSearchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourseData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _teacherService.getCourseContent(widget.courseId),
        _teacherService.getCourseStudents(widget.courseId, page: _studentsPage),
        _liveSessionService.getTeacherSessions(status: 'scheduled'),
      ]);

      final courseContent = futures[0] as CourseContent;
      final studentsResponse = futures[1] as CourseStudentsResponse;
      final sessionsResponse = futures[2] as LiveSessionsResponse;

      // Filter sessions for this course
      final courseSessions = sessionsResponse.sessions
          .where((s) => s.courseId == widget.courseId)
          .toList();

      setState(() {
        _courseContent = courseContent;
        _students = studentsResponse.students;
        _studentsTotalPages = studentsResponse.totalPages;
        _sessions = courseSessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading course data: $e';
        _isLoading = false;
      });
    }
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

  Future<void> _loadStudents({bool reset = false}) async {
    if (reset) {
      setState(() => _studentsPage = 1);
    }

    try {
      final response = await _teacherService.getCourseStudents(
        widget.courseId,
        page: _studentsPage,
        search: _studentSearchQuery,
      );

      setState(() {
        _students = response.students;
        _studentsTotalPages = response.totalPages;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

  void _navigateToStudentDetail(String studentId) {
    context.push('/teacher/courses/${widget.courseId}/students/$studentId');
  }

  void _scheduleSession([String? sectionId, String? lessonId]) {
    context.push('/teacher/sessions/create', extra: {
      'courseId': widget.courseId,
      'sectionId': sectionId,
      'lessonId': lessonId,
    });
  }

  void _createSection() {
    context.push('/teacher/courses/${widget.courseId}/create-section');
  }

  void _createLesson(String sectionId) {
    context.push('/teacher/courses/${widget.courseId}/sections/$sectionId/create-lesson');
  }

  Future<void> _joinSession(LiveSession session) async {
    try {
      final response = await _liveSessionService.joinSession(session.id);
      // Open BBB meeting URL
      if (mounted) {
        // Navigate to webview or external browser
        _showJoinDialog(response.joinUrl, session.title);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining session: $e')),
      );
    }
  }

  void _showJoinDialog(String joinUrl, String sessionTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join $sessionTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Click below to join the BigBlueButton meeting:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Launch URL
                Navigator.pop(context);
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _courseContent?.course.title ?? 'Course Detail',
                  style: const TextStyle(color: Colors.white),
                ),
                background: _courseContent?.course.thumbnail != null
                    ? NetworkImageWidget(
                        imageUrl: _courseContent!.course.thumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: AppTheme.primaryGreen,
                        child: const Icon(Icons.school, size: 64, color: Colors.white54),
                      ),
              ),
              actions: [
                // Teachers reach their course community from here — these
                // screens sit outside MainLayout, so there is no sidebar.
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  tooltip: 'Build lessons from a book with AI',
                  onPressed: () => context.push('/teacher/courses/${widget.courseId}/ai-builder').then((_) => _loadCourseData()),
                ),
                IconButton(
                  icon: const Icon(Icons.groups_rounded, color: Colors.white),
                  tooltip: 'Course community',
                  onPressed: () => context.push('/community/${widget.courseId}'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadCourseData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _handleLogout,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryGreen,
                  tabs: const [
                    Tab(icon: Icon(Icons.menu_book), text: 'Content'),
                    Tab(icon: Icon(Icons.people), text: 'Students'),
                    Tab(icon: Icon(Icons.schedule), text: 'Sessions'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentTab(),
                      _buildStudentsTab(),
                      _buildSessionsTab(),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scheduleSession(),
        icon: const Icon(Icons.add),
        label: const Text('Schedule Session'),
        backgroundColor: AppTheme.primaryGreen,
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
            onPressed: _loadCourseData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Content Tab
  Widget _buildContentTab() {
    return Column(
      children: [
        // Create Section Button
        if (_courseContent != null)
          Container(
            margin: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _createSection,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create New Section'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/teacher/courses/${widget.courseId}/ai-builder').then((_) => _loadCourseData()),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Build from a book with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Sections List
        Expanded(
          child: _courseContent == null || _courseContent!.sections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sections available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first section to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createSection,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Section'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _courseContent!.sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = _courseContent!.sections[sectionIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          // Section Header
                          ListTile(
                            title: Text(
                              section.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${section.lessons.length} lessons'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                              onPressed: () => _createLesson(section.id),
                              tooltip: 'Add Lesson',
                            ),
                          ),
                          
                          // Lessons
                          if (section.lessons.isNotEmpty)
                            ...section.lessons.map((lesson) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: lesson.hasRecording ? Colors.green : Colors.grey[300],
                                  child: Icon(
                                    lesson.hasRecording ? Icons.play_circle : Icons.play_arrow,
                                    color: lesson.hasRecording ? Colors.white : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                                title: Text(lesson.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${lesson.duration} min • ${lesson.lessonType}'),
                                    if (lesson.liveSessionCount > 0)
                                      Text(
                                        '${lesson.liveSessionCount} live session${lesson.liveSessionCount > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.schedule, color: AppTheme.primaryGreen),
                                      onPressed: () => _scheduleSession(section.id, lesson.id),
                                      tooltip: 'Schedule Live Session',
                                    ),
                                    if (lesson.hasRecording)
                                      IconButton(
                                        icon: const Icon(Icons.video_library, color: Colors.blue),
                                        onPressed: () {
                                          // View recordings
                                        },
                                        tooltip: 'View Recording',
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          
                          // Add Lesson Button for Empty Sections
                          if (section.lessons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: OutlinedButton.icon(
                                onPressed: () => _createLesson(section.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Lesson'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side: const BorderSide(color: AppTheme.primaryGreen),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Students Tab
  Widget _buildStudentsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _studentSearchQuery != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _studentSearchQuery = null);
                        _loadStudents(reset: true);
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (value) {
              setState(() => _studentSearchQuery = value.trim());
              _loadStudents(reset: true);
            },
          ),
        ),

        // Students list
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('No students enrolled'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return _StudentCard(
                      student: student,
                      onTap: () => _navigateToStudentDetail(student.student.id),
                    );
                  },
                ),
        ),

        // Pagination
        if (_studentsTotalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _studentsPage > 1
                      ? () {
                          setState(() => _studentsPage--);
                          _loadStudents();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $_studentsPage of $_studentsTotalPages'),
                IconButton(
                  onPressed: _studentsPage < _studentsTotalPages
                      ? () {
                          setState(() => _studentsPage++);
                          _loadStudents();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Sessions Tab
  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No upcoming sessions',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _scheduleSession(),
              icon: const Icon(Icons.add),
              label: const Text('Schedule First Session'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _SessionCard(
          session: session,
          onJoin: () => _joinSession(session),
          onCancel: () async {
            try {
              await _liveSessionService.cancelSession(session.id);
              _loadCourseData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session cancelled')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        );
      },
    );
  }
}

/// Student Card Widget
class _StudentCard extends StatelessWidget {
  final StudentPerformance student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Text(
            student.student.fullName.isNotEmpty
                ? student.student.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(student.student.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.student.email ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.completionStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.progressStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getStatusColor(student.completionStatus),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${student.progress}%',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

/// Session Card Widget
class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  const _SessionCard({
    required this.session,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.scheduledAt.isAfter(DateTime.now());
    final canJoin = isUpcoming || session.status == 'live';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUpcoming ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.status.toUpperCase(),
                    style: TextStyle(
                      color: isUpcoming ? Colors.orange : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (canJoin)
                  ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  )
                else if (isUpcoming)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (session.description != null) ...[
              const SizedBox(height: 4),
              Text(
                session.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(session.scheduledAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.duration} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
