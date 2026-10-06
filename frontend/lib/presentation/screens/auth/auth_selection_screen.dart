import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';

const _kAccent = Color(0xFF10B981);
const _kAccentLight = Color(0xFF34D399);
const _kSurface = Color(0xFFF5F7FA);
const _kText2 = Color(0xFF4A5568);
const _kAmber = Color(0xFFF59E0B);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFDE68A);

// ─── Floating shapes background ─────────────────────────────────────────────

class _FloatingBackground extends StatefulWidget {
  final bool compact;
  const _FloatingBackground({this.compact = false});
  @override
  State<_FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<_FloatingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _particles = List.generate(
      15, (i) => Offset(Random().nextDouble(), Random().nextDouble()));
  final List<double> _particleSizes =
      List.generate(15, (i) => Random().nextDouble() * 40 + 10);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          children: [
            // Large blurred blobs
            Positioned(
              top: -100 + (30 * sin(t * 2 * pi)),
              right: -100 + (20 * cos(t * 2 * pi)),
              child: _GlowCircle(
                size: widget.compact ? 300 : 500,
                color: _kAccent.withOpacity(0.08),
                blur: 80,
              ),
            ),
            Positioned(
              bottom: 100 + (40 * cos(t * 2 * pi + 1)),
              left: -120 + (30 * sin(t * 2 * pi + 1)),
              child: _GlowCircle(
                size: widget.compact ? 250 : 400,
                color: _kAccentLight.withOpacity(0.06),
                blur: 60,
              ),
            ),
            // Bokeh particles
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              final s = _particleSizes[i];
              final y = (p.dy + (t * 0.1 * (i % 3 + 1))) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.15 + (0.1 * sin(t * 2 * pi + i)),
                  child: Container(
                    width: s,
                    height: s,
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
}

// ─── Glow circle ─────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;
  const _GlowCircle({required this.size, required this.color, this.blur = 0});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: blur > 0 ? null : color,
          boxShadow: blur > 0
              ? [
                  BoxShadow(
                    color: color,
                    blurRadius: blur,
                    spreadRadius: blur / 2,
                  )
                ]
              : null,
        ),
      );
}

// ─── Minimal Branding section (mobile-optimized) ────────────────────────────────────────────────────────

class _MinimalBrandingSection extends StatelessWidget {
  final bool isDark;
  const _MinimalBrandingSection({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4B5563);
    final brandGreen =
        isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 360;
    final isMobile = screenWidth <= 768;

    final logoSize = isSmallMobile ? 60.0 : (isMobile ? 72.0 : 80.0);
    final titleFontSize = isSmallMobile ? 24.0 : (isMobile ? 27.0 : 28.0);
    final subtitleFontSize = isSmallMobile ? 15.0 : (isMobile ? 16.0 : 17.0);
    final taglineFontSize = isSmallMobile ? 12.5 : (isMobile ? 13.5 : 14.0);
    final verticalSpacing = isSmallMobile ? 12.0 : (isMobile ? 14.0 : 16.0);
    final smallSpacing = isSmallMobile ? 6.0 : 8.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo - responsive sizing
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // White backdrop keeps the logo's own colours legible on the dark theme.
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF10B981).withOpacity(isDark ? 0.35 : 0.15),
                blurRadius: isSmallMobile ? 15 : 20,
                spreadRadius: isSmallMobile ? 1 : 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: EdgeInsets.all(logoSize * 0.1),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Icon(
                  Icons.school_rounded,
                  color: const Color(0xFF10B981),
                  size: logoSize * 0.45,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: verticalSpacing),

