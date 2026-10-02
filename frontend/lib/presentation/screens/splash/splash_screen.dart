import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _isInitializing = true;
  String _loadingMessage = 'Initializing app...';
  bool _didNavigate = false;

  // Looping ambient animation (particles + glow)
  late AnimationController _animController;

  // Entrance animation — drives fade+slide for all content
  late AnimationController _entranceCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _pillFade;
  late Animation<Offset> _pillSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _illustrationFade;
  late Animation<double> _loadingFade;

  // Pulsing glow on the logo
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Shimmer sweep on the loading bar
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    // ── Ambient looping (particles) ───────────────────────────────────────
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // ── Entrance sequence ─────────────────────────────────────────────────
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade     = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.00, 0.35, curve: Curves.easeOut));
    _logoSlide    = Tween(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.00, 0.40, curve: Curves.easeOutCubic)));
    _pillFade     = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.20, 0.50, curve: Curves.easeOut));
    _pillSlide    = Tween(begin: const Offset(-0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic)));
    _headlineFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.35, 0.65, curve: Curves.easeOut));
    _headlineSlide= Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic)));
    _illustrationFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.55, 0.90, curve: Curves.easeOut));
    _loadingFade  = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.75, 1.00, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceCtrl.forward();
    });

    // ── Logo pulse ────────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Shimmer on loading bar ────────────────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Start initialization check
    _checkInitializationStatus();

    // Start listening for auth changes (delayed to avoid build conflicts)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });

    // NOTE: no navigation fallback timer.
    // Routing must wait for auth restoration to finish to avoid racing
    // against the async session restore.
  }

  @override
  void dispose() {
    _animController.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _checkInitializationStatus() {
    // Check if background services are ready
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _loadingMessage = 'Preparing your learning experience...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }
  
  Future<void> _navigateBasedOnAuth() async {
    if (_didNavigate) return;

    final authState = ref.read(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Only route when auth restoration is done.
    if (authState.isLoading) return;

    _didNavigate = true;

    // Check if user has selected language (for first-time users)
    final hasSelectedLanguage = await ref.read(localeProvider.notifier).hasSelectedLanguage();
    
    if (!hasSelectedLanguage && authState.user == null) {
      // First-time user - show language selection
      context.go('/language-selection');
      return;
    }

    if (authState.user != null) {
      final user = authState.user!;
      final nextStep = nextOnboardingRoute(user);

      if (user.role != 'admin' && user.role != 'instructor' &&
          (nextStep != null || !user.hasCompletedOnboarding)) {
        // Only the onboarding steps the user hasn't already answered.
        await continueAfterAuth(context, ref);
      } else {
        // Check if user has active (non-completed) courses
        try {
          final enrollmentsAsync = await ref.read(userEnrollmentsProvider.future);
          
          // Filter out completed courses to get active courses
          final activeEnrollments = enrollmentsAsync.where((enrollment) {
            return !enrollment.isCompleted;
          }).toList();
          
          if (activeEnrollments.isEmpty) {
            // No active courses - redirect to courses page to select a course
            context.go('/courses');
          } else {
            // Has active courses - go to dashboard
            context.go('/dashboard');
          }
        } catch (e) {
          // If there's an error checking enrolled courses, default to dashboard
          debugPrint('Error checking enrolled courses: $e');
          context.go('/dashboard');
        }
      }
    } else {
      if (isDesktop) {
        context.go('/email-auth-option');
      } else {
        context.go('/auth-selection');
      }
    }
  }

  void _checkAuthAndNavigate() {
    debugPrint('Splash: checkAuthAndNavigate');

    // Poll after first frame and then rely on authState.isLoading.
    // We also update the UI spinner independent of routing.
    Future.microtask(() async {
      if (!mounted) return;
      await _navigateBasedOnAuth();
    });

    // Listen to provider changes so navigation happens immediately
    // when auth restoration completes.
    ref.listenManual<AuthState>(authProvider, (previous, current) async {
      if (!mounted) return;
      _isInitializing = current.isLoading;
      if (!current.isLoading) {
        await _navigateBasedOnAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          _buildBackgroundImage(),
          // Gradient overlay
          _buildGradientOverlay(),
          // Floating animation
          _buildFloatingAnimation(),
          // Content
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    if (!isDesktop) {
      // Mobile: solid dark-green gradient — no image needed
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A0F),
              Color(0xFF0A2415),
              Color(0xFF071810),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/onboading desktop.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    if (!isDesktop) return const SizedBox.shrink(); // gradient already in background
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withOpacity(0.4),
            const Color(0xFF1E293B).withOpacity(0.6),
            const Color(0xFF0F172A).withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingAnimation() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value;
        return Stack(
          children: [
            // Glowing circles
            Positioned(
              top: -100 + 30 * sin(t * 2 * pi),
              right: -100 + 20 * cos(t * 2 * pi),
              child: _glowCircle(400, const Color(0xFF00C896).withOpacity(0.15), 70),
            ),
            Positioned(
              bottom: 80 + 40 * cos(t * 2 * pi + 1),
              left: -120 + 30 * sin(t * 2 * pi + 1),
              child: _glowCircle(300, const Color(0xFF34D399).withOpacity(0.1), 55),
            ),
            // Floating particles
            ...List.generate(12, (i) {
              final random = Random(i);
              final p = Offset(random.nextDouble(), random.nextDouble());
              final size = random.nextDouble() * 36 + 8;
              final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.15 + 0.08 * sin(t * 2 * pi + i),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _glowCircle(double size, Color color, double blur) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    // Wrapped in a scroll view with IntrinsicHeight so short/resized desktop
    // windows don't overflow the fixed-size logo/card content below - it still
    // centers normally once the window is tall enough to fit everything.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          // Left side - Logo and branding with modern glassmorphism
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo with glow effect
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00C896).withOpacity(0.3),
                          const Color(0xFF00C896).withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // App name with modern typography
                  const Text(
                    'Excellence',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Coaching Hub',
                    style: TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Color(0xFF00C896),
                          blurRadius: 30,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Transforming Education Through Technology',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem('10K+', 'Students'),
                      const SizedBox(width: 32),
                      _buildStatItem('500+', 'Courses'),
                      const SizedBox(width: 32),
                      _buildStatItem('98%', 'Success'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Right side - Loading and features with modern card design
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loading card with glassmorphism
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_isInitializing) ...[
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C896)),
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C896), Color(0xFF009E76)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C896).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Ready to go!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Feature cards grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.video_library_rounded,
                          title: 'Video Courses',
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.quiz_rounded,
                          title: 'Interactive Quizzes',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.verified_rounded,
                          title: 'Certifications',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.groups_rounded,
                          title: 'Expert Instructors',
                          color: const Color(0xFFF59E0B),
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
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00C896),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
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
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top bar: logo + name  (slide down + fade) ─────────────────────
        FadeTransition(
          opacity: _logoFade,
          child: SlideTransition(
            position: _logoSlide,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, isSmall ? 12 : 20, 20, 0),
              child: Row(
                children: [
                  // Pulsing logo
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.45),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.30),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Excellence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Coaching Hub',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: isSmall ? 10 : 16),

        // ── Journey pill (slide in from left + fade) ──────────────────────
        FadeTransition(
          opacity: _pillFade,
          child: SlideTransition(
            position: _pillSlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF34D399), size: 12),
                        SizedBox(width: 5),
                        Text(
                          'Your Journey to Excellence Starts Here',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: isSmall ? 8 : 12),

        // ── Headline (slide up + fade) ─────────────────────────────────────
        FadeTransition(
          opacity: _headlineFade,
          child: SlideTransition(
            position: _headlineSlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learn. Grow.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Succeed.',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: isSmall ? 5 : 8),
                  Text(
                    'Empowering learners with world-class\ncourses and expert guidance.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.60),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: isSmall ? 10 : 16),

        // ── Illustration — fade in, fills remaining space ──────────────────
        Expanded(
          child: FadeTransition(
            opacity: _illustrationFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(
                'assets/Course app-bro.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // ── Bottom loading bar with shimmer ───────────────────────────────
        FadeTransition(
          opacity: _loadingFade,
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.25),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment(_shimmer.value - 1, 0),
                    end: Alignment(_shimmer.value, 0),
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.13),
                      Colors.white.withOpacity(0.06),
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isInitializing) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      strokeWidth: 2,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _loadingMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Ready to go!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Helper widget for feature items
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _FeatureItem({
    required this.icon,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}
