import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excellencecoachinghub/models/course_build.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'widgets/build_options_panel.dart';

/// One AI build: live progress, outline review, and the chapter-by-chapter
/// review table where drafts are approved and published.
class CourseBuildJobScreen extends StatefulWidget {
  final String jobId;
  final bool isTeacher;
  const CourseBuildJobScreen({super.key, required this.jobId, this.isTeacher = false});

  @override
  State<CourseBuildJobScreen> createState() => _CourseBuildJobScreenState();
}

class _CourseBuildJobScreenState extends State<CourseBuildJobScreen> {
  final _service = CourseBuilderService();
  CourseBuildJob? _job;
  List<BuildItemSummary> _items = [];
  String? _error;
  Timer? _poll;
  bool _busy = false;

  // Outline editing
  List<OutlineChapter>? _chapters;
  BuildOptions? _genOptions;
  bool _outlineDirty = false;
  bool _editingOutline = false;
  bool _showLogs = false;
  final Set<int> _expanded = {};

  String get _base => widget.isTeacher ? '/teacher' : '/admin';

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
      final r = await _service.getJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = r.job;
        _items = r.items;
        _error = null;
        if (!_outlineDirty) {
          _chapters = r.job.chapters.map((c) => OutlineChapter.fromJson(c.toJson())..isPublished = c.isPublished).toList();
          _genOptions = BuildOptions.fromJson(r.job.options.toJson());
        }
        if (_expanded.isEmpty && r.items.isNotEmpty) {
          final first = r.items.firstWhere((i) => i.chapterIndex != null, orElse: () => r.items.first).chapterIndex;
          if (first != null) _expanded.add(first);
        }
      });
      _schedulePoll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      _poll?.cancel();
      _poll = Timer(const Duration(seconds: 6), _load);
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    final active = (_job?.isBusy ?? false) || _items.any((i) => i.isWorking);
    if (active) _poll = Timer(const Duration(seconds: 2), _load);
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) _snack(success);
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : builderGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final chapters = _chapters ?? [];
    if (!chapters.any((c) => c.selected)) {
      _snack('Select at least one chapter', error: true);
      return;
    }
    await _run(() async {
      await _service.saveOutline(widget.jobId, chapters: chapters, options: _genOptions);
      _outlineDirty = false;
      _editingOutline = false;
      await _service.startGeneration(widget.jobId);
    }, success: 'Generation started — items appear here as soon as each one is ready');
  }

  Future<void> _saveOutline() => _run(() async {
        await _service.saveOutline(widget.jobId, chapters: _chapters, options: _genOptions);
        _outlineDirty = false;
      }, success: 'Outline saved');

  Future<void> _publish({int? chapterIndex}) async {
    final approved = _items.where((i) =>
        (chapterIndex == null || i.chapterIndex == chapterIndex) && (i.status == 'approved' || (i.isPublished && i.dirtyAfterPublish)));
    if (approved.isEmpty) {
      _snack('Approve items first — only reviewed items are published', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish to the course?'),
        content: Text('${approved.length} reviewed item(s) will become visible to enrolled students. '
            'Chapters become sections; lessons, quizzes and tests are added in order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: builderGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final n = await _service.publish(widget.jobId, chapterIndex: chapterIndex);
      if (mounted) _snack('$n item(s) published to the course');
    });
  }

  Future<void> _exportCsv() async {
    await _run(() async {
      final csv = await _service.exportQuestionBankCsv(widget.jobId);
      final name = 'question-bank-${(_job?.displayTitle ?? 'book').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.csv';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(Uint8List.fromList(utf8.encode(csv)), mimeType: 'text/csv', name: name)],
        fileNameOverrides: [name],
        subject: 'Question bank — ${_job?.displayTitle ?? ''}',
      ));
    });
  }

  Future<void> _deleteJob() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: const Text('All unpublished drafts of this build are deleted. Lessons already published to the course are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteJob(widget.jobId);
      if (mounted) context.pop();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _regenerate(BuildItemSummary item) async {
    final controller = TextEditingController();
    String part = 'all';
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Regenerate "${item.title}"'),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.kind == 'lesson')
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Everything')),
                    ButtonSegment(value: 'content', label: Text('Notes')),
                    ButtonSegment(value: 'questions', label: Text('Quiz')),
                  ],
                  selected: {part},
                  onSelectionChanged: (s) => setD(() => part = s.first),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What should change? (optional)',
                  hintText: 'e.g. Simpler language, more calculation questions, add a comparison table',
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: builderGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Regenerate'),
            ),
          ],
        ),
      ),
    );
    if (go == true) {
      await _run(() => _service.regenerateItem(item.id, part: part, instructions: controller.text), success: 'Regenerating…');
    }
  }

  void _openItem(BuildItemSummary item) {
    context.push('$_base/ai-build-items/${item.id}').then((_) => _load());
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: builderGreen,
        foregroundColor: Colors.white,
        title: Text(job?.displayTitle ?? 'AI build', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (job != null && _items.any((i) => i.questionCount > 0))
            IconButton(onPressed: _busy ? null : _exportCsv, tooltip: 'Export question bank (CSV)', icon: const Icon(Icons.download_outlined)),
          IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'outline') setState(() => _editingOutline = true);
              if (v == 'delete') _deleteJob();
              if (v == 'logs') setState(() => _showLogs = !_showLogs);
            },
            itemBuilder: (_) => [
              if (job != null && job.hasOutline && !job.isBusy)
                const PopupMenuItem(value: 'outline', child: ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Generate more chapters'))),
              PopupMenuItem(value: 'logs', child: ListTile(leading: const Icon(Icons.list_alt), title: Text(_showLogs ? 'Hide activity log' : 'Show activity log'))),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete draft'))),
            ],
          ),
        ],
      ),
      body: job == null
          ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(wide ? 28 : 12, 16, wide ? 28 : 12, 110),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressHeader(job: job, items: _items, onStop: () => _run(() => _service.cancel(widget.jobId), success: 'Stopping…')),
                        if (_showLogs) ...[const SizedBox(height: 12), _LogPanel(logs: job.logs)],
                        const SizedBox(height: 16),
                        ..._buildMain(job, wide),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: job != null && _items.isNotEmpty && !_editingOutline ? _buildBottomBar() : null,
    );
  }

  List<Widget> _buildMain(CourseBuildJob job, bool wide) {
    if (job.status == 'failed' && !job.hasOutline) {
      return [
        _ErrorCard(
          message: job.error ?? 'Something went wrong',
          action: 'Try again',
          onAction: () => _run(() => _service.retryAnalysis(widget.jobId), success: 'Analysis restarted'),
        ),
      ];
    }
    if (job.isAnalyzing) return [const _AnalyzingHint()];

    final showOutline = job.status == 'outline_ready' || _editingOutline || (_items.isEmpty && !job.isGenerating);
    return [
      if (job.status == 'failed' && job.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ErrorCard(
            message: job.error!,
            action: 'Resume generation',
            onAction: () => _run(() => _service.startGeneration(widget.jobId), success: 'Resumed'),
          ),
        ),
      if (showOutline) _buildOutlineEditor(job),
      if (_items.isNotEmpty) ...[
        if (showOutline) const SizedBox(height: 20),
        _buildReviewTable(job, wide),
      ],
    ];
  }

  // ─── Outline editor ────────────────────────────────────────────────────────

  Widget _buildOutlineEditor(CourseBuildJob job) {
    final chapters = _chapters ?? [];
    final selected = chapters.where((c) => c.selected).length;
    final lessons = chapters.where((c) => c.selected).fold<int>(0, (s, c) => s + c.lessons.length);

    return _Section(
      title: 'Step 1 · Check the course outline',
      subtitle: 'The AI found ${chapters.length} chapters in the book. Untick what you don\'t need, rename anything, then choose what to generate.',
      icon: Icons.account_tree_outlined,
      trailing: _outlineDirty
          ? TextButton.icon(onPressed: _busy ? null : _saveOutline, icon: const Icon(Icons.save_outlined), label: const Text('Save'))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('$selected of ${chapters.length} chapters · $lessons lessons', style: const TextStyle(fontWeight: FontWeight.w600, color: builderMuted)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                final all = chapters.every((c) => c.selected);
                for (final c in chapters) {
                  c.selected = !all;
                }
                _outlineDirty = true;
              }),
              child: Text(chapters.every((c) => c.selected) ? 'Select none' : 'Select all'),
            ),
          ]),
          const SizedBox(height: 6),
          ...chapters.map((c) => _ChapterOutlineTile(
                chapter: c,
                pageLabel: job.pageLabel,
                pageCount: job.pageCount,
                onChanged: () => setState(() => _outlineDirty = true),
              )),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Step 2 · What to generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_genOptions != null)
            BuildOptionsPanel(
              key: ValueKey('opts-${job.id}'),
              options: _genOptions!,
              onChanged: () => setState(() => _outlineDirty = true),
            ),
          const SizedBox(height: 18),
          Row(children: [
            if (_editingOutline && _items.isNotEmpty)
              TextButton(onPressed: () => setState(() => _editingOutline = false), child: const Text('Back to review')),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _busy || job.isBusy ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_items.isEmpty ? 'Generate course draft' : 'Generate missing items'),
              style: ElevatedButton.styleFrom(
                backgroundColor: builderGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Review table ──────────────────────────────────────────────────────────

  Widget _buildReviewTable(CourseBuildJob job, bool wide) {
    final byChapter = <int?, List<BuildItemSummary>>{};
    for (final i in _items) {
      byChapter.putIfAbsent(i.chapterIndex, () => []).add(i);
    }
    final chapterIndexes = byChapter.keys.whereType<int>().toList()..sort();
    final titles = {for (final c in job.chapters) c.index: c.title};

    return _Section(
      title: 'Review & publish',
      subtitle: 'Open any item to read, edit or regenerate it. Approved items are published when you press Publish.',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Expanded(flex: 6, child: _Th('Chapter')),
                Expanded(flex: 2, child: _Th('Lessons')),
                Expanded(flex: 2, child: _Th('Quiz')),
                Expanded(flex: 3, child: _Th('Status')),
                SizedBox(width: 200, child: _Th('Actions', end: true)),
              ]),
            ),
          const SizedBox(height: 8),
          for (final ci in chapterIndexes)
            _ChapterReviewCard(
              title: titles[ci] ?? 'Chapter ${ci + 1}',
              items: byChapter[ci]!,
              wide: wide,
              expanded: _expanded.contains(ci),
              busy: _busy,
              onToggle: () => setState(() => _expanded.contains(ci) ? _expanded.remove(ci) : _expanded.add(ci)),
              onApprove: () => _run(() => _service.approve(widget.jobId, chapterIndex: ci), success: 'Chapter approved'),
              onPublish: () => _publish(chapterIndex: ci),
              itemBuilder: _itemRow,
            ),
          if (byChapter[null] != null)
            _ChapterReviewCard(
              title: 'Exam preparation',
              items: byChapter[null]!,
              wide: wide,
              expanded: true,
              busy: _busy,
              onToggle: () {},
              onApprove: () => _run(() => _service.approve(widget.jobId, itemIds: byChapter[null]!.map((i) => i.id).toList()), success: 'Approved'),
              onPublish: () => _publish(),
              itemBuilder: _itemRow,
            ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildItemSummary item) {
    final kindIcon = switch (item.kind) {
      'chapter_test' => Icons.assignment_outlined,
      'revision' => Icons.psychology_outlined,
      'mock_exam' => Icons.workspace_premium_outlined,
      _ => Icons.menu_book_outlined,
    };
    final conf = item.confidence;
    final confColor = conf == null ? builderMuted : conf >= 85 ? const Color(0xFF16A34A) : conf >= 70 ? const Color(0xFFD97706) : const Color(0xFFDC2626);

    return InkWell(
      onTap: item.isWorking ? null : () => _openItem(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(kindIcon, size: 20, color: builderGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('${item.kindLabel} · ${_job!.pageLabel}s ${item.pageStart}–${item.pageEnd}', style: const TextStyle(fontSize: 11.5, color: builderMuted)),
                    if (item.questionCount > 0) _MiniStat(Icons.quiz_outlined, '${item.questionCount} Q'),
                    if (item.visualCount > 0) _MiniStat(Icons.insights_outlined, '${item.visualCount} visuals'),
                    if (conf != null)
                      Tooltip(
                        message: 'AI confidence, based on how well the content matches the book',
                        child: Text('$conf% confidence', style: TextStyle(fontSize: 11.5, color: confColor, fontWeight: FontWeight.w700)),
                      ),
                    if (item.unverifiedCount > 0)
                      Tooltip(
                        message: '${item.unverifiedCount} question(s) could not be matched to the book text',
                        child: _MiniStat(Icons.help_outline, '${item.unverifiedCount} unverified', color: const Color(0xFFD97706)),
                      ),
                    if (item.isPublished && item.dirtyAfterPublish) _MiniStat(Icons.sync, 'edited since publish', color: const Color(0xFF7C3AED)),
                  ]),
                  if (item.status == 'error' && item.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item.error!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Colors.red)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.isWorking)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            BuildStatusChip(item.status, dense: true),
            PopupMenuButton<String>(
              enabled: !item.isWorking && !_busy,
              onSelected: (v) {
                switch (v) {
                  case 'open':
                    _openItem(item);
                  case 'approve':
                    _run(() => _service.setItemStatus(item.id, 'approved'));
                  case 'reject':
                    _run(() => _service.setItemStatus(item.id, 'rejected'));
                  case 'restore':
                    _run(() => _service.setItemStatus(item.id, 'draft'));
                  case 'regen':
                    _regenerate(item);
                  case 'publish':
                    _run(() async {
                      final n = await _service.publish(widget.jobId, itemIds: [item.id]);
                      if (mounted) _snack(n > 0 ? 'Published' : 'Approve it first');
                    });
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'open', child: Text('Open & review')),
                if (item.isReviewable) const PopupMenuItem(value: 'approve', child: Text('Approve')),
                if (item.status == 'approved' || (item.isPublished && item.dirtyAfterPublish))
                  PopupMenuItem(value: 'publish', child: Text(item.isPublished ? 'Update published lesson' : 'Publish now')),
                const PopupMenuItem(value: 'regen', child: Text('Regenerate with AI')),
                if (!item.isPublished && item.status != 'rejected') const PopupMenuItem(value: 'reject', child: Text('Reject (don\'t publish)')),
                if (item.status == 'rejected' || item.status == 'approved') const PopupMenuItem(value: 'restore', child: Text('Back to draft')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final reviewable = _items.where((i) => i.isReviewable).length;
    final publishable = _items.where((i) => i.status == 'approved' || (i.isPublished && i.dirtyAfterPublish)).length;
    final published = _items.where((i) => i.isPublished).length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: builderBorder)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$published published · $publishable ready to publish · $reviewable awaiting review',
                style: const TextStyle(fontSize: 12.5, color: builderMuted),
                maxLines: 2,
              ),
            ),
            if (reviewable > 0)
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          final n = await _service.approve(widget.jobId);
                          if (mounted) _snack('$n item(s) approved');
                        }),
                icon: const Icon(Icons.done_all),
                label: const Text('Approve all'),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _busy || publishable == 0 ? null : () => _publish(),
              icon: const Icon(Icons.public),
              label: Text('Publish ($publishable)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: builderGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pieces ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, this.subtitle, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: builderBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: builderGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: const TextStyle(fontSize: 13, color: builderMuted, height: 1.4)),
                ],
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final bool end;
  const _Th(this.text, {this.end = false});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: builderMuted, letterSpacing: 0.3));
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MiniStat(this.icon, this.text, {this.color = builderMuted});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
      ]);
}

