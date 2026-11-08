import 'dart:async';

import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/wishlist_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_stats_provider.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // State variables
  bool _hasRedirected = false;
  bool _isPaymentLoading = false;
  bool _isEnrollmentLoading = false;

  // Payment status refresh
  static const Duration _paymentPollInterval = Duration(seconds: 10);
  Timer? _paymentPollTimer;
  bool _isRefreshing = false;
  bool _hasPendingPayment = false;
  bool _isForeground = true;
  DateTime? _lastCheckedAt;

  // Enroll button attention animation
  late final AnimationController _enrollPulseController;
  late final Animation<double> _enrollPulseScale;
  late final Animation<double> _enrollGlowStrength;

  // Localization
  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enrollPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _enrollPulseScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _enrollPulseController, curve: Curves.easeInOut),
    );
    _enrollGlowStrength = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _enrollPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _paymentPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _enrollPulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool isForeground = state == AppLifecycleState.resumed;
    if (isForeground == _isForeground) return;
    _isForeground = isForeground;

    // Coming back from the MoMo prompt is the most likely moment for the
    // payment to have been approved, so check straight away instead of waiting
    // for the next poll tick.
    if (isForeground && _hasPendingPayment) {
      _refreshStatus();
    }
    _syncAutoRefresh();
  }

  // ─── Payment Status Refresh ─────────────────────────────────────────────

  /// Polls only while a payment is actually awaiting approval and the screen is
  /// in the foreground - there is nothing to watch for otherwise.
  void _syncAutoRefresh() {
    final bool shouldPoll = _hasPendingPayment && _isForeground && !_hasRedirected;

    if (shouldPoll) {
      _paymentPollTimer ??= Timer.periodic(
        _paymentPollInterval,
        (_) => _refreshStatus(),
      );
    } else {
      _paymentPollTimer?.cancel();
      _paymentPollTimer = null;
    }
  }

  /// Re-checks payment, enrollment and course data. Used by the manual refresh
  /// button, pull-to-refresh and the background poll.
  Future<void> _refreshStatus({bool showFeedback = false}) async {
    if (_isRefreshing || !mounted) return;
    setState(() => _isRefreshing = true);

    final bool wasPending = _hasPendingPayment;

    try {
      ref.invalidate(hasPendingPaymentProvider(widget.courseId));
      ref.invalidate(isEnrolledInCourseProvider(widget.courseId));
      ref.invalidate(courseAccessProvider(widget.courseId));
      ref.invalidate(enrollmentStatusProvider(widget.courseId));
      ref.invalidate(courseStatsProvider(widget.courseId));
      ref.invalidate(_courseProvider(widget.courseId));

      final results = await Future.wait([
        ref.read(hasPendingPaymentProvider(widget.courseId).future),
        ref.read(isEnrolledInCourseProvider(widget.courseId).future),
      ]);
      final bool hasPending = results[0];
      final bool isEnrolled = results[1];

      if (!mounted) return;
      _lastCheckedAt = DateTime.now();

      // The redirect to the learning screen is driven by the enrollment watch
      // in build(); here we only explain what changed.
      if (wasPending && !hasPending && !isEnrolled) {
        _showStatusMessage(
          'Your payment is no longer pending. Please contact support if it was not approved.',
          Colors.orange,
        );
      } else if (showFeedback && !isEnrolled) {
        _showStatusMessage(
          hasPending
              ? 'Payment is still awaiting approval.'
              : 'Status updated.',
          hasPending ? Colors.orange : AppTheme.primaryGreen,
        );
      }
    } catch (e) {
      if (showFeedback && mounted) {
        _showStatusMessage('Could not refresh status: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showStatusMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _lastCheckedLabel() {
    final checkedAt = _lastCheckedAt;
    if (checkedAt == null) return 'Checking automatically';
    final seconds = DateTime.now().difference(checkedAt).inSeconds;
    if (seconds < 60) return 'Checked ${seconds}s ago';
    return 'Checked ${DateTime.now().difference(checkedAt).inMinutes}m ago';
  }

  // Course provider
  static final _courseProvider = FutureProvider.family<Course, String>((ref, courseId) async {
    final repository = ref.watch(courseRepositoryProvider);
    return await repository.getCourseById(courseId);
  });

  // ─── Helper Methods ─────────────────────────────────────────────────────

  String _formatDuration(Course course) {
    return course.formattedDuration;
  }

  String _formatAccessDuration(Course course) {
    if (course.accessDurationDays != null) {
      if (course.accessDurationDays! >= 365) return 'Lifetime';
      return '${course.accessDurationDays} Days';
    }
    
    if (course.accessDuration != null && course.accessDurationUnit != null) {
      String unit = course.accessDurationUnit!;
      if (unit.toLowerCase() == 'days') return '${course.accessDuration} Days';
      if (unit.toLowerCase() == 'months') return '${course.accessDuration} Months';
      if (unit.toLowerCase() == 'years') return course.accessDuration! >= 1 ? 'Lifetime' : '${course.accessDuration} Years';
    }
    
    return 'Lifetime';
  }

  // ─── Action Handlers ─────────────────────────────────────────────────────

  void _handleEnrollment(WidgetRef ref, String courseId) async {
    setState(() => _isEnrollmentLoading = true);
    ref.read(courseContentProvider(courseId).future);
    
    final enrollmentNotifier = ref.read(enrollmentNotifierProvider.notifier);
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(
        content: Text('Enrolling you in the course...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await enrollmentNotifier.enrollInCourse(courseId);
      
      if (ref.context.mounted && !_hasRedirected) {
        setState(() => _hasRedirected = true);
        ref.context.push('/learning/$courseId');
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Enrollment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrollmentLoading = false);
      }
    }
  }

  void _handlePayment(WidgetRef ref, Course course) async {
    setState(() => _isPaymentLoading = true);
    ref.read(courseContentProvider(course.id).future);
    
    final paymentNotifier = ref.read(paymentProvider.notifier);
    
    try {
      final paymentResponse = await paymentNotifier.initiatePayment(
        courseId: course.id,
        paymentMethod: 'mtn_momo',
        contactInfo: 'Student initiated payment for ${course.title}',
      );
          
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Payment initiated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(hasPendingPaymentProvider(course.id));
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (ref.context.mounted) {
          ref.context.go('/payment/pending', extra: {
            'course': course,
            'transactionId': paymentResponse.transactionId,
            'amount': paymentResponse.amount,
          });
        }
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentLoading = false);
      }
    }
  }

  void _handleShare(Course course) async {
    final String shareText = 'Check out this amazing course: ${course.title}\n'
        'Instructor: ${course.displayInstructor}\n'
        'Price: ${(course.price ?? 0) == 0 ? 'Free' : 'RWF ${(course.price ?? 0).toStringAsFixed(0)}'}\n'
        'Level: ${course.level}\n'
        'Duration: ${_formatDuration(course)}\n\n'
        'Download the Excellence Coaching Hub app: https://play.google.com/store/apps/details?id=com.excellencecoachinghub.app&pcampaignid=web_share';
    
    await Share.share(shareText, subject: 'Course Recommendation: ${course.title}');
  }

  // ─── Build Method ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(_courseProvider(widget.courseId));
    final isEnrolledAsync = ref.watch(isEnrolledInCourseProvider(widget.courseId));
    final pendingPaymentAsync = ref.watch(hasPendingPaymentProvider(widget.courseId));

    // Keep the auto-refresh in step with the pending payment state.
    _hasPendingPayment = pendingPaymentAsync.valueOrNull ?? _hasPendingPayment;
    _syncAutoRefresh();

    // Pre-fetch course content if enrolled
    isEnrolledAsync.whenData((isEnrolled) {
      if (isEnrolled) {
        ref.read(courseContentProvider(widget.courseId).future);
      }
    });

    // Auto-redirect if enrolled
    isEnrolledAsync.whenData((isEnrolled) {
      if (isEnrolled && context.mounted && !_hasRedirected) {
        setState(() => _hasRedirected = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.push('/learning/${widget.courseId}');
          }
        });
      }
    });

    // Redirect loading state
    if (_hasRedirected) {
      return _buildRedirectLoading();
    }

    return courseAsync.when(
      data: (course) => _buildCourseContent(course, isEnrolledAsync),
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(error),
    );
  }

  // ─── Loading States ─────────────────────────────────────────────────────

  Widget _buildRedirectLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final accentColor = const Color(0xFF10B981);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Redirecting to learning...',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
    final accentColor = const Color(0xFF10B981);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading course...',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final accentColor = const Color(0xFF10B981);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading course',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(courseId: widget.courseId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Main Content Builder ─────────────────────────────────────────────

  Widget _buildCourseContent(Course course, AsyncValue<bool> isEnrolledAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final accentColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _refreshStatus(showFeedback: true),
        color: accentColor,
        backgroundColor: cardColor,
        child: CustomScrollView(
          // Guarantees the pull-to-refresh gesture is available even when the
          // content is short enough not to scroll.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // Header
          _buildHeader(course, isDark, cardColor, textColor, dividerColor, accentColor),
          
          // Content sections
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.isDesktop(context)
                        ? 840
                        : ResponsiveBreakpoints.isTablet(context)
                            ? 680
                            : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
                      vertical: 20,
                    ).copyWith(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceSection(course, isDark, textColor, accentColor, l10n),
                        const SizedBox(height: 12),
                        _buildEnrollSection(course, isEnrolledAsync, isDark, accentColor, l10n),
                        const SizedBox(height: 20),
                        if (course.category != null && course.category!['name'] != null)
                          _buildCategoryCard(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor),
                        const SizedBox(height: 20),
                        _buildCourseStats(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor),
                        const SizedBox(height: 20),
                        _buildDescription(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor, l10n),
                        const SizedBox(height: 20),
                        if (course.learningObjectives != null && course.learningObjectives!.isNotEmpty)
                          _buildLearningObjectives(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor, accentColor, l10n),
                        const SizedBox(height: 20),
                        if (course.requirements != null && course.requirements!.isNotEmpty)
                          _buildRequirements(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor, l10n),
                        const SizedBox(height: 20),
                        _buildInstructorInfo(course, isDark, cardColor, textColor, secondaryTextColor, dividerColor, accentColor, l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // ─── Header Section ─────────────────────────────────────────────────────

  Widget _buildHeader(Course course, bool isDark, Color cardColor, Color textColor, Color dividerColor, Color accentColor) {
    return SliverAppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      elevation: 0,
      leading: _buildHeaderButton(Icons.arrow_back_ios_rounded, textColor, dividerColor, cardColor, () => context.pop()),
      actions: [
        _buildRefreshButton(textColor, dividerColor, cardColor, accentColor),
        _buildBookmarkButton(course, isDark, cardColor, textColor, dividerColor, accentColor),
        _buildHeaderButton(Icons.share_outlined, textColor, dividerColor, cardColor, () => _handleShare(course)),
      ],
      expandedHeight: 240,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildCourseImage(course, isDark, accentColor),
            _buildGradientOverlay(isDark),
            _buildCourseInfoOverlay(course),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, Color textColor, Color dividerColor, Color cardColor, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: IconButton(icon: Icon(icon, color: textColor, size: 20), onPressed: onPressed),
    );
  }

  Widget _buildRefreshButton(Color textColor, Color dividerColor, Color cardColor, Color accentColor) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: IconButton(
        tooltip: 'Refresh payment status',
        icon: _isRefreshing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
              )
            : Icon(Icons.refresh_rounded, color: textColor, size: 20),
        onPressed: _isRefreshing ? null : () => _refreshStatus(showFeedback: true),
      ),
    );
  }

  Widget _buildBookmarkButton(Course course, bool isDark, Color cardColor, Color textColor, Color dividerColor, Color accentColor) {
    return Consumer(
      builder: (context, ref, child) {
        final isBookmarkedAsync = ref.watch(isCourseInWishlistProvider(widget.courseId));
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: IconButton(
            icon: isBookmarkedAsync.when(
              data: (isBookmarked) => Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? accentColor : textColor,
                size: 20,
              ),
              loading: () => Icon(Icons.bookmark_border, color: textColor, size: 20),
              error: (error, stack) => Icon(Icons.bookmark_border, color: textColor, size: 20),
            ),
            onPressed: () {
              final wishlistNotifier = ref.read(wishlistNotifierProvider.notifier);
              wishlistNotifier.toggleCourse(widget.courseId, course);
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseImage(Course course, bool isDark, Color accentColor) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
      child: course.thumbnail != null && course.thumbnail!.trim().isNotEmpty
          ? NetworkImageWidget(
              imageUrl: course.thumbnail!.trim(),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_circle_outline, color: accentColor, size: 64),
              ),
            ),
    );
  }

  Widget _buildGradientOverlay(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            isDark ? Colors.black.withOpacity(0.7) : Colors.black.withOpacity(0.2),
          ],
          stops: const [0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildCourseInfoOverlay(Course course) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
              shadows: [
                Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black26),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Text(
                  course.averageRating != null && course.averageRating! > 0 
                    ? course.averageRating!.toStringAsFixed(1) 
                    : '4.8',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Content Sections ─────────────────────────────────────────────────────

  Widget _buildPriceSection(Course course, bool isDark, Color textColor, Color accentColor, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFD1FAE5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.coursePrice ?? 'Price',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF047857),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (course.price ?? 0) == 0 ? 'FREE' : 'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: (course.price ?? 0) == 0 ? accentColor : const Color(0xFF047857),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((course.price ?? 0) != 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'RWF ${((course.price ?? 0) * 1.2).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (course.averageRating != null && course.averageRating! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    course.averageRating!.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.category_outlined, color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.category!['name'],
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor) {
    return Consumer(
      builder: (context, ref, child) {
        final enrollmentCountAsync = ref.watch(courseStatsProvider(course.id));
        
        return enrollmentCountAsync.when(
          data: (enrollmentCount) {
            final stats = [
              {'icon': Icons.access_time_outlined, 'value': _formatDuration(course), 'label': 'Duration', 'color': const Color(0xFF667eea)},
              {'icon': Icons.speed_outlined, 'value': course.level, 'label': 'Level', 'color': const Color(0xFF764ba2)},
              {'icon': Icons.people_outline, 'value': enrollmentCount.toString(), 'label': 'Students', 'color': const Color(0xFFf093fb)},
              {'icon': Icons.update_outlined, 'value': _formatAccessDuration(course), 'label': 'Access', 'color': const Color(0xFF10B981)},
            ];
            return _buildStatsList(stats, textColor, secondaryTextColor, cardColor, dividerColor, isDark);
          },
          loading: () {
            final stats = [
              {'icon': Icons.access_time_outlined, 'value': _formatDuration(course), 'label': 'Duration', 'color': const Color(0xFF667eea)},
              {'icon': Icons.speed_outlined, 'value': course.level, 'label': 'Level', 'color': const Color(0xFF764ba2)},
              {'icon': Icons.people_outline, 'value': '...', 'label': 'Students', 'color': const Color(0xFFf093fb)},
              {'icon': Icons.update_outlined, 'value': _formatAccessDuration(course), 'label': 'Access', 'color': const Color(0xFF10B981)},
            ];
            return _buildStatsList(stats, textColor, secondaryTextColor, cardColor, dividerColor, isDark);
          },
          error: (error, stack) {
            final stats = [
              {'icon': Icons.access_time_outlined, 'value': _formatDuration(course), 'label': 'Duration', 'color': const Color(0xFF667eea)},
              {'icon': Icons.speed_outlined, 'value': course.level, 'label': 'Level', 'color': const Color(0xFF764ba2)},
              {'icon': Icons.people_outline, 'value': (course.enrollmentCount ?? 0).toString(), 'label': 'Students', 'color': const Color(0xFFf093fb)},
              {'icon': Icons.update_outlined, 'value': _formatAccessDuration(course), 'label': 'Access', 'color': const Color(0xFF10B981)},
            ];
            return _buildStatsList(stats, textColor, secondaryTextColor, cardColor, dividerColor, isDark);
          },
        );
      },
    );
  }

  Widget _buildStatsList(List<Map<String, dynamic>> stats, Color textColor, Color secondaryTextColor, Color cardColor, Color dividerColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isMobile ? 1.3 : 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                return _buildStatItem(stats[index], textColor, secondaryTextColor, cardColor, dividerColor, isDark);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat, Color textColor, Color secondaryTextColor, Color cardColor, Color dividerColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat['icon'], color: stat['color'], size: 18),
          const SizedBox(height: 6),
          Text(
            stat['value'],
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat['label'],
            style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.aboutThisCourse ?? 'About',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          course.description,
          style: TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLearningObjectives(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor, Color accentColor, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.whatYouWillLearn ?? 'What You\'ll Learn',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...course.learningObjectives!.asMap().entries.map((entry) {
          final objective = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: accentColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(objective, style: TextStyle(color: secondaryTextColor, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRequirements(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.requirements ?? 'Requirements',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...course.requirements!.asMap().entries.map((entry) {
          final requirement = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: const Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(requirement, style: TextStyle(color: secondaryTextColor, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInstructorInfo(Course course, bool isDark, Color cardColor, Color textColor, Color secondaryTextColor, Color dividerColor, Color accentColor, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.meetYourInstructor ?? 'Instructor',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  course.displayInstructor.split(' ').map((n) => n[0]).join('').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.displayInstructor,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Course Creator',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnrollSection(Course course, AsyncValue<bool> isEnrolledAsync, bool isDark, Color accentColor, AppLocalizations? l10n) {
    return isEnrolledAsync.when(
      data: (isEnrolled) {
        return isEnrolled 
          ? _buildContinueLearningButton(course, isDark, l10n) 
          : _buildEnrollButton(course, isDark, accentColor, l10n);
      },
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            l10n?.checkingEnrollment ?? 'Checking...',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF047857),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      error: (error, stack) => _buildEnrollButton(course, isDark, accentColor, l10n),
    );
  }

  Widget _buildEnrollButton(Course course, bool isDark, Color accentColor, AppLocalizations? l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final hasPendingPayment = ref.watch(hasPendingPaymentProvider(course.id));

        return hasPendingPayment.when(
          data: (hasPending) {
            if (hasPending) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 56, child: _buildPaymentPendingButton(isDark)),
                  const SizedBox(height: 8),
                  _buildPaymentCheckStatus(isDark, accentColor),
                ],
              );
            }

            return _buildPurchaseOrReenroll(ref, course, isDark, accentColor, l10n);
          },
          loading: () => SizedBox(height: 56, child: _buildLoadingButton(isDark)),
          error: (error, stack) => _buildPurchaseOrReenroll(ref, course, isDark, accentColor, l10n),
        );
      },
    );
  }

  /// Enroll / pay for learners new to the course, "Re-enroll" for learners who
  /// left it (free courses, or paid ones still covered by their original
  /// payment), and a notice when an administrator has suspended access.
  Widget _buildPurchaseOrReenroll(WidgetRef ref, Course course, bool isDark, Color accentColor, AppLocalizations? l10n) {
    final statusInfo = ref.watch(enrollmentStatusProvider(course.id)).valueOrNull;
    final isFree = (course.price ?? 0) == 0;

    if (statusInfo?.isSuspended == true) {
      return _buildSuspendedNotice(isDark);
    }

    final canReenroll = statusInfo?.isUnenrolled == true &&
        (isFree || statusInfo!.canReenrollWithoutPayment);
    final isLoading = (isFree || canReenroll) ? _isEnrollmentLoading : _isPaymentLoading;

    final button = SizedBox(
      height: 56,
      child: _buildPurchaseButton(course, isFree, isLoading, isDark, accentColor, l10n, reenroll: canReenroll),
    );
    if (!canReenroll) return button;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 8),
        Text(
          'Welcome back! Your previous progress will be restored.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSuspendedNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your access to this course has been suspended by an administrator. Please contact support.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows that the pending payment is being watched automatically, plus an
  /// escape hatch for users who do not want to wait for the next tick.
  Widget _buildPaymentCheckStatus(bool isDark, Color accentColor) {
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: _isRefreshing
              ? CircularProgressIndicator(strokeWidth: 2, color: accentColor)
              : Icon(Icons.autorenew_rounded, size: 14, color: secondaryTextColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isRefreshing ? 'Checking payment status...' : _lastCheckedLabel(),
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: _isRefreshing ? null : () => _refreshStatus(showFeedback: true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Check now',
            style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPendingButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextButton(
        onPressed: () {
          final ref = context as WidgetRef;
          final courseAsync = ref.read(_courseProvider(widget.courseId));
          courseAsync.whenData((course) {
            if (context.mounted) {
              context.go('/payment/pending', extra: {
                'course': course,
                'transactionId': 'pending',
                'amount': course?.price ?? 0.0,
              });
            }
          });
        },
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Payment Pending',
            maxLines: 1,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(Course course, bool isFree, bool isLoading, bool isDark, Color accentColor, AppLocalizations? l10n, {bool reenroll = false}) {
    // A punchy, high-contrast color pair so the CTA reads clearly against both
    // the light and dark backgrounds behind it.
    final greenStyle = isFree || reenroll;
    final glowColor = greenStyle ? const Color(0xFF00E676) : const Color(0xFFFF7A00);
    final gradientColors = greenStyle
        ? const [Color(0xFF00E676), Color(0xFF00C853)]
        : const [Color(0xFFFF9100), Color(0xFFFF6D00)];

    return AnimatedBuilder(
      animation: _enrollPulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: isLoading ? 1.0 : _enrollPulseScale.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.25 : 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(isLoading ? 0.3 : _enrollGlowStrength.value),
                  blurRadius: 22,
                  spreadRadius: isLoading ? 0 : 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          final ref = context as WidgetRef;
          if (isFree || reenroll) {
            _handleEnrollment(ref, course.id);
          } else {
            _handlePayment(ref, course);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.isSmallMobile(context) ? 16 : 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reenroll
                          ? 'Re-enroll'
                          : isFree ? (l10n?.enrollNow ?? 'Enroll Now') : '${l10n?.buyNow ?? 'Pay'} ${(course.price ?? 0).toStringAsFixed(0)} RWF',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          'Checking...',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF047857),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearningButton(Course course, bool isDark, AppLocalizations? l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final courseAccessAsync = ref.watch(courseAccessProvider(course.id));
        
        return Column(
          children: [
            courseAccessAsync.when(
              data: (accessData) {
                if (accessData != null && accessData['accessExpirationDate'] != null) {
                  try {
                    final expirationDateString = accessData['accessExpirationDate'];
                    DateTime expirationDate;
                    
                    if (expirationDateString is String) {
                      expirationDate = DateTime.parse(expirationDateString);
                    } else if (expirationDateString is int) {
                      expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationDateString);
                    } else {
                      return const SizedBox.shrink();
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CountdownTimer(
                        expirationDate: expirationDate,
                        onExpiration: () {
                          print('Course access has expired');
                        },
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  context.push('/learning/${course.id}');
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n?.continueLearning ?? 'Continue Learning',
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
