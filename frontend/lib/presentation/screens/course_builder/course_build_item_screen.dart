import 'dart:async';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/course_build.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/ai_study_guide.dart';
import 'widgets/build_options_panel.dart';

/// Review one AI draft: preview it exactly as students will see it, edit the
/// content and questions, check them against the book pages, regenerate,
/// approve or reject.
class CourseBuildItemScreen extends StatefulWidget {
  final String itemId;
  const CourseBuildItemScreen({super.key, required this.itemId});

  @override
  State<CourseBuildItemScreen> createState() => _CourseBuildItemScreenState();
}

class _CourseBuildItemScreenState extends State<CourseBuildItemScreen>
    with SingleTickerProviderStateMixin {
  final _service = CourseBuilderService();
  late final TabController _tabs = TabController(length: 4, vsync: this);
  BuildItem? _item;
  String? _error;
  bool _dirty = false;
  bool _saving = false;
  Timer? _poll;
  int _editVersion = 0; // bumps to rebuild editors after reload

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final item = await _service.getItem(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _dirty = false;
        _error = null;
        _editVersion++;
      });
      _poll?.cancel();
      if (item.isWorking) _poll = Timer(const Duration(seconds: 3), _load);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _save({bool quiet = false}) async {
    final item = _item;
    if (item == null) return false;
    setState(() => _saving = true);
    try {
      final saved = await _service.saveItem(item);
      if (!mounted) return true;
      setState(() {
        _item = saved;
        _dirty = false;
        _editVersion++;
      });
      if (!quiet) _snack('Saved');
      return true;
    } catch (e) {
      _snack(e.toString(), error: true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(String status) async {
    if (_dirty && !await _save(quiet: true)) return;
    try {
      await _service.setItemStatus(widget.itemId, status);
      if (!mounted) return;
      _snack(status == 'approved'
          ? 'Approved — it will be published with the next Publish'
          : status == 'rejected'
              ? 'Rejected'
              : 'Moved back to draft');
      await _load();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _regenerate() async {
    final item = _item!;
    final ctrl = TextEditingController();
    String part = 'all';
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Regenerate with AI'),
          content: SizedBox(
            width: 460,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    controller: ctrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'What should change? (optional)',
                      hintText:
                          'e.g. Add a worked example on annuities. Harder questions.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_dirty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('Your unsaved edits will be replaced.',
                          style: TextStyle(color: Colors.red, fontSize: 12.5)),
                    ),
                ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Regenerate')),
          ],
        ),
      ),
    );
    if (go != true) return;
    try {
      await _service.regenerateItem(widget.itemId,
          part: part, instructions: ctrl.text);
      _snack('Regenerating… this page updates when it is done');
      await _load();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save your edits before leaving?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: const Text('Discard')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Save')),
        ],
      ),
    );
    if (r == 'save') return _save(quiet: true);
    return r == 'discard';
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red[700] : builderGreen,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          // canPop is read from the rebuilt PopScope, so pop after the frame.
          setState(() => _dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: AppBar(
          backgroundColor: builderGreen,
          foregroundColor: Colors.white,
          title: Text(item?.title ?? 'Review',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            if (item != null && !item.isWorking) ...[
              IconButton(
                  tooltip: 'Regenerate with AI',
                  onPressed: _regenerate,
                  icon: const Icon(Icons.auto_awesome)),
              if (_dirty)
                TextButton.icon(
                  onPressed: _saving ? null : () => _save(),
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                ),
            ],
          ],
          bottom: item == null
              ? null
              : TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    const Tab(
                        icon: Icon(Icons.visibility_outlined, size: 18),
                        text: 'Preview'),
                    const Tab(
                        icon: Icon(Icons.edit_note, size: 18),
                        text: 'Edit content'),
                    Tab(
                        icon: const Icon(Icons.quiz_outlined, size: 18),
                        text: 'Questions (${item.questions.length})'),
                    const Tab(
                        icon: Icon(Icons.menu_book_outlined, size: 18),
                        text: 'Book source'),
                  ],
                ),
        ),
        body: item == null
            ? Center(
                child: _error != null
                    ? Text(_error!)
                    : const CircularProgressIndicator())
            : item.isWorking
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: builderGreen),
                      SizedBox(height: 16),
                      Text('The AI is writing this item…',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  )
                : Column(
                    children: [
                      _ReviewBanner(
                          item: item,
                          onApprove: () => _setStatus('approved'),
                          onReject: () => _setStatus('rejected'),
                          onDraft: () => _setStatus('draft')),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _PreviewTab(item: item),
                            _ContentEditor(
                                key: ValueKey('content-$_editVersion'),
                                item: item,
                                onChanged: _touch),
                            _QuestionsEditor(
                                key: ValueKey('q-$_editVersion'),
                                item: item,
                                service: _service,
                                onChanged: _touch,
                                onSnack: _snack),
                            _SourceTab(item: item, service: _service),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  final BuildItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDraft;
  const _ReviewBanner(
      {required this.item,
      required this.onApprove,
      required this.onReject,
      required this.onDraft});

  @override
  Widget build(BuildContext context) {
    final conf = item.confidence;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BuildStatusChip(item.status),
              if (conf != null)
                Text('AI confidence $conf%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: conf >= 85
                          ? const Color(0xFF16A34A)
                          : conf >= 70
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626),
                    )),
              Text('Book pages ${item.pageStart}–${item.pageEnd}',
                  style: const TextStyle(color: builderMuted, fontSize: 12.5)),
              if (item.isPublished)
                const Text('· Live in the course — saving marks it for update',
                    style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12.5)),
              const SizedBox(width: 8),
              if (item.status == 'draft' ||
                  item.status == 'needs_review' ||
                  (item.isPublished)) ...[
                ElevatedButton.icon(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: builderGreen,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(item.isPublished ? 'Approve changes' : 'Approve'),
                ),
                if (!item.isPublished)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Reject'),
                  ),
              ],
              if (item.status == 'approved' || item.status == 'rejected')
                OutlinedButton(
                    onPressed: onDraft,
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: const Text('Back to draft')),
            ],
          ),
          if (item.error != null && item.status == 'error') ...[
            const SizedBox(height: 8),
            Text('Generation failed: ${item.error}',
                style: const TextStyle(color: Colors.red)),
          ],
          for (final w in item.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF92400E)))),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─── Preview ─────────────────────────────────────────────────────────────────

