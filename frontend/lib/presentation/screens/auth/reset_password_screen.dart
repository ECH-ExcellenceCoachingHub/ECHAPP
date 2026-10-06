import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? oobCode;
  
  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerifying = true;
  bool _isValidLink = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyResetLink();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyResetLink() async {
    // Check if oobCode was passed as argument (from EnterResetCodeScreen)
    final passedCode = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final resetCode = passedCode?['oobCode'] as String?;

    // Use the passed code if available, otherwise use the widget's code
    final codeToUse = resetCode ?? widget.oobCode;

    if (codeToUse == null || codeToUse.isEmpty) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid reset link. Please request a new password reset.';
      });
      return;
    }

    // Verify the token with backend before allowing reset
    try {
      final isValid = await ref.read(authProvider.notifier).verifyResetToken(codeToUse);
      setState(() {
        _isVerifying = false;
        _isValidLink = isValid;
        _errorMessage = isValid ? null : 'Invalid or expired reset link. Please request a new password reset.';
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isValidLink = false;
        _errorMessage = 'Invalid or expired reset link. Please request a new password reset.';
      });
    }
  }

  Future<void> _resetPassword() async {
    // Use the code passed as argument if available
    final passedCode = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final resetCode = passedCode?['oobCode'] as String?;
    final codeToUse = resetCode ?? widget.oobCode;

    if (_formKey.currentState!.validate() && codeToUse != null) {
      final newPassword = _passwordController.text.trim();
      
      try {
        final notifier = ref.read(authProvider.notifier);
        notifier.state = notifier.state.copyWith(isLoading: true, error: null);
        
        // Reset password using backend API
        await ref.read(authProvider.notifier).resetPassword(codeToUse, newPassword);
        
          // Show success and navigate to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! You can now login with your new password.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to login screen using GoRouter
          context.go('/login');
        }
      } catch (e) {
        String errorMessage = e.toString();
        
        // Provide user-friendly error messages
        if (errorMessage.contains('Invalid or expired reset token')) {
          errorMessage = 'This reset link is invalid or has expired. Please request a new password reset.';
        } else if (errorMessage.contains('must be at least 6 characters')) {
          errorMessage = 'Password must be at least 6 characters long.';
        } else if (errorMessage.contains('Token and new password are required')) {
          errorMessage = 'Missing required information. Please try again.';
        } else {
          errorMessage = 'Failed to reset password. Please try again.';
        }
        
        if (mounted) {
          final notifier = ref.read(authProvider.notifier);
          notifier.state = notifier.state.copyWith(isLoading: false, error: errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_isVerifying) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C896),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verifying reset link...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isValidLink && _errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C896),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/forgot-password'),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Invalid Link',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'This reset link is invalid or has expired',
                style: TextStyle(color: Color(0xEBFFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
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
                              onTap: () => context.go('/forgot-password'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: const Text('Request New Reset Link', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Remember password? ', style: TextStyle(color: Color(0xFF4A5568), fontSize: 13)),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text('Sign In', style: TextStyle(color: Color(0xFF00C896), fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00C896),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Logo
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Create New Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Enter a strong new password for your account',
              style: TextStyle(color: Color(0xEBFFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 20),

            // White card
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: Color(0xFF1A2433), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'New Password',
                              hintStyle: const TextStyle(color: Color(0xFF8899AA)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8899AA)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: const Color(0xFF8899AA),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a new password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$').hasMatch(value)) {
                                return 'Password must contain at least one letter and one number';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _resetPassword(),
                            style: const TextStyle(color: Color(0xFF1A2433), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Confirm New Password',
                              hintStyle: const TextStyle(color: Color(0xFF8899AA)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8899AA)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: const Color(0xFF8899AA),
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your new password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Password requirements
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Requirements:',
                                style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 8),
                              Text('• At least 6 characters long', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                              SizedBox(height: 3),
                              Text('• Must contain letters and numbers', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Reset Button
                        Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                            ),
                            child: InkWell(
                              onTap: authState.isLoading ? null : _resetPassword,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: authState.isLoading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : const Text('Update Password', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),

                        // Error message
                        if (authState.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: TextStyle(color: Colors.red.shade600, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Remember your password? ', style: TextStyle(color: Color(0xFF4A5568), fontSize: 13)),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text('Sign In', style: TextStyle(color: Color(0xFF00C896), fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
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
}