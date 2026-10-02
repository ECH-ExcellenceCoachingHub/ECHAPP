import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _Country {
  final String name;
  final String code;
  final String dialCode;
  const _Country(this.name, this.code, this.dialCode);
}

const List<_Country> _countries = [
  _Country('Rwanda', 'RW', '+250'),
  _Country('Uganda', 'UG', '+256'),
  _Country('Kenya', 'KE', '+254'),
  _Country('Tanzania', 'TZ', '+255'),
  _Country('Burundi', 'BI', '+257'),
  _Country('DR Congo', 'CD', '+243'),
  _Country('Nigeria', 'NG', '+234'),
  _Country('South Africa', 'ZA', '+27'),
  _Country('Ethiopia', 'ET', '+251'),
  _Country('Ghana', 'GH', '+233'),
  _Country('United States', 'US', '+1'),
  _Country('United Kingdom', 'GB', '+44'),
  _Country('France', 'FR', '+33'),
  _Country('Germany', 'DE', '+49'),
  _Country('China', 'CN', '+86'),
  _Country('India', 'IN', '+91'),
  _Country('Belgium', 'BE', '+32'),
  _Country('Canada', 'CA', '+1'),
  _Country('Australia', 'AU', '+61'),
  _Country('Brazil', 'BR', '+55'),
];

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCodeSent = false;
  int _resendTimer = 60;
  bool _canResend = false;
  _Country _selectedCountry = _countries.first;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark
      ? const Color(0xFF0F172A)
      : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDark
      ? const Color(0xFF1E293B)
      : Colors.white;
  Color get _textColor => _isDark
      ? Colors.white
      : const Color(0xFF0F172A);
  Color get _secondaryTextColor => _isDark
      ? Colors.white70
      : const Color(0xFF64748B);
  Color get _inputTextColor => _isDark
      ? Colors.white
      : const Color(0xFF1A2433);
  Color get _inputHintColor => _isDark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF8899AA);
  Color get _inputBorderColor => _isDark
      ? const Color(0xFF334155)
      : const Color(0xFFE2E8F0);
  Color get _inputFillColor => _isDark
      ? const Color(0xFF0F172A)
      : Colors.white;
  Color get _prefixBgColor => _isDark
      ? const Color(0xFF1E293B)
      : const Color(0xFFF8FAFC);

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        return true;
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return false;
    });
  }

  void _sendOTP() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      String phoneNumber = _phoneController.text.trim();
      
      // Format phone number with selected country code if not present
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '${_selectedCountry.dialCode}$phoneNumber';
      }
      
      ref.read(authProvider.notifier).sendPhoneOTP(phoneNumber);
    }
  }

  void _verifyOTP() {
    FocusScope.of(context).unfocus();
    if (_otpController.text.length == 6) {
      ref.read(authProvider.notifier).verifyPhoneOTP(_otpController.text.trim());
    }
  }

  void _resendOTP() {
    if (_canResend) {
      _sendOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    
    debugPrint('PhoneAuthScreen: l10n is ${l10n == null ? "NULL" : "available"}, locale: ${Localizations.localeOf(context)}');
    
    // Guard against missing localizations
    if (l10n == null) {
      debugPrint('PhoneAuthScreen: Returning loading indicator due to null l10n');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Listen for code sent state
    ref.listen(authProvider, (previous, current) {
      if (current.isCodeSent && !_isCodeSent) {
        setState(() {
          _isCodeSent = true;
        });
        _startResendTimer();
      }
      
      // Navigate on successful login
      if (current.user != null && !current.isLoading && current.error?.contains('successful') == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Phone is already verified here, so the phone step is skipped.
          if (mounted) await continueAfterAuth(context, ref);
        });
      }
    });

    if (isDesktop) {
      return _buildDesktopLayout(authState);
    }
    return _buildMobileLayout(authState, l10n);
  }

  Widget _buildDesktopLayout(dynamic authState) {
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
          // Right form panel (55%) - theme-aware
          Expanded(
            flex: 55,
            child: Container(
              color: _cardColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 60),
                    child: _buildRightPanel(authState),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final l10n = AppLocalizations.of(context);
    // Fallback strings if localization fails
    final String phoneSignInText = l10n?.phoneSignIn ?? 'Phone Sign In';
    final String quickSecureText = l10n?.quickAndSecure ?? 'Quick and Secure';
    final String signInWithPhoneText = l10n?.signInWithPhone ?? 'Sign in with your phone number for a quick and secure process. No password needed.';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00C896).withOpacity(0.15),
            const Color(0xFF0A4A5A).withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C896), Color(0xFF009E76)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
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
          Text(
            phoneSignInText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00C896),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            quickSecureText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            signInWithPhoneText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isWindowsDesktop =>
      defaultTargetPlatform == TargetPlatform.windows && !kIsWeb;

  Widget _buildRightPanel(dynamic authState) {
    final l10n = AppLocalizations.of(context);
    // Fallback strings if localization fails
    final String phoneAuthTitleText = l10n?.phoneAuthTitle ?? 'Phone Authentication';
    final String enterVerifCodeText = l10n?.enterVerificationCode ?? 'Enter verification code';
    final String enterPhoneNumText = l10n?.enterPhoneNumber ?? 'Enter your phone number';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.close_rounded, color: _textColor.withOpacity(0.7), size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            phoneAuthTitleText,
            style: TextStyle(
              color: _textColor,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isCodeSent ? enterVerifCodeText : enterPhoneNumText,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          // Desktop Windows: phone auth not supported — show clear notice
          if (_isWindowsDesktop) ..._buildDesktopNotSupportedContent()
          else Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Browser state warning banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n?.phoneAuthBrowserWarning ?? 'Phone authentication may open a browser for verification. Please allow the process to complete.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isCodeSent) _buildPhoneField(),
                if (_isCodeSent) _buildOTPField(),
                const SizedBox(height: 24),
                if (!_isCodeSent) _buildSendOTPButton(authState),
                if (_isCodeSent) _buildVerifyOTPButton(authState),
                const SizedBox(height: 20),
                if (authState.error != null && authState.error!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (_isCodeSent) _buildResendSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDesktopNotSupportedContent() {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1.5),
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
                    color: const Color(0xFFFFC107).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_disabled_rounded,
                      color: Color(0xFFB45309), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Phone auth not available on desktop',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Firebase phone authentication requires a mobile device or web browser. On Windows desktop, please use email/password sign-in instead.',
              style: TextStyle(
                color: Color(0xFF78350F),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/email-auth-option'),
          icon: const Icon(Icons.email_rounded, size: 20),
          label: const Text(
            'Sign in with Email instead',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C896),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    ];
  }

  Widget _buildMobileLayout(dynamic authState, AppLocalizations l10n) {
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
              padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 16),
              child: Column(
                children: [
                  // Small logo
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(_isDark ? 0.5 : 0.3), width: 2),
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
                    l10n.phoneAuthTitle ?? 'Kwiyemeza ukoresheje Telefone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.phoneAuthSubtitle ?? 'Injiza numero ya telefone yawe wemerwe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 13,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Browser state warning banner (applies to all platforms during reCAPTCHA flow)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF92400E).withOpacity(0.2) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: _isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.phoneAuthBrowserWarning ?? 'Phone authentication may open a browser for verification. Please allow the process to complete.',
                                  style: TextStyle(
                                    color: _isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isCodeSent) _buildPhoneField(),
                        if (_isCodeSent) _buildOTPField(),
                        const SizedBox(height: 20),
                        if (!_isCodeSent) _buildSendOTPButton(authState),
                        if (_isCodeSent) _buildVerifyOTPButton(authState),
                        const SizedBox(height: 16),
                        if (authState.error != null && authState.error!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: TextStyle(
                                      color: _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_isCodeSent) _buildResendSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Privacy notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isDark ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFBBF7D0), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.verified_user, color: Color(0xFF059669), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.secureProtected.split('.').first ?? 'Amakuru yawe arinzwe kandi ararindwa',
                                      style: TextStyle(
                                          color: _textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3),
                                    ),
                                    Text(
                                      'Amakuru yawe arinzwe kandi ararindwa.',
                                      style: TextStyle(
                                          color: _secondaryTextColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context);
    // Default error messages if localization fails
    final String enterPhoneError = l10n?.enterPhoneNumber ?? 'Please enter your phone number';
    final String enterValidPhoneError = l10n?.enterValidPhone ?? 'Please enter a valid phone number';
    
    return TextFormField(
      controller: _phoneController,
      style: TextStyle(
        color: _inputTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _sendOTP(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return enterPhoneError;
        }
        final phoneRegex = RegExp(r'^\d{7,12}$');
        if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
          return enterValidPhoneError;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: '078 123 4567',
        hintStyle: TextStyle(
          color: _inputHintColor.withOpacity(0.6),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        filled: true,
        fillColor: _inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _inputBorderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C896), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        prefixIcon: InkWell(
          onTap: _showCountryPicker,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _prefixBgColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              border: Border(
                right: BorderSide(color: _inputBorderColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withOpacity(_isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedCountry.code,
                    style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedCountry.dialCode,
                  style: TextStyle(
                    color: _inputTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context);
    final String selectCountryText = l10n?.selectCountry ?? 'Select Country';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                selectCountryText,
                style: const TextStyle(
                  color: Color(0xFF1A2433),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final country = _countries[i];
                    final isSelected = country.code == _selectedCountry.code;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00C896).withOpacity(0.12)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00C896).withOpacity(0.4)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          country.code,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00C896)
                                : const Color(0xFF4A5568),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: const Color(0xFF1A2433),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        country.dialCode,
                        style: const TextStyle(
                          color: Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF00C896).withOpacity(0.05),
                      onTap: () {
                        setState(() => _selectedCountry = country);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOTPField() {
    final l10n = AppLocalizations.of(context);
    // Default error messages if localization fails
    final String enterCodeError = l10n?.enterVerificationCode ?? 'Please enter verification code';
    final String enter6DigitError = l10n?.enter6DigitCode ?? 'Please enter 6-digit code';
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _inputBorderColor,
          width: 1.5,
        ),
        boxShadow: _isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _otpController,
        style: TextStyle(
          color: _inputTextColor,
          fontSize: 20,
          letterSpacing: 12,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: TextStyle(
            color: _inputHintColor.withOpacity(0.4),
            letterSpacing: 6,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
        ),
        textInputAction: TextInputAction.done,
        onChanged: (value) {
          if (value.length == 6) {
            _verifyOTP();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return enterCodeError;
          }
          if (value.length != 6) {
            return enter6DigitError;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSendOTPButton(dynamic authState) {
    final l10n = AppLocalizations.of(context);
    final String sendCodeText = l10n?.sendVerificationCode ?? 'Send Verification Code';
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF00C896),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authState.isPhoneLoading ? null : _sendOTP,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: authState.isPhoneLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        sendCodeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyOTPButton(dynamic authState) {
    final l10n = AppLocalizations.of(context);
    final String verifyCodeText = l10n?.verifyCode ?? 'Verify Code';
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF00C896),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authState.isPhoneLoading ? null : _verifyOTP,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: authState.isPhoneLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        verifyCodeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    final l10n = AppLocalizations.of(context);
    final String resendCodeText = l10n?.resendCode ?? 'Resend Code';
    final String changePhoneText = l10n?.changePhoneNumber ?? 'Change Phone Number';
    
    return Column(
      children: [
        if (!_canResend)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF8899AA), size: 16),
                const SizedBox(width: 8),
                Text(
                  '$resendCodeText ($_resendTimer)s',
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00C896),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: _resendOTP,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    resendCodeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _isCodeSent = false;
              _otpController.clear();
            });
            ref.read(authProvider.notifier).resetPhoneAuth();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded, color: Color(0xFF8899AA), size: 16),
              const SizedBox(width: 6),
              Text(
                changePhoneText,
                style: const TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
