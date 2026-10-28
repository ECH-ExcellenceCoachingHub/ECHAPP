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