        // Title - responsive typography
        Text(
          'Excellence',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        Text(
          'Coaching Hub',
          style: TextStyle(
            color: brandGreen,
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: smallSpacing),
        Text(
          l10n?.authLearnGrowSucceed ?? 'Kwiga • Kukura • Kunesha',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: taglineFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Minimal Auth card (clean, modern, spacious) ────────────────────────────────────────────────────────────────

class _MinimalAuthCard extends StatelessWidget {
  final bool isLoading;
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final bool isPhoneLoading;
  final String? error;
  final VoidCallback onEmail;
  final VoidCallback? onGoogle;
  final VoidCallback? onPhone;
  final bool isDark;

  const _MinimalAuthCard({
    required this.isLoading,
    required this.isEmailLoading,
    required this.isGoogleLoading,
    required this.isPhoneLoading,
    required this.error,
    required this.onEmail,
    this.onGoogle,
    this.onPhone,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);
    final dividerColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final orTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 360;
    final isMobile = screenWidth <= 768;

    final headerFontSize = isSmallMobile ? 22.0 : (isMobile ? 23.0 : 24.0);
    final subtitleFontSize = isSmallMobile ? 13.5 : (isMobile ? 14.0 : 15.0);
    final sectionSpacing = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 24.0);
    final smallSpacing = isSmallMobile ? 4.0 : 6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clean header
        Text(
          l10n?.signIn ?? 'Injira',
          style: TextStyle(
            color: textColor,
            fontSize: headerFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: smallSpacing),
        Text(
          l10n?.authSelectionSubtitle ??
              'Hitamo uburyo ushaka gukoresha ukomeze',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: subtitleFontSize,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: sectionSpacing),

        // Error message display - responsive and overflow-safe
        if (error != null && error!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
            padding: EdgeInsets.all(isSmallMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                  size: isSmallMobile ? 16 : 18,
                ),
                SizedBox(width: isSmallMobile ? 6 : 8),
                Expanded(
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF991B1B),
                      fontSize: isSmallMobile ? 12.5 : 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Phone Auth - Primary (Green theme)
        _ModernAuthButton(
          icon: Icons.phone_rounded,
          label: l10n?.continueWithPhone ?? 'Komeza na Telefone',
          isLoading: isPhoneLoading,
          onPressed: isLoading ? null : onPhone,
          isDark: isDark,
          accentColor: const Color(0xFF10B981),
          iconBgColor: isDark
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFD1FAE5),
        ),

        SizedBox(height: isSmallMobile ? 8 : 10),

        // Google Auth with proper G icon
        if (onGoogle != null && !kIsWeb) ...[
          _ModernAuthButton(
            icon: Icons.phone_rounded, // Placeholder, will use custom widget
            label: l10n?.continueWithGoogle ?? 'Komeza na Google',
            isLoading: isGoogleLoading,
            onPressed: !isLoading ? onGoogle : null,
            isDark: isDark,
            accentColor: const Color(0xFF4285F4),
            iconBgColor: isDark
                ? const Color(0xFF4285F4).withOpacity(0.2)
                : const Color(0xFFDBEAFE),
            customIcon: const _GoogleGIcon(size: 20),
          ),
          SizedBox(height: isSmallMobile ? 8 : 10),
        ],

        // OR Divider - modern style
        Padding(
          padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 2 : 4),
          child: Row(
            children: [
              Expanded(
                  child: Divider(color: dividerColor, thickness: 1, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n?.or ?? 'OR',
                  style: TextStyle(
                    color: orTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                  child: Divider(color: dividerColor, thickness: 1, height: 1)),
            ],
          ),
        ),
        SizedBox(height: isSmallMobile ? 8 : 10),

        // Email Auth (Blue theme)
        _ModernAuthButton(
          icon: Icons.email_outlined,
          label: l10n?.continueWithEmail ?? 'Komeza na Email',
          isLoading: isEmailLoading,
          onPressed: isLoading ? null : onEmail,
          isDark: isDark,
          accentColor: const Color(0xFF3B82F6),
          iconBgColor: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : const Color(0xFFDBEAFE),
        ),

        SizedBox(height: sectionSpacing),

        // Simple privacy note - compact and overflow-safe
        LayoutBuilder(builder: (context, constraints) {
          final isVeryNarrow = constraints.maxWidth < 320;
          final fontSize = isVeryNarrow ? 10.5 : (isSmallMobile ? 11.5 : 13.0);
          final iconSize = isVeryNarrow ? 10.0 : (isSmallMobile ? 12.0 : 14.0);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: iconSize,
                color:
                    isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              ),
              SizedBox(width: isVeryNarrow ? 3 : (isSmallMobile ? 4 : 6)),
              Flexible(
                child: Text(
                  l10n?.accountBoundToDevice ?? 'Account bound to this device',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Google G Icon (CustomPainter) ────────────────────────────────────────────────────────────────

class _GoogleGIcon extends StatelessWidget {
  final double size;
  const _GoogleGIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double strokeWidth = w * 0.18;
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      w - strokeWidth,
      h - strokeWidth,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Google brand colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    // Blue arc (right side)
    paint.color = blue;
    canvas.drawArc(rect, -0.6, 1.4, false, paint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.5),
      Offset(w * 0.95, h * 0.5),
      barPaint,
    );

    // Green arc (bottom)
    paint.color = green;
    canvas.drawArc(rect, 0.9, 1.5, false, paint);

    // Yellow arc (left)
    paint.color = yellow;
    canvas.drawArc(rect, 2.5, 1.3, false, paint);

    // Red arc (top)
    paint.color = red;
    canvas.drawArc(rect, 3.8, 1.7, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─── Modern Auth Button (attractive with smaller text, custom icons) ────────────────────────────────────────────────────────────────

class _ModernAuthButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;
  final Color accentColor;
  final Color iconBgColor;
  final Widget? customIcon;

  const _ModernAuthButton({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.isDark = false,
    required this.accentColor,
    required this.iconBgColor,
    this.customIcon,
  });

  @override
  State<_ModernAuthButton> createState() => _ModernAuthButtonState();
}

class _ModernAuthButtonState extends State<_ModernAuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark
        ? const Color(0xFF334155).withOpacity(0.5)
        : const Color(0xFFE5E7EB);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1F2937);

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 360;
    final isMobile = screenWidth <= 768;

    final buttonHeight = isSmallMobile ? 48.0 : (isMobile ? 52.0 : 54.0);
    final iconSize = isSmallMobile ? 30.0 : (isMobile ? 34.0 : 36.0);
    final iconInnerSize = isSmallMobile ? 16.0 : (isMobile ? 18.0 : 19.0);
    final fontSize = isSmallMobile ? 14.0 : (isMobile ? 15.0 : 15.5);
    final horizontalPadding = isSmallMobile ? 10.0 : 14.0;
    final iconSpacing = isSmallMobile ? 8.0 : 12.0;
    final arrowSize = isSmallMobile ? 14.0 : 16.0;
    final loaderSize = isSmallMobile ? 16.0 : 18.0;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: loaderSize,
                    height: loaderSize,
                    child: CircularProgressIndicator(
                      strokeWidth: isSmallMobile ? 1.5 : 2,
                      valueColor: AlwaysStoppedAnimation(widget.accentColor),
                    ),
                  )
                else
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: widget.iconBgColor,
                      borderRadius:
                          BorderRadius.circular(isSmallMobile ? 8 : 10),
                    ),
                    child: widget.customIcon ??
                        Icon(widget.icon,
                            color: widget.accentColor, size: iconInnerSize),
                  ),
                SizedBox(width: iconSpacing),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: widget.isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  size: arrowSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  _AuthSelectionScreenState createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends ConsumerState<AuthSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _listenerRegistered = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : _kSurface;
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _secondaryTextColor => _isDark ? Colors.white70 : _kText2;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasNavigated) _checkAndNavigate();
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listenManual(authProvider, (_, current) {
        if (current.user != null && !current.isLoading && !_hasNavigated) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _checkAndNavigate());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuthSelectionScreen old) {
    super.didUpdateWidget(old);
    if (!_hasNavigated) _checkAndNavigate();
  }

  void _checkAndNavigate() async {
    final authState = ref.read(authProvider);
    // Gate navigation behind full auth restoration.
    // Prevents onboarding/home routing from firing while user is still null/loading.
    if (authState.user != null && !authState.isLoading && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await continueAfterAuth(context, ref);
      });
    }
  }

  void _handleGoogleSignIn() async {
    try {
      debugPrint('Screen: Starting Google Sign-In');
      await ref.read(authProvider.notifier).signInWithGoogle();
      debugPrint('Screen: Google Sign-In completed');
    } catch (e) {
      debugPrint('Google Sign-In error in screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isDesktop ? _desktopLayout(authState) : _mobileLayout(authState),
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _desktopLayout(dynamic authState) {
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel (45%)
          const Expanded(
            flex: 45,
            child: DesktopBrandPanel(
              headline: 'Welcome to',
              title: 'Excellence\nCoaching Hub',
              tagline: 'Empowering Growth.\nInspiring Excellence.',
            ),
          ),
          // Right auth panel (55%) - theme-aware
          Expanded(
            flex: 55,
            child: Container(
              color: _cardColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 60),
                    child: _MinimalAuthCard(
                      isLoading: authState.isLoading,
                      isEmailLoading: authState.isEmailLoading,
                      isGoogleLoading: authState.isGoogleLoading,
                      isPhoneLoading: authState.isPhoneLoading,
                      error: authState.error,
                      onEmail: () => context.push('/email-auth-option'),
                      onGoogle: null,
                      onPhone: () => context.push('/phone-auth'),
                      isDark: _isDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStat(String value, String label) {
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

  // ── Mobile layout (attractive with dynamic background, responsive card) ─────────────────────────────────────────────────────────

  Widget _mobileLayout(dynamic authState) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallMobile = screenWidth <= 360;
    final isShort = screenHeight < 700;
    final isVeryShort = screenHeight < 600;

    // Responsive padding values
    final horizontalPadding = isSmallMobile ? 12.0 : 16.0;
    final topSpacing = isVeryShort ? 8.0 : (isShort ? 12.0 : 24.0);
    final brandingSpacing = isVeryShort ? 12.0 : (isShort ? 16.0 : 32.0);
    final cardPadding = isSmallMobile ? 16.0 : 20.0;
    final cardBorderRadius = isSmallMobile ? 16.0 : 20.0;
    final bottomSpacing = isVeryShort ? 8.0 : (isShort ? 12.0 : 16.0);
    final footerSpacing = isVeryShort ? 6.0 : (isShort ? 8.0 : 12.0);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        // Dynamic gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFECFDF5),
                    const Color(0xFFD1FAE5),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // Top spacing
                SizedBox(height: topSpacing),

                // Minimal branding
                _MinimalBrandingSection(isDark: _isDark),

                SizedBox(height: brandingSpacing),

                // Auth card - responsive with modern styling
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                      border: _isDark
                          ? Border.all(
                              color: const Color(0xFF334155).withOpacity(0.5),
                              width: 1)
                          : Border.all(color: Colors.white, width: 1),
                      boxShadow: _isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.08),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(cardPadding),
                      child: _MinimalAuthCard(
                        isLoading: authState.isLoading,
                        isEmailLoading: authState.isEmailLoading,
                        isGoogleLoading: authState.isGoogleLoading,
                        isPhoneLoading: authState.isPhoneLoading,
                        error: authState.error,
                        onEmail: () => context.push('/email-auth-option'),
                        onGoogle: _handleGoogleSignIn,
                        onPhone: () => context.push('/phone-auth'),
                        isDark: _isDark,
                      ),
                    ),
                  ),
                ),

                // Bottom terms text
                SizedBox(height: bottomSpacing),
                _MinimalTermsFooter(),
                SizedBox(height: footerSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _MinimalTermsFooter() {
    // Responsive font sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 360;
    final fontSize = isSmallMobile ? 11.0 : 12.5;

    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: _secondaryTextColor,
          fontSize: fontSize,
          height: 1.4,
        ),
        children: [
          TextSpan(
              text:
                  '${AppLocalizations.of(context)?.byContinuing ?? "Ukomeza, wemeza"} '),
          TextSpan(
            text: AppLocalizations.of(context)?.termsOfService ??
                'Amategeko ya Serivisi',
            style: TextStyle(
              color:
                  _isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          TextSpan(text: ' ${AppLocalizations.of(context)?.and ?? "na"} '),
          TextSpan(
            text: AppLocalizations.of(context)?.privacyPolicy ??
                'Ibihishwe Bwite',
            style: TextStyle(
              color:
                  _isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
