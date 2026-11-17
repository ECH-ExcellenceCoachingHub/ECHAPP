import 'package:flutter/material.dart';

import '../../../../services/api/teacher_tools_service.dart';
import 'tools_common.dart';

/// Lesson Planner (REB/CBC lesson plan form) — ECH tool, engine on eexams.
class LessonPlannerScreen extends StatefulWidget {
  const LessonPlannerScreen({super.key});
  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen> {
  final _svc = TeacherToolsService();

  bool _loading = true;
  TeacherToolsStatus? _status;
  PlannerQuota? _quota;
  List<Map<String, dynamic>> _saved = [];

  final _brief = TextEditingController();
  final Map<String, dynamic> _details = {
    'subject': '', 'className': '', 'term': '', 'date': DateTime.now().toIso8601String().substring(0, 10),
    'duration': '40 min', 'classSize': '', 'unitNo': '', 'lessonNo': '', 'specialNeeds': '', 'language': 'auto',
  };

  String? _refName;
  String _refText = '';
  bool _reading = false;

  Map<String, dynamic>? _plan;
  String? _planId;
  int _version = 0;
  bool _generating = false, _saving = false;
  String? _downloading;

  static const _languages = ['auto', 'English', 'French', 'Kinyarwanda', 'Kiswahili'];

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
      final status = await _svc.status();
      _status = status;
      if (status.linked) {
        final results = await Future.wait([_svc.quotas(), _svc.listLessonPlans()]);
        final quotas = results[0] as List<PlannerQuota>;
        _quota = quotas.where((q) => q.key == 'lessonPlansPerMonth').firstOrNull;
        _saved = results[1] as List<Map<String, dynamic>>;
      }
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshQuotaAndSaved() async {
    try {
      final quotas = await _svc.quotas();
      final saved = await _svc.listLessonPlans();
      if (!mounted) return;
      setState(() {
        _quota = quotas.where((q) => q.key == 'lessonPlansPerMonth').firstOrNull;
        _saved = saved;
      });
    } catch (_) {}
  }

  Future<void> _attach() async {
    try {
      final file = await pickDocument();
      if (file == null) return;
      setState(() => _reading = true);
      final text = await _svc.extractText(file);
      setState(() {
        _refName = file.name;
        _refText = text;
      });
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Map<String, dynamic> _emptyPlan() => {
        'schoolName': '', 'teacherName': '', 'term': '', 'date': _details['date'], 'subject': '', 'className': '',
        'unitNo': '', 'lessonNo': '', 'duration': '40 min', 'classSize': '', 'specialNeeds': 'None', 'unitTitle': '',
        'keyUnitCompetence': '', 'lessonTitle': '', 'instructionalObjectives': '', 'location': 'Classroom',
        'learningMaterials': '', 'references': '', 'lessonOverview': '', 'steps': <dynamic>[], 'selfEvaluation': '',
        'language': '', 'sourcePrompt': '', 'sourceFileName': '',
      };

  Future<void> _generate() async {
    if (_brief.text.trim().isEmpty && _refText.isEmpty) {
      showToolMessage(context, 'Tell us what to prepare, or attach the book first.');
      return;
    }
    setState(() => _generating = true);
    try {
      final res = await _svc.generateLessonPlan({
        'brief': _brief.text.trim(),
        'referenceContent': _refText,
        'sourceFileName': _refName ?? '',
        ..._details,
      });
      setState(() {
        _plan = {..._emptyPlan(), ...res};
        _planId = null;
        _version++;
      });
      if (mounted) showToolMessage(context, 'Lesson plan ready — review it, then save or download.');
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startBlank() {
    setState(() {
      _plan = {..._emptyPlan(), ..._details, 'language': _details['language'] == 'auto' ? '' : _details['language'], 'sourcePrompt': _brief.text.trim()};
      _planId = null;
      _version++;
    });
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _saving = true);
    try {
      final payload = {...plan, 'sourcePrompt': plan['sourcePrompt'] ?? _brief.text.trim(), 'sourceFileName': _refName ?? plan['sourceFileName'] ?? ''}
        ..remove('_id')
        ..remove('createdBy')
        ..remove('createdAt')
        ..remove('updatedAt');
      final res = await _svc.saveLessonPlan(payload, id: _planId);
      setState(() => _planId = res['_id']?.toString());
      if (mounted) showToolMessage(context, 'Lesson plan saved.');
      _refreshQuotaAndSaved();
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _download(String format, {Map<String, dynamic>? plan, String? id}) async {
    final target = plan ?? _plan;
    if (target == null) return;
    setState(() => _downloading = format);
    try {
      final bytes = await _svc.exportLessonPlan(format, id: id ?? _planId, plan: target);
      final name = [target['subject'], target['className'], target['lessonTitle']].where((s) => (s ?? '').toString().isNotEmpty).join(' - ');
      await saveAndOpenDocument(bytes, '${name.isEmpty ? 'lesson-plan' : name}.$format');
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete lesson plan?'),
        content: Text((item['lessonTitle'] ?? 'This plan').toString()),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteLessonPlan(item['_id'].toString());
      if (_planId == item['_id']) setState(() { _plan = null; _planId = null; });
      _refreshQuotaAndSaved();
    } catch (e) {
      if (mounted) showToolError(context, e);
    }
  }

  void _openSaved(Map<String, dynamic> item) {
    setState(() {
      _plan = {..._emptyPlan(), ...item};
      _planId = item['_id']?.toString();
      _brief.text = (item['sourcePrompt'] ?? '').toString();
      _version++;
    });
  }

  void _showSaved() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('My lesson plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          Expanded(
            child: _saved.isEmpty
                ? const Center(child: Text('No saved lesson plans yet.'))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: _saved.length,
                    itemBuilder: (_, i) {
                      final p = _saved[i];
                      return ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text((p['lessonTitle'] ?? p['unitTitle'] ?? 'Lesson plan').toString()),
                        subtitle: Text([p['subject'], p['className'], p['date']].where((s) => (s ?? '').toString().isNotEmpty).join(' · ')),
                        onTap: () {
                          Navigator.pop(c);
                          _openSaved(p);
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            Navigator.pop(c);
                            if (v == 'delete') {
                              _delete(p);
                            } else {
                              _download(v, plan: p, id: p['_id'].toString());
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'docx', child: Text('Download Word')),
                            PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
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
        title: const Text('Lesson Planner'),
        backgroundColor: kToolsGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_status?.linked == true)
            TextButton.icon(
              onPressed: _showSaved,
              icon: const Icon(Icons.folder_open, color: Colors.white),
              label: Text('Saved (${_saved.length})', style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_status?.linkRequired == true) LinkRequiredCard(message: _status?.message, onRetry: _load),
                  if (_status?.linked == true) ...[
                    QuotaBanner(quota: _quota, noun: 'lesson plans'),
                    _buildBriefCard(),
                    if (_plan != null) _buildEditor(),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _plan == null ? null : _buildActions(),
    );
  }

  Widget _buildBriefCard() {
    final exhausted = _quota != null && !_quota!.allowed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What lesson are you preparing?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            controller: _brief,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'e.g. Introduce fractions to P4 learners, first lesson of the unit',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ReferenceAttach(
            fileName: _refName,
            busy: _reading,
            onAttach: _attach,
            onClear: () => setState(() { _refName = null; _refText = ''; }),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Lesson details (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            children: [
              FieldGrid(children: [
                mapField(_details, 'subject', 'Subject', version: 'd', onChanged: () {}),
                mapField(_details, 'className', 'Class', version: 'd', onChanged: () {}),
                mapField(_details, 'term', 'Term', version: 'd', onChanged: () {}),
                mapField(_details, 'date', 'Date (YYYY-MM-DD)', version: 'd', onChanged: () {}),
                mapField(_details, 'duration', 'Duration', version: 'd', onChanged: () {}),
                mapField(_details, 'classSize', 'Class size', version: 'd', onChanged: () {}, keyboard: TextInputType.number),
                mapField(_details, 'unitNo', 'Unit No', version: 'd', onChanged: () {}),
                mapField(_details, 'lessonNo', 'Lesson No', version: 'd', onChanged: () {}),
              ]),
              mapField(_details, 'specialNeeds', 'Special educational needs (and number of learners)', version: 'd', onChanged: () {}),
              DropdownButtonFormField<String>(
                value: _details['language'] as String,
                decoration: const InputDecoration(labelText: 'Language', isDense: true, border: OutlineInputBorder()),
                items: [for (final l in _languages) DropdownMenuItem(value: l, child: Text(l == 'auto' ? 'Match the subject / book' : l))],
                onChanged: (v) => setState(() => _details['language'] = v ?? 'auto'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kToolsGreen, foregroundColor: Colors.white),
              onPressed: _generating || exhausted ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_generating ? 'Writing the plan… (up to a minute)' : 'Generate with AI'),
            ),
            OutlinedButton.icon(onPressed: exhausted ? null : _startBlank, icon: const Icon(Icons.edit_note, size: 18), label: const Text('Start blank')),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEditor() {
    final plan = _plan!;
    final v = 'p$_version';
    void touch() {}
    final steps = (plan['steps'] as List? ?? []).map((s) => Map<String, dynamic>.from(s as Map)).toList();
    plan['steps'] = steps;

    List<String> lines(dynamic x) => (x as List? ?? []).map((e) => e.toString()).toList();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Lesson plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            if (_planId != null) const Chip(label: Text('Saved'), avatar: Icon(Icons.check_circle, size: 16, color: kToolsGreen)),
          ]),
          const SizedBox(height: 10),
          FieldGrid(children: [
            mapField(plan, 'schoolName', 'School name', version: v, onChanged: touch),
            mapField(plan, 'teacherName', "Teacher's name", version: v, onChanged: touch),
            mapField(plan, 'term', 'Term', version: v, onChanged: touch),
            mapField(plan, 'date', 'Date', version: v, onChanged: touch),
            mapField(plan, 'subject', 'Subject', version: v, onChanged: touch),
            mapField(plan, 'className', 'Class', version: v, onChanged: touch),
            mapField(plan, 'unitNo', 'Unit No', version: v, onChanged: touch),
            mapField(plan, 'lessonNo', 'Lesson No', version: v, onChanged: touch),
            mapField(plan, 'duration', 'Duration', version: v, onChanged: touch),
            mapField(plan, 'classSize', 'Class size', version: v, onChanged: touch),
          ]),
          mapField(plan, 'specialNeeds', 'Special educational needs catered for', version: v, onChanged: touch, maxLines: 3),
          mapField(plan, 'unitTitle', 'Unit title', version: v, onChanged: touch),
          mapField(plan, 'keyUnitCompetence', 'Key unit competence', version: v, onChanged: touch, maxLines: 4),
          mapField(plan, 'lessonTitle', 'Title of the lesson', version: v, onChanged: touch),
          mapField(plan, 'instructionalObjectives', 'Instructional objectives', version: v, onChanged: touch, maxLines: 5),
          mapField(plan, 'location', 'Plan of this class (location)', version: v, onChanged: touch),
          mapField(plan, 'learningMaterials', 'Learning materials', version: v, onChanged: touch, maxLines: 4),
          mapField(plan, 'references', 'References', version: v, onChanged: touch, maxLines: 4),
          mapField(plan, 'lessonOverview', 'Lesson overview', version: v, onChanged: touch, maxLines: 5),
          const Divider(height: 28),
          const Text('Teaching and learning activities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: mapField(steps[i], 'name', 'Step', version: '$v-s$i-${steps.length}', onChanged: touch)),
                  const SizedBox(width: 8),
                  SizedBox(width: 110, child: mapField(steps[i], 'duration', 'Timing', version: '$v-s$i-${steps.length}', onChanged: touch)),
                  IconButton(
                    tooltip: 'Remove step',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => setState(() { steps.removeAt(i); _version++; }),
                  ),
                ]),
                LineListEditor(
                  keyPrefix: '$v-s$i-t',
                  label: "Teacher's activity",
                  items: lines(steps[i]['teacherActivities']),
                  hint: 'Greets learners.',
                  onChanged: (l) => setState(() => steps[i]['teacherActivities'] = l),
                ),
                LineListEditor(
                  keyPrefix: '$v-s$i-l',
                  label: "Learner's activity",
                  items: lines(steps[i]['learnerActivities']),
                  hint: 'Respond to greetings.',
                  onChanged: (l) => setState(() => steps[i]['learnerActivities'] = l),
                ),
                LineListEditor(
                  keyPrefix: '$v-s$i-c',
                  label: 'Competences & cross-cutting issues',
                  items: lines(steps[i]['competences']),
                  hint: 'Communication: …',
                  onChanged: (l) => setState(() => steps[i]['competences'] = l),
                ),
              ]),
            ),
          TextButton.icon(
            onPressed: () => setState(() {
              steps.add({'name': '', 'duration': '', 'teacherActivities': <String>[], 'learnerActivities': <String>[], 'competences': <String>[]});
              _version++;
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add a step'),
          ),
          const Divider(height: 28),
          mapField(plan, 'selfEvaluation', "Teacher's self-evaluation (leave blank to fill in by hand)", version: v, onChanged: touch, maxLines: 4),
        ]),
      ),
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
              style: ElevatedButton.styleFrom(backgroundColor: kToolsGreen, foregroundColor: Colors.white),
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 18),
              label: Text(_planId == null ? 'Save' : 'Save changes'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _downloading != null ? null : () => _download('docx'), child: Text(_downloading == 'docx' ? '…' : 'Word')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _downloading != null ? null : () => _download('pdf'), child: Text(_downloading == 'pdf' ? '…' : 'PDF')),
        ]),
      ),
    );
  }
}
