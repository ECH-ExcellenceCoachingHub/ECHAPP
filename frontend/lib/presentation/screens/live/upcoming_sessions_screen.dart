import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class UpcomingSessionsScreen extends ConsumerStatefulWidget {
  const UpcomingSessionsScreen({super.key});

  @override
  ConsumerState<UpcomingSessionsScreen> createState() => _UpcomingSessionsScreenState();
}

class _UpcomingSessionsScreenState extends ConsumerState<UpcomingSessionsScreen> {
  final LiveSessionService _liveSessionService = LiveSessionService();
  List<LiveSession> _allSessions = [];
  Map<String, List<LiveSession>> _sessionsByCourse = {};
  Map<String, Course> _courses = {};
  String _selectedCourseId = 'all';
  bool _isLoading = true;
  String? _errorMessage;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _checkPermissions();
    _loadSessions();
  }

  void _checkUserRole() {
    final authState = ref.read(authProvider);
    _isTeacher = authState?.user?.role == 'instructor';
  }

  void _checkPermissions() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // For teachers, always allow access
    if (_isTeacher) return;
    
    // For students, check if they have any enrollment with live session access.
    // Access lives on the Enrollment (not the Course), and we only deny once
    // enrollments have actually loaded — an empty list while loading, or for a
    // student with no courses yet, is not a "no access" decision.
    if (user != null) {
      final enrollments =
          ref.read(userEnrollmentsProvider).valueOrNull ?? const <Enrollment>[];
      final hasAccess = enrollments.isEmpty ||
          enrollments.any((enrollment) => enrollment.canAccessLiveSessions);

      if (!hasAccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.noPermissionToAccessLiveSessions),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            context.pop();
          }
        });
      }
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isTeacher) {
        // Load teacher's sessions
        final response = await _liveSessionService.getTeacherSessions(
          status: 'scheduled',
          page: 1,
          limit: 100,
        );
        
        final now = DateTime.now();
        _allSessions = response.sessions.where((s) {
          return !s.isEnded &&
              !s.isCancelled &&
              s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
        }).toList();
        
        // Don't group by course for teachers - show all sessions
        _sessionsByCourse = {};
        _courses = {};
      } else {
        // Load student's enrolled courses sessions
        // Await the provider so a cold open (straight from the dashboard
        // tile) doesn't see an empty list while enrollments are still loading.
        List<Enrollment> enrollments;
        try {
          enrollments = await ref.read(userEnrollmentsProvider.future);
        } catch (_) {
          enrollments = const <Enrollment>[];
        }

        if (enrollments.isEmpty) {
          setState(() {
            _isLoading = false;
            _allSessions = [];
            _sessionsByCourse = {};
            _courses = {};
          });
          return;
        }

        _allSessions = [];
        _sessionsByCourse = {};
        _courses = {};

        for (final enrollment in enrollments) {
          // Skip if user doesn't have live session access for this enrollment
          if (!enrollment.canAccessLiveSessions) continue;
          
          final course = enrollment.course;
          if (course == null) continue;
          
          _courses[course.id] = course;

          try {
            final response = await _liveSessionService.getCourseSessions(
              course.id,
              status: 'scheduled',
              limit: 20,
            );
            final now = DateTime.now();
            final upcoming = response.sessions.where((s) {
              return !s.isEnded &&
                  !s.isCancelled &&
                  s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
            }).toList();

            if (upcoming.isNotEmpty) {
              _sessionsByCourse[course.id] = upcoming;
              _allSessions.addAll(upcoming);
            }
          } catch (e) {
            debugPrint('Error loading sessions for course ${course.id}: $e');
          }
        }
      }

      // Sort all sessions by scheduled time
      _allSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<LiveSession> get _filteredSessions {
    if (_selectedCourseId == 'all') {
      return _allSessions;
    }
    return _sessionsByCourse[_selectedCourseId] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Upcoming Sessions'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _allSessions.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        // Course filter
                        if (_courses.length > 1)
                          _buildCourseFilter(isMobile, isDark),
                        // Sessions list
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 12 : 20),
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSessionCard(_filteredSessions[index], isDark),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildCourseFilter(bool isMobile, bool isDark) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All Courses', 'all', isDark),
            ..._courses.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _filterChip(entry.value.title, entry.key, isDark),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String courseId, bool isDark) {
    final isSelected = _selectedCourseId == courseId;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCourseId = courseId;
        });
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildSessionCard(LiveSession session, bool isDark) {
    final course = _courses[session.courseId];
    final now = DateTime.now();
    final isLive = session.isLive && !session.isEnded;
    final hasStarted = session.scheduledAt.isBefore(now) || session.scheduledAt.isAtSameMomentAs(now);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLive 
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.video_call,
                    color: isLive ? Colors.red : AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      if (course != null)
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  session.timeProgressInfo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.duration} min',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: AppTheme.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Upcoming Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for scheduled live sessions',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSessions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
