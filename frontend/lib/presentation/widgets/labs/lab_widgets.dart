import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_scenario.dart';
import '../../providers/lab_provider.dart';

/// Visual identity per lab family.
class LabSubjectStyle {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const LabSubjectStyle(this.label, this.icon, this.gradient);

  static const _styles = {
    'chemistry': LabSubjectStyle('Chemistry', Icons.science_rounded, [Color(0xFF10B981), Color(0xFF047857)]),
    'physics': LabSubjectStyle('Physics', Icons.bolt_rounded, [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
    'biology': LabSubjectStyle('Biology', Icons.biotech_rounded, [Color(0xFF84CC16), Color(0xFF3F6212)]),
    'cybersecurity': LabSubjectStyle('Cybersecurity', Icons.shield_rounded, [Color(0xFFF43F5E), Color(0xFF9F1239)]),
    'networking': LabSubjectStyle('Networking', Icons.lan_rounded, [Color(0xFF8B5CF6), Color(0xFF5B21B6)]),
    'coding': LabSubjectStyle('Coding & AI', Icons.code_rounded, [Color(0xFFF59E0B), Color(0xFFB45309)]),
  };

  static LabSubjectStyle of(String subject) => _styles[subject] ?? const LabSubjectStyle('Lab', Icons.science_outlined, [Color(0xFF64748B), Color(0xFF334155)]);
  static List<String> get subjects => _styles.keys.toList();
}

/// A lab card: gradient "scene" header with the subject icon, then title, summary and facts.
class LabCard extends StatelessWidget {
  final LabScenario lab;
  final VoidCallback onStart;
  const LabCard({super.key, required this.lab, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final s = LabSubjectStyle.of(lab.subject);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF151B23) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onStart,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: s.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
                    if (lab.thumbnail != null) Image.network(lab.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                    // Soft "hologram" grid for a modern lab feel.
                    CustomPaint(painter: _GridPainter()),
                    Positioned(right: -12, bottom: -18, child: Icon(s.icon, size: 120, color: Colors.white.withValues(alpha: 0.18))),
                    Positioned(
                      left: 14,
                      top: 12,
                      child: _Pill(text: s.label.toUpperCase(), icon: s.icon),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Pill(text: '+${lab.xp} XP', icon: Icons.bolt_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(lab.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(lab.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.35)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
                child: Row(
                  children: [
                    _Fact(Icons.schedule_rounded, '${lab.durationMin} min'),
                    const SizedBox(width: 12),
                    _Fact(Icons.checklist_rounded, '${lab.stepCount} steps'),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(backgroundColor: s.gradient.first, padding: const EdgeInsets.symmetric(horizontal: 14), visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 22) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 22) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Pill({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        ]),
      );
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor)),
      ]);
}

/// Shown in the lesson player's "Lab" tab.
class LessonLabCard extends ConsumerWidget {
  final String scenarioId;
  final String lessonId;
  final bool required;
  const LessonLabCard({super.key, required this.scenarioId, required this.lessonId, this.required = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lab = ref.watch(labScenarioProvider(scenarioId));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: lab.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Could not load the lab: $e'),
            data: (l) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: 300, child: LabCard(lab: l, onStart: () => context.push('/lab/${l.id}?lesson=$lessonId'))),
              if (required) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.flag_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Pass this lab to complete the lesson.')),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Enter the 6-digit code shown inside a VR headset (Quest/Pico browser or ECH Labs VR app).
Future<void> showConnectHeadsetDialog(BuildContext context, WidgetRef ref, {String? scenarioId, String? lessonId}) async {
  final controller = TextEditingController();
  String? error;
  bool busy = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      Future<void> submit() async {
        final code = controller.text.replaceAll(RegExp(r'\D'), '');
        if (code.length != 6) { setState(() => error = 'Enter the 6 digits shown in the headset'); return; }
        setState(() { busy = true; error = null; });
        try {
          final device = await ref.read(labServiceProvider).confirmHeadset(code, scenarioId: scenarioId, lessonId: lessonId);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$device connected — the lab starts in your headset.')));
        } catch (e) {
          setState(() { busy = false; error = e.toString().replaceFirst('ApiException: ', ''); });
        }
      }

      return AlertDialog(
        title: const Row(children: [Icon(Icons.vrpano_rounded), SizedBox(width: 10), Text('Connect a VR headset')]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('1. Put on your headset and open ECH Labs (or labs.excellencecoachinghub.com in the headset browser).\n2. Enter the code it shows:'),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(7)],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, letterSpacing: 10, fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: '123 456', errorText: error, border: const OutlineInputBorder()),
            onSubmitted: (_) => submit(),
          ),
        ]),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect')),
        ],
      );
    }),
  );
}