class _ProgressHeader extends StatelessWidget {
  final CourseBuildJob job;
  final List<BuildItemSummary> items;
  final VoidCallback onStop;
  const _ProgressHeader({required this.job, required this.items, required this.onStop});

  static const _stages = ['Upload', 'Read', 'Structure', 'Outline', 'Generate', 'Review', 'Publish'];

  int get _stageIndex {
    final published = items.isNotEmpty && items.every((i) => i.isPublished || i.status == 'rejected');
    return switch (job.status) {
      'uploaded' => 0,
      'extracting' => 1,
      'analyzing' => 2,
      'outline_ready' => 3,
      'generating' => 4,
      'ready' => published ? 6 : 5,
      _ => items.isEmpty ? (job.hasOutline ? 3 : 1) : 5,
    };
  }

  String _eta(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${m % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final p = job.progress;
    final busy = job.isBusy;
    final stage = _stageIndex;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: builderBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.displayTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  [
                    job.fileName,
                    if (job.pageCount > 0) '${job.pageCount} ${job.pageLabel}s',
                    if (job.subject.isNotEmpty) job.subject,
                    BuildMode.byId(job.options.mode).label,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: builderMuted),
                ),
              ]),
            ),
            if (job.ocrUsed) const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('OCR'), visualDensity: VisualDensity.compact)),
            BuildStatusChip(job.status),
          ]),
          const SizedBox(height: 18),
          // Stage stepper
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _stages.length; i++) ...[
                  _StageDot(label: _stages[i], state: i < stage ? 2 : i == stage ? (busy ? 1 : 3) : 0),
                  if (i < _stages.length - 1)
                    Container(width: 26, height: 2, color: i < stage ? builderGreen : builderBorder, margin: const EdgeInsets.only(bottom: 18)),
                ],
              ],
            ),
          ),
          if (busy || job.status == 'cancelled') ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: job.status == 'analyzing' ? null : (p.percent.clamp(0, 100)) / 100,
                minHeight: 10,
                color: builderGreen,
                backgroundColor: builderBorder,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(p.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: builderInk))),
              if (job.isGenerating && p.total > 0)
                Text('${p.done}/${p.total} · ${p.percent}%', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (job.isGenerating && p.etaSeconds != null && p.etaSeconds! > 0)
                Padding(padding: const EdgeInsets.only(left: 10), child: Text('~${_eta(p.etaSeconds!)} left', style: const TextStyle(color: builderMuted, fontSize: 12.5))),
              if (job.isGenerating)
                TextButton.icon(onPressed: onStop, icon: const Icon(Icons.stop_circle_outlined, size: 18), label: const Text('Stop')),
            ]),
            if (job.isGenerating)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Tip: you can start reviewing finished lessons now — they appear below as soon as they are ready.',
                    style: TextStyle(fontSize: 12, color: builderMuted)),
              ),
          ],
          if (items.isNotEmpty || job.statQuestions > 0) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _StatTile(Icons.menu_book_outlined, '${job.statLessons}', 'lessons'),
              _StatTile(Icons.quiz_outlined, '${job.statQuestions}', 'questions'),
              _StatTile(Icons.insights_outlined, '${job.statVisuals}', 'visuals'),
              _StatTile(Icons.verified_outlined, '${job.statQuestions - job.statUnverified}', 'source-verified'),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final String label;
  final int state; // 0 todo, 1 running, 2 done, 3 current-waiting
  const _StageDot({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state == 0 ? builderBorder : builderGreen;
    return SizedBox(
      width: 74,
      child: Column(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: state == 2 ? builderGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: state == 2
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : state == 1
                  ? const Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(strokeWidth: 2, color: builderGreen))
                  : state == 3
                      ? const Icon(Icons.circle, size: 10, color: builderGreen)
                      : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: state > 0 ? FontWeight.w700 : FontWeight.w500, color: state > 0 ? builderInk : builderMuted)),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF9), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: builderGreen),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: builderMuted, fontSize: 12.5)),
        ]),
      );
}

