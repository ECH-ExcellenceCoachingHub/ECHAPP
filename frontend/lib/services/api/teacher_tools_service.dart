import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';

/// Error from the teacher tools (keeps eexams' message, e.g. "allowance used").
class TeacherToolsException implements Exception {
  final String message;
  final int? status;
  final String? code;
  TeacherToolsException(this.message, {this.status, this.code});
  bool get quotaReached => code == 'PLANNER_QUOTA_EXCEEDED';
  bool get upgradeRequired => code == 'FEATURE_NOT_AVAILABLE' || code == 'PLAN_SCOPE_EXCLUDED' || code == 'EXAM_LIMIT_REACHED';
  @override
  String toString() => message;
}

/// A file picked by the teacher (bytes work on web, mobile and desktop).
class PickedUpload {
  final String name;
  final Uint8List bytes;
  const PickedUpload(this.name, this.bytes);
}

/// One monthly planner allowance (lessonPlansPerMonth, slidesPerMonth, …).
class PlannerQuota {
  final String key;
  final String label;
  final int limit; // -1 = unlimited
  final int used;
  final bool allowed;
  final DateTime? periodEnd;
  const PlannerQuota({required this.key, required this.label, required this.limit, required this.used, required this.allowed, this.periodEnd});

  factory PlannerQuota.fromJson(Map<String, dynamic> j) => PlannerQuota(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        limit: (j['limit'] as num?)?.toInt() ?? -1,
        used: (j['used'] as num?)?.toInt() ?? 0,
        allowed: j['allowed'] != false,
        periodEnd: j['periodEnd'] != null ? DateTime.tryParse(j['periodEnd'].toString())?.toLocal() : null,
      );

  String get summary => limit < 0 ? 'Unlimited this month' : '$used of $limit used this month';
}

class TeacherToolsStatus {
  final bool linked;
  final bool linkRequired;
  final String? message;
  final String? eexamsRole;
  const TeacherToolsStatus({required this.linked, this.linkRequired = false, this.message, this.eexamsRole});
}

class EexamsExamSummary {
  final String id;
  final String title;
  final String status;
  final int? timeLimit;
  final DateTime? createdAt;
  const EexamsExamSummary({required this.id, required this.title, required this.status, this.timeLimit, this.createdAt});
  factory EexamsExamSummary.fromJson(Map<String, dynamic> j) => EexamsExamSummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Exam').toString(),
        status: (j['status'] ?? 'draft').toString(),
        timeLimit: (j['timeLimit'] as num?)?.toInt(),
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString())?.toLocal() : null,
      );
}

class ExamLevel {
  final String id;
  final String name;
  final List<String> subLevels;
  const ExamLevel(this.id, this.name, this.subLevels);
}

/// Planner kinds handled by the "resources" studio on eexams.
enum PlannerKind { slides, exercises, scheme }

extension PlannerKindX on PlannerKind {
  String get api => name; // slides | exercises | scheme
  String get quotaKey => switch (this) { PlannerKind.slides => 'slidesPerMonth', PlannerKind.exercises => 'exercisesPerMonth', PlannerKind.scheme => 'schemesPerMonth' };
  String get bodyKey => switch (this) { PlannerKind.slides => 'slides', PlannerKind.exercises => 'items', PlannerKind.scheme => 'weeks' };
}

/// ECH teacher tools (/api/teacher-tools): planner engine + exam creation on eexams.
class TeacherToolsService {
  final ApiClient _api;
  final http.Client _http;
  TeacherToolsService({ApiClient? apiClient, http.Client? httpClient})
      : _api = apiClient ?? ApiClient(),
        _http = httpClient ?? http.Client();

  static String get _base => '${ApiConfig.baseUrl}/teacher-tools';