class _PreviewTab extends StatelessWidget {
  final BuildItem item;
  const _PreviewTab({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = AiGuidePalette.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.content != null)
                  AiStudyGuideView(
                      content: {...item.content!, 'kind': item.kind},
                      palette: palette),
                if (item.questions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(item.kind == 'lesson' ? 'Lesson quiz' : 'Questions',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < item.questions.length; i++)
                    _QuestionPreview(index: i + 1, q: item.questions[i]),
                ],
                if (item.content == null && item.questions.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Nothing generated yet.'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  final int index;
  final DraftQuestion q;
  const _QuestionPreview({required this.index, required this.q});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: builderBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Q$index',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: builderGreen)),
            const SizedBox(width: 8),
            _Tag(q.typeLabel),
            const SizedBox(width: 6),
            _DifficultyTag(q.difficulty),
            const Spacer(),
            _VerifiedTag(q),
          ]),
          const SizedBox(height: 8),
          Text(q.question,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.45)),
          const SizedBox(height: 8),
          if (q.hasOptions)
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          i == q.correctIndex
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: i == q.correctIndex
                              ? builderGreen
                              : builderMuted),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                              style: TextStyle(
                                  fontWeight: i == q.correctIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400))),
                    ]),
              )
          else
            Text('Model answer: ${q.answer}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: builderGreen)),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.explanation,
                style: const TextStyle(
                    fontSize: 13, color: builderMuted, height: 1.45)),
          ],
          if (q.sourceLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('📖 ${q.sourceLabel}',
                style: const TextStyle(fontSize: 12, color: builderMuted)),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: builderMuted)),
      );
}

class _DifficultyTag extends StatelessWidget {
  final String difficulty;
  const _DifficultyTag(this.difficulty);
  @override
  Widget build(BuildContext context) {
    final c = switch (difficulty) {
      'easy' => const Color(0xFF16A34A),
      'hard' => const Color(0xFFDC2626),
      _ => const Color(0xFFD97706)
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty[0].toUpperCase() + difficulty.substring(1),
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

class _VerifiedTag extends StatelessWidget {
  final DraftQuestion q;
  const _VerifiedTag(this.q);
  @override
  Widget build(BuildContext context) {
    final ok = q.verified;
    return Tooltip(
      message: ok
          ? 'The supporting quote was found in the book${q.sourceQuote.isNotEmpty ? ':\n"${q.sourceQuote}"' : ''}'
          : 'The AI\'s supporting quote could not be found in the book — please check this question',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.verified : Icons.help_outline,
            size: 16, color: ok ? builderGreen : const Color(0xFFD97706)),
        const SizedBox(width: 4),
        Text(
            ok
                ? 'Source verified · ${q.confidence}%'
                : 'Check source · ${q.confidence}%',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: ok ? builderGreen : const Color(0xFFD97706))),
      ]),
    );
  }
}

