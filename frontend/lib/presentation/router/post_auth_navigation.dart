import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';

/// Single source of truth for where a signed-in user goes next.
///
/// Every onboarding step is skipped when the user already supplied that
/// information (e.g. during registration), so nobody is asked twice.

bool userNeedsName(User user) {
  final name = user.fullName.trim();
  return name.isEmpty || name == 'Unknown User';
}

bool userHasPhone(User user) => user.phone?.trim().isNotEmpty ?? false;

bool userHasInterests(User user) => user.interests?.isNotEmpty ?? false;

/// The next onboarding screen [user] still has to see, or null when there is
/// nothing left to collect.
String? nextOnboardingRoute(User user) {
  if (userNeedsName(user)) return '/name-collection';
  if (user.hasCompletedOnboarding) return null;
  if (!userHasInterests(user)) return '/interest-selection';
  if (!userHasPhone(user)) return '/phone-collection';
  return null;
}

/// Routes the current user to the next missing onboarding step, or home when
/// everything is already provided (marking onboarding complete on the way).
Future<void> continueAfterAuth(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  if (user == null) return;

  if (user.role == 'admin') {
    context.go('/admin');
    return;
  }
  if (user.role == 'instructor') {
    context.go('/teacher/dashboard');
    return;
  }

  final next = nextOnboardingRoute(user);
  if (next != null) {
    context.go(next);
    return;
  }

  if (!user.hasCompletedOnboarding) {
    await markOnboardingComplete(ref);
    if (!context.mounted) return;
  }
  await goHome(context, ref);
}

Future<void> markOnboardingComplete(WidgetRef ref) async {
  try {
    await ref
        .read(authProvider.notifier)
        .updateProfile(hasCompletedOnboarding: true);
  } catch (e) {
    debugPrint('markOnboardingComplete: backend update failed: $e');
  }
  // Persist locally either way so the user isn't bounced back to onboarding.
  await StorageManager().saveHasCompletedOnboarding(true);
}

/// Courses page for users with no enrollments yet, dashboard otherwise.
Future<void> goHome(BuildContext context, WidgetRef ref) async {
  try {
    final enrolledCourses = await ref.read(enrolledCoursesProvider.future);
    if (!context.mounted) return;
    context.go(enrolledCourses.isEmpty ? '/courses' : '/dashboard');
  } catch (e) {
    debugPrint('goHome: error checking enrolled courses: $e');
    if (context.mounted) context.go('/dashboard');
  }
}