  // ── plumbing ──────────────────────────────────────────────────────────────
  Future<http.Response> _send(String method, String path, {Object? body, Duration timeout = const Duration(seconds: 60)}) async {
    final headers = await _api.authHeaders();
    final uri = Uri.parse('$_base$path');
    final req = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);
    final streamed = await _http.send(req).timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  dynamic _decode(http.Response res) {
    dynamic json;
    try {
      json = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      json = null;
    }
    if (res.statusCode >= 400) {
      final map = json is Map ? json : const {};
      throw TeacherToolsException(
        (map['message'] ?? 'Something went wrong (HTTP ${res.statusCode}).').toString(),
        status: res.statusCode,
        code: map['code']?.toString(),
      );
    }
    return json;
  }

  Future<dynamic> _json(String method, String path, {Object? body, Duration timeout = const Duration(seconds: 60)}) async =>
      _decode(await _send(method, path, body: body, timeout: timeout));

  Future<Uint8List> _bytes(String method, String path, {Object? body}) async {
    final res = await _send(method, path, body: body, timeout: const Duration(seconds: 120));
    if (res.statusCode >= 400) _decode(res);
    return res.bodyBytes;
  }

  Future<dynamic> _multipart(String path, {required Map<String, String> fields, required Map<String, PickedUpload> files, Duration timeout = const Duration(minutes: 5)}) async {
    final headers = await _api.authHeaders()
      ..remove('Content-Type');
    final req = http.MultipartRequest('POST', Uri.parse('$_base$path'))
      ..headers.addAll(headers)
      ..fields.addAll(fields);
    files.forEach((field, f) => req.files.add(http.MultipartFile.fromBytes(field, f.bytes, filename: f.name)));
    final streamed = await _http.send(req).timeout(timeout);
    return _decode(await http.Response.fromStream(streamed));
  }

  // ── status ────────────────────────────────────────────────────────────────
  Future<TeacherToolsStatus> status() async {
    final json = await _json('GET', '/status', timeout: const Duration(seconds: 45));
    final d = Map<String, dynamic>.from((json['data'] as Map?) ?? const {});
    return TeacherToolsStatus(
      linked: d['linked'] == true,
      linkRequired: d['linkRequired'] == true,
      message: d['message']?.toString(),
      eexamsRole: d['eexamsRole']?.toString(),
    );
  }

