/// A real experiment demonstration on YouTube, with the lesson's own steps
/// placed in it (`Lesson.demo`). Students watch it in YouTube's embedded
/// player; the app pauses after each step to explain it and ask a question.
class LessonDemo {
  final DemoVideo video;
  final List<DemoStep> steps;

  const LessonDemo({required this.video, required this.steps});

  static LessonDemo? fromJson(dynamic json) {
    if (json is! Map) return null;
    final video = DemoVideo.fromJson(json['video'] ?? json['selected']);
    if (video == null) return null;
    final steps = (json['steps'] as List? ?? []).map(DemoStep.fromJson).whereType<DemoStep>().toList();
    if (steps.isEmpty) return null;
    return LessonDemo(video: video, steps: steps);
  }
}

class DemoVideo {
  final String videoId;
  final String title;
  final String channel;
  final int? durationSec;
  final String? thumbnail;
  final List<DemoChapter> chapters;

  const DemoVideo({required this.videoId, this.title = '', this.channel = '', this.durationSec, this.thumbnail, this.chapters = const []});

  static DemoVideo? fromJson(dynamic json) {
    if (json is! Map || json['videoId'] is! String) return null;
    return DemoVideo(
      videoId: json['videoId'] as String,
      title: json['title'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      durationSec: (json['durationSec'] as num?)?.toInt(),
      thumbnail: json['thumbnail'] as String?,
      chapters: (json['chapters'] as List? ?? [])
          .whereType<Map>()
          .map((c) => DemoChapter((c['at'] as num?)?.toInt() ?? 0, c['title'] as String? ?? ''))
          .toList(),
    );
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';
}

class DemoChapter {
  final int at;
  final String title;
  const DemoChapter(this.at, this.title);
}

class DemoStep {
  final String text;
  /// Second in the video where this step starts; null until placed.
  final int? at;
  /// 'chapter' | 'teacher' | null
  final String? source;
  final String explain;
  final DemoCheck? check;

  const DemoStep({required this.text, this.at, this.source, this.explain = '', this.check});

  static DemoStep? fromJson(dynamic json) {
    if (json is! Map || (json['text'] as String? ?? '').isEmpty) return null;
    return DemoStep(
      text: json['text'] as String,
      at: (json['at'] as num?)?.toInt(),
      source: json['source'] as String?,
      explain: json['explain'] as String? ?? '',
      check: DemoCheck.fromJson(json['check']),
    );
  }

  DemoStep copyWith({String? text, int? at, bool clearAt = false, String? source, String? explain}) => DemoStep(
        text: text ?? this.text,
        at: clearAt ? null : (at ?? this.at),
        source: clearAt ? null : (source ?? this.source),
        explain: explain ?? this.explain,
        check: check,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'at': at,
        'source': source,
        'explain': explain,
        'check': check?.toJson(),
      };
}

class DemoCheck {
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  const DemoCheck({required this.question, required this.choices, required this.answerIndex, this.explanation = ''});

  static DemoCheck? fromJson(dynamic json) {
    if (json is! Map) return null;
    final choices = (json['choices'] as List? ?? []).map((c) => '$c').toList();
    final answer = (json['answerIndex'] as num?)?.toInt() ?? -1;
    if ((json['question'] as String? ?? '').isEmpty || choices.length < 2 || answer < 0 || answer >= choices.length) return null;
    return DemoCheck(question: json['question'] as String, choices: choices, answerIndex: answer, explanation: json['explanation'] as String? ?? '');
  }

  Map<String, dynamic> toJson() => {'question': question, 'choices': choices, 'answerIndex': answerIndex, 'explanation': explanation};
}

/// Teacher view of a draft lesson's demonstration (search results + choice).
class DemoDraft {
  final bool configured;
  final String defaultQuery;
  final String? query;
  final List<DemoVideo> suggestions;
  final DemoVideo? selected;
  final List<DemoStep> steps;
  /// Students can see it (a video is chosen and every step is placed).
  final bool live;

  const DemoDraft({required this.configured, required this.defaultQuery, this.query, this.suggestions = const [], this.selected, this.steps = const [], this.live = false});

  factory DemoDraft.fromJson(Map<String, dynamic> json) {
    final demo = json['demo'] is Map ? Map<String, dynamic>.from(json['demo'] as Map) : const <String, dynamic>{};
    return DemoDraft(
      configured: json['configured'] == true,
      defaultQuery: json['defaultQuery'] as String? ?? '',
      query: demo['query'] as String?,
      suggestions: (demo['suggestions'] as List? ?? []).map(DemoVideo.fromJson).whereType<DemoVideo>().toList(),
      selected: DemoVideo.fromJson(demo['selected']),
      steps: (demo['steps'] as List? ?? []).map(DemoStep.fromJson).whereType<DemoStep>().toList(),
      live: json['live'] == true,
    );
  }
}

/// 75 → "1:15"
String formatDemoTime(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// "1:15" / "75" → 75; null when unreadable.
int? parseDemoTime(String text) {
  final parts = text.trim().split(':');
  if (parts.isEmpty || parts.length > 3) return null;
  var total = 0;
  for (final p in parts) {
    final n = int.tryParse(p.trim());
    if (n == null || n < 0) return null;
    total = total * 60 + n;
  }
  return total;
}
