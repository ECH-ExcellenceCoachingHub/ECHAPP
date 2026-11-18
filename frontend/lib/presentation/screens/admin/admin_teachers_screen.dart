import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

/// Admin Teachers Screen - Manage teachers and course assignments
class AdminTeachersScreen extends ConsumerStatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  ConsumerState<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends ConsumerState<AdminTeachersScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  bool _isLoadingCourses = false;
  String? _errorMessage;
  
  List<TeacherData> _teachers = [];
  List<Course> _courses = [];
  
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/admin/teachers?page=$_currentPage&limit=20${_searchQuery != null && _searchQuery!.isNotEmpty ? '&search=${Uri.encodeComponent(_searchQuery!)}' : ''}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final teachers = (data['teachers'] as List)
            .map((t) => TeacherData.fromJson(t))
            .toList();

        setState(() {
          _teachers = teachers;
          _totalPages = data['totalPages'] ?? 1;
          _currentPage = data['currentPage'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading teachers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/courses?limit=100&showUnpublished=true');
      debugPrint('LoadCourses: Status ${response.statusCode}');
      debugPrint('LoadCourses: Body ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonBody['data'];

        List<Course> courses = [];
        if (data is List) {
          // Direct array response
          courses = data.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
        } else if (data is Map<String, dynamic>) {
          // Object with courses property
          final coursesList = data['courses'] as List?;
          if (coursesList != null) {
            courses = coursesList.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
          }
        }

        debugPrint('LoadCourses: Loaded ${courses.length} courses');
        setState(() {
          _courses = courses;
          _isLoadingCourses = false;
        });
      } else {
        debugPrint('LoadCourses: Failed with status ${response.statusCode}');
        setState(() => _isLoadingCourses = false);
      }
    } catch (e, stack) {
      debugPrint('LoadCourses Error: $e');
      debugPrint('LoadCourses Stack: $stack');
      setState(() => _isLoadingCourses = false);
    }
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadTeachers();
  }

  Future<void> _createTeacher() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateTeacherDialog(),
    );

    if (result != null) {
      try {
        final response = await _apiClient.post(
          '${ApiConfig.baseUrl}/admin/teachers',
          body: jsonEncode(result),
        );

        if (response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTeachers();
        } else {
          String errorMsg = 'Failed to create teacher';
          try {
            final body = jsonDecode(response.body);
            errorMsg = body['message'] ?? body['error'] ?? errorMsg;
          } catch (_) {}
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (!mounted) return;
        final errorText = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _editTeacher(TeacherData teacher) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditTeacherDialog(teacher: teacher),
    );

    if (result != null) {
      try {
        final response = await _apiClient.put(
          '${ApiConfig.baseUrl}/admin/teachers/${teacher.id}',
          body: jsonEncode(result),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher updated successfully')),
          );
          _loadTeachers();
        } else {
          throw Exception('Failed to update teacher: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating teacher: $e')),
        );
      }
    }
  }

  Future<void> _deleteTeacher(TeacherData teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Teacher'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${teacher.fullName}?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. The teacher will be removed from the system permanently.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _apiClient.delete('${ApiConfig.baseUrl}/admin/teachers/${teacher.id}');

        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${teacher.fullName} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTeachers();
        } else {
          String errorMsg = 'Failed to delete teacher';
          try {
            final body = jsonDecode(response.body);
            errorMsg = body['message'] ?? body['error'] ?? errorMsg;
          } catch (_) {}
          throw Exception(errorMsg);
        }
      } catch (e) {
        if (!mounted) return;
        final errorText = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _assignCourses(TeacherData teacher) async {
    // Get current assignments
    List<String> assignedCourseIds = [];
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/admin/teachers/${teacher.id}/assignments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final assignments = data['assignments'] as List;
        assignedCourseIds = assignments
            .map((a) => a['course']['_id']?.toString() ?? a['course']['id']?.toString())
            .where((id) => id != null)
            .cast<String>()
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    }

    if (!mounted) return;

    debugPrint('_assignCourses: Opening dialog with ${_courses.length} courses, isLoading: $_isLoadingCourses');

    // Reload courses if empty
    if (_courses.isEmpty && !_isLoadingCourses) {
      debugPrint('_assignCourses: Courses empty, reloading...');
      await _loadCourses();
    }

    if (!mounted) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AssignCoursesDialog(
        courses: _courses,
        assignedCourseIds: assignedCourseIds,
        teacherName: teacher.fullName,
        isLoading: _isLoadingCourses,
        onRefresh: () async {
          debugPrint('AssignCoursesDialog: Manual refresh requested');
          await _loadCourses();
          // Force rebuild of dialog
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );

    if (result != null) {
      // Unassign courses that are no longer selected
      for (final courseId in assignedCourseIds) {
        if (!result.contains(courseId)) {
          try {
            await _apiClient.post(
              '${ApiConfig.baseUrl}/admin/teachers/unassign',
              body: jsonEncode({
                'teacherId': teacher.id,
                'courseId': courseId,
              }),
            );
          } catch (e) {
            debugPrint('Error unassigning course: $e');
          }
        }
      }

      // Assign new courses
      for (final courseId in result) {
        if (!assignedCourseIds.contains(courseId)) {
          try {
            await _apiClient.post(
              '${ApiConfig.baseUrl}/admin/teachers/assign',
              body: jsonEncode({
                'teacherId': teacher.id,
                'courseId': courseId,
              }),
            );
          } catch (e) {
            debugPrint('Error assigning course: $e');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course assignments updated')),
      );
      _loadTeachers();
    }
  }

  Future<void> _resetTeacherPassword(TeacherData teacher) async {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text('Reset Password — ${teacher.fullName}', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setSt(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v != newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/admin/teachers/${teacher.id}',
        body: jsonEncode({
          'resetPassword': true,
          'newPassword': newPasswordController.text,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully for ${teacher.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Failed to reset password';
        throw Exception(msg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewTeacherActivity(TeacherData teacher) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/admin/teachers/${teacher.id}/activity?days=30',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => TeacherActivityDialog(
            teacherName: teacher.fullName,
            activityData: data,
          ),
        );
      } else {
        throw Exception('Failed to load activity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading teacher activity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Create bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teachers...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = null);
                                _loadTeachers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _createTeacher,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _teachers.isEmpty
                        ? _buildEmptyWidget()
                        : _buildTeachersTable(),
          ),

          // Pagination
          if (!_isLoading && _teachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadTeachers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadTeachers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTeachers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery != null
                ? 'No teachers found for "$_searchQuery"'
                : 'No teachers found',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Courses')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _teachers.map((teacher) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text(
                          teacher.fullName.isNotEmpty
                              ? teacher.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(teacher.fullName),
                      if (teacher.teacherStatus != null) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Registered themselves — manage in Teacher Approvals',
                          child: InkWell(
                            onTap: () => context.go('/admin/teacher-approvals'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (teacher.teacherStatus == 'approved' ? Colors.green : teacher.teacherStatus == 'rejected' ? Colors.red : Colors.orange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                switch (teacher.teacherStatus) {
                                  'approved' => 'Self-registered',
                                  'rejected' => 'Rejected',
                                  'pending' => 'Awaiting approval',
                                  _ => 'Profile incomplete',
                                },
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(Text(teacher.email ?? '-')),
                DataCell(Text(teacher.phone ?? '-')),
                DataCell(
                  Chip(
                    label: Text('${teacher.assignedCourseCount}'),
                    backgroundColor: Colors.blue[50],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: teacher.isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      teacher.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: teacher.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTeacher(teacher),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.assignment, color: Colors.orange),
                        onPressed: () => _assignCourses(teacher),
                        tooltip: 'Assign Courses',
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock_reset, color: Colors.orange),
                        onPressed: () => _resetTeacherPassword(teacher),
                        tooltip: 'Reset Password',
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics, color: Colors.purple),
                        onPressed: () => _viewTeacherActivity(teacher),
                        tooltip: 'View Activity',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTeacher(teacher),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Teacher Data class
class TeacherData {
  final String id;
  final String firebaseUid;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;
  final int assignedCourseCount;
  final DateTime? createdAt;
  /// Self-registered teachers only: profile_incomplete | pending | approved | rejected.
  final String? teacherStatus;

  TeacherData({
    required this.id,
    this.firebaseUid = '',
    required this.fullName,
    this.email,
    this.phone,
    this.role = 'instructor',
    this.isActive = true,
    this.assignedCourseCount = 0,
    this.createdAt,
    this.teacherStatus,
  });

  factory TeacherData.fromJson(Map<String, dynamic> json) {
    return TeacherData(
      id: json['_id'] ?? json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'instructor',
      isActive: json['isActive'] ?? true,
      assignedCourseCount: json['assignedCourseCount'] ?? 0,
      teacherStatus: json['teacherStatus'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// Create Teacher Dialog
class CreateTeacherDialog extends StatefulWidget {
  const CreateTeacherDialog({super.key});

  @override
  State<CreateTeacherDialog> createState() => _CreateTeacherDialogState();
}

class _CreateTeacherDialogState extends State<CreateTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _generatePassword = true;
  bool _sendCredentials = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Teacher'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'teacher@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if ((value == null || value.trim().isEmpty) &&
                      (_phoneController.text.trim().isEmpty)) {
                    return 'Email or phone number is required';
                  }
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+250788123456',
                  helperText: 'Use international format starting with +',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              if (!_generatePassword)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (!_generatePassword && (value == null || value.length < 6)) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              CheckboxListTile(
                value: _generatePassword,
                onChanged: (value) => setState(() => _generatePassword = value ?? true),
                title: const Text('Auto-generate password'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _sendCredentials,
                onChanged: (value) => setState(() => _sendCredentials = value ?? false),
                title: const Text('Send credentials via email'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Ensure phone is in E.164 format if provided
              String? phone = _phoneController.text.trim();
              if (phone.isNotEmpty && !phone.startsWith('+')) {
                phone = '+$phone';
              }
              Navigator.pop(context, {
                'fullName': _nameController.text.trim(),
                'email': _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : null,
                'phone': phone.isNotEmpty ? phone : null,
                'password': _generatePassword
                    ? 'AutoGenerated123!'
                    : _passwordController.text,
                'sendCredentials': _sendCredentials,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Edit Teacher Dialog
class EditTeacherDialog extends StatefulWidget {
  final TeacherData teacher;

  const EditTeacherDialog({super.key, required this.teacher});

  @override
  State<EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<EditTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.teacher.fullName);
  late final _emailController = TextEditingController(text: widget.teacher.email ?? '');
  late final _phoneController = TextEditingController(text: widget.teacher.phone ?? '');
  late bool _isActive = widget.teacher.isActive;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Teacher'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Active Account'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'fullName': _nameController.text.trim(),
                'email': _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : null,
                'phone': _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
                'isActive': _isActive,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Assign Courses Dialog
class AssignCoursesDialog extends StatefulWidget {
  final List<Course> courses;
  final List<String> assignedCourseIds;
  final String teacherName;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AssignCoursesDialog({
    super.key,
    required this.courses,
    required this.assignedCourseIds,
    required this.teacherName,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<AssignCoursesDialog> createState() => _AssignCoursesDialogState();
}

class _AssignCoursesDialogState extends State<AssignCoursesDialog> {
  late List<String> _selectedCourseIds = List.from(widget.assignedCourseIds);
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return widget.courses;
    }
    final query = _searchQuery.toLowerCase();
    return widget.courses.where((course) {
      return course.title.toLowerCase().contains(query) ||
          course.level.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _filteredCourses;
    debugPrint('AssignCoursesDialog: courses count = ${widget.courses.length}, isLoading = ${widget.isLoading}');

    return AlertDialog(
      title: Text('Assign Courses to ${widget.teacherName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            // Results count
            Text(
              '${_selectedCourseIds.length} selected • ${filteredCourses.length} of ${widget.courses.length} courses',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            // Course list
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No courses available\n(${widget.courses.length} total loaded)'
                                    : 'No courses found for "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (_searchQuery.isEmpty && widget.onRefresh != null) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: widget.onRefresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reload Courses'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        final isSelected = _selectedCourseIds.contains(course.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCourseIds.add(course.id);
                              } else {
                                _selectedCourseIds.remove(course.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Expanded(child: Text(course.title)),
                              if (!course.isPublished)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Draft',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text('${course.level} • ${course.enrollmentCount} students'),
                          secondary: course.thumbnail != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    mediaProxyUrl(course.thumbnail),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.school, size: 48),
                                  ),
                                )
                              : const Icon(Icons.school, size: 48),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedCourseIds),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Teacher Activity Dialog - Shows teacher performance and activity tracking
class TeacherActivityDialog extends StatelessWidget {
  final String teacherName;
  final Map<String, dynamic> activityData;

  const TeacherActivityDialog({
    super.key,
    required this.teacherName,
    required this.activityData,
  });

  @override
  Widget build(BuildContext context) {
    final overview = activityData['overview'] as Map<String, dynamic>? ?? {};
    final courses = activityData['courses'] as List? ?? [];
    final recentSessions = activityData['recentSessions'] as List? ?? [];
    final dailyActivity = activityData['dailyActivity'] as List? ?? [];
    final teacher = activityData['teacher'] as Map<String, dynamic>? ?? {};

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacherName, style: const TextStyle(fontSize: 18)),
                Text(
                  'Activity Tracking (Last 30 Days)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Stats Grid
              _buildStatsGrid(overview),
              const SizedBox(height: 20),

              // Daily Activity Chart
              if (dailyActivity.isNotEmpty) ...[
                const Text(
                  'Daily Activity (Last 7 Days)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildDailyActivityChart(dailyActivity),
                const SizedBox(height: 20),
              ],

              // Assigned Courses
              if (courses.isNotEmpty) ...[
                const Text(
                  'Assigned Courses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildCoursesList(courses),
                const SizedBox(height: 20),
              ],

              // Recent Sessions
              if (recentSessions.isNotEmpty) ...[
                const Text(
                  'Recent Live Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRecentSessionsList(recentSessions),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> overview) {
    final stats = [
      _StatItem('Courses', overview['totalCourses']?.toString() ?? '0', Colors.blue),
      _StatItem('Students', overview['totalStudents']?.toString() ?? '0', Colors.green),
      _StatItem('Active', overview['activeStudents']?.toString() ?? '0', Colors.orange),
      _StatItem('Sessions', overview['totalSessions']?.toString() ?? '0', Colors.purple),
      _StatItem('Completed', overview['completedSessions']?.toString() ?? '0', Colors.teal),
      _StatItem('Upcoming', overview['upcomingSessions']?.toString() ?? '0', Colors.indigo),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: stats,
    );
  }

  Widget _buildDailyActivityChart(List<dynamic> dailyActivity) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dailyActivity.map((day) {
          final sessions = (day['sessions'] as int?) ?? 0;
          final date = day['date'] as String? ?? '';
          final maxSessions = dailyActivity.fold<int>(
            1,
            (max, d) => math.max(max, (d['sessions'] as int?) ?? 0),
          );
          final height = maxSessions > 0 ? (sessions / maxSessions * 60).toDouble() : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$sessions', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: math.max(height, 4),
                decoration: BoxDecoration(
                  color: sessions > 0 ? AppTheme.primaryGreen : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.split('-').last,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCoursesList(List<dynamic> courses) {
    return Column(
      children: courses.take(5).map((course) {
        final title = course['title'] as String? ?? 'Untitled';
        final level = course['level'] as String? ?? 'N/A';
        final assignedAt = course['assignedAt'] as String?;

        return ListTile(
          dense: true,
          leading: const Icon(Icons.school, color: AppTheme.primaryGreen),
          title: Text(title, style: const TextStyle(fontSize: 13)),
          subtitle: Text('$level • Assigned ${_formatDate(assignedAt)}', style: const TextStyle(fontSize: 11)),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSessionsList(List<dynamic> sessions) {
    return Column(
      children: sessions.take(5).map((session) {
        final title = session['title'] as String? ?? 'Untitled';
        final status = session['status'] as String? ?? 'unknown';
        final scheduledAt = session['scheduledAt'] as String?;
        final duration = session['duration'] as int? ?? 0;

        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'completed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'scheduled':
            statusColor = Colors.blue;
            statusIcon = Icons.schedule;
            break;
          case 'cancelled':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        return ListTile(
          dense: true,
          leading: Icon(statusIcon, color: statusColor, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 13)),
          subtitle: Text('${_formatDate(scheduledAt)} • ${duration}min', style: const TextStyle(fontSize: 11)),
        );
      }).toList(),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
