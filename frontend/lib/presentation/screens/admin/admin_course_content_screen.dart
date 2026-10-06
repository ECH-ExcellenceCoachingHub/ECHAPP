import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/section.dart';
import '../../../models/lesson.dart';
import '../../../models/question.dart';
import '../../../services/api/quiz_service.dart';
import '../../../services/api/section_service.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class AdminCourseContentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const AdminCourseContentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AdminCourseContentScreen> createState() =>
      _AdminCourseContentScreenState();
}

class _AdminCourseContentScreenState
    extends State<AdminCourseContentScreen> {
  List<Section> _sections = [];
  List<Map<String, dynamic>> _quizzes = [];
  Map<String, List<Lesson>> _lessonsBySection = {};
  bool _isLoading = true;
  bool _isReordering = false;

  final SectionService _sectionService = SectionService();

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadCourseContent() async {
    setState(() => _isLoading = true);
    try {
      final sections = await _sectionService.getSectionsByCourse(widget.courseId);
      
      // Load quizzes from all sections in the course
      final quizzesFuture = sections.map((section) async {
        try {
          return await QuizService.getSectionExamsAdmin(section.id);
        } catch (e) {
          print('Error loading quizzes for section ${section.id}: $e');
          return <Map<String, dynamic>>[];
        }
      });
      
      final quizzesLists = await Future.wait(quizzesFuture);
      final allQuizzes = quizzesLists.expand((quizzes) => quizzes).toList();
      
      // Load lessons for each section
      final lessonsFuture = sections.map((section) async {
        final lessons = await _sectionService.getLessonsBySection(section.id);
        return MapEntry(section.id, lessons);
      });
      
      final lessonsEntries = await Future.wait(lessonsFuture);
      final lessonsMap = Map.fromEntries(lessonsEntries);

      if (!mounted) return;
      setState(() {
        _sections = sections;
        _quizzes = allQuizzes;
        _lessonsBySection = lessonsMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading content: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    const labels = {
      'mcq': 'Multiple Choice',
      'true_false': 'True / False',
      'essay': 'Essay',
      'fill_blank': 'Fill in Blank',
    };
    return labels[type] ?? type;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/admin/courses/${widget.courseId}/ai-builder').then((_) => _loadCourseContent()),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Build with AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: Icon(_isReordering ? Icons.check_circle : Icons.reorder),
            tooltip: _isReordering ? 'Done reordering' : 'Reorder sections',
            onPressed: () => setState(() => _isReordering = !_isReordering),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadCourseContent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _buildFABs(),
    );
  }

  Widget _buildFABs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab_section',
          onPressed: _showAddSectionDialog,
          backgroundColor: AppTheme.primaryGreen,
          icon: const Icon(Icons.folder_open),
          label: const Text('Section'),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'fab_quiz',
          onPressed: _showAddQuizDialog,
          backgroundColor: AppTheme.accent,
          icon: const Icon(Icons.quiz),
          label: const Text('Quiz'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_sections.isEmpty && _quizzes.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadCourseContent,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          ..._sections.asMap().entries.map(
                (e) => _buildSectionCard(e.value, e.key),
              ),
          const SizedBox(height: 8),
          _buildQuizzesSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 96, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No content yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a section to get started',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/admin/courses/${widget.courseId}/ai-builder').then((_) => _loadCourseContent()),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Build from a book with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showAddSectionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Card ─────────────────────────────────────────────────────────

  Widget _buildSectionCard(Section section, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (_isReordering)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                Expanded(
                  child: Text(
                    'Section ${index + 1}: ${section.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleSectionAction(action, section),
                  itemBuilder: (_) => [
                    _menuItem('edit', Icons.edit, 'Edit Section'),
                    _menuItem('add_lesson', Icons.add, 'Add Lesson'),
                    _menuItem('delete', Icons.delete, 'Delete Section',
                        isDestructive: true),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.description != null && section.description!.isNotEmpty) ...[
                  Text(
                    section.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                ],
                (_lessonsBySection[section.id] ?? []).isEmpty
                    ? _buildEmptyLessonsPlaceholder()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lessons',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_lessonsBySection[section.id] ?? []).map(
                            (l) => _buildLessonTile(l, section),
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddLessonDialog(context, section),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Lesson'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLessonsPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.book_outlined, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Text(
            'No lessons in this section yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, Section section) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.accent.withOpacity(0.12),
        child:
            const Icon(Icons.play_lesson, color: AppTheme.accent, size: 18),
      ),
      title: Text(
        lesson.title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: (lesson.description?.isNotEmpty ?? false)
          ? Text(
              lesson.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleLessonAction(action, lesson),
        itemBuilder: (_) => [
          _menuItem('edit', Icons.edit, 'Edit'),
          _menuItem('preview', Icons.visibility_outlined, 'Preview'),
          _menuItem('delete', Icons.delete, 'Delete', isDestructive: true),
        ],
      ),
      onTap: () => _handleLessonAction('edit', lesson),
    );
  }

  // ─── Quizzes Section ──────────────────────────────────────────────────────

  Widget _buildQuizzesSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quizzes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddQuizDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_quizzes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No quizzes created yet',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a quiz to test student knowledge',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ..._quizzes.map(_buildQuizTile),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTile(Map<String, dynamic> quiz) {
    final questionCount =
        (quiz['questions'] as List<dynamic>?)?.length ?? 0;
    final timeLimit = quiz['timeLimit'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey[50],
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withOpacity(0.12),
          child: const Icon(Icons.quiz, color: AppTheme.accent),
        ),
        title: Text(
          quiz['title'] as String? ?? 'Untitled Quiz',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          [
            '$questionCount question${questionCount == 1 ? '' : 's'}',
            if (timeLimit != null) '$timeLimit min',
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleQuizAction(action, quiz),
          itemBuilder: (_) => [
            _menuItem('edit', Icons.edit, 'Edit'),
            _menuItem(
                'questions', Icons.help_outline, 'Manage Questions'),
            _menuItem('delete', Icons.delete, 'Delete',
                isDestructive: true),
          ],
        ),
        onTap: () => _handleQuizAction('questions', quiz),
      ),
    );
  }

  // ─── Action Handlers ──────────────────────────────────────────────────────

  void _handleSectionAction(String action, Section section) {
    switch (action) {
      case 'edit':
        _showEditSectionDialog(section);
        break;
      case 'add_lesson':
        _showAddLessonDialog(context, section);
        break;
      case 'delete':
        _showDeleteConfirmation(
          type: 'Section',
          title: section.title,
          onConfirm: () => _sectionService.deleteSection(section.id),
        );
        break;
    }
  }

  void _handleLessonAction(String action, Lesson lesson) {
    switch (action) {
      case 'edit':
        context.push('/admin/courses/${widget.courseId}/sections/${lesson.sectionId}/lessons/${lesson.id}/edit');
        break;
      case 'preview':
        context.push('/lesson/${lesson.id}?admin=true');
        break;
      case 'delete':
        _showDeleteConfirmation(
          type: 'Lesson',
          title: lesson.title,
          onConfirm: () => _sectionService.deleteLesson(lesson.id),
        );
        break;
    }
  }

  void _handleQuizAction(String action, Map<String, dynamic> quiz) {
    switch (action) {
      case 'edit':
        _showEditQuizDialog(quiz);
        break;
      case 'questions':
        _showQuizQuestionsDialog(quiz);
        break;
      case 'delete':
        _showDeleteConfirmation(
          type: 'Quiz',
          title: quiz['title'] as String? ?? '',
          onConfirm: () => QuizService.deleteQuiz(quiz['id'] as String),
        );
        break;
    }
  }

  // ─── Dialogs: Sections ────────────────────────────────────────────────────

  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    _showFormDialog(
      title: 'Add Section',
      content: _sectionFormFields(titleCtrl, descCtrl),
      onSave: () async {
        _validateNotEmpty(titleCtrl.text, 'Section title');
        await _sectionService.createSection(
          courseId: widget.courseId,
          title: titleCtrl.text.trim(),
          order: _sections.length + 1,
        );
        _showSuccessSnackBar('Section created successfully');
        _loadCourseContent();
      },
    );
  }

  void _showEditSectionDialog(Section section) {
    final titleCtrl = TextEditingController(text: section.title);
    final descCtrl = TextEditingController(text: section.description);

    _showFormDialog(
      title: 'Edit Section',
      content: _sectionFormFields(titleCtrl, descCtrl),
      saveLabel: 'Update',
      onSave: () async {
        _validateNotEmpty(titleCtrl.text, 'Section title');
        await _sectionService.updateSection(
          sectionId: section.id,
          title: titleCtrl.text.trim(),
        );
        _showSuccessSnackBar('Section updated successfully');
        _loadCourseContent();
      },
    );
  }

  Widget _sectionFormFields(
    TextEditingController titleCtrl,
    TextEditingController descCtrl,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _textField(controller: titleCtrl, label: 'Section Title'),
        const SizedBox(height: 16),
        _textField(
            controller: descCtrl,
            label: 'Description (Optional)',
            maxLines: 3),
      ],
    );
  }

  // ─── Dialogs: Lessons ─────────────────────────────────────────────────────

  void _showAddLessonDialog(BuildContext context, Section section) {
    if (widget.courseId.isEmpty || section.id.isEmpty) {
      _showErrorSnackBar('Invalid course or section ID');
      return;
    }
    context.push('/admin/courses/${widget.courseId}/sections/${section.id}/lessons/create')
        .then((_) => _loadCourseContent());
  }

  void _showEditLessonDialog(Map<String, dynamic> lesson) {
    final titleCtrl =
        TextEditingController(text: lesson['title'] as String? ?? '');
    final descCtrl = TextEditingController(
        text: lesson['description'] as String? ?? '');
    final notesCtrl =
        TextEditingController(text: lesson['notes'] as String? ?? '');

    _showFormDialog(
      title: 'Edit Lesson',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _textField(controller: titleCtrl, label: 'Lesson Title'),
          const SizedBox(height: 16),
          _textField(
              controller: descCtrl, label: 'Description', maxLines: 3),
          const SizedBox(height: 16),
          _textField(controller: notesCtrl, label: 'Notes', maxLines: 4),
        ],
      ),
      saveLabel: 'Update',
      onSave: () async {
        _validateNotEmpty(titleCtrl.text, 'Lesson title');
        await _sectionService.updateLesson(
          lessonId: lesson['id'] as String,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          notes: notesCtrl.text.trim(),
        );
        _showSuccessSnackBar('Lesson updated successfully');
        _loadCourseContent();
      },
    );
  }

  // ─── Dialogs: Quizzes ─────────────────────────────────────────────────────

  void _showAddQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int timeLimit = 30;
    bool isShuffled = false;

    _showFormDialog(
      title: 'Create Quiz',
      content: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _textField(controller: titleCtrl, label: 'Quiz Title'),
            const SizedBox(height: 16),
            _textField(
                controller: descCtrl,
                label: 'Description (Optional)',
                maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: timeLimit.toString(),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Time Limit (minutes)'),
              onChanged: (v) => timeLimit = int.tryParse(v) ?? 30,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shuffle Questions'),
              value: isShuffled,
              activeThumbColor: AppTheme.primaryGreen,
              onChanged: (v) => setLocal(() => isShuffled = v),
            ),
          ],
        ),
      ),
      onSave: () async {
        _validateNotEmpty(titleCtrl.text, 'Quiz title');
        await QuizService.createQuiz(
          sectionId: '',
          courseId: widget.courseId,
          title: titleCtrl.text.trim(),
          type: 'quiz',
          timeLimit: timeLimit,
        );
        _showSuccessSnackBar('Quiz created successfully');
        _loadCourseContent();
      },
    );
  }

  void _showEditQuizDialog(Map<String, dynamic> quiz) {
    final titleCtrl =
        TextEditingController(text: quiz['title'] as String? ?? '');
    final descCtrl = TextEditingController(
        text: quiz['description'] as String? ?? '');
    int timeLimit = quiz['timeLimit'] as int? ?? 30;
    bool isShuffled = quiz['isShuffled'] as bool? ?? false;

    _showFormDialog(
      title: 'Edit Quiz',
      content: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _textField(controller: titleCtrl, label: 'Quiz Title'),
            const SizedBox(height: 16),
            _textField(
                controller: descCtrl,
                label: 'Description (Optional)',
                maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: timeLimit.toString(),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Time Limit (minutes)'),
              onChanged: (v) => timeLimit = int.tryParse(v) ?? 30,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shuffle Questions'),
              value: isShuffled,
              activeThumbColor: AppTheme.primaryGreen,
              onChanged: (v) => setLocal(() => isShuffled = v),
            ),
          ],
        ),
      ),
      saveLabel: 'Update',
      onSave: () async {
        _validateNotEmpty(titleCtrl.text, 'Quiz title');
        // TODO: wire up QuizService.updateQuiz when available
        _showSuccessSnackBar('Quiz updated successfully');
        _loadCourseContent();
      },
    );
  }

  // ─── Dialogs: Quiz Questions ──────────────────────────────────────────────

  void _showQuizQuestionsDialog(Map<String, dynamic> quiz) async {
    List<Question> questions = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          // Load once
          if (isLoading) {
            _loadQuizQuestions(quiz['id'] as String).then((loaded) {
              setLocal(() {
                questions = loaded;
                isLoading = false;
              });
            });
          }

          return AlertDialog(
            title: Text('Questions — ${quiz['title']}'),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.85,
              height: MediaQuery.of(ctx).size.height * 0.65,
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : questions.isEmpty
                            ? _buildEmptyQuestionsState()
                            : ListView.separated(
                                itemCount: questions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (_, index) =>
                                    _buildQuestionItem(
                                  questions[index].toJson(),
                                  index,
                                  onDelete: () => setLocal(() {
                                    questions.removeAt(index);
                                  }),
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _showAddQuestionDialog(
                          quiz['id'] as String,
                          onAdded: () => _showQuizQuestionsDialog(quiz),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: TextStyle(
                fontSize: 17,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Question" to get started',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<List<Question>> _loadQuizQuestions(String examId) async {
    try {
      final response = await QuizService.getQuiz(examId);
      if (response['success'] == true && response['data'] != null) {
        final raw = response['data']['questions'] as List<dynamic>? ?? [];
        return raw.map((q) => Question.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      _showErrorSnackBar('Failed to load questions: $e');
      return [];
    }
  }

  Widget _buildQuestionItem(
    Map<String, dynamic> question,
    int index, {
    required VoidCallback onDelete,
  }) {
    final options = question['options'] as List<dynamic>?;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeChip(question['type'] as String? ?? 'mcq'),
                    const SizedBox(width: 8),
                    _buildPointsChip(question['points'] as int? ?? 1),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  question['question'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (options != null && options.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...options.map<Widget>((opt) {
                    final isCorrect = opt['isCorrect'] as bool? ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: isCorrect
                                ? Colors.green
                                : Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              opt['text'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Delete question',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    const colors = {
      'mcq': Colors.blue,
      'true_false': Colors.green,
      'essay': Colors.purple,
      'fill_blank': Colors.orange,
    };
    const labels = {
      'mcq': 'MCQ',
      'true_false': 'T/F',
      'essay': 'Essay',
      'fill_blank': 'Fill',
    };
    final color = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        labels[type] ?? type,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPointsChip(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$points pt${points == 1 ? '' : 's'}',
        style: const TextStyle(
          color: AppTheme.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Dialogs: Add Question ────────────────────────────────────────────────

  void _showAddQuestionDialog(
    String examId, {
    VoidCallback? onAdded,
  }) {
    final questionCtrl = TextEditingController();
    final essayCtrl = TextEditingController();
    final blankCtrl = TextEditingController();
    final optionsCtrls = List.generate(4, (_) => TextEditingController());
    String selectedType = 'mcq';
    int points = 1;
    int correctOptionIndex = 0;
    bool trueFalseAnswer = true;

    _showFormDialog(
      title: 'Add Question',
      scrollable: true,
      content: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: _inputDecoration('Question Type'),
              items: const [
                DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice')),
                DropdownMenuItem(
                    value: 'true_false', child: Text('True / False')),
                DropdownMenuItem(value: 'essay', child: Text('Essay')),
                DropdownMenuItem(
                    value: 'fill_blank', child: Text('Fill in Blank')),
              ],
              onChanged: (v) => setLocal(() => selectedType = v ?? 'mcq'),
            ),
            const SizedBox(height: 16),
            _textField(
                controller: questionCtrl,
                label: 'Question',
                hint: 'Enter the question text',
                maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Points'),
              onChanged: (v) => points = int.tryParse(v) ?? 1,
            ),
            const SizedBox(height: 16),
            if (selectedType == 'mcq') ...[
              const Text('Options',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...optionsCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: e.key,
                          groupValue: correctOptionIndex,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (v) =>
                              setLocal(() => correctOptionIndex = v!),
                        ),
                        Expanded(
                          child: _textField(
                            controller: e.value,
                            label:
                                'Option ${String.fromCharCode(65 + e.key)}',
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else if (selectedType == 'true_false') ...[
              const Text('Correct Answer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('True'),
                      value: true,
                      groupValue: trueFalseAnswer,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (v) =>
                          setLocal(() => trueFalseAnswer = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('False'),
                      value: false,
                      groupValue: trueFalseAnswer,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (v) =>
                          setLocal(() => trueFalseAnswer = v!),
                    ),
                  ),
                ],
              ),
            ] else if (selectedType == 'essay') ...[
              _textField(
                  controller: essayCtrl,
                  label: 'Sample Answer (Optional)',
                  hint: 'Provide a reference answer',
                  maxLines: 4),
            ] else if (selectedType == 'fill_blank') ...[
              _textField(
                  controller: blankCtrl,
                  label: 'Correct Answer',
                  hint: 'Enter the expected answer'),
            ],
          ],
        ),
      ),
      saveLabel: 'Add Question',
      onSave: () async {
        _validateNotEmpty(questionCtrl.text, 'Question text');
        if (selectedType == 'mcq') {
          for (final c in optionsCtrls) {
            if (c.text.trim().isEmpty) {
              throw Exception('All options are required');
            }
          }
        }

        List<Option>? options;
        dynamic correctAnswer;

        if (selectedType == 'mcq') {
          options = optionsCtrls.asMap().entries.map((e) {
            return Option(
              id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
              text: e.value.text.trim(),
              isCorrect: e.key == correctOptionIndex,
            );
          }).toList();
          correctAnswer = correctOptionIndex;
        } else if (selectedType == 'true_false') {
          correctAnswer = trueFalseAnswer;
        } else if (selectedType == 'essay') {
          correctAnswer = essayCtrl.text.trim();
        } else {
          correctAnswer = blankCtrl.text.trim();
        }

        final q = Question(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          examId: examId,
          question: questionCtrl.text.trim(),
          type: selectedType,
          points: points,
          options: options,
          correctAnswer: correctAnswer,
        );

        await QuizService.addQuestion(examId, q);
        _showSuccessSnackBar('Question added successfully');
        onAdded?.call();
      },
    );
  }

  // ─── Generic Delete Confirmation ──────────────────────────────────────────

  void _showDeleteConfirmation({
    required String type,
    required String title,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type'),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await onConfirm();
                _showSuccessSnackBar(
                    '$type "$title" deleted successfully');
                _loadCourseContent();
              } catch (e) {
                _showErrorSnackBar('Failed to delete $type: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Reusable Form Dialog ─────────────────────────────────────────────────

  void _showFormDialog({
    required String title,
    required Widget content,
    String saveLabel = 'Create',
    bool scrollable = false,
    required Future<void> Function() onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        scrollable: scrollable,
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.6,
          child: content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await onSave();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }

  // ─── Small UI Helpers ─────────────────────────────────────────────────────

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : null;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _validateNotEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw Exception('$fieldName is required');
    }
  }
}