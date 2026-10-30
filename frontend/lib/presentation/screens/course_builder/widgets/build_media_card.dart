import 'dart:async';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import '../video_jobs_screen.dart';
import 'build_options_panel.dart' show builderGreen;

/// Build overview of textbook figures and generated lesson videos.
class BuildMediaCard extends StatefulWidget {
  final String jobId;
  /// The build's course (for pausing its videos).
  final String? courseId;
  final CourseBuilderService service;
  final void Function(String message, {bool error})? onSnack;

  const BuildMediaCard({super.key, required this.jobId, this.courseId, required this.service, this.onSnack});

  @override
  State<BuildMediaCard> createState() => _BuildMediaCardState();
}

class _BuildMediaCardState extends State<BuildMediaCard> {
  Map<String, dynamic>? _data;
  Timer? _poll;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await widget.service.buildMedia(widget.jobId);
      if (!mounted) return;
      setState(() => _data = d);
      final fx = (d['figureExtraction'] as Map?)?['status'];
      final byStatus = Map<String, dynamic>.from((d['videos'] as Map?)?['byStatus'] ?? {});
      final videosRunning = byStatus.keys.any((k) => LessonVideo.processingStatuses.contains(k));
      _poll?.cancel();
      if (fx == 'queued' || fx == 'running' || videosRunning) _poll = Timer(const Duration(seconds: 10), _load);
    } catch (_) {
      // Media status is optional — the build screen works without it.
    }
  }

  Future<void> _extract() async {
    setState(() => _busy = true);
    try {
      final msg = await widget.service.extractFigures(widget.jobId);
      widget.onSnack?.call(msg.isEmpty ? 'Figure extraction requested' : msg);
      await _load();
    } catch (e) {
      widget.onSnack?.call(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPaused(String courseId, bool paused) async {
    setState(() => _busy = true);
    try {
      widget.onSnack?.call(await widget.service.setCourseVideosPaused(courseId, paused));
      await _load();
    } catch (e) {
      widget.onSnack?.call(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _manageVideos() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => VideoJobsScreen(jobId: widget.jobId, service: widget.service)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final fx = Map<String, dynamic>.from(d['figureExtraction'] ?? {});
    final videos = Map<String, dynamic>.from(d['videos'] ?? {});
    final byStatus = Map<String, dynamic>.from(videos['byStatus'] ?? {});
    final budget = Map<String, dynamic>.from(d['budget'] ?? {});
    final summary = fx['summary'] is Map ? Map<String, dynamic>.from(fx['summary']) : const <String, dynamic>{};
    final fxStatus = (fx['status'] ?? 'not_applicable').toString();
    final processing = byStatus.entries.where((e) => LessonVideo.processingStatuses.contains(e.key)).fold<int>(0, (a, e) => a + ((e.value as num?)?.toInt() ?? 0));
    final spent = (budget['courseSpentUsd'] as num?)?.toDouble() ?? 0;
    final limit = (budget['perCourse'] as num?)?.toDouble() ?? 0;
    final stuck = (videos['stuck'] as num?)?.toInt() ?? 0;
    final failed = (byStatus['failed'] as num?)?.toInt() ?? 0;
    final paused = (d['pause'] as Map?)?['paused'] == true;
    final courseId = (d['courseId'] as String?) ?? (widget.courseId?.isNotEmpty == true ? widget.courseId : null);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 700;
          final figures = _section(
            icon: Icons.image_search_outlined,
            title: 'Textbook figures',
            lines: [
              _fxLabel(fxStatus),
              if (fxStatus == 'completed') '${fx['figures'] ?? 0} figures · ${summary['ok'] ?? 0} OK · ${summary['needsReview'] ?? 0} to check · ${summary['incomplete'] ?? 0} incomplete',
              if (fx['error'] != null) fx['error'].toString(),
            ],
            action: ['failed', 'skipped'].contains(fxStatus)
                ? TextButton.icon(onPressed: _busy ? null : _extract, icon: const Icon(Icons.refresh, size: 18), label: const Text('Extract again'))
                : null,
            busy: fxStatus == 'queued' || fxStatus == 'running',
          );
          final vids = _section(
            icon: Icons.movie_creation_outlined,
            title: 'Lesson videos',
            lines: [
              if (d['generateVideos'] == false) 'Turned off for this build'
              else if ((videos['total'] ?? 0) == 0) 'Videos are queued automatically as lessons are generated'
              else '${byStatus['completed'] ?? 0} ready · $processing in progress · ${byStatus['failed'] ?? 0} failed',
              if ((videos['pendingReview'] ?? 0) > 0) '${videos['pendingReview']} waiting for your review',
              'Spent \$${spent.toStringAsFixed(2)} of \$${limit.toStringAsFixed(2)} course budget',
              if (paused) '⏸ Paused — this course\'s videos wait while other courses\' videos are made',
            ],
            warning: stuck > 0 ? '$stuck video${stuck == 1 ? ' looks' : 's look'} stuck and may be blocking the others' : null,
            action: Wrap(spacing: 4, children: [
              if ((videos['total'] ?? 0) > 0)
                TextButton.icon(
                  style: stuck > 0 ? TextButton.styleFrom(foregroundColor: Colors.red.shade700) : null,
                  onPressed: _manageVideos,
                  icon: Icon(stuck > 0 ? Icons.warning_amber_rounded : Icons.tune, size: 18),
                  label: Text(stuck > 0 ? 'Find and stop stuck videos' : processing + failed > 0 ? 'Manage videos' : 'View videos'),
                ),
              if (courseId != null && (paused || (videos['total'] ?? 0) > 0))
                TextButton.icon(
                  onPressed: _busy ? null : () => _setPaused(courseId, !paused),
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
                  label: Text(paused ? 'Resume videos' : 'Pause videos'),
                ),
            ]),
            busy: processing > 0 && !paused,
          );
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: figures), const SizedBox(width: 24), Expanded(child: vids)])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [figures, const Divider(height: 24), vids]);
        }),
      ),
    );
  }

  String _fxLabel(String s) {
    switch (s) {
      case 'queued':
        return 'Waiting for the media worker…';
      case 'running':
        return 'Extracting diagrams, graphs and captions…';
      case 'completed':
        return 'Extracted and ready for lessons and videos';
      case 'failed':
        return 'Extraction failed';
      case 'skipped':
        return 'Not extracted';
      default:
        return 'Only available for PDF books';
    }
  }

  Widget _section({required IconData icon, required String title, required List<String> lines, Widget? action, String? warning, bool busy = false}) {
    // Readable on both light and dark card backgrounds.
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: builderGreen),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (busy) ...[const SizedBox(width: 8), const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: builderGreen))],
        ]),
        const SizedBox(height: 4),
        ...lines.map((l) => Padding(padding: const EdgeInsets.only(top: 2), child: Text(l, style: TextStyle(color: muted, fontSize: 13)))),
        if (warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('⚠ $warning', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        if (action != null) action,
      ])),
    ]);
  }
}
