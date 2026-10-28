import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'build_options_panel.dart' show builderGreen;

/// Admin/teacher panel for a draft lesson's generated videos: status per
/// pipeline stage, errors, cost, quality checks, storyboard, preview, and
/// retry / partial regeneration / cancel / review actions.
class LessonVideoPanel extends StatefulWidget {
  final String itemId;
  final CourseBuilderService service;
  final void Function(String message, {bool error}) onSnack;

  const LessonVideoPanel({super.key, required this.itemId, required this.service, required this.onSnack});

  @override
  State<LessonVideoPanel> createState() => _LessonVideoPanelState();
}

class _LessonVideoPanelState extends State<LessonVideoPanel> {
  VideoJobView? _explainer;
  VideoJobView? _experiment;
  LessonVideo? _video;
  LessonVideo? _experimentVideo;
  Map<String, String?> _previewUrls = {};
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;

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
      final r = await widget.service.itemVideos(widget.itemId);
      final previews = <String, String?>{};
      for (final j in [r.explainer, r.experiment]) {
        if (j != null && j.isDone) previews[j.id] = (await widget.service.videoJob(j.id))?.previewUrl;
      }
      if (!mounted) return;
      setState(() {
        _explainer = r.explainer;
        _experiment = r.experiment;
        _video = r.video;
        _experimentVideo = r.experimentVideo;
        _previewUrls = previews;
        _loading = false;
        _error = null;
      });
      final running = [r.explainer, r.experiment].any((j) => j?.isRunning ?? false);
      _poll?.cancel();
      if (running) _poll = Timer(const Duration(seconds: 5), _load);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _act(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      widget.onSnack(msg.isEmpty ? 'Done' : msg);
      await _load();
    } catch (e) {
      widget.onSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: builderGreen));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _load, child: const Text('Try again')),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VariantCard(
            title: 'Lesson video',
            subtitle: 'Explanatory video generated automatically from this lesson',
            icon: Icons.play_circle_outline,
            job: _explainer,
            meta: _video,
            previewUrl: _explainer == null ? null : _previewUrls[_explainer!.id],
            busy: _busy,
            onRequest: (mode) => _act(() => widget.service.requestItemVideo(widget.itemId, variant: 'explainer', mode: mode)),
            onCancel: (id) => _act(() => widget.service.cancelVideoJob(id)),
            onReview: (id, s) => _act(() => widget.service.reviewVideoJob(id, s)),
          ),
          const SizedBox(height: 16),
          _VariantCard(
            title: 'Experiment demonstration',
            subtitle: 'Simulated practical for science lessons — always labelled as simulated',
            icon: Icons.science_outlined,
            job: _experiment,
            meta: _experimentVideo,
            previewUrl: _experiment == null ? null : _previewUrls[_experiment!.id],
            busy: _busy,
            emptyText: 'No experiment video — this lesson was not detected as a practical. You can still create one.',
            onRequest: (mode) => _act(() => widget.service.requestItemVideo(widget.itemId, variant: 'experiment', mode: mode)),
            onCancel: (id) => _act(() => widget.service.cancelVideoJob(id)),
            onReview: (id, s) => _act(() => widget.service.reviewVideoJob(id, s)),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VideoJobView? job;
  final LessonVideo? meta;
  final String? previewUrl;
  final bool busy;
  final String emptyText;
  final void Function(String mode) onRequest;
  final void Function(String jobId) onCancel;
  final void Function(String jobId, String status) onReview;

  const _VariantCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.job,
    required this.meta,
    required this.previewUrl,
    required this.busy,
    required this.onRequest,
    required this.onCancel,
    required this.onReview,
    this.emptyText = 'No video yet.',
  });

  Color _statusColor(String status) {
    if (status == 'completed') return builderGreen;
    if (status == 'failed' || status == 'cancelled') return Colors.red.shade700;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final j = job;
    final status = meta?.status ?? j?.status;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: builderGreen),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ])),
            if (status != null)
              Chip(
                label: Text(LessonVideo.labelFor(status), style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: _statusColor(status),
                visualDensity: VisualDensity.compact,
              ),
          ]),
          const SizedBox(height: 10),
          if (j == null) ...[
            Text(emptyText, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: builderGreen),
              onPressed: busy ? null : () => onRequest('full'),
              icon: const Icon(Icons.movie_creation_outlined),
              label: const Text('Generate video'),
            ),
          ] else ...[
            if (j.isRunning) ...[
              LinearProgressIndicator(value: LessonVideo(status: j.status).progress, color: builderGreen, backgroundColor: Colors.grey.shade200),
              const SizedBox(height: 6),
              Text('${LessonVideo.labelFor(j.status)} · attempt ${j.attempts}/${j.maxAttempts}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
            if (meta?.stale == true)
              _note(Icons.update, Colors.blue.shade700, 'The lesson changed after this video was made (version ${meta!.contentVersion}). Regenerate to update it.'),
            if (j.errorMessage != null && !j.isDone)
              _note(Icons.error_outline, Colors.red.shade700, '${j.errorStage != null ? '[${LessonVideo.labelFor(j.errorStage!)}] ' : ''}${j.errorMessage}'),
            if (j.reviewRequired && j.isDone)
              _note(
                j.reviewStatus == 'approved' ? Icons.verified_outlined : j.reviewStatus == 'rejected' ? Icons.block : Icons.fact_check_outlined,
                j.reviewStatus == 'approved' ? builderGreen : Colors.orange.shade800,
                j.reviewStatus == 'pending'
                    ? 'Needs review before students can see it. ${j.reviewReasons.join(' ')}'
                    : 'Review: ${j.reviewStatus}',
              ),
            const SizedBox(height: 6),
            Wrap(spacing: 14, runSpacing: 4, children: [
              _fact('Version', 'v${j.contentVersion}'),
              if (j.durationSeconds != null) _fact('Length', '${(j.durationSeconds! / 60).floor()}:${(j.durationSeconds! % 60).round().toString().padLeft(2, '0')}'),
              _fact('Cost', '\$${j.actualUsd.toStringAsFixed(3)}${j.estimatedUsd > 0 ? ' (est. \$${j.estimatedUsd.toStringAsFixed(3)})' : ''}'),
              if (j.scenes.isNotEmpty) _fact('Scenes', '${j.scenes.length}'),
            ]),
            if (j.checks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: j.checks.map((c) => Tooltip(
                message: c.detail,
                child: Chip(
                  avatar: Icon(c.passed ? Icons.check_circle : Icons.warning_amber, size: 16, color: c.passed ? builderGreen : Colors.orange.shade800),
                  label: Text(c.name.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              )).toList()),
            ],
            if (j.storyboardWarnings.isNotEmpty)
              _note(Icons.info_outline, Colors.grey.shade700, j.storyboardWarnings.take(4).join('\n')),
            if (j.scenes.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Storyboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                children: j.scenes.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(radius: 12, backgroundColor: builderGreen, child: Text('${s.n}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                  title: Text('${s.type.replaceAll('_', ' ')}${s.heading.isNotEmpty ? ' — ${s.heading}' : ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(s.narration, style: const TextStyle(fontSize: 12)),
                )).toList(),
              ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (previewUrl != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: builderGreen),
                  onPressed: () => launchUrl(Uri.parse(previewUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Preview'),
                ),
              if (j.reviewRequired && j.isDone && j.reviewStatus != 'approved')
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onReview(j.id, 'approved'),
                  icon: const Icon(Icons.check, color: builderGreen),
                  label: const Text('Approve'),
                ),
              if (j.reviewRequired && j.isDone && j.reviewStatus != 'rejected')
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onReview(j.id, 'rejected'),
                  icon: Icon(Icons.close, color: Colors.red.shade700),
                  label: const Text('Reject'),
                ),
              if (j.state == 'failed' || j.state == 'cancelled')
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: builderGreen),
                  onPressed: busy ? null : () => onRequest('retry'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              if (j.isRunning)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => onCancel(j.id),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Cancel'),
                ),
              if (!j.isRunning)
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Regenerate',
                  onSelected: onRequest,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'script', child: Text('New script & storyboard')),
                    PopupMenuItem(value: 'audio', child: Text('Re-record narration')),
                    PopupMenuItem(value: 'visuals', child: Text('Re-render visuals only')),
                    PopupMenuItem(value: 'full', child: Text('Regenerate everything')),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome, size: 18, color: builderGreen),
                      SizedBox(width: 6),
                      Text('Regenerate', style: TextStyle(color: builderGreen, fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_drop_down, color: builderGreen),
                    ]),
                  ),
                ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _note(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ]),
      );

  Widget _fact(String label, String value) => RichText(
        text: TextSpan(style: const TextStyle(fontSize: 12, color: Colors.black87), children: [
          TextSpan(text: '$label: ', style: TextStyle(color: Colors.grey.shade600)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
