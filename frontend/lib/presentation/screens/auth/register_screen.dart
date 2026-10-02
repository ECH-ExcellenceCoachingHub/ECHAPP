import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasNavigated = false;
  late AnimationController _animController;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1F2937);
  Color get _secondaryTextColor => _isDark ? Colors.white70 : const Color(0xFF6B7280);
  Color get _inputBorderColor => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _inputFillColor => _isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get _inputTextColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _inputHintColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _iconColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _errorBgColor => _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
  Color get _errorBorderColor => _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
  Color get _errorTextColor => _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
  Color get _linkColor => const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _register() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
      );
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

    ref.listen(authProvider, (previous, current) async {
      if (current.user != null && !current.isLoading && !_hasNavigated) {
        _hasNavigated = true;
        // Skips any onboarding step already answered in the registration form.
        await continueAfterAuth(context, ref);
      }
    });

    if (isDesktop) {
      return _buildDesktopLayout(authState, l10n);
    }
    return _buildMobileLayout(authState, l10n);
  }

  Widget _buildDesktopLayout(dynamic authState, AppLocalizations l10n) {
    final String createAccountText = l10n.createAccount;
    final String subtitleText = l10n.createAccountSubtitle;
    final String fullNameText = l10n.fullName;
    final String emailText = l10n.email;
    final String phoneText = l10n.phoneNumber;
    final String passwordText = l10n.password;
    final String confirmPasswordText = l10n.confirmPassword;
    final String haveAccountText = l10n.alreadyHaveAccount;
    final String signInText = l10n.loginNow;
    final String requiredError = 'Required';
    final String min6CharsError = 'Min 6 chars';
    final String mismatchError = 'Mismatch';

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Row(
        children: [
          // Left branding panel (45%)
          const Expanded(
            flex: 45,
            child: DesktopBrandPanel(
              headline: 'Join Us Today',
              title: 'Excellence\nCoaching Hub',
              tagline: 'Start your learning journey\nand reach new heights.',
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
                              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00C896), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Create Account',
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
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                          child: _buildRightPanel(authState, l10n, createAccountText, subtitleText, fullNameText, emailText, phoneText, passwordText, confirmPasswordText, haveAccountText, signInText, requiredError, min6CharsError, mismatchError),
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

  Widget _buildRightPanel(dynamic authState, AppLocalizations l10n, String createAccountText, String subtitleText, String fullNameText, String emailText, String phoneText, String passwordText, String confirmPasswordText, String haveAccountText, String signInText, String requiredError, String min6CharsError, String mismatchError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page title section
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
                Text(
                  createAccountText,
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
                  subtitleText,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Form card
        Container(
          padding: const EdgeInsets.all(28),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_nameController, fullNameText, Icons.person_outline),
                const SizedBox(height: 14),
                _buildTextField(_emailController, '$emailText (or use phone below)', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress, required: false,
                  extraValidator: (value) {
                    if ((value == null || value.trim().isEmpty) && _phoneController.text.trim().isEmpty) {
                      return 'Email or phone number is required';
                    }
                    if (value != null && value.trim().isNotEmpty) {
                      if (!RegExp(r'^[\w.-]+@[\w-]+\.[\w.]{2,}$').hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  }),
                const SizedBox(height: 14),
                _buildTextField(_phoneController, '$phoneText (or use email above)', Icons.phone_outlined,
                  keyboardType: TextInputType.phone, required: false,
                  extraValidator: (value) {
                    if ((value == null || value.trim().isEmpty) && _emailController.text.trim().isEmpty) {
                      return 'Phone or email is required';
                    }
                    return null;
                  }),
                const SizedBox(height: 14),
                _buildPasswordField(_passwordController, passwordText, (value) {
                  if (value == null || value.isEmpty) return requiredError;
                  if (value.length < 6) return min6CharsError;
                  return null;
                }),
                const SizedBox(height: 14),
                _buildPasswordField(_confirmController, confirmPasswordText, (value) {
                  if (value == null || value.isEmpty) return requiredError;
                  if (value != _passwordController.text) return mismatchError;
                  return null;
                }, TextInputAction.done, _register),
                const SizedBox(height: 24),
                _buildSignUpButton(authState, createAccountText),
                if (authState.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _errorBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _errorBorderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: _errorTextColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Sign in link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              haveAccountText,
              style: TextStyle(color: _secondaryTextColor, fontSize: 14),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
              child: Text(
                signInText,
                style: TextStyle(color: _linkColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSecurityBadge(l10n),
      ],
    );
  }

  Widget _buildMobileLayout(dynamic authState, AppLocalizations l10n) {
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 700;

    // Localization strings
    final String createAccountText = l10n.createAccount;
    final String subtitleText = l10n.createAccountSubtitle;
    final String fullNameText = l10n.fullName;
    final String emailText = l10n.email;
    final String phoneText = l10n.phoneNumber;
    final String passwordText = l10n.password;
    final String confirmPasswordText = l10n.confirmPassword;
    final String haveAccountText = l10n.alreadyHaveAccount;
    final String signInText = l10n.loginNow;
    final String requiredError = 'Required';
    final String min6CharsError = 'Min 6 chars';
    final String mismatchError = 'Mismatch';

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
              padding: EdgeInsets.symmetric(vertical: isShort ? 4 : 8),
              child: Column(
                children: [
                  // Small logo
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(_isDark ? 0.5 : 0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    createAccountText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
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
                    isSmallMobile ? 16 : 20,
                    isSmallMobile ? 16 : 20,
                    isSmallMobile ? 16 : 20,
                    isSmallMobile ? 16 : 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(_nameController, fullNameText, Icons.person_outline),
                        const SizedBox(height: 10),
                        _buildTextField(_emailController, '$emailText (or use phone)', Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress, required: false,
                          extraValidator: (value) {
                            if ((value == null || value.trim().isEmpty) && _phoneController.text.trim().isEmpty) {
                              return 'Email or phone number is required';
                            }
                            if (value != null && value.trim().isNotEmpty) {
                              if (!RegExp(r'^[\w.-]+@[\w-]+\.[\w.]{2,}$').hasMatch(value.trim())) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          }),
                        const SizedBox(height: 10),
                        _buildTextField(_phoneController, '$phoneText (or use email)', Icons.phone_outlined,
                          keyboardType: TextInputType.phone, required: false,
                          extraValidator: (value) {
                            if ((value == null || value.trim().isEmpty) && _emailController.text.trim().isEmpty) {
                              return 'Phone or email is required';
                            }
                            return null;
                          }),
                        const SizedBox(height: 10),
                        _buildPasswordField(_passwordController, passwordText, (value) { 
                          if (value == null || value.isEmpty) return requiredError; 
                          if (value.length < 6) return min6CharsError; 
                          return null; 
                        }),
                        const SizedBox(height: 10),
                        _buildPasswordField(_confirmController, confirmPasswordText, (value) { 
                          if (value == null || value.isEmpty) return requiredError; 
                          if (value != _passwordController.text) return mismatchError; 
                          return null; 
                        }, TextInputAction.done, _register),
                        const SizedBox(height: 16),
                        _buildSignUpButton(authState, createAccountText),
                        const SizedBox(height: 12),
                        if (authState.error != null) 
                          Container(
                            padding: const EdgeInsets.all(10), 
                            decoration: BoxDecoration(
                              color: _errorBgColor, 
                              borderRadius: BorderRadius.circular(8), 
                              border: Border.all(color: _errorBorderColor)
                            ), 
                            child: Text(
                              authState.error!, 
                              style: TextStyle(color: _errorTextColor, fontSize: 11)
                            )
                          ),
                        const SizedBox(height: 12),
                        _buildSecurityBadge(l10n),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Text(
                              haveAccountText, 
                              style: TextStyle(color: _secondaryTextColor, fontSize: 12)
                            ), 
                            TextButton(
                              onPressed: () => context.push('/login'), 
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                signInText, 
                                style: TextStyle(color: _linkColor, fontSize: 12, fontWeight: FontWeight.w700)
                              )
                            )
                          ]
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(AppLocalizations l10n) {
    final String secureText = l10n.secureProtected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isDark ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFBBF7D0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.verified_user, color: Color(0xFF059669), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              secureText,
              style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool required = true, TextInputAction textInputAction = TextInputAction.next, String? Function(String?)? extraValidator}) {
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
        controller: controller,
        style: TextStyle(color: _inputTextColor, fontSize: 15),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: _inputHintColor),
          prefixIcon: Icon(icon, color: _iconColor),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: (value) {
          if (extraValidator != null) return extraValidator(value);
          if (!required) return null;
          if (value == null || value.isEmpty) return '$label required';
          if (keyboardType == TextInputType.emailAddress && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Invalid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, String? Function(String?) validator, [TextInputAction textInputAction = TextInputAction.next, VoidCallback? onSubmitted]) {
    bool obscure = label.contains('Confirm') ? _obscureConfirm : _obscurePassword;
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
        controller: controller,
        style: TextStyle(color: _inputTextColor, fontSize: 15),
        obscureText: obscure,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: _inputHintColor),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: _iconColor),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _iconColor),
            onPressed: () => setState(() {
              if (label.contains('Confirm')) {
                _obscureConfirm = !_obscureConfirm;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            }),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignUpButton(dynamic authState, String buttonText) {
    return Container(
      height: 52,
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
          onTap: authState.isLoading ? null : _register,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: authState.isLoading
                ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9))))
                : Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
