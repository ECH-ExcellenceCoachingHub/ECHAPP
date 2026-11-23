import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';
import '../../providers/auth_provider.dart';
import 'student_school_screens.dart';

/// Parent home: one card per child with homework status and averages.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const T('My children'),
        actions: [
          IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'pin') showChangePinDialog(context);
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth-selection');
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'pin', child: T('Change my PIN')), PopupMenuItem(value: 'logout', child: T('Sign out'))],
          ),
        ],
      ),
      body: AsyncBody<List<Map<String, dynamic>>>(
        load: () => SchoolService().children(),
        builder: (context, kids, reload) => SchoolPage(onRefresh: reload, maxWidth: 900, children: [
          PageHero(
            leading: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
            ),
            title: 'Hello ${user?.fullName.split(' ').first ?? ''}',
            subtitle: 'How your children are doing at school. You can help with homework from here.',
          ),
          if (kids.isEmpty)
            const EmptyState(icon: Icons.family_restroom_outlined, title: 'No children linked', message: 'Ask the school to add your phone number to your child\'s record.')
          else
            for (final k in kids) _ChildCard(k: k),
        ]),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.k});
  final Map<String, dynamic> k;

  @override
  Widget build(BuildContext context) {
    final stats = Map<String, dynamic>.from(k['stats'] as Map? ?? {});
    final subjects = SchoolService.list(k['subjects']);
    final muted = AppTheme.getSecondaryTextColor(context);
    void open() => context.push('/parent/child/${k['id']}');
    return Semantics(
      container: true,
      child: Container(
        decoration: cardDecoration(context),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: open,
            child: Row(children: [
              InitialsAvatar('${k['fullName']}', radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${k['fullName']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.getTextColor(context))),
                  Text([k['classroom']?['name'], k['school']?['name']].where((e) => e != null).join(' · '), style: TextStyle(color: muted, fontSize: 13)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          MiniStats(items: [
            MiniStat('${stats['todo'] ?? 0}', 'To do', tone: Tone.info),
            MiniStat('${stats['overdue'] ?? 0}', 'Overdue', tone: (stats['overdue'] ?? 0) > 0 ? Tone.bad : Tone.neutral),
            MiniStat('${stats['missed'] ?? 0}', 'Missed', tone: (stats['missed'] ?? 0) > 0 ? Tone.warn : Tone.neutral),
            MiniStat('${stats['submitted'] ?? 0}', 'Handed in', tone: Tone.good),
          ]),
          if (subjects.any((s) => s['averagePercent'] != null)) ...[
            const SizedBox(height: 14),
            for (final s in subjects.where((s) => s['averagePercent'] != null))
              Padding(padding: const EdgeInsets.only(bottom: 8), child: ProgressLine(percent: (s['averagePercent'] as num).toInt(), label: '${s['subject']}')),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: open,
            icon: const Icon(Icons.arrow_forward),
            label: T((stats['todo'] ?? 0) > 0 ? 'See homework and help' : 'Open'),
          ),
        ]),
      ),
    );
  }
}

/// Parent: everything about one child.
class ParentChildScreen extends StatelessWidget {
  const ParentChildScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const T('Child')),
      body: AsyncBody<Map<String, dynamic>>(
        load: () => SchoolService().child(childId),
        builder: (context, d, reload) => StudentOverviewView(
          data: d,
          onRefresh: reload,
          forParent: true,
          onOpenHomework: (a) async {
            await context.push('/parent/child/$childId/homework/${a['id']}');
            reload();
          },
          onJoinExam: (a) => joinClassExam(context, a, childId: childId),
        ),
      ),
    );
  }
}