class _LogPanel extends StatelessWidget {
  final List<BuildLog> logs;
  const _LogPanel({required this.logs});

  @override
  Widget build(BuildContext context) {
    final recent = logs.reversed.take(60).toList();
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: recent.length,
        itemBuilder: (_, i) {
          final l = recent[i];
          final color = l.level == 'error' ? const Color(0xFFFCA5A5) : l.level == 'warn' ? const Color(0xFFFCD34D) : const Color(0xFFA7F3D0);
          final t = l.at == null ? '' : '${l.at!.hour.toString().padLeft(2, '0')}:${l.at!.minute.toString().padLeft(2, '0')}:${l.at!.second.toString().padLeft(2, '0')}  ';
          return Text('$t${l.message}', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color, height: 1.5));
        },
      ),
    );
  }
}

class _AnalyzingHint extends StatelessWidget {
  const _AnalyzingHint();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: builderBorder)),
        child: const Column(children: [
          Icon(Icons.auto_stories_outlined, size: 48, color: builderGreen),
          SizedBox(height: 12),
          Text('Reading the book and detecting its chapters…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 6),
          Text(
            'This usually takes under a minute for text PDFs and a few minutes for scanned books. '
            'You can leave this page — the build keeps running on the server.',
            textAlign: TextAlign.center,
            style: TextStyle(color: builderMuted, height: 1.5),
          ),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String action;
  final VoidCallback onAction;
  const _ErrorCard({required this.message, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFECACA))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF991B1B)))),
          TextButton(onPressed: onAction, child: Text(action)),
        ]),
      );
}

