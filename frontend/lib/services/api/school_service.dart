import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';

/// Error from the school API. [code] carries machine-readable reasons such as
/// `POSSIBLE_DUPLICATE`, `STUDENT_LIMIT_REACHED`, `CONTACT_IN_USE`; [body]
/// keeps the full response (e.g. duplicate `candidates`).
class SchoolApiError implements Exception {
  final String message;
  final int status;
  final String? code;
  final Map<String, dynamic> body;

  SchoolApiError(this.message, this.status, {this.code, this.body = const {}});

  List<Map<String, dynamic>> get candidates =>
      ((body['candidates'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  String toString() => message;
}

/// Everything about schools: super admin, school admin (head teacher /
/// director of studies), teachers, students and parents.
///
/// Responses are returned as plain maps (the `data` part of the API answer).
class SchoolService {
  SchoolService({ApiClient? apiClient}) : _api = apiClient ?? testClient ?? ApiClient();

  /// Tests only: every SchoolService() created by a screen uses this client.
  static ApiClient? testClient;

  final ApiClient _api;
  static String get _base => ApiConfig.baseUrl;

  void dispose() {}

  // ── HTTP helpers ─────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw SchoolApiError(
        r.statusCode >= 500 ? 'The server is not answering right now. Please try again.' : 'Unexpected answer from the server.',
        r.statusCode,
      );
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && json['success'] != false) {
      final data = json['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{'value': data};
    }
    throw SchoolApiError(
      (json['message'] as String?) ?? 'Request failed',
      r.statusCode,
      code: json['code'] as String?,
      body: json,
    );
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? query]) async {
    final q = <String, dynamic>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    try {
      return _decode(await _api.get('$_base$path', queryParams: q.isEmpty ? null : q));
    } on ApiException catch (e) {
      throw SchoolApiError(e.message, e.statusCode ?? 0);
    }
  }

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, dynamic>? body]) async {
    try {
      final url = '$_base$path';
      final http.Response r;
      switch (method) {
        case 'POST':
          r = await _api.post(url, body: body ?? <String, dynamic>{});
          break;
        case 'PATCH':
          r = await _api.patch(url, body: body ?? <String, dynamic>{});
          break;
        case 'DELETE':
          r = await _api.delete(url);
          break;
        default:
          throw ArgumentError(method);
      }
      return _decode(r);
    } on ApiException catch (e) {
      throw SchoolApiError(e.message, e.statusCode ?? 0);
    }
  }

  static List<Map<String, dynamic>> list(dynamic v) =>
      ((v as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  // ── Super admin ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listSchools({int page = 1, String? search}) =>
      _get('/schools', {'page': page, 'limit': 30, 'search': search});

  /// Returns { school, schoolAdmin, credentials }.
  Future<Map<String, dynamic>> createSchool(Map<String, dynamic> body) => _send('POST', '/schools', body);

  Future<Map<String, dynamic>> deactivateSchool(String schoolId) => _send('DELETE', '/schools/$schoolId');

  Future<Map<String, dynamic>> setMainAdmin(String schoolId, String userId) =>
      _send('PATCH', '/schools/$schoolId/main-admin', {'userId': userId});

  // ── School (use 'me' for the caller's own school) ───────────────────

  Future<Map<String, dynamic>> getSchool([String schoolId = 'me']) async =>
      Map<String, dynamic>.from((await _get('/schools/$schoolId'))['school'] as Map);

  Future<Map<String, dynamic>> updateSchool(String schoolId, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _send('PATCH', '/schools/$schoolId', body))['school'] as Map);

  Future<Map<String, dynamic>> overview([String schoolId = 'me']) => _get('/schools/$schoolId/overview');

  // Terms & billing
  Future<Map<String, dynamic>> terms([String schoolId = 'me']) => _get('/schools/$schoolId/terms');
  Future<Map<String, dynamic>> createTerm(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/terms', body);
  Future<Map<String, dynamic>> updateTerm(String schoolId, String termId, Map<String, dynamic> body) =>
      _send('PATCH', '/schools/$schoolId/terms/$termId', body);
  Future<Map<String, dynamic>> deleteTerm(String schoolId, String termId) => _send('DELETE', '/schools/$schoolId/terms/$termId');

  // Classes
  Future<List<Map<String, dynamic>>> classes([String schoolId = 'me', String? academicYear]) async =>
      list((await _get('/schools/$schoolId/classes', {'academicYear': academicYear}))['classes']);
  Future<Map<String, dynamic>> createClasses(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/classes', body);
  Future<Map<String, dynamic>> classDetail(String classId) => _get('/school/classes/$classId');
  Future<Map<String, dynamic>> updateClass(String classId, Map<String, dynamic> body) => _send('PATCH', '/school/classes/$classId', body);
  Future<Map<String, dynamic>> deleteClass(String classId) => _send('DELETE', '/school/classes/$classId');
  Future<Map<String, dynamic>> addSubjects(String classId, List<Map<String, dynamic>> subjects) =>
      _send('POST', '/school/classes/$classId/subjects', {'subjects': subjects});
  Future<Map<String, dynamic>> updateSubject(String id, Map<String, dynamic> body) => _send('PATCH', '/school/class-subjects/$id', body);
  Future<Map<String, dynamic>> removeSubject(String id) => _send('DELETE', '/school/class-subjects/$id');

  // Staff
  Future<Map<String, dynamic>> staff(String schoolId, {String? role, String? search, String active = 'true'}) =>
      _get('/schools/$schoolId/staff', {'role': role, 'search': search, 'active': active, 'limit': 200});
  /// Returns { user, credentials }.
  Future<Map<String, dynamic>> addTeacher(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/teachers', body);
  Future<Map<String, dynamic>> addSchoolAdmin(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/admins', body);

  // Students
  Future<Map<String, dynamic>> students(String schoolId, {String? classId, String? search, bool unassigned = false, String active = 'true', int page = 1}) =>
      _get('/schools/$schoolId/students', {'classId': classId, 'search': search, 'unassigned': unassigned ? 'true' : null, 'active': active, 'page': page, 'limit': 100});
  Future<List<Map<String, dynamic>>> lookupStudents(String schoolId, String q) async =>
      list((await _get('/schools/$schoolId/students/lookup', {'q': q}))['students']);
  /// Returns { student, credentials: { studentCode, pin }, parents, warnings }.
  /// Throws [SchoolApiError] with code POSSIBLE_DUPLICATE (see [SchoolApiError.candidates]).
  Future<Map<String, dynamic>> addStudent(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/students', body);
  Future<Map<String, dynamic>> importStudents(String schoolId, String classroomId, List<Map<String, dynamic>> rows) =>
      _send('POST', '/schools/$schoolId/students/import', {'classroomId': classroomId, 'students': rows});
  Future<Map<String, dynamic>> enrollStudent(String schoolId, String userId, String classroomId) =>
      _send('POST', '/schools/$schoolId/students/$userId/enroll', {'classroomId': classroomId});

  // Any member
  Future<Map<String, dynamic>> member(String schoolId, String userId) => _get('/schools/$schoolId/members/$userId');
  Future<Map<String, dynamic>> updateMember(String schoolId, String userId, Map<String, dynamic> body) =>
      _send('PATCH', '/schools/$schoolId/members/$userId', body);
  /// Returns { credentials } — a new PIN (students/parents) or password (staff).
  Future<Map<String, dynamic>> resetCredentials(String schoolId, String userId) =>
      _send('POST', '/schools/$schoolId/members/$userId/reset-credentials');

  // Parents
  Future<Map<String, dynamic>> parents([String schoolId = 'me', String? search]) => _get('/schools/$schoolId/parents', {'search': search, 'limit': 200});
  Future<Map<String, dynamic>> resetParentPin(String schoolId, String parentId) => _send('POST', '/schools/$schoolId/parents/$parentId/reset-pin');

  // Head teacher reports
  Future<Map<String, dynamic>> progress([String schoolId = 'me', String? classId]) => _get('/schools/$schoolId/progress', {'classId': classId});
  Future<Map<String, dynamic>> coverage(String schoolId, {String? status, String? classId, String? teacherId, int page = 1}) =>
      _get('/schools/$schoolId/coverage', {'status': status, 'classId': classId, 'teacherId': teacherId, 'page': page});
  Future<Map<String, dynamic>> reviewCoverage(String schoolId, String id, String status, {String? note}) =>
      _send('PATCH', '/schools/$schoolId/coverage/$id', {'status': status, 'note': note});
  Future<Map<String, dynamic>> teacherActivity(String schoolId, String userId, {int days = 30}) =>
      _get('/schools/$schoolId/teachers/$userId/activity', {'days': days});
  Future<Map<String, dynamic>> results(String schoolId, String classId) => _get('/schools/$schoolId/results', {'classId': classId});
  Future<Map<String, dynamic>> signIns(String schoolId, {bool suspiciousOnly = false, String? userId, int page = 1}) =>
      _get('/schools/$schoolId/sign-ins', {'suspicious': suspiciousOnly ? 'true' : null, 'userId': userId, 'page': page});

  // ── "School only" sign-in codes ──────────────────────────────────────

  /// Current class code ([classId]) or school-wide lab code (no classId),
  /// with who signed in with it today.
  Future<Map<String, dynamic>> accessCode({String? classId, String? schoolId}) =>
      _get('/school/access-code', {'classId': classId, 'schoolId': schoolId});

  /// The internet address the server sees for this device (to allow the school network).
  Future<Map<String, dynamic>> myIp() => _get('/school/my-ip');

  // ── Login cards and year-end promotion ───────────────────────────────

  /// New PINs for a class (or chosen students) to print on login cards.
  Future<Map<String, dynamic>> loginCards(String classId, {List<String>? studentIds}) =>
      _send('POST', '/school/classes/$classId/login-cards', {if (studentIds != null) 'studentIds': studentIds});
  Future<Map<String, dynamic>> promotionPreview(String schoolId, {String? fromYear, String? toYear}) =>
      _get('/schools/$schoolId/promotion/preview', {'fromYear': fromYear, 'toYear': toYear});
  Future<Map<String, dynamic>> runPromotion(String schoolId, Map<String, dynamic> body) => _send('POST', '/schools/$schoolId/promotion', body);

  // ── Class groups (school community) ──────────────────────────────────

  Future<List<Map<String, dynamic>>> groups() async => list((await _get('/school/groups'))['groups']);
  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _send('POST', '/school/groups', body))['group'] as Map);
  Future<Map<String, dynamic>> group(String id) async => Map<String, dynamic>.from((await _get('/school/groups/$id'))['group'] as Map);
  Future<Map<String, dynamic>> updateGroup(String id, Map<String, dynamic> body) async =>
      Map<String, dynamic>.from((await _send('PATCH', '/school/groups/$id', body))['group'] as Map);
  Future<void> closeGroup(String id) async => _send('DELETE', '/school/groups/$id');
  /// { messages (oldest→newest), pinned, hasMore, canPost }. Use [after] to poll for new ones.
  Future<Map<String, dynamic>> groupMessages(String id, {String? before, String? after}) =>
      _get('/school/groups/$id/messages', {'before': before, 'after': after});
  Future<Map<String, dynamic>> postGroupMessage(String id, {String? text, List<Map<String, dynamic>> attachments = const [], String? replyTo}) async =>
      Map<String, dynamic>.from((await _send('POST', '/school/groups/$id/messages', {'text': text, 'attachments': attachments, 'replyTo': replyTo}))['message'] as Map);
  Future<void> deleteGroupMessage(String id, String messageId) async => _send('DELETE', '/school/groups/$id/messages/$messageId');
  Future<void> pinGroupMessage(String id, String messageId, bool pinned) async =>
      _send('POST', '/school/groups/$id/messages/$messageId/pin', {'pinned': pinned});

  // ── Teacher portal ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> myTeaching() => _get('/school/teaching/me');
  Future<Map<String, dynamic>> syllabus(String classSubjectId) => _get('/school/teaching/class-subjects/$classSubjectId/syllabus');
  Future<Map<String, dynamic>> markTaught(String classSubjectId, Map<String, dynamic> body) =>
      _send('POST', '/school/teaching/class-subjects/$classSubjectId/coverage', body);
  Future<Map<String, dynamic>> unmarkTaught(String coverageId) => _send('DELETE', '/school/teaching/coverage/$coverageId');
  Future<Map<String, dynamic>> assessments(String classSubjectId) => _get('/school/teaching/class-subjects/$classSubjectId/assessments');
  Future<Map<String, dynamic>> createAssessment(String classSubjectId, Map<String, dynamic> body) =>
      _send('POST', '/school/teaching/class-subjects/$classSubjectId/assessments', body);
  Future<Map<String, dynamic>> assessment(String id) => _get('/school/teaching/assessments/$id');
  Future<Map<String, dynamic>> updateAssessment(String id, Map<String, dynamic> body) => _send('PATCH', '/school/teaching/assessments/$id', body);
  Future<Map<String, dynamic>> deleteAssessment(String id) => _send('DELETE', '/school/teaching/assessments/$id');
  Future<Map<String, dynamic>> grade(String assessmentId, String submissionId, num score, {String? feedback}) =>
      _send('POST', '/school/teaching/assessments/$assessmentId/submissions/$submissionId/grade', {'score': score, 'feedback': feedback});

  // ── Courses offered to schools (super admin) ─────────────────────────

  Future<List<Map<String, dynamic>>> schoolCourses({String search = '', bool onlyMarked = false}) async =>
      list((await _get('/schools-courses', {if (search.isNotEmpty) 'search': search, if (onlyMarked) 'onlyMarked': 'true'}))['courses']);
  Future<Map<String, dynamic>> setCourseSchoolAccess(String courseId, {required bool enabled, required List<String> levels, String subject = ''}) async =>
      Map<String, dynamic>.from((await _send('PATCH', '/schools-courses/$courseId', {'enabled': enabled, 'levels': levels, 'subject': subject}))['course'] as Map);

  // ── Student portal ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> studentHome() => _get('/school/learning/home');
  Future<Map<String, dynamic>> studentAssessment(String id) async =>
      Map<String, dynamic>.from((await _get('/school/learning/assessments/$id'))['assessment'] as Map);
  Future<Map<String, dynamic>> submitAssessment(String id, {String? text, List<Map<String, dynamic>> attachments = const []}) =>
      _send('POST', '/school/learning/assessments/$id/submit', {'text': text, 'attachments': attachments});
  Future<Map<String, dynamic>> checkLesson(String coverageId, bool taught) =>
      _send('POST', '/school/learning/coverage/$coverageId/check', {'taught': taught});

  // ── Parent portal ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> children() async => list((await _get('/school/parent/children'))['children']);
  Future<Map<String, dynamic>> child(String id) => _get('/school/parent/children/$id');
  Future<Map<String, dynamic>> childAssessment(String childId, String id) async =>
      Map<String, dynamic>.from((await _get('/school/parent/children/$childId/assessments/$id'))['assessment'] as Map);
  /// The parent hands in the child's homework (school-only schools: done at home).
  Future<Map<String, dynamic>> submitChildAssessment(String childId, String id, {String? text, List<Map<String, dynamic>> attachments = const []}) =>
      _send('POST', '/school/parent/children/$childId/assessments/$id/submit', {'text': text, 'attachments': attachments});
  /// One-time eexams sign-in link that opens the class exam as the child.
  Future<String> childExamLink(String childId, String id) async =>
      '${(await _send('POST', '/school/parent/children/$childId/assessments/$id/eexams', {}))['url']}';

  // ── Photos (homework, lesson evidence) ───────────────────────────────

  /// Uploads an image and returns an attachment map {url, name, type}.
  /// Works with Firebase and ECH tokens (PIN accounts on desktop too).
  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename, {String mime = 'image/jpeg'}) async {
    final headers = await _api.authHeaders();
    headers.remove('Content-Type');
    final req = http.MultipartRequest('POST', Uri.parse('$_base/upload/image'))
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename, contentType: MediaType.parse(mime)));
    final streamed = await req.send().timeout(const Duration(minutes: 2));
    final r = await http.Response.fromStream(streamed);
    final data = _decode(r);
    final url = (data['imageUrl'] ?? data['signedUrl']) as String?;
    if (url == null) throw SchoolApiError('Upload failed', r.statusCode);
    return {'url': url, 'name': filename, 'type': mime};
  }

  // ── ECH courses (syllabus link for a class subject) ──────────────────

  Future<List<Map<String, dynamic>>> searchCourses(String? search) async =>
      list((await _get('/courses', {'search': search, 'limit': 25}))['courses']);

  // ── PIN account ──────────────────────────────────────────────────────

  Future<void> changePin(String currentPin, String newPin) async {
    await _send('POST', '/auth/pin/change', {'currentPin': currentPin, 'newPin': newPin});
  }
}
