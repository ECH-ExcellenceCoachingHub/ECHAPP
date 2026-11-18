import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Back arrow that always works: pops when there is a previous page, otherwise
/// goes to [fallback]. With [signOutWhenRoot] (sign-up steps that have nothing
/// behind them) it offers to sign out and return to the sign-in screen instead.
class SmartBackButton extends ConsumerWidget {
  final String fallback;
  final bool signOutWhenRoot;
  final Color? color;
  const SmartBackButton({super.key, this.fallback = '/', this.signOutWhenRoot = false, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Back',
      color: color,
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () async {
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (!signOutWhenRoot) {
          context.go(fallback);
          return;
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Leave for now?'),
            content: const Text('You will be signed out. Sign in again any time to continue where you left off.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out')),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        await ref.read(authProvider.notifier).logout();
        if (!context.mounted) return;
        final desktop = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
        context.go(desktop ? '/email-auth-option' : '/auth-selection');
      },
    );
  }
}
