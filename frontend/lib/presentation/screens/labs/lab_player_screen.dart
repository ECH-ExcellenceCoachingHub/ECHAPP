import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_scenario.dart';
import '../../../services/labs/lab_launcher.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_frame.dart';
import '../../widgets/labs/lab_widgets.dart';

/// Opens one lab: choose how to experience it (screen / phone VR viewer / headset),
/// mint a lab session, then run it in the best way this device supports.
class LabPlayerScreen extends ConsumerStatefulWidget {
  final String scenarioId;
  final String? lessonId;
  const LabPlayerScreen({super.key, required this.scenarioId, this.lessonId});

  @override
  ConsumerState<LabPlayerScreen> createState() => _LabPlayerScreenState();
}

class _LabPlayerScreenState extends ConsumerState<LabPlayerScreen> {
  LabSessionTicket? _ticket;
  LabViewMode? _mode;
  bool _busy = false;
  String? _error;
  String? _status;
  bool _embedded = false;

  Future<void> _start(LabViewMode mode) async {
    if (mode == LabViewMode.headset) {
      await showConnectHeadsetDialog(context, ref, scenarioId: widget.scenarioId, lessonId: widget.lessonId);
      return;
    }
    setState(() { _busy = true; _error = null; _mode = mode; });
    try {
      final lang = Localizations.localeOf(context).languageCode == 'rw' ? 'rw' : 'en';
      final t = _ticket ?? await ref.read(labServiceProvider).startSession(scenarioId: widget.scenarioId, lessonId: widget.lessonId, lang: lang);
      _ticket = t;
      switch (LabLauncher.kind) {
        case LabLaunchKind.embeddedWeb:
          setState(() { _embedded = true; _busy = false; });
        case LabLaunchKind.windowsApp:
          await LabLauncher.launchWindows(t, mode);
          setState(() { _busy = false; _status = 'The lab opened in its own window. Your results are saved automatically.'; });
        case LabLaunchKind.browser:
          final ok = await LabLauncher.openInBrowser(t, mode);
          setState(() {
            _busy = false;
            _status = ok
                ? (mode == LabViewMode.cardboard
                    ? 'Opened in your browser. Turn your phone sideways and place it in the viewer.'
                    : 'The lab opened in your browser. Your results are saved automatically.')
                : null;
            _error = ok ? null : 'Could not open the lab.';
          });
      }
    } catch (e) {
      setState(() { _busy = false; _error = e.toString().replaceFirst('ApiException: ', ''); });
    }
  }

  void _onLabMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'completed':
        ref.invalidate(labSummaryProvider);
        final passed = m['passed'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(passed ? 'Lab passed with ${m['score']}%! 🎉' : 'Lab finished — score ${m['score']}%.'),
          backgroundColor: passed ? const Color(0xFF047857) : null,
        ));
      case 'exit':
        _close();
    }
  }

  void _close() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ref.invalidate(labSummaryProvider);
    if (context.canPop()) context.pop(); else context.go('/labs');
  }

  @override
  Widget build(BuildContext context) {
    if (_embedded && _ticket != null && _mode != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        body: Stack(children: [
          Positioned.fill(child: LabFrame(url: LabLauncher.webUrlFor(_ticket!, _mode!), onMessage: _onLabMessage)),
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(child: IconButton.filledTonal(onPressed: _close, icon: const Icon(Icons.close_rounded), tooltip: 'Leave lab')),
          ),
        ]),
      );
    }

    final lab = ref.watch(labScenarioProvider(widget.scenarioId));
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Lab'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _close)),
      body: lab.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load the lab: $e')),
        data: (l) => _Launcher(
          lab: l,
          busy: _busy,
          error: _error,
          status: _status,
          onStart: _start,
        ),
      ),
    );
  }
}

class _Launcher extends StatelessWidget {
  final LabScenario lab;
  final bool busy;
  final String? error, status;
  final void Function(LabViewMode) onStart;
  const _Launcher({required this.lab, required this.busy, required this.onStart, this.error, this.status});

  @override
  Widget build(BuildContext context) {
    final s = LabSubjectStyle.of(lab.subject);
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
            height: 180,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: s.gradient)),
            child: Stack(children: [
              Positioned(right: -10, bottom: -20, child: Icon(s.icon, size: 170, color: Colors.white.withValues(alpha: 0.18))),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(s.label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(lab.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(lab.summary, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Chip(avatar: const Icon(Icons.schedule_rounded, size: 16), label: Text('${lab.durationMin} min')),
            Chip(avatar: const Icon(Icons.checklist_rounded, size: 16), label: Text('${lab.stepCount} steps')),
            Chip(avatar: const Icon(Icons.bolt_rounded, size: 16), label: Text('${lab.xp} XP')),
          ]),
          const SizedBox(height: 20),
          Text('How do you want to do this experiment?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _ModeTile(icon: Icons.desktop_windows_rounded, title: kIsWeb || !LabLauncher.canUseCardboard ? 'On this screen' : 'On this phone', subtitle: 'Point, tap and drag. Best for most students.', primary: true, busy: busy, onTap: () => onStart(LabViewMode.screen)),
          if (LabLauncher.canUseCardboard || kIsWeb)
            _ModeTile(icon: Icons.view_in_ar_rounded, title: 'Phone VR viewer', subtitle: 'Cardboard-style headset: look around, gaze to select, tap the viewer button.', busy: busy, onTap: () => onStart(LabViewMode.cardboard)),
          _ModeTile(icon: Icons.vrpano_rounded, title: 'VR headset', subtitle: 'Meta Quest, Pico or PC VR — connect with a 6-digit code.', busy: busy, onTap: () => onStart(LabViewMode.headset)),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: theme.colorScheme.error))),
          if (status != null)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)), const SizedBox(width: 10), Expanded(child: Text(status!))]),
            ),
        ]),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool primary, busy;
  final VoidCallback onTap;
  const _ModeTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.primary = false, this.busy = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: primary ? const Color(0xFF10B981).withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: primary ? const Color(0xFF10B981) : Colors.transparent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Icon(icon, size: 30, color: primary ? const Color(0xFF10B981) : null),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            trailing: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_rounded),
            onTap: busy ? null : onTap,
          ),
        ),
      );
}
