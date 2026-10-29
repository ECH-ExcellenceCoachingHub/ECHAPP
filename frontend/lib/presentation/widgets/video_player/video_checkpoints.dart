import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';

/// Decides when a "pause and think" question should interrupt playback.
///
/// A question fires when normal playback crosses its time (the previous
/// position was just before it). Jumping over it with a seek does not fire,
/// and each question is asked at most once per player session.
class CheckpointTracker {
  final List<VideoInteraction> items;
  final Set<String> _asked = {};
  Duration? _last;

  /// Largest gap between two position updates still treated as playback.
  static const maxStep = Duration(milliseconds: 1500);

  CheckpointTracker(List<VideoInteraction> items) : items = [...items]..sort((a, b) => a.at.compareTo(b.at));

  bool get isEmpty => items.isEmpty;

  /// Feed every position update; returns the question to ask now, if any.
  VideoInteraction? onPosition(Duration position) {
    final last = _last;
    _last = position;
    if (last == null || items.isEmpty) return null;
    final step = position - last;
    if (step <= Duration.zero || step > maxStep) return null; // paused, rewound or seeked
    for (final it in items) {
      if (_asked.contains(it.id)) continue;
      if (last < it.at && position >= it.at) {
        _asked.add(it.id);
        return it;
      }
    }
    return null;
  }
}

/// Overlay shown on top of the paused video: the question, its choices,
/// feedback with the explanation, then "Continue".
class VideoCheckOverlay extends StatefulWidget {
  final VideoInteraction interaction;
  final VoidCallback onContinue;

  const VideoCheckOverlay({super.key, required this.interaction, required this.onContinue});

  @override
  State<VideoCheckOverlay> createState() => _VideoCheckOverlayState();
}

class _VideoCheckOverlayState extends State<VideoCheckOverlay> {
  int? _picked;

  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);
  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final it = widget.interaction;
    final answered = _picked != null;
    final correct = _picked == it.answerIndex;
    return Material(
      key: const ValueKey('video-check-overlay'),
      color: Colors.black.withValues(alpha: 0.72),
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 300 || c.maxWidth < 420;
        final twoColumns = !compact && c.maxWidth >= 640;
        final choiceWidth = twoColumns ? (c.maxWidth.clamp(0, 860) - 72) / 2 : double.infinity;
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 10 : 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(999)),
                    child: Text('Quick check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: compact ? 11 : 13)),
                  ),
                  const Spacer(),
                  if (!answered)
                    TextButton(
                      onPressed: widget.onContinue,
                      style: TextButton.styleFrom(foregroundColor: Colors.white70, visualDensity: VisualDensity.compact),
                      child: const Text('Skip'),
                    ),
                ]),
                SizedBox(height: compact ? 6 : 12),
                Text(it.question,
                    style: TextStyle(color: Colors.white, fontSize: compact ? 15 : 20, fontWeight: FontWeight.w700, height: 1.25)),
                SizedBox(height: compact ? 8 : 14),
                Wrap(spacing: 10, runSpacing: compact ? 6 : 10, children: [
                  for (var i = 0; i < it.choices.length; i++)
                    SizedBox(width: choiceWidth, child: _choice(i, compact)),
                ]),
                if (answered) ...[
                  SizedBox(height: compact ? 8 : 14),
                  Container(
                    key: const ValueKey('video-check-feedback'),
                    padding: EdgeInsets.all(compact ? 8 : 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(correct ? Icons.check_circle : Icons.info, color: correct ? _green : _red, size: compact ? 18 : 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${correct ? 'Correct!' : 'Not quite — the answer is ${_letters[it.answerIndex]}.'}${it.explanation.isNotEmpty ? ' ${it.explanation}' : ''}',
                          style: TextStyle(color: const Color(0xFF111827), fontSize: compact ? 12.5 : 15, height: 1.35),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _green, visualDensity: compact ? VisualDensity.compact : null),
                      onPressed: widget.onContinue,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue'),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _choice(int i, bool compact) {
    final it = widget.interaction;
    final answered = _picked != null;
    final isAnswer = i == it.answerIndex;
    final isPicked = i == _picked;
    Color bg = Colors.white;
    Color border = Colors.white;
    if (answered && isAnswer) {
      bg = const Color(0xFFDCFCE7);
      border = _green;
    } else if (answered && isPicked) {
      bg = const Color(0xFFFEE2E2);
      border = _red;
    } else if (answered) {
      bg = Colors.white.withValues(alpha: 0.6);
    }
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border, width: 2)),
      child: InkWell(
        key: ValueKey('video-check-choice-$i'),
        borderRadius: BorderRadius.circular(12),
        onTap: answered ? null : () => setState(() => _picked = i),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 12),
          child: Row(children: [
            CircleAvatar(
              radius: compact ? 12 : 15,
              backgroundColor: answered && isAnswer ? _green : const Color(0xFFEFF6FF),
              child: answered && isAnswer
                  ? Icon(Icons.check, size: compact ? 14 : 18, color: Colors.white)
                  : Text(_letters[i], style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 11 : 13, color: const Color(0xFF2563EB))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(it.choices[i], style: TextStyle(fontSize: compact ? 13 : 16, color: const Color(0xFF111827)))),
          ]),
        ),
      ),
    );
  }
}
