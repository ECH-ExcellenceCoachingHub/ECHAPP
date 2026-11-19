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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
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
                  decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailC,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneC,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    hintText: 'Leave blank to generate',
                  ),
                  obscureText: true,
                ),
                if (_school != null && _school!.isFull) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Student limit reached: ${_school!.studentCount}/${_school!.studentLimit}. Ask the school admin to upgrade the plan.',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (nameC.text.trim().isEmpty || emailC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and email are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_school != null && _school!.isFull) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student limit reached'),
                    backgroundColor: Colors.red,
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
                    phone: phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                    password: passC.text.trim().isEmpty ? null : passC.text.trim(),
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStudents();
                }
              } catch (e) {
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
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = _school;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : school == null
                  ? const Center(child: Text('Your account is not linked to a school'))
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(16),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Plan: ${school.planLabel}  •  Students: ${school.studentCount}/${school.studentLimit}',
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.grey),
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
                                  decoration: InputDecoration(
                                    hintText: 'Search students...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
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
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen),
                                onPressed:
                                    school.isFull ? null : _showAddStudentDialog,
                                child: const Text('Add Student'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _students.isEmpty
                              ? const Center(child: Text('No students yet'))
                              : ListView.builder(
                                  itemCount: _students.length,
                                  itemBuilder: (context, index) {
                                    final m = _students[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              AppTheme.primaryGreen.withOpacity(0.1),
                                          child: Text(
                                              m.fullName.isNotEmpty
                                                  ? m.fullName[0].toUpperCase()
                                                  : '?'),
                                        ),
                                        title: Text(m.fullName),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(m.email),
                                            if (m.phone != null &&
                                                m.phone!.isNotEmpty)
                                              Text(m.phone!),
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
     );
  }
}
