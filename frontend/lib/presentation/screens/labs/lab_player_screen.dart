import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lab_scenario.dart';
import '../../../services/labs/lab_launcher.dart';
import '../../providers/lab_provider.dart';
import '../../widgets/labs/lab_frame.dart';
import '../../widgets/labs/lab_webview.dart';
import '../../widgets/labs/lab_widgets.dart';

/// Opens one lab activity straight away on the device the student is using — no device choice:
///   Android → native 3D lab inside the app · Windows → ECH Labs window · Web → in the page.
/// When the lab closes the student is taken back to where they came from, with their score.
/// VR viewer / headset modes are available inside the lab (☰ menu) and from the Labs page.
class LabPlayerScreen extends ConsumerStatefulWidget {
  final String scenarioId;
  final String? lessonId;
  /// Optional: 'cardboard' to open straight in phone-VR mode (deep links); default is the screen.
  final String? mode;
  const LabPlayerScreen({super.key, required this.scenarioId, this.lessonId, this.mode});

  @override
  ConsumerState<LabPlayerScreen> createState() => _LabPlayerScreenState();
}

class _LabPlayerScreenState extends ConsumerState<LabPlayerScreen> {
  LabSessionTicket? _ticket;
  late final LabViewMode _mode = widget.mode == 'cardboard' ? LabViewMode.cardboard : LabViewMode.screen;
  String? _error;
  bool _embedded = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final lang = Localizations.localeOf(context).languageCode == 'rw' ? 'rw' : 'en';
      final t = _ticket ?? await ref.read(labServiceProvider).startSession(scenarioId: widget.scenarioId, lessonId: widget.lessonId, lang: lang);
      _ticket = t;
      if (!mounted) return;

      // Android: native 3D lab built into the app.
      if (await LabLauncher.nativeAvailable()) {
        final result = await LabLauncher.launchNative(t, _mode);
        _finish(result);
        return;
      }

      switch (LabLauncher.kind) {
        case LabLaunchKind.windowsApp:
          await LabLauncher.launchWindows(t, _mode);
          _finish(null, message: 'Your lab opened in its own window. Results are saved automatically.');
          return;
        case LabLaunchKind.embeddedWeb:
        case LabLaunchKind.inApp:
          if (t.webUrl == null) throw StateError('The 3D lab is not available on this device yet. Please try again later.');
          if (LabLauncher.kind == LabLaunchKind.inApp) {
            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
          }
          if (mounted) setState(() => _embedded = true);
          return;
        case LabLaunchKind.browser:
          if (t.webUrl == null) throw StateError('The 3D lab is not available on this device yet. Please try again later.');
          final ok = await LabLauncher.openInBrowser(t, _mode);
          if (!ok) throw StateError('Could not open the lab.');
          _finish(null, message: 'Your lab opened in the browser. Results are saved automatically.');
          return;
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Bad state: ', ''));
    }
  }

  /// Back to where the student came from, with a short result message.
  void _finish(Map<String, dynamic>? result, {String? message}) {
    if (!mounted || _leaving) return;
    _leaving = true;
    ref.invalidate(labSummaryProvider);
    ref.invalidate(labScenariosProvider);
    final messenger = ScaffoldMessenger.of(context);
    _restoreSystemUi();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/labs');
    }
    final score = result?['score'];
    final passed = result?['passed'] == true;
    final text = score != null
        ? (passed ? 'Well done — you passed with $score%! 🎉' : 'Activity finished — score $score%. Try again to improve it.')
        : message ?? 'Your progress is saved — continue any time.';
    messenger.showSnackBar(SnackBar(content: Text(text), backgroundColor: passed ? const Color(0xFF047857) : null));
  }

  void _onLabMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'completed':
        _lastResult = m;
        ref.invalidate(labSummaryProvider);
      case 'exit':
        _finish(_lastResult);
    }
  }

  Map<String, dynamic>? _lastResult;

  void _restoreSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    if (_embedded) _restoreSystemUi();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the lab?'),
        content: const Text('Your progress is saved — you can continue this experiment later.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Leave')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_embedded && _ticket != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async { if (!didPop && await _confirmLeave()) _finish(_lastResult); },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0F14),
          body: Stack(children: [
            Positioned.fill(
              child: kIsWeb
                  ? LabFrame(url: LabLauncher.webUrlFor(_ticket!, _mode), onMessage: _onLabMessage)
                  : LabWebView(url: LabLauncher.webUrlFor(_ticket!, _mode), onMessage: _onLabMessage),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: SafeArea(child: IconButton.filledTonal(onPressed: () async { if (await _confirmLeave()) _finish(_lastResult); }, icon: const Icon(Icons.close_rounded), tooltip: 'Leave lab')),
            ),
          ]),
        ),
      );
    }
    return _Opening(
      lab: ref.watch(labScenarioProvider(widget.scenarioId)).valueOrNull,
      error: _error,
      onRetry: _start,
      onBack: () => context.canPop() ? context.pop() : context.go('/labs'),
    );
  }
}

/// Short branded screen while the lab starts (or a friendly error with Retry).
class _Opening extends StatelessWidget {
  final LabScenario? lab;
  final String? error;
  final VoidCallback onRetry, onBack;
  const _Opening({required this.lab, required this.error, required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = LabSubjectStyle.of(lab?.subject ?? '');
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [s.gradient.last, const Color(0xFF0B0F14)])),
        child: SafeArea(
          child: Stack(children: [
            Positioned(left: 8, top: 4, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), tooltip: 'Back')),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                    child: Icon(s.icon, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text(lab?.title ?? 'Virtual Lab', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  if (error == null) ...[
                    const SizedBox(width: 220, child: LinearProgressIndicator(minHeight: 5, color: Color(0xFF10B981), backgroundColor: Colors.white12)),
                    const SizedBox(height: 12),
                    const Text('Opening your lab…', style: TextStyle(color: Colors.white70)),
                  ] else ...[
                    Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFCA5A5))),
                    const SizedBox(height: 16),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      OutlinedButton(onPressed: onBack, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)), child: const Text('Back')),
                      const SizedBox(width: 12),
                      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
