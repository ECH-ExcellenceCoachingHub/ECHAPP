/// Student "My experiments": the builder kit from the backend and project cards.
/// A project's spec is kept as plain JSON (Map) — the backend compiles and validates it.
library;

class LabKitParam {
  final String key;
  final String label;
  final String type; // number | select | text
  final String unit;
  final num? min, max, step;
  final dynamic defaultValue;
  final List<({String value, String label})> options;

  const LabKitParam({required this.key, required this.label, required this.type, this.unit = '', this.min, this.max, this.step, this.defaultValue, this.options = const []});

  factory LabKitParam.fromJson(Map<String, dynamic> j) => LabKitParam(
        key: j['key'].toString(),
        label: (j['label'] ?? j['key']).toString(),
        type: (j['type'] ?? 'text').toString(),
        unit: (j['unit'] ?? '').toString(),
        min: j['min'] as num?,
        max: j['max'] as num?,
        step: j['step'] as num?,
        defaultValue: j['default'],
        options: [
          for (final o in (j['options'] as List? ?? const []))
            (value: (o as Map)['value'].toString(), label: (o['label'] ?? o['value']).toString()),
        ],
      );
}

class LabKitValue {
  final String label, unit;
  final num min, max, step, defaultValue;
  final String? maxFrom;
  const LabKitValue({required this.label, required this.unit, required this.min, required this.max, required this.step, required this.defaultValue, this.maxFrom});
  factory LabKitValue.fromJson(Map<String, dynamic> j) => LabKitValue(
        label: (j['label'] ?? 'Value').toString(),
        unit: (j['unit'] ?? '').toString(),
        min: j['min'] as num? ?? 0,
        max: j['max'] as num? ?? 1,
        step: j['step'] as num? ?? 0.1,
        defaultValue: j['default'] as num? ?? 0,
        maxFrom: j['maxFrom'] as String?,
      );
}

class LabKitAction {
  final String key, label, intent, text;
  final List<String> into;
  final LabKitValue? value;
  final LabKitValue? count;
  final List<String> choices;
  final bool command;
  final String? needsModel, needsType;

  const LabKitAction({required this.key, required this.label, required this.intent, required this.text, this.into = const [], this.value, this.count, this.choices = const [], this.command = false, this.needsModel, this.needsType});

