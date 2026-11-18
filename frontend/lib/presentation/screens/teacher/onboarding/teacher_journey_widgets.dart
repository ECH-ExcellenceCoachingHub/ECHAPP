import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';

/// "Profile → Approval → Choose course → Teach" header shown on every step
/// of a new teacher's journey, so they always know where they are.
class TeacherJourneyProgress extends StatelessWidget {
  /// 0 profile, 1 approval, 2 choose course, 3 teach
  final int current;
  final int profileStep;
  final int profileSteps;
  const TeacherJourneyProgress({super.key, required this.current, this.profileStep = 0, this.profileSteps = 1});

  static const _labels = ['Profile', 'Approval', 'Choose course', 'Teach'];
  static const _icons = [Icons.badge_outlined, Icons.verified_user_outlined, Icons.menu_book_outlined, Icons.school_outlined];

  @override
  Widget build(BuildContext context) {
    final green = AppTheme.primaryGreen;
    final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(children: [
            for (var i = 0; i < _labels.length; i++) ...[
              Expanded(
                child: Column(children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: i < current ? green : (i == current ? green.withOpacity(0.15) : muted),
                    child: Icon(i < current ? Icons.check : _icons[i], size: 16, color: i < current ? Colors.white : (i == current ? green : Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: i == current ? FontWeight.w800 : FontWeight.w500, color: i <= current ? null : Colors.grey),
                  ),
                  if (i == current && current == 0 && profileSteps > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                      child: LinearProgressIndicator(value: (profileStep + 1) / profileSteps, minHeight: 3, color: green, backgroundColor: muted),
                    ),
                ]),
              ),
              if (i < _labels.length - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: SizedBox(width: 16, child: Divider(thickness: 2, color: i < current ? green : muted)),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Lets a teacher who is still in the journey sign out.
class TeacherLogoutButton extends ConsumerWidget {
  const TeacherLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Log out?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Log out')),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        await ref.read(authProvider.notifier).logout();
        if (!context.mounted) return;
        final desktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
        context.go(desktop ? '/email-auth-option' : '/auth-selection');
      },
    );
  }
}
