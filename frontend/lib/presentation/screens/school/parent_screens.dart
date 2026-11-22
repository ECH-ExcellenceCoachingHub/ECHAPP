import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/pickers.dart';
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
          T('Hello ${user?.fullName.split(' ').first ?? ''}. Here is how your children are doing at school.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
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
    return Material(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/parent/child/${k['id']}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(child: Text(initialsOf(k['fullName']))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${k['fullName']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.getTextColor(context))),
                  Text([k['classroom']?['name'], k['school']?['name']].where((e) => e != null).join(' · '), style: TextStyle(color: muted)),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              StatusPill('${stats['todo'] ?? 0} to do', tone: Tone.info),
              if ((stats['overdue'] ?? 0) > 0) StatusPill('${stats['overdue']} overdue', tone: Tone.bad),
              if ((stats['missed'] ?? 0) > 0) StatusPill('${stats['missed']} missed', tone: Tone.warn),
              StatusPill('${stats['submitted'] ?? 0} handed in', tone: Tone.good),
            ]),
            if (subjects.any((s) => s['averagePercent'] != null)) ...[
              const SizedBox(height: 12),
              for (final s in subjects.where((s) => s['averagePercent'] != null))
                Padding(padding: const EdgeInsets.only(bottom: 6), child: ProgressLine(percent: (s['averagePercent'] as num).toInt(), label: '${s['subject']}')),
            ],
          ]),
        ),
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
        builder: (context, d, reload) => StudentOverviewView(data: d, onRefresh: reload, forParent: true),
      ),
    );
  }
}
