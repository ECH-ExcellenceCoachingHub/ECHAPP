import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/teacher_access_provider.dart';

/// Wraps every teacher screen. A self-registered teacher who has not finished
/// the journey (profile → admin approval → an approved course) is sent to the
/// step they are on instead. The backend enforces the same rule on every
/// teacher API, so this is about guiding the teacher, not security.
class TeacherAccessGate extends ConsumerWidget {
  final Widget child;
  const TeacherAccessGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(teacherAccessProvider);
    return access.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(teacherAccessProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ]),
          ),
        ),
      ),
      data: (status) {
        final gate = status.gateRoute;
        if (gate == null) return child;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(gate);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
