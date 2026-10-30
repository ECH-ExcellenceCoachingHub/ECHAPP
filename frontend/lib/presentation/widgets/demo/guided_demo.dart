import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:excellencecoachinghub/models/lesson_demo.dart';

const _green = Color(0xFF16A34A);

/// YouTube's embedded player runs in a web view: web, Android, iOS and macOS.
/// Other desktops get the steps with "watch on YouTube" links instead.
bool get youtubeEmbedSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

Future<void> openDemoOnYouTube(DemoVideo video, {int? at}) =>
    launchUrl(Uri.parse('${video.youtubeUrl}${at != null && at > 0 ? '&t=${at}s' : ''}'), mode: LaunchMode.externalApplication);

/// Entry point shown in a lesson: opens the guided demonstration.
class DemoOpenCard extends StatelessWidget {
  final LessonDemo demo;
  final String lessonTitle;
  final bool isDark;

  const DemoOpenCard({super.key, required this.demo, required this.lessonTitle, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _green.withValues(alpha: 0.4))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuidedDemoScreen(demo: demo, lessonTitle: lessonTitle))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const CircleAvatar(backgroundColor: _green, child: Icon(Icons.science, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Watch the real experiment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${demo.steps.length} guided steps · the video pauses so your teacher can explain each one',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              ]),
            ),
            const Icon(Icons.play_circle_fill, color: _green, size: 34),
          ]),
        ),
      ),
    );
  }
}

/// A real experiment video with the lesson's steps beside it. At the end of
/// each step the video pauses, the explanation is read aloud, and an optional
/// check question is asked before the video carries on.
class GuidedDemoScreen extends StatefulWidget {
  final LessonDemo demo;
  final String lessonTitle;

  const GuidedDemoScreen({super.key, required this.demo, required this.lessonTitle});

  @override
  State<GuidedDemoScreen> createState() => _GuidedDemoScreenState();
}

class _GuidedDemoScreenState extends State<GuidedDemoScreen> {
  YoutubePlayerController? _player;
  final FlutterTts _tts = FlutterTts();
  final List<StreamSubscription> _subs = [];
  final Set<int> _explained = {};
  int _current = -1;
  int _lastIdx = -1;
  int? _pausedFor;
  int? _answer;
  bool _speaking = false;

  List<DemoStep> get _steps => widget.demo.steps;

  @override
  void initState() {
    super.initState();
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    if (youtubeEmbedSupported) {
      final p = YoutubePlayerController.fromVideoId(
        videoId: widget.demo.video.videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true, enableCaption: true),
      );
      _subs.add(p.videoStateStream.listen((s) => _onTime(s.position.inMilliseconds / 1000)));
      _subs.add(p.listen((v) { if (v.playerState == PlayerState.ended) _onEnded(); }));
      _player = p;
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _tts.stop();
    _player?.close();
    super.dispose();
  }

  int _indexAt(double t) {
    var idx = -1;
    for (var i = 0; i < _steps.length; i++) {
      if ((_steps[i].at ?? 1 << 30) <= t) idx = i;
    }
    return idx;
  }

  void _onTime(double t) {
    if (_pausedFor != null) return;
    final idx = _indexAt(t);
    // Playing on into the next step ends the previous one: pause and explain it.
    final finished = idx == _lastIdx + 1 && _lastIdx >= 0 && !_explained.contains(_lastIdx) ? _lastIdx : null;
    _lastIdx = idx;
    if (idx != _current) setState(() => _current = idx);
    if (finished != null) _explain(finished);
  }

  void _onEnded() {
    final last = _steps.length - 1;
    if (_pausedFor == null && !_explained.contains(last)) _explain(last);
  }

