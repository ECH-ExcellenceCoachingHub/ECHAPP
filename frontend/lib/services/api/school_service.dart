import 'dart:convert';

import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';
import '../../models/school.dart';

/// Service for school management: super admin creates schools and plans,
/// school admins manage their teachers and students, teachers add students.
class SchoolService {
  final ApiClient _apiClient;

  SchoolService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Super admin: list all schools with member counts
  Future<SchoolListResponse> getSchools({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _apiClient.get(ApiConfig.schools, queryParams: queryParams);
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final schools = (data['schools'] as List)
          .map((item) => School.fromJson(item as Map<String, dynamic>))
          .toList();

      return SchoolListResponse(
        schools: schools,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch schools: $e');
    }
  }

  /// Get a single school with stats (super admin or member of the school)
  Future<School> getSchool(String schoolId) async {
    try {
      final response = await _apiClient.get(ApiConfig.school(schoolId));
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return School.fromJson(data['school'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch school: $e');
    }
  }

  /// The school of the logged-in school admin / instructor
  Future<School> getMySchool() async {
    try {
      final response = await _apiClient.get('${ApiConfig.schools}/me');
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return School.fromJson(data['school'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch your school: $e');
    }
  }

  /// Super admin: create a school and its school admin user
  Future<SchoolCreatedResult> createSchool(SchoolCreateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.schools, body: request.toJson());
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return SchoolCreatedResult(
        school: School.fromJson(data['school'] as Map<String, dynamic>),
        schoolAdmin: UserMin.fromJson(data['schoolAdmin'] as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create school: $e');
    }
  }

  /// Super admin: update a school's plan and student limit
  Future<School> updateSchoolPlan(String schoolId, SchoolPlanUpdateRequest request) async {
    try {
      final response = await _apiClient.patch(ApiConfig.schoolPlan(schoolId), body: request.toJson());
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return School.fromJson(data['school'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update school plan: $e');
    }
  }

  /// Super admin: delete a school (only when it has no members)
  Future<void> deleteSchool(String schoolId) async {
    try {
      final response = await _apiClient.delete(ApiConfig.school(schoolId));
      response.validateStatus();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete school: $e');
    }
  }

  /// School admin: add a teacher to the school
  Future<UserMin> addTeacher(String schoolId, MemberCreateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.schoolTeachers(schoolId), body: request.toJson());
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return UserMin.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to add teacher: $e');
    }
  }

  /// List teachers of a school
  Future<MemberListResponse> getTeachers({
    required String schoolId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _apiClient.get(ApiConfig.schoolTeachers(schoolId), queryParams: queryParams);
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final members = (data['teachers'] as List)
          .map((item) => UserMin.fromJson(item as Map<String, dynamic>))
          .toList();

      return MemberListResponse(
        members: members,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch teachers: $e');
    }
  }

  /// School admin or teacher: add a student to the school (respects student limit)
  Future<UserMin> addStudent(String schoolId, MemberCreateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.schoolStudents(schoolId), body: request.toJson());
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return UserMin.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to add student: $e');
    }
  }

  /// List students of a school
  Future<MemberListResponse> getStudents({
    required String schoolId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _apiClient.get(ApiConfig.schoolStudents(schoolId), queryParams: queryParams);
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final members = (data['students'] as List)
          .map((item) => UserMin.fromJson(item as Map<String, dynamic>))
          .toList();

      return MemberListResponse(
        members: members,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch students: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}

class SchoolListResponse {
  final List<School> schools;
  final int totalPages;
  final int currentPage;
  final int total;

  SchoolListResponse({
    required this.schools,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}

class SchoolCreatedResult {
  final School school;
  final UserMin schoolAdmin;

  SchoolCreatedResult({required this.school, required this.schoolAdmin});
}

class MemberListResponse {
  final List<UserMin> members;
  final int totalPages;
  final int currentPage;
  final int total;

  MemberListResponse({
    required this.members,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}

/// Minimal user info returned by school member endpoints
class UserMin {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? schoolId;
  final bool? isPrivateStudent;
  final bool isActive;
  final String? firebaseUid;

  UserMin({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.schoolId,
    this.isPrivateStudent,
    this.isActive = true,
    this.firebaseUid,
  });

  factory UserMin.fromJson(Map<String, dynamic> json) {
    return UserMin(
      id: _str(json['id']) ?? _str(json['_id']) ?? '',
      fullName: _str(json['fullName']) ?? 'Unknown User',
      email: _str(json['email']) ?? '',
      phone: _str(json['phone']),
      role: _str(json['role']) ?? 'student',
      schoolId: _str(json['schoolId']),
      isPrivateStudent: json['isPrivateStudent'] == true,
      isActive: json['isActive'] == true,
      firebaseUid: _str(json['firebaseUid']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}
