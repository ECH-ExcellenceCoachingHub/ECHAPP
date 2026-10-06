import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/models/course_build.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'widgets/build_options_panel.dart';

/// AI Course Builder home for one course: upload a book, pick what to
/// generate, and see previous builds. Used by admins and assigned teachers.
class CourseBuilderScreen extends StatefulWidget {
  final String courseId;
  final bool isTeacher;
  const CourseBuilderScreen({super.key, required this.courseId, this.isTeacher = false});

  @override
  State<CourseBuilderScreen> createState() => _CourseBuilderScreenState();
}

class _CourseBuilderScreenState extends State<CourseBuilderScreen> {
  final _service = CourseBuilderService();
  final _options = BuildOptions();
  List<CourseBuildJob> _jobs = [];
  bool _loading = true;
  String? _error;
  PlatformFile? _file;
  double? _uploadProgress;
  Timer? _poll;

  String get _jobRoute => widget.isTeacher ? '/teacher/ai-builds' : '/admin/ai-builds';

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
      final jobs = await _service.listJobs(widget.courseId);
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
        _error = null;
      });
      _poll?.cancel();
      if (jobs.any((j) => j.isBusy)) _poll = Timer(const Duration(seconds: 4), _load);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'md'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) setState(() => _file = result.files.first);
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    setState(() => _uploadProgress = 0);
    try {
      final job = await _service.uploadBook(
        courseId: widget.courseId,
        file: file,
        options: _options,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _file = null;
        _uploadProgress = null;
      });
      context.push('$_jobRoute/${job.id}').then((_) => _load());
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1000;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('AI Course Builder', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: builderGreen,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16, vertical: 20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _PipelineHero(),
                          const SizedBox(height: 20),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildNewBuildCard()),
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: _buildJobsCard()),
                              ],
                            )
                          else ...[
                            _buildNewBuildCard(),
                            const SizedBox(height: 20),
                            _buildJobsCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNewBuildCard() {
    final uploading = _uploadProgress != null;
    return _Panel(
      title: 'New build from a book',
      icon: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: uploading ? null : _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                color: _file == null ? const Color(0xFFF0FDF9) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: builderGreen.withValues(alpha: 0.5), width: 1.5),
              ),
              child: _file == null
                  ? const Column(children: [
                      Icon(Icons.cloud_upload_outlined, size: 44, color: builderGreen),
                      SizedBox(height: 10),
                      Text('Choose a book to upload', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('PDF (text or scanned), DOCX, DOC, TXT · up to 150 MB',
                          textAlign: TextAlign.center, style: TextStyle(color: builderMuted, fontSize: 12.5)),
                    ])
                  : Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_file!.extension == 'pdf' ? Icons.picture_as_pdf : Icons.description, color: const Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_file!.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${(_file!.size / 1048576).toStringAsFixed(1)} MB', style: const TextStyle(color: builderMuted, fontSize: 12)),
                        ]),
                      ),
                      if (!uploading)
                        IconButton(onPressed: () => setState(() => _file = null), icon: const Icon(Icons.close), tooltip: 'Remove'),
                    ]),
            ),
          ),
          const SizedBox(height: 20),
          BuildOptionsPanel(options: _options, onChanged: () => setState(() {}), showAutoGenerate: true),
          const SizedBox(height: 18),
          if (uploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _uploadProgress, minHeight: 8, color: builderGreen, backgroundColor: builderBorder),
            ),
            const SizedBox(height: 8),
            Text(
              _uploadProgress! < 1 ? 'Uploading… ${(_uploadProgress! * 100).round()}%' : 'Upload complete — starting analysis…',
              style: const TextStyle(color: builderMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _file == null || uploading ? null : _upload,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(_options.autoGenerate ? 'Upload & generate course' : 'Upload & analyse book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: builderGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(children: [
            Icon(Icons.verified_user_outlined, size: 16, color: builderMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Nothing is shown to students until you review and publish it.',
                style: TextStyle(fontSize: 12, color: builderMuted),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildJobsCard() {
    return _Panel(
      title: 'Previous builds',
      icon: Icons.history,
      child: _error != null
          ? Column(children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ])
          : _jobs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(children: [
                    Icon(Icons.library_books_outlined, size: 40, color: builderBorder),
                    SizedBox(height: 8),
                    Text('No builds yet', style: TextStyle(color: builderMuted)),
                  ]),
                )
              : Column(
                  children: _jobs.map((j) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('$_jobRoute/${j.id}').then((_) => _load()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: builderBorder), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(j.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              BuildStatusChip(j.status, dense: true),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              [
                                BuildMode.byId(j.options.mode).label,
                                if (j.pageCount > 0) '${j.pageCount} ${j.pageLabel}s',
                                if (j.statLessons > 0) '${j.statLessons} lessons',
                                if (j.statQuestions > 0) '${j.statQuestions} questions',
                                if (j.createdAt != null) DateFormat('d MMM, HH:mm').format(j.createdAt!),
                              ].join(' · '),
                              style: const TextStyle(fontSize: 12, color: builderMuted),
                            ),
                            if (j.isBusy) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(value: j.progress.percent / 100, minHeight: 5, color: builderGreen, backgroundColor: builderBorder),
                              ),
                              const SizedBox(height: 4),
                              Text(j.progress.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: builderMuted)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Panel({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: builderBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icon, color: builderGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: builderInk)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PipelineHero extends StatelessWidget {
  const _PipelineHero();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.upload_file, 'Upload book'),
      (Icons.document_scanner_outlined, 'Read & OCR'),
      (Icons.account_tree_outlined, 'Detect chapters'),
      (Icons.auto_awesome, 'AI drafts lessons & quizzes'),
      (Icons.fact_check_outlined, 'You review'),
      (Icons.public, 'Publish'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF047857), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Turn a book into a full course',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Chapters become sections, sections become lessons with notes, visuals, key terms, '
            'examples, flashcards and quizzes — every question linked back to the page it came from.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(steps[i].$1, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(steps[i].$2, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (i < steps.length - 1) const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
