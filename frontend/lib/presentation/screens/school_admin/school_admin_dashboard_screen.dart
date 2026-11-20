import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/widgets/school_admin_layout_wrapper.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/models/school.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Tab labels and icons shared between the state class and tab bar widget.
const List<String> _tabLabels = [
  'Overview',
  'Teachers',
  'Students',
  'Admins',
];
const List<IconData> _tabIcons = [
  Icons.dashboard,
  Icons.person,
  Icons.people,
  Icons.admin_panel_settings,
];

/// School admin dashboard: view the school's plan/student limit and manage
/// the school's teachers, students, and admins.
class SchoolAdminDashboardScreen extends ConsumerStatefulWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  ConsumerState<SchoolAdminDashboardScreen> createState() =>
      _SchoolAdminDashboardScreenState();
}

class _SchoolAdminDashboardScreenState
    extends ConsumerState<SchoolAdminDashboardScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  String? _error;
  School? _school;
  int _tabIndex = 0; // 0 = overview, 1 = teachers, 2 = students, 3 = admins

  final TextEditingController _teacherSearch = TextEditingController();
  final TextEditingController _studentSearch = TextEditingController();
  final TextEditingController _adminSearch = TextEditingController();
  List<MemberItem> _teachers = [];
  List<MemberItem> _students = [];
  List<MemberItem> _admins = [];
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
    _adminSearch.dispose();
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
      final futures = <Future>[];
      futures.add(_schoolService.getTeachers(
        schoolId: _school!.id,
        search: _teacherSearch.text,
      ));
      futures.add(_schoolService.getStudents(
        schoolId: _school!.id,
        search: _studentSearch.text,
      ));
      futures.add(_schoolService.getSchoolMembers(
        schoolId: _school!.id,
        search: _adminSearch.text,
      ));
      final results = await Future.wait(futures);

      final teachersResult = results[0] as MemberListResponse;
      final studentsResult = results[1] as MemberListResponse;
      final membersResult = results[2] as MemberListResponse;

      if (!mounted) return;
      setState(() {
        _teachers = teachersResult.members
            .map((m) => MemberItem(
                  id: m.id,
                  fullName: m.fullName,
                  email: m.email,
                  phone: m.phone,
                  role: m.role,
                  isActive: m.isActive,
                ))
            .toList();
        _students = studentsResult.members
            .map((m) => MemberItem(
                  id: m.id,
                  fullName: m.fullName,
                  email: m.email,
                  phone: m.phone,
                  role: m.role,
                  isActive: m.isActive,
                ))
            .toList();
        _admins = membersResult.members
            .where((m) => m.role == 'school_admin')
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.getErrorColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/auth-selection');
    }
  }

  void _showAddMemberDialog({bool isTeacher = false, bool isAdmin = false}) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAdmin
              ? 'Add School Admin'
              : (isTeacher ? 'Add Teacher' : 'Add Student'),
          style: TextStyle(color: AppTheme.getTextColor(context)),
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
                  decoration: InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: const Icon(Icons.person),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailC,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(Icons.email),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneC,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: const Icon(Icons.phone),
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    hintText: 'Leave blank to generate',
                    labelStyle: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  obscureText: true,
                ),
                if (!isAdmin && !isTeacher && _school != null && _school!.isFull)
                  ...[
                    const SizedBox(height: 12),
                    Text(
                      'Student limit reached: ${_school!.studentCount}/${_school!.studentLimit}. Upgrade the plan to add more students.',
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
              if (!isAdmin && !isTeacher && _school != null && _school!.isFull) {
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
                if (isAdmin) {
                  await _schoolService.addSchoolAdmin(
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
                } else if (isTeacher) {
                  await _schoolService.addTeacher(
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
                } else {
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
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${isAdmin ? 'School admin' : (isTeacher ? 'Teacher' : 'Student')} added successfully',
                      ),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                  _loadMembers();
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
            child: Text(
              isAdmin ? 'Add Admin' : (isTeacher ? 'Add Teacher' : 'Add Student'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = _school;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SchoolAdminLayoutWrapper(
      screenName: 'School Admin Dashboard',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.school, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  school != null ? school.name : 'School Admin',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              AppTheme.primaryGreen,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor ??
              Colors.white,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.getIconColor(context),
              ),
              color: AppTheme.getCardColor(context),
              onSelected: (value) {
                if (value == 'profile') {
                  context.go('/school-admin/profile');
                } else if (value == 'settings') {
                  context.push('/settings');
                } else if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              itemBuilder: (context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppTheme.getIconColor(context),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              color: AppTheme.getTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: AppTheme.getIconColor(context),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              color: AppTheme.getTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: AppTheme.getErrorColor(context),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: AppTheme.getErrorColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
            if (!isSmallMobile)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                tooltip: 'Refresh',
              ),
          ],
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : school == null
                  ? _EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No school found',
                      subtitle:
                          'Your account is not associated with any school.',
                      actionLabel: 'Refresh',
                      onAction: _load,
                    )
                  : _buildBody(school, isMobile, isSmallMobile),
    ),
  );
}

  Widget _buildBody(School school, bool isMobile, bool isSmallMobile) {
    return SingleChildScrollView(
      padding: ResponsiveBreakpoints.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SchoolHeaderCard(school: school),
          const SizedBox(height: 20),
          _QuickActionsRow(
            school: school,
            onAddTeacher: () => _showAddMemberDialog(isTeacher: true),
            onAddStudent: () => _showAddMemberDialog(isTeacher: false),
            onAddAdmin: () => _showAddMemberDialog(isAdmin: true),
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          _ThemeAwareTabBar(
            index: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 20),
          _tabIndex == 0
              ? _OverviewTab(school: school)
              : _tabIndex == 1
                  ? _MembersTab(
                      title: 'Teachers',
                      members: _teachers,
                      roleFilter: 'instructor',
                      onAdd: () => _showAddMemberDialog(isTeacher: true),
                      onSearch: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () => _loadMembers(),
                        );
                      },
                      searchController: _teacherSearch,
                    )
                  : _tabIndex == 2
                      ? _MembersTab(
                          title: 'Students',
                          members: _students,
                          roleFilter: 'student',
                          onAdd: () => _showAddMemberDialog(isTeacher: false),
                          onSearch: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () => _loadMembers(),
                            );
                          },
                          searchController: _studentSearch,
                        )
                      : _MembersTab(
                          title: 'School Admins',
                          members: _admins,
                          roleFilter: 'school_admin',
                          onAdd: () => _showAddMemberDialog(isAdmin: true),
                          onSearch: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () => _loadMembers(),
                            );
                          },
                          searchController: _adminSearch,
                        ),
        ],
      ),
    );
  }
}

