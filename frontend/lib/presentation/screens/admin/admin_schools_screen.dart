import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/school_detail_screen.dart';

/// Super admin screen: create schools, assign a school admin, set the paid
/// plan and the maximum number of students the school may admit.
class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = false;
  String? _error;
  List<School> _schools = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  static const _plans = [
    ('free', 'Free'),
    ('basic', 'Basic'),
    ('premium', 'Premium'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _schoolService.dispose();
    super.dispose();
  }

  Future<void> _loadSchools({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _schoolService.getSchools(search: search);
      if (!mounted) return;
      setState(() {
        _schools = result.schools;
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

  Color _planColor(String plan) {
    switch (plan) {
      case 'premium':
        return Colors.purple;
      case 'basic':
        return AppTheme.accent;
      default:
        return Colors.grey;
    }
  }

  void _showCreateSchoolDialog() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final adminNameC = TextEditingController();
    final adminEmailC = TextEditingController();
    final adminPhoneC = TextEditingController();
    final adminPassC = TextEditingController();
    String plan = 'free';
    int? studentLimit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create School'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width * 0.9
                : 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                      labelText: 'School name *',
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descC,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminNameC,
                    decoration: const InputDecoration(
                      labelText: 'School admin full name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminEmailC,
                    decoration: const InputDecoration(
                      labelText: 'School admin email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminPhoneC,
                    decoration: const InputDecoration(
                      labelText: 'School admin phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminPassC,
                    decoration: const InputDecoration(
                      labelText: 'School admin password',
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Leave blank to generate',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: plan,
                    decoration: const InputDecoration(
                      labelText: 'Plan',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: _plans
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.$1,
                            child: Text('${e.$2}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => plan = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Student limit (max students)',
                      prefixIcon: const Icon(Icons.people),
                      hintText: plan == 'free' ? '50 (free plan)' : 'e.g. 200',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => studentLimit = int.tryParse(v),
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
                if (nameC.text.trim().isEmpty ||
                    adminNameC.text.trim().isEmpty ||
                    adminEmailC.text.trim().isEmpty) {
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
                  await _schoolService.createSchool(SchoolCreateRequest(
                    name: nameC.text.trim(),
                    description: descC.text.trim().isEmpty ? null : descC.text.trim(),
                    adminFullName: adminNameC.text.trim(),
                    adminEmail: adminEmailC.text.trim(),
                    adminPhone: adminPhoneC.text.trim().isEmpty ? null : adminPhoneC.text.trim(),
                    adminPassword: adminPassC.text.trim().isEmpty ? null : adminPassC.text.trim(),
                    plan: plan,
                    studentLimit: studentLimit,
                  ));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('School created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadSchools(search: _searchController.text);
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
              child: const Text('Create School'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanDialog(School school) {
    String plan = school.plan;
    final limitC = TextEditingController(text: school.studentLimit.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Plan - ${school.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: plan,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: _plans
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.$1,
                          child: Text('${e.$2}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => plan = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitC,
                  decoration: const InputDecoration(
                    labelText: 'Student limit',
                    hintText: 'Maximum students allowed',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text(
                  'Current students: ${school.studentCount}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (school.studentCount > school.studentLimit)
                  const Text(
                    'Warning: school is over its limit.',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
              ],
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
                final limit = int.tryParse(limitC.text.trim());
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
                  await _schoolService.updateSchoolPlan(
                    school.id,
                    SchoolPlanUpdateRequest(plan: plan, studentLimit: limit),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('School plan updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadSchools(search: _searchController.text);
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
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSchool(School school) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete School'),
        content: Text(
          'Permanently delete "${school.name}"? This cannot be undone and is only allowed when the school has no members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _schoolService.deleteSchool(school.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSchools(search: _searchController.text);
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

  Widget _planChip(String plan) {
    final color = _planColor(plan);
    return Chip(
      label: Text(
        plan[0].toUpperCase() + plan.substring(1),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.12),
      color: WidgetStateProperty.resolveWith((states) => color.withOpacity(0.12)),
      labelStyle: TextStyle(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSchools(search: _searchController.text),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showCreateSchoolDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add School', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create schools, assign school admins, and set paid plans with student limits.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schools...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  _loadSchools(search: value);
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _schools.isEmpty
                          ? const Center(child: Text('No schools found'))
                          : ListView.builder(
                              itemCount: _schools.length,
                              itemBuilder: (context, index) {
                                final school = _schools[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
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
                                                  const SizedBox(height: 6),
                                                  if (school.description != null &&
                                                        school.description!.isNotEmpty)
                                                    Text(
                                                      school.description!,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                _planChip(school.plan),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${school.studentCount}/${school.studentLimit}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.primaryGreen,
                                                  ),
                                                ),
                                                const Text(
                                                  'students',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _StatItem(
                                                    icon: Icons.person,
                                                    label: 'School Admin',
                                                    value:
                                                        school.adminFullName ??
                                                            '—',
                                                    subtitle:
                                                        school.adminEmail,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _StatItem(
                                                    icon: Icons.calendar_today,
                                                    label: 'Created',
                                                    value:
                                                        _formatDate(
                                                            school.createdAt),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _StatItem(
                                                    icon: Icons.people,
                                                    label: 'Teachers',
                                                    value:
                                                        '${school.teacherCount}',
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _StatItem(
                                                    icon: Icons.people_outline,
                                                    label: 'Students',
                                                    value:
                                                        '${school.studentCount} / ${school.studentLimit}',
                                                    subtitle:
                                                        school.isFull
                                                            ? 'Limit reached'
                                                            : '${school.remainingSlots} slots left',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (school.studentCount >=
                                                school.studentLimit)
                                              Tooltip(
                                                message: 'Student limit reached',
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.orange,
                                                  ),
                                                  onPressed: null,
                                                ),
                                              ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: AppTheme.primaryGreen,
                                              ),
                                              tooltip: 'Edit plan & limit',
                                              onPressed: () =>
                                                  _showEditPlanDialog(school),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.info_outline,
                                                color: Colors.blue,
                                              ),
                                              tooltip: 'View school details',
                                              onPressed: () =>
                                                  GoRouter.of(context).push(
                                                    '/school-detail/${school.id}',
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Delete school',
                                              onPressed: () =>
                                                  _deleteSchool(school),
                                            ),
                                          ],
                                        ),
                                      ],
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day}/${date.month}/${date.year}';
}
