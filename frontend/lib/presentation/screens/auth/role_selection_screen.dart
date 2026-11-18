import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_access_provider.dart';
import '../../router/post_auth_navigation.dart';
import '../../widgets/smart_back_button.dart';

/// Shown once to new Google / phone accounts: "Are you a student or a teacher?"
/// (email sign-up asks this inside the registration form).
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String _role = 'student';
  bool _saving = false;
  String? _error;

  Future<void> _continue() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).chooseRole(_role);
      ref.invalidate(teacherAccessProvider);
      if (!mounted) return;
      await continueAfterAuth(context, ref);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(authProvider).user?.fullName.split(' ').first ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(signOutWhenRoot: true),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.waving_hand_rounded, size: 44, color: AppTheme.primaryGreen),
                const SizedBox(height: 12),
                Text(
                  name.isEmpty || name == 'Unknown' ? 'Welcome!' : 'Welcome, $name!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.selectRoleSubtitle ?? 'Are you joining as a student or a teacher?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 28),
                RoleOptionCard(
                  selected: _role == 'student',
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF10B981),
                  title: l10n?.studentRole ?? 'Student',
                  subtitle: l10n?.studentRoleDescription ?? 'Enroll in courses and learn',
                  onTap: () => setState(() => _role = 'student'),
                ),
                const SizedBox(height: 12),
                RoleOptionCard(
                  selected: _role == 'instructor',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF3B82F6),
                  title: l10n?.teacherRole ?? 'Teacher',
                  subtitle: l10n?.teacherRoleDescription ?? 'Teacher guides, lesson tools and your classes',
                  onTap: () => setState(() => _role = 'instructor'),
                ),
                if (_role == 'instructor') ...[
                  const SizedBox(height: 12),
                  const _InfoNote(
                    'Next, tell us where and what you teach. An ECH admin reviews every teacher account, '
                    'then you choose your course(s) to unlock the teacher\'s guides and tools.',
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: _saving ? null : _continue,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can\'t change this later yourself — contact support if you pick the wrong one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Large tappable Student / Teacher choice.
class RoleOptionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const RoleOptionCard({super.key, required this.selected, required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(isDark ? 0.22 : 0.08) : AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : (isDark ? Colors.white24 : Colors.black12), width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: selected ? color : color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: selected ? Colors.white : color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: selected ? color : null)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
              ]),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}
