import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import 'school_i18n.dart';

/// Bottom bar of a school student: Home · Work · Learn · Class.
///
/// Used by the school home itself and by shared pages (lab, library,
/// courses, messages…) so a school student never sees the private-learner bar.
/// Without [onSelect] a tap goes back to that tab of `/school/home`.
class SchoolStudentNavBar extends StatelessWidget {
  const SchoolStudentNavBar({super.key, required this.selected, this.onSelect, this.workBadge = 0, this.classBadge = 0});
  final int selected;
  final ValueChanged<int>? onSelect;
  final int workBadge;
  final int classBadge;

  static const green = Color(0xFF0E9F6E);

  /// Which tab a shared page belongs to.
  static int tabForRoute(String path) {
    if (path.startsWith('/messages') || path.startsWith('/school/groups')) return 3;
    const learn = ['/labs', '/library', '/courses', '/course', '/downloads', '/upcoming-sessions', '/live', '/categories', '/my-courses'];
    if (learn.any(path.startsWith)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon(IconData i, int n, {Color? color}) => Badge(isLabelVisible: n > 0, label: Text(n > 99 ? '99+' : '$n'), child: Icon(i, color: color));
    return NavigationBar(
      selectedIndex: selected,
      // `at` makes every tap a new location, so the home switches tab even
      // when the same tab number was asked for before.
      onDestinationSelected: onSelect ?? (i) => context.go('/school/home?tab=$i&at=${DateTime.now().millisecondsSinceEpoch}'),
      backgroundColor: AppTheme.getCardColor(context),
      indicatorColor: green.withValues(alpha: 0.18),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded, color: green), label: trSchool(context, 'Home')),
        NavigationDestination(icon: icon(Icons.assignment_outlined, workBadge), selectedIcon: icon(Icons.assignment_rounded, workBadge, color: green), label: trSchool(context, 'Work')),
        NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), selectedIcon: const Icon(Icons.auto_stories_rounded, color: green), label: trSchool(context, 'Learn')),
        NavigationDestination(icon: icon(Icons.groups_outlined, classBadge), selectedIcon: icon(Icons.groups_rounded, classBadge, color: green), label: trSchool(context, 'Class')),
      ],
    );
  }
}

/// Slim bar for parents and school admins on shared pages: back to their home.
class SchoolHomeReturnBar extends StatelessWidget {
  const SchoolHomeReturnBar({super.key, required this.homeRoute});
  final String homeRoute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.getCardColor(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go(homeRoute),
              icon: const Icon(Icons.home_rounded),
              label: Text(trSchool(context, 'Back to home')),
            ),
          ),
        ),
      ),
    );
  }
}
