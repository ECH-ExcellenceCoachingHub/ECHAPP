// Models for the AI Course Builder (book → course draft → review → publish).

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

class BuildMode {
  final String id;
  final String label;
  final String emoji;
  final String description;
  const BuildMode(this.id, this.label, this.emoji, this.description);

  static const all = [
    BuildMode('full', 'Full book', '📚', 'Lessons, quizzes, chapter tests and a mock exam for every chapter'),
    BuildMode('selected', 'Selected chapters', '📖', 'Same as full book, only for the chapters you pick'),
    BuildMode('lessons_only', 'Lessons only', '📝', 'Notes, key terms, examples and visuals — no questions'),
    BuildMode('quizzes_only', 'Quizzes only', '❓', 'A quiz for every lesson, without lesson notes'),
    BuildMode('exam_prep', 'Exam preparation', '🎯', 'Revision notes, chapter tests and a mock exam'),
    BuildMode('revision', 'Revision notes', '🧠', 'One condensed revision sheet per chapter'),
    BuildMode('mock_exam', 'Mock exam', '📋', 'A single exam drawn from the chapters you pick'),
  ];

  static BuildMode byId(String id) => all.firstWhere((m) => m.id == id, orElse: () => all.first);
}

class BuildOptions {
  String mode;
  int questionsPerLesson;
  int chapterTestQuestions;
  int mockExamQuestions;
  int easy;
  int medium;
  int hard;
  List<String> questionTypes;
  String examStyle;
  bool includeVisuals;
  bool includeFlashcards;
  bool autoGenerate;
  String instructions;
  String language;

  BuildOptions({
    this.mode = 'full',
    this.questionsPerLesson = 5,
    this.chapterTestQuestions = 15,
    this.mockExamQuestions = 0,
    this.easy = 30,
    this.medium = 50,
    this.hard = 20,
    List<String>? questionTypes,
    this.examStyle = '',
    this.includeVisuals = true,
    this.includeFlashcards = true,
    this.autoGenerate = false,
    this.instructions = '',
    this.language = 'English',
  }) : questionTypes = questionTypes ?? ['mcq', 'true_false', 'short_answer', 'calculation', 'scenario'];

  factory BuildOptions.fromJson(Map<String, dynamic>? j) {
    if (j == null) return BuildOptions();
    final mix = (j['difficultyMix'] as Map?)?.cast<String, dynamic>() ?? {};
    return BuildOptions(
      mode: _str(j['mode']).isEmpty ? 'full' : _str(j['mode']),
      questionsPerLesson: _int(j['questionsPerLesson'], 5),
      chapterTestQuestions: _int(j['chapterTestQuestions'], 15),
      mockExamQuestions: _int(j['mockExamQuestions'], 0),
      easy: _int(mix['easy'], 30),
      medium: _int(mix['medium'], 50),
      hard: _int(mix['hard'], 20),
      questionTypes: (j['questionTypes'] as List?)?.map((e) => e.toString()).toList(),
      examStyle: _str(j['examStyle']),
      includeVisuals: j['includeVisuals'] != false,
      includeFlashcards: j['includeFlashcards'] != false,
      autoGenerate: j['autoGenerate'] == true,
      instructions: _str(j['instructions']),
      language: _str(j['language']).isEmpty ? 'English' : _str(j['language']),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'questionsPerLesson': questionsPerLesson,
        'chapterTestQuestions': chapterTestQuestions,
        'mockExamQuestions': mockExamQuestions,
        'difficultyMix': {'easy': easy, 'medium': medium, 'hard': hard},
        'questionTypes': questionTypes,
        'examStyle': examStyle,
        'includeVisuals': includeVisuals,
        'includeFlashcards': includeFlashcards,
        'autoGenerate': autoGenerate,
        'instructions': instructions,
        'language': language,
      };
}

class OutlineLesson {
  String title;
  int pageStart;
  int pageEnd;
  OutlineLesson({required this.title, required this.pageStart, required this.pageEnd});

  factory OutlineLesson.fromJson(Map<String, dynamic> j) => OutlineLesson(
        title: _str(j['title']),
        pageStart: _int(j['pageStart'], 1),
        pageEnd: _int(j['pageEnd'], 1),
      );

