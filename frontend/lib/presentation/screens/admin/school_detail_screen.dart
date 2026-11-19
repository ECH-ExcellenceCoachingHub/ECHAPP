import 'dart:async';

import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';
import 'package:excellencecoachinghub/widgets/admin_layout_wrapper.dart';

/// Super admin school detail view: teachers, students, and activities of one school.
class SchoolDetailScreen extends StatefulWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  String? _error;
  School? _school;
  List<UserMin> _teachers = [];
  List<UserMin> _students = [];
  int _tabIndex = 0; // 0 = overview, 1 = teachers, 2 = students
  Timer? _debounce;

  final TextEditingController _teacherSearch = TextEditingController();
  final TextEditingController _studentSearch = TextEditingController();

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
      final school = await _schoolService.getSchool(widget.schoolId);
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
        _teachers = teachers.members;
        _students = students.members;
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

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWrapper(
      screenName: 'School Detail',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('School Details'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _school == null
                    ? const Center(child: Text('School not found'))
                    : _buildBody(context, _school!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, School school) {
    return Column(
      children: [
        _SchoolDetailHeader(school: school),
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
                  ? _MembersTab(
                      title: 'Teachers',
                      members: _teachers,
                      searchController: _teacherSearch,
                      onSearch: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(
                            const Duration(milliseconds: 400), () {
                          _loadMembers();
                        });
                      },
                    )
                  : _MembersTab(
                      title: 'Students',
                      members: _students,
                      searchController: _studentSearch,
                      onSearch: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(
                            const Duration(milliseconds: 400), () {
                          _loadMembers();
                        });
                      },
                    ),
        ),
      ],
    );
  }
}

class _SchoolDetailHeader extends StatelessWidget {
  final School school;

  const _SchoolDetailHeader({required this.school});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
                    if (school.description != null &&
                        school.description!.isNotEmpty)
                      Text(
                        school.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  school.planLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: 'Plan',
                value: school.planLabel,
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Students',
                value: '${school.studentCount} / ${school.studentLimit}',
                color: school.isFull ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Teachers',
                value: '${school.teacherCount}',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Remaining slots',
                value:
                    school.remainingSlots < 0 ? '0' : '${school.remainingSlots}',
                color: school.isFull ? Colors.redAccent : Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                label: 'Admin',
                value: school.adminFullName ?? '—',
                color: Colors.white,
                subtitle: school.adminEmail,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Created',
                value: '${school.createdAt.day}/${school.createdAt.month}/${school.createdAt.year}',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _Stat(
                label: 'Status',
                value: school.isActive ? 'Active' : 'Inactive',
                color: school.isActive ? Colors.green : Colors.redAccent,
              ),
            ],
          ),
          if (school.isFull)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Student limit reached. Upgrade the plan to admit more students.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
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
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
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
                  if (school.description != null && school.description!.isNotEmpty)
                    _Row(label: 'Description', value: school.description!),
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
                    label: 'Available slots',
                    value:
                        school.remainingSlots < 0 ? '0 (over limit)' : '${school.remainingSlots}',
                  ),
                  _Row(
                    label: 'Status',
                    value: school.isActive ? 'Active' : 'Inactive',
                  ),
                  _Row(
                    label: 'Admin',
                    value: school.adminFullName ?? '—',
                    subtitle: school.adminEmail,
                  ),
                  _Row(
                    label: 'Created on',
                    value:
                        '${school.createdAt.day}/${school.createdAt.month}/${school.createdAt.year}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How it works',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_add,
            title: 'Add teachers',
            subtitle:
                'School admin or super admin can add teachers to this school.',
          ),
          _InfoRow(
            icon: Icons.person_add_alt_1,
            title: 'Add students',
            subtitle:
                'Teachers and school admins can add students up to the paid plan limit.',
          ),
          _InfoRow(
            icon: Icons.payment,
            title: 'Plan limits',
            subtitle:
                'Students added to this school use the school\u2019s plan. Self-registered students are private.',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _Row({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final String title;
  final List<UserMin> members;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  const _MembersTab({
    required this.title,
    required this.members,
    required this.searchController,
    required this.onSearch,
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
                    hintText: 'Search $title...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: onSearch,
                ),
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
                          backgroundColor:
                              AppTheme.primaryGreen.withOpacity(0.1),
                          child: Text(
                              m.fullName.isNotEmpty
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
                          backgroundColor: m.role == 'instructor'
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