  /// All four monthly allowances (same counters for every tool).
  Future<List<PlannerQuota>> quotas() async {
    final json = await _json('GET', '/planner/resources/quota');
    return ((json['quotas'] as List?) ?? const []).map((e) => PlannerQuota.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Reads a textbook / document and returns its text (nothing is stored).
  Future<String> extractText(PickedUpload file) async {
    final json = await _multipart('/planner/lesson-plans/extract', fields: const {}, files: {'file': file}, timeout: const Duration(minutes: 3));
    return (json['content'] ?? json['text'] ?? '').toString();
  }

  // ── Lesson plans ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listLessonPlans() async {
    final json = await _json('GET', '/planner/lesson-plans');
    return ((json as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> generateLessonPlan(Map<String, dynamic> request) async =>
      Map<String, dynamic>.from(await _json('POST', '/planner/lesson-plans/generate', body: request, timeout: const Duration(minutes: 3)) as Map);

  Future<Map<String, dynamic>> saveLessonPlan(Map<String, dynamic> plan, {String? id}) async => Map<String, dynamic>.from(
      await _json(id == null ? 'POST' : 'PUT', id == null ? '/planner/lesson-plans' : '/planner/lesson-plans/$id', body: plan) as Map);

  Future<void> deleteLessonPlan(String id) => _json('DELETE', '/planner/lesson-plans/$id');

  /// [format] is `docx` or `pdf`. Unsaved plans are rendered from [plan].
  Future<Uint8List> exportLessonPlan(String format, {String? id, Map<String, dynamic>? plan}) =>
      id != null ? _bytes('GET', '/planner/lesson-plans/$id/$format') : _bytes('POST', '/planner/lesson-plans/$format', body: plan);

  // ── Slides / Exercises / Scheme of work ───────────────────────────────────
  Future<List<Map<String, dynamic>>> listResources(PlannerKind kind) async {
    final json = await _json('GET', '/planner/resources/${kind.api}');
    return ((json as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> slideThemes() async {
    final json = await _json('GET', '/planner/resources/themes');
    return ((json['themes'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> generateResource(PlannerKind kind, Map<String, dynamic> request) async =>
      Map<String, dynamic>.from(await _json('POST', '/planner/resources/${kind.api}/generate', body: request, timeout: const Duration(minutes: 3)) as Map);

  Future<Map<String, dynamic>> saveResource(PlannerKind kind, Map<String, dynamic> resource, {String? id}) async => Map<String, dynamic>.from(
      await _json(id == null ? 'POST' : 'PUT', id == null ? '/planner/resources/${kind.api}' : '/planner/resources/${kind.api}/$id', body: resource) as Map);

  Future<void> deleteResource(PlannerKind kind, String id) => _json('DELETE', '/planner/resources/${kind.api}/$id');

  /// [format]: `pptx`/`pdf` for slides, `docx`/`pdf` for exercises and schemes.
  Future<Uint8List> exportResource(PlannerKind kind, String format, {String? id, Map<String, dynamic>? resource}) => id != null
      ? _bytes('GET', '/planner/resources/${kind.api}/$id/export/$format')
      : _bytes('POST', '/planner/resources/${kind.api}/export/$format', body: resource);

  // ── Exams (saved + managed on eexams) ─────────────────────────────────────
  Future<List<EexamsExamSummary>> listExams() async {
    final json = await _json('GET', '/exams');
    return ((json['data'] as List?) ?? const []).map((e) => EexamsExamSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ExamLevel>> levels() async {
    final json = await _json('GET', '/levels');
    final list = json is List ? json : (json is Map ? (json['levels'] ?? json['data'] ?? const []) : const []);
    return (list as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final subs = ((m['subLevels'] as List?) ?? const []).map((s) => s is Map ? (s['name'] ?? '').toString() : s.toString()).where((s) => s.isNotEmpty).toList();
      return ExamLevel((m['_id'] ?? m['id'] ?? '').toString(), (m['name'] ?? '').toString(), subs);
    }).where((l) => l.id.isNotEmpty).toList();
  }

  /// AI writes the exam from a description; it is saved on eexams as a draft.
  Future<Map<String, dynamic>> createExamWithAi({required String prompt, String? level, String? subLevel}) async {
    final json = await _json('POST', '/exams/ai', body: {'prompt': prompt, if (level != null) 'level': level, if (subLevel != null) 'subLevel': subLevel}, timeout: const Duration(minutes: 4));
    return Map<String, dynamic>.from((json['data'] as Map?) ?? const {});
  }

  /// Uploads an exam document (+ optional answer sheet); eexams converts it into a draft.
  Future<Map<String, dynamic>> uploadExam({required PickedUpload examFile, PickedUpload? answerFile, required String title, required int timeLimit, String? level, String? subLevel}) async {
    final json = await _multipart('/exams/upload', fields: {
      'title': title,
      'timeLimit': '$timeLimit',
      if (level != null) 'level': level,
      if (subLevel != null) 'subLevel': subLevel,
      'accessType': 'subscription',
    }, files: {
      'examFile': examFile,
      if (answerFile != null) 'answerFile': answerFile,
    });
    return Map<String, dynamic>.from(json as Map);
  }
}

/// Saves a downloaded document and opens it (browser download on web).
/// Returns where it was saved (null on web).
Future<String?> saveAndOpenDocument(Uint8List bytes, String fileName) async {
  final safe = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-').trim();
  if (kIsWeb) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', safe)
      ..click();
    html.Url.revokeObjectUrl(url);
    return null;
  }
  Directory? dir;
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getDownloadsDirectory();
    }
  } catch (_) {}
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$safe');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFile.open(file.path);
  return file.path;
}
