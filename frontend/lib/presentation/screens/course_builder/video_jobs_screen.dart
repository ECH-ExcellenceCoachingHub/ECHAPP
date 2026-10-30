import 'dart:async';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'course_build_item_screen.dart';
import 'widgets/build_options_panel.dart' show builderGreen;

/// Every lesson video of a build that is running, waiting or failed: which
/// one is stuck and why, with Stop / Force stop / Retry. The media worker
/// makes one video at a time, so one hung video holds up all the others.
class VideoJobsScreen extends StatefulWidget {
  final String jobId;
  final CourseBuilderService service;

  const VideoJobsScreen({super.key, required this.jobId, required this.service});

  @override
  State<VideoJobsScreen> createState() => _VideoJobsScreenState();
}

class _VideoJobsScreenState extends State<VideoJobsScreen> {
  BuildVideoJobs? _jobs;
  String? _error;
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
    _poll?.cancel();
    try {
      final j = await widget.service.buildVideoJobs(widget.jobId);
      if (!mounted) return;
      setState(() {
        _jobs = j;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) _poll = Timer(const Duration(seconds: 10), _load);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : builderGreen));
  }

  Future<void> _act(Future<String> Function() fn) async {
    setState(() => _busy = true);
    try {
      final msg = await fn();
      if (msg.isNotEmpty) _snack(msg);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _forceStop(BuildVideoJob j) async {
    if (!await _confirm('Force stop "${j.title}"?',
        'The video is marked as cancelled now, and the worker drops it within a minute and moves on to the next video. You can retry it later.', 'Force stop')) {
      return;
    }
    await _act(() => widget.service.cancelVideoJob(j.id, force: true));
  }

  Future<void> _stopAllStuck(List<BuildVideoJob> stuck) async {
    if (!await _confirm('Force stop ${stuck.length} stuck video${stuck.length == 1 ? '' : 's'}?',
        'They are marked as cancelled now so the other videos can carry on. You can retry them later.', 'Force stop')) {
      return;
    }
    await _act(() => widget.service.bulkVideoJobs(widget.jobId, 'force_stop', stuckOnly: true));
  }

  Future<void> _retryAll(int n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Retry $n failed video${n == 1 ? '' : 's'}?'),
        content: const Text('They go back into the queue and are made one at a time. Paid narration counts towards the course video budget; stages that already succeeded are reused.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: builderGreen), onPressed: () => Navigator.pop(c, true), child: const Text('Retry all')),
        ],
      ),
    );
    if (ok == true) await _act(() => widget.service.bulkVideoJobs(widget.jobId, 'retry'));
  }

  void _open(BuildVideoJob j) {
    if (j.itemId == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseBuildItemScreen(itemId: j.itemId!))).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final j = _jobs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson videos in progress'),
        backgroundColor: builderGreen,
        foregroundColor: Colors.white,
        actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _busy ? null : _load)],
      ),
      body: j == null
          ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator(color: builderGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_busy) const LinearProgressIndicator(color: builderGreen),
                  _workerBanner(j),
                  if (j.stuck.isNotEmpty) _stuckBanner(j.stuck),
                  _header('Running and waiting (${j.active.length})', null),
                  if (j.active.isEmpty) _empty('Nothing is being made right now.'),
                  for (final job in j.active) _activeTile(job, j.stuckAfterMinutes),
                  const SizedBox(height: 20),
                  _header(
                    'Failed (${j.failed.length})',
                    j.failed.isEmpty
                        ? null
                        : TextButton.icon(onPressed: _busy ? null : () => _retryAll(j.failed.length), icon: const Icon(Icons.replay), label: const Text('Retry all')),
                  ),
                  if (j.failed.isEmpty) _empty('No failed videos.'),
                  ..._failedGroups(j.failed),
                ],
              ),
            ),
    );
  }

  Widget _workerBanner(BuildVideoJobs j) {
    final waiting = j.active.where((a) => !a.isRunning).length;
    if (j.workerActive || waiting == 0) return const SizedBox.shrink();
    return _banner(
      Colors.orange,
      Icons.power_off_outlined,
      'No media worker is picking up videos',
      '$waiting video${waiting == 1 ? ' is' : 's are'} waiting, but no worker has run anything in the last 10 minutes. Check that the "echapp-media-worker" service is running on Render (Logs / Restart).',
    );
  }

  Widget _stuckBanner(List<BuildVideoJob> stuck) {
    return _banner(
      Colors.red,
      Icons.warning_amber_rounded,
      '${stuck.length} video${stuck.length == 1 ? ' looks' : 's look'} stuck',
      'A stuck video blocks the ones waiting behind it. Force stop it so the queue moves on, then retry it later.',
      action: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
        onPressed: _busy ? null : () => _stopAllStuck(stuck),
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('Force stop stuck videos'),
      ),
    );
  }

  Widget _banner(MaterialColor color, IconData icon, String title, String body, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade300)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color.shade800),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color.shade900)),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: color.shade900)),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 10), child: action),
          ]),
        ),
      ]),
    );
  }

  Widget _header(String text, Widget? action) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          if (action != null) action,
        ]),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
      );

  Widget _activeTile(BuildVideoJob job, int stuckMinutes) {
    final stuck = job.stuck != null;
    final details = <String>[
      _variantLabel(job.variant),
      if (job.isRunning) 'Step: ${LessonVideo.labelFor(job.status)}${job.stageSince != null ? ' for ${_ago(job.stageSince!)}' : ''}',
      if (job.state == 'retry_wait') 'Retrying${job.nextRunAt != null ? ' ${_when(job.nextRunAt!)}' : ''} after: ${job.errorMessage ?? 'an error'}',
      if (job.state == 'queued') 'Waiting for its turn',
      if (job.attempts > 0) 'Attempt ${job.attempts} of ${job.maxAttempts}',
      if (job.isRunning && job.startedAt != null) 'Started ${_ago(job.startedAt!)} ago',
      if (job.worker != null) 'Worker: ${job.worker!.split(':').first}',
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: stuck ? Colors.red.shade300 : Colors.grey.shade300, width: stuck ? 2 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _stateIcon(job),
            const SizedBox(width: 10),
            Expanded(child: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Text(details.join(' · '), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          if (stuck)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 6),
              child: Text('⚠ ${job.stuck}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Wrap(spacing: 4, children: [
              TextButton.icon(onPressed: () => _open(job), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open lesson')),
              if (!job.cancelRequested && !stuck)
                TextButton.icon(
                  onPressed: _busy ? null : () => _act(() => widget.service.cancelVideoJob(job.id)),
                  icon: const Icon(Icons.stop_outlined, size: 16),
                  label: const Text('Stop'),
                ),
              if (job.isRunning || stuck || job.cancelRequested)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  onPressed: _busy ? null : () => _forceStop(job),
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text('Force stop'),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Failed videos grouped by error, so one cause behind many failures is obvious.
  List<Widget> _failedGroups(List<BuildVideoJob> failed) {
    final groups = <String, List<BuildVideoJob>>{};
    for (final f in failed) {
      groups.putIfAbsent(f.errorMessage ?? 'Unknown error', () => []).add(f);
    }
    final sorted = groups.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return [
      for (final g in sorted)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: ExpansionTile(
            leading: Icon(Icons.error_outline, color: Colors.red.shade700),
            title: Text(g.key, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              '${g.value.length} video${g.value.length == 1 ? '' : 's'}${g.value.first.errorStage != null ? ' · failed while ${LessonVideo.labelFor(g.value.first.errorStage!).toLowerCase()}' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: TextButton(
              onPressed: _busy ? null : () => _act(() => widget.service.bulkVideoJobs(widget.jobId, 'retry', ids: g.value.map((f) => f.id).toList())),
              child: Text(g.value.length == 1 ? 'Retry' : 'Retry these'),
            ),
            children: [
              for (final f in g.value)
                ListTile(
                  dense: true,
                  title: Text(f.title),
                  subtitle: Text('${_variantLabel(f.variant)}${f.finishedAt != null ? ' · ${_ago(f.finishedAt!)} ago' : ''}'),
                  onTap: () => _open(f),
                  trailing: IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.replay, size: 18),
                    onPressed: _busy ? null : () => _act(() => widget.service.bulkVideoJobs(widget.jobId, 'retry', ids: [f.id])),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _stateIcon(BuildVideoJob job) {
    if (job.stuck != null) return Icon(Icons.warning_amber_rounded, color: Colors.red.shade700);
    if (job.isRunning) return const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2.5, color: builderGreen)));
    if (job.state == 'retry_wait') return Icon(Icons.replay, color: Colors.orange.shade800);
    return Icon(Icons.schedule, color: Colors.grey.shade600);
  }

  String _variantLabel(String v) => v == 'experiment' ? 'Experiment video' : 'Lesson video';

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '${d.inSeconds.clamp(0, 59)} s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) return '${d.inHours} h ${d.inMinutes % 60} min';
    return '${d.inDays} d';
  }

  String _when(DateTime t) {
    final d = t.difference(DateTime.now());
    return d.isNegative ? 'now' : 'in ${d.inMinutes < 1 ? '${d.inSeconds} s' : '${d.inMinutes} min'}';
  }
}