  factory LabKitAction.fromJson(Map<String, dynamic> j) => LabKitAction(
        key: j['key'].toString(),
        label: (j['label'] ?? j['key']).toString(),
        intent: (j['intent'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        into: [for (final t in (j['into'] as List? ?? const [])) t.toString()],
        value: j['value'] is Map ? LabKitValue.fromJson(Map<String, dynamic>.from(j['value'] as Map)) : null,
        count: j['count'] is Map ? LabKitValue.fromJson({...Map<String, dynamic>.from(j['count'] as Map), 'step': 1, 'unit': ''}) : null,
        choices: [for (final c in (j['choices'] as List? ?? const [])) c.toString()],
        command: j['command'] == true,
        needsModel: j['needsModel'] as String?,
        needsType: j['needsType'] as String?,
      );
}

class LabKitReading {
  final String key, label, unit;
  final num tolerance;
  const LabKitReading({required this.key, required this.label, required this.unit, required this.tolerance});
  factory LabKitReading.fromJson(Map<String, dynamic> j) => LabKitReading(
        key: j['key'].toString(),
        label: (j['label'] ?? j['key']).toString(),
        unit: (j['unit'] ?? '').toString(),
        tolerance: j['tolerance'] as num? ?? 0,
      );
}

class LabKitItem {
  final String type, title, category;
  final int max;
  final List<LabKitParam> params;
  final List<LabKitAction> actions;
  final List<LabKitReading> readings;

  const LabKitItem({required this.type, required this.title, required this.category, required this.max, required this.params, required this.actions, required this.readings});

  factory LabKitItem.fromJson(Map<String, dynamic> j) => LabKitItem(
        type: j['type'].toString(),
        title: (j['title'] ?? j['type']).toString(),
        category: (j['category'] ?? '').toString(),
        max: (j['max'] as num?)?.toInt() ?? 1,
        params: [for (final p in (j['params'] as List? ?? const [])) LabKitParam.fromJson(Map<String, dynamic>.from(p as Map))],
        actions: [for (final a in (j['actions'] as List? ?? const [])) LabKitAction.fromJson(Map<String, dynamic>.from(a as Map))],
        readings: [for (final r in (j['readings'] as List? ?? const [])) LabKitReading.fromJson(Map<String, dynamic>.from(r as Map))],
      );

  /// Short name without "(250 mL)" etc.
  String get shortTitle => title.replaceAll(RegExp(r'\s*\(.*\)$'), '');
}

class LabKitRoom {
  final String environment, title, subject;
  final List<String> tips;
  final List<LabKitItem> items;
  const LabKitRoom({required this.environment, required this.title, required this.subject, required this.tips, required this.items});

  LabKitItem? item(String type) {
    for (final i in items) {
      if (i.type == type) return i;
    }
    return null;
  }
}

class LabKit {
  final Map<String, LabKitRoom> rooms;
  final int maxSteps;
  const LabKit({required this.rooms, required this.maxSteps});

  factory LabKit.fromJson(Map<String, dynamic> j) {
    final rooms = <String, LabKitRoom>{};
    for (final e in ((j['rooms'] as Map?) ?? const {}).entries) {
      final r = Map<String, dynamic>.from(e.value as Map);
      rooms[e.key.toString()] = LabKitRoom(
        environment: e.key.toString(),
        title: (r['title'] ?? e.key).toString(),
        subject: (r['subject'] ?? '').toString(),
        tips: [for (final t in (r['tips'] as List? ?? const [])) t.toString()],
        items: [for (final i in (r['items'] as List? ?? const [])) LabKitItem.fromJson(Map<String, dynamic>.from(i as Map))],
      );
    }
    return LabKit(rooms: rooms, maxSteps: ((j['limits'] as Map?)?['steps'] as num?)?.toInt() ?? 30);
  }
}

/// One of the student's own experiments (list card).
class LabProject {
  final String id, slug, title, summary, environment, status, aim, hypothesis, conclusion;
  final int stepCount;
  final DateTime? updatedAt;
  final int? best;
  final bool passed;
  final int attempts;

  const LabProject({required this.id, required this.slug, required this.title, required this.summary, required this.environment, required this.status, required this.aim, required this.hypothesis, required this.conclusion, required this.stepCount, this.updatedAt, this.best, this.passed = false, this.attempts = 0});

  factory LabProject.fromJson(Map<String, dynamic> j) {
    final best = j['best'] is Map ? Map<String, dynamic>.from(j['best'] as Map) : null;
    return LabProject(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      environment: (j['environment'] ?? '').toString(),
      status: (j['status'] ?? 'draft').toString(),
      aim: (j['aim'] ?? '').toString(),
      hypothesis: (j['hypothesis'] ?? '').toString(),
      conclusion: (j['conclusion'] ?? '').toString(),
      stepCount: (j['stepCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((j['updatedAt'] ?? '').toString()),
      best: (best?['best'] as num?)?.toInt(),
      passed: best?['passed'] == true,
      attempts: (best?['attempts'] as num?)?.toInt() ?? 0,
    );
  }

  String get statusLabel => switch (status) {
        'review' => 'Sent to teachers',
        'published' => 'Published for everyone',
        _ => 'Private',
      };
}

/// The backend rejected a project; [errors] are friendly, student-facing messages.
class LabProjectInvalid implements Exception {
  final String message;
  final List<String> errors;
  const LabProjectInvalid(this.message, this.errors);
  @override
  String toString() => errors.isEmpty ? message : '$message:\n• ${errors.join('\n• ')}';
}