// ─── Content editor ──────────────────────────────────────────────────────────

class _ContentEditor extends StatefulWidget {
  final BuildItem item;
  final VoidCallback onChanged;
  const _ContentEditor(
      {super.key, required this.item, required this.onChanged});

  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  Map<String, dynamic> get c => widget.item.content ??= <String, dynamic>{};

  void _set(String key, dynamic value) {
    c[key] = value;
    widget.onChanged();
  }

  List<Map<String, dynamic>> _list(String key) {
    final v = c[key];
    if (v is List) {
      final l =
          v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      c[key] = l;
      return l;
    }
    final l = <Map<String, dynamic>>[];
    c[key] = l;
    return l;
  }

  String _lines(String key) => (c[key] is List)
      ? (c[key] as List).map((e) => e.toString()).join('\n')
      : '';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.kind == 'chapter_test' || item.kind == 'mock_exam') {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'This item only has questions — see the Questions tab.')));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('Lesson title', item.title, (v) {
                  item.title = v;
                  widget.onChanged();
                }),
                _field('Summary', c['summary']?.toString() ?? '',
                    (v) => _set('summary', v),
                    lines: 3),
                _field(
                    'Learning objectives (one per line)',
                    _lines('learningObjectives'),
                    (v) => _set('learningObjectives', _split(v)),
                    lines: 4),
                _field('Lesson notes (Markdown)', c['notes']?.toString() ?? '',
                    (v) => _set('notes', v),
                    lines: 18, mono: true),
                _field('Key points (one per line)', _lines('keyPoints'),
                    (v) => _set('keyPoints', _split(v)),
                    lines: 5),
                if (item.kind == 'revision') ...[
                  _field('Exam tips (one per line)', _lines('examTips'),
                      (v) => _set('examTips', _split(v)),
                      lines: 4),
                  _field(
                      'Common mistakes (one per line)',
                      _lines('commonMistakes'),
                      (v) => _set('commonMistakes', _split(v)),
                      lines: 4),
                ],
                _ObjectListEditor(
                  title: 'Key terms',
                  items: _list('keyTerms'),
                  fields: const [
                    ('term', 'Term', 1),
                    ('definition', 'Definition', 2)
                  ],
                  onChanged: () => setState(widget.onChanged),
                ),
                _ObjectListEditor(
                  title: 'Formulas',
                  items: _list('formulas'),
                  fields: const [
                    ('name', 'Name', 1),
                    ('expression', 'Expression', 1),
                    ('explanation', 'Explanation', 2)
                  ],
                  onChanged: () => setState(widget.onChanged),
                ),
                _ObjectListEditor(
                  title: 'Worked examples',
                  items: _list('examples'),
                  fields: const [
                    ('title', 'Title', 1),
                    ('body', 'Steps (Markdown)', 6)
                  ],
                  onChanged: () => setState(widget.onChanged),
                ),
                _ObjectListEditor(
                  title: 'Flashcards',
                  items: _list('flashcards'),
                  fields: const [('front', 'Front', 1), ('back', 'Back', 2)],
                  onChanged: () => setState(widget.onChanged),
                ),
                const SizedBox(height: 8),
                const Text('Visuals',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                    'Generated diagrams and charts. Remove any that are wrong; use Regenerate to ask for different ones.',
                    style: TextStyle(color: builderMuted, fontSize: 12.5)),
                const SizedBox(height: 10),
                ..._list('visuals').asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(children: [
                        AiVisualCard(
                            visual: e.value,
                            palette: AiGuidePalette.of(context)),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton(
                            tooltip: 'Remove visual',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => setState(() {
                              _list('visuals').removeAt(e.key);
                              widget.onChanged();
                            }),
                          ),
                        ),
                      ]),
                    )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _split(String v) =>
      v.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Widget _field(String label, String initial, ValueChanged<String> onChanged,
      {int lines = 1, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: initial,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 10,
        style: mono
            ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
            : null,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ObjectListEditor extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final List<(String, String, int)> fields;
  final VoidCallback onChanged;
  const _ObjectListEditor(
      {required this.title,
      required this.items,
      required this.fields,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: builderBorder)),
      child: ExpansionTile(
        title: Text('$title (${items.length})',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              key: ObjectKey(items[i]),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(children: [
                    for (final f in fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          initialValue: items[i][f.$1]?.toString() ?? '',
                          minLines: f.$3,
                          maxLines: f.$3 == 1 ? 1 : f.$3 + 6,
                          decoration: InputDecoration(
                              labelText: f.$2,
                              isDense: true,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white),
                          onChanged: (v) {
                            items[i][f.$1] = v;
                            onChanged();
                          },
                        ),
                      ),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    items.removeAt(i);
                    onChanged();
                  },
                ),
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(
                  'Add ${title.toLowerCase().replaceAll(RegExp(r's$'), '')}'),
              onPressed: () {
                items.add({for (final f in fields) f.$1: ''});
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Questions editor ────────────────────────────────────────────────────────

class _QuestionsEditor extends StatefulWidget {
  final BuildItem item;
  final CourseBuilderService service;
  final VoidCallback onChanged;
  final void Function(String, {bool error}) onSnack;
  const _QuestionsEditor(
      {super.key,
      required this.item,
      required this.service,
      required this.onChanged,
      required this.onSnack});

  @override
  State<_QuestionsEditor> createState() => _QuestionsEditorState();
}

class _QuestionsEditorState extends State<_QuestionsEditor> {
  final Set<int> _regenerating = {};
  String _filter = 'all';

  List<DraftQuestion> get qs => widget.item.questions;

  void _changed(DraftQuestion q) {
    q.edited = true;
    widget.onChanged();
  }

  Future<void> _regen(int i) async {
    final q = qs[i];
    if (q.id == null) {
      widget.onSnack('Save first, then regenerate this question', error: true);
      return;
    }
    setState(() => _regenerating.add(i));
    try {
      final fresh =
          await widget.service.regenerateQuestion(widget.item.id, q.id!);
      setState(() => qs[i] = fresh);
      widget.onSnack('Question replaced');
    } catch (e) {
      widget.onSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _regenerating.remove(i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = <int>[
      for (var i = 0; i < qs.length; i++)
        if (_filter == 'all' ||
            (_filter == 'unverified' && !qs[i].verified) ||
            qs[i].difficulty == _filter)
          i,
    ];
    final counts = {
      for (final d in ['easy', 'medium', 'hard'])
        d: qs.where((q) => q.difficulty == d).length
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final f in [
                    ('all', 'All (${qs.length})'),
                    ('easy', 'Easy (${counts['easy']})'),
                    ('medium', 'Medium (${counts['medium']})'),
                    ('hard', 'Hard (${counts['hard']})'),
                    (
                      'unverified',
                      'Needs checking (${qs.where((q) => !q.verified).length})'
                    ),
                  ])
                    ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      selectedColor: builderGreen.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                ]),
                const SizedBox(height: 14),
                for (final i in visible)
                  _QuestionCard(
                    key: ObjectKey(qs[i]),
                    index: i + 1,
                    q: qs[i],
                    regenerating: _regenerating.contains(i),
                    onChanged: () => _changed(qs[i]),
                    onDelete: () {
                      setState(() => qs.removeAt(i));
                      widget.onChanged();
                    },
                    onRegenerate: () => _regen(i),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => qs.add(DraftQuestion(
                        type: 'mcq',
                        options: ['', '', '', ''],
                        correctIndex: 0,
                        verified: true,
                        confidence: 100,
                        edited: true)));
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add question'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final DraftQuestion q;
  final bool regenerating;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  const _QuestionCard(
      {super.key,
      required this.index,
      required this.q,
      required this.regenerating,
      required this.onChanged,
      required this.onDelete,
      required this.onRegenerate});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  DraftQuestion get q => widget.q;

  void _set(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isTf = q.type == 'true_false';
    final isShort = q.type == 'short_answer';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: q.verified ? builderBorder : const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Q${widget.index}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: builderGreen)),
                DropdownButton<String>(
                  value: q.type,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'mcq', child: Text('Multiple choice')),
                    DropdownMenuItem(
                        value: 'true_false', child: Text('True / False')),
                    DropdownMenuItem(
                        value: 'short_answer', child: Text('Short answer')),
                    DropdownMenuItem(
                        value: 'calculation', child: Text('Calculation')),
                    DropdownMenuItem(
                        value: 'scenario', child: Text('Scenario')),
                  ],
                  onChanged: (v) => _set(() {
                    q.type = v ?? 'mcq';
                    if (q.type == 'true_false') {
                      q.options = ['True', 'False'];
                      q.correctIndex = (q.correctIndex == 1) ? 1 : 0;
                    } else if (q.type == 'short_answer') {
                      q.options = [];
                      q.correctIndex = null;
                    } else if (q.options.length < 2) {
                      q.options = ['', '', '', ''];
                      q.correctIndex = 0;
                    }
                  }),
                ),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  style:
                      const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: 'easy', label: Text('Easy')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'hard', label: Text('Hard')),
                  ],
                  selected: {q.difficulty},
                  onSelectionChanged: (s) => _set(() => q.difficulty = s.first),
                ),
                _VerifiedTag(q),
              ]),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: q.question,
            minLines: 2,
            maxLines: 8,
            decoration: const InputDecoration(
                labelText: 'Question', border: OutlineInputBorder()),
            onChanged: (v) {
              q.question = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          if (!isShort)
            RadioGroup<int>(
              groupValue: q.correctIndex,
              onChanged: (v) => _set(() => q.correctIndex = v),
              child: Column(children: [
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Radio<int>(value: i, activeColor: builderGreen),
                      Expanded(
                        child: isTf
                            ? Text(q.options[i])
                            : TextFormField(
                                key: ValueKey('opt-$i-${q.options.length}'),
                                initialValue: q.options[i],
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText:
                                      'Option ${String.fromCharCode(65 + i)}${i == q.correctIndex ? ' (correct)' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  q.options[i] = v;
                                  widget.onChanged();
                                },
                              ),
                      ),
                      if (!isTf && q.options.length > 2)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _set(() {
                            q.options.removeAt(i);
                            final c = q.correctIndex;
                            if (c != null) {
                              if (c == i) {
                                q.correctIndex = 0;
                              } else if (c > i) {
                                q.correctIndex = c - 1;
                              }
                            }
                          }),
                        ),
                    ]),
                  ),
              ]),
            ),
          if (!isShort && !isTf && q.options.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: () => _set(() => q.options.add('')),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add option')),
            ),
          if (isShort)
            TextFormField(
              initialValue: q.answer,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Model answer', border: OutlineInputBorder()),
              onChanged: (v) {
                q.answer = v;
                widget.onChanged();
              },
            ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: q.explanation,
            minLines: 2,
            maxLines: 8,
            decoration: const InputDecoration(
                labelText: 'Explanation (shown after answering)',
                border: OutlineInputBorder()),
            onChanged: (v) {
              q.explanation = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(
                q.sourceLabel.isEmpty
                    ? 'No source reference'
                    : '📖 ${q.sourceLabel}${q.sourceQuote.isNotEmpty ? '\n“${q.sourceQuote}”' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: builderMuted, height: 1.4),
              ),
            ),
            if (widget.regenerating)
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else
              IconButton(
                  tooltip: 'Replace with a new AI question',
                  onPressed: widget.onRegenerate,
                  icon: const Icon(Icons.auto_awesome, color: builderGreen)),
            IconButton(
                tooltip: 'Delete question',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ]),
        ],
      ),
    );
  }
}

