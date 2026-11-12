import 'dart:convert';

import '../../config/api_config.dart';
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

  Future<void> attachToLesson(String lessonId, String? scenarioId, {bool required = false}) async {
    final res = await _api.put('$_base/lessons/$lessonId/lab', body: {'scenarioId': scenarioId, 'required': required});
    res.validateStatus();
  }
}
