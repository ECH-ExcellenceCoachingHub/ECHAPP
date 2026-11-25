import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_project.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_rooms.dart';

/// "My experiments": the student's own lab projects — create, run, edit, share.
class LabProjectsScreen extends ConsumerWidget {
  const LabProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(myLabProjectsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My experiments', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/labs')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startNewExperiment(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New experiment'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myLabProjectsProvider.future),
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Could not load your experiments\n$e', textAlign: TextAlign.center)),
            const SizedBox(height: 12),
            Center(child: FilledButton(onPressed: () => ref.invalidate(myLabProjectsProvider), child: const Text('Try again'))),
          ]),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              const _Intro(),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 52, color: theme.hintColor),
                    const SizedBox(height: 10),
                    Text('No experiments yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Tap "New experiment" to design your first one.', style: TextStyle(color: theme.hintColor)),
                  ]),
                )
              else
                for (final p in list) _ProjectTile(project: p),
            ],
          ),
        ),
      ),
    );
  }
}

/// Room picker → builder (blank, or drafted by the AI from an idea).
Future<void> startNewExperiment(BuildContext context, WidgetRef ref, {String? environment}) async {
  final room = environment ?? await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
        Text('Which lab will you work in?', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final r in LabRoom.all)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: LinearGradient(colors: r.gradient), borderRadius: BorderRadius.circular(10)),
              child: Icon(r.icon, color: Colors.white),
            ),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(r.tagline),
            onTap: () => Navigator.of(ctx).pop(r.environment),
          ),
      ]),
    ),
  );
  if (room == null || !context.mounted) return;
  final how = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('How do you want to start?', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.construction_rounded, size: 32),
            title: const Text('Build it myself', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Choose equipment, then write your own steps.'),
            onTap: () => Navigator.of(ctx).pop('blank'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome_rounded, size: 32, color: Color(0xFF8B5CF6)),
            title: const Text('Start from my idea (AI helper)', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Describe what you want to find out. The AI drafts it, you change anything.'),
            onTap: () => Navigator.of(ctx).pop('ai'),
          ),
        ]),
      ),
    ),
  );
  if (how == null || !context.mounted) return;
  if (how == 'blank') {
    context.push('/labs/projects/new', extra: {'spec': {'environment': room, 'title': '', 'equipment': [], 'steps': []}});
    return;
  }
  final idea = await showDialog<String>(context: context, builder: (_) => const _IdeaDialog());
  if (idea == null || !context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Expanded(child: Text('Designing your experiment…'))])),
  );
  try {
    final spec = await ref.read(labServiceProvider).projectFromIdea(room, idea);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    context.push('/labs/projects/new', extra: {'spec': spec});
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

class _IdeaDialog extends StatefulWidget {
  const _IdeaDialog();
  @override
  State<_IdeaDialog> createState() => _IdeaDialogState();
}

class _IdeaDialogState extends State<_IdeaDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('What do you want to find out?'),
        content: TextField(
          controller: _c,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 1500,
          decoration: const InputDecoration(
            hintText: 'e.g. "Does a longer pendulum swing more slowly?" or "How much NaOH neutralises vinegar?"',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_c.text.trim().length < 15) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe your idea in a sentence or two.')));
                return;
              }
              Navigator.pop(context, _c.text.trim());
            },
            child: const Text('Draft it'),
          ),
        ],
      );
}

class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF0F2D44)]),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Be the scientist', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Ask a question, choose your equipment and settings, write your own method, then do it in the 3D lab. '
            'Your readings are checked against the real simulation. Proud of one? Send it to your teachers — they can publish it for the whole school.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ]),
      );
}

class _ProjectTile extends ConsumerWidget {
  final LabProject project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final room = LabRoom.of(project.environment);
    final p = project;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/labs/projects/${p.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: LinearGradient(colors: room.gradient), borderRadius: BorderRadius.circular(10)),
                child: Icon(room.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text('${room.title} · ${p.stepCount} steps', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ]),
              ),
              _StatusChip(status: p.status, label: p.statusLabel),
            ]),
            if (p.aim.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Aim: ${p.aim}', maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ],
            if (p.best != null) ...[
              const SizedBox(height: 6),
              Text('Best run: ${p.best}% · ${p.attempts} ${p.attempts == 1 ? 'run' : 'runs'}${p.passed ? ' · completed' : ''}',
                  style: theme.textTheme.labelMedium?.copyWith(color: p.passed ? const Color(0xFF10B981) : theme.hintColor, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              FilledButton.icon(
                onPressed: () => context.push('/lab/${p.id}'),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Run in 3D'),
              ),
              OutlinedButton.icon(onPressed: () => context.push('/labs/projects/${p.id}/edit'), icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Edit')),
              OutlinedButton.icon(onPressed: () => _conclusion(context, ref), icon: const Icon(Icons.edit_note_rounded, size: 18), label: Text(p.conclusion.isEmpty ? 'Write conclusion' : 'Conclusion')),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) => _menu(context, ref, v),
                itemBuilder: (_) => [
                  if (p.status == 'draft') const PopupMenuItem(value: 'share', child: Text('Send to my teachers')),
                  if (p.status == 'review') const PopupMenuItem(value: 'unshare', child: Text('Make private again')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, String v) async {
    final svc = ref.read(labServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (v == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this experiment?'),
            content: Text('"${project.title}" will be removed from your list.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
          ),
        );
        if (ok != true) return;
        await svc.deleteProject(project.id);
        messenger.showSnackBar(const SnackBar(content: Text('Experiment deleted')));
      } else {
        await svc.shareProject(project.id, share: v == 'share');
        messenger.showSnackBar(SnackBar(content: Text(v == 'share' ? 'Sent to your teachers for review' : 'Your experiment is private again')));
      }
      ref.invalidate(myLabProjectsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _conclusion(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: project.conclusion);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conclusion'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (project.hypothesis.isNotEmpty) Text('Your hypothesis: ${project.hypothesis}', style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'What did your results show? Was your hypothesis right? What would you improve?'),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save'))],
      ),
    );
    c.dispose();
    if (text == null) return;
    try {
      await ref.read(labServiceProvider).saveConclusion(project.id, text);
      ref.invalidate(myLabProjectsProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status, label;
  const _StatusChip({required this.status, required this.label});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) { 'review' => const Color(0xFFF59E0B), 'published' => const Color(0xFF10B981), _ => const Color(0xFF64748B) };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
