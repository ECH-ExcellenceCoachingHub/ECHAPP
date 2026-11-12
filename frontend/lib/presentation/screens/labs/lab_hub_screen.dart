import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_scenario.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_rooms.dart';
import '../../widgets/labs/lab_widgets.dart';

/// "Virtual Labs": choose one of the 3D lab rooms, then an activity inside it.
class LabHubScreen extends ConsumerWidget {
  const LabHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labs = ref.watch(labScenariosProvider);
    final summary = ref.watch(labSummaryProvider).valueOrNull ?? LabSummary.empty;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1200 ? 3 : width > 720 ? 2 : 1;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(labScenariosProvider);
          ref.invalidate(labSummaryProvider);
          await ref.read(labScenariosProvider.future);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Hero(summary: summary, onHeadset: () => showConnectHeadsetDialog(context, ref))),
          if (summary.continueItems.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                title: 'Continue where you left off',
                child: SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: summary.continueItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _ContinueTile(item: summary.continueItems[i]),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Choose a lab', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Every lab has activities from Beginner to Expert. Start easy — hints are there when you need them.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
              ]),
            ),
          ),
          labs.when(
            loading: () => const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 8),
                Text('Could not load labs. $e', textAlign: TextAlign.center),
                TextButton(onPressed: () => ref.invalidate(labScenariosProvider), child: const Text('Try again')),
              ])),
            ),
            data: (all) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 16, crossAxisSpacing: 16, mainAxisExtent: 300),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final room = LabRoom.all[i];
                    final activities = all.where((s) => s.environment == room.environment).toList();
                    final done = activities.where((s) => summary.activities[s.id]?.passed == true).length;
                    return _RoomCard(room: room, activities: activities, completed: done, onOpen: () => context.push('/labs/room/${room.environment}'));
                  },
                  childCount: LabRoom.all.length,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final LabRoom room;
  final List<LabScenario> activities;
  final int completed;
  final VoidCallback onOpen;
  const _RoomCard({required this.room, required this.activities, required this.completed, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = activities.length;
    final levels = activities.map((a) => a.difficulty).toSet();
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      color: theme.brightness == Brightness.dark ? const Color(0xFF151B23) : Colors.white,
      child: InkWell(
        onTap: onOpen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(room.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: room.gradient)))),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)]),
                ),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: room.gradient), borderRadius: BorderRadius.circular(12)),
                  child: Icon(room.icon, color: Colors.white, size: 22),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20)),
                  child: Text('$total activities', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(room.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(room.tagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final d in LabDifficulty.levels)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: d.label,
                      child: Container(width: 22, height: 6, decoration: BoxDecoration(color: levels.contains(d.level) ? d.color : theme.dividerColor, borderRadius: BorderRadius.circular(3))),
                    ),
                  ),
                const SizedBox(width: 6),
                Text('Beginner → Expert', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                const Spacer(),
                Text('$completed/$total done', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: total == 0 ? 0 : completed / total, minHeight: 6, color: room.gradient.first, backgroundColor: theme.dividerColor),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final LabSummary summary;
  final VoidCallback onHeadset;
  const _Hero({required this.summary, required this.onHeadset});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF0B1F1A), Color(0xFF0F2D44)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Flex(
        direction: narrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: narrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          _LevelRing(summary: summary),
          SizedBox(width: narrow ? 0 : 24, height: narrow ? 16 : 0),
          Flexible(
            fit: narrow ? FlexFit.loose : FlexFit.tight,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(8)),
                child: const Text('ECH VIRTUAL LABS', style: TextStyle(color: Color(0xFF032219), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.4)),
              ),
              const SizedBox(height: 10),
              const Text('Do real experiments — in 3D and VR', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
              const SizedBox(height: 6),
              Text('Pick a lab, choose an activity and work at your own level. Your phone, computer, a phone VR viewer or a VR headset all work.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.4)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final b in summary.badges.take(4))
                  Chip(
                    avatar: const Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFFFCD34D)),
                    label: Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: const BorderSide(color: Colors.white12),
                  ),
                OutlinedButton.icon(
                  onPressed: onHeadset,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
                  icon: const Icon(Icons.vrpano_rounded, size: 18),
                  label: const Text('Connect VR headset'),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LevelRing extends StatelessWidget {
  final LabSummary summary;
  const _LevelRing({required this.summary});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        height: 112,
        child: CustomPaint(
          painter: _RingPainter(summary.levelProgress),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('LEVEL', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              Text('${summary.level}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.1)),
              Text('${summary.xp} XP', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 9;
    final fg = Paint()
      ..shader = const SweepGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF10B981)]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(6), 0, math.pi * 2, false, bg);
    canvas.drawArc(rect.deflate(6), -math.pi / 2, math.pi * 2 * progress.clamp(0.02, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8), child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        child,
      ]);
}

class _ContinueTile extends StatelessWidget {
  final LabContinue item;
  const _ContinueTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final s = LabSubjectStyle.of(item.subject);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/lab/${item.scenarioId}'),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(gradient: LinearGradient(colors: s.gradient), borderRadius: BorderRadius.circular(12)),
            child: Icon(s.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${item.completedSteps} steps done · tap to resume', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981)),
        ]),
      ),
    );
  }
}
