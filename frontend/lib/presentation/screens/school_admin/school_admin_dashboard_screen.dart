import 'dart:async';

import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/widgets/school_admin_layout_wrapper.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';

/// School admin dashboard: view the school's plan/student limit and manage
/// the school's teachers and students.
class SchoolAdminDashboardScreen extends StatefulWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  State<SchoolAdminDashboardScreen> createState() =>
      _SchoolAdminDashboardScreenState();
}

class _SchoolAdminDashboardScreenState
    extends State<SchoolAdminDashboardScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  String? _error;
  School? _school;
  int _tabIndex = 0; // 0 = overview, 1 = teachers, 2 = students

  final TextEditingController _teacherSearch = TextEditingController();
  final TextEditingController _studentSearch = TextEditingController();
  List<MemberItem> _teachers = [];
  List<MemberItem> _students = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _teacherSearch.dispose();
    _studentSearch.dispose();
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
      _loadMembers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    if (_school == null) return;
    try {
      final teachers = await _schoolService.getTeachers(
        schoolId: _school!.id,
        search: _teacherSearch.text,
      );
      final students = await _schoolService.getStudents(
        schoolId: _school!.id,
        search: _studentSearch.text,
      );
      if (!mounted) return;
      setState(() {
        _teachers = teachers.members
            .map((m) => MemberItem(
                  id: m.id,
                  fullName: m.fullName,
                  email: m.email,
                  phone: m.phone,
                  role: m.role,
                  isActive: m.isActive,
                ))
            .toList();
        _students = students.members
            .map((m) => MemberItem(
                  id: m.id,
                  fullName: m.fullName,
                  email: m.email,
                  phone: m.phone,
                  role: m.role,
                  isActive: m.isActive,
                ))
            .toList();
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

  void _showAddMemberDialog({required bool isTeacher}) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isTeacher ? 'Add Teacher' : 'Add Student',
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.88
              : 420,
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
                if (!isTeacher && _school != null && _school!.isFull) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Student limit reached: ${_school!.studentCount}/${_school!.studentLimit}. Upgrade the plan to add more students.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
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
              if (!isTeacher && _school != null && _school!.isFull) {
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
                if (isTeacher) {
                  await _schoolService.addTeacher(
                    _school!.id,
                    MemberCreateRequest(
                      fullName: nameC.text.trim(),
                      email: emailC.text.trim(),
                      phone: phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                      password: passC.text.trim().isEmpty ? null : passC.text.trim(),
                    ),
                  );
                } else {
                  await _schoolService.addStudent(
                    _school!.id,
                    MemberCreateRequest(
                      fullName: nameC.text.trim(),
                      email: emailC.text.trim(),
                      phone: phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                      password: passC.text.trim().isEmpty ? null : passC.text.trim(),
                    ),
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${isTeacher ? 'Teacher' : 'Student'} added successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadMembers();
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
            child: Text(isTeacher ? 'Add Teacher' : 'Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = _school;

    return SchoolAdminLayoutWrapper(
      screenName: 'School Admin Dashboard',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('School Admin'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : school == null
                    ? const Center(child: Text('No school found for your account'))
                    : Column(
                        children: [
                          _SchoolHeader(school: school),
                          const SizedBox(height: 16),
                          _TabBar(
                            index: _tabIndex,
                            onChanged: (i) => setState(() => _tabIndex = i),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _tabIndex == 0
                                ? _OverviewTab(school: school)
                                : _tabIndex == 1
                                    ? _TeachersTab(
                                        school: school,
                                        members: _teachers,
                                        onAdd: () =>
                                            _showAddMemberDialog(isTeacher: true),
                                        onSearch: (v) {
                                          _debounce?.cancel();
                                          _debounce = Timer(
                                            const Duration(milliseconds: 400),
                                            () => _loadMembers(),
                                          );
                                        },
                                        searchController: _teacherSearch,
                                      )
                                    : _StudentsTab(
                                        school: school,
                                        members: _students,
                                        onAdd: () =>
                                            _showAddMemberDialog(isTeacher: false),
                                        onSearch: (v) {
                                          _debounce?.cancel();
                                          _debounce = Timer(
                                            const Duration(milliseconds: 400),
                                            () => _loadMembers(),
                                          );
                                        },
                                        searchController: _studentSearch,
                                      ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _SchoolHeader extends StatelessWidget {
  final School school;

  const _SchoolHeader({required this.school});

  @override
  Widget build(BuildContext context) {
    final remaining = school.remainingSlots;
    final isFull = school.isFull;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (school.adminFullName != null &&
                        school.adminFullName!.isNotEmpty)
                      Text(
                        'Admin: ${school.adminFullName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Plan',
                value: school.planLabel,
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Students',
                value: '${school.studentCount} / ${school.studentLimit}',
                color: isFull ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Teachers',
                value: '${school.teacherCount}',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Remaining',
                value: remaining < 0 ? '0' : '$remaining',
                color: isFull ? Colors.redAccent : Colors.white70,
              ),
            ],
          ),
          if (isFull)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Student limit reached. Ask the super admin to upgrade the plan.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _TabBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Overview'), icon: Icon(Icons.dashboard)),
        ButtonSegment(value: 1, label: Text('Teachers'), icon: Icon(Icons.person)),
        ButtonSegment(value: 2, label: Text('Students'), icon: Icon(Icons.people)),
      ],
      selected: {index},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final School school;

  const _OverviewTab({required this.school});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription & Limits',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Row(label: 'School name', value: school.name),
                  _Row(label: 'Plan', value: school.planLabel),
                  _Row(
                    label: 'Student limit (paid plan)',
                    value: '${school.studentLimit}',
                  ),
                  _Row(
                    label: 'Current students',
                    value: '${school.studentCount}',
                  ),
                  _Row(
                    label: 'Teachers',
                    value: '${school.teacherCount}',
                  ),
                  _Row(
                    label: 'Status',
                    value: school.isActive ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final School school;
  final List<MemberItem> members;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;

  const _MembersTab({
    required this.school,
    required this.members,
    required this.onAdd,
    required this.onSearch,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: onSearch,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: onAdd,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Text(m.fullName.isNotEmpty
                              ? m.fullName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(m.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.email),
                            if (m.phone != null && m.phone!.isNotEmpty)
                              Text(m.phone!),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            m.role[0].toUpperCase() + m.role.substring(1),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: m.role == 'teacher'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TeachersTab extends _MembersTab {
  const _TeachersTab({
    required School school,
    required List<MemberItem> members,
    required VoidCallback onAdd,
    required ValueChanged<String> onSearch,
    required TextEditingController searchController,
  }) : super(
          school: school,
          members: members,
          onAdd: onAdd,
          onSearch: onSearch,
          searchController: searchController,
        );
}

class _StudentsTab extends _MembersTab {
  const _StudentsTab({
    required School school,
    required List<MemberItem> members,
    required VoidCallback onAdd,
    required ValueChanged<String> onSearch,
    required TextEditingController searchController,
  }) : super(
          school: school,
          members: members,
          onAdd: onAdd,
          onSearch: onSearch,
          searchController: searchController,
        );
}

class MemberItem {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;

  MemberItem({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isActive = true,
  });
}
