import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const AdminStudentsScreen({super.key, this.studentId});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  List<User> _students = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state for student details
  bool _loadingStudentDetail = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    if (widget.studentId != null) {
      // Delay to ensure the screen is built
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadStudentDetail(widget.studentId!);
        }
      });
    }
  }

  void _handleGlobalRefresh() {
    // Refresh all key providers
    // NOTE: We DO NOT invalidate authProvider here because it causes the user to be logged out.
    ref.invalidate(coursesProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(backendCategoriesProvider);
    ref.invalidate(notificationCountProvider);
    ref.invalidate(adminDashboardProvider);
    
    // Also refresh local data
    _loadStudents();
    
    // Show a small feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _loadStudents({String? searchQuery, String? source}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentsData = await _adminService.getStudents(
        page: _currentPage,
        search: searchQuery,
        source: source ?? 'mongodb',
      );
      
      if (!mounted) return;
      setState(() {
        _students = studentsData.students;
        _totalPages = studentsData.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentDetail(String studentId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final studentDetail = await _adminService.getStudentDetail(studentId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Show dialog with student detail
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentDetailModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
            onResetDevice: () => _resetUserDevice(studentDetail.user.id),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student details: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentEnrollments(String studentId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final studentDetail = await _adminService.getStudentDetail(studentId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Show dialog with only enrollments
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentEnrollmentsModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
            studentId: studentId,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student enrollments: $e')),
        );
      }
    }
  }

  Future<void> _loadUserDeviceInfo(String userId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final userDeviceInfo = await _adminService.getUserDeviceInfo(userId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Convert UserDeviceInfo to StudentDetail for compatibility with existing modal
      final studentDetail = StudentDetail(
        user: userDeviceInfo.user,
        enrollments: userDeviceInfo.enrolledCourses,
        examResults: [],
        payments: [],
        totalEnrollments: userDeviceInfo.totalEnrollments,
        completedCourses: userDeviceInfo.enrolledCourses.where((e) => e.completionStatus == 'completed').length,
        inProgressCourses: userDeviceInfo.enrolledCourses.where((e) => e.completionStatus == 'in-progress').length,
        totalSpent: 0.0,
        lastActive: null,
      );
      
      // Show dialog with device info
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentDetailModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
            onResetDevice: () => _resetUserDevice(userId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user device info: $e')),
        );
      }
    }
  }

  Future<void> _resetUserDevice(String userId) async {
    try {
      final result = await _adminService.resetUserDevice(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device reset successfully: ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the student detail
        _loadStudentDetail(userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStudentStatus(User student, bool disabled) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.toggleStudentStatus(student.id, disabled);
      if (!mounted) return;
      
      setState(() {
        _loadingStudentDetail = false;
        // Update the student in the list if found
        final index = _students.indexWhere((s) => s.id == student.id);
        if (index != -1) {
          // We might need to update the User model to include the 'disabled' field
          // For now, we'll just refresh the list
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} ${disabled ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the student list to get updated statuses
        await _loadStudents(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling student status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeactivateDialog(User student) {
    final bool isDeactivating = student.disabled != true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeactivating ? 'Deactivate Account' : 'Activate Account'),
        content: Text('Are you sure you want to ${isDeactivating ? 'deactivate' : 'activate'} ${student.fullName}\'s account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleStudentStatus(student, isDeactivating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : AppTheme.primaryGreen
            ),
            child: Text(isDeactivating ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(User student) {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Reset Password - ${student.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a new temporary password for this student. The student will be required to change it on next login.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a new password')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }

                setState(() => isLoading = true);
                
                try {
                  await _resetStudentPassword(student.id, newPasswordController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error resetting password: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(User student) {
    final nameController = TextEditingController(text: student.fullName);
    final emailController = TextEditingController(text: student.email);
    final phoneController = TextEditingController(text: student.phone ?? '');
    String selectedRole = student.role;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edit — ${student.fullName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: student.profilePicture != null && student.profilePicture!.isNotEmpty
                          ? ClipOval(
                              child: NetworkImageWidget(
                                imageUrl: student.profilePicture!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorWidget: Text(
                                  (student.fullName.isNotEmpty ? student.fullName.substring(0, 1) : '?').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              (student.fullName.isNotEmpty ? student.fullName.substring(0, 1) : '?').toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+250...',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Full name cannot be empty')),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await _adminService.updateStudent(
                          student.id,
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim().isNotEmpty
                              ? emailController.text.trim()
                              : null,
                          phone: phoneController.text.trim(),
                          role: selectedRole,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${nameController.text.trim()} updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadStudents(searchQuery: _searchController.text);
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(User student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: 'Are you sure you want to permanently delete '),
              TextSpan(
                text: student.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\'s account?\n\n'),
              const TextSpan(
                text: 'This action will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\n• User account\n• All enrollments\n• Payment records\n• Exam results\n\n'),
              const TextSpan(
                text: 'This action cannot be undone!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(student);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetStudentPassword(String studentId, String newPassword) async {
    try {
      await _adminService.resetStudentPassword(studentId, newPassword);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> _deleteStudent(User student) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.deleteStudent(student.id);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
        // Remove the deleted student from the list
        _students.removeWhere((s) => s.id == student.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the student list
        await _loadStudents(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchStudents(String query) {
    _currentPage = 1;
    _loadStudents(searchQuery: query, source: 'mongodb');
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadStudents(searchQuery: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: (context.canPop() || GoRouterState.of(context).uri.path != '/admin') 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin');
                }
              },
              tooltip: 'Back',
            ) 
          : null,
        title: const Text('Student Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStudents(),
            tooltip: 'Refresh Students',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/admin/analytics'),
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage and monitor all students on the platform',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    onChanged: _searchStudents,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchStudents('');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Students list
            Expanded(
              child: _isLoading && _students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentsList(),
            ),
            
            // Pagination
            if (_totalPages > 1)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.people,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _searchController.text.isEmpty 
              ? 'No students have registered yet' 
              : 'No students match your search criteria',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: student.profilePicture != null && student.profilePicture!.isNotEmpty
                  ? ClipOval(
                      child: NetworkImageWidget(
                        imageUrl: student.profilePicture!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: Text(
                          (student.fullName.isNotEmpty ? student.fullName.substring(0, 1) : '?').toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      (student.fullName.isNotEmpty ? student.fullName.substring(0, 1) : '?').toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  student.email,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                if (student.phone != null && student.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          student.phone!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: student.role == 'admin' 
                            ? AppTheme.primaryGreen.withOpacity(0.2) 
                            : AppTheme.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.role.toUpperCase(),
                        style: TextStyle(
                          color: student.role == 'admin' 
                              ? AppTheme.primaryGreen 
                              : AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (student.disabled == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DISABLED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.greyColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Joined: ${_formatDate(student.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppTheme.greyColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student.deviceId != null && student.deviceId!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.devices,
                        size: 16,
                        color: Colors.green,
                      ),
                    ] else ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.phonelink_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: AppTheme.primaryGreen),
                  onPressed: () => _loadStudentDetail(student.id),
                  tooltip: 'View Details',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _loadStudentDetail(student.id);
                        break;
                      case 'edit_info':
                        _showEditStudentDialog(student);
                        break;
                      case 'enrollments':
                        _loadStudentEnrollments(student.id);
                        break;
                      case 'device_info':
                        _loadUserDeviceInfo(student.id); // student.id is the MongoDB _id
                        break;
                      case 'toggle_status':
                        _showDeactivateDialog(student);
                        break;
                      case 'reset_password':
                        _showPasswordResetDialog(student);
                        break;
                      case 'delete':
                        _showDeleteConfirmationDialog(student);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: AppTheme.primaryGreen),
                          SizedBox(width: 10),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_info',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.primaryGreen),
                          SizedBox(width: 10),
                          Text('Edit Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'enrollments',
                      child: Row(
                        children: [
                          Icon(Icons.school, color: AppTheme.accent),
                          SizedBox(width: 10),
                          Text('View Enrollments'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'device_info',
                      child: Row(
                        children: [
                          Icon(Icons.devices, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('View Device Info'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            (student.disabled == true) ? Icons.check_circle : Icons.block, 
                            color: (student.disabled == true) ? Colors.green : Colors.orange
                          ),
                          const SizedBox(width: 10),
                          Text((student.disabled == true) ? 'Activate Account' : 'Deactivate Account'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.password, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Reset Password'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete Student'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
        ),
        Text('Page $_currentPage of $_totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminService.dispose();
    super.dispose();
  }


}

/// Label for enrollments the learner left or an admin suspended, with the date.
Widget _enrollmentLifecycleBadge(Enrollment enrollment, String Function(DateTime) formatDate) {
  final suspended = enrollment.isSuspended;
  final date = suspended ? enrollment.suspendedAt : enrollment.unenrolledAt;
  final label = suspended ? 'Suspended' : 'Unenrolled by learner';
  final color = suspended ? Colors.amber.shade800 : Colors.blueGrey;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
      if (date != null) ...[
        const SizedBox(width: 6),
        Text(formatDate(date), style: const TextStyle(fontSize: 11, color: AppTheme.greyColor)),
      ],
    ],
  );
}

// Student Enrollments Modal Widget
class StudentEnrollmentsModal extends StatefulWidget {
  final StudentDetail studentDetail;
  final VoidCallback onClose;
  final bool isLoading;
  final String studentId;

  const StudentEnrollmentsModal({
    super.key,
    required this.studentDetail,
    required this.onClose,
    required this.isLoading,
    required this.studentId,
  });

  @override
  State<StudentEnrollmentsModal> createState() => _StudentEnrollmentsModalState();
}

class _StudentEnrollmentsModalState extends State<StudentEnrollmentsModal> {
  final AdminService _adminService = AdminService();
  bool _isUnenrolling = false;
  bool _isUpdatingStatus = false;

  Future<void> _toggleSuspension(Enrollment enrollment) async {
    final suspend = !enrollment.isSuspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspend ? 'Suspend access?' : 'Reinstate access?'),
        content: Text(suspend
            ? 'The student will temporarily lose access to "${_getCourseTitle(enrollment)}". Their progress is kept and you can reinstate them at any time.'
            : 'The student will regain access to "${_getCourseTitle(enrollment)}" with their progress intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(suspend ? 'Suspend' : 'Reinstate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await _adminService.updateEnrollmentStatus(enrollment.id, suspend ? 'suspended' : 'active');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(suspend ? 'Access suspended' : 'Access reinstated'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading student enrollments...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: widget.studentDetail.user.profilePicture != null && widget.studentDetail.user.profilePicture!.isNotEmpty
                        ? ClipOval(
                            child: NetworkImageWidget(
                              imageUrl: widget.studentDetail.user.profilePicture!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: Text(
                                (widget.studentDetail.user.fullName.isNotEmpty ? widget.studentDetail.user.fullName.substring(0, 1) : '?').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            (widget.studentDetail.user.fullName.isNotEmpty ? widget.studentDetail.user.fullName.substring(0, 1) : '?').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Enrollments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.studentDetail.user.fullName} - ${widget.studentDetail.enrollments.length} Courses',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Total Enrollments',
                          widget.studentDetail.totalEnrollments.toString(),
                          Icons.school,
                          AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          context,
                          'Completed',
                          widget.studentDetail.completedCourses.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          context,
                          'In Progress',
                          widget.studentDetail.inProgressCourses.toString(),
                          Icons.timelapse,
                          AppTheme.accent,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Enrollments Section
                    _buildEnrollmentsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enrolled Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (widget.studentDetail.enrollments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No course enrollments found',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ...widget.studentDetail.enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCourseTitle(enrollment),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(enrollment.completionStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enrollment.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(enrollment.completionStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Progress: ${enrollment.progressDisplay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Enrolled: ${_formatDateSimple(enrollment.enrollmentDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        if (!enrollment.isActiveEnrollment) ...[
                          const SizedBox(height: 4),
                          _enrollmentLifecycleBadge(enrollment, _formatDateSimple),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RWF ${enrollment.course?.price ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings, color: AppTheme.primaryGreen, size: 18),
                            onPressed: () => _showEnrollmentPermissionsDialog(context, enrollment),
                            tooltip: 'Manage permissions',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (!enrollment.isUnenrolled) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                enrollment.isSuspended
                                    ? Icons.play_circle_outline
                                    : Icons.pause_circle_outline,
                                color: Colors.amber.shade800,
                                size: 18,
                              ),
                              onPressed: _isUpdatingStatus
                                  ? null
                                  : () => _toggleSuspension(enrollment),
                              tooltip: enrollment.isSuspended ? 'Reinstate access' : 'Suspend access',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                          const SizedBox(width: 4),
                          IconButton(
                            icon: _isUnenrolling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                            onPressed: _isUnenrolling
                                ? null
                                : () => _showUnenrollConfirmation(context, enrollment),
                            tooltip: 'Unenroll from course',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _getCourseTitle(Enrollment enrollment) {
    // Try to get the title from the populated course object
    if (enrollment.course != null && 
        enrollment.course!.title.isNotEmpty && 
        enrollment.course!.title != 'Untitled Course' &&
        enrollment.course!.title != 'Unknown Course') {
      return enrollment.course!.title;
    }
    
    // If the course object wasn't properly populated, check if there's course data in the raw enrollment object
    // Sometimes the course data might be in a different format
    if (enrollment.courseId.isNotEmpty && enrollment.courseId != '') {
      // Use courseId as fallback, though ideally we'd have the course title
      return 'Course ID: ${enrollment.courseId}';
    }
    
    // If the course object wasn't properly populated, return a default value
    // The backend might not have populated the course details
    return 'Course Title Unknown';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return AppTheme.accent;
      case 'enrolled':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDateSimple(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUnenrollConfirmation(BuildContext context, Enrollment enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll Student'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: 'Are you sure you want to unenroll '),
              TextSpan(
                text: widget.studentDetail.user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' from '),
              TextSpan(
                text: _getCourseTitle(enrollment),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\n\n'),
              const TextSpan(
                text: 'This action will:\n• Remove the enrollment\n• Delete associated certificate\n• Remove payment records\n\nThis action cannot be undone!',
                style: TextStyle(color: Colors.red),
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
            onPressed: () {
              Navigator.pop(context);
              _unenrollStudent(enrollment);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _unenrollStudent(Enrollment enrollment) async {
    setState(() {
      _isUnenrolling = true;
    });

    try {
      await _adminService.unenrollStudent(
        enrollment.courseId,
        widget.studentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student unenrolled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Close the modal to refresh the data
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unenrolling student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnenrolling = false;
        });
      }
    }
  }

  void _showEnrollmentPermissionsDialog(BuildContext context, Enrollment enrollment) {
    bool canAccessLiveSessions = enrollment.canAccessLiveSessions;
    bool canAccessChapters = enrollment.canAccessChapters;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.settings, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permissions - ${_getCourseTitle(enrollment)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.canAccessLiveSessions),
                subtitle: Text(AppLocalizations.of(context)!.canAccessLiveSessionsDescription),
                value: canAccessLiveSessions,
                onChanged: isLoading ? null : (value) {
                  setDialogState(() => canAccessLiveSessions = value);
                },
                activeColor: AppTheme.primaryGreen,
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.canAccessChapters),
                subtitle: Text(AppLocalizations.of(context)!.canAccessChaptersDescription),
                value: canAccessChapters,
                onChanged: isLoading ? null : (value) {
                  setDialogState(() => canAccessChapters = value);
                },
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                try {
                  await _adminService.updateEnrollmentPermissions(
                    enrollment.id,
                    canAccessLiveSessions: canAccessLiveSessions,
                    canAccessChapters: canAccessChapters,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Permissions updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onClose();
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adminService.dispose();
    super.dispose();
  }
}

// Student Detail Modal Widget
class StudentDetailModal extends StatelessWidget {
  final StudentDetail studentDetail;
  final VoidCallback onClose;
  final bool isLoading;
  final VoidCallback? onResetDevice;

  const StudentDetailModal({
    super.key,
    required this.studentDetail,
    required this.onClose,
    required this.isLoading,
    this.onResetDevice,
  });

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'No data';
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading student details...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: studentDetail.user.profilePicture != null && studentDetail.user.profilePicture!.isNotEmpty
                        ? ClipOval(
                            child: NetworkImageWidget(
                              imageUrl: studentDetail.user.profilePicture!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: Text(
                                (studentDetail.user.fullName.isNotEmpty ? studentDetail.user.fullName.substring(0, 1) : '?').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            (studentDetail.user.fullName.isNotEmpty ? studentDetail.user.fullName.substring(0, 1) : '?').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentDetail.user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          studentDetail.user.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (studentDetail.user.phone != null && studentDetail.user.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                studentDetail.user.phone!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(context),
                    
                    const SizedBox(height: 20),
                    
                    // Enrollments Section
                    _buildEnrollmentsSection(context),
                    
                    const SizedBox(height: 20),
                    
                    // Activity Timeline
                    _buildActivityTimeline(context),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Request Section
                    _buildPaymentRequestSection(context),
                    
                    const SizedBox(height: 20),
                    
                    // Device Info Section
                    _buildDeviceInfoSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRequestSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final paymentState = ref.watch(paymentProvider);
        final paymentNotifier = ref.read(paymentProvider.notifier);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Request Payment for Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Initiate a payment request on behalf of this student for any course. The student will be notified to complete the payment process.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: paymentState.isProcessing 
                          ? null 
                          : () => _showPaymentRequestDialog(context, ref, studentDetail.user.id, paymentNotifier),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(paymentState.isProcessing ? 'Processing...' : 'Request Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.greyColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Binding Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty 
                    ? 'Bound to device'
                    : 'Not bound to device',
                style: TextStyle(
                  color: studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty ? Colors.green : Colors.orange,
                ),
              ),
              if (studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Device ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  studentDetail.user.deviceId!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
              if (onResetDevice != null) ...[
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onResetDevice,
                  icon: const Icon(Icons.sync_problem, size: 16),
                  label: const Text('Reset Device Binding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCards(BuildContext context) {
    return Column(
      children: [
        // First row - existing cards
        Row(
          children: [
            _buildStatCard(
              context,
              'Total Enrollments',
              studentDetail.totalEnrollments.toString(),
              Icons.school,
              AppTheme.primaryGreen,
            ),
            const SizedBox(width: 15),
            _buildStatCard(
              context,
              'Completed',
              studentDetail.completedCourses.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(width: 15),
            _buildStatCard(
              context,
              'In Progress',
              studentDetail.inProgressCourses.toString(),
              Icons.timelapse,
              AppTheme.accent,
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Second row - time spent card
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Time Spent in App',
                _formatDuration(studentDetail.timeSpentInApp),
                Icons.access_time,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Enrollments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (studentDetail.enrollments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No course enrollments found',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ...studentDetail.enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.course?.title ?? 'Unknown Course',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(enrollment.completionStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enrollment.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(enrollment.completionStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Progress: ${enrollment.progressDisplay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Enrolled: ${_formatDateSimple(enrollment.enrollmentDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        if (!enrollment.isActiveEnrollment) ...[
                          const SizedBox(height: 4),
                          _enrollmentLifecycleBadge(enrollment, _formatDateSimple),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'RWF ${enrollment.course?.price ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActivityTimeline(BuildContext context) {
    final List<Map<String, dynamic>> activities = [];
    
    // Add enrollments to activities
    for (var enrollment in studentDetail.enrollments) {
      activities.add({
        'type': 'enrollment',
        'title': 'Enrolled in Course',
        'subtitle': enrollment.course?.title ?? 'Unknown Course',
        'date': enrollment.enrollmentDate,
        'icon': Icons.school,
        'color': AppTheme.primaryGreen,
      });
    }
    
    // Add payments to activities
    for (var payment in studentDetail.payments) {
      final date = payment['paymentDate'] != null 
          ? DateTime.parse(payment['paymentDate'].toString())
          : (payment['createdAt'] != null ? DateTime.parse(payment['createdAt'].toString()) : DateTime.now());
      
      activities.add({
        'type': 'payment',
        'title': 'Payment Completed',
        'subtitle': 'RWF ${payment['amount']} for ${payment['courseId']?['title'] ?? 'a course'}',
        'date': date,
        'icon': Icons.payment,
        'color': Colors.blue,
      });
    }
    
    // Add exam results to activities
    for (var result in studentDetail.examResults) {
      final date = result['submittedAt'] != null 
          ? DateTime.parse(result['submittedAt'].toString())
          : DateTime.now();
      
      final bool passed = result['passed'] == true;
      
      activities.add({
        'type': 'exam',
        'title': passed ? 'Exam Passed' : 'Exam Failed',
        'subtitle': '${result['examId']?['title'] ?? 'Unknown Exam'} - Score: ${result['score']}/${result['totalPoints']}',
        'date': date,
        'icon': passed ? Icons.check_circle : Icons.cancel,
        'color': passed ? Colors.green : Colors.red,
      });
    }
    
    // Sort by date newest first
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No recent activity recorded',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 16,
                          ),
                        ),
                        if (index < (activities.length > 5 ? 4 : activities.length - 1))
                          Container(
                            width: 2,
                            height: 30,
                            color: AppTheme.greyColor.withOpacity(0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                activity['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDateSimple(activity['date'] as DateTime),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.greyColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return AppTheme.accent;
      case 'enrolled':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.greyColor;
    }
  }

  void _showPaymentRequestDialog(BuildContext context, WidgetRef ref, String userId, PaymentStateNotifier paymentNotifier) {
    // Get all courses by reading the courses provider
    final coursesAsyncValue = ref.watch(coursesProvider);
    
    coursesAsyncValue.when(
      data: (courses) {
        final paidCourses = courses.where((course) => (course.price ?? 0) > 0).toList();
        
        if (paidCourses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No paid courses available for payment requests'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        _showPaymentRequestDialogWithData(context, ref, userId, paymentNotifier, paidCourses);
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading courses...'),
            backgroundColor: Colors.blue,
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
  
  void _showPaymentRequestDialogWithData(BuildContext context, WidgetRef ref, String userId, PaymentStateNotifier paymentNotifier, List<Course> paidCourses) {

    // Debug: Print all available courses
    print('=== AVAILABLE COURSES DEBUG ===');
    for (int i = 0; i < paidCourses.length; i++) {
      final course = paidCourses[i];
      print('Course ${i + 1}: ID=${course.id}, Title="${course.title}", Price=${course.price}');
    }

    final paymentMethodController = TextEditingController(text: 'mtn_momo');
    final contactInfoController = TextEditingController(text: studentDetail.user.phone ?? '');
    
    // Initialize state variables outside StatefulBuilder to prevent re-initialization
    String? selectedCourseId = paidCourses.isNotEmpty ? paidCourses.first.id : null;
    String? selectedPaymentMethod = 'mtn_momo';
    
    // Debug: Track initial selection
    print('Initial selectedCourseId: $selectedCourseId');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          
          return AlertDialog(
            title: const Text('Request Payment'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student: ${studentDetail.user.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Course Selection
                  const Text(
                    'Select Course:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourseId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a course',
                    ),
                    items: paidCourses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'RWF ${course.price}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourseId = value;
                        print('Course selected: $value');
                        print('Updated selectedCourseId in setState: $selectedCourseId');
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Debug info - show selected course
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Selected Course ID: $selectedCourseId',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Payment Method
                  const Text(
                    'Payment Method:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPaymentMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select payment method',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'mtn_momo', child: Text('MTN Mobile Money')),
                      DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Info
                  const Text(
                    'Contact Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contactInfoController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter phone number or contact details',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final paymentState = ref.watch(paymentProvider);
                  
                  return ElevatedButton(
                    onPressed: paymentState.isProcessing || selectedCourseId == null
                        ? null
                        : () async {
                            try {
                              print('=== SUBMISSION DEBUG ===');
                              print('selectedCourseId before submission: $selectedCourseId');
                              print('selectedPaymentMethod before submission: $selectedPaymentMethod');
                              print('contactInfo before submission: ${contactInfoController.text.trim()}');
                              
                              await paymentNotifier.adminInitiatePayment(
                                userId: userId,
                                courseId: selectedCourseId!,
                                paymentMethod: selectedPaymentMethod!,
                                contactInfo: contactInfoController.text.trim(),
                              );
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment request initiated successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to initiate payment: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    child: paymentState.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Request Payment'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateSimple(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

}