import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';

class EmailAuthOptionScreen extends StatefulWidget {
  const EmailAuthOptionScreen({super.key});

  @override
  State<EmailAuthOptionScreen> createState() => _EmailAuthOptionScreenState();
}

class _EmailAuthOptionScreenState extends State<EmailAuthOptionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1F2937);
  Color get _secondaryTextColor => _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);
  Color get _tertiaryTextColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    
    // Guard against missing localizations
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isDesktop) {
      return _buildDesktopLayout(l10n);
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: _backgroundColor,
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
          // Right form panel (55%) - theme-aware
          Expanded(
            flex: 55,
            child: Container(
              color: _backgroundColor,
              child: Column(
                children: [
                  // Top branded header bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      border: Border(
                        bottom: BorderSide(color: _isDark ? const Color(0xFF334155) : const Color(0xFFE8F5F0), width: 1.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.arrow_back_ios_rounded, color: _secondaryTextColor, size: 20),
                          tooltip: 'Back',
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C896).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00C896).withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.apps_rounded, color: Color(0xFF00C896), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Choose Your Path',
                                style: TextStyle(
                                  color: Color(0xFF00C896),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Excellence Coaching Hub',
                          style: TextStyle(
                            color: _tertiaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                          child: _buildRightPanel(l10n),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(AppLocalizations l10n) {
    // Fallback strings if localization fails
    final String choosePathText = l10n.chooseYourPath;
    final String selectHowText = l10n.selectHowToProceed;
    final String signInText = l10n.signIn;
    final String accessAccountText = l10n.accessYourAccount;
    final String createAccountText = l10n.createAccount;
    final String joinCommunityText = l10n.joinCommunity;
    final String resetPasswordText = l10n.resetPassword;
    final String recoverAccessText = l10n.recoverAccess;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page title section with indicator
        Row(
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF00C896),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choosePathText,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectHowText,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        // Options card
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1),
            boxShadow: _isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactAuthOptionButton(
                icon: Icons.login_rounded,
                title: signInText,
                subtitle: accessAccountText,
                color: const Color(0xFF10B981),
                onTap: () => context.push('/login'),
                isDark: _isDark,
              ),
              const SizedBox(height: 16),
              _CompactAuthOptionButton(
                icon: Icons.person_add_rounded,
                title: createAccountText,
                subtitle: joinCommunityText,
                color: const Color(0xFF3B82F6),
                onTap: () => context.push('/register'),
                isDark: _isDark,
              ),
              const SizedBox(height: 16),
              _CompactAuthOptionButton(
                icon: Icons.lock_reset_rounded,
                title: resetPasswordText,
                subtitle: recoverAccessText,
                color: const Color(0xFFF59E0B),
                onTap: () => context.push('/forgot-password'),
                isDark: _isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Security badge
        _buildSecurityBadge(l10n),
        const SizedBox(height: 16),
        // Terms footer
        _buildTermsFooter(l10n),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final l10n = AppLocalizations.of(context);
    // Fallback strings if localization fails
    final String choosePathText = l10n?.chooseYourPath ?? 'Choose Your Path';
    final String selectHowText = l10n?.selectHowToProceed ?? 'Select how you want to proceed';
    final String signInText = l10n?.signIn ?? 'Sign In';
    final String signInSubtitleText = l10n?.signInPhoneSubtitle ?? 'Access your account';
    final String createAccountText = l10n?.createAccount ?? 'Create Account';
    final String createAccountSubtitleText = l10n?.createAccountPhoneSubtitle ?? 'Join our community';
    final String resetPasswordText = l10n?.resetPassword ?? 'Reset Password';
    final String resetPasswordSubtitleText = l10n?.resetPasswordPhoneSubtitle ?? 'Recover your access';
    
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 700;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button at top left
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_ios_rounded, 
                        color: _textColor, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Compact header section
            Padding(
              padding: EdgeInsets.symmetric(vertical: isShort ? 6 : 12),
              child: Column(
                children: [
                  // Small logo
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // White backdrop keeps the logo's own colours legible on the dark theme.
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(_isDark ? 0.35 : 0.15),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    choosePathText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectHowText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Main card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthOptionButton(
                        icon: Icons.login_rounded,
                        title: signInText,
                        subtitle: signInSubtitleText,
                        color: const Color(0xFF10B981),
                        onTap: () => context.push('/login'),
                        compact: isSmallMobile,
                      ),
                      const SizedBox(height: 12),
                      _AuthOptionButton(
                        icon: Icons.person_add_rounded,
                        title: createAccountText,
                        subtitle: createAccountSubtitleText,
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.push('/register'),
                        compact: isSmallMobile,
                      ),
                      const SizedBox(height: 12),
                      _AuthOptionButton(
                        icon: Icons.lock_reset_rounded,
                        title: resetPasswordText,
                        subtitle: resetPasswordSubtitleText,
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.push('/forgot-password'),
                        compact: isSmallMobile,
                      ),
                      const SizedBox(height: 24),
                      _buildSecurityBadge(l10n),
                      const SizedBox(height: 20),
                      _buildTermsFooter(l10n),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(AppLocalizations? l10n) {
    final String secureText = l10n?.secureProtected ?? 'Secure & Protected';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user, color: Color(0xFF059669), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              secureText,
              style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }

  Widget _buildTermsFooter(AppLocalizations? l10n) {
    final String byContinuingText = l10n?.byContinuing ?? 'By continuing, you agree to our';
    final String termsText = l10n?.termsOfService ?? 'Terms of Service';
    final String andText = l10n?.and ?? 'and';
    final String privacyText = l10n?.privacyPolicy ?? 'Privacy Policy';

    return Text.rich(
      TextSpan(
        style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            height: 1.5),
        children: [
          TextSpan(text: '$byContinuingText '),
          TextSpan(
            text: termsText,
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          TextSpan(text: ' $andText '),
          TextSpan(
            text: privacyText,
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _CompactAuthOptionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _CompactAuthOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDark = false,
  });

  @override
  State<_CompactAuthOptionButton> createState() => _CompactAuthOptionButtonState();
}

class _CompactAuthOptionButtonState extends State<_CompactAuthOptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A2433);
    final secondaryTextColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : borderColor,
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
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
                      widget.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: _isHovered ? widget.color : iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthOptionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _AuthOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_AuthOptionButton> createState() => _AuthOptionButtonState();
}

class _AuthOptionButtonState extends State<_AuthOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2433);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.compact ? 16 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : borderColor,
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: widget.compact ? 44 : 56,
                height: widget.compact ? 44 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.compact ? 12 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.compact ? 22 : 28,
                ),
              ),
              SizedBox(width: widget.compact ? 14 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: widget.compact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: widget.compact ? 2 : 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: _isHovered ? widget.color : iconColor,
                size: widget.compact ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00C896),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermsFooter extends StatelessWidget {
  final AppLocalizations? l10n;
  const _TermsFooter({this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final localL10n = l10n ?? AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fallback strings
    final String byContinuingText = localL10n?.byContinuing ?? 'By continuing, you agree to our';
    final String termsText = localL10n?.termsOfService ?? 'Terms of Service';
    final String andText = localL10n?.and ?? 'and';
    final String privacyText = localL10n?.privacyPolicy ?? 'Privacy Policy';
    
    return Text.rich(
      TextSpan(
        style: TextStyle(
            color: isDark ? const Color(0xFF8899AA) : const Color(0xFF64748B),
            fontSize: isDesktop ? 12.5 : 11.5,
            height: 1.5),
        children: [
          TextSpan(text: '$byContinuingText '),
          TextSpan(
            text: termsText,
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          TextSpan(text: ' $andText '),
          TextSpan(
            text: privacyText,
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
