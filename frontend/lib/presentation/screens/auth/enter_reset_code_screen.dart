import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EnterResetCodeScreen extends ConsumerStatefulWidget {
  const EnterResetCodeScreen({super.key});

  @override
  _EnterResetCodeScreenState createState() => _EnterResetCodeScreenState();
}

class _EnterResetCodeScreenState extends ConsumerState<EnterResetCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    if (_formKey.currentState!.validate()) {
      final resetCode = _codeController.text.trim();
      
      // Navigate to reset password screen with the code
      // Navigate using GoRouter and pass the code as query parameter
      context.push('/reset-password?oobCode=${Uri.encodeComponent(resetCode)}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (context.canPop())
                    IconButton(
                      onPressed: () => context.pop(),
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
              'Enter Reset Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Enter the code sent to your email',
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
                        // Code Field
                        Container(
                          height: 56,
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
                            controller: _codeController,
                            style: const TextStyle(
                              color: Color(0xFF1A2433),
                              fontSize: 16,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Enter reset code',
                              hintStyle: TextStyle(
                                color: Color(0xFF8899AA),
                                letterSpacing: 0,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.vpn_key_outlined, color: Color(0xFF8899AA)),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter the reset code';
                              if (value.length < 6) return 'Code must be at least 6 characters';
                              return null;
                            },
                            onFieldSubmitted: (_) => _submitCode(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                            ),
                            child: InkWell(
                              onTap: _isLoading ? null : _submitCode,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _isLoading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : const Text('Submit Code', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
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
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade600, fontSize: 12))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Instructions
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
                              Text('Instructions:', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 8),
                              Text('• Check your email for the reset code', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                              SizedBox(height: 3),
                              Text('• The code expires in 1 hour', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                              SizedBox(height: 3),
                              Text('• If you don\'t see it, check spam folder', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

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

                        TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text(
                            'Didn\'t receive the code? Request again',
                            style: TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                          ),
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