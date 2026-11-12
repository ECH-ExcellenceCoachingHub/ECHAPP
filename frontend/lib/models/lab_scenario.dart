/// Virtual-lab models (backend /api/labs).
class LabScenario {
  final String id;
  final String slug;
  final String title;
  final String summary;
  final String subject;
  final String environment;
  final String level;
  final int durationMin;
  final int xp;
  final int stepCount;
  final String? thumbnail;
  final String status;
  /// 1 Beginner · 2 Easy · 3 Intermediate · 4 Advanced · 5 Expert
  final int difficulty;
  final List<String> tags;
  final List<String> objectives;
  final int hintCount;

  const LabScenario({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.subject,
    required this.environment,
    required this.level,
    required this.durationMin,
    required this.xp,
    required this.stepCount,
    this.thumbnail,
    this.status = 'published',
    this.difficulty = 2,
    this.tags = const [],
    this.objectives = const [],
    this.hintCount = 0,
  });

  factory LabScenario.fromJson(Map<String, dynamic> j) => LabScenario(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        environment: (j['environment'] ?? '').toString(),
        level: (j['level'] ?? 'secondary').toString(),
        durationMin: (j['durationMin'] as num?)?.toInt() ?? 20,
        xp: (j['xp'] as num?)?.toInt() ?? 100,
        stepCount: (j['stepCount'] as num?)?.toInt() ?? 0,
        thumbnail: j['thumbnail'] as String?,
        status: (j['status'] ?? 'published').toString(),
        difficulty: ((j['difficulty'] as num?)?.toInt() ?? 2).clamp(1, 5),
        tags: [for (final t in (j['tags'] as List? ?? const [])) t.toString()],
        objectives: [for (final o in (j['objectives'] as List? ?? const [])) o.toString()],
        hintCount: (j['hintCount'] as num?)?.toInt() ?? 0,
      );
}

/// Student's best result in one activity.
class LabActivityProgress {
  final int best;
  final bool passed;
  final int attempts;
  const LabActivityProgress({required this.best, required this.passed, required this.attempts});
}

/// A launch ticket for the Unity lab engine: short-lived lab token + parameters.
class LabSessionTicket {
  final String labToken;
  final String webUrl;
  final Map<String, String> launch;
  final LabScenario scenario;
  final String? resumeClientId;

  const LabSessionTicket({required this.labToken, required this.webUrl, required this.launch, required this.scenario, this.resumeClientId});

  factory LabSessionTicket.fromJson(Map<String, dynamic> j) => LabSessionTicket(
        labToken: j['labToken'] as String,
        webUrl: j['webUrl'] as String,
        launch: (j['launch'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
        scenario: LabScenario.fromJson(Map<String, dynamic>.from(j['scenario'] as Map)),
        resumeClientId: (j['resume'] is Map) ? (j['resume']['clientId'] as String?) : null,
      );

  /// Command-line arguments for the Windows standalone lab.
  List<String> get cliArgs => [
        for (final e in launch.entries)
          if (e.value.isNotEmpty) '--${e.key}=${e.value}',
        if (resumeClientId != null) '--resume=$resumeClientId',
      ];
}

class LabBadge {
  final String key;
  final DateTime? awardedAt;
  const LabBadge(this.key, this.awardedAt);

  String get title => switch (key) {
        'first-experiment' => 'First Experiment',
        'safety-champion' => 'Safety Champion',
        'precision-scientist' => 'Precision Scientist',
        'flawless-lab' => 'Flawless Lab',
        _ => key.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' '),
      };
}

class LabSummary {
  final int xp;
  final int level;
  final List<LabBadge> badges;
  final Map<String, int> passedBySubject;
  final List<LabContinue> continueItems;
  /// Best score per activity (keyed by scenario id).
  final Map<String, LabActivityProgress> activities;

  const LabSummary({required this.xp, required this.level, required this.badges, required this.passedBySubject, required this.continueItems, this.activities = const {}});

  static const empty = LabSummary(xp: 0, level: 1, badges: [], passedBySubject: {}, continueItems: []);

  /// XP needed for the next level (levels at 50·(n−1)² XP).
  int get nextLevelXp => 50 * level * level;
  int get levelStartXp => 50 * (level - 1) * (level - 1);
  double get levelProgress => nextLevelXp == levelStartXp ? 0 : ((xp - levelStartXp) / (nextLevelXp - levelStartXp)).clamp(0, 1).toDouble();

  factory LabSummary.fromJson(Map<String, dynamic> j) => LabSummary(
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        badges: [
          for (final b in (j['badges'] as List? ?? const []))
            LabBadge((b['key'] ?? '').toString(), DateTime.tryParse((b['awardedAt'] ?? '').toString())),
        ],
        passedBySubject: {
          for (final e in ((j['bySubject'] as Map?) ?? const {}).entries) e.key.toString(): ((e.value as Map)['passed'] as num?)?.toInt() ?? 0,
        },
        continueItems: [
          for (final c in (j['continue'] as List? ?? const []))
            if (c['scenarioId'] is Map) LabContinue.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
        activities: {
          for (final e in ((j['scenarios'] as Map?) ?? const {}).entries)
            e.key.toString(): LabActivityProgress(
              best: ((e.value as Map)['best'] as num?)?.toInt() ?? 0,
              passed: (e.value as Map)['passed'] == true,
              attempts: ((e.value as Map)['attempts'] as num?)?.toInt() ?? 0,
            ),
        },
      );
}

class LabContinue {
  final String clientId;
  final String scenarioId;
  final String title;
  final String subject;
  final int completedSteps;

  const LabContinue({required this.clientId, required this.scenarioId, required this.title, required this.subject, required this.completedSteps});

  factory LabContinue.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from(j['scenarioId'] as Map);
    return LabContinue(
      clientId: (j['clientId'] ?? '').toString(),
      scenarioId: (s['_id'] ?? s['id'] ?? '').toString(),
      title: (s['title'] ?? '').toString(),
      subject: (s['subject'] ?? '').toString(),
      completedSteps: (j['completedSteps'] as List?)?.length ?? 0,
    );
  }
}
