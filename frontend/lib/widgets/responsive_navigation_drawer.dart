import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/widgets/modern_dialog.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

/// Width of the collapsed desktop sidebar (icon rail).
const double kSidebarRailWidth = 88;

/// Width of the expanded desktop sidebar.
const double kSidebarExpandedWidth = 272;

// Shared palette for every menu variant.
const Color _kForest = Color(0xFF0B6E4F);
const Color _kGreen = Color(0xFF0E8A5F);
const Color _kBlue = Color(0xFF2563EB);
const Color _kPurple = Color(0xFF7C3AED);
const Color _kOrange = Color(0xFFF97316);
const Color _kLime = Color(0xFF16A34A);
const Color _kTeal = Color(0xFF0D9488);
const Color _kRose = Color(0xFFE11D48);
const Color _kSlate = Color(0xFF64748B);

enum _MenuRole { student, admin, guest }

/// One destination in the menu.
class _NavItem {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// Null together with [comingSoon] for features that don't exist yet.
  final String? route;

  /// Legacy page key from MainLayout, used as a fallback for highlighting.
  final String? pageKey;
  final bool comingSoon;

  const _NavItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.route,
    this.pageKey,
    this.comingSoon = false,
  });
}

class _NavSection {
  /// Null for the unlabeled lead section (Home).
  final String? label;
  final List<_NavItem> items;

  const _NavSection(this.label, this.items);
}

/// The whole menu for one role: grouped destinations plus the cards pinned
/// near the bottom (help / settings).
class _Menu {
  final List<_NavSection> sections;
  final List<_NavItem> footerCards;

  const _Menu(this.sections, this.footerCards);
}

class ResponsiveNavigationDrawer extends ConsumerWidget {
  final String currentPage;

  const ResponsiveNavigationDrawer({
    super.key,
    required this.currentPage,
  });

  // ---------------------------------------------------------------------------
  // Menu definitions
  // ---------------------------------------------------------------------------

