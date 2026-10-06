import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;
  late AnimationController _animController;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1F2937);
  Color get _secondaryTextColor => _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);
  Color get _inputBorderColor => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _inputFillColor => _isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get _inputTextColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _inputHintColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _iconColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _errorBgColor => _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
  Color get _errorBorderColor => _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
  Color get _errorTextColor => _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendReset() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    
    // Guard against missing localizations
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isDesktop) {
      return _buildDesktopLayout(authState, l10n);
    }
    return _buildMobileLayout(authState, l10n);
  }

  Widget _buildDesktopLayout(dynamic authState, AppLocalizations l10n) {
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
          // Right form panel (55%)
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
                              Icon(Icons.lock_reset_rounded, color: Color(0xFF00C896), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Reset Password',
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
                            color: _secondaryTextColor.withOpacity(0.6),
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
                          child: _emailSent ? _buildSuccessMessage() : _buildRightPanel(authState, l10n),
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

  Widget _buildLeftPanel() {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF00C896).withOpacity(0.15), const Color(0xFF0A4A5A).withOpacity(0.1)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
              child: Column(
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Excellence Coaching Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Reset Your Password', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -1)),
                  const SizedBox(height: 20),
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: const Color(0xFF00C896), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 30),
                  const Text(
                    "We'll send you a reset link to your email address. Click it to create a new password for your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(dynamic authState, AppLocalizations l10n) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your email to receive a reset link',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),
        // Form card
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _inputBorderColor, width: 1),
            boxShadow: _isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _emailSent ? _buildSuccessMessage() : _buildResetForm(authState),
        ),
        const SizedBox(height: 24),
        // Sign in link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
              child: Text(
                'Sign in',
                style: TextStyle(
                  color: const Color(0xFF00C896),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Security badge
        _buildSecurityBadge(l10n),
      ],
    );
  }

  Widget _buildResetForm(dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: _inputTextColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: _inputHintColor),
                  prefixIcon: Icon(Icons.email_outlined, color: _iconColor),
                  filled: true,
                  fillColor: _inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _inputBorderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _inputBorderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C896), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sendReset(),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: InkWell(
                    onTap: authState.isLoading ? null : _sendReset,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: authState.isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9))))
                          : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              if (authState.error != null && !_emailSent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _errorBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _errorBorderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(authState.error, style: TextStyle(color: _errorTextColor, fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 30),
        const Text('Check Your Email', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF111827), fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const Text(
          "We've sent a reset link to your email. Click the link to create a new password.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 8),
        const Text(
          "If you don't receive the email within a few minutes, please check your spam folder or contact our support team for assistance.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 40),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00C896), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => context.push('/login'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: const Text('Back to Sign In', style: TextStyle(color: Color(0xFF00C896), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(AppLocalizations l10n) {
    final String secureText = l10n.secureProtected;
    
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

  Widget _buildMobileLayout(dynamic authState, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_ios_rounded, color: _textColor, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Compact header section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your email to receive a reset link',
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: _emailSent ? _buildMobileSuccessMessage() : _buildMobileResetForm(authState),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
  );
}

  Widget _buildMobileResetForm(dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _inputFillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _inputBorderColor, width: 1.5),
                  boxShadow: _isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: _inputTextColor, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: _inputHintColor),
                    prefixIcon: Icon(Icons.email_outlined, color: _iconColor),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendReset(),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: InkWell(
                    onTap: authState.isLoading ? null : _sendReset,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: authState.isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              if (authState.error != null && !_emailSent) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _errorBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _errorBorderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(authState.error, style: TextStyle(color: _errorTextColor, fontSize: 12))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Remember password? ', style: TextStyle(color: _secondaryTextColor, fontSize: 13)),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text('Sign in', style: TextStyle(color: const Color(0xFF00C896), fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 4)],
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF1A2433), fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          "We've sent a reset link to your email. Click it to create a new password.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF4A5568), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 8),
        Text(
          "If you don't receive the email within a few minutes, please check your spam folder or contact our support team for assistance.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 32),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
            ),
            child: InkWell(
              onTap: () => context.push('/login'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Text('Back to Sign In', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
