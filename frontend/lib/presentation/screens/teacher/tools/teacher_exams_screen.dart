import 'package:flutter/material.dart';

import '../../../../services/api/teacher_tools_service.dart';
import '../../../widgets/eexams_section.dart';
import 'tools_common.dart';

const _examBlue = Color(0xFF0D406C);

/// Create exams from ECH (AI description or document upload). They are saved on
/// eexams as drafts and reviewed, published and marked there.
class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});
  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  final _svc = TeacherToolsService();

  bool _loading = true;
  TeacherToolsStatus? _status;
  List<EexamsExamSummary> _exams = [];
  List<ExamLevel> _levels = [];

  int _mode = 0; // 0 describe, 1 upload
  final _prompt = TextEditingController();
  final _title = TextEditingController();
  final _timeLimit = TextEditingController(text: '60');
  String? _levelId;
  String? _subLevel;
  PickedUpload? _examFile;
  PickedUpload? _answerFile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _title.dispose();
    _timeLimit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _status = await _svc.status();
      if (_status!.linked) {
        final r = await Future.wait([_svc.listExams(), _svc.levels().catchError((_) => <ExamLevel>[])]);
        _exams = r[0] as List<EexamsExamSummary>;
        _levels = r[1] as List<ExamLevel>;
      }
    } catch (e) {
      if (mounted) showToolError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ExamLevel? get _level => _levels.where((l) => l.id == _levelId).firstOrNull;

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      Map<String, dynamic> result;
      if (_mode == 0) {
        if (_prompt.text.trim().length < 10) {
          showToolMessage(context, 'Describe the exam: subject, class, topics and how many questions of each type.');
          return;
        }
        result = await _svc.createExamWithAi(prompt: _prompt.text.trim(), level: _levelId, subLevel: _subLevel);
      } else {
        final minutes = int.tryParse(_timeLimit.text.trim());
        if (_examFile == null || _title.text.trim().isEmpty || minutes == null || minutes <= 0) {
          showToolMessage(context, 'Choose the exam document and give it a title and time limit.');
          return;
        }
        result = await _svc.uploadExam(examFile: _examFile!, answerFile: _answerFile, title: _title.text.trim(), timeLimit: minutes, level: _levelId, subLevel: _subLevel);
      }
      if (!mounted) return;
      await _showCreated(result);
      setState(() {
        _prompt.clear();
        _title.clear();
        _examFile = null;
        _answerFile = null;
      });
      _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object e) {
    final upgrade = e is TeacherToolsException && (e.upgradeRequired || e.status == 403);
    if (!upgrade) return showToolError(context, e);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your eexams plan'),
        content: Text('$e\n\nExams are an eexams service — you can upgrade your plan on eexams.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
          ElevatedButton(onPressed: () { Navigator.pop(c); openEexams(context, redirect: '/pricing'); }, child: const Text('See eexams plans')),
        ],
      ),
    );
  }

  Future<void> _showCreated(Map<String, dynamic> r) {
    final title = (r['title'] ?? 'Your exam').toString();
    final count = r['questionCount'] ?? (r['questions'] is List ? (r['questions'] as List).length : null);
    final parsingFailed = r['parsingFailed'] == true;
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: kToolsGreen, size: 40),
        title: const Text('Exam saved on eexams'),
        content: Text([
          '"$title" was saved as a draft${count != null ? ' with $count questions' : ''}.',
          if (parsingFailed) 'The document could not be read completely — add or fix the questions on eexams.',
          'Review it, then publish and assign it to your students on eexams.',
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Later')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _examBlue, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(c); openEexams(context, redirect: '/teacher'); },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Review on eexams'),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(bool answer) async {
    try {
      final f = await pickDocument(extensions: const ['pdf', 'doc', 'docx', 'txt']);
      if (f == null) return;
      setState(() => answer ? _answerFile = f : _examFile = f);
      if (!answer && _title.text.trim().isEmpty) _title.text = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    } catch (e) {
      if (mounted) showToolError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        backgroundColor: _examBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => openEexams(context, redirect: '/teacher'),
            icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
            label: const Text('eexams dashboard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_status?.linkRequired == true) LinkRequiredCard(message: _status?.message, onRetry: _load),
                if (_status?.linked == true) ...[
                  _buildCreateCard(),
                  const SizedBox(height: 16),
                  _buildList(),
                ],
              ]),
            ),
    );
  }

  Widget _buildCreateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Create an exam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Saved on eexams as a draft — you review, publish and mark it there.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.auto_awesome), label: Text('Describe with AI')),
              ButtonSegment(value: 1, icon: Icon(Icons.upload_file), label: Text('Upload document')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 14),
          if (_mode == 0)
            TextField(
              controller: _prompt,
              minLines: 4,
              maxLines: 8,
              maxLength: 4000,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. S2 Biology, unit 3 "Photosynthesis": 10 multiple-choice, 5 short-answer and 2 essay questions, 60 minutes.',
              ),
            )
          else ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              _fileButton('Exam document', _examFile, () => _pick(false), () => setState(() => _examFile = null)),
              _fileButton('Answer sheet (optional)', _answerFile, () => _pick(true), () => setState(() => _answerFile = null)),
            ]),
            const SizedBox(height: 12),
            FieldGrid(children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Exam title', isDense: true, border: OutlineInputBorder())),
              TextField(controller: _timeLimit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Time limit (minutes)', isDense: true, border: OutlineInputBorder())),
            ]),
            const SizedBox(height: 10),
          ],
          if (_levels.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              value: _levelId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Level (optional)', isDense: true, border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                for (final l in _levels) DropdownMenuItem<String?>(value: l.id, child: Text(l.name)),
              ],
              onChanged: (v) => setState(() { _levelId = v; _subLevel = null; }),
            ),
            if ((_level?.subLevels ?? const []).isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: _subLevel,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sub-level (optional)', isDense: true, border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  for (final s in _level!.subLevels) DropdownMenuItem<String?>(value: s, child: Text(s)),
                ],
                onChanged: (v) => setState(() => _subLevel = v),
              ),
            ],
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _examBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _busy ? null : _create,
              icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_mode == 0 ? Icons.auto_awesome : Icons.cloud_upload),
              label: Text(_busy ? (_mode == 0 ? 'Writing the exam… (1–2 minutes)' : 'Uploading and reading…') : (_mode == 0 ? 'Create exam with AI' : 'Upload exam')),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fileButton(String label, PickedUpload? file, VoidCallback onPick, VoidCallback onClear) {
    if (file != null) return InputChip(avatar: const Icon(Icons.description, size: 18), label: Text(file.name, overflow: TextOverflow.ellipsis), onDeleted: onClear);
    return OutlinedButton.icon(onPressed: onPick, icon: const Icon(Icons.attach_file, size: 18), label: Text(label));
  }

  Widget _buildList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('My exams on eexams', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            TextButton(onPressed: () => openEexams(context, redirect: '/teacher'), child: const Text('Manage')),
          ]),
          if (_exams.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('No exams yet — create one above.', style: TextStyle(color: Colors.grey[600])))
          else
            for (final e in _exams.take(30))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.assignment, color: _examBlue),
                title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if (e.timeLimit != null) '${e.timeLimit} min',
                  if (e.createdAt != null) '${e.createdAt!.day}/${e.createdAt!.month}/${e.createdAt!.year}',
                ].join(' · ')),
                trailing: _statusChip(e.status),
                onTap: () => openEexams(context, redirect: '/teacher'),
              ),
        ]),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) { 'published' || 'active' => kToolsGreen, 'scheduled' => Colors.blue, 'completed' => Colors.grey, _ => Colors.orange };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
