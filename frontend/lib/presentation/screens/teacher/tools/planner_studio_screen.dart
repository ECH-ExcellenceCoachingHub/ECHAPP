import 'package:flutter/material.dart';

import '../../../../services/api/teacher_tools_service.dart';
import 'tools_common.dart';

class _KindConfig {
  final String title, heading, blurb, rowLabel, countLabel, noun, hint;
  final int defaultCount, maxCount;
  final Color color;
  final IconData icon;
  final List<String> formats; // export formats
  const _KindConfig({required this.title, required this.heading, required this.blurb, required this.rowLabel, required this.countLabel, required this.noun, required this.hint, required this.defaultCount, required this.maxCount, required this.color, required this.icon, required this.formats});
}

const _configs = {
  PlannerKind.slides: _KindConfig(
    title: 'Slides', heading: 'Slide deck builder', blurb: 'Describe the lesson and get a ready-to-teach PowerPoint deck you can edit.',
    rowLabel: 'slide', countLabel: 'How many slides', noun: 'slide decks', hint: 'e.g. Unit 6 "Les habits" — vocabulary deck for P3, 10 slides',
    defaultCount: 10, maxCount: 25, color: Color(0xFFC43E1C), icon: Icons.slideshow, formats: ['pptx', 'pdf']),
  PlannerKind.exercises: _KindConfig(
    title: 'Exercises', heading: 'Exercise sheet builder', blurb: 'Turn a lesson into a printable question sheet with a marking key.',
    rowLabel: 'question', countLabel: 'How many questions', noun: 'exercise sheets', hint: 'e.g. 10 questions on fractions for P4 — mixed multiple choice and short answer',
    defaultCount: 10, maxCount: 40, color: Color(0xFF7C3AED), icon: Icons.fact_check, formats: ['docx', 'pdf']),
  PlannerKind.scheme: _KindConfig(
    title: 'Scheme of Work', heading: 'Scheme of work builder', blurb: 'Lay out a whole term week by week, then export it for your head teacher.',
    rowLabel: 'week', countLabel: 'How many weeks', noun: 'schemes of work', hint: 'e.g. Mathematics P4, Term 2 — 12 weeks covering units 4 to 7',
    defaultCount: 12, maxCount: 20, color: Color(0xFF0891B2), icon: Icons.calendar_month, formats: ['docx', 'pdf']),
};

const _slideLayouts = {
  'title': 'Title slide', 'bullets': 'Bullet points', 'twoColumn': 'Two columns', 'compare': 'Compare (two panels)',
  'steps': 'Numbered steps', 'callout': 'Big statement', 'image': 'Text + picture', 'question': 'Question to the class', 'summary': 'Summary + homework',
};

/// Slides / Exercises / Scheme of Work — ECH tools, engine on eexams.
class PlannerStudioScreen extends StatefulWidget {
  final PlannerKind kind;
  const PlannerStudioScreen({super.key, required this.kind});
  @override
  State<PlannerStudioScreen> createState() => _PlannerStudioScreenState();
}

class _PlannerStudioScreenState extends State<PlannerStudioScreen> {
  final _svc = TeacherToolsService();
  _KindConfig get _cfg => _configs[widget.kind]!;

  bool _loading = true;
  TeacherToolsStatus? _status;
  PlannerQuota? _quota;
  List<Map<String, dynamic>> _saved = [];
  List<Map<String, dynamic>> _themes = [];

  final _brief = TextEditingController();
  late int _count = _cfg.defaultCount;
  String _questionType = 'mixed';
  String _theme = 'classic';
  final Map<String, dynamic> _details = {'subject': '', 'className': '', 'term': '', 'unitTitle': '', 'academicYear': '${DateTime.now().year}', 'language': 'auto'};

  String? _refName;
  String _refText = '';
  bool _reading = false;

