import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/admin_account.dart';
import '../infrastructure/api_client.dart';

/// Super admins managing other super admins (`/api/admin/admins`).
class AdminAccountsService {
  final ApiClient _apiClient;

  AdminAccountsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  String get _base => '${ApiConfig.admin}/admins';

  Map<String, dynamic> _data(http.Response response) {
    response.validateStatus();
    final body = response.body.trim();
    if (body.isEmpty) return const {};
    final json = jsonDecode(body);
    final data = json is Map ? json['data'] : null;
    return data is Map<String, dynamic> ? data : const {};
  }

  String _message(http.Response response, String fallback) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['message'] is String) return json['message'] as String;
    } catch (_) {}
    return fallback;
  }

  /// All admins, from MongoDB (the source that carries limits and Mongo ids).
  Future<List<AdminAccount>> list({String? search}) async {
    final response = await _apiClient.get(_base, queryParams: {
      'source': 'mongodb',
      'limit': '200',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final list = _data(response)['admins'];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(AdminAccount.fromJson).toList();
  }

  /// The signed-in admin's own limits (drives which dashboard areas show).
  Future<AdminLimits> myAccess() async {
    final response = await _apiClient.get('${ApiConfig.admin}/my-access');
    return AdminLimits.fromJson(_data(response));
  }

  Future<AdminAccount> updateDetails(String id, {String? fullName, String? email, String? phone}) async {
    final response = await _apiClient.put('$_base/$id', body: {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return AdminAccount.fromJson(_data(response));
  }

  /// Returns the server's confirmation message.
  Future<String> setPassword(String id, String newPassword) async {
    final response = await _apiClient.put('$_base/$id/password', body: {'newPassword': newPassword});
    _data(response);
    return _message(response, 'Password changed');
  }

  Future<AdminAccount> setLimits(String id, AdminLimits limits) async {
    final response = await _apiClient.put('$_base/$id/limits', body: limits.toJson());
    return AdminAccount.fromJson(_data(response));
  }

  Future<AdminAccount> setActive(String id, bool active) async {
    final response = await _apiClient.put('$_base/$id/status', body: {'active': active});
    return AdminAccount.fromJson(_data(response));
  }

  Future<void> delete(String id) async {
    final response = await _apiClient.delete('$_base/$id');
    _data(response);
  }
}
