/// A "pause and think" question inside a generated video. The player pauses
/// at [at] and asks; after answering, playback continues from [resumeAt]
/// (the start of the answer reveal).
class VideoInteraction {
  final String id;
  final Duration at;
  final Duration resumeAt;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  const VideoInteraction({
    required this.id,
    required this.at,
    required this.resumeAt,
    required this.question,
    required this.choices,
    required this.answerIndex,
    this.explanation = '',
  });

  static Duration _secs(dynamic v) => Duration(milliseconds: (((v as num?) ?? 0) * 1000).round());

  /// Null for anything malformed (missing question, fewer than 2 choices, bad answer index).
  static VideoInteraction? fromJson(dynamic json) {
    if (json is! Map) return null;
    final choices = (json['choices'] as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? const <String>[];
    final answer = (json['answerIndex'] as num?)?.toInt() ?? -1;
    final question = json['question']?.toString() ?? '';
    if (question.isEmpty || choices.length < 2 || answer < 0 || answer >= choices.length || json['at'] is! num) return null;
    final at = _secs(json['at']);
    final resume = json['resumeAt'] is num ? _secs(json['resumeAt']) : at;
    return VideoInteraction(
      id: json['id']?.toString() ?? 'check-${at.inMilliseconds}',
      at: at,
      resumeAt: resume < at ? at : resume,
      question: question,
      choices: choices,
      answerIndex: answer,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

/// Attribution for a licensed photo or clip shown in a generated video.
class VideoCredit {
  final String title;
  final String author;
  final String source; // e.g. "Wikimedia Commons", "Pexels"
  final String license;
  final String? sourceUrl;
  final String kind; // image | video

  const VideoCredit({required this.title, required this.author, required this.source, required this.license, this.sourceUrl, this.kind = 'image'});

  static VideoCredit? fromJson(dynamic json) {
    if (json is! Map) return null;
    final author = json['author']?.toString() ?? '';
    final source = json['providerLabel']?.toString() ?? json['provider']?.toString() ?? '';
    if (author.isEmpty && source.isEmpty) return null;
    return VideoCredit(
      title: json['title']?.toString() ?? '',
      author: author,
      source: source,
      license: json['license']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString(),
      kind: json['kind']?.toString() ?? 'image',
    );
  }

  /// "Jane Doe · Wikimedia Commons · CC BY 4.0"
  String get line => [author, source, license].where((s) => s.isNotEmpty).join(' · ');
}

/// Generated lesson video metadata (Lesson.aiVideo / aiExperimentVideo and
/// draft item video fields). Older lessons have none — parse returns null.
class LessonVideo {
  final String variant; // explainer | experiment
  final String status; // queued | generating_script | ... | completed | failed | cancelled
  final String? url;
  final String? s3Key;
  final String? captionsUrl;
  final double? durationSeconds;
  final String? transcript;
  final bool stale;
  final String reviewStatus; // not_required | pending | approved | rejected
  final String? disclosure;
  final String? error;
  final int contentVersion;
  final List<VideoInteraction> interactions;
  final List<VideoCredit> credits;

  const LessonVideo({
    this.variant = 'explainer',
    this.status = 'queued',
    this.url,
    this.s3Key,
    this.captionsUrl,
    this.durationSeconds,
    this.transcript,
    this.stale = false,
    this.reviewStatus = 'not_required',
    this.disclosure,
    this.error,
    this.contentVersion = 1,
    this.interactions = const [],
    this.credits = const [],
  });

  static LessonVideo? fromJson(dynamic json) {
    if (json is! Map) return null;
    final j = Map<String, dynamic>.from(json);
    String? s(String k) {
      final v = j[k];
      return v == null || v.toString().isEmpty ? null : v.toString();
    }

    return LessonVideo(
      variant: s('variant') ?? 'explainer',
      status: s('status') ?? 'queued',
      url: s('url'),
      s3Key: s('s3Key'),
      captionsUrl: s('captionsUrl'),
      durationSeconds: (j['durationSeconds'] as num?)?.toDouble(),
      transcript: s('transcript'),
      stale: j['stale'] == true,
      reviewStatus: s('reviewStatus') ?? 'not_required',
      disclosure: s('disclosure'),
      error: s('error'),
      contentVersion: (j['contentVersion'] as num?)?.toInt() ?? 1,
      interactions: ((j['interactions'] as List?) ?? const [])
          .map(VideoInteraction.fromJson)
          .whereType<VideoInteraction>()
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at)),
      credits: ((j['credits'] as List?) ?? const []).map(VideoCredit.fromJson).whereType<VideoCredit>().toList(),
    );
  }

  static const processingStatuses = {
    'queued', 'generating_script', 'generating_audio', 'generating_visuals', 'assembling', 'validating',
  };

  bool get isProcessing => processingStatuses.contains(status);
  bool get isFailed => status == 'failed' || status == 'cancelled';

  /// Students may watch it (a file exists and it is not waiting for / rejected in review).
  bool get isWatchable => (s3Key != null || url != null) && (reviewStatus == 'not_required' || reviewStatus == 'approved');
  bool get needsReview => reviewStatus == 'pending';

  /// A watchable video can exist while a newer one is being generated.
  bool get hasPlayableFile => isWatchable;

  String get statusLabel => labelFor(status);

  static String labelFor(String status) {
    switch (status) {
      case 'queued':
        return 'Waiting to start';
      case 'generating_script':
        return 'Writing the teaching script';
      case 'generating_audio':
        return 'Recording the narration';
      case 'generating_visuals':
        return 'Drawing diagrams and formulas';
      case 'assembling':
        return 'Putting the video together';
      case 'validating':
        return 'Final quality checks';
      case 'completed':
        return 'Ready';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// 0..1 progress estimate from the pipeline stage.
  double get progress {
    const order = ['queued', 'generating_script', 'generating_audio', 'generating_visuals', 'assembling', 'validating', 'completed'];
    final i = order.indexOf(status);
    return i < 0 ? 0 : i / (order.length - 1);
  }
}

/// Admin view of one video generation job (GET /course-builder/video-jobs/:id).
class VideoJobView {
  final String id;
  final String variant;
  final String state;
  final String status;
  final int contentVersion;
  final int attempts;
  final int maxAttempts;
  final String? errorMessage;
  final String? errorStage;
  final bool reviewRequired;
  final String reviewStatus;
  final List<String> reviewReasons;
  final List<({String name, bool passed, String detail})> checks;
  final double actualUsd;
  final double estimatedUsd;
  final String? outputUrl;
  final String? previewUrl;
  final double? durationSeconds;
  final List<({int n, String type, String heading, String narration})> scenes;
  final List<String> storyboardWarnings;
  final DateTime? finishedAt;

  const VideoJobView({
    required this.id,
    required this.variant,
    required this.state,
    required this.status,
    this.contentVersion = 1,
    this.attempts = 0,
    this.maxAttempts = 0,
    this.errorMessage,
    this.errorStage,
    this.reviewRequired = false,
    this.reviewStatus = 'not_required',
    this.reviewReasons = const [],
    this.checks = const [],
    this.actualUsd = 0,
    this.estimatedUsd = 0,
    this.outputUrl,
    this.previewUrl,
    this.durationSeconds,
    this.scenes = const [],
    this.storyboardWarnings = const [],
    this.finishedAt,
  });

  bool get isRunning => state == 'running' || state == 'queued' || state == 'retry_wait';
  bool get isDone => state == 'completed';

  static VideoJobView? fromJson(dynamic json) {
    if (json is! Map) return null;
    final j = Map<String, dynamic>.from(json);
    final err = j['error'] is Map ? Map<String, dynamic>.from(j['error']) : null;
    final review = j['review'] is Map ? Map<String, dynamic>.from(j['review']) : <String, dynamic>{};
    final cost = j['cost'] is Map ? Map<String, dynamic>.from(j['cost']) : <String, dynamic>{};
    final output = j['output'] is Map ? Map<String, dynamic>.from(j['output']) : null;
    final sb = j['storyboard'] is Map ? Map<String, dynamic>.from(j['storyboard']) : null;
    return VideoJobView(
      id: (j['_id'] ?? '').toString(),
      variant: (j['variant'] ?? 'explainer').toString(),
      state: (j['state'] ?? 'queued').toString(),
      status: (j['status'] ?? 'queued').toString(),
      contentVersion: (j['contentVersion'] as num?)?.toInt() ?? 1,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (j['maxAttempts'] as num?)?.toInt() ?? 0,
      errorMessage: err?['message']?.toString(),
      errorStage: err?['stage']?.toString(),
      reviewRequired: review['required'] == true,
      reviewStatus: (review['status'] ?? 'not_required').toString(),
      reviewReasons: (review['reasons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      checks: (j['checks'] as List?)
              ?.whereType<Map>()
              .map((c) => (name: c['name']?.toString() ?? '', passed: c['passed'] == true, detail: c['detail']?.toString() ?? ''))
              .toList() ??
          const [],
      actualUsd: (cost['actualUsd'] as num?)?.toDouble() ?? 0,
      estimatedUsd: (cost['estimatedUsd'] as num?)?.toDouble() ?? 0,
      outputUrl: output?['url']?.toString(),
      previewUrl: j['previewUrl']?.toString(),
      durationSeconds: (output?['durationSeconds'] as num?)?.toDouble(),
      scenes: (sb?['scenes'] as List?)
              ?.whereType<Map>()
              .map((s) => (
                    n: (s['n'] as num?)?.toInt() ?? 0,
                    type: s['type']?.toString() ?? '',
                    heading: s['heading']?.toString() ?? '',
                    narration: s['narration']?.toString() ?? '',
                  ))
              .toList() ??
          const [],
      storyboardWarnings: (j['storyboardWarnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      finishedAt: DateTime.tryParse(j['finishedAt']?.toString() ?? ''),
    );
  }
}

/// One lesson video in a build's job list (GET /course-builder/jobs/:jobId/video-jobs).
class BuildVideoJob {
  final String id;
  final String? itemId;
  final String title;
  final String variant;
  /// queued | retry_wait | running | failed
  final String state;
  final String status;
  final int attempts;
  final int maxAttempts;
  final DateTime? startedAt;
  final DateTime? stageSince;
  final DateTime? nextRunAt;
  final String? worker;
  final bool cancelRequested;
  /// Why the job looks stuck (null when it is fine).
  final String? stuck;
  final String? errorMessage;
  final String? errorStage;
  final DateTime? finishedAt;

  const BuildVideoJob({
    required this.id,
    this.itemId,
    required this.title,
    required this.variant,
    required this.state,
    required this.status,
    this.attempts = 0,
    this.maxAttempts = 0,
    this.startedAt,
    this.stageSince,
    this.nextRunAt,
    this.worker,
    this.cancelRequested = false,
    this.stuck,
    this.errorMessage,
    this.errorStage,
    this.finishedAt,
  });

  factory BuildVideoJob.fromJson(Map<String, dynamic> j) {
    DateTime? date(String k) => j[k] is String ? DateTime.tryParse(j[k] as String)?.toLocal() : null;
    final error = j['error'] is Map ? Map<String, dynamic>.from(j['error'] as Map) : null;
    return BuildVideoJob(
      id: '${j['_id'] ?? ''}',
      itemId: j['itemId'] as String?,
      title: j['title'] as String? ?? 'Lesson',
      variant: j['variant'] as String? ?? 'explainer',
      state: j['state'] as String? ?? 'queued',
      status: j['status'] as String? ?? 'queued',
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (j['maxAttempts'] as num?)?.toInt() ?? 0,
      startedAt: date('startedAt'),
      stageSince: date('stageSince'),
      nextRunAt: date('nextRunAt'),
      worker: j['worker'] as String?,
      cancelRequested: j['cancelRequested'] == true,
      stuck: j['stuck'] as String?,
      errorMessage: error?['message'] as String?,
      errorStage: error?['stage'] as String?,
      finishedAt: date('finishedAt'),
    );
  }

  bool get isRunning => state == 'running';
}

class BuildVideoJobs {
  final List<BuildVideoJob> active;
  final List<BuildVideoJob> failed;
  /// A media worker is holding a job or finished one in the last 10 minutes.
  final bool workerActive;
  final int stuckAfterMinutes;
  final String? courseId;
  /// Video generation is paused for this course.
  final bool paused;

  const BuildVideoJobs({this.active = const [], this.failed = const [], this.workerActive = false, this.stuckAfterMinutes = 15, this.courseId, this.paused = false});

  factory BuildVideoJobs.fromJson(Map<String, dynamic> j) {
    List<BuildVideoJob> list(String k) =>
        (j[k] as List? ?? []).whereType<Map>().map((e) => BuildVideoJob.fromJson(Map<String, dynamic>.from(e))).toList();
    return BuildVideoJobs(
      active: list('active'),
      failed: list('failed'),
      workerActive: j['workerActive'] == true,
      stuckAfterMinutes: (j['stuckAfterMinutes'] as num?)?.toInt() ?? 15,
      courseId: j['courseId'] as String?,
      paused: (j['pause'] as Map?)?['paused'] == true,
    );
  }

  List<BuildVideoJob> get stuck => active.where((j) => j.stuck != null).toList();
}

/// A course in the lesson-video queue (GET /course-builder/video-queue).
class CourseVideoQueue {
  final String courseId;
  final String title;
  final String? buildJobId;
  final bool paused;
  final int running;
  final int waiting;

  const CourseVideoQueue({required this.courseId, required this.title, this.buildJobId, this.paused = false, this.running = 0, this.waiting = 0});

  factory CourseVideoQueue.fromJson(Map<String, dynamic> j) => CourseVideoQueue(
        courseId: '${j['courseId'] ?? ''}',
        title: j['title'] as String? ?? 'Course',
        buildJobId: j['buildJobId'] as String?,
        paused: j['paused'] == true,
        running: (j['running'] as num?)?.toInt() ?? 0,
        waiting: (j['waiting'] as num?)?.toInt() ?? 0,
      );
}
