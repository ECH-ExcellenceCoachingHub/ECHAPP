import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_scenario.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_rooms.dart';

/// One lab room: its activities as a learning path from Beginner to Expert.
class LabRoomScreen extends ConsumerStatefulWidget {
  final String environment;
  const LabRoomScreen({super.key, required this.environment});

  @override
  ConsumerState<LabRoomScreen> createState() => _LabRoomScreenState();
}

class _LabRoomScreenState extends ConsumerState<LabRoomScreen> {
  int? _level; // null = all levels

  @override
  Widget build(BuildContext context) {
    final room = LabRoom.of(widget.environment);
    final labs = ref.watch(labScenariosProvider);
    final summary = ref.watch(labSummaryProvider).valueOrNull ?? LabSummary.empty;
    final theme = Theme.of(context);

    return Scaffold(
      body: labs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load activities: $e')),
        data: (all) {
          final activities = all.where((s) => s.environment == widget.environment).toList()
            ..sort((a, b) => a.difficulty != b.difficulty ? a.difficulty.compareTo(b.difficulty) : a.title.compareTo(b.title));
          final done = activities.where((a) => summary.activities[a.id]?.passed == true).length;
          final next = activities.firstWhere((a) => summary.activities[a.id]?.passed != true, orElse: () => activities.isEmpty ? _placeholder : activities.last);
          final shown = _level == null ? activities : activities.where((a) => a.difficulty == _level).toList();

          return CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 230,
              leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/labs')),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 16),
                title: Text(room.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                background: Stack(fit: StackFit.expand, children: [
                  Image.asset(room.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: room.gradient)))),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.8)]))),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 52,
                    child: Row(children: [
                      Expanded(child: Text(room.tagline, style: TextStyle(color: Colors.white.withValues(alpha: 0.85)))),
                      Text('$done/${activities.length} completed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),
            ),
            if (activities.isNotEmpty && summary.activities[next.id]?.passed != true)
              SliverToBoxAdapter(child: _RecommendedCard(lab: next, onStart: () => _openDetails(next, summary.activities[next.id]))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  children: [
                    _levelChip(null, 'All levels', activities.length),
                    for (final d in LabDifficulty.levels) _levelChip(d.level, d.label, activities.where((a) => a.difficulty == d.level).length),
                  ],
                ),
              ),
            ),
            if (shown.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('No activities at this level yet.')))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final lab = shown[i];
                    final showHeader = i == 0 || shown[i - 1].difficulty != lab.difficulty;
                    final d = LabDifficulty.of(lab.difficulty);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (showHeader)
                        Padding(
                          padding: EdgeInsets.fromLTRB(4, i == 0 ? 8 : 22, 4, 8),
                          child: Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('Level ${d.level} · ${d.label}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(d.blurb, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor))),
                          ]),
                        ),
                      _ActivityTile(
                        lab: lab,
                        number: activities.indexOf(lab) + 1,
                        progress: summary.activities[lab.id],
                        recommended: lab.id == next.id && summary.activities[lab.id]?.passed != true,
                        onTap: () => _openDetails(lab, summary.activities[lab.id]),
                      ),
                    ]);
                  },
                ),
              ),
          ]);
        },
      ),
    );
  }

  static const _placeholder = LabScenario(id: '', slug: '', title: '', summary: '', subject: '', environment: '', level: '', durationMin: 0, xp: 0, stepCount: 0);

  Widget _levelChip(int? level, String label, int count) {
    final color = level == null ? const Color(0xFF64748B) : LabDifficulty.of(level).color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: _level == level,
        showCheckmark: false,
        selectedColor: color.withValues(alpha: 0.2),
        side: BorderSide(color: _level == level ? color : Theme.of(context).dividerColor),
        label: Text('$label  $count', style: TextStyle(fontWeight: _level == level ? FontWeight.w700 : FontWeight.w500)),
        onSelected: (_) => setState(() => _level = level),
      ),
    );
  }

  void _openDetails(LabScenario lab, LabActivityProgress? progress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ActivityDetails(lab: lab, progress: progress, onStart: () {
        Navigator.of(ctx).pop();
        context.push('/lab/${lab.id}');
      }),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final LabScenario lab;
  final VoidCallback onStart;
  const _RecommendedCard({required this.lab, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final d = LabDifficulty.of(lab.difficulty);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [d.color.withValues(alpha: 0.18), d.color.withValues(alpha: 0.05)]),
        border: Border.all(color: d.color.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Icon(Icons.flag_rounded, color: d.color, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RECOMMENDED NEXT', style: TextStyle(color: d.color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(lab.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
        FilledButton.icon(onPressed: onStart, style: FilledButton.styleFrom(backgroundColor: d.color), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start')),
      ]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final LabScenario lab;
  final int number;
  final LabActivityProgress? progress;
  final bool recommended;
  final VoidCallback onTap;
  const _ActivityTile({required this.lab, required this.number, required this.progress, required this.recommended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = LabDifficulty.of(lab.difficulty);
    final passed = progress?.passed == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.brightness == Brightness.dark ? const Color(0xFF151B23) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: recommended ? d.color : theme.dividerColor, width: recommended ? 1.6 : 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed ? const Color(0xFF10B981) : d.color.withValues(alpha: 0.14),
                  border: Border.all(color: passed ? const Color(0xFF10B981) : d.color.withValues(alpha: 0.6), width: 1.5),
                ),
                child: passed
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : Text('$number', style: TextStyle(color: d.color, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lab.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(lab.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.35)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    DifficultyChip(lab.difficulty, compact: true),
                    _Fact(Icons.schedule_rounded, '${lab.durationMin} min'),
                    _Fact(Icons.checklist_rounded, '${lab.stepCount} steps'),
                    if (lab.hintCount > 0) _Fact(Icons.lightbulb_outline_rounded, '${lab.hintCount} hints') else const _Fact(Icons.lightbulb_outline_rounded, 'No hints'),
                    _Fact(Icons.bolt_rounded, '${lab.xp} XP'),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              if (progress != null)
                Column(children: [
                  Text('${progress!.best}%', style: TextStyle(fontWeight: FontWeight.w800, color: passed ? const Color(0xFF10B981) : theme.colorScheme.error)),
                  Text('best', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                ])
              else
                Icon(Icons.chevron_right_rounded, color: theme.hintColor),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).hintColor),
        const SizedBox(width: 3),
        Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor)),
      ]);
}

class _ActivityDetails extends StatelessWidget {
  final LabScenario lab;
  final LabActivityProgress? progress;
  final VoidCallback onStart;
  const _ActivityDetails({required this.lab, required this.progress, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = LabDifficulty.of(lab.difficulty);
    final hintText = lab.hintCount == 0
        ? 'Expert mode: no hints. Dr. ECH will only repeat the instruction if you ask.'
        : 'Stuck? Tap "Hint" during the lab — there are ${lab.hintCount} hints in this activity. Each hint costs 2 points, so try first!';
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DifficultyChip(lab.difficulty),
            const SizedBox(height: 10),
            Text(lab.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(lab.summary, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(avatar: const Icon(Icons.schedule_rounded, size: 16), label: Text('${lab.durationMin} min')),
              Chip(avatar: const Icon(Icons.checklist_rounded, size: 16), label: Text('${lab.stepCount} steps')),
              Chip(avatar: const Icon(Icons.bolt_rounded, size: 16), label: Text('${lab.xp} XP')),
              if (progress != null) Chip(avatar: const Icon(Icons.emoji_events_rounded, size: 16), label: Text('Best ${progress!.best}% · ${progress!.attempts} tries')),
            ]),
            if (lab.objectives.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('You will learn to', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final o in lab.objectives)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: d.color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(o)),
                  ]),
                ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFCD34D).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(child: Text(hintText)),
              ]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(backgroundColor: d.color, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(progress?.passed == true ? 'Play again' : 'Start activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
