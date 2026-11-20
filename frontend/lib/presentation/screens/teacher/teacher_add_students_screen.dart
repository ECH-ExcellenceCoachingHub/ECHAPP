import 'dart:async';

import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';

/// Teacher screen: add students to the teacher's own school.
/// Students added here belong to the school and use the school's plan.
class TeacherAddStudentsScreen extends StatefulWidget {
  const TeacherAddStudentsScreen({super.key});

  @override
  State<TeacherAddStudentsScreen> createState() =>
      _TeacherAddStudentsScreenState();
}

class _TeacherAddStudentsScreenState extends State<TeacherAddStudentsScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = false;
  String? _error;
  School? _school;
  List<UserMin> _students = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _schoolService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final school = await _schoolService.getMySchool();
      if (!mounted) return;
      setState(() => _school = school);
      _loadStudents();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_school == null) return;
    try {
      final result = await _schoolService.getStudents(
        schoolId: _school!.id,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _students = result.members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddStudentDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passC = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.getCardColor(context),
        title: Text(
          'Add Student',
          style: TextStyle(color: AppTheme.getTextColor(context)),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.88
              : 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailC,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email, color: AppTheme.primaryGreen),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneC,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.primaryGreen),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryGreen),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    hintText: 'Leave blank to generate',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.getBorderColor(context),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (_school != null && _school!.isFull) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Student limit reached: ${_school!.studentCount}/${_school!.studentLimit}. Ask the school admin to upgrade the plan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getErrorColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (nameC.text.trim().isEmpty || emailC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Name and email are required'),
                    backgroundColor: AppTheme.getErrorColor(context),
                  ),
                );
                return;
              }
              if (_school != null && _school!.isFull) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Student limit reached'),
                    backgroundColor: AppTheme.getErrorColor(context),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await _schoolService.addStudent(
                  _school!.id,
                  MemberCreateRequest(
                    fullName: nameC.text.trim(),
                    email: emailC.text.trim(),
                    phone: phoneC.text.trim().isEmpty
                        ? null
                        : phoneC.text.trim(),
                    password: passC.text.trim().isEmpty
                        ? null
                        : passC.text.trim(),
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Student added successfully'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                  _loadStudents();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.getErrorColor(context),
                    ),
                  );
                }
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = _school;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            AppTheme.primaryGreen,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ??
            Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppTheme.getErrorColor(context)),
                  ),
                )
              : school == null
                  ? Center(
                      child: Text(
                        'Your account is not linked to a school',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.getCardColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.getBorderColor(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.school,
                                        color: AppTheme.primaryGreen, size: 30),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            school.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.getTextColor(context),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Plan: ${school.planLabel}  •  Students: ${school.studentCount}/${school.studentLimit}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.getSecondaryTextColor(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (school.isFull)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'Student limit reached — you cannot add more students until the plan is upgraded.',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: TextStyle(color: AppTheme.getTextColor(context)),
                                    decoration: InputDecoration(
                                      hintText: 'Search students...',
                                      hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppTheme.getBorderColor(context),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _debounce?.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 400), () {
                                        _loadStudents();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                    onPressed:
                                        school.isFull ? null : _showAddStudentDialog,
                                    child: const Text('Add Student'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: _students.isEmpty
                                ? Center(
                                    child: Text(
                                      'No students yet',
                                      style: TextStyle(
                                        color: AppTheme.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _students.length,
                                    itemBuilder: (context, index) {
                                      final m = _students[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 1,
                                        color: AppTheme.getCardColor(context),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                AppTheme.primaryGreen.withOpacity(0.1),
                                            child: Text(
                                                m.fullName.isNotEmpty
                                                    ? m.fullName[0].toUpperCase()
                                                    : '?'),
                                          ),
                                          title: Text(m.fullName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.getTextColor(context),
                                              )),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(m.email,
                                                  style: TextStyle(
                                                      color: AppTheme.getSecondaryTextColor(context))),
                                              if (m.phone != null &&
                                                  m.phone!.isNotEmpty)
                                                Text(m.phone!,
                                                    style: TextStyle(
                                                        color: AppTheme.getSecondaryTextColor(context),
                                                        fontSize: 12)),
                                            ],
                                          ),
                                          trailing: const Chip(
                                            label: Text(
                                              'Student',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor:
                                                Colors.greenAccent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
