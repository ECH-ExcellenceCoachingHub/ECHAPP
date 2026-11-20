import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';
import 'package:excellencecoachinghub/widgets/admin_layout_wrapper.dart';

/// Super admin school detail view: teachers, students, and activities of one school.
/// Responsive layout with edit capabilities for school details and admin.
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
  List<UserMin> _members = [];
  int _tabIndex = 0;
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _limitController.dispose();
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
      _selectedPlan = school.plan;
      _nameController.text = school.name;
      _descriptionController.text = school.description ?? '';
      _limitController.text = school.studentLimit.toString();
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
      final members = await _schoolService.getSchoolMembers(
        schoolId: _school!.id,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _members = members.members;
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

  void _showEditSchoolDialog() {
    _nameController.text = _school?.name ?? '';
    _descriptionController.text = _school?.description ?? '';
    _limitController.text = _school?.studentLimit.toString() ?? '';
    _selectedPlan = _school?.plan;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit School Details'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width * 0.9
                : 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'School name *',
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'Plan *',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'basic', child: Text('Basic')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (v) => setState(() => _selectedPlan = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _limitController,
                    decoration: const InputDecoration(
                      labelText: 'Student limit',
                      prefixIcon: Icon(Icons.people),
                      hintText: 'Maximum students allowed',
                    ),
                    keyboardType: TextInputType.number,
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
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () async {
                if (_nameController.text.trim().isEmpty ||
                    _selectedPlan == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final limit = int.tryParse(_limitController.text.trim());
                if (limit == null || limit < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid student limit'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await _schoolService.updateSchoolDetails(
                    widget.schoolId,
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                  );
                  await _schoolService.updateSchoolPlan(
                    widget.schoolId,
                    SchoolPlanUpdateRequest(
                      plan: _selectedPlan!,
                      studentLimit: limit,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('School details updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _load();
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change School Admin'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width * 0.9
                : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select a new school admin from the school members:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: _members.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final m = _members[index];
                            final isCurrentAdmin =
                                _school?.adminId == m.id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isCurrentAdmin
                                        ? AppTheme.primaryGreen
                                        : AppTheme.primaryGreen.withOpacity(0.1),
                                child: Text(
                                  m.fullName.isNotEmpty
                                      ? m.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: isCurrentAdmin
                                        ? Colors.white
                                        : AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(m.fullName),
                              subtitle: Text(
                                '${m.email}  •  ${m.role[0].toUpperCase()}${m.role.substring(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isCurrentAdmin
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                Navigator.pop(context, m.id);
                              },
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
          ],
        ),
      ),
    ).then((selectedId) {
      if (selectedId != null && selectedId is String) {
        _changeAdmin(selectedId);
      }
    });
  }

  Future<void> _changeAdmin(String newAdminId) async {
    try {
      await _schoolService.changeSchoolAdmin(widget.schoolId, newAdminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School admin changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
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
  }

  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  void _showAddAdminDialog() {
    _adminNameController.clear();
    _adminEmailController.clear();
    _adminPhoneController.clear();
    _adminPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add School Admin'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width * 0.9
                : 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _adminNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
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
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () async {
                if (_adminNameController.text.trim().isEmpty ||
                    _adminEmailController.text.trim().isEmpty ||
                    _adminPasswordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await _addSchoolAdmin(
                    MemberCreateRequest(
                      fullName: _adminNameController.text.trim(),
                      email: _adminEmailController.text.trim(),
                      phone: _adminPhoneController.text.trim().isEmpty
                          ? null
                          : _adminPhoneController.text.trim(),
                      password: _adminPasswordController.text.trim(),
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('School admin added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _load();
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSchoolAdmin(MemberCreateRequest request) async {
    await _schoolService.addSchoolAdmin(widget.schoolId, request);
    if (mounted) _loadMembers();
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
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit school details',
              onPressed: _showEditSchoolDialog,
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              tooltip: 'Change school admin',
              onPressed: _showChangeAdminDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _school == null
                    ? const Center(child: Text('School not found'))
                    : _buildBody(context, _school!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, School school) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SchoolDetailHeader(school: school),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Overview'), icon: Icon(Icons.dashboard)),
                  ButtonSegment(value: 1, label: Text('Teachers'), icon: Icon(Icons.person)),
                  ButtonSegment(value: 2, label: Text('Students'), icon: Icon(Icons.people)),
                  ButtonSegment(value: 3, label: Text('Members'), icon: Icon(Icons.group)),
                  ButtonSegment(value: 4, label: Text('Admins'), icon: Icon(Icons.admin_panel_settings)),
                ],
                selected: {_tabIndex},
                onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: _tabIndex == 0
                  ? _OverviewTab(school: school)
                  : _tabIndex == 1
                      ? _MembersTab(
                          title: 'Teachers',
                          members: _members
                              .where((m) => m.role == 'instructor')
                              .toList(),
                          searchController: _searchController,
                          onSearch: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                                const Duration(milliseconds: 400), () {
                              _loadMembers();
                            });
                          },
                        )
                      : _tabIndex == 2
                          ? _MembersTab(
                              title: 'Students',
                              members: _members
                                  .where((m) => m.role == 'student')
                                  .toList(),
                              searchController: _searchController,
                              onSearch: (v) {
                                _debounce?.cancel();
                                _debounce = Timer(
                                    const Duration(milliseconds: 400), () {
                                  _loadMembers();
                                });
                              },
                            )
                          : _tabIndex == 3
                          ? _MembersTab(
                              title: 'All Members',
                              members: _members,
                              searchController: _searchController,
                              onSearch: (v) {
                                _debounce?.cancel();
                                _debounce = Timer(
                                    const Duration(milliseconds: 400), () {
                                  _loadMembers();
                                });
                              },
                            )
                          : _AdminsTab(
                              schoolId: _school!.id,
                              admins: _members.where((m) => m.role == 'school_admin').toList(),
                              onAddAdmin: _showAddAdminDialog,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolDetailHeader extends StatelessWidget {
  final School school;

  const _SchoolDetailHeader({required this.school});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _Stat(
                label: 'Plan',
                value: school.planLabel,
                color: Colors.amber,
              ),
              _Stat(
                label: 'Students',
                value: '${school.studentCount} / ${school.studentLimit}',
                color: school.isFull ? Colors.redAccent : Colors.white,
              ),
              _Stat(
                label: 'Teachers',
                value: '${school.teacherCount}',
                color: Colors.white,
              ),
              _Stat(
                label: 'Remaining slots',
                value: school.remainingSlots < 0 ? '0' : '${school.remainingSlots}',
                color: school.isFull ? Colors.redAccent : Colors.white70,
              ),
              _Stat(
                label: 'Admin',
                value: school.adminFullName ?? '—',
                color: Colors.white,
                subtitle: school.adminEmail,
              ),
              _Stat(
                label: 'Status',
                value: school.isActive ? 'Active' : 'Inactive',
                color: school.isActive ? Colors.green : Colors.redAccent,
              ),
            ],
          ),
          if (school.isFull)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Student limit reached. Upgrade the plan to admit more students.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
      mainAxisSize: MainAxisSize.min,
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

class _OverviewTab extends StatelessWidget {
  final School school;

  const _OverviewTab({required this.school});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  value: school.remainingSlots < 0 ? '0 (over limit)' : '${school.remainingSlots}',
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
                  value: '${school.createdAt.day}/${school.createdAt.month}/${school.createdAt.year}',
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Flexible(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
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
                          backgroundColor: m.role == 'school_admin'
                              ? Colors.purple.withOpacity(0.1)
                              : m.role == 'instructor'
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

class _AdminsTab extends StatelessWidget {
  final String schoolId;
  final List<UserMin> admins;
  final VoidCallback onAddAdmin;

  const _AdminsTab({
    required this.schoolId,
    required this.admins,
    required this.onAddAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search admins...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                onPressed: onAddAdmin,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Admin'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: admins.isEmpty
              ? const Center(child: Text('No school admins found'))
              : ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final m = admins[index];
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
                                : '?',
                          ),
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
                        trailing: const Chip(
                          label: Text(
                            'School Admin',
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.purple,
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