  Map<String, dynamic>? _res;
  String? _resId;
  int _version = 0;
  bool _generating = false, _saving = false;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _brief.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _status = await _svc.status();
      if (_status!.linked) {
        final quotas = await _svc.quotas();
        _quota = quotas.where((q) => q.key == widget.kind.quotaKey).firstOrNull;
        _saved = await _svc.listResources(widget.kind);
        if (widget.kind == PlannerKind.slides) _themes = await _svc.slideThemes();
      }
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final quotas = await _svc.quotas();
      final saved = await _svc.listResources(widget.kind);
      if (!mounted) return;
      setState(() {
        _quota = quotas.where((q) => q.key == widget.kind.quotaKey).firstOrNull;
        _saved = saved;
      });
    } catch (_) {}
  }

  Map<String, dynamic> _newRow(int n) => switch (widget.kind) {
        PlannerKind.slides => {'layout': 'bullets', 'eyebrow': '', 'heading': '', 'bullets': <String>[''], 'columnLabels': <String>[], 'imageIdea': '', 'homework': '', 'notes': ''},
        PlannerKind.exercises => {'number': '$n', 'question': '', 'options': <String>[], 'answer': '', 'marks': ''},
        PlannerKind.scheme => {'week': '$n', 'lessonNo': '', 'unitTitle': '', 'lessonTitle': '', 'objectives': '', 'activities': '', 'materials': '', 'assessment': ''},
      };

  Map<String, dynamic> _empty() => {
        'kind': widget.kind.api, 'theme': _theme, 'title': '', 'subject': '', 'className': '', 'term': '', 'unitTitle': '',
        'academicYear': '${DateTime.now().year}', 'schoolName': '', 'teacherName': '', 'language': '', 'instructions': '', widget.kind.bodyKey: <dynamic>[],
      };

  Future<void> _attach() async {
    try {
      final file = await pickDocument();
      if (file == null) return;
      setState(() => _reading = true);
      final text = await _svc.extractText(file);
      setState(() { _refName = file.name; _refText = text; });
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _generate() async {
    if (_brief.text.trim().isEmpty && _refText.isEmpty) {
      showToolMessage(context, 'Tell us what to prepare, or attach the book first.');
      return;
    }
    setState(() => _generating = true);
    try {
      final res = await _svc.generateResource(widget.kind, {
        'brief': _brief.text.trim(), 'referenceContent': _refText, 'count': _count, 'questionType': _questionType, 'theme': _theme,
        ..._details, 'sourceFileName': _refName ?? '',
      });
      setState(() { _res = {..._empty(), 'theme': _theme, ...res}; _resId = null; _version++; });
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startBlank() => setState(() {
        _res = {..._empty(), ..._details, 'language': _details['language'] == 'auto' ? '' : _details['language'], 'sourcePrompt': _brief.text.trim(), widget.kind.bodyKey: [_newRow(1)]};
        _resId = null;
        _version++;
      });

  Future<void> _save() async {
    final r = _res;
    if (r == null) return;
    setState(() => _saving = true);
    try {
      final payload = {...r}..remove('_id')..remove('createdBy')..remove('createdAt')..remove('updatedAt');
      final saved = await _svc.saveResource(widget.kind, payload, id: _resId);
      setState(() => _resId = saved['_id']?.toString());
      if (mounted) showToolMessage(context, 'Saved to your library.');
      _refresh();
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _download(String format, {Map<String, dynamic>? res, String? id}) async {
    final target = res ?? _res;
    if (target == null) return;
    setState(() => _downloading = format);
    try {
      final bytes = await _svc.exportResource(widget.kind, format, id: id ?? _resId, resource: target);
      final name = [target['subject'], target['className'], target['title']].where((s) => (s ?? '').toString().isNotEmpty).join(' - ');
      await saveAndOpenDocument(bytes, '${name.isEmpty ? widget.kind.api : name}.$format');
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await _svc.deleteResource(widget.kind, item['_id'].toString());
      if (_resId == item['_id']) setState(() { _res = null; _resId = null; });
      _refresh();
    } catch (e) {
      if (mounted) showToolError(context, e);
    }
  }

  String _fmtLabel(String f) => switch (f) { 'pptx' => 'PowerPoint', 'docx' => 'Word', _ => 'PDF' };

  void _showSaved() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('My ${_cfg.title.toLowerCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          Expanded(
            child: _saved.isEmpty
                ? const Center(child: Text('Nothing saved yet.'))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: _saved.length,
                    itemBuilder: (_, i) {
                      final s = _saved[i];
                      return ListTile(
                        leading: Icon(_cfg.icon, color: _cfg.color),
                        title: Text((s['title'] ?? s['unitTitle'] ?? _cfg.title).toString()),
                        subtitle: Text([s['subject'], s['className'], s['term']].where((x) => (x ?? '').toString().isNotEmpty).join(' · ')),
                        onTap: () {
                          Navigator.pop(c);
                          setState(() { _res = Map<String, dynamic>.from(s); _resId = s['_id']?.toString(); if (s['theme'] != null) _theme = s['theme'].toString(); _version++; });
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            Navigator.pop(c);
                            v == 'delete' ? _delete(s) : _download(v, res: s, id: s['_id'].toString());
                          },
                          itemBuilder: (_) => [
                            for (final f in _cfg.formats) PopupMenuItem(value: f, child: Text('Download ${_fmtLabel(f)}')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cfg.title),
        backgroundColor: _cfg.color,
        foregroundColor: Colors.white,
        actions: [
          if (_status?.linked == true)
            TextButton.icon(onPressed: _showSaved, icon: const Icon(Icons.folder_open, color: Colors.white), label: Text('Saved (${_saved.length})', style: const TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_status?.linkRequired == true) LinkRequiredCard(message: _status?.message, onRetry: _load),
                if (_status?.linked == true) ...[
                  QuotaBanner(quota: _quota, noun: _cfg.noun),
                  _buildBrief(),
                  if (_res != null) _buildEditor(),
                ],
              ]),
            ),
      bottomNavigationBar: _res == null ? null : _buildActions(),
    );
  }

  Widget _buildBrief() {
    final exhausted = _quota != null && !_quota!.allowed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_cfg.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_cfg.blurb, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: _brief, minLines: 2, maxLines: 5, decoration: InputDecoration(hintText: _cfg.hint, border: const OutlineInputBorder())),
          const SizedBox(height: 10),
          ReferenceAttach(fileName: _refName, busy: _reading, onAttach: _attach, onClear: () => setState(() { _refName = null; _refText = ''; })),
          const SizedBox(height: 10),
          Row(children: [
            Text('${_cfg.countLabel}: $_count', style: const TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: Slider(
                value: _count.toDouble(), min: 1, max: _cfg.maxCount.toDouble(), divisions: _cfg.maxCount - 1,
                activeColor: _cfg.color, onChanged: (v) => setState(() => _count = v.round()),
              ),
            ),
          ]),
          if (widget.kind == PlannerKind.exercises)
            DropdownButtonFormField<String>(
              value: _questionType,
              decoration: const InputDecoration(labelText: 'Question type', isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple choice')),
                DropdownMenuItem(value: 'open', child: Text('Open response')),
              ],
              onChanged: (v) => setState(() => _questionType = v ?? 'mixed'),
            ),
          if (widget.kind == PlannerKind.slides && _themes.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text('Design', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in _themes)
                ChoiceChip(
                  selected: _theme == t['key'],
                  avatar: CircleAvatar(backgroundColor: _hex(t['swatch']?['deep']), radius: 8),
                  label: Text((t['name'] ?? t['key']).toString()),
                  onSelected: (_) => setState(() { _theme = t['key'].toString(); if (_res != null) _res!['theme'] = _theme; }),
                ),
            ]),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Details (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              FieldGrid(children: [
                mapField(_details, 'subject', 'Subject', version: 'd', onChanged: () {}),
                mapField(_details, 'className', 'Class', version: 'd', onChanged: () {}),
                widget.kind == PlannerKind.scheme
                    ? mapField(_details, 'term', 'Term', version: 'd', onChanged: () {})
                    : mapField(_details, 'unitTitle', 'Unit', version: 'd', onChanged: () {}),
                mapField(_details, 'academicYear', 'Academic year', version: 'd', onChanged: () {}),
              ]),
              DropdownButtonFormField<String>(
                value: _details['language'] as String,
                decoration: const InputDecoration(labelText: 'Language', isDense: true, border: OutlineInputBorder()),
                items: [for (final l in const ['auto', 'English', 'French', 'Kinyarwanda', 'Kiswahili']) DropdownMenuItem(value: l, child: Text(l == 'auto' ? 'Match the subject / book' : l))],
                onChanged: (v) => setState(() => _details['language'] = v ?? 'auto'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _cfg.color, foregroundColor: Colors.white),
              onPressed: _generating || exhausted ? null : _generate,
              icon: _generating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_generating ? 'Working… (up to a minute)' : 'Generate with AI'),
            ),
            OutlinedButton.icon(onPressed: exhausted ? null : _startBlank, icon: const Icon(Icons.edit_note, size: 18), label: const Text('Start blank')),
          ]),
        ]),
      ),
    );
  }

  Color _hex(dynamic s) {
    final h = (s ?? '').toString().replaceFirst('#', '');
    return h.length == 6 ? Color(int.parse('FF$h', radix: 16)) : _cfg.color;
  }

  Widget _buildEditor() {
    final r = _res!;
    final v = 'r$_version';
    void touch() {}
    final rows = (r[widget.kind.bodyKey] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    r[widget.kind.bodyKey] = rows;
    List<String> lines(dynamic x) => (x as List? ?? []).map((e) => e.toString()).toList();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(_cfg.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            if (_resId != null) const Chip(label: Text('Saved'), avatar: Icon(Icons.check_circle, size: 16, color: kToolsGreen)),
          ]),
          const SizedBox(height: 10),
          mapField(r, 'title', 'Title', version: v, onChanged: touch),
          FieldGrid(children: [
            mapField(r, 'subject', 'Subject', version: v, onChanged: touch),
            mapField(r, 'className', 'Class', version: v, onChanged: touch),
            mapField(r, widget.kind == PlannerKind.scheme ? 'term' : 'unitTitle', widget.kind == PlannerKind.scheme ? 'Term' : 'Unit', version: v, onChanged: touch),
            mapField(r, 'academicYear', 'Academic year', version: v, onChanged: touch),
            mapField(r, 'schoolName', 'School name', version: v, onChanged: touch),
            mapField(r, 'teacherName', "Teacher's name", version: v, onChanged: touch),
          ]),
          if (widget.kind == PlannerKind.exercises) mapField(r, 'instructions', 'Instructions to learners', version: v, onChanged: touch, maxLines: 3),
          const Divider(height: 24),
          for (var i = 0; i < rows.length; i++) _rowEditor(rows, i, '$v-$i-${rows.length}', lines),
          TextButton.icon(
            onPressed: () => setState(() { rows.add(_newRow(rows.length + 1)); _version++; }),
            icon: const Icon(Icons.add),
            label: Text('Add a ${_cfg.rowLabel}'),
          ),
        ]),
      ),
    );
  }

  Widget _rowEditor(List<Map<String, dynamic>> rows, int i, String v, List<String> Function(dynamic) lines) {
    final row = rows[i];
    void touch() {}
    final header = Row(children: [
      Text('${_cfg.rowLabel[0].toUpperCase()}${_cfg.rowLabel.substring(1)} ${i + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: _cfg.color)),
      const Spacer(),
      IconButton(tooltip: 'Remove', icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() { rows.removeAt(i); _version++; })),
    ]);

    final List<Widget> body = switch (widget.kind) {
      PlannerKind.slides => [
          DropdownButtonFormField<String>(
            value: _slideLayouts.containsKey(row['layout']) ? row['layout'] as String : 'bullets',
            decoration: const InputDecoration(labelText: 'Layout', isDense: true, border: OutlineInputBorder()),
            items: [for (final e in _slideLayouts.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (val) => setState(() { row['layout'] = val ?? 'bullets'; _version++; }),
          ),
          const SizedBox(height: 10),
          mapField(row, 'eyebrow', 'Small label above the heading', version: v, onChanged: touch),
          mapField(row, 'heading', 'Heading', version: v, onChanged: touch),
          if (row['layout'] == 'compare')
            LineListEditor(keyPrefix: '$v-cl', label: 'Panel headings (left, right)', items: lines(row['columnLabels']), onChanged: (l) => setState(() => row['columnLabels'] = l)),
          LineListEditor(
            keyPrefix: '$v-b',
            label: row['layout'] == 'steps' ? 'Steps, in order' : row['layout'] == 'question' ? 'Question (first line), then answer options' : 'Bullet points',
            items: lines(row['bullets']),
            onChanged: (l) => setState(() => row['bullets'] = l),
          ),
          if (row['layout'] == 'image') mapField(row, 'imageIdea', 'Picture idea', version: v, onChanged: touch),
          if (row['layout'] == 'summary') mapField(row, 'homework', 'Homework', version: v, onChanged: touch),
          mapField(row, 'notes', "Teacher's notes", version: v, onChanged: touch, maxLines: 3),
        ],
      PlannerKind.exercises => [
          Row(children: [
            SizedBox(width: 80, child: mapField(row, 'number', 'No.', version: v, onChanged: touch)),
            const SizedBox(width: 10),
            SizedBox(width: 90, child: mapField(row, 'marks', 'Marks', version: v, onChanged: touch)),
          ]),
          mapField(row, 'question', 'Question', version: v, onChanged: touch, maxLines: 4),
          LineListEditor(keyPrefix: '$v-o', label: 'Options (leave empty for an open question)', items: lines(row['options']), onChanged: (l) => setState(() => row['options'] = l)),
          mapField(row, 'answer', 'Answer / marking key', version: v, onChanged: touch, maxLines: 3),
        ],
      PlannerKind.scheme => [
          FieldGrid(children: [
            mapField(row, 'week', 'Week', version: v, onChanged: touch),
            mapField(row, 'lessonNo', 'Lessons', version: v, onChanged: touch),
            mapField(row, 'unitTitle', 'Unit', version: v, onChanged: touch),
            mapField(row, 'lessonTitle', 'Lesson title', version: v, onChanged: touch),
          ]),
          mapField(row, 'objectives', 'Objectives', version: v, onChanged: touch, maxLines: 3),
          mapField(row, 'activities', 'Activities', version: v, onChanged: touch, maxLines: 3),
          mapField(row, 'materials', 'Materials', version: v, onChanged: touch, maxLines: 2),
          mapField(row, 'assessment', 'Assessment', version: v, onChanged: touch, maxLines: 2),
        ],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, ...body]),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _cfg.color, foregroundColor: Colors.white),
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 18),
              label: Text(_resId == null ? 'Save' : 'Save changes'),
            ),
          ),
          for (final f in _cfg.formats) ...[
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _downloading != null ? null : () => _download(f), child: Text(_downloading == f ? '…' : _fmtLabel(f))),
          ],
        ]),
      ),
    );
  }
}
