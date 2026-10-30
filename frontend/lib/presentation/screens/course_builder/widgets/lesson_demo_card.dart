import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:excellencecoachinghub/models/lesson_demo.dart';
import 'package:excellencecoachinghub/presentation/widgets/demo/guided_demo.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'build_options_panel.dart' show builderGreen;

/// Teacher card for a draft lesson's real experiment demonstration: search
/// YouTube, choose a video, place each lesson step in it ("Set to now" while
/// watching, or type the time), edit explanations, preview as a student.
class LessonDemoCard extends StatefulWidget {
  final String itemId;
  final CourseBuilderService service;
  final void Function(String message, {bool error}) onSnack;

  const LessonDemoCard({super.key, required this.itemId, required this.service, required this.onSnack});

  @override
  State<LessonDemoCard> createState() => _LessonDemoCardState();
}

class _StepFields {
  final TextEditingController text;
  final TextEditingController time;
  final TextEditingController explain;
  final DemoStep original;

  _StepFields(DemoStep s)
      : original = s,
        text = TextEditingController(text: s.text),
        time = TextEditingController(text: s.at == null ? '' : formatDemoTime(s.at!)),
        explain = TextEditingController(text: s.explain);

  void dispose() {
    text.dispose();
    time.dispose();
    explain.dispose();
  }
}

class _LessonDemoCardState extends State<LessonDemoCard> {
  DemoDraft? _draft;
  String? _error;
  String? _busy;
  bool _choosing = false;
  bool _dirty = false;
  final _query = TextEditingController();
  List<_StepFields> _fields = [];
  YoutubePlayerController? _player;
  String? _playerVideoId;

  @override
  void initState() {
    super.initState();
    _run(null, () => widget.service.itemDemo(widget.itemId));
  }

  @override
  void dispose() {
    _query.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    _player?.close();
    super.dispose();
  }