class _ThemeAwareTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ThemeAwareTabBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextSecondary.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: SegmentedButton<int>(
        segments: List.generate(
          _tabLabels.length,
          (i) => ButtonSegment(
            value: i,
            label: Text(_tabLabels[i]),
            icon: Icon(_tabIcons[i], size: 18),
          ),
        ),
        selected: {index},
        onSelectionChanged: (s) => onChanged(s.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: AppTheme.primaryGreen,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppTheme.getSecondaryTextColor(context),
        ),
      ),
    );
  }
}

class _SchoolHeaderCard extends StatelessWidget {
  final School school;

  const _SchoolHeaderCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final remaining = school.remainingSlots;
    final isFull = school.isFull;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.primaryDark, AppTheme.primary]
              : [AppTheme.primaryGreen, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  school.planLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                _ResponsiveStatGrid(
                  stats: [
                    _StatItem(
                      label: 'Plan',
                      value: school.planLabel,
                      color: Colors.amber,
                    ),
                    _StatItem(
                      label: 'Students',
                      value: '${school.studentCount} / ${school.studentLimit}',
                      color: isFull ? Colors.redAccent : Colors.white,
                    ),
                    _StatItem(
                      label: 'Teachers',
                      value: '${school.teacherCount}',
                      color: Colors.white,
                    ),
                    _StatItem(
                      label: 'Remaining',
                      value: remaining < 0 ? '0' : '$remaining',
                      color: isFull ? Colors.redAccent : Colors.white70,
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _StatItem(
                  label: 'Plan',
                  value: school.planLabel,
                  color: Colors.amber,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatItem(
                  label: 'Students',
                  value: '${school.studentCount} / ${school.studentLimit}',
                  color: isFull ? Colors.redAccent : Colors.white,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatItem(
                  label: 'Teachers',
                  value: '${school.teacherCount}',
                  color: Colors.white,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatItem(
                  label: 'Remaining',
                  value: remaining < 0 ? '0' : '$remaining',
                  color: isFull ? Colors.redAccent : Colors.white70,
                )),
              ],
            ),
          if (isFull)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student limit reached. Ask the super admin to upgrade the plan.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
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
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ResponsiveStatGrid extends StatelessWidget {
  final List<_StatItem> stats;

  const _ResponsiveStatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final count = ResponsiveGridCount(context).crossAxisCount;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return stats[index];
      },
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final School school;
  final VoidCallback onAddTeacher;
  final VoidCallback onAddStudent;
  final VoidCallback onAddAdmin;
  final bool isMobile;

  const _QuickActionsRow({
    required this.school,
    required this.onAddTeacher,
    required this.onAddStudent,
    required this.onAddAdmin,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile)
          Column(
            children: [
              _ActionButton(
                label: 'Add Teacher',
                icon: Icons.person_add,
                color: Colors.blue,
                onPressed: onAddTeacher,
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Add Student',
                icon: Icons.person_add_alt_1,
                color: Colors.green,
                onPressed: onAddStudent,
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Add School Admin',
                icon: Icons.admin_panel_settings,
                color: Colors.purple,
                onPressed: onAddAdmin,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _ActionButton(
                label: 'Add Teacher',
                icon: Icons.person_add,
                color: Colors.blue,
                onPressed: onAddTeacher,
              )),
              const SizedBox(width: 12),
              Expanded(child: _ActionButton(
                label: 'Add Student',
                icon: Icons.person_add_alt_1,
                color: Colors.green,
                onPressed: onAddStudent,
              )),
              const SizedBox(width: 12),
              Expanded(child: _ActionButton(
                label: 'Add Admin',
                icon: Icons.admin_panel_settings,
                color: Colors.purple,
                onPressed: onAddAdmin,
              )),
            ],
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final School school;

  const _OverviewTab({required this.school});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: isDark ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppTheme.getCardColor(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(label: 'School name', value: school.name),
                  const Divider(height: 24),
                  _InfoRow(label: 'Plan', value: school.planLabel),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Student limit (paid plan)',
                    value: '${school.studentLimit}',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Current students',
                    value: '${school.studentCount}',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Teachers',
                    value: '${school.teacherCount}',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Status',
                    value: school.isActive ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ),
          ),
          if (!isMobile) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 14)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  final String title;
  final List<MemberItem> members;
  final String roleFilter;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;

  const _MembersTab({
    required this.title,
    required this.members,
    required this.roleFilter,
    required this.onAdd,
    required this.onSearch,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = members.where((m) => m.role == roleFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
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
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  onPressed: onAdd,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.people_outline,
            title: 'No $title found',
            subtitle: 'Tap "Add" to add a new ${title.toLowerCase()}.',
            actionLabel: 'Add',
            onAction: onAdd,
          )
        else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: isMobile
                  ? _MemberListView(members: filtered)
                  : _MemberGridView(members: filtered),
            ),
      ],
    );
  }
}

class _MemberListView extends StatelessWidget {
  final List<MemberItem> members;

  const _MemberListView({required this.members});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          color: AppTheme.getCardColor(context),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(m.fullName.isNotEmpty
                  ? m.fullName[0].toUpperCase()
                  : '?'),
            ),
            title: Text(m.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.email, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
                if (m.phone != null && m.phone!.isNotEmpty)
                  Text(m.phone!, style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12)),
              ],
            ),
            trailing: Chip(
              label: Text(
                m.role[0].toUpperCase() + m.role.substring(1),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: _roleColor(m.role).withOpacity(0.1),
              labelStyle: TextStyle(color: _roleColor(m.role), fontSize: 10),
            ),
          ),
        );
      },
    );
  }
}

class _MemberGridView extends StatelessWidget {
  final List<MemberItem> members;

  const _MemberGridView({required this.members});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = ResponsiveGridCount(context).crossAxisCount;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          color: AppTheme.getCardColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(m.fullName.isNotEmpty
                      ? m.fullName[0].toUpperCase()
                      : '?'),
                ),
                const SizedBox(height: 12),
                Text(m.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.getTextColor(context),
                    )),
                const SizedBox(height: 6),
                Text(m.email,
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (m.phone != null && m.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(m.phone!,
                      style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 11)),
                ],
                const Spacer(),
                Chip(
                  label: Text(
                    m.role[0].toUpperCase() + m.role.substring(1),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _roleColor(m.role).withOpacity(0.1),
                  labelStyle: TextStyle(color: _roleColor(m.role), fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'school_admin':
      return Colors.purple;
    case 'instructor':
    case 'teacher':
      return Colors.blue;
    case 'student':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              )),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
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