  _Menu _menuFor(_MenuRole role, AppLocalizations? l10n, {required bool desktop}) {
    final needHelp = _NavItem(
      icon: Icons.support_agent_rounded,
      color: _kGreen,
      title: l10n?.drawerNeedHelp ?? 'Need Help?',
      subtitle: l10n?.drawerContactSupport ?? 'Contact support or get assistance',
      route: '/help',
    );
    final settings = _NavItem(
      icon: Icons.settings_rounded,
      color: _kSlate,
      title: l10n?.settings ?? 'Settings',
      subtitle: l10n?.drawerAppPreferences ?? 'App preferences',
      route: '/settings',
      pageKey: 'settings',
    );

    switch (role) {
      case _MenuRole.guest:
        return _Menu([
          _NavSection(null, [
            _NavItem(
              icon: Icons.home_rounded,
              color: _kGreen,
              title: l10n?.welcome ?? 'Welcome',
              route: '/auth-selection',
              pageKey: 'auth',
            ),
          ]),
          _NavSection(l10n?.sidebarSectionGetStarted ?? 'Get Started', [
            _NavItem(
              icon: Icons.login_rounded,
              color: _kGreen,
              title: l10n?.sidebarSignIn ?? 'Sign In',
              subtitle: l10n?.drawerAccessAccount ?? 'Access your account',
              route: '/login',
              pageKey: 'login',
            ),
            _NavItem(
              icon: Icons.person_add_rounded,
              color: _kBlue,
              title: l10n?.sidebarRegister ?? 'Register',
              subtitle: l10n?.drawerCreateAccount ?? 'Create a free account',
              route: '/register',
              pageKey: 'register',
            ),
          ]),
        ], [needHelp]);

      case _MenuRole.admin:
        return _Menu([
          _NavSection(null, [
            _NavItem(
              icon: Icons.space_dashboard_rounded,
              color: _kGreen,
              title: l10n?.dashboard ?? 'Dashboard',
              route: '/admin',
              pageKey: 'dashboard',
            ),
          ]),
          _NavSection(l10n?.drawerSectionInsights ?? 'Insights', [
            _NavItem(
              icon: Icons.insights_rounded,
              color: _kBlue,
              title: l10n?.sidebarAdminAnalytics ?? 'Analytics',
              subtitle: l10n?.drawerPlatformInsights ?? 'Platform insights',
              route: '/admin/analytics',
            ),
            _NavItem(
              icon: Icons.mark_email_read_rounded,
              color: _kTeal,
              title: l10n?.drawerPushReport ?? 'Push Report',
              subtitle: l10n?.drawerDeliveryStats ?? 'Delivery statistics',
              route: '/admin/push-report',
            ),
          ]),
          _NavSection(l10n?.sidebarSectionManage ?? 'Manage', [
            _NavItem(
              icon: Icons.school_rounded,
              color: _kGreen,
              title: l10n?.courses ?? 'Courses',
              subtitle: l10n?.drawerCreateEditCourses ?? 'Create & edit courses',
              route: '/admin/courses',
            ),
            _NavItem(
              icon: Icons.people_alt_rounded,
              color: _kPurple,
              title: l10n?.sidebarAdminStudents ?? 'Students',
              subtitle: l10n?.drawerLearnersAccess ?? 'Learners & access',
              route: '/admin/students',
            ),
            _NavItem(
              icon: Icons.video_library_rounded,
              color: _kRose,
              title: l10n?.drawerRecordings ?? 'Recordings',
              subtitle: l10n?.drawerSessionVideos ?? 'Session videos',
              route: '/admin/recordings',
            ),
            _NavItem(
              icon: Icons.payments_rounded,
              color: _kOrange,
              title: l10n?.sidebarAdminPayments ?? 'Payments',
              subtitle: l10n?.drawerApproveTrack ?? 'Approve & track',
              route: '/admin/payments',
            ),
            _NavItem(
              icon: Icons.campaign_rounded,
              color: _kBlue,
              title: l10n?.sidebarAdminNotifications ?? 'Notifications',
              subtitle: l10n?.drawerSendAnnouncements ?? 'Send announcements',
              route: '/admin/notifications',
            ),
          ]),
        ], [settings]);

      case _MenuRole.student:
        final home = _NavItem(
          icon: Icons.home_rounded,
          color: _kGreen,
          title: l10n?.home ?? 'Home',
          route: '/dashboard',
          pageKey: 'dashboard',
        );
        final myCourses = _NavItem(
          icon: Icons.school_rounded,
          color: _kGreen,
          title: l10n?.myCourses ?? 'My Courses',
          subtitle: l10n?.dashContinueLearning ?? 'Continue learning',
          route: '/my-courses',
          pageKey: 'my-courses',
        );
        final liveSessions = _NavItem(
          icon: Icons.videocam_rounded,
          color: _kBlue,
          title: l10n?.dashLiveSessions ?? 'Live Sessions',
          subtitle: l10n?.dashJoinParticipate ?? 'Join & participate',
          route: '/upcoming-sessions',
        );
        final career = _NavItem(
          icon: Icons.groups_rounded,
          color: _kPurple,
          title: l10n?.drawerCareerGuidance ?? 'Career Guidance',
          subtitle: l10n?.drawerGetSupport ?? 'Get support',
          comingSoon: true,
        );
        final jobs = _NavItem(
          icon: Icons.work_rounded,
          color: _kOrange,
          title: l10n?.drawerJobs ?? 'Jobs',
          subtitle: l10n?.drawerFindOpportunities ?? 'Find opportunities',
          comingSoon: true,
        );
        final progress = _NavItem(
          icon: Icons.bar_chart_rounded,
          color: _kLime,
          title: l10n?.drawerMyProgress ?? 'My Progress',
          subtitle: l10n?.drawerTrackGrowth ?? 'Track your growth',
          route: '/profile',
          pageKey: 'profile',
        );
        final certificates = _NavItem(
          icon: Icons.workspace_premium_rounded,
          color: _kPurple,
          title: l10n?.certificates ?? 'Certificates',
          subtitle: l10n?.dashYourAchievements ?? 'Your achievements',
          route: '/certificates',
          pageKey: 'certificates',
        );
        final messages = _NavItem(
          icon: Icons.chat_rounded,
          color: _kBlue,
          title: l10n?.messages ?? 'Messages',
          subtitle: l10n?.drawerStayConnected ?? 'Stay connected',
          route: '/messages',
          pageKey: 'messages',
        );

        // Phones also have the bottom bar (courses, community, downloads), so
        // the drawer stays focused. Desktop has no bottom bar: everything
        // lives here.
        if (!desktop) {
          return _Menu([
            _NavSection(null, [home]),
            _NavSection(l10n?.sidebarSectionLearning ?? 'Learning',
                [myCourses, liveSessions, career, jobs]),
            _NavSection(
                l10n?.drawerSectionProfileProgress ?? 'Profile & Progress',
                [progress, certificates]),
            _NavSection(l10n?.drawerSectionCommunication ?? 'Communication',
                [messages]),
          ], [needHelp, settings]);
        }

        return _Menu([
          _NavSection(null, [home]),
          _NavSection(l10n?.sidebarSectionLearning ?? 'Learning', [
            myCourses,
            _NavItem(
              icon: Icons.explore_rounded,
              color: _kTeal,
              title: l10n?.courses ?? 'Courses',
              subtitle: l10n?.drawerExploreCatalog ?? 'Explore the catalog',
              route: '/courses',
              pageKey: 'courses',
            ),
            liveSessions,
            _NavItem(
              icon: Icons.local_library_rounded,
              color: _kOrange,
              title: l10n?.library ?? 'Library',
              subtitle: l10n?.drawerBooksResources ?? 'Books & resources',
              route: '/library',
            ),
            _NavItem(
              icon: Icons.quiz_rounded,
              color: _kRose,
              title: l10n?.exams ?? 'Exams',
              subtitle: l10n?.drawerYourResults ?? 'Your results',
              route: '/exams/history',
              pageKey: 'exams',
            ),
            _NavItem(
              icon: Icons.download_rounded,
              color: _kSlate,
              title: l10n?.downloads ?? 'Downloads',
              subtitle: l10n?.drawerOfflineLearning ?? 'Learn offline',
              route: '/downloads',
              pageKey: 'downloads',
            ),
            career,
            jobs,
          ]),
          _NavSection(
              l10n?.drawerSectionProfileProgress ?? 'Profile & Progress', [
            progress,
            certificates,
            _NavItem(
              icon: Icons.receipt_long_rounded,
              color: _kTeal,
              title: l10n?.payments ?? 'Payments',
              subtitle: l10n?.drawerBillingHistory ?? 'Billing history',
              route: '/payments/history',
              pageKey: 'payments',
            ),
          ]),
          _NavSection(l10n?.drawerSectionCommunication ?? 'Communication', [
            _NavItem(
              icon: Icons.groups_2_rounded,
              color: _kPurple,
              title: l10n?.community ?? 'Community',
              subtitle: l10n?.dashLearnTogether ?? 'Learn together',
              route: '/community',
              pageKey: 'community',
            ),
            messages,
          ]),
        ], [needHelp, settings]);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCollapsed = ref.watch(sidebarProvider);
    final user = ref.watch(authProvider.select((state) => state.user));
    final role = (user == null || currentPage == 'auth')
        ? _MenuRole.guest
        : (user.role == 'admin' ? _MenuRole.admin : _MenuRole.student);

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isPlatformDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
    // Consistent with MainLayout: desktop platforms use the sidebar from 600px.
    final bool useSidebarStyle = isDesktop ||
        (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);

    final menu = _menuFor(role, l10n, desktop: useSidebarStyle);
    return useSidebarStyle
        ? _buildDesktopSidebar(context, ref, menu, role, isCollapsed)
        : _buildMobileDrawer(context, ref, menu, role, user);
  }

  /// Current location, read from the router when available.
  String? _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return null;
    }
  }

  bool _isSelected(_NavItem item, String? path) {
    final route = item.route;
    if (route != null && path != null) {
      // Dashboards only match exactly; everything else also owns its sub-pages.
      if (route == '/admin' || route == '/dashboard') return path == route;
      return path == route || path.startsWith('$route/');
    }
    return item.pageKey != null && item.pageKey == currentPage;
  }

  void _open(BuildContext context, _NavItem item,
      {required bool selected, required bool closeDrawer}) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (closeDrawer) Navigator.of(context).pop();
    if (item.comingSoon || item.route == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n?.drawerComingSoon ??
            "Coming soon — we're building this for you."),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!selected) context.go(item.route!);
  }

  // ===========================================================================
  // MOBILE DRAWER
  // ===========================================================================

  Widget _buildMobileDrawer(BuildContext context, WidgetRef ref, _Menu menu,
      _MenuRole role, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final drawerWidth = (media.size.width * 0.88).clamp(280.0, 360.0);
    final path = _currentPath(context);

    final children = <Widget>[];
    for (var i = 0; i < menu.sections.length; i++) {
      final section = menu.sections[i];
      if (section.label != null) {
        if (i > 1) children.add(_mobileDivider(isDark));
        children.add(_sectionLabel(context, section.label!));
      }
      for (final item in section.items) {
        children.add(_mobileRow(context, item, _isSelected(item, path)));
      }
    }
    children.add(const SizedBox(height: 16));
    for (final card in menu.footerCards) {
      children
        ..add(_mobileCard(context, card))
        ..add(const SizedBox(height: 10));
    }
    if (role != _MenuRole.guest) children.add(_logoutRow(context, ref));

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F1A24) : Colors.white,
      width: drawerWidth,
      elevation: 16,
      shape: const RoundedRectangleBorder(),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            _mobileHeader(context, ref, role, user),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
            _footer(context, media.padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _mobileDivider(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
        child: Container(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE7ECEF),
        ),
      );

  Widget _mobileHeader(
      BuildContext context, WidgetRef ref, _MenuRole role, dynamic user) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final topInset = (media.padding.top < 24 ? 24.0 : media.padding.top) + 16;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _headerGradient),
        child: CustomPaint(
          painter: const _DrawerMistPainter(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, topInset, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logoBadge(72),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _brandText(l10n, titleSize: 19, taglineSize: 11.5),
                      ),
                    ),
                    if (role != _MenuRole.guest) ...[
                      const SizedBox(width: 6),
                      _bell(context, ref, closeDrawer: true),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                if (role == _MenuRole.guest)
                  _guestCard(context, closeDrawer: true)
                else if (user != null)
                  _profileCard(context, user, role, closeDrawer: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One menu row: tinted icon tile, title (+ subtitle) and a chevron. The
  /// active page gets a mint pill and a green accent bar on the left.
  Widget _mobileRow(BuildContext context, _NavItem item, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final row = Material(
      color: selected ? _activeFill(isDark) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _open(context, item, selected: selected, closeDrawer: true),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: selected ? 12 : 6, vertical: selected ? 10 : 7),
          child: Row(
            children: [
              _iconTile(item, isDark, size: 52, selected: selected),
              const SizedBox(width: 15),
              Expanded(
                child: _titleBlock(context, item, selected,
                    titleSize: selected && item.subtitle == null ? 17 : 15.5,
                    subtitleSize: 13),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: selected
                    ? _activeText(isDark)
                    : (isDark ? Colors.white54 : const Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Accent bar sits just outside the active pill.
          Container(
            width: 4,
            height: selected ? 64 : 0,
            decoration: BoxDecoration(
              color: _kForest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: selected ? 6 : 0),
          Expanded(child: row),
        ],
      ),
    );
  }

  Widget _mobileCard(BuildContext context, _NavItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(18);
    final selected = _isSelected(item, _currentPath(context));

    return Material(
      color: isDark
          ? item.color.withOpacity(0.12)
          : Color.alphaBlend(item.color.withOpacity(0.07), Colors.white),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _open(context, item, selected: selected, closeDrawer: true),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: item.color.withOpacity(isDark ? 0.25 : 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withOpacity(isDark ? 0.22 : 0.13),
                ),
                child: Icon(item.icon,
                    color: item.color == _kGreen
                        ? (isDark ? const Color(0xFF6EE7B7) : _kForest)
                        : (isDark
                            ? Colors.white70
                            : const Color(0xFF475569)),
                    size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _titleBlock(context, item, false,
                    titleSize: 15, subtitleSize: 12, boldTitle: true),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : const Color(0xFF475569)),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP SIDEBAR
  // Same look as the phone drawer, laid out for a persistent side panel. It
  // switches to the icon rail by its *actual* width, so the expand/collapse
  // animation never overflows.
  // ===========================================================================

  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref, _Menu menu,
      _MenuRole role, bool isCollapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = _currentPath(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? kSidebarRailWidth : kSidebarExpandedWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A24) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE7ECEF),
          ),
        ),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rail = constraints.maxWidth < 200;

            final children = <Widget>[];
            for (var i = 0; i < menu.sections.length; i++) {
              final section = menu.sections[i];
              if (section.label != null) {
                children.add(rail
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        child: Container(
                          height: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE7ECEF),
                        ),
                      )
                    : _sectionLabel(context, section.label!, dense: true));
              }
              for (final item in section.items) {
                children.add(_desktopRow(
                    context, item, _isSelected(item, path), rail));
              }
            }

            return Column(
              children: [
                _desktopHeader(context, ref, role, rail),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                        rail ? 12 : 12, 8, rail ? 12 : 14, 12),
                    children: children,
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(rail ? 12 : 14, 10,
                      rail ? 12 : 14, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE7ECEF),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final card in menu.footerCards)
                        _desktopRow(context, card, _isSelected(card, path),
                            rail),
                      if (role != _MenuRole.guest) ...[
                        const SizedBox(height: 6),
                        rail
                            ? _railLogout(context, ref)
                            : _logoutRow(context, ref, compact: true),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _desktopHeader(
      BuildContext context, WidgetRef ref, _MenuRole role, bool rail) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((state) => state.user));

    return Padding(
      padding: EdgeInsets.fromLTRB(rail ? 10 : 12, 12, rail ? 10 : 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(rail ? 18 : 22),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: CustomPaint(
            painter: const _DrawerMistPainter(),
            child: Padding(
              padding: EdgeInsets.all(rail ? 10 : 14),
              child: rail
                  ? Center(child: _logoBadge(46))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _logoBadge(46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _brandText(l10n,
                                  titleSize: 14.5, taglineSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (role == _MenuRole.guest)
                          _guestCard(context, closeDrawer: false, compact: true)
                        else if (user != null)
                          _profileCard(context, user, role,
                              closeDrawer: false, compact: true),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopRow(
      BuildContext context, _NavItem item, bool selected, bool rail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void onTap() => _open(context, item, selected: selected, closeDrawer: false);

    if (rail) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: item.comingSoon
              ? '${item.title} · ${AppLocalizations.of(context)?.drawerSoon ?? 'Soon'}'
              : item.title,
          waitDuration: const Duration(milliseconds: 400),
          child: Material(
            color: selected ? _activeFill(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 56,
                child: Center(
                    child: _iconTile(item, isDark, size: 42, selected: selected)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? _activeFill(isDark) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 7, 8, 7),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: selected ? 30 : 0,
                  decoration: BoxDecoration(
                    color: _kForest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: selected ? 6.5 : 10),
                _iconTile(item, isDark, size: 40, selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: _titleBlock(context, item, selected,
                      titleSize: 13.5, subtitleSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _railLogout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n?.logout ?? 'Log Out',
      child: Material(
        color: _kRose.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showLogoutDialog(context, ref),
          borderRadius: BorderRadius.circular(14),
          child: const SizedBox(
            height: 46,
            child: Center(
              child: Icon(Icons.logout_rounded, color: _kRose, size: 21),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SHARED PIECES
  // ===========================================================================

  static const LinearGradient _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6A4B), Color(0xFF0F7A56), Color(0xFF0B6347)],
  );

  Color _tint(Color c, bool isDark) =>
      isDark ? Color.lerp(c, Colors.white, 0.3)! : c;

  Color _activeFill(bool isDark) =>
      isDark ? const Color(0xFF12352A) : const Color(0xFFE8F5EE);

  Color _activeText(bool isDark) =>
      isDark ? const Color(0xFF6EE7B7) : _kForest;

  Widget _iconTile(_NavItem item, bool isDark,
      {required double size, required bool selected}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.31),
        color: item.color.withOpacity(
            selected ? (isDark ? 0.28 : 0.16) : (isDark ? 0.18 : 0.09)),
      ),
      child: Icon(item.icon, color: _tint(item.color, isDark), size: size * 0.5),
    );
  }

  Widget _titleBlock(
    BuildContext context,
    _NavItem item,
    bool selected, {
    required double titleSize,
    required double subtitleSize,
    bool boldTitle = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: selected || boldTitle
                      ? FontWeight.w700
                      : FontWeight.w600,
                  letterSpacing: -0.2,
                  color: selected
                      ? _activeText(isDark)
                      : (isDark ? Colors.white : const Color(0xFF0F2233)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.comingSoon) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n?.drawerSoon ?? 'Soon',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _tint(item.color, isDark),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (item.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            item.subtitle!,
            style: TextStyle(
              fontSize: subtitleSize,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label, {bool dense = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(dense ? 10 : 6, dense ? 16 : 20, 6, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: dense ? 10.5 : 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF5B7083),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _logoBadge(double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.school, color: _kGreen),
      ),
    );
  }

  Widget _brandText(AppLocalizations? l10n,
      {required double titleSize, required double taglineSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n?.appName ?? 'Excellence Coaching Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            height: 1.18,
            letterSpacing: -0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          l10n?.drawerTagline ?? 'Learn • Grow • Build Your Future',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: taglineSize,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _bell(BuildContext context, WidgetRef ref, {required bool closeDrawer}) {
    final l10n = AppLocalizations.of(context);
    final hasUnread =
        ref.watch(notificationProvider).notifications.any((n) => !n.isRead);

    return Tooltip(
      message: l10n?.notifications ?? 'Notifications',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (closeDrawer) Navigator.of(context).pop();
          context.push('/notifications');
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 23),
              ),
              if (hasUnread)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF0F7A56), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, dynamic user, _MenuRole role,
      {required bool closeDrawer, bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    final fullName = ((user.fullName as String?) ?? '').trim();
    final parts =
        fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final displayName = parts.isEmpty
        ? (l10n?.student ?? 'Student')
        : parts
            .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
            .join(' ');
    final initials = parts.isEmpty
        ? 'S'
        : (parts.first[0] + (parts.length > 1 ? parts[1][0] : '')).toUpperCase();
    final picture = user.profilePicture as String?;
    final hasPhoto = picture != null && picture.isNotEmpty;
    final roleLabel = role == _MenuRole.admin
        ? (l10n?.drawerAdministrator ?? 'Administrator')
        : (l10n?.student ?? 'Student');
    final avatar = compact ? 40.0 : 56.0;

    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(compact ? 14 : 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        onTap: () {
          if (closeDrawer) Navigator.of(context).pop();
          context.go('/profile');
        },
        child: Container(
          padding: compact
              ? const EdgeInsets.fromLTRB(10, 8, 8, 8)
              : const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: avatar,
                height: avatar,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A9D8F), Color(0xFF0F5E57)],
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.55),
                      width: compact ? 1.5 : 2),
                  image: hasPhoto
                      ? DecorationImage(
                          image: NetworkImage(mediaProxyUrl(picture)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: hasPhoto
                    ? null
                    : Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: avatar * 0.34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13.5 : 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: compact ? 11 : 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: compact ? 20 : 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Signed-out header card: a short pitch and the two ways in.
  Widget _guestCard(BuildContext context,
      {required bool closeDrawer, bool compact = false}) {
    final l10n = AppLocalizations.of(context);

    void go(String route) {
      if (closeDrawer) Navigator.of(context).pop();
      context.go(route);
    }

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.sidebarUnlockPotential ??
                'Unlock your potential with expert-led courses.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kForest,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: compact ? 8 : 11),
                    textStyle: TextStyle(
                        fontSize: compact ? 12 : 13.5,
                        fontWeight: FontWeight.w700),
                  ),
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n?.sidebarSignIn ?? 'Sign In')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: compact ? 8 : 11),
                    textStyle: TextStyle(
                        fontSize: compact ? 12 : 13.5,
                        fontWeight: FontWeight.w700),
                  ),
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n?.sidebarRegister ?? 'Register')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutRow(BuildContext context, WidgetRef ref, {bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? _kRose.withOpacity(0.10) : const Color(0xFFFBF7F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showLogoutDialog(context, ref),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16, vertical: compact ? 10 : 12),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: _kRose, size: compact ? 20 : 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.logout ?? 'Log Out',
                  style: TextStyle(
                    color: _kRose,
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, double bottomInset) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E7D5B);

    return SizedBox(
      height: 104 + bottomInset,
      child: CustomPaint(
        painter: _DrawerWavePainter(isDark: isDark),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 16, 16 + bottomInset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco_rounded, color: green, size: 30),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.drawerBetterSkills ?? 'Better Skills',
                    style: TextStyle(color: green, fontSize: 13.5, height: 1.3),
                  ),
                  Text(
                    l10n?.drawerBrighterFuture ?? 'Brighter Future',
                    style: TextStyle(color: green, fontSize: 13.5, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 2, color: green.withOpacity(0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModernDialog(
      context: context,
      title: l10n?.logout ?? 'Logout',
      content: Text(
        l10n?.sidebarAreYouSureLogout ?? 'Are you sure you want to logout?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppTheme.greyColor),
      ),
      icon: const Icon(Icons.logout_rounded, color: AppTheme.primary, size: 32),
      actions: [
        ModernDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
        ModernDialogAction.danger(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(authProvider.notifier).logout();
          },
          text: l10n?.logout ?? 'Logout',
        ),
      ],
    );
  }
}

/// Misty mountain ridges and a soft fog bloom for the menu header.
class _DrawerMistPainter extends CustomPainter {
  const _DrawerMistPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w * 0.85, h * 0.2);
    canvas.drawCircle(
      center,
      w * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: center, radius: w * 0.7)),
    );

    Path ridge(double base, List<Offset> peaks) {
      final path = Path()..moveTo(w * 0.35, h * base);
      for (final p in peaks) {
        path.lineTo(w * p.dx, h * p.dy);
      }
      path
        ..lineTo(w, h * base)
        ..lineTo(w, h)
        ..lineTo(w * 0.35, h)
        ..close();
      return path;
    }

    canvas.drawPath(
      ridge(0.40, const [
        Offset(0.50, 0.30),
        Offset(0.60, 0.36),
        Offset(0.72, 0.18),
        Offset(0.84, 0.30),
        Offset(0.95, 0.22),
      ]),
      Paint()..color = Colors.white.withOpacity(0.05),
    );
    canvas.drawPath(
      ridge(0.55, const [
        Offset(0.48, 0.50),
        Offset(0.62, 0.40),
        Offset(0.76, 0.48),
        Offset(0.88, 0.36),
      ]),
      Paint()..color = Colors.black.withOpacity(0.06),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Two soft mint waves along the bottom of the drawer.
class _DrawerWavePainter extends CustomPainter {
  final bool isDark;
  const _DrawerWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = isDark ? const Color(0xFF10B981) : const Color(0xFF7FD3A8);

    final back = Path()
      ..moveTo(w * 0.25, h)
      ..quadraticBezierTo(w * 0.55, h * 0.55, w, h * 0.35)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
        back, Paint()..color = base.withOpacity(isDark ? 0.10 : 0.18));

    final front = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.45, h * 0.70, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        front, Paint()..color = base.withOpacity(isDark ? 0.08 : 0.14));
  }

  @override
  bool shouldRepaint(covariant _DrawerWavePainter old) => old.isDark != isDark;
}