  Map<String, dynamic> toJson() => {'title': title, 'pageStart': pageStart, 'pageEnd': pageEnd};
}

class OutlineChapter {
  int index;
  String title;
  String summary;
  int pageStart;
  int pageEnd;
  bool selected;
  bool isPublished;
  List<OutlineLesson> lessons;

  OutlineChapter({
    required this.index,
    required this.title,
    this.summary = '',
    required this.pageStart,
    required this.pageEnd,
    this.selected = true,
    this.isPublished = false,
    required this.lessons,
  });

  factory OutlineChapter.fromJson(Map<String, dynamic> j) => OutlineChapter(
        index: _int(j['index']),
        title: _str(j['title']),
        summary: _str(j['summary']),
        pageStart: _int(j['pageStart'], 1),
        pageEnd: _int(j['pageEnd'], 1),
        selected: j['selected'] != false,
        isPublished: j['publishedSectionId'] != null,
        lessons: ((j['lessons'] as List?) ?? []).map((e) => OutlineLesson.fromJson(Map<String, dynamic>.from(e))).toList(),
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'summary': summary,
        'pageStart': pageStart,
        'pageEnd': pageEnd,
        'selected': selected,
        'lessons': lessons.map((l) => l.toJson()).toList(),
      };
}

class BuildProgress {
  final String stage;
  final int percent;
  final String message;
  final int done;
  final int total;
  final int? etaSeconds;
  final DateTime? startedAt;

  BuildProgress({
    this.stage = '',
    this.percent = 0,
    this.message = '',
    this.done = 0,
    this.total = 0,
    this.etaSeconds,
    this.startedAt,
  });

  factory BuildProgress.fromJson(Map<String, dynamic>? j) {
    if (j == null) return BuildProgress();
    return BuildProgress(
      stage: _str(j['stage']),
      percent: _int(j['percent']),
      message: _str(j['message']),
      done: _int(j['done']),
      total: _int(j['total']),
      etaSeconds: _intOrNull(j['etaSeconds']),
      startedAt: _date(j['startedAt']),
    );
  }
}

class BuildLog {
  final DateTime? at;
  final String level;
  final String message;
  BuildLog(this.at, this.level, this.message);
}

class CourseBuildJob {
  final String id;
  final String courseId;
  final String status;
  final String fileName;
  final int pageCount;
  final String pageUnit;
  final bool ocrUsed;
  final bool hasBookmarks;
  final BuildOptions options;
  final String bookTitle;
  final String subject;
  final String level;
  final String description;
  final List<OutlineChapter> chapters;
  final BuildProgress progress;
  final int statLessons;
  final int statQuestions;
  final int statVisuals;
  final int statUnverified;
  final List<BuildLog> logs;
  final String? error;
  final bool isRunning;
  final DateTime? createdAt;

  CourseBuildJob({
    required this.id,
    required this.courseId,
    required this.status,
    required this.fileName,
    required this.pageCount,
    required this.pageUnit,
    required this.ocrUsed,
    required this.hasBookmarks,
    required this.options,
    required this.bookTitle,
    required this.subject,
    required this.level,
    required this.description,
    required this.chapters,
    required this.progress,
    required this.statLessons,
    required this.statQuestions,
    required this.statVisuals,
    required this.statUnverified,
    required this.logs,
    required this.error,
    required this.isRunning,
    required this.createdAt,
  });