  /// Runs a request; [label] is shown while it works (null = initial load).
  Future<void> _run(String? label, Future<DemoDraft> Function() fn, {String? done}) async {
    setState(() => _busy = label ?? 'Loading…');
    try {
      final d = await fn();
      if (!mounted) return;
      _apply(d);
      if (done != null) widget.onSnack(done);
    } catch (e) {
      if (!mounted) return;
      if (_draft == null) _error = '$e';
      widget.onSnack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _apply(DemoDraft d) {
    for (final f in _fields) {
      f.dispose();
    }
    _fields = d.steps.map(_StepFields.new).toList();
    if (_query.text.isEmpty) _query.text = d.query ?? d.defaultQuery;
    final id = d.selected?.videoId;
    if (id != _playerVideoId) {
      _player?.close();
      _player = id != null && youtubeEmbedSupported
          ? YoutubePlayerController.fromVideoId(videoId: id, params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true))
          : null;
      _playerVideoId = id;
    }
    setState(() {
      _draft = d;
      _error = null;
      _dirty = false;
      _choosing = d.selected == null;
    });
  }

  List<DemoStep> _currentSteps() => [
        for (final f in _fields)
          () {
            final at = parseDemoTime(f.time.text);
            final timeChanged = at != f.original.at;
            return DemoStep(
              text: f.text.text.trim(),
              at: f.time.text.trim().isEmpty ? null : at,
              source: timeChanged ? 'teacher' : f.original.source,
              explain: f.explain.text.trim(),
              check: f.original.check,
            );
          }(),
      ];

  Future<void> _setNow(_StepFields f) async {
    final t = await _player?.currentTime;
    if (t == null) return;
    setState(() {
      f.time.text = formatDemoTime(t.floor());
      _dirty = true;
    });
  }

  Future<void> _playFrom(_StepFields f) async {
    final at = parseDemoTime(f.time.text);
    if (at == null || _player == null) return;
    await _player!.seekTo(seconds: at.toDouble(), allowSeekAhead: true);
    await _player!.playVideo();
  }

  void _save() {
    final steps = _currentSteps();
    final placed = steps.where((s) => s.at != null).map((s) => s.at!).toList();
    for (var i = 1; i < placed.length; i++) {
      if (placed[i] <= placed[i - 1]) {
        widget.onSnack('Steps must be in order: each step has to start later in the video than the one before.', error: true);
        return;
      }
    }
    _run('Saving…', () => widget.service.saveDemoSteps(widget.itemId, steps), done: 'Demonstration saved');
  }

  void _preview() {
    final d = _draft;
    if (d?.selected == null) return;
    final steps = _currentSteps();
    if (steps.any((s) => s.at == null)) {
      widget.onSnack('Place every step in the video first.', error: true);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuidedDemoScreen(demo: LessonDemo(video: d!.selected!, steps: steps), lessonTitle: 'Student preview'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.smart_display_outlined, color: builderGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Real experiment (YouTube)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('A real demonstration students watch step by step, with pauses to explain each step',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
            ),
            if (d?.selected != null)
              Chip(
                label: Text(d!.live ? 'Visible to students' : 'Not visible yet', style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: d.live ? builderGreen : Colors.orange.shade800,
                visualDensity: VisualDensity.compact,
              ),
          ]),
          const SizedBox(height: 12),
          if (_busy != null) ...[
            LinearProgressIndicator(color: builderGreen, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 6),
            Text(_busy!, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
          ],
          if (d == null)
            Text(_error ?? '', style: TextStyle(color: Colors.red.shade700))
          else if (!d.configured)
            Text('YouTube is not set up on the server. Add YOUTUBE_DATA_API_V3_KEY to the API service\'s environment.',
                style: TextStyle(color: Colors.grey.shade700))
          else ...[
            if (d.selected != null && !_choosing) _selected(d) else _search(d),
          ],
        ]),
      ),
    );
  }

  Widget _search(DemoDraft d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _query,
            decoration: const InputDecoration(labelText: 'Search YouTube for', isDense: true, border: OutlineInputBorder()),
            onSubmitted: (_) => _run('Searching YouTube…', () => widget.service.searchDemos(widget.itemId, query: _query.text)),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: builderGreen),
          onPressed: _busy != null ? null : () => _run('Searching YouTube…', () => widget.service.searchDemos(widget.itemId, query: _query.text)),
          icon: const Icon(Icons.search),
          label: const Text('Search'),
        ),
      ]),
      if (d.selected != null)
        TextButton(onPressed: () => setState(() => _choosing = false), child: const Text('Keep the current video')),
      const SizedBox(height: 10),
      if (d.suggestions.isEmpty)
        Text('Search to see real demonstrations of this practical.', style: TextStyle(color: Colors.grey.shade700))
      else
        for (final v in d.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: v.thumbnail == null
                    ? Container(width: 128, height: 72, color: Colors.grey.shade300, child: const Icon(Icons.smart_display))
                    : Image.network(v.thumbnail!, width: 128, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 128, height: 72, color: Colors.grey.shade300)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    [v.channel, if (v.durationSec != null) formatDemoTime(v.durationSec!), if (v.chapters.isNotEmpty) '${v.chapters.length} chapters (steps placed automatically)'].join(' · '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Wrap(spacing: 6, children: [
                    TextButton.icon(onPressed: () => openDemoOnYouTube(v), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Watch')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: builderGreen),
                      onPressed: _busy != null
                          ? null
                          : () => _run('Planning the steps from your lesson…', () => widget.service.selectDemo(widget.itemId, v.videoId),
                              done: 'Video chosen — now place each step in the video'),
                      child: const Text('Use this video'),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
    ]);
  }

  Widget _selected(DemoDraft d) {
    final v = d.selected!;
    final unplaced = _fields.where((f) => f.time.text.trim().isEmpty).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('“${v.title}” · ${v.channel}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (_player != null)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: YoutubePlayer(controller: _player!, aspectRatio: 16 / 9)),
        )
      else
        OutlinedButton.icon(onPressed: () => openDemoOnYouTube(v), icon: const Icon(Icons.open_in_new), label: const Text('Watch on YouTube to find the times')),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: unplaced > 0 ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(
          unplaced > 0
              ? 'Place each step: play the video and press “Set to now” when the step begins${_player == null ? ' (or type the time, e.g. 1:15)' : ''}. Students see the demonstration once all $unplaced remaining step(s) are placed and saved.'
              : 'Every step is placed. The video pauses at the start of the next step to explain the one just watched.',
          style: const TextStyle(fontSize: 13),
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < _fields.length; i++) _stepEditor(i, _fields[i]),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: builderGreen),
          onPressed: _busy != null || !_dirty ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save steps'),
        ),
        OutlinedButton.icon(onPressed: _preview, icon: const Icon(Icons.visibility_outlined), label: const Text('Preview as student')),
        OutlinedButton.icon(onPressed: () => setState(() => _choosing = true), icon: const Icon(Icons.swap_horiz), label: const Text('Choose another video')),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          onPressed: _busy != null ? null : () => _run('Removing…', () => widget.service.removeDemo(widget.itemId), done: 'Demonstration removed'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove'),
        ),
      ]),
    ]);
  }

  Widget _stepEditor(int i, _StepFields f) {
    void changed(_) => setState(() => _dirty = true);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 13, backgroundColor: builderGreen, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: f.text, onChanged: changed, decoration: const InputDecoration(isDense: true, labelText: 'Step'))),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: TextField(controller: f.time, onChanged: changed, decoration: const InputDecoration(isDense: true, labelText: 'Starts at', hintText: '0:00')),
          ),
          if (_player != null) ...[
            IconButton(tooltip: 'Set to the video\'s current time', icon: const Icon(Icons.my_location, color: builderGreen), onPressed: () => _setNow(f)),
            IconButton(tooltip: 'Play from here', icon: const Icon(Icons.play_arrow), onPressed: () => _playFrom(f)),
          ],
        ]),
        if (f.original.source == 'chapter' && f.time.text.isNotEmpty)
          Padding(padding: const EdgeInsets.only(left: 34, top: 2), child: Text('Placed from the video\'s chapters — check it', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
        Padding(
          padding: const EdgeInsets.only(left: 34, top: 6),
          child: TextField(
            controller: f.explain,
            onChanged: changed,
            maxLines: null,
            decoration: const InputDecoration(isDense: true, labelText: 'Explanation read aloud after this step'),
          ),
        ),
        if (f.original.check != null)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 6),
            child: Text('❓ ${f.original.check!.question}  ✔ ${f.original.check!.choices[f.original.check!.answerIndex]}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
      ]),
    );
  }
}
