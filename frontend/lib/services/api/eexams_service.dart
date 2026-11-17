import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';

/// One eexams.net exam result, synced to ECH by the eexams backend.
class EexamsResult {
  final String id;
  final String examTitle;
  final String? level;
  final num score;
  final num maxScore;
  final num percentage;
  final bool? passed;
  final DateTime? completedAt;
  final String? reviewPath;

  const EexamsResult({
    required this.id,
    required this.examTitle,
    this.level,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.passed,
    this.completedAt,
    this.reviewPath,
  });

  factory EexamsResult.fromJson(Map<String, dynamic> j) => EexamsResult(
        id: (j['id'] ?? '').toString(),
        examTitle: (j['examTitle'] ?? 'Exam').toString(),
        level: j['level']?.toString(),
        score: (j['score'] as num?) ?? 0,
        maxScore: (j['maxScore'] as num?) ?? 0,
        percentage: (j['percentage'] as num?) ?? 0,
        passed: j['passed'] as bool?,
        completedAt: j['completedAt'] != null ? DateTime.tryParse(j['completedAt'].toString())?.toLocal() : null,
        reviewPath: j['reviewPath']?.toString(),
      );
}

class EexamsOverview {
  final bool linked;
  final int examsTaken;
  final num? averagePercentage;
  final num? bestPercentage;
  final int passed;
  final List<EexamsResult> results;

  const EexamsOverview({
    required this.linked,
    required this.examsTaken,
    this.averagePercentage,
    this.bestPercentage,
    required this.passed,
    required this.results,
  });

  static const empty = EexamsOverview(linked: false, examsTaken: 0, passed: 0, results: []);

  factory EexamsOverview.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from((j['summary'] as Map?) ?? const {});
    return EexamsOverview(
      linked: j['linked'] == true,
      examsTaken: (s['examsTaken'] as num?)?.toInt() ?? 0,
      averagePercentage: s['averagePercentage'] as num?,
      bestPercentage: s['bestPercentage'] as num?,
      passed: (s['passed'] as num?)?.toInt() ?? 0,
      results: ((j['results'] as List?) ?? const [])
          .map((e) => EexamsResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// eexams.net integration (/api/integrations/eexams): single sign-on + results.
class EexamsService {
  final ApiClient _api;
  EexamsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static String get _base => '${ApiConfig.baseUrl}/integrations/eexams';

  Map<String, dynamic> _data(String body, [int? status]) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] != true) throw ApiException((json['message'] ?? 'Request failed').toString(), status);
    return Map<String, dynamic>.from((json['data'] as Map?) ?? const {});
  }

  Future<EexamsOverview> overview() async {
    final res = await _api.get('$_base/me');
    res.validateStatus();
    return EexamsOverview.fromJson(_data(res.body));
  }

  /// Gets a one-time sign-in link (valid ~60 s) that opens eexams already logged in.
  /// [redirect] is a path on eexams, e.g. `/student/results/<id>`.
  Future<Uri> signInUrl({String redirect = '/'}) async {
    final res = await _api.post('$_base/sso/start', body: {'redirect': redirect});
    return Uri.parse(_data(res.body, res.statusCode)['url'].toString());
  }

  /// Public eexams site, used when a signed-in link can't be created
  /// (not logged in to ECH, offline, or the integration isn't configured).
  static const publicBaseUrl = 'https://www.eexams.net';

  /// Opens eexams signed in as the current ECH user. If that fails, opens the
  /// same page on the public site so the button always does something.
  /// Returns true when the user arrives signed in.
  Future<bool> open({String redirect = '/'}) async {
    Uri url;
    var signedIn = true;
    try {
      url = await signInUrl(redirect: redirect);
    } catch (_) {
      signedIn = false;
      url = Uri.parse('$publicBaseUrl${redirect.startsWith('/') ? redirect : '/'}');
    }
    if (kIsWeb) {
      // New tab; if the browser blocks it (the click → request → open gap), use this tab.
      final opened = await launchUrl(url, webOnlyWindowName: '_blank');
      if (!opened) await launchUrl(url, webOnlyWindowName: '_self');
      return signedIn;
    }
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) throw ApiException('Could not open eexams');
    return signedIn;
  }
}