class _ChapterOutlineTile extends StatefulWidget {
  final OutlineChapter chapter;
  final String pageLabel;
  final int pageCount;
  final VoidCallback onChanged;
  const _ChapterOutlineTile({required this.chapter, required this.pageLabel, required this.pageCount, required this.onChanged});

  @override
  State<_ChapterOutlineTile> createState() => _ChapterOutlineTileState();
}

class _ChapterOutlineTileState extends State<_ChapterOutlineTile> {
  bool _open = false;
  OutlineChapter get c => widget.chapter;

  void _changed(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  Future<String?> _editText(String title, String initial) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: 460, child: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.selected ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.selected ? builderGreen.withValues(alpha: 0.4) : builderBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(value: c.selected, activeColor: builderGreen, onChanged: (v) => _changed(() => c.selected = v ?? false)),
            title: Text(c.title, style: TextStyle(fontWeight: FontWeight.w700, color: c.selected ? builderInk : builderMuted)),
            subtitle: Text(
              '${widget.pageLabel}s ${c.pageStart}–${c.pageEnd} · ${c.lessons.length} lessons${c.isPublished ? ' · already in course' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Rename chapter',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final t = await _editText('Chapter title', c.title);
                  if (t != null && t.isNotEmpty) _changed(() => c.title = t);
                },
              ),
              IconButton(icon: Icon(_open ? Icons.expand_less : Icons.expand_more), onPressed: () => setState(() => _open = !_open)),
            ]),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < c.lessons.length; i++)
                    Row(children: [
                      Text('${i + 1}.', style: const TextStyle(color: builderMuted)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.lessons[i].title, style: const TextStyle(fontSize: 13.5))),
                      Text('${widget.pageLabel} ${c.lessons[i].pageStart}–${c.lessons[i].pageEnd}', style: const TextStyle(fontSize: 11.5, color: builderMuted)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        onPressed: () async {
                          final t = await _editText('Lesson title', c.lessons[i].title);
                          if (t != null && t.isNotEmpty) _changed(() => c.lessons[i].title = t);
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Merge into previous lesson',
                        icon: const Icon(Icons.remove_circle_outline, size: 17),
                        onPressed: c.lessons.length <= 1
                            ? null
                            : () => _changed(() {
                                  final removed = c.lessons.removeAt(i);
                                  if (i > 0) {
                                    c.lessons[i - 1].pageEnd = removed.pageEnd;
                                  } else {
                                    c.lessons[0].pageStart = removed.pageStart;
                                  }
                                }),
                      ),
                    ]),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.call_split, size: 18),
                      label: const Text('Split the longest lesson'),
                      onPressed: () => _changed(() {
                        if (c.lessons.isEmpty) return;
                        var idx = 0;
                        for (var i = 1; i < c.lessons.length; i++) {
                          if (c.lessons[i].pageEnd - c.lessons[i].pageStart > c.lessons[idx].pageEnd - c.lessons[idx].pageStart) idx = i;
                        }
                        final l = c.lessons[idx];
                        if (l.pageEnd <= l.pageStart) return;
                        final mid = (l.pageStart + l.pageEnd) ~/ 2;
                        c.lessons.insert(idx + 1, OutlineLesson(title: '${l.title} (continued)', pageStart: mid + 1, pageEnd: l.pageEnd));
                        l.pageEnd = mid;
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterReviewCard extends StatelessWidget {
  final String title;
  final List<BuildItemSummary> items;
  final bool wide;
  final bool expanded;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onApprove;
  final VoidCallback onPublish;
  final Widget Function(BuildItemSummary) itemBuilder;

  const _ChapterReviewCard({
    required this.title,
    required this.items,
    required this.wide,
    required this.expanded,
    required this.busy,
    required this.onToggle,
    required this.onApprove,
    required this.onPublish,
    required this.itemBuilder,
  });

  /// Chapter-level status shown in the review table.
  (String, Color, String) get _status {
    final live = items.where((i) => i.status != 'rejected').toList();
    if (live.any((i) => i.isWorking)) return ('⏳', const Color(0xFF2563EB), 'Generating');
    if (live.any((i) => i.status == 'error')) return ('❌', const Color(0xFFDC2626), 'Failed items');
    if (live.isNotEmpty && live.every((i) => i.isPublished && !i.dirtyAfterPublish)) return ('🌐', const Color(0xFF7C3AED), 'Published');
    if (live.isNotEmpty && live.every((i) => i.status == 'approved' || i.isPublished)) return ('✅', const Color(0xFF16A34A), 'Reviewed');
    if (live.any((i) => i.status == 'needs_review')) return ('⚠️', const Color(0xFFD97706), 'Review');
    return ('📝', const Color(0xFF6B7280), 'Draft');
  }

  @override
  Widget build(BuildContext context) {
    final lessons = items.where((i) => i.kind == 'lesson').length;
    final questions = items.fold<int>(0, (s, i) => s + i.questionCount);
    final (emoji, color, label) = _status;
    final canApprove = items.any((i) => i.isReviewable);
    final canPublish = items.any((i) => i.status == 'approved' || (i.isPublished && i.dirtyAfterPublish));

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$emoji $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      if (canApprove)
        TextButton(onPressed: busy ? null : onApprove, child: const Text('Approve')),
      if (canPublish)
        TextButton(onPressed: busy ? null : onPublish, child: const Text('Publish')),
    ]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(border: Border.all(color: builderBorder), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: wide
                  ? Row(children: [
                      Expanded(
                        flex: 6,
                        child: Row(children: [
                          Icon(expanded ? Icons.expand_less : Icons.expand_more, color: builderMuted),
                          const SizedBox(width: 6),
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                        ]),
                      ),
                      Expanded(flex: 2, child: Text('$lessons')),
                      Expanded(flex: 2, child: Text(questions > 0 ? '$questions questions' : '—')),
                      Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: statusBadge)),
                      SizedBox(width: 200, child: Align(alignment: Alignment.centerRight, child: actions)),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(expanded ? Icons.expand_less : Icons.expand_more, color: builderMuted),
                        const SizedBox(width: 6),
                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                        statusBadge,
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 4),
                        child: Row(children: [
                          Text('$lessons lessons · $questions questions', style: const TextStyle(fontSize: 12.5, color: builderMuted)),
                          const Spacer(),
                          actions,
                        ]),
                      ),
                    ]),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            ...items.map(itemBuilder),
          ],
        ],
      ),
    );
  }
}