// ─── Book source ─────────────────────────────────────────────────────────────

class _SourceTab extends StatefulWidget {
  final BuildItem item;
  final CourseBuilderService service;
  const _SourceTab({required this.item, required this.service});

  @override
  State<_SourceTab> createState() => _SourceTabState();
}

class _SourceTabState extends State<_SourceTab>
    with AutomaticKeepAliveClientMixin {
  List<({int n, String text})> _pages = [];
  late int _from = widget.item.pageStart;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pages = await widget.service
          .sourcePages(widget.item.id, from: _from, to: _from + 9);
      if (mounted) setState(() => _pages = pages);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final item = widget.item;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            const Expanded(
              child: Text(
                  'Original text the AI used — check facts and figures against it.',
                  style: TextStyle(fontSize: 12.5, color: builderMuted)),
            ),
            IconButton(
              onPressed: _from > item.pageStart
                  ? () {
                      _from = (_from - 10).clamp(item.pageStart, item.pageEnd);
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
                'Pages $_from–${(_from + 9).clamp(_from, item.pageEnd)} of ${item.pageStart}–${item.pageEnd}',
                style: const TextStyle(fontSize: 12.5)),
            IconButton(
              onPressed: _from + 10 <= item.pageEnd
                  ? () {
                      _from += 10;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _pages
                          .map((p) => Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: builderBorder)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Page ${p.n}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: builderGreen)),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                          p.text.isEmpty
                                              ? '(no text on this page)'
                                              : p.text,
                                          style: const TextStyle(
                                              fontSize: 13.5, height: 1.6)),
                                    ]),
                              ))
                          .toList(),
                    ),
        ),
      ],
    );
  }
}
