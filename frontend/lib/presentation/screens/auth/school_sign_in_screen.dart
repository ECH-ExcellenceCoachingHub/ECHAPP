import 'package:flutter/material.dart';
import '../../../widgets/school/school_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../widgets/forms/password_field.dart';
import '../../providers/auth_provider.dart';
import '../../router/post_auth_navigation.dart';

enum _Who { student, young, parent }

/// Sign-in for school students (student code + PIN [+ class code]),
/// young pupils (class code + tap their name) and parents (phone + PIN).
class SchoolSignInScreen extends ConsumerStatefulWidget {
  const SchoolSignInScreen({super.key});

  @override
  ConsumerState<SchoolSignInScreen> createState() => _SchoolSignInScreenState();
}

class _SchoolSignInScreenState extends ConsumerState<SchoolSignInScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pin = TextEditingController();
  final _classCode = TextEditingController();
  final _classCodeFocus = FocusNode();
  _Who _who = _Who.student;
  bool _needClassCode = false;
  bool _busy = false;
  String? _error;
  // Young pupils: class list opened by the class code.
  Map<String, dynamic>? _classInfo;

  @override
  void initState() {
    super.initState();
    // Arrived here because the server ended the session: say why.
    final s = ref.read(authProvider);
    if (s.user == null && s.error != null && (s.error!.toLowerCase().contains('signed out') || s.error!.toLowerCase().contains('session'))) {
      _error = s.error;
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _pin.dispose();
    _classCode.dispose();
    _classCodeFocus.dispose();
    super.dispose();
  }

  void _switch(_Who w) => setState(() {
        _who = w;
        _error = null;
        _classInfo = null;
        if (w == _Who.parent) _id.clear();
      });

  Future<void> _afterLogin() async {
    final notifier = ref.read(authProvider.notifier);
    final s = ref.read(authProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (s.user != null) {
      await continueAfterAuth(context, ref);
      return;
    }
    final code = notifier.lastPinErrorCode;
    setState(() {
      _error = s.error ?? 'Sign-in failed';
      if (code == 'ACCESS_CODE_REQUIRED' || code == 'ACCESS_CODE_INVALID') {
        _needClassCode = true;
        if (code == 'ACCESS_CODE_REQUIRED') _error = 'Your school asks for the class code. Ask your teacher for the code shown in class.';
      }
    });
    if (_needClassCode) _classCodeFocus.requestFocus();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    await ref.read(authProvider.notifier).loginWithPin(
          _id.text,
          _pin.text,
          accessCode: _who == _Who.student && _classCode.text.trim().isNotEmpty ? _classCode.text.trim() : null,
        );
    await _afterLogin();
  }

  Future<void> _openClass() async {
    final code = _classCode.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) return setState(() => _error = 'The class code has 6 digits.');
    setState(() { _busy = true; _error = null; });
    try {
      final info = await ref.read(authProvider.notifier).classCodeInfo(code);
      if (!mounted) return;
      if (info['pinRequired'] == true) {
        setState(() {
          _who = _Who.student;
          _needClassCode = true;
          _busy = false;
          _error = '${info['className'] ?? 'This class'} signs in with student code and PIN. Enter them below; the class code is already filled in.';
        });
        return;
      }
      setState(() { _classInfo = info; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _busy = false; });
    }
  }

  Future<void> _pickName(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: T('Are you ${s['fullName']}?'),
        content: const T('Only tap your own name. Your teacher can see who signed in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const T('Yes, it is me')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _busy = true; _error = null; });
    await ref.read(authProvider.notifier).loginWithPin('', '', accessCode: _classCode.text.replaceAll(RegExp(r'\D'), ''), studentId: '${s['id']}');
    await _afterLogin();
  }

  Widget _classCodeField({bool autofocus = false, VoidCallback? onDone}) => TextFormField(
        controller: _classCode,
        focusNode: _classCodeFocus,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onDone?.call(),
        style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600),
        decoration: InputDecoration(labelText: trSchool(context, 'Class code'), hintText: trSchool(context, '6 digits shown by your teacher'), prefixIcon: const Icon(Icons.pin_outlined)),
      );

  @override
  Widget build(BuildContext context) {
    final text = AppTheme.getTextColor(context);
    final muted = AppTheme.getSecondaryTextColor(context);
    final subtitle = switch (_who) {
      _Who.student => 'Use the student code and PIN your school gave you.',
      _Who.young => 'Type the class code your teacher shows, then tap your name.',
      _Who.parent => 'Use the phone number you gave the school and your PIN.',
    };
    final narrow = MediaQuery.sizeOf(context).width < 420;
    Widget whoTab(_Who w, String label, IconData icon) {
      final sel = _who == w;
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _switch(w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: sel ? AppTheme.getCardColor(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: sel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 22, color: sel ? AppTheme.primary : muted),
                const SizedBox(height: 4),
                Text(trSchool(context, label), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? text : muted)),
              ]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SingleChildScrollView(
        child: Column(children: [
          // Brand header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 56),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.canPop() ? context.pop() : context.go(signedOutStartRoute()),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.school_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 12),
              T('Sign in with your school', textAlign: TextAlign.center, style: TextStyle(fontSize: narrow ? 21 : 24, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              T(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.88))),
            ]),
          ),
          // Form card, overlapping the header
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(context, radius: 20),
                    child: Form(
                      key: _form,
                      child: AutofillGroup(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.getBackgroundColor(context), borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              whoTab(_Who.student, 'Student', Icons.person_outline),
                              whoTab(_Who.young, 'Young pupil', Icons.child_care_outlined),
                              whoTab(_Who.parent, 'Parent', Icons.family_restroom_outlined),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          if (_who == _Who.young) ..._youngPupil(muted) else ..._codeAndPin(),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            InfoBanner(tone: Tone.bad, icon: Icons.error_outline, text: _error!),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: T(
                _who == _Who.parent
                    ? 'Forgot your PIN? Ask the school office for a new one.'
                    : 'Forgot your PIN? Ask your class teacher. Only one device can use a student account at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: muted),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _codeAndPin() {
    final parent = _who == _Who.parent;
    return [
      TextFormField(
        controller: _id,
        textInputAction: TextInputAction.next,
        autofillHints: [parent ? AutofillHints.telephoneNumber : AutofillHints.username],
        keyboardType: parent ? TextInputType.phone : TextInputType.visiblePassword,
        textCapitalization: parent ? TextCapitalization.none : TextCapitalization.characters,
        inputFormatters: parent ? null : [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]'))],
        decoration: InputDecoration(
          labelText: trSchool(context, parent ? 'Phone number' : 'Student code'),
          hintText: parent ? '07XX XXX XXX' : 'e.g. GSB260001',
          prefixIcon: Icon(parent ? Icons.phone_outlined : Icons.badge_outlined),
        ),
        validator: (v) => (v == null || v.trim().length < 4) ? trSchool(context, parent ? 'Enter your phone number' : 'Enter your student code') : null,
      ),
      const SizedBox(height: 14),
      PasswordField.pin(
        controller: _pin,
        textInputAction: _needClassCode && !parent ? TextInputAction.next : TextInputAction.done,
        onSubmitted: (_) => _needClassCode && !parent ? _classCodeFocus.requestFocus() : _submit(),
        validator: (v) => (v == null || v.length != 6) ? trSchool(context, 'The PIN has 6 digits') : null,
      ),
      if (!parent) ...[
        const SizedBox(height: 14),
        if (_needClassCode)
          _classCodeField(onDone: _submit)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _needClassCode = true),
              icon: const Icon(Icons.pin_outlined, size: 18),
              label: const T('My teacher gave a class code'),
            ),
          ),
      ],
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _busy ? null : _submit,
        child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const T('Sign in'),
      ),
    ];
  }

  List<Widget> _youngPupil(Color muted) {
    final info = _classInfo;
    if (info == null) {
      return [
        _classCodeField(autofocus: true, onDone: _openClass),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _busy ? null : _openClass,
          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const T('Open my class'),
        ),
      ];
    }
    final students = ((info['students'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [
      T('${info['className']} · ${info['schoolName'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 4),
      T('Tap your name', textAlign: TextAlign.center, style: TextStyle(color: muted)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 380 ? 2 : 1;
        final w = (box.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in students)
            SizedBox(
              width: w,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14), alignment: Alignment.centerLeft),
                onPressed: _busy ? null : () => _pickName(s),
                child: Row(children: [
                  InitialsAvatar('${s['fullName']}', radius: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${s['fullName']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
        ]);
      }),
      const SizedBox(height: 12),
      TextButton(onPressed: () => setState(() => _classInfo = null), child: const T('Wrong class? Enter the code again')),
    ];
  }
}
