import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_notification_provider.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  bool _hasCheckedRole = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
        ref.read(adminNotificationProvider.notifier).loadNotifications();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void didUpdateWidget(covariant AdminDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUserRole();
  }

  void _checkUserRole() {
    // Role checking is now handled by AdminLayoutWrapper
    // This method is kept for compatibility but no longer performs checks
    if (!_hasCheckedRole) {
      final authState = ref.watch(authProvider);
      if (authState.user != null && !authState.isLoading) {
        _hasCheckedRole = true;
        debugPrint('AdminDashboardScreen: User authenticated - role checking delegated to AdminLayoutWrapper');
      }
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
    ref.invalidate(adminCourseProvider);
    
    // Explicitly load dashboard data after invalidation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
        ref.read(adminNotificationProvider.notifier).loadNotifications();
      }
    });
    
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

  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing users...';
    });
    
    try {
      final adminService = AdminService();
      final result = await adminService.manualSyncUsers();
      
      if (!mounted) return;
      setState(() {
        _syncMessage = result['message'] ?? 'Sync completed successfully';
        _isSyncing = false;
      });
      
      // Reload dashboard data to show updated stats
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      });
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_syncMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Sync failed: ${e.toString()}';
        _isSyncing = false;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_syncMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);

    // Responsive sidebar auto-collapse
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool shouldBeCollapsed = screenWidth < 1100 && screenWidth >= 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCurrentlyCollapsed = ref.read(sidebarProvider);
      if (shouldBeCollapsed && !isCurrentlyCollapsed) {
        ref.read(sidebarProvider.notifier).setCollapsed(true);
      }
    });
      
    if (!_hasLoadedInitialData && dashboardState.stats == null && !dashboardState.isLoading) {
      _hasLoadedInitialData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      });
    }
    
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return _buildDesktopLayout(context, ref, dashboardState);
    } else {
      return _buildMobileLayout(context, ref, dashboardState);
    }
  }
  
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
    final isCollapsed = ref.watch(sidebarProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          _buildDesktopSidebar(context, ref, isCollapsed),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context, ref, isCollapsed),
                Expanded(
                  child: _buildDashboardContent(context, ref, dashboardState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ) : null,
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _triggerManualSync,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationProvider);
              final unreadCount = notificationState.notifications.where((n) => !n.isRead).length;
              
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 24),
                    if (unreadCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  _showNotificationCenter(context);
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authProvider.select((state) => state.user));
              return PopupMenuButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: AppTheme.getIconColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Profile', style: TextStyle(color: AppTheme.getTextColor(context))),
                        ],
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: AppTheme.getIconColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Settings', style: TextStyle(color: AppTheme.getTextColor(context))),
                        ],
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.getErrorColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: AppTheme.getErrorColor(context))),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildDashboardContent(context, ref, dashboardState),
    );
  }
  
  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref, bool isCollapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 24, 40, isCollapsed ? 12 : 24, 32),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'EXCELLENCE HUB',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16),
              children: [
                _buildDesktopNavItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', true, isCollapsed),
                _buildDesktopNavItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false, isCollapsed),
                _buildDesktopNavItem(context, 'Library', Icons.menu_book_rounded, '/admin/books', false, isCollapsed),
                _buildDesktopNavItem(context, 'Teachers', Icons.person_rounded, '/admin/teachers', false, isCollapsed),
                _buildDesktopNavItem(context, 'Teacher Approvals', Icons.how_to_reg_rounded, '/admin/teacher-approvals', false, isCollapsed),
                _buildDesktopNavItem(context, "Teacher's Guides", Icons.auto_stories_rounded, '/admin/teacher-guides', false, isCollapsed),
                _buildDesktopNavItem(context, 'Students', Icons.people_rounded, '/admin/students', false, isCollapsed),
                _buildDesktopNavItem(context, 'Admins', Icons.admin_panel_settings_rounded, '/admin/admins', false, isCollapsed),
                _buildDesktopNavItem(context, 'Schools', Icons.school_rounded, '/admin/schools', false, isCollapsed),
                _buildDesktopNavItem(context, 'Live Sessions', Icons.videocam_rounded, '/admin/live-sessions', false, isCollapsed),
                _buildDesktopNavItem(context, 'Exams', Icons.quiz_rounded, '/admin/exams-review', false, isCollapsed),
                _buildDesktopNavItem(context, 'Feedback', Icons.feedback_rounded, '/admin/user-feedback', false, isCollapsed),
                _buildDesktopNavItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false, isCollapsed),
                _buildDesktopNavItem(context, 'Notifications', Icons.notifications_active_rounded, '/admin/notifications', false, isCollapsed),
                _buildDesktopNavItem(context, 'Push Report', Icons.mark_email_read_rounded, '/admin/push-report', false, isCollapsed),
                _buildDesktopNavItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false, isCollapsed),
                _buildDesktopNavItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false, isCollapsed),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: isCollapsed ? 0 : 16
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 12, 
                      horizontal: isCollapsed ? 0 : 16
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(BuildContext context, String title, IconData icon, String route, bool isActive, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () => context.push(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16, 
              vertical: 10
            ),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            decoration: isActive
                ? BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: isCollapsed
                ? Icon(
                    icon,
                    color: isActive ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                    size: 22,
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isActive ? AppTheme.primaryGreen : AppTheme.getTextColor(context).withOpacity(0.8),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDesktopHeader(BuildContext context, WidgetRef ref, bool isCollapsed) {
    final String currentRoute = GoRouterState.of(context).uri.path;
    final bool isRootRoute = currentRoute == '/admin';
    final bool showBackButton = context.canPop() || !isRootRoute;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: AppTheme.getTextColor(context).withOpacity(0.7),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin');
                }
              },
              tooltip: 'Go back',
            ),
          const SizedBox(width: 8),
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: AppTheme.getTextColor(context).withOpacity(0.7),
            ),
            onPressed: () => ref.read(sidebarProvider.notifier).toggleSidebar(),
            tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
          const SizedBox(width: 16),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 20),
            onPressed: _isSyncing ? null : _triggerManualSync,
            tooltip: 'Sync Users',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 16),
          Consumer(
            builder: (context, ref, child) {
              final adminNotifications = ref.watch(adminNotificationProvider);
              final unreadCount = adminNotifications.notifications.where((n) => !n.isRead).length;
              
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 24),
                    if (unreadCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showNotificationCenter(context),
                tooltip: 'Notifications',
              );
            },
          ),
              Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(authProvider.select((state) => state.user));
                  return PopupMenuButton(
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    color: Theme.of(context).cardColor,
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog(context);
                      }
                    },
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: AppTheme.getIconColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Profile', style: TextStyle(color: AppTheme.getTextColor(context))),
                            ],
                          ),
                          onTap: () => context.push('/profile'),
                        ),
                        PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, color: AppTheme.getIconColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Settings', style: TextStyle(color: AppTheme.getTextColor(context))),
                            ],
                          ),
                          onTap: () => context.push('/settings'),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: AppTheme.getErrorColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Logout', style: TextStyle(color: AppTheme.getErrorColor(context))),
                            ],
                          ),
                        ),
                      ];
                    },
                  );
                },
              ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.whiteColor,
          title: Text(
            'Logout',
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showNotificationCenter(BuildContext context) {
    context.push('/admin/notifications');
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
      
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  Widget _buildDrawer(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      child: Column(
        children: [
          _buildMobileHeader(context, user),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg : Colors.white,
                image: !isDark ? DecorationImage(
                  image: const AssetImage('assets/logo.png'),
                  opacity: 0.02,
                  scale: 8,
                  repeat: ImageRepeat.repeat,
                ) : null,
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  _buildMobileNavItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', true),
                  _buildMobileNavItem(context, 'Notifications', Icons.notifications_active_rounded, '/admin/notifications', false),
                  _buildMobileNavItem(context, 'Push Report', Icons.mark_email_read_rounded, '/admin/push-report', false),
                  _buildMobileNavItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false),
                  _buildMobileNavItem(context, 'Library', Icons.menu_book_rounded, '/admin/books', false),
                  _buildMobileNavItem(context, 'Teachers', Icons.person_rounded, '/admin/teachers', false),
                  _buildMobileNavItem(context, 'Teacher Approvals', Icons.how_to_reg_rounded, '/admin/teacher-approvals', false),
                  _buildMobileNavItem(context, "Teacher's Guides", Icons.auto_stories_rounded, '/admin/teacher-guides', false),
                  _buildMobileNavItem(context, 'Students', Icons.people_rounded, '/admin/students', false),
                  _buildMobileNavItem(context, 'Admins', Icons.admin_panel_settings_rounded, '/admin/admins', false),
                  _buildMobileNavItem(context, 'Schools', Icons.school_rounded, '/admin/schools', false),
                  _buildMobileNavItem(context, 'Live Sessions', Icons.videocam_rounded, '/admin/live-sessions', false),
                  _buildMobileNavItem(context, 'Exams', Icons.quiz_rounded, '/admin/exams-review', false),
                  _buildMobileNavItem(context, 'Feedback', Icons.feedback_rounded, '/admin/user-feedback', false),
                  _buildMobileNavItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false),
                  _buildMobileNavItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false),
                  _buildMobileNavItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMobileLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'MANAGEMENT CONSOLE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    image: user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(mediaProxyUrl(user.profilePicture)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: user.profilePicture == null || user.profilePicture!.isEmpty
                    ? Center(
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMINISTRATOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLogoutButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.05) : Colors.red.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.logout_rounded,
            color: Colors.red.shade600,
            size: 20,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        trailing: Icon(
          Icons.power_settings_new_rounded,
          size: 18,
          color: Colors.red.withOpacity(0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () {
          _showLogoutDialog(context);
        },
      ),
    );
  }
  
  Widget _buildMobileNavItem(BuildContext context, String title, IconData icon, String route, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.12)
                : (isDark ? Colors.white.withOpacity(0.05) : AppTheme.greyColor.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryGreen : (isDark ? Colors.white70 : AppTheme.greyColor),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : (isDark ? Colors.white.withOpacity(0.9) : AppTheme.getTextColor(context)),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        trailing: isSelected 
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: () {
          if (!isSelected) {
            context.push(route);
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
    if (dashboardState.isLoading && dashboardState.stats == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading dashboard data...'),
          ],
        ),
      );
    }
    
    if (dashboardState.error != null && dashboardState.stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error loading dashboard: ${dashboardState.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final stats = dashboardState.stats;
    
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 32.0 : 20.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: isDesktop ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your coaching platform efficiently',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      color: AppTheme.greyColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              if (isDesktop)
                ElevatedButton.icon(
                  onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: isDesktop ? 40 : 30),
          
          _buildStatsSection(stats, context),
          
          SizedBox(height: isDesktop ? 40 : 30),
          
          _buildRecentActivitySection(stats, context),
          
          SizedBox(height: isDesktop ? 40 : 20),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AdminDashboardStats stats, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
    final spacing = isDesktop ? 24.0 : 20.0;
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.8 : 2.5),
      children: [
        _buildStatCard('Total Courses', stats.totalCourses.toString(), Icons.school_rounded, const Color(0xFF6366F1), context),
        _buildStatCard('Active Students', stats.activeStudents.toString(), Icons.people_alt_rounded, const Color(0xFF10B981), context),
        _buildStatCard('Total Revenue', 'RWF ${stats.totalRevenue.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFFF59E0B), context),
        _buildStatCard('Total Final Exams', stats.totalFinalExams.toString(), Icons.assignment_turned_in_rounded, const Color(0xFFEF4444), context),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: color.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      color: AppTheme.greyColor.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.greyColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(AdminDashboardStats stats, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/admin/notifications'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: stats.recentActivity.isEmpty 
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 48, color: AppTheme.greyColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No recent activity',
                            style: TextStyle(color: AppTheme.greyColor.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  )
                ]
              : stats.recentActivity.map((activity) => Column(
                children: [
                  _ActivityItem(
                    icon: _getIconFromString(activity.icon),
                    title: activity.title,
                    subtitle: activity.subtitle,
                    time: activity.time,
                    iconColor: _getIconColorFromString(activity.icon),
                  ),
                  if (stats.recentActivity.indexOf(activity) < stats.recentActivity.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Divider(
                        height: 32,
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                ],
              )).toList(),
          ),
        ),
      ],
    );
  }

  static Color _getIconColorFromString(String? iconString) {
    switch (iconString) {
      case 'school':
        return const Color(0xFF6366F1);
      case 'people':
        return const Color(0xFF10B981);
      case 'payment':
        return const Color(0xFFF59E0B);
      case 'video_call':
        return const Color(0xFF8B5CF6);
      case 'quiz':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.primaryGreen;
    }
  }

  static IconData _getIconFromString(String? iconString) {
    switch (iconString) {
      case 'school':
        return Icons.school_rounded;
      case 'people':
        return Icons.people_alt_rounded;
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'video_call':
        return Icons.video_call_rounded;
      case 'quiz':
        return Icons.assignment_rounded;
      case 'add':
        return Icons.add_rounded;
      case 'person_add':
        return Icons.person_add_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color iconColor;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.getTextColor(context),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.greyColor.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: AppTheme.greyColor.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
