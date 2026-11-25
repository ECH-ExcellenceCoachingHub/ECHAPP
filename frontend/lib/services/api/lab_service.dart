import 'dart:convert';

import '../../config/api_config.dart';
import '../../models/lab_project.dart';
import '../../models/lab_scenario.dart';
import '../infrastructure/api_client.dart';

/// Virtual labs API (/api/labs).
class LabService {
  final ApiClient _api;
  LabService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static String get _base => '${ApiConfig.baseUrl}/labs';

  Map<String, dynamic> _data(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] != true) throw ApiException((json['message'] ?? 'Request failed').toString());
    return json;
  }

  Future<List<LabScenario>> listScenarios({String? subject}) async {
    final res = await _api.get('$_base/scenarios', queryParams: {if (subject != null) 'subject': subject});
    res.validateStatus();
    final list = _data(res.body)['data'] as List;
    return list.map((e) => LabScenario.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<LabScenario> getScenario(String idOrSlug) async {
    final res = await _api.get('$_base/scenarios/$idOrSlug');
    res.validateStatus();
    return LabScenario.fromJson(Map<String, dynamic>.from(_data(res.body)['data'] as Map));
  }

  /// Mints a short-lived lab token for the Unity engine.
  Future<LabSessionTicket> startSession({required String scenarioId, String? lessonId, String lang = 'en'}) async {
    final res = await _api.post('$_base/session', body: {'scenarioId': scenarioId, if (lessonId != null) 'lessonId': lessonId, 'lang': lang});
    res.validateStatus();
    return LabSessionTicket.fromJson(Map<String, dynamic>.from(_data(res.body)['data'] as Map));
  }

  Future<LabSummary> summary() async {
    final res = await _api.get('$_base/me/summary');
    res.validateStatus();
    return LabSummary.fromJson(Map<String, dynamic>.from(_data(res.body)['data'] as Map));
  }

  /// Links a VR headset showing [code] to this student (optionally opening a lab directly).
  Future<String> confirmHeadset(String code, {String? scenarioId, String? lessonId}) async {
    final res = await _api.post('$_base/pair/confirm', body: {'code': code, if (scenarioId != null) 'scenarioId': scenarioId, if (lessonId != null) 'lessonId': lessonId});
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || json['success'] != true) throw ApiException((json['message'] ?? 'Could not connect the headset').toString(), res.statusCode);
    return ((json['data'] as Map?)?['deviceName'] ?? 'VR headset').toString();
  }

  /// Teacher/admin: AI builds a lab draft from a lesson (needs review before publishing).
  Future<LabScenario> generateForLesson(String lessonId) async {
    final res = await _api.post('$_base/scenarios/generate', body: {'lessonId': lessonId});
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || json['success'] != true) throw ApiException((json['message'] ?? 'Generation failed').toString(), res.statusCode);
    return LabScenario.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }

  // ─── Student "My experiments" ───────────────────────────────────────────────

  Map<String, dynamic> _projectData(dynamic res) {
    final json = jsonDecode(res.body as String) as Map<String, dynamic>;
    if (res.statusCode >= 400 || json['success'] != true) {
      final err = json['error'];
      final errors = err is List ? [for (final e in err) e.toString()] : (err is Map && err['errors'] is List ? [for (final e in err['errors'] as List) e.toString()] : <String>[]);
      if (res.statusCode == 422 && errors.isNotEmpty) throw LabProjectInvalid((json['message'] ?? 'Your experiment needs a few fixes').toString(), errors);
      throw ApiException((json['message'] ?? 'Request failed').toString(), res.statusCode as int);
    }
    return json;
  }

  Future<LabKit> projectKit() async => LabKit.fromJson(Map<String, dynamic>.from(_projectData(await _api.get('$_base/projects/kit'))['data'] as Map));

  Future<List<LabProject>> myProjects() async {
    final list = _projectData(await _api.get('$_base/projects'))['data'] as List;
    return [for (final p in list) LabProject.fromJson(Map<String, dynamic>.from(p as Map))];
  }

  /// The card plus the editable `spec`.
  Future<(LabProject, Map<String, dynamic>)> getProject(String id) async {
    final d = Map<String, dynamic>.from(_projectData(await _api.get('$_base/projects/$id'))['data'] as Map);
    return (LabProject.fromJson(d), Map<String, dynamic>.from(d['spec'] as Map));
  }

  Future<LabProject> saveProject(Map<String, dynamic> spec, {String? id, String? remixOf}) async {
    final body = {'spec': spec, if (remixOf != null) 'remixOf': remixOf};
    final res = id == null ? await _api.post('$_base/projects', body: body) : await _api.put('$_base/projects/$id', body: body);
    return LabProject.fromJson(Map<String, dynamic>.from(_projectData(res)['data'] as Map));
  }

  /// Compile without saving. Returns the problems (empty = ready to run).
  Future<List<String>> checkProject(Map<String, dynamic> spec) async {
    final d = Map<String, dynamic>.from(_projectData(await _api.post('$_base/projects/check', body: {'spec': spec}))['data'] as Map);
    return [for (final e in (d['errors'] as List? ?? const [])) e.toString()];
  }

  Future<void> deleteProject(String id) async => _projectData(await _api.delete('$_base/projects/$id'));

  Future<LabProject> shareProject(String id, {bool share = true}) async =>
      LabProject.fromJson(Map<String, dynamic>.from(_projectData(await _api.post('$_base/projects/$id/share', body: {'share': share}))['data'] as Map));

  Future<void> saveConclusion(String id, String conclusion) async => _projectData(await _api.patch('$_base/projects/$id/conclusion', body: {'conclusion': conclusion}));

  /// An existing lab as an editable spec ("Remix").
  Future<(Map<String, dynamic>, String)> remixSpec(String scenarioId) async {
    final d = Map<String, dynamic>.from(_projectData(await _api.get('$_base/projects/remix/$scenarioId'))['data'] as Map);
    return (Map<String, dynamic>.from(d['spec'] as Map), d['remixOf'].toString());
  }

  /// AI drafts a spec from the student's idea (not saved).
  Future<Map<String, dynamic>> projectFromIdea(String environment, String idea) async {
    final d = Map<String, dynamic>.from(_projectData(await _api.post('$_base/projects/from-idea', body: {'environment': environment, 'idea': idea}))['data'] as Map);
    return Map<String, dynamic>.from(d['spec'] as Map);
  }

  Future<void> attachToLesson(String lessonId, String? scenarioId, {bool required = false}) async {
    final res = await _api.put('$_base/lessons/$lessonId/lab', body: {'scenarioId': scenarioId, 'required': required});
    res.validateStatus();
  }
}
