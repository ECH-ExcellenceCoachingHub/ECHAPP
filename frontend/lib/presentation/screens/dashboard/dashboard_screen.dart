import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX #11: Added for Clipboard.setData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/screens/community/session_card.dart';
import 'package:excellencecoachinghub/presentation/providers/community_provider.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/widgets/downloads_section.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/live_session_countdown.dart';
import 'package:excellencecoachinghub/widgets/enhanced_course_navigation.dart';
import 'package:excellencecoachinghub/widgets/support_floating_button.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Device binding policy widget for dashboard
class _DashboardDeviceBindingPolicy extends StatelessWidget {
  const _DashboardDeviceBindingPolicy();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20, vertical: isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryDark.withOpacity(0.18)
            : AppTheme.primarySoft.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withOpacity(0.18)
              : AppTheme.primary.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
            size: isMobile ? 18 : 22,
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Text(
              l10n?.accountBoundToDevice ?? 'Account secured to this device. Contact support to change.',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary.withOpacity(0.84)
                    : AppTheme.primaryDark,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Stat item widget for statistics dialog
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for a subtle woven dashboard edge.
class _CurvedEdgePainter extends CustomPainter {
  final bool isDark;

  _CurvedEdgePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = (isDark ? AppTheme.primaryLight : AppTheme.primary)
          .withOpacity(isDark ? 0.18 : 0.16)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.2,
    );

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);

    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.18)
      ..strokeWidth = 2;

    for (var x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _hasCheckedRole = false;
  bool _isRefreshing = false;
  Future<List<LiveSession>>? _upcomingSessionsFuture;
  List<String> _lastEnrolledCourseIds = [];
  Timer? _autoRefreshTimer;
  Timer? _phraseTimer;
  AnimationController? _animationController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _showCategoryDropdown = false;
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  // Gamification
  int _phraseIndex = 0;
  List<String> get _motivationalPhrases => [
    l10n?.motivationalQuote1 ?? 'Build skills for your next opportunity.',
    l10n?.motivationalQuote2 ?? 'Every lesson brings you closer to your goal.',
    l10n?.motivationalQuote3 ?? 'Keep going — consistency beats talent.',
    l10n?.motivationalQuote4 ?? 'Champions learn daily. You are one.',
    l10n?.motivationalQuote5 ?? 'Small steps, massive results.',
    l10n?.motivationalQuote6 ?? 'Your future self is watching. Make it count.',
    l10n?.motivationalQuote7 ?? 'Top performers never stop learning.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotificationService.clearNotifications();

    _initConnectivityListener();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startAutoRefresh();
    _animationController?.forward();

    // Rotate motivational phrase every 5 seconds
    _phraseTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _phraseIndex =
            (_phraseIndex + 1) % _motivationalPhrases.length);
      }
    });

    // Show welcome-back popup after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowWelcomePopup();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh dashboard when app is resumed (user returns from background)
    if (state == AppLifecycleState.resumed) {
      debugPrint('DashboardScreen: App resumed, refreshing data...');
      _refreshDashboard();
    }
  }

  Future<void> _maybeShowWelcomePopup() async {
    if (!mounted) return;
    final storage = StorageManager();
    final lastSeen = await storage.getItem('dashboard_last_seen');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await storage.saveItem('dashboard_last_seen', today);

    if (!mounted) return;

    // First ever open — show "welcome" toast
    if (lastSeen == null) {
      _showDashboardToast(
        icon: '👋',
        title: l10n?.welcomeToExcellenceHub ?? 'Welcome to Excellence Hub!',
        message: l10n?.startFirstLesson ?? 'Start your first lesson today and earn XP.',
        color: AppTheme.primary,
      );
      return;
    }

    // Returning user on a new day — show motivational toast
    if (lastSeen != today) {
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? l10n?.goodMorning ?? 'Good morning'
          : hour < 17
              ? l10n?.goodAfternoon ?? 'Good afternoon'
              : l10n?.goodEvening ?? 'Good evening';
      _showDashboardToast(
        icon: '🔥',
        title: '$greeting! ${l10n?.keepStreakAlive ?? 'Keep the streak alive.'}',
        message: l10n?.consistencyIsSuperpower ?? 'Your consistency is your superpower.',
        color: const Color(0xFFFF7043),
      );
    }
  }

  void _showDashboardToast({
    required String icon,
    required String title,
    required String message,
    required Color color,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'toast',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => _DashboardToast(
        icon: icon,
        title: title,
        message: message,
        color: color,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _checkProgressMilestone(List<Enrollment> enrollments) {
    if (enrollments.isEmpty) return;
    final avg = enrollments.fold(0.0, (s, e) => s + e.progress) /
        enrollments.length;
    final milestones = [25, 50, 75, 100];
    for (final m in milestones) {
      if (avg >= m) {
        _maybeShowMilestone(m, avg);
        return;
      }
    }
  }

  Future<void> _maybeShowMilestone(int milestone, double progress) async {
    if (!mounted) return;
    final storage = StorageManager();
    final key = 'milestone_shown_$milestone';
    final already = await storage.getItem(key);
    if (already == 'true') return;
    await storage.saveItem(key, 'true');
    if (!mounted) return;

    final messages = {
      25: ('🚀', l10n?.quarterWay ?? 'Quarter way there!', l10n?.momentumBuilding ?? 'You have hit 25% — momentum is building!'),
      50: ('⚡', l10n?.halfwayChampion ?? 'Halfway champion!', l10n?.finishLineReal ?? 'You are at 50% — the finish line is real.'),
      75: ('🏅', l10n?.almostThere ?? 'Almost there!', l10n?.nearlyUnstoppable ?? '75% done — you are nearly unstoppable.'),
      100: ('🎓', l10n?.courseCompleted ?? 'Course completed!', l10n?.incredibleEffort ?? 'You finished a course. Incredible effort!'),
    };
    final data = messages[milestone];
    if (data == null) return;

    _showDashboardToast(
      icon: data.$1,
      title: data.$2,
      message: data.$3,
      color: milestone == 100
          ? const Color(0xFFFFD700)
          : milestone >= 75
              ? AppTheme.accent
              : AppTheme.primary,
    );
  }

  void _startAutoRefresh() {
    // Check payment status every 60 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _refreshPaymentStatus();
    });
    // Session refresh timer removed to avoid continuous reloading
  }

  void _refreshPaymentStatus() {
    // Refresh user payments to check for status updates
    ref.read(paymentProvider.notifier).loadUserPayments();
    // Also refresh enrolled courses to update UI if payment was approved
    ref.invalidate(enrolledCoursesProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _phraseTimer?.cancel();
    _animationController?.dispose();
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initConnectivityListener() async {
    // Check initial connectivity state
    final initialResults = await Connectivity().checkConnectivity();
    final isInitiallyOffline = initialResults.isEmpty || initialResults.contains(ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOffline = isInitiallyOffline;
      });
    }
    print('Initial offline state: $_isOffline');

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      print('Connectivity changed: offline=$isNowOffline');
      if (mounted) {
        setState(() {
          _isOffline = isNowOffline;
        });
      }
    });
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re offline',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Some content may not be available. Go to Downloads to view offline content.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/downloads'),
            icon: const Icon(Icons.download, color: AppTheme.primaryGreen),
            label: const Text(
              'Downloads',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // Handle search submission with category filtering
  void _performSearch(String query) {
    final trimmedQuery = query.trim();

    // Allow search if either query is not empty OR a category is selected
    if (trimmedQuery.isEmpty && _selectedCategoryId == null) {
      return;
    }

    // Close keyboard before navigating
    FocusManager.instance.primaryFocus?.unfocus();

    // Close category dropdown if open
    if (_showCategoryDropdown) {
      setState(() => _showCategoryDropdown = false);
    }

    final extra = {
      'searchQuery': trimmedQuery.isEmpty ? null : trimmedQuery,
      'categoryId': _selectedCategoryId,
      'categoryName': _selectedCategoryName,
    };

    // Navigate and then clear after navigation completes
    context.push('/courses', extra: extra).then((_) {
      // Clear search after returning from courses screen
      if (mounted) {
        _searchController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
      }
    });
  }

  // Trigger search with button tap
  void _onSearchButtonTap() {
    _performSearch(_searchController.text);
  }

  // FIX #10: Removed duplicate _checkUserRole call from didUpdateWidget.
  // didChangeDependencies already handles re-checks; calling it from
  // didUpdateWidget too caused redundant checks on every widget rebuild.

  void _checkUserRole() async {
    if (!_hasCheckedRole) {
      final authState =
          ref.read(authProvider); // use read, not watch, outside build

      // Prevent onboarding redirect during initial auth restoration.
      // This avoids a bounce right after login when onboarding flags are not yet stable.
      if (authState.user != null && !authState.isLoading) {
        _hasCheckedRole = true;
        debugPrint(
            'DashboardScreen: Checking user role - ${authState.user?.role}');

        if (authState.user?.role == 'admin') {
          debugPrint(
              'DashboardScreen: Admin detected, redirecting to admin dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/admin');
          });
        } else if (authState.user?.role == 'instructor') {
          debugPrint(
              'DashboardScreen: Instructor detected, redirecting to teacher dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/teacher/dashboard');
          });
        } else {
          // Only redirect to a step whose info is actually missing; a user who
          // already gave name, interests and phone is never sent back.
          final nextStep = nextOnboardingRoute(authState.user!);
          if (nextStep != null) {
            debugPrint(
                'DashboardScreen: Onboarding incomplete, redirecting to $nextStep');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(nextStep);
            });
          }
        }
      }
    }
  }

  // Content width scales with the window so wide desktop monitors aren't
  // left with a narrow column and huge unused side gutters, while still
  // capping line/card widths at a sane reading width on ultra-wide screens.
  double _dashboardContentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1700) return 1560;
    if (width >= 1400) return 1320;
    return 1180;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    // Watched so the provider stays alive and refreshes with the dashboard.
    ref.watch(enrolledCoursesProvider);
    final userEnrollmentsAsync = ref.watch(userEnrollmentsProvider);

    final popularCoursesAsync = ref.watch(popularCoursesProvider);
    final recommendedCoursesAsync = ref.watch(recommendedCoursesProvider);

    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double hPad = isMobile ? 16 : 28;

    final List<Course> popularCourses =
        popularCoursesAsync.valueOrNull ?? const <Course>[];
    final List<Course> recommendedCourses =
        recommendedCoursesAsync.valueOrNull ?? const <Course>[];
    final coursesToShow =
        recommendedCourses.isNotEmpty ? recommendedCourses : popularCourses;

    final enrollments =
        userEnrollmentsAsync.valueOrNull ?? const <Enrollment>[];
    final enrollmentsLoading =
        userEnrollmentsAsync.isLoading && !userEnrollmentsAsync.hasValue;
    final enrolledCourses =
        enrollments.map((e) => e.course).whereType<Course>().toList();

    return Scaffold(
      backgroundColor: _Dx.canvas(isDark),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            displacement: 50,
            strokeWidth: 3,
            color: AppTheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: isDesktop
                      ? _buildDesktopGreeting(context, user, hPad)
                      : _buildPremiumHeader(context, user, hPad),
                ),
                if (_showCategoryDropdown && !_isOffline)
                  SliverToBoxAdapter(
                    child: _heroConstrained(
                      context,
                      hPad,
                      _buildCategoryDropdown(context),
                    ),
                  ),
                if (_isOffline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _heroConstrained(
                          context, 0, _buildOfflineBanner(context)),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 18 : 26)),
                SliverToBoxAdapter(
                  child: _heroConstrained(
                    context,
                    hPad,
                    _isOffline
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DownloadsSection(),
                              SizedBox(height: 40),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 1000;
                              final main = _buildMainColumn(
                                context,
                                wide: wide,
                                enrollments: enrollments,
                                enrollmentsLoading: enrollmentsLoading,
                                enrolledCourses: enrolledCourses,
                                coursesToShow: coursesToShow,
                                popularCourses: popularCourses,
                              );
                              if (!wide) return main;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: main),
                                  const SizedBox(width: 24),
                                  SizedBox(
                                    width: constraints.maxWidth >= 1300
                                        ? 360
                                        : 320,
                                    child: _buildRightRail(
                                      context,
                                      enrollments: enrollments,
                                      enrollmentsLoading: enrollmentsLoading,
                                      enrolledCourses: enrolledCourses,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Support Button
          const Positioned(
            right: 16,
            bottom: 16,
            child: SupportFloatingButton(),
          ),
        ],
      ),
    );
  }

  /// Everything in the primary reading column, top to bottom. On wide
  /// layouts the progress/upcoming/help blocks move to the right rail.
  Widget _buildMainColumn(
    BuildContext context, {
    required bool wide,
    required List<Enrollment> enrollments,
    required bool enrollmentsLoading,
    required List<Course> enrolledCourses,
    required List<Course> coursesToShow,
    required List<Course> popularCourses,
  }) {
    final hasEnrollments = enrollments.isNotEmpty;
    const sectionGap = SizedBox(height: 28);
    // Started (or enrolled) students get their current course as the hero;
    // the generic "Build Skills" banner is only for those with nothing to resume.
    final current = _currentEnrollment(enrollments);
    final otherEnrollments =
        enrollments.where((e) => e.id != current?.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(
          0,
          enrollmentsLoading
              ? _buildHeroPlaceholder(context, wide: wide)
              : current != null
                  ? _buildContinueHero(context, current, wide: wide)
                  : _buildNextStepBanner(context, wide: wide),
        ),
        // Next upcoming/live session sits right under the hero; collapses
        // to nothing when there isn't one.
        if (hasEnrollments)
          _reveal(1, _buildNextSessionSection(context, enrolledCourses)),
        if (hasEnrollments) ...[
          if (otherEnrollments.any((e) => e.course != null)) ...[
            sectionGap,
            _reveal(
                2, _buildMyLearning(context, otherEnrollments, wide: wide)),
          ],
          _buildUpcomingStudySessions(context),
          if (!wide) ...[
            sectionGap,
            _reveal(3, _buildQuickStats(context, enrollments)),
          ],
        ],
        if (coursesToShow.isNotEmpty) ...[
          sectionGap,
          _buildRecommendedCourses(context, coursesToShow, enrolledCourses),
        ],
        if (popularCourses.isNotEmpty) ...[
          sectionGap,
          _buildResponsivePopularCourses(
              context, popularCourses, enrolledCourses),
        ],
        if (!wide) ...[
          sectionGap,
          _buildUpdateInterestsCard(context),
          const SizedBox(height: 14),
          _buildExamPreparationCard(context),
        ],
        sectionGap,
        const DownloadsSection(),
        const SizedBox(height: 28),
        if (ref.watch(authProvider.notifier).isAdmin)
          _buildAdminAccessButton(context),
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _buildRightRail(
    BuildContext context, {
    required List<Enrollment> enrollments,
    required bool enrollmentsLoading,
    required List<Course> enrolledCourses,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _reveal(
          1,
          _buildProgressPanel(context, enrollments, loading: enrollmentsLoading),
        ),
        _buildUpcomingRail(context, enrolledCourses),
        const SizedBox(height: 18),
        _buildUpdateInterestsCard(context),
        const SizedBox(height: 14),
        _buildExamPreparationCard(context),
        const SizedBox(height: 18),
        _buildHelpCard(context),
      ],
    );
  }

  /// Staggered fade-and-rise for the first blocks of the page, driven by the
  /// screen's one-second intro controller.
  Widget _reveal(int index, Widget child) {
    final controller = _animationController;
    if (controller == null) return child;
    final start = (index * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? (l10n?.goodMorning ?? 'Good morning')
        : hour < 17
            ? (l10n?.goodAfternoon ?? 'Good afternoon')
            : (l10n?.goodEvening ?? 'Good evening');
  }

  String _displayName(dynamic user) {
    final rawName = (user?.fullName as String?)?.trim();
    return (rawName == null || rawName.isEmpty) ? 'Student' : rawName;
  }

  // ===========================================================================
  // HERO (phones & tablets)
  // Deep emerald band with layered hills, identity, actions — and the search
  // bar floating across its lower edge.
  // ===========================================================================

  Widget _buildPremiumHeader(BuildContext context, dynamic user, double hPad) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;
    final showSearch = !_isOffline;
    const double searchHeight = 54;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          // Backdrop stops half-way down the search bar.
          Positioned.fill(
            bottom: showSearch ? searchHeight / 2 : 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF042F23), Color(0xFF053B2C)]
                        : const [_Dx.forest, _Dx.pine],
                  ),
                ),
                child: const CustomPaint(painter: _HeroHillsPainter()),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topInset + (isMobile ? 14 : 20)),
              // --- Identity + actions, one calm row ------------------------
              _heroConstrained(
                context,
                hPad,
                Row(
                  children: [
                    _buildHeroAvatar(
                      context,
                      user,
                      isSmall ? 46 : 52,
                      opensMenu: isMobile,
                    ),
                    SizedBox(width: isSmall ? 12 : 14),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go('/profile'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: isSmall ? 12 : 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _titleCase(_displayName(user)),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmall ? 17 : 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildHeroNotificationButton(context),
                    const SizedBox(width: 8),
                    _buildLanguageSwitcher(),
                  ],
                ),
              ),
              SizedBox(height: showSearch ? 24 : 28),
              if (showSearch)
                _heroConstrained(
                  context,
                  hPad,
                  SizedBox(
                    height: searchHeight,
                    child: _buildModernSearchBar(context, inset: false),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "tuyizere dieudonne" -> "Tuyizere Dieudonne".
  String _titleCase(String name) => name
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');

  /// Avatar on the dark hero: photo or initials inside a hairline ring. On
  /// phones it opens the navigation drawer (a small menu badge says so).
  Widget _buildHeroAvatar(BuildContext context, dynamic user, double size,
      {bool opensMenu = false}) {
    final picture = user?.profilePicture as String?;
    final hasPicture = picture != null && picture.isNotEmpty;

    return Tooltip(
      message: opensMenu ? 'Menu' : 'Profile',
      child: GestureDetector(
        onTap: () => opensMenu
            ? Scaffold.of(context).openDrawer()
            : context.go('/profile'),
        child: SizedBox(
          width: size + 4,
          height: size + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 1),
                ),
                child: ClipOval(
                  child: hasPicture
                      ? NetworkImageWidget(imageUrl: picture, fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withOpacity(0.14),
                          alignment: Alignment.center,
                          child: Text(
                            _initialsFor(user?.fullName as String?),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                ),
              ),
              if (opensMenu)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _Dx.forest, width: 2),
                    ),
                    child: const Icon(Icons.menu_rounded,
                        size: 11, color: _Dx.forest),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP GREETING
  // The shell already shows brand, notifications and avatar, so desktop gets a
  // calm greeting line with search beside it instead of the coloured band.
  // ===========================================================================

  Widget _buildDesktopGreeting(BuildContext context, dynamic user, double hPad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = _displayName(user).split(' ').first;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _heroConstrained(
        context,
        hPad,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, $firstName',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      color: _Dx.text(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: Text(
                      _motivationalPhrases[_phraseIndex],
                      key: ValueKey(_phraseIndex),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: _Dx.sub(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isOffline) ...[
              const SizedBox(width: 24),
              SizedBox(
                width: 420,
                height: 52,
                child: _buildModernSearchBar(context, inset: false),
              ),
            ],
            const SizedBox(width: 12),
            _buildLanguageSwitcher(onDark: false),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // "YOUR NEXT STEP" BANNER
  // ===========================================================================

  Widget _buildNextStepBanner(BuildContext context, {required bool wide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Text keeps the left ~58%; the illustration owns the rest.
        final artWidth = width * (wide ? 0.40 : 0.42);

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(wide ? 28 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0E2B23), Color(0xFF0B1F1C), Color(0xFF0C1A26)]
                  : const [Color(0xFFF1FBF6), Color(0xFFE6F6EE), Color(0xFFD9F1E5)],
            ),
            border: Border.all(
              color: isDark
                  ? _Dx.jade.withOpacity(0.22)
                  : const Color(0xFFCDEBDC),
            ),
            boxShadow: _Dx.shadow(isDark),
          ),
          child: Stack(
            children: [
              // Soft organic blobs behind the art.
              Positioned(
                right: -artWidth * 0.25,
                bottom: -artWidth * 0.35,
                child: Container(
                  width: artWidth * 1.15,
                  height: artWidth * 1.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Dx.jade.withOpacity(isDark ? 0.16 : 0.12),
                  ),
                ),
              ),
              Positioned(
                right: artWidth * 0.55,
                top: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(isDark ? 0.03 : 0.55),
                  ),
                ),
              ),
              Positioned(
                right: wide ? 8 : -6,
                bottom: 0,
                top: wide ? 14 : 22,
                width: artWidth,
                child: Image.asset(
                  'assets/Course app-bro.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : (isSmall ? 16 : 20),
                  wide ? 30 : (isSmall ? 18 : 20),
                  artWidth - (wide ? 10 : 18),
                  wide ? 30 : (isSmall ? 18 : 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _Dx.jade.withOpacity(isDark ? 0.22 : 0.13),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Your Next Step',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? _Dx.mintGlow : _Dx.emerald,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    SizedBox(height: wide ? 14 : 12),
                    Text(
                      'Build Skills,\nGet Opportunities',
                      style: TextStyle(
                        fontSize: wide ? 34 : (isSmall ? 20 : (isMobile ? 23 : 28)),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: wide ? -1.1 : -0.7,
                        color: _Dx.text(isDark),
                      ),
                    ),
                    SizedBox(height: wide ? 12 : 9),
                    Text(
                      'Access quality courses, live sessions and career support — all in one place.',
                      style: TextStyle(
                        fontSize: wide ? 15 : (isSmall ? 12 : 13),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: _Dx.sub(isDark),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: wide ? 22 : 16),
                    _buildPillButton(
                      label: l10n?.browseCourses ?? 'Explore Courses',
                      icon: Icons.arrow_forward_rounded,
                      compact: !wide,
                      onTap: () => context.push('/courses'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The course the hero should resume: the most recently active course in
  /// progress, else the newest one not started yet. Null when every course is
  /// finished (or there are none) — then the generic banner shows instead.
  Enrollment? _currentEnrollment(List<Enrollment> enrollments) {
    final withCourse = enrollments.where((e) => e.course != null);
    final inProgress = withCourse
        .where((e) => e.progress > 0 && e.progress < 100)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (inProgress.isNotEmpty) return inProgress.first;
    final notStarted = withCourse.where((e) => e.progress <= 0).toList()
      ..sort((a, b) => b.enrollmentDate.compareTo(a.enrollmentDate));
    return notStarted.isNotEmpty ? notStarted.first : null;
  }

  /// Hero for students already enrolled: their current course, how far they
  /// are, and one button straight back into it.
  Widget _buildContinueHero(BuildContext context, Enrollment enrollment,
      {required bool wide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final course = enrollment.course!;
    final percent = enrollment.progress.clamp(0, 100).toInt();
    final notStarted = percent == 0;
    final categoryName = (course.category?['name'] as String?)?.trim();
    final hasThumb = course.thumbnail != null && course.thumbnail!.isNotEmpty;
    final accent = isDark ? _Dx.mintGlow : _Dx.emerald;
    void open() =>
        CourseNavigationUtils.navigateToCourseWithContext(context, ref, course);

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 22 : 18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasThumb)
            NetworkImageWidget(imageUrl: course.thumbnail!, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_Dx.pine, _Dx.forest],
                ),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: Colors.white.withOpacity(0.35), size: 44),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
              ),
            ),
          ),
          Center(
            child: Container(
              width: wide ? 58 : 46,
              height: wide ? 58 : 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: _Dx.emerald, size: wide ? 32 : 26),
            ),
          ),
        ],
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _Dx.jade.withOpacity(isDark ? 0.22 : 0.13),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                notStarted ? Icons.flag_rounded : Icons.history_rounded,
                size: 13,
                color: accent,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  notStarted
                      ? (l10n?.dashReadyToStart ?? 'Ready when you are')
                      : (l10n?.dashPickUpWhereLeft ??
                          'Pick up where you left off'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: wide ? 14 : 12),
        if (categoryName != null && categoryName.isNotEmpty) ...[
          Text(
            categoryName,
            style: TextStyle(
              fontSize: wide ? 13 : 12,
              fontWeight: FontWeight.w500,
              color: _Dx.sub(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          course.title,
          style: TextStyle(
            fontSize: wide ? 28 : (isSmall ? 18 : 20),
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: wide ? -0.9 : -0.5,
            color: _Dx.text(isDark),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: wide ? 16 : 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.85),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent / 100,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), _Dx.emerald],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? 20 : 16),
        _buildPillButton(
          label: notStarted
              ? (l10n?.startLearning ?? 'Start Learning')
              : (l10n?.continueLearning ?? 'Continue Learning'),
          icon: Icons.play_arrow_rounded,
          compact: !wide,
          onTap: open,
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(wide ? 28 : 24),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(wide ? 28 : 24),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(wide ? 26 : (isSmall ? 14 : 16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(wide ? 28 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0E2B23), Color(0xFF0B1F1C), Color(0xFF0C1A26)]
                  : const [Color(0xFFF1FBF6), Color(0xFFE6F6EE), Color(0xFFD9F1E5)],
            ),
            border: Border.all(
              color: isDark
                  ? _Dx.jade.withOpacity(0.22)
                  : const Color(0xFFCDEBDC),
            ),
            boxShadow: _Dx.shadow(isDark),
          ),
          child: Row(
            children: [
              Expanded(flex: wide ? 13 : 12, child: details),
              SizedBox(width: wide ? 28 : 14),
              Expanded(
                flex: wide ? 9 : 8,
                child: AspectRatio(
                  aspectRatio: wide ? 4 / 3 : 0.9,
                  child: thumbnail,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same footprint as the hero, shown while enrollments load so returning
  /// students don't see the "get started" banner flash first.
  Widget _buildHeroPlaceholder(BuildContext context, {required bool wide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: wide ? 250 : 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wide ? 28 : 24),
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE9F3EE),
      ),
    );
  }

  /// The dashboard's primary button: a deep emerald pill with a trailing icon.
  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Dx.emerald, _Dx.forest],
        ),
        boxShadow: [
          BoxShadow(
            color: _Dx.forest.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 22,
              vertical: compact ? 11 : 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shrink rather than truncate when space is tight.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: compact ? 17 : 19),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MY LEARNING
  // ===========================================================================

  Widget _buildMyLearning(BuildContext context, List<Enrollment> enrollments,
      {required bool wide}) {
    // In-progress courses first, then not-started, then completed.
    int rank(Enrollment e) =>
        e.progress >= 100 ? 2 : (e.progress > 0 ? 0 : 1);
    final ordered = enrollments.where((e) => e.course != null).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    if (ordered.isEmpty) return const SizedBox.shrink();
    final visible = ordered.take(wide ? 2 : 1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: l10n?.myLearning ?? 'My Learning',
          icon: Icons.play_circle_rounded,
          color: _Dx.jade,
          onSeeAll: () => context.push('/my-courses'),
          seeAllLabel: 'View All',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildLearningCard(context, visible[i]),
        ],
      ],
    );
  }

  Widget _buildLearningCard(BuildContext context, Enrollment enrollment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final course = enrollment.course!;
    final percent = enrollment.progress.clamp(0, 100).toInt();
    final isCompleted = percent >= 100;
    final isNotStarted = percent == 0;
    final categoryName = (course.category?['name'] as String?)?.trim();
    final hasThumb = course.thumbnail != null && course.thumbnail!.isNotEmpty;
    final thumbW = isSmall ? 104.0 : (isMobile ? 124.0 : 148.0);
    final thumbH = isSmall ? 84.0 : (isMobile ? 96.0 : 104.0);

    final (badgeLabel, badgeColor) = isCompleted
        ? (l10n?.completed ?? 'Completed', const Color(0xFF2563EB))
        : isNotStarted
            ? (l10n?.notStarted ?? 'Not Started', const Color(0xFFEA580C))
            : ('In Progress', _Dx.jade);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
            context, ref, course),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: _Dx.surface(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _Dx.line(isDark)),
            boxShadow: _Dx.shadow(isDark),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: thumbW,
                  height: thumbH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumb)
                        NetworkImageWidget(
                            imageUrl: course.thumbnail!, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                            ),
                          ),
                          child: Icon(Icons.code_rounded,
                              color: Colors.white.withOpacity(0.8), size: 30),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.5],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 7,
                        top: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (categoryName != null && categoryName.isNotEmpty) ...[
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _Dx.sub(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                        color: _Dx.text(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                  height: 7,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : const Color(0xFFE8EEF0),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percent / 100,
                                  child: Container(
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_Dx.emerald, Color(0xFF10B981)],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? _Dx.mintGlow : _Dx.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 6 : 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Dx.jade.withOpacity(isDark ? 0.18 : 0.10),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.replay_rounded
                      : Icons.chevron_right_rounded,
                  color: isDark ? _Dx.mintGlow : _Dx.emerald,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LIVE SESSIONS
  // ===========================================================================

  /// Cached so rebuilds don't refetch — only a change of enrolled courses does.
  Future<List<LiveSession>> _sessionsFutureFor(List<Course> enrolledCourses) {
    final courseIds = enrolledCourses.map((c) => c.id).toList();
    if (_upcomingSessionsFuture == null ||
        !_listEquals(courseIds, _lastEnrolledCourseIds)) {
      _lastEnrolledCourseIds = List<String>.from(courseIds);
      _upcomingSessionsFuture =
          _fetchUpcomingSessionsForCourses(enrolledCourses);
    }
    return _upcomingSessionsFuture!;
  }

  bool _sessionIsLiveNow(LiveSession session) =>
      session.isLive && !session.calculatedEndTime.isBefore(DateTime.now());

  String _friendlySessionTime(DateTime when) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = when.toLocal();
    final now = DateTime.now();
    final dayDiff = DateTime(local.year, local.month, local.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final time =
        '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
    if (dayDiff == 0) return 'Today, $time';
    if (dayDiff == 1) return 'Tomorrow, $time';
    if (dayDiff == -1) return 'Yesterday, $time';
    return '${weekdays[local.weekday - 1]}, ${months[local.month - 1]} ${local.day} · $time';
  }

  /// The single next session, featured — with a join button once it's live.
  Widget _buildNextSessionSection(
      BuildContext context, List<Course> enrolledCourses) {
    if (enrolledCourses.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<LiveSession>>(
      future: _sessionsFutureFor(enrolledCourses),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <LiveSession>[];
        if (sessions.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
        final session = sessions.first;
        final isLive = _sessionIsLiveNow(session);
        final accent = isLive ? const Color(0xFFDC2626) : _Dx.jade;
        final courseTitle = session.course?['title'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLive
                    ? (isDark
                        ? const [Color(0xFF2A0F12), Color(0xFF1A0F14)]
                        : const [Color(0xFFFFF5F5), Color(0xFFFFECEC)])
                    : (isDark
                        ? const [Color(0xFF0E2A22), Color(0xFF0D1F22)]
                        : const [Color(0xFFF2FBF6), Color(0xFFE7F6EE)]),
              ),
              border: Border.all(
                color: accent.withOpacity(isDark ? 0.30 : 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isSmall ? 48 : 54,
                      height: isSmall ? 48 : 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Dx.surface(isDark),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLive
                            ? Icons.videocam_rounded
                            : Icons.event_available_rounded,
                        color: accent,
                        size: isSmall ? 22 : 25,
                      ),
                    ),
                    SizedBox(width: isSmall ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isLive) ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  isLive ? 'Live now' : 'Next Live Session',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isLive ? accent : _Dx.sub(isDark),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            session.title,
                            style: TextStyle(
                              fontSize: isSmall ? 14 : 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: _Dx.text(isDark),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 14, color: _Dx.sub(isDark)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  courseTitle.isNotEmpty
                                      ? '${_friendlySessionTime(session.scheduledAt)} · $courseTitle'
                                      : _friendlySessionTime(session.scheduledAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _Dx.sub(isDark),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isLive)
                      FilledButton(
                        onPressed: () => _joinStudentSession(context, session),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 16 : 22, vertical: 12),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Join'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => context.push('/upcoming-sessions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? _Dx.mintGlow : _Dx.emerald,
                          side: BorderSide(
                              color: _Dx.jade.withOpacity(isDark ? 0.5 : 0.35)),
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 12 : 18, vertical: 11),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Details'),
                      ),
                  ],
                ),
                if (!isLive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      LiveSessionCountdown(
                        scheduledAt: session.scheduledAt,
                        durationMinutes: session.duration,
                        isLive: session.isLive,
                        compact: true,
                      ),
                      const Spacer(),
                      if (sessions.length > 1)
                        InkWell(
                          onTap: () => context.push('/upcoming-sessions'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              '+${sessions.length - 1} more',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? _Dx.mintGlow : _Dx.emerald,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Right-rail list of the next few sessions (wide layouts only).
  Widget _buildUpcomingRail(BuildContext context, List<Course> enrolledCourses) {
    if (enrolledCourses.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<LiveSession>>(
      future: _sessionsFutureFor(enrolledCourses),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <LiveSession>[];
        if (sessions.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            decoration: _Dx.panel(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  title: 'Upcoming',
                  icon: Icons.event_rounded,
                  color: _Dx.jade,
                  onSeeAll: () => context.push('/upcoming-sessions'),
                  seeAllLabel: 'View All',
                  compact: true,
                ),
                const SizedBox(height: 12),
                for (final session in sessions.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildUpcomingRow(context, session),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingRow(BuildContext context, LiveSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLive = _sessionIsLiveNow(session);
    final accent = isLive ? const Color(0xFFDC2626) : _Dx.jade;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isLive
            ? _joinStudentSession(context, session)
            : context.push('/upcoming-sessions'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _Dx.surface(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Dx.line(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(isDark ? 0.2 : 0.1),
                ),
                child: Icon(
                  isLive ? Icons.videocam_rounded : Icons.video_call_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? 'Live now' : 'Live Session',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Dx.text(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _friendlySessionTime(session.scheduledAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _Dx.sub(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PROGRESS & STATS
  // ===========================================================================

  ({int enrolled, int completed, double average}) _learningStats(
      List<Enrollment> enrollments) {
    final completed = enrollments.where((e) => e.progress >= 100).length;
    final average = enrollments.isEmpty
        ? 0.0
        : enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length;
    return (
      enrolled: enrollments.length,
      completed: completed,
      average: average.clamp(0.0, 100.0),
    );
  }

  /// Mobile/tablet: three tinted tiles under the learning blocks.
  Widget _buildQuickStats(BuildContext context, List<Enrollment> enrollments) {
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final stats = _learningStats(enrollments);

    final items = [
      (Icons.menu_book_rounded, '${stats.enrolled}',
          l10n?.enrolled ?? 'Enrolled', _Dx.jade),
      (Icons.verified_rounded, '${stats.completed}',
          l10n?.completed ?? 'Completed', const Color(0xFF2563EB)),
      (Icons.military_tech_rounded, '${stats.average.toInt()}%',
          'Avg. Progress', const Color(0xFF7C3AED)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Quick Stats',
          icon: Icons.insights_rounded,
          color: _Dx.jade,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: _buildStatTile(
                  context,
                  icon: items[i].$1,
                  value: items[i].$2,
                  label: items[i].$3,
                  color: items[i].$4,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
    final tint = isDark ? Color.lerp(color, Colors.white, 0.3)! : color;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Color.alphaBlend(
            color.withOpacity(isDark ? 0.10 : 0.06), _Dx.surface(isDark)),
        border: Border.all(color: color.withOpacity(isDark ? 0.22 : 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isDark ? 0.22 : 0.12),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 19 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: _Dx.text(isDark),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10.5 : 11.5,
              fontWeight: FontWeight.w500,
              color: _Dx.sub(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Right-rail progress card: average progress ring + the three headline
  /// numbers.
  Widget _buildProgressPanel(BuildContext context, List<Enrollment> enrollments,
      {required bool loading}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _learningStats(enrollments);
    final value = loading ? '—' : null;

    Widget stat(IconData icon, String number, String label, Color color) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: isDark ? Color.lerp(color, Colors.white, 0.3) : color),
            const SizedBox(height: 8),
            Text(
              value ?? number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Dx.text(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: _Dx.sub(isDark)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 46,
          color: _Dx.line(isDark),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _Dx.panel(isDark),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stats.average / 100),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => CustomPaint(
                    painter: _ProgressRingPainter(
                      value: t,
                      track: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFE6F2EC),
                    ),
                    child: Center(
                      child: Text(
                        value ?? '${(t * 100).round()}%',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: _Dx.text(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.yourProgress ?? 'Your Progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _Dx.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      child: Text(
                        _motivationalPhrases[_phraseIndex],
                        key: ValueKey(_phraseIndex),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: _Dx.sub(isDark),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push('/my-courses'),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? _Dx.mintGlow : _Dx.emerald,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 15,
                              color: isDark ? _Dx.mintGlow : _Dx.emerald),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF7FAF8),
              border: Border.all(color: _Dx.line(isDark)),
            ),
            child: Row(
              children: [
                stat(Icons.menu_book_rounded, '${stats.enrolled}',
                    l10n?.enrolled ?? 'Enrolled', _Dx.jade),
                divider(),
                stat(Icons.verified_rounded, '${stats.completed}',
                    l10n?.completed ?? 'Completed', const Color(0xFF2563EB)),
                divider(),
                stat(Icons.bar_chart_rounded, '${stats.average.toInt()}%',
                    'Avg. Progress', const Color(0xFF7C3AED)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0E2A22), Color(0xFF0D1F22)]
              : const [Color(0xFFF2FBF6), Color(0xFFE5F5EC)],
        ),
        border: Border.all(color: _Dx.jade.withOpacity(isDark ? 0.25 : 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Dx.surface(isDark),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: _Dx.jade, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _Dx.text(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Our team is here to support you.',
                  style: TextStyle(fontSize: 12, color: _Dx.sub(isDark)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            label: 'Contact',
            icon: Icons.arrow_forward_rounded,
            compact: true,
            onTap: () => _showContactInfoDialog(context),
          ),
        ],
      ),
    );
  }

  // FIX #6: Extracted refresh logic into a dedicated method to cleanly
  // discard provider refresh futures without the warning-suppression no-op pattern.
  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return; // Prevent concurrent refreshes

    setState(() => _isRefreshing = true);

    try {
      // Invalidate all dashboard data providers to trigger fresh fetch
      ref.invalidate(enrolledCoursesProvider);
      ref.invalidate(userEnrollmentsProvider);
      ref.invalidate(popularCoursesProvider);
      ref.invalidate(recommendedCoursesProvider);

      // Wait for the providers to reload
      await Future.wait([
        ref.read(enrolledCoursesProvider.future),
        ref.read(userEnrollmentsProvider.future),
        ref.read(popularCoursesProvider.future),
        ref.read(recommendedCoursesProvider.future),
      ]);
    } catch (e) {
      debugPrint('DashboardScreen: Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Centres hero content and caps it at the shared dashboard width so the
  /// layout also reads well on tablets and desktop.
  Widget _heroConstrained(BuildContext context, double hPad, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: _dashboardContentMaxWidth(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeroNotificationButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notifications = ref.watch(notificationProvider).notifications;
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeroIconButton(
              icon: unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              tooltip: l10n?.notifications ?? 'Notifications',
              onTap: () {
                PushNotificationService.clearNotifications();
                context.push('/notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Translucent 40x40 tile used for header actions on the coloured backdrop.
  Widget _buildHeroIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        tooltip: tooltip,
        padding: const EdgeInsets.all(10),
      ),
    );
  }

  /// Flag + chevron pill. [onDark] styles it for the emerald hero; otherwise
  /// it sits on the page canvas (desktop greeting).
  Widget _buildLanguageSwitcher({bool onDark = true}) {
    return Consumer(
      builder: (context, ref, child) {
        final currentLocale = ref.watch(localeProvider);
        final currentLang = currentLocale.languageCode;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fg = onDark ? Colors.white : _Dx.text(isDark);

        return Container(
          height: onDark ? 42 : 52,
          decoration: BoxDecoration(
            color: onDark ? Colors.white.withOpacity(0.12) : _Dx.surface(isDark),
            borderRadius: BorderRadius.circular(onDark ? 14 : 16),
            border: Border.all(
              color: onDark ? Colors.white.withOpacity(0.18) : _Dx.line(isDark),
            ),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLang == 'en' ? '🇬🇧' : '🇷🇼',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (!ResponsiveBreakpoints.isSmallMobile(context)) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: fg.withOpacity(0.85)),
                  ],
                ],
              ),
            ),
            tooltip: 'Change Language',
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String languageCode) async {
              await ref.read(localeProvider.notifier).setLanguage(languageCode);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      'English',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A2433),
                        fontWeight: currentLang == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLang == 'en')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Color(0xFF00C896)),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'rw',
                child: Row(
                  children: [
                    const Text('🇷🇼', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      'Kinyarwanda',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A2433),
                        fontWeight: currentLang == 'rw'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLang == 'rw')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Color(0xFF00C896)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Up to two initials from the user's name, e.g. "Jane Doe" -> "JD".
  String _initialsFor(String? fullName) {
    final parts = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  List<BoxShadow> _softShadows(Color color, {double opacity = 0.10}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  BoxDecoration _modernPanelDecoration(BuildContext context, {Color? accent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF111C2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE6ECF3);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: _softShadows(accent ?? const Color(0xFF64748B),
          opacity: isDark ? 0.16 : 0.08),
    );
  }

  BoxDecoration _examPreparationDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? const Color(0xFF1E1B3A) 
        : const Color(0xFFF5F3FF);
    final borderColor = isDark 
        ? const Color(0xFF8B5CF6).withOpacity(0.3) 
        : const Color(0xFF8B5CF6).withOpacity(0.2);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: _softShadows(const Color(0xFF8B5CF6), opacity: isDark ? 0.2 : 0.12),
    );
  }

  /// Floating search pill. [inset] adds the page gutter; pass false when the
  /// caller already constrains and pads it.
  Widget _buildModernSearchBar(BuildContext context, {bool inset = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final hasFilter = _selectedCategoryId != null;
    final accent = isDark ? _Dx.mintGlow : _Dx.emerald;

    return Container(
      margin: inset
          ? EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28)
          : EdgeInsets.zero,
      height: 54,
      decoration: BoxDecoration(
        color: _Dx.surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFilter ? _Dx.jade.withOpacity(0.5) : _Dx.line(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _Dx.forest)
                .withOpacity(isDark ? 0.35 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: _Dx.sub(isDark), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              onChanged: (_) {
                if (mounted) setState(() {});
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: _Dx.text(isDark),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: _selectedCategoryName == null
                    ? 'Search courses, sessions, anything…'
                    : 'Search in $_selectedCategoryName…',
                hintStyle: TextStyle(
                  color: _Dx.sub(isDark).withOpacity(0.8),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: Icon(Icons.close_rounded, color: _Dx.sub(isDark), size: 18),
              onPressed: () {
                _searchController.clear();
                if (mounted) setState(() {});
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Material(
              color: hasFilter || _showCategoryDropdown
                  ? _Dx.jade.withOpacity(isDark ? 0.25 : 0.14)
                  : _Dx.jade.withOpacity(isDark ? 0.14 : 0.07),
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  if (mounted) {
                    setState(
                        () => _showCategoryDropdown = !_showCategoryDropdown);
                  }
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    _showCategoryDropdown
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.tune_rounded,
                    color: accent,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Study sessions organised by students and study groups, shown right below
  /// the teacher-led live sessions.
  ///
  /// Peer sessions were previously only discoverable by opening a course's
  /// community, which meant a group meeting scheduled for tonight could be
  /// missed entirely. Here they sit next to classes, with the same join
  /// affordances the community card gives.
  Widget _buildUpcomingStudySessions(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Consumer(
      builder: (context, ref, _) {
        final sessionsAsync = ref.watch(myStudySessionsProvider);

        return sessionsAsync.maybeWhen(
          data: (sessions) {
            if (sessions.isEmpty) return const SizedBox.shrink();
            final live = sessions.where((s) => s.isLive).length;

            return Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Study Sessions',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getTextColor(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (live > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organised by you and your classmates',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // The community's own card, so Open the room / Join now /
                  // recording all behave identically to the Sessions tab.
                  ...sessions.take(3).map((session) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SessionCard(
                          courseId: session.courseId ?? '',
                          session: session,
                        ),
                      )),
                  if (sessions.length > 3)
                    TextButton.icon(
                      onPressed: () => context.push('/community'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View all study sessions'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                      ),
                    ),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<List<LiveSession>> _fetchUpcomingSessionsForCourses(List<Course> courses) async {
    final service = LiveSessionService();
    final all = <LiveSession>[];
    for (final course in courses) {
      if (course.id.isEmpty) continue;
      try {
        final result = await service.getCourseSessions(
          course.id,
          status: 'scheduled',
          limit: 5,
        );
        all.addAll(result.sessions);
      } catch (_) {}
    }
    // Remove ended/cancelled sessions
    // Scheduled sessions should be shown even if past their expected end time (teacher may not have started yet)
    // Only filter out live sessions that have actually ended
    final now = DateTime.now();
    all.removeWhere((s) =>
        s.isEnded ||
        s.isCancelled ||
        (s.isLive && s.calculatedEndTime.isBefore(now)));
    // Live sessions first, then by scheduledAt ascending
    all.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
    // Schedule push notifications for these sessions
    PushNotificationService.scheduleLiveSessionNotifications(all);
    return all;
  }

  Future<void> _joinStudentSession(BuildContext context, LiveSession session) async {
    try {
      final service = LiveSessionService();
      final response = await service.joinSession(session.id);
      if (!mounted) return;
      if (response.joinUrl.isNotEmpty) {
        final uri = Uri.parse(response.joinUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: ${response.joinUrl}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining session: $e')),
        );
      }
    }
  }

  // Stat Card (kept for other uses)
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateInterestsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/interest-selection', extra: {'isEditMode': true}),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _modernPanelDecoration(
            context,
            accent: AppTheme.primary,
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 50,
                height: isMobile ? 42 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.updateInterests ?? 'Update your interests',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.updateYourInterests ?? 'Refresh recommendations based on what you want to learn next.',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildChevronChip(
                  isDark ? AppTheme.primaryLight : AppTheme.primaryDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevronChip(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward_rounded, color: color, size: 17),
    );
  }

  Widget _buildExamPreparationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final url = l10n?.examMarketplaceUrl ?? 'https://www.eexams.net/marketplace';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _examPreparationDecoration(context),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 50,
                height: isMobile ? 42 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.examPreparation ?? 'Exam Preparation',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.examPreparationBenefit ?? 'Access past papers, practice tests, and expert guidance to ace your exams',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildChevronChip(
                  isDark ? const Color(0xFFA78BFA) : const Color(0xFF6366F1)),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_graph, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Text(l10n?.learningStatistics ?? 'Learning Statistics'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatItem(
                icon: Icons.school,
                label: l10n?.coursesEnrolled ?? 'Courses Enrolled',
                value: '5',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.play_circle,
                label: l10n?.lessonsCompleted ?? 'Lessons Completed',
                value: '24',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.quiz,
                label: l10n?.examsTaken ?? 'Exams Taken',
                value: '8',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.access_time,
                label: l10n?.hoursLearned ?? 'Hours Learned',
                value: '12.5',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.close ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.selectCategory ?? 'Select Category',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    if (mounted) {
                      setState(() => _showCategoryDropdown = false);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.getSecondaryTextColor(context),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Category List
          SizedBox(
            height: isMobile ? 200 : 300,
            child: _buildCategoryList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No categories available',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildCategoryOption(
              context,
              'all',
              l10n?.allCategories ?? 'All Categories',
              l10n?.searchAcrossAllCourses ?? 'Search across all available courses',
              Icons.grid_view_rounded,
              const Color(0xFF10B981),
              null,
            ),
            ...categories.map((category) => _buildCategoryOption(
                  context,
                  category.id,
                  category.name,
                  'Courses in ${category.name}',
                  CategoryUtils.getCategoryIcon(category.id, name: category.name),
                  CategoryUtils.getCategoryColor(category.id, name: category.name),
                  category,
                )),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n?.failedToLoadCategories ?? 'Failed to load categories',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOption(
    BuildContext context,
    String categoryId,
    String name,
    String description,
    IconData icon,
    Color color,
    Category? category,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategoryId == categoryId;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!mounted) return;
          // Immediate response for better UX
          setState(() {
            _selectedCategoryId = categoryId;
            _selectedCategoryName = name;
            _showCategoryDropdown = false;
          });

          // Perform search immediately if category is selected to improve UX
          if (categoryId != 'all' && mounted) {
            _performSearch(''); // Trigger search with selected category
          }
        },
        splashColor: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : isDark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : color.withOpacity(0.8),
                  size: isMobile ? 18 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color:
                            isSelected ? color : AppTheme.getTextColor(context),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: isMobile ? 11 : 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Animated checkmark
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.elasticOut,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: isMobile ? 18 : 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      height: isMobile ? 40 : 44,
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final category = isFirst ? null : categories[index - 1];
            final categoryId = isFirst ? 'all' : category!.id;
            final color = CategoryUtils.getCategoryColor(categoryId,
                name: isFirst ? 'all' : category?.name);
            final name = isFirst ? 'All' : category!.name;
            final icon = CategoryUtils.getCategoryIcon(categoryId,
                name: isFirst ? 'all' : category?.name);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  context.push('/courses', extra: {
                    'categoryId': categoryId,
                    'categoryName': isFirst ? 'All Courses' : name,
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: isMobile ? 16 : 18,
                        color: color,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWelcomeCard(
      BuildContext context, user, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C896), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            // Profile Header Section
            Row(
              children: [
                // Profile Picture
                Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: user?.profilePicture != null &&
                          user!.profilePicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: NetworkImageWidget(
                            imageUrl: user.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isMobile ? 24 : 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName?.split(" ")[0] ?? 'Student'}!',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to continue your learning journey?',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 12 : 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enhanced Notification Bell
                Consumer(
                  builder: (context, ref, child) {
                    final notifications =
                        ref.watch(notificationProvider).notifications;
                    final unreadCount =
                        notifications.where((n) => !n.isRead).length;
                    final isMobile = ResponsiveBreakpoints.isMobile(context);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Clear notification badge when clicked
                            PushNotificationService.clearNotifications();
                            context.push('/notifications');
                          },
                          borderRadius: BorderRadius.circular(20),
                          splashColor: const Color(0xFF10B981).withOpacity(0.1),
                          child: Container(
                            width: isMobile ? 36 : 44,
                            height: isMobile ? 36 : 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Bell Icon
                                AnimatedScale(
                                  scale: unreadCount > 0 ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.elasticOut,
                                  child: Icon(
                                    unreadCount > 0
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: isMobile ? 18 : 22,
                                  ),
                                ),
                                // Notification Badge
                                AnimatedScale(
                                  scale: unreadCount > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.bounceOut,
                                  child: Container(
                                    width: isMobile ? 16 : 20,
                                    height: isMobile ? 16 : 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 8 : 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search Bar floats on the green card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildEnhancedSearchBar(context, false),
            ),
            // Category Dropdown
            if (_showCategoryDropdown)
              GestureDetector(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _showCategoryDropdown = false);
                    }
                  });
                },
                child: _buildCategoryDropdown(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Category Filter Button
        GestureDetector(
          onTap: () {
            // Use WidgetsBinding to prevent frame callback issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _showCategoryDropdown = !_showCategoryDropdown);
              }
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _selectedCategoryId != null
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.category_outlined,
                  color: _selectedCategoryId != null
                      ? const Color(0xFF10B981)
                      : AppTheme.getSecondaryTextColor(context),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedCategoryName ?? 'All',
                  style: TextStyle(
                    color: _selectedCategoryId != null
                        ? const Color(0xFF10B981)
                        : AppTheme.getSecondaryTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCategoryDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _selectedCategoryId != null
                      ? const Color(0xFF10B981)
                      : AppTheme.getSecondaryTextColor(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // Search Input
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: _performSearch,
            onChanged: (value) {
              if (_showCategoryDropdown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            },
            decoration: InputDecoration(
              hintText: _selectedCategoryId != null
                  ? 'Search in $_selectedCategoryName...'
                  : 'Search courses, topics, instructors...',
              hintStyle: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppTheme.greyColor),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: AppTheme.getSecondaryTextColor(context),
                        size: 18,
                      ),
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() =>
                                _showCategoryDropdown = !_showCategoryDropdown);
                          }
                        });
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveClassInfo(BuildContext context, bool isDark) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF10B981).withOpacity(0.1),
              const Color(0xFF06B6D4).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: isMobile ? 32 : 40,
              height: isMobile ? 32 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              ),
              child: Icon(
                Icons.live_tv_rounded,
                color: const Color(0xFF10B981),
                size: isMobile ? 16 : 20,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n?.liveClassesAvailable ?? 'Live Classes Available',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    'Want to join our live classes? Contact us to get started!',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: isMobile ? 12 : 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Contact Options
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildContactOption(
                    context,
                    Icons.email_rounded,
                    'Email',
                    'support@excellencecoachinghub.com',
                    () => _launchEmail('support@excellencecoachinghub.com'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.phone_rounded,
                    'Phone',
                    '+0781 671 517',
                    () => _launchPhone('0781671517'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.phone_rounded,
                    'Phone',
                    '+250 788 1234',
                    () => _launchPhone('2507881234'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.message_rounded,
                    'WhatsApp',
                    '+250 788 1234',
                    () => _launchWhatsApp('2507881234'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 300 : 400,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.contact_support_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Contact Us for Live Classes',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contact Options
                _buildContactOption(
                  context,
                  Icons.email_rounded,
                  'Email',
                  'support@excellencecoachinghub.com',
                  () => _launchEmail('support@excellencecoachinghub.com'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.phone_rounded,
                  'Phone',
                  '+0781 671 517',
                  () => _launchPhone('0781671517'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.phone_rounded,
                  'Phone',
                  '+250 788 1234',
                  () => _launchPhone('2507881234'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.message_rounded,
                  'WhatsApp',
                  '+250 788 1234',
                  () {
                    // Open WhatsApp
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF10B981).withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContinueButton(BuildContext context, Course lastCourse) {
    return InkWell(
      onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
          context, ref, lastCourse),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (l10n?.continueLearning ?? 'CONTINUE LEARNING').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    lastCourse.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatsOverlay(BuildContext context,
      List<Enrollment> enrollments, double averageProgress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: !isMobile(context)
            ? Colors.white.withOpacity(0.12)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: !isMobile(context)
            ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: !isMobile(context)
            ? []
            : [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeStatItem(
                    context,
                    Icons.school_rounded,
                    '${enrollments.length} Courses',
                    'Enrolled',
                    !isMobile(context) ? Colors.white : const Color(0xFF10B981),
                    isDesktop: !isMobile(context)),
                SizedBox(height: isDesktop ? 16 : 12),
                _buildWelcomeStatItem(
                    context,
                    Icons.auto_graph_rounded,
                    '${averageProgress.toInt()}%',
                    'Avg. Progress',
                    !isMobile(context) ? Colors.white : const Color(0xFF06B6D4),
                    isDesktop: !isMobile(context)),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          _buildCircularProgress(context, averageProgress,
              mini: isMobile(context) || !isDesktop,
              color: !isMobile(context) ? Colors.white : null),
        ],
      ),
    );
  }

  bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.isMobile(context);

  Widget _buildWelcomeStatItem(BuildContext context, IconData icon,
      String value, String label, Color color,
      {bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDesktop
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: isDesktop ? Colors.white : color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDesktop
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF333333)),
                    height: 1.2,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDesktop
                        ? Colors.white.withOpacity(0.8)
                        : (isDark ? Colors.white70 : const Color(0xFF9CA3AF)),
                    height: 1.2,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context, double progress,
      {bool mini = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = mini ? 54.0 : 70.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: mini ? 5 : 8,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                color ?? (mini ? Colors.white : const Color(0xFF10B981))),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${progress.toInt()}%',
                style: TextStyle(
                  fontSize: mini ? 12 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
            if (!mini)
              Text('Completed',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                  )),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminAccessButton(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.adminPanel ?? 'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.coursesManagement ?? 'Manage courses, students & settings',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF00C896)),
              onPressed: () => context.push('/admin'),
            ),
          ),
        ],
      ),
    );
  }

  // FIX #4: Removed unused _buildQuickActions (non-responsive version).
  // Only _buildResponsiveQuickActions is kept since it's the only one referenced.

  Widget _buildResponsiveQuickActions(BuildContext context) {
    final actions = [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'subtitle': l10n?.continueText ?? 'Continue',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'subtitle': l10n?.offline ?? 'Offline',
        'icon': Icons.file_download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': l10n?.exams ?? 'Exams',
        'subtitle': l10n?.history ?? 'History',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/exams/history'),
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'subtitle': l10n?.awards ?? 'Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/certificates'),
      },
    ];

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final crossAxisCount = isDesktop
        ? 4
        : (isMobile ? 4 : 2); // 4 in a row for mobile too to be COMPACT

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {}, // Optional: more actions
              child: Text(l10n?.seeAll ?? 'See All',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 8 : 20,
            mainAxisSpacing: isMobile ? 8 : 20,
            childAspectRatio: isMobile ? 0.85 : 1.6,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickAccessCard(
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['onTap'] as Function,
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveActionCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, Function onTap) {
    return _QuickAccessCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildLearningAndOnboarding(
      BuildContext context, List<Enrollment> enrollments) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Column(
      children: [
        _buildContinueLearning(context, enrollments),
        const SizedBox(height: 24),
        _buildMyProgress(context, enrollments),
      ],
    );
  }

  // Desktop stats section for right column
  Widget _buildDesktopStatsSection(
      BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate statistics
    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.myProgress ?? 'My Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          _DesktopStatCard(
            icon: Icons.school_rounded,
            value: '$coursesEnrolled',
            label: l10n?.coursesEnrolled ?? 'Courses Enrolled',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.verified_rounded,
            value: '$coursesCompleted',
            label: l10n?.completed ?? 'Completed',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.auto_graph_rounded,
            value: '${averageProgress.toInt()}%',
            label: l10n?.averageScore ?? 'Average Score',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Desktop quick actions for right column
  Widget _buildDesktopQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final quickActions = [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'subtitle': l10n?.continueCourses ?? 'Continue Courses',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': l10n?.community ?? 'Community',
        'subtitle': 'Study with classmates',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF00C853),
        'onTap': () => context.push('/community'),
      },
      {
        'title': l10n?.library ?? 'Library',
        'subtitle': l10n?.browseResources ?? 'Browse Resources',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.go('/library'),
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'subtitle': l10n?.offlineContent ?? 'Offline Content',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'subtitle': l10n?.viewAwards ?? 'View Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/certificates'),
      },
      {
        'title': l10n?.examHistory ?? 'Exam History',
        'subtitle': l10n?.pastResults ?? 'Past Results',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.go('/exams/history'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ...quickActions
              .map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DesktopQuickActionCard(
                      title: action['title'] as String,
                      subtitle: action['subtitle'] as String,
                      icon: action['icon'] as IconData,
                      color: action['color'] as Color,
                      onTap: action['onTap'] as Function,
                      isDark: isDark,
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  Widget _buildMyProgress(BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    // Calculate statistics
    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.myProgress ?? 'My Progress',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Courses Enrolled Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFDCFCE7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$coursesEnrolled',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.coursesEnrolled ?? 'Courses Enrolled',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Courses Completed Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFDBEAFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$coursesCompleted',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.completed ?? 'Completed',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Average Score Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${averageProgress.toInt()}%',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.averageScore ?? 'Average Score',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickNavigationButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    // Simplified for mobile - only essential items not in header
    final quickActions = isMobile ? [
      {
        'title': 'Library',
        'subtitle': 'Browse Resources',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.go('/library'),
      },
      {
        'title': 'Downloads',
        'subtitle': 'Offline Content',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
    ] : [
      {
        'title': 'Library',
        'subtitle': 'Browse Resources',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.go('/library'),
      },
      {
        'title': 'Downloads',
        'subtitle': 'Offline Content',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': 'Exam History',
        'subtitle': 'Past Results',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.go('/exams/history'),
      },
      {
        'title': 'Discover',
        'subtitle': 'New Courses',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.go('/courses'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        // Responsive grid layout
        if (isMobile)
          // Modern horizontal scroll for mobile
          SizedBox(
            height: isSmallMobile ? 100 : 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < quickActions.length - 1 ? 12 : 0,
                  ),
                  child: _buildModernQuickActionCard(
                    context: context,
                    title: action['title'] as String,
                    subtitle: action['subtitle'] as String,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    onTap: action['onTap'] as Function,
                    isSmallMobile: isSmallMobile,
                  ),
                );
              },
            ),
          )
        else
          Row(
            children: quickActions
                .map((action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildQuickActionCard(
                          context: context,
                          title: action['title'] as String,
                          subtitle: action['subtitle'] as String,
                          icon: action['icon'] as IconData,
                          color: action['color'] as Color,
                          onTap: action['onTap'] as Function,
                          isFullWidth: false,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Function onTap,
    required bool isFullWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.getSecondaryTextColor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Modern horizontal card for mobile
  Widget _buildModernQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Function onTap,
    required bool isSmallMobile,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = isSmallMobile ? 140.0 : 160.0;

    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(isSmallMobile ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallMobile ? 36 : 40,
              height: isSmallMobile ? 36 : 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmallMobile ? 18 : 20,
              ),
            ),
            SizedBox(height: isSmallMobile ? 8 : 10),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallMobile ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isSmallMobile ? 10 : 11,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearning(
      BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    if (enrollments.isEmpty) {
      return const SizedBox.shrink(); // Hide if no enrollments
    }

    final lastEnrollment = enrollments.first;
    final course = lastEnrollment.course;
    if (course == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.continueLearning ?? 'Continue Learning',
              style: TextStyle(
                fontSize: isSmallMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-courses'),
              child: Text(
                l10n?.seeAll ?? 'See All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        course.thumbnail != null && course.thumbnail!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: NetworkImageWidget(
                                  imageUrl: course.thumbnail!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.play_circle_filled,
                                color: const Color(0xFF10B981),
                                size: 30,
                              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${course.displayInstructor}',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: isSmallMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      Text(
                        '${lastEnrollment.progress.toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: lastEnrollment.progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      CourseNavigationUtils.navigateToCourseWithContext(
                          context, ref, course),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.continueLearning ?? 'Continue Learning',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnrolledCourseCard(BuildContext context, Enrollment enrollment) {
    final course = enrollment.course;
    if (course == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    // Adjust dimensions based on device
    final imageHeight = isDesktop ? 110.0 : 100.0;
    final cardPadding = isMobile ? 12.0 : 16.0;
    final titleSize = isDesktop ? 15.0 : 14.0;

    return Container(
      height: 300, // Fixed height for uniform sizing
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : AppTheme.borderGrey.withOpacity(0.2),
        ),
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
              context, ref, course),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: isDark
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.primary.withOpacity(0.05),
                    child: course.thumbnail != null &&
                            course.thumbnail!.isNotEmpty
                        ? NetworkImageWidget(
                            imageUrl: course.thumbnail!,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(Icons.play_circle_filled,
                                color: AppTheme.primary, size: 40),
                          )
                        : const Icon(Icons.play_circle_filled,
                            color: AppTheme.primary, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                          color: AppTheme.getTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${course.displayInstructor}',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: isMobile ? 10 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (enrollment.accessExpirationDate != null) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CountdownTimer(
                            expirationDate: enrollment.accessExpirationDate,
                            showSeconds: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: isMobile ? 9 : 10,
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${enrollment.progress.toInt()}%',
                                style: TextStyle(
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: enrollment.progress / 100,
                              backgroundColor: isDark
                                  ? AppTheme.primary.withOpacity(0.15)
                                  : AppTheme.primary.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                              minHeight: isMobile ? 3 : 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // COURSE COLLECTIONS
  // Recommended and Popular share one card and one layout so every course
  // tile on the dashboard has exactly the same size and visual language.
  // ===========================================================================

  static const double _courseCardHeightMobile = 236;
  static const double _courseCardHeightWide = 248;
  static const double _courseCardWidthMobile = 172;
  static const double _courseCardMaxWidthWide = 214;
  static const double _courseCardSpacing = 14;

  Widget _buildRecommendedCourses(BuildContext context, List<Course> courses,
      List<Course> enrolledCourses) {
    final displayCourses = courses.take(8).toList();
    if (displayCourses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: l10n?.recommendedForYou ?? 'Recommended for you',
          subtitle: 'Picked from your interests',
          icon: Icons.auto_awesome_rounded,
          color: AppTheme.primary,
          onSeeAll: () => context.push('/courses'),
          seeAllLabel: l10n?.seeAll ?? 'See all',
        ),
        const SizedBox(height: 14),
        _buildCourseCollection(context, displayCourses, enrolledCourses),
      ],
    );
  }

  Widget _buildResponsivePopularCourses(BuildContext context,
      List<Course> popularCourses, List<Course> enrolledCourses) {
    if (popularCourses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: l10n?.popularCourses ?? 'Popular Courses',
          subtitle: 'Trending with learners right now',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFF97316),
          onSeeAll: () => context.push('/courses'),
          seeAllLabel: l10n?.seeAll ?? 'See all',
        ),
        const SizedBox(height: 14),
        _buildCourseCollection(context, popularCourses, enrolledCourses),
      ],
    );
  }

  /// Section title: bold heading, optional quiet subtitle and a green
  /// "View All ›" link. [icon]/[color] are kept for call-site readability;
  /// the editorial style deliberately leads with type, not icons.
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onSeeAll,
    String? seeAllLabel,
    bool compact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final link = isDark ? _Dx.mintGlow : _Dx.emerald;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 17 : (isMobile ? 19 : 21),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                  color: _Dx.text(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: _Dx.sub(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllLabel ?? 'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: link,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18, color: link),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Mobile: fixed-size horizontal carousel. Tablet/desktop: a grid whose
  /// tiles all share one fixed height (mainAxisExtent), capped at two rows.
  Widget _buildCourseCollection(
      BuildContext context, List<Course> courses, List<Course> enrolledCourses) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      final isSmall = ResponsiveBreakpoints.isSmallMobile(context);
      final cardWidth = isSmall ? 158.0 : _courseCardWidthMobile;
      return SizedBox(
        // Extra room so the soft card shadows are not clipped.
        height: _courseCardHeightMobile + 14,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 2, bottom: 12),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: cardWidth,
            height: _courseCardHeightMobile,
            child: _buildPremiumCourseCard(
                context, courses[index], enrolledCourses),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Same column maths SliverGridDelegateWithMaxCrossAxisExtent uses,
        // so we can cap the grid at exactly two full rows.
        final columns = ((constraints.maxWidth + _courseCardSpacing) /
                (_courseCardMaxWidthWide + _courseCardSpacing))
            .ceil()
            .clamp(2, 8);
        final visible = courses.take(columns * 2).toList();

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _courseCardMaxWidthWide,
            mainAxisExtent: _courseCardHeightWide,
            crossAxisSpacing: _courseCardSpacing,
            mainAxisSpacing: _courseCardSpacing + 4,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) =>
              _buildPremiumCourseCard(context, visible[index], enrolledCourses),
        );
      },
    );
  }

  String _formatCoursePrice(double price) {
    final digits = price.toStringAsFixed(0);
    final grouped = digits.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return 'RWF $grouped';
  }

  /// The single course tile used across the dashboard. Its parent always
  /// gives it a fixed size; every inner block has a fixed height too, so
  /// long titles or missing data never make one card differ from another.
  Widget _buildPremiumCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isEnrolled = enrolledCourses.any((c) => c.id == course.id);
    final price = course.price ?? 0;
    final isFree = price == 0;
    final rating = course.averageRating ?? 0.0;
    final categoryName = (course.category?['name'] as String?)?.trim();
    final hasThumb = course.thumbnail != null && course.thumbnail!.isNotEmpty;
    final thumbHeight = isMobile ? 104.0 : 116.0;

    final surface = isDark ? const Color(0xFF111C2E) : Colors.white;
    final border =
        isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EDF3);
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    final metaParts = <String>[
      if (course.duration > 0) '${course.duration} ${course.durationUnit}',
      if (course.level.isNotEmpty)
        course.level[0].toUpperCase() + course.level.substring(1),
    ];

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: EnhancedCourseNavigation(
        course: course,
        showRipple: true,
        enableHapticFeedback: true,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF0F172A))
                    .withOpacity(isDark ? 0.30 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Thumbnail --------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: thumbHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasThumb)
                          NetworkImageWidget(
                            imageUrl: course.thumbnail!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary.withOpacity(0.85),
                                  AppTheme.accent.withOpacity(0.85),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 34,
                            ),
                          ),
                        // Soft scrim so the badges stay legible on any image.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.22),
                                Colors.transparent,
                                Colors.black.withOpacity(0.28),
                              ],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: _buildCardBadge(
                            isEnrolled
                                ? 'Enrolled'
                                : (isFree ? 'Free' : 'Premium'),
                            isEnrolled
                                ? Icons.check_circle_rounded
                                : (isFree
                                    ? Icons.bolt_rounded
                                    : Icons.workspace_premium_rounded),
                            isEnrolled || isFree
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        if (rating > 0)
                          Positioned(
                            right: 7,
                            bottom: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: Color(0xFFFBBF24)),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Body ---------------------------------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (categoryName == null || categoryName.isEmpty)
                            ? 'COURSE'
                            : categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Fixed two-line slot keeps every card identical.
                      SizedBox(
                        height: 34,
                        child: Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -0.2,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12,
                              color: AppTheme.getSecondaryTextColor(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              metaParts.isEmpty
                                  ? 'Self-paced'
                                  : metaParts.join(' · '),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // --- Footer ---------------------------------------------
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEnrolled
                                  ? 'Continue'
                                  : (isFree ? 'Free' : _formatCoursePrice(price)),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: isEnrolled || isFree
                                    ? const Color(0xFF10B981)
                                    : AppTheme.getTextColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isEnrolled
                                  ? Icons.play_arrow_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCoursesGrid(BuildContext context,
      List<Course> courses, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildRecommendedCourseCard(
            context, courses[index], enrolledCourses);
      },
    );
  }

  Widget _buildModernCategorySection(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.exploreCategories ?? 'Explore Categories',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            if (!isMobile)
              TextButton(
                onPressed: () => context.push('/courses'),
                child: Text(
                  l10n?.viewAll ?? 'View All',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        categoriesAsync.when(
          data: (categories) {
            final displayCategories = isDesktop
                ? categories.take(6).toList()
                : categories.take(4).toList();
            return isDesktop
                ? _buildCategoryGrid(context, displayCategories)
                : _buildCategoryHorizontalList(context, displayCategories);
          },
          loading: () => _buildCategoryLoading(context),
          error: (_, __) => _buildCategoryError(context),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color =
            CategoryUtils.getCategoryColor(category.id, name: category.name);
        final icon =
            CategoryUtils.getCategoryIcon(category.id, name: category.name);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/courses', extra: {
                'categoryId': category.id,
                'categoryName': category.name,
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryHorizontalList(
      BuildContext context, List<Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final category = categories[index];
          final color =
              CategoryUtils.getCategoryColor(category.id, name: category.name);
          final icon =
              CategoryUtils.getCategoryIcon(category.id, name: category.name);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/courses', extra: {
                    'categoryId': category.id,
                    'categoryName': category.name,
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryLoading(BuildContext context) {
    return SizedBox(
      height: 100,
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildCategoryError(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Failed to load categories',
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final price = course.price ?? 0;
    final isFree = price == 0;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: isMobile ? 90 : 100,
                height: isMobile ? 90 : 100,
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? NetworkImageWidget(
                        imageUrl: course.thumbnail!,
                        fit: BoxFit.cover,
                        width: isMobile ? 90 : 100,
                        height: isMobile ? 90 : 100,
                      )
                    : Container(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Color(0xFF10B981),
                          size: 36,
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level badge
                    if (course.level.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.level[0].toUpperCase() +
                              course.level.substring(1),
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.displayInstructor,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFree
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFree ? 'FREE' : 'RWF ${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isFree
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isEnrolled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Enrolled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout',
              style: TextStyle(color: AppTheme.getTextColor(context))),
          content: Text('Are you sure you want to logout?',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withValues(alpha: 0.1), // FIX #8
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.2), // FIX #8
              width: 1,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
      BuildContext context, String title, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withValues(alpha: 0.1), // FIX #8
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.2), // FIX #8
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('Error loading data: $errorMessage',
                  style: const TextStyle(color: Colors.red, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  // FIX #5: Replaced Navigator.push with context.push for consistent go_router navigation.
  void _navigateToCategories(BuildContext context) =>
      context.push('/categories');

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.contact_support, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Text(l10n?.contactUs ?? 'Contact Us',
                style: TextStyle(color: AppTheme.getTextColor(context))),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: l10n?.whatsapp ?? 'WhatsApp',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchWhatsApp('250793828834')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: l10n?.whatsapp ?? 'WhatsApp',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchWhatsApp('250788535156')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchPhone('250788535156')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchPhone('250793828834')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '0781671517',
                    onTap: () => _launchPhone('0781671517')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.email,
                    title: l10n?.emailUs ?? 'Email Us',
                    subtitle: 'info@excellencecoachinghub.com',
                    onTap: () =>
                        _launchEmail('info@excellencecoachinghub.com')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.close ?? 'Close',
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context)))),
          ],
        );
      },
    );
  }

  Widget _buildContactMethod(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : AppTheme.primaryGreen.withValues(alpha: 0.05), // FIX #8
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : AppTheme.primaryGreen.withValues(alpha: 0.2),
              width: 1), // FIX #8
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getTextColor(context))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.getSecondaryTextColor(context), size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri(
        scheme: 'https',
        host: 'api.whatsapp.com',
        path: 'send',
        queryParameters: {'phone': phoneNumber});

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showWhatsAppFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showWhatsAppFallbackDialog(context, phoneNumber);
    }
  }

  void _showWhatsAppFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n?.whatsappNotAvailable ?? 'WhatsApp Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'WhatsApp is not installed or not accessible on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.phone,
                  title: 'Call Directly',
                  subtitle: phoneNumber,
                  onTap: () => _launchPhone(phoneNumber)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Number',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, phoneNumber, 'Phone number')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildFallbackOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.getTextColor(context))),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  // FIX #11: Implemented clipboard copy using flutter/services Clipboard API.
  Future<void> _copyToClipboard(
      BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label ${l10n?.copiedToClipboard ?? 'copied to clipboard'}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else if (context.mounted) {
        _showPhoneFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showPhoneFallbackDialog(context, phoneNumber);
    }
  }

  void _showPhoneFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.phone_disabled, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n?.callNotAvailable ?? 'Call Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.phoneCallsNotSupported ?? 'Phone calls are not supported on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.message,
                  title: 'WhatsApp Message',
                  subtitle: 'Send WhatsApp message',
                  onTap: () => _launchWhatsApp(phoneNumber)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Number',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, phoneNumber, 'Phone number')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else if (context.mounted) {
        _showEmailFallbackDialog(context, email);
      }
    } catch (_) {
      if (context.mounted) _showEmailFallbackDialog(context, email);
    }
  }

  void _showEmailFallbackDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.email_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n?.emailNotAvailable ?? 'Email Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.emailClientNotAvailable ?? 'Email client is not available on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Email',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, email, 'Email address')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  /// Compact header for small mobile devices (≤ 360px)
  Widget _buildSmallMobileHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text - stacked vertically for space
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user?.fullName ?? 'Student',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Compact action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.contact_support, size: 20),
                onPressed: () => _showContactInfoDialog(context),
                tooltip: 'Contact',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20),
                    if (ref
                        .watch(notificationProvider)
                        .notifications
                        .any((n) => !n.isRead))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notifications',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  await _refreshDashboard();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.refreshed ?? 'Refreshed'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    onTap: () => context.push('/profile'),
                    child: const Row(children: [
                      Icon(Icons.person_outline, size: 16),
                      SizedBox(width: 8),
                      Text('Profile', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    onTap: () => context.push('/settings'),
                    child: const Row(children: [
                      Icon(Icons.settings_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Settings', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const Row(children: [
                      Icon(Icons.logout, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Logout',
                          style: TextStyle(color: Colors.red, fontSize: 14)),
                    ]),
                  ),
                ],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header for standard mobile devices (361px - 768px)
  Widget _buildStandardMobileHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.fullName ?? 'Student',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Action row with better spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.contact_support, size: 22),
                onPressed: () => _showContactInfoDialog(context),
                tooltip: l10n?.contactUs ?? 'Contact Us',
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () async {
                  await _refreshDashboard();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.dashboardRefreshed ?? 'Dashboard refreshed'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Refresh Dashboard',
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 22),
                    if (ref
                        .watch(notificationProvider)
                        .notifications
                        .any((n) => !n.isRead))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notifications',
                padding: const EdgeInsets.all(8),
              ),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    onTap: () => context.push('/profile'),
                    child: const Row(children: [
                      Icon(Icons.person_outline, size: 17),
                      SizedBox(width: 9),
                      Text('Profile', style: TextStyle(fontSize: 15)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    onTap: () => context.push('/settings'),
                    child: const Row(children: [
                      Icon(Icons.settings_outlined, size: 17),
                      SizedBox(width: 9),
                      Text('Settings', style: TextStyle(fontSize: 15)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const Row(children: [
                      Icon(Icons.logout, color: Colors.red, size: 17),
                      SizedBox(width: 9),
                      Text('Logout',
                          style: TextStyle(color: Colors.red, fontSize: 15)),
                    ]),
                  ),
                ],
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Desktop stat card widget
class _DesktopStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _DesktopStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Desktop quick action card widget
class _DesktopQuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Function onTap;
  final bool isDark;

  const _DesktopQuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151).withOpacity(0.3)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Function onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

// ═══════════════════════════════════════════════════
//  DASHBOARD TOAST  (gamified popup)
// ═══════════════════════════════════════════════════
class _DashboardToast extends StatefulWidget {
  final String icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback onDismiss;

  const _DashboardToast({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_DashboardToast> createState() => _DashboardToastState();
}

class _DashboardToastState extends State<_DashboardToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.96,
        upperBound: 1.0)
      ..repeat(reverse: true);
    _pulse = _pulseCtrl;
    // Auto-dismiss after 5 s
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            isMobile ? 20 : 40, 0, isMobile ? 20 : 40, 48),
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: _pulse,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2333) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: widget.color.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: widget.color.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: Center(
                        child: Text(widget.icon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0D1117),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final scale = _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => widget.onTap(),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_isHovered ? 0.4 : 0.25),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  if (!isMobile) const Spacer(),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard design tokens: one emerald family, one ink, one line colour.
class _Dx {
  static const forest = Color(0xFF053B2C);
  static const pine = Color(0xFF065F46);
  static const emerald = Color(0xFF047857);
  static const jade = Color(0xFF059669);
  static const mintGlow = Color(0xFF6EE7B7);
  static const ink = Color(0xFF0B1B14);

  static Color canvas(bool dark) =>
      dark ? const Color(0xFF07111D) : const Color(0xFFF4F7F5);
  static Color surface(bool dark) =>
      dark ? const Color(0xFF111C2E) : Colors.white;
  static Color line(bool dark) =>
      dark ? Colors.white.withOpacity(0.07) : const Color(0xFFE6EDE9);
  static Color text(bool dark) => dark ? const Color(0xFFF1F5F9) : ink;
  static Color sub(bool dark) =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Two-layer shadow: a wide, faint forest-tinted ambient plus a tight
  /// contact shadow. [k] scales intensity.
  static List<BoxShadow> shadow(bool dark, {double k = 1}) => [
        BoxShadow(
          color: (dark ? Colors.black : forest)
              .withOpacity((dark ? 0.30 : 0.06) * k),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity((dark ? 0.18 : 0.03) * k),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static BoxDecoration panel(bool dark) => BoxDecoration(
        color: surface(dark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line(dark)),
        boxShadow: shadow(dark),
      );
}

/// Hero backdrop art: a soft light bloom and two hairline rings, top-right.
class _HeroHillsPainter extends CustomPainter {
  const _HeroHillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.92, h * 0.05);

    final bloomRadius = math.max(w, h) * 0.75;
    canvas.drawCircle(
      center,
      bloomRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF34D399).withOpacity(0.22),
            const Color(0xFF34D399).withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: bloomRadius)),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.07);
    canvas.drawCircle(center, w * 0.30, ring);
    canvas.drawCircle(center, w * 0.48, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round-capped progress ring with an emerald sweep.
class _ProgressRingPainter extends CustomPainter {
  final double value;
  final Color track;

  const _ProgressRingPainter({required this.value, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [_Dx.mintGlow, Color(0xFF10B981), _Dx.emerald],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.value != value || old.track != track;
}
