import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../models/course_build.dart';
import '../infrastructure/api_client.dart';

class CourseBuilderException implements Exception {
  final String message;
  CourseBuilderException(this.message);
  @override
  String toString() => message;
}

/// Client for /api/course-builder — AI book → course drafts.
class CourseBuilderService {
  final ApiClient _api;
  CourseBuilderService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static String get _base => '${ApiConfig.baseUrl}/course-builder';

  dynamic _data(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw CourseBuilderException('Unexpected server response (${res.statusCode})');
    }
    if (res.statusCode >= 400 || body['success'] == false) {
      throw CourseBuilderException(body['message']?.toString() ?? 'Request failed (${res.statusCode})');
    }
    return body['data'];
  }

  String _message(http.Response res) {
    try {
      return (jsonDecode(res.body) as Map)['message']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ─── Jobs ──────────────────────────────────────────────────────────────────

  Future<List<CourseBuildJob>> listJobs(String courseId) async {
    final data = _data(await _api.get('$_base/courses/$courseId/jobs')) as List;
    return data.map((e) => CourseBuildJob.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Uploads the book. [onProgress] reports 0..1 while bytes are sent.
  Future<CourseBuildJob> uploadBook({
    required String courseId,
    required PlatformFile file,
    required BuildOptions options,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('$_base/courses/$courseId/jobs');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _authHeaders());
    request.fields['options'] = jsonEncode(options.toJson());

    final contentType = _mediaType(file.extension);
    if (!kIsWeb && file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('book', file.path!, filename: file.name, contentType: contentType));
    } else if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('book', file.bytes!, filename: file.name, contentType: contentType));
    } else {
      throw CourseBuilderException('Could not read the selected file');
    }

    // Wrap the body stream so we can report upload progress.
    final total = request.contentLength;
    var sent = 0;
    final byteStream = request.finalize();
    final streamed = http.StreamedRequest('POST', uri)
      ..headers.addAll(request.headers)
      ..contentLength = total;
    byteStream.listen(
      (chunk) {
        sent += chunk.length;
        onProgress?.call(total > 0 ? sent / total : 0);
        streamed.sink.add(chunk);
      },
      onDone: () => streamed.sink.close(),
      onError: (e) => streamed.sink.addError(e),
      cancelOnError: true,
    );

    final response = await http.Response.fromStream(await streamed.send());
    if (response.statusCode >= 400) {
      throw CourseBuilderException(_message(response).isNotEmpty ? _message(response) : 'Upload failed (${response.statusCode})');
    }
    return CourseBuildJob.fromJson(Map<String, dynamic>.from(_data(response)));
  }

  Future<({CourseBuildJob job, List<BuildItemSummary> items})> getJob(String jobId) async {
    final data = Map<String, dynamic>.from(_data(await _api.get('$_base/jobs/$jobId')));
    return (
      job: CourseBuildJob.fromJson(Map<String, dynamic>.from(data['job'])),
      items: ((data['items'] as List?) ?? []).map((e) => BuildItemSummary.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Future<void> saveOutline(String jobId, {List<OutlineChapter>? chapters, String? bookTitle, BuildOptions? options}) async {
    _data(await _api.put('$_base/jobs/$jobId/outline', body: {
      if (chapters != null)
        'outline': {
          'chapters': chapters.map((c) => c.toJson()).toList(),
          if (bookTitle != null) 'bookTitle': bookTitle,
        },
      if (options != null) 'options': options.toJson(),
    }));
  }

  Future<void> startGeneration(String jobId, {BuildOptions? options}) async {
    _data(await _api.post('$_base/jobs/$jobId/generate', body: {if (options != null) 'options': options.toJson()}));
  }

  Future<void> cancel(String jobId) async => _data(await _api.post('$_base/jobs/$jobId/cancel', body: {}));

  Future<void> retryAnalysis(String jobId) async => _data(await _api.post('$_base/jobs/$jobId/retry-analysis', body: {}));

  Future<void> deleteJob(String jobId) async => _data(await _api.delete('$_base/jobs/$jobId'));

  Future<int> approve(String jobId, {int? chapterIndex, List<String>? itemIds}) async {
    final data = _data(await _api.post('$_base/jobs/$jobId/approve', body: {
      if (chapterIndex != null) 'chapterIndex': chapterIndex,
      if (itemIds != null) 'itemIds': itemIds,
    }));
    return (data?['approved'] as num?)?.toInt() ?? 0;
  }

  Future<int> publish(String jobId, {int? chapterIndex, List<String>? itemIds}) async {
    final data = _data(await _api.post('$_base/jobs/$jobId/publish', body: {
      if (chapterIndex != null) 'chapterIndex': chapterIndex,
      if (itemIds != null) 'itemIds': itemIds,
    }));
    return (data?['published'] as num?)?.toInt() ?? 0;
  }

  String questionBankCsvUrl(String jobId) => '$_base/jobs/$jobId/question-bank?format=csv';

  Future<String> exportQuestionBankCsv(String jobId) async {
    final res = await _api.get(questionBankCsvUrl(jobId));
    if (res.statusCode >= 400) throw CourseBuilderException(_message(res));
    return utf8.decode(res.bodyBytes);
  }

  // ─── Items ─────────────────────────────────────────────────────────────────

  Future<BuildItem> getItem(String itemId) async =>
      BuildItem.fromJson(Map<String, dynamic>.from(_data(await _api.get('$_base/items/$itemId'))));

  Future<BuildItem> saveItem(BuildItem item) async {
    final data = _data(await _api.put('$_base/items/${item.id}', body: {
      'title': item.title,
      'content': item.content,
      'questions': item.questions.map((q) => q.toJson()).toList(),
    }));
    return BuildItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> setItemStatus(String itemId, String status) async =>
      _data(await _api.post('$_base/items/$itemId/status', body: {'status': status}));

  Future<void> regenerateItem(String itemId, {String part = 'all', String instructions = ''}) async =>
      _data(await _api.post('$_base/items/$itemId/regenerate', body: {'part': part, 'instructions': instructions}));

  Future<DraftQuestion> regenerateQuestion(String itemId, String questionId, {String instructions = ''}) async {
    final data = _data(await _api.post('$_base/items/$itemId/questions/$questionId/regenerate', body: {'instructions': instructions}));
    return DraftQuestion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<({int n, String text})>> sourcePages(String itemId, {int? from, int? to}) async {
    final data = _data(await _api.get('$_base/items/$itemId/source', queryParams: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    })) as List;
    return data.map((e) => (n: (e['n'] as num).toInt(), text: e['text']?.toString() ?? '')).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  // Same options as ApiClient so we read the same stored token.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<Map<String, String>> _authHeaders() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (token != null) return {'Authorization': 'Bearer $token'};
    } catch (_) {}
    try {
      final stored = await _storage.read(key: StorageKeys.accessToken);
      if (stored != null && stored.isNotEmpty) return {'Authorization': 'Bearer $stored'};
    } catch (_) {}
    return {};
  }

  MediaType _mediaType(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'doc':
        return MediaType('application', 'msword');
      case 'md':
        return MediaType('text', 'markdown');
      default:
        return MediaType('text', 'plain');
    }
  }
}