  Future<void> _explain(int i) async {
    await _player?.pauseVideo();
    if (!mounted) return;
    setState(() {
      _pausedFor = i;
      _answer = null;
    });
    _speak(_steps[i].explain);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    setState(() => _speaking = true);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _continue() async {
    final i = _pausedFor;
    if (i == null) return;
    await _tts.stop();
    setState(() {
      _explained.add(i);
      _pausedFor = null;
      _speaking = false;
    });
    if (i < _steps.length - 1) await _player?.playVideo();
  }

  Future<void> _jumpTo(int i) async {
    final at = _steps[i].at;
    if (at == null) return;
    await _tts.stop();
    setState(() {
      _pausedFor = null;
      _current = i;
      _lastIdx = i;
      // Re-watching a step explains it again at its end.
      _explained.removeWhere((e) => e >= i);
    });
    await _player?.seekTo(seconds: at.toDouble(), allowSeekAhead: true);
    await _player?.playVideo();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final video = widget.demo.video;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'Open on YouTube', icon: const Icon(Icons.open_in_new), onPressed: () => openDemoOnYouTube(video)),
        ],
      ),
      body: _player == null
          ? _StepsOnly(demo: widget.demo)
          : wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: ListView(padding: const EdgeInsets.all(16), children: [_playerBox(), const SizedBox(height: 12), _pauseCard(), _credit()])),
                  SizedBox(width: 380, child: _stepList()),
                ])
              : ListView(padding: const EdgeInsets.all(12), children: [
                  _playerBox(),
                  const SizedBox(height: 10),
                  _pauseCard(),
                  _credit(),
                  const SizedBox(height: 8),
                  _stepList(shrink: true),
                ]),
    );
  }

  Widget _playerBox() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(controller: _player!, aspectRatio: 16 / 9),
      );

  Widget _credit() {
    final v = widget.demo.video;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text('Video: “${v.title}” by ${v.channel} on YouTube', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    );
  }

  Widget _pauseCard() {
    final i = _pausedFor;
    if (i == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Press play. The video stops after each step so your teacher can explain what happened.')),
        ]),
      );
    }
    final step = _steps[i];
    final check = step.check;
    final answered = _answer != null;
    return Card(
      elevation: 0,
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _green)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.pause_circle_filled, color: _green),
            const SizedBox(width: 8),
            Expanded(child: Text('Step ${i + 1}: ${step.text}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87))),
          ]),
          if (step.explain.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(step.explain, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
            TextButton.icon(
              onPressed: () => _speaking ? _tts.stop().then((_) => setState(() => _speaking = false)) : _speak(step.explain),
              icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(_speaking ? 'Stop' : 'Listen again'),
            ),
          ],
          if (check != null) ...[
            const Divider(),
            Text('❓ ${check.question}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            for (var c = 0; c < check.choices.length; c++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: Colors.black87,
                    backgroundColor: !answered
                        ? null
                        : c == check.answerIndex
                            ? Colors.green.shade100
                            : c == _answer
                                ? Colors.red.shade100
                                : null,
                  ),
                  onPressed: answered ? null : () => setState(() => _answer = c),
                  child: Text(check.choices[c]),
                ),
              ),
            if (answered)
              Text(
                '${_answer == check.answerIndex ? '✅ Correct!' : '❌ Not quite.'} ${check.explanation}',
                style: TextStyle(color: _answer == check.answerIndex ? Colors.green.shade800 : Colors.red.shade800),
              ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _green),
              // A check question must be answered before moving on.
              onPressed: check != null && !answered ? null : _continue,
              icon: Icon(i < _steps.length - 1 ? Icons.play_arrow : Icons.check),
              label: Text(i < _steps.length - 1 ? 'Continue the video' : 'Finish'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepList({bool shrink = false}) {
    return ListView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(12),
      itemCount: _steps.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text('🧪 Steps of the experiment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          );
        }
        final idx = i - 1;
        final s = _steps[idx];
        final done = _explained.contains(idx);
        final current = idx == (_pausedFor ?? _current);
        return Card(
          elevation: 0,
          color: current ? _green.withValues(alpha: 0.12) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: current ? _green : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            onTap: () => _jumpTo(idx),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: done || current ? _green : Colors.grey.shade400,
              child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            title: Text(s.text, style: TextStyle(fontWeight: current ? FontWeight.w700 : FontWeight.w500)),
            trailing: s.at == null ? null : Text(formatDemoTime(s.at!), style: TextStyle(color: Colors.grey.shade600)),
          ),
        );
      },
    );
  }
}

/// Platforms without an embedded YouTube player: every step with its
/// explanation and check, each with a link to that moment on YouTube.
class _StepsOnly extends StatefulWidget {
  final LessonDemo demo;
  const _StepsOnly({required this.demo});

  @override
  State<_StepsOnly> createState() => _StepsOnlyState();
}

class _StepsOnlyState extends State<_StepsOnly> {
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    final video = widget.demo.video;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        elevation: 0,
        child: ListTile(
          leading: const Icon(Icons.smart_display, color: Colors.red, size: 32),
          title: Text(video.title),
          subtitle: Text('${video.channel} · opens on YouTube'),
          trailing: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () => openDemoOnYouTube(video),
            child: const Text('Watch'),
          ),
        ),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < widget.demo.steps.length; i++) _step(i, widget.demo.steps[i]),
    ]);
  }

  Widget _step(int i, DemoStep s) {
    final check = s.check;
    final answer = _answers[i];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: _green, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13))),
            const SizedBox(width: 10),
            Expanded(child: Text(s.text, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (s.at != null)
              TextButton.icon(
                onPressed: () => openDemoOnYouTube(widget.demo.video, at: s.at),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(formatDemoTime(s.at!)),
              ),
          ]),
          if (s.explain.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.explain)),
          if (check != null) ...[
            const SizedBox(height: 8),
            Text('❓ ${check.question}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var c = 0; c < check.choices.length; c++)
                ChoiceChip(
                  label: Text(check.choices[c]),
                  selected: answer == c,
                  selectedColor: c == check.answerIndex ? Colors.green.shade200 : Colors.red.shade200,
                  onSelected: answer != null ? null : (_) => setState(() => _answers[i] = c),
                ),
            ]),
            if (answer != null) Text('${answer == check.answerIndex ? '✅ Correct!' : '❌ Not quite.'} ${check.explanation}'),
          ],
        ]),
      ),
    );
  }
}