  factory CourseBuildJob.fromJson(Map<String, dynamic> j) {
    final source = (j['source'] as Map?)?.cast<String, dynamic>() ?? {};
    final outline = (j['outline'] as Map?)?.cast<String, dynamic>() ?? {};
    final stats = (j['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    return CourseBuildJob(
      id: _str(j['_id'] ?? j['id']),
      courseId: _str(j['courseId']),
      status: _str(j['status']),
      fileName: _str(source['fileName']),
      pageCount: _int(source['pageCount']),
      pageUnit: _str(source['pageUnit']).isEmpty ? 'page' : _str(source['pageUnit']),
      ocrUsed: source['ocrUsed'] == true,
      hasBookmarks: source['hasBookmarks'] == true,
      options: BuildOptions.fromJson((j['options'] as Map?)?.cast<String, dynamic>()),
      bookTitle: _str(outline['bookTitle']),
      subject: _str(outline['subject']),
      level: _str(outline['level']),
      description: _str(outline['description']),
      chapters: ((outline['chapters'] as List?) ?? [])
          .map((e) => OutlineChapter.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      progress: BuildProgress.fromJson((j['progress'] as Map?)?.cast<String, dynamic>()),
      statLessons: _int(stats['lessons']),
      statQuestions: _int(stats['questions']),
      statVisuals: _int(stats['visuals']),
      statUnverified: _int(stats['unverifiedQuestions']),
      logs: ((j['logs'] as List?) ?? [])
          .map((e) => BuildLog(_date(e['at']), _str(e['level']), _str(e['message'])))
          .toList(),
      error: j['error']?.toString(),
      isRunning: j['isRunning'] == true,
      createdAt: _date(j['createdAt']),
    );
  }

  String get displayTitle => bookTitle.isNotEmpty ? bookTitle : fileName;
  String get pageLabel => pageUnit == 'segment' ? 'part' : 'page';

  bool get isAnalyzing => ['uploaded', 'extracting', 'analyzing'].contains(status);
  bool get isGenerating => status == 'generating';
  bool get isBusy => isAnalyzing || isGenerating;
  bool get hasOutline => chapters.isNotEmpty;
}

class BuildItemSummary {
  final String id;
  final String kind;
  final int? chapterIndex;
  final int order;
  final String title;
  final int pageStart;
  final int pageEnd;
  final String status;
  final int? confidence;
  final List<String> warnings;
  final String? error;
  final int questionCount;
  final int unverifiedCount;
  final int visualCount;
  final bool hasContent;
  final String summary;
  final bool isPublished;
  final bool dirtyAfterPublish;
  final String? publishedLessonId;

  BuildItemSummary({
    required this.id,
    required this.kind,
    required this.chapterIndex,
    required this.order,
    required this.title,
    required this.pageStart,
    required this.pageEnd,
    required this.status,
    required this.confidence,
    required this.warnings,
    required this.error,
    required this.questionCount,
    required this.unverifiedCount,
    required this.visualCount,
    required this.hasContent,
    required this.summary,
    required this.isPublished,
    required this.dirtyAfterPublish,
    required this.publishedLessonId,
  });

  factory BuildItemSummary.fromJson(Map<String, dynamic> j) {
    final published = (j['published'] as Map?)?.cast<String, dynamic>() ?? {};
    return BuildItemSummary(
      id: _str(j['_id']),
      kind: _str(j['kind']),
      chapterIndex: _intOrNull(j['chapterIndex']),
      order: _int(j['order']),
      title: _str(j['title']),
      pageStart: _int(j['pageStart'], 1),
      pageEnd: _int(j['pageEnd'], 1),
      status: _str(j['status']),
      confidence: _intOrNull(j['confidence']),
      warnings: ((j['warnings'] as List?) ?? []).map((e) => e.toString()).toList(),
      error: j['error']?.toString(),
      questionCount: _int(j['questionCount']),
      unverifiedCount: _int(j['unverifiedCount']),
      visualCount: _int(j['visualCount']),
      hasContent: j['hasContent'] == true,
      summary: _str(j['summary']),
      isPublished: published['lessonId'] != null,
      dirtyAfterPublish: j['dirtyAfterPublish'] == true,
      publishedLessonId: published['lessonId']?.toString(),
    );
  }

  bool get isWorking => status == 'pending' || status == 'generating';
  bool get isReviewable => status == 'draft' || status == 'needs_review';

  String get kindLabel => switch (kind) {
        'chapter_test' => 'Chapter test',
        'revision' => 'Revision notes',
        'mock_exam' => 'Mock exam',
        _ => 'Lesson',
      };
}

class DraftQuestion {
  String? id;
  String type;
  String question;
  List<String> options;
  int? correctIndex;
  String answer;
  String explanation;
  String difficulty;
  String sourceChapter;
  String sourceSection;
  int? sourcePage;
  String sourceQuote;
  bool verified;
  int confidence;
  bool edited;

  DraftQuestion({
    this.id,
    this.type = 'mcq',
    this.question = '',
    List<String>? options,
    this.correctIndex,
    this.answer = '',
    this.explanation = '',
    this.difficulty = 'medium',
    this.sourceChapter = '',
    this.sourceSection = '',
    this.sourcePage,
    this.sourceQuote = '',
    this.verified = false,
    this.confidence = 0,
    this.edited = false,
  }) : options = options ?? [];

  factory DraftQuestion.fromJson(Map<String, dynamic> j) {
    final s = (j['source'] as Map?)?.cast<String, dynamic>() ?? {};
    return DraftQuestion(
      id: j['_id']?.toString(),
      type: _str(j['type']).isEmpty ? 'mcq' : _str(j['type']),
      question: _str(j['question']),
      options: ((j['options'] as List?) ?? []).map((e) => e.toString()).toList(),
      correctIndex: _intOrNull(j['correctIndex']),
      answer: _str(j['answer']),
      explanation: _str(j['explanation']),
      difficulty: _str(j['difficulty']).isEmpty ? 'medium' : _str(j['difficulty']),
      sourceChapter: _str(s['chapter']),
      sourceSection: _str(s['section']),
      sourcePage: _intOrNull(s['page']),
      sourceQuote: _str(s['quote']),
      verified: j['verified'] == true,
      confidence: _int(j['confidence']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'type': type,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'answer': answer,
        'explanation': explanation,
        'difficulty': difficulty,
        'source': {
          'chapter': sourceChapter,
          'section': sourceSection,
          'page': sourcePage,
          'quote': sourceQuote,
        },
        'verified': verified,
        'confidence': confidence,
        'edited': edited,
      };

  bool get hasOptions => options.length >= 2 && type != 'short_answer';

  String get typeLabel => switch (type) {
        'true_false' => 'True / False',
        'short_answer' => 'Short answer',
        'calculation' => 'Calculation',
        'scenario' => 'Scenario',
        _ => 'Multiple choice',
      };

  String get sourceLabel {
    final parts = <String>[
      if (sourceChapter.isNotEmpty) sourceChapter,
      if (sourceSection.isNotEmpty) sourceSection,
      if (sourcePage != null) 'p. $sourcePage',
    ];
    return parts.join(' › ');
  }
}

class BuildItem {
  final String id;
  final String jobId;
  final String kind;
  final int? chapterIndex;
  String title;
  final int pageStart;
  final int pageEnd;
  final String status;
  Map<String, dynamic>? content;
  List<DraftQuestion> questions;
  final int? confidence;
  final List<String> warnings;
  final String? error;
  final bool isPublished;

  BuildItem({
    required this.id,
    required this.jobId,
    required this.kind,
    required this.chapterIndex,
    required this.title,
    required this.pageStart,
    required this.pageEnd,
    required this.status,
    required this.content,
    required this.questions,
    required this.confidence,
    required this.warnings,
    required this.error,
    required this.isPublished,
  });

  factory BuildItem.fromJson(Map<String, dynamic> j) {
    final published = (j['published'] as Map?)?.cast<String, dynamic>() ?? {};
    return BuildItem(
      id: _str(j['_id']),
      jobId: _str(j['jobId']),
      kind: _str(j['kind']),
      chapterIndex: _intOrNull(j['chapterIndex']),
      title: _str(j['title']),
      pageStart: _int(j['pageStart'], 1),
      pageEnd: _int(j['pageEnd'], 1),
      status: _str(j['status']),
      content: (j['content'] as Map?)?.cast<String, dynamic>(),
      questions: ((j['questions'] as List?) ?? [])
          .map((e) => DraftQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      confidence: _intOrNull(j['confidence']),
      warnings: ((j['warnings'] as List?) ?? []).map((e) => e.toString()).toList(),
      error: j['error']?.toString(),
      isPublished: published['lessonId'] != null,
    );
  }

  bool get isWorking => status == 'pending' || status == 'generating';
}
