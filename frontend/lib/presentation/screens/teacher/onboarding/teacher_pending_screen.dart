import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/teacher_access_service.dart';
import '../../../providers/teacher_access_provider.dart';
import 'teacher_journey_widgets.dart';

/// Step 2: waiting for an admin to approve (or fix-and-resubmit after a rejection).
class TeacherPendingScreen extends ConsumerWidget {
  const TeacherPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(teacherAccessProvider);
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const Text('Teacher account'), automaticallyImplyLeading: false, actions: const [TeacherLogoutButton()]),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Retry(message: e.toString(), onRetry: () => ref.invalidate(teacherAccessProvider)),
        data: (s) {
          final next = s.gateRoute;
          if (next != '/teacher/pending') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(next ?? '/teacher/dashboard');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherAccessProvider),
            child: ListView(children: [
              const TeacherJourneyProgress(current: 1),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: s.rejected ? _Rejected(status: s) : _Waiting(status: s),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Waiting extends ConsumerWidget {
  final TeacherAccessStatus status;
  const _Waiting({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = status.profile;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      const Icon(Icons.hourglass_top_rounded, size: 64, color: Color(0xFFF59E0B)),
      const SizedBox(height: 12),
      const Text('Your account is being reviewed', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(
        'An ECH admin is checking your teacher profile. This usually takes less than a day. '
        'We will notify you as soon as you are approved — then you can choose your course(s).',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).hintColor, height: 1.4),
      ),
      const SizedBox(height: 20),
      _ProfileCard(profile: p),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size.fromHeight(48)),
        onPressed: () => ref.invalidate(teacherAccessProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Check again'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => context.push('/teacher/onboarding'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit my profile'),
      ),
      const SizedBox(height: 16),
      Text(
        'Questions? info@excellencecoachinghub.com · +250 788 535 156',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      ),
    ]);
  }
}

class _Rejected extends StatelessWidget {
  final TeacherAccessStatus status;
  const _Rejected({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      const Icon(Icons.report_gmailerrorred_rounded, size: 64, color: Colors.redAccent),
      const SizedBox(height: 12),
      const Text('Your application needs changes', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      if ((status.reviewReason ?? '').isNotEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Message from the admin', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(status.reviewReason!),
          ]),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size.fromHeight(48)),
        onPressed: () => context.push('/teacher/onboarding'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Update profile and resubmit'),
      ),
    ]);
  }
}

class _ProfileCard extends StatelessWidget {
  final TeacherProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData i, String label, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, size: 18, color: Theme.of(context).hintColor),
              const SizedBox(width: 10),
              SizedBox(width: 90, child: Text(label, style: TextStyle(color: Theme.of(context).hintColor))),
              Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          );
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          row(Icons.apartment_outlined, 'School', profile.school),
          row(Icons.location_on_outlined, 'Location', [profile.district, profile.province].where((e) => e.isNotEmpty).join(', ')),
          row(Icons.class_outlined, 'Classes', profile.levels.join(', ')),
          row(Icons.menu_book_outlined, 'Subjects', profile.subjects.join(', ')),
        ]),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Retry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}
