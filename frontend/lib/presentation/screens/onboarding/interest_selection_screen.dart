import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/models/category.dart' as models;

final _storageManager = StorageManager();

// ─── Shared design tokens ─────────────────────────────────────────────────────
const _kAccent      = Color(0xFF10B981);
const _kAccentDark  = Color(0xFF059669);
// Cards shown before "View more interests" expands the rest.
const _kCollapsedCount = 8;

class InterestSelectionScreen extends ConsumerStatefulWidget {
  final bool isEditMode;

  const InterestSelectionScreen({super.key, this.isEditMode = false});

  @override
  _InterestSelectionScreenState createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends ConsumerState<InterestSelectionScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedInterests = {};
  bool _interestsInitialized = false;
  bool _entryChecked = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _animController;
  String? _hoveredId;
  bool _showAllInterests = false;

  // ─── Fixed dark theme to match language screen ─────────────────────────────
  Color get _backgroundColor => const Color(0xFF071810);
  Color get _cardColor => const Color(0xFF1E293B);
  Color get _textColor => Colors.white;
  Color get _subtitleColor => const Color(0xFF94A3B8);
  Color get _unselectedCardBg => Colors.white.withOpacity(0.06);
  Color get _borderColor => Colors.white.withOpacity(0.1);
  Color get _accentColor => const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isMobile = !isDesktop && !isTablet;
    final l10n = AppLocalizations.of(context);

    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/auth-selection');
      });
      return const SizedBox.shrink();
    }

    // Outside edit mode, don't ask again for interests the user already gave
    // (or anything else already collected) — move on to the next missing step.
    // Checked only on entry so returning here via Back still allows editing.
    if (!widget.isEditMode && !_entryChecked) {
      _entryChecked = true;
      final user = authState.user!;
      if (user.hasCompletedOnboarding || userHasInterests(user)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) continueAfterAuth(context, ref);
        });
        return const SizedBox.shrink();
      }
    }

    // Pre-populate with previously saved interests (skip + come back, or edit)
    if (!_interestsInitialized) {
      final savedInterests = authState.user!.interests;
      if (savedInterests != null && savedInterests.isNotEmpty) {
        _selectedInterests.addAll(savedInterests);
      }
      _interestsInitialized = true;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          _buildFloatingAnimation(),
          SafeArea(
            child: isDesktop ? _buildDesktopLayout(l10n) : (isTablet ? _buildTabletLayout(l10n) : _buildMobileLayout(l10n)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A0F),
            Color(0xFF0A2415),
            Color(0xFF071810),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAnimation() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value;
        return Stack(
          children: [
            Positioned(
              top: -100 + 30 * sin(t * 2 * pi),
              right: -100 + 20 * cos(t * 2 * pi),
              child: _glowCircle(400, const Color(0xFF00C896).withOpacity(0.15), 70),
            ),
            Positioned(
              bottom: 80 + 40 * cos(t * 2 * pi + 1),
              left: -120 + 30 * sin(t * 2 * pi + 1),
              child: _glowCircle(300, const Color(0xFF34D399).withOpacity(0.1), 55),
            ),
            ...List.generate(12, (i) {
              final random = Random(i);
              final p = Offset(random.nextDouble(), random.nextDouble());
              final size = random.nextDouble() * 36 + 8;
              final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.15 + 0.08 * sin(t * 2 * pi + i),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _glowCircle(double size, Color color, double blur) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(AppLocalizations? l10n) {
    return Row(
      children: [
        const Expanded(
          flex: 45,
          child: DesktopBrandPanel(
            headline: 'Personalize Your',
            title: 'Learning\nJourney',
            tagline: 'Choose the topics that matter\nmost to you.',
          ),
        ),
        Expanded(
          flex: 55,
          child: Container(
            color: const Color(0xFF0A2415),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                  child: _buildContent(l10n, isDesktop: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tablet layout ───────────────────────────────────────────────────────────
  Widget _buildTabletLayout(AppLocalizations? l10n) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, isSmall ? 16 : 24, 32, 0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.45),
                          blurRadius: 24,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 14,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Excellence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Coaching Hub',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isSmall ? 14 : 20),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 8,
                ),
                child: _buildContent(l10n, isDesktop: false, isTablet: true, isSmall: isSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout ───────────────────────────────────────────────────────────
  Widget _buildMobileLayout(AppLocalizations? l10n) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;
    final isVerySmall = size.height < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, isVerySmall ? 8 : (isSmall ? 12 : 16), 16, 0),
              child: Row(
                children: [
                  Container(
                    width: isVerySmall ? 48 : 52,
                    height: isVerySmall ? 48 : 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: EdgeInsets.all(isVerySmall ? 5 : 6),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Excellence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVerySmall ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Coaching Hub',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: isVerySmall ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isVerySmall ? 6 : (isSmall ? 10 : 14)),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isVerySmall ? 12 : 16,
                  right: isVerySmall ? 12 : 16,
                  bottom: 8,
                ),
                child: _buildContent(l10n, isDesktop: false, isTablet: false, isSmall: isSmall, isVerySmall: isVerySmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared content builder ──────────────────────────────────────────────────
  Widget _buildContent(AppLocalizations? l10n, {required bool isDesktop, bool isTablet = false, bool isSmall = false, bool isVerySmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          Text(
            l10n?.onboardingInterestTitle ?? 'What are you interested in?',
            style: TextStyle(
              fontSize: isTablet ? 28 : (isSmall ? 22 : (isVerySmall ? 18 : 24)),
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isVerySmall ? 4 : 6),
          Text(
            l10n?.onboardingInterestSubtitle ?? 'Pick the coaching areas you want to focus on',
            style: TextStyle(
              fontSize: isTablet ? 14 : (isVerySmall ? 11 : 13),
              color: _subtitleColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 18 : (isSmall ? 10 : 14)),
        ] else ...[
          // The brand panel on the left already shows the logo, so the form
          // column starts straight with the question.
          Text(
            l10n?.onboardingInterestTitle ?? 'What are you interested in?',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingInterestSubtitle ?? 'Pick the coaching areas you want to focus on',
            style: TextStyle(
              fontSize: 15,
              color: _subtitleColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],

        // Desktop content already sits inside a SingleChildScrollView (unbounded
        // height), so it can't use Expanded here - that requires a bounded parent.
        if (isDesktop)
          _buildInterestsGrid(l10n, isDesktop: true)
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildInterestsGrid(l10n, isDesktop: false, isTablet: isTablet),
            ),
          ),

        SizedBox(height: isDesktop ? 28 : (isTablet ? 20 : (isVerySmall ? 10 : 14))),

        // Continue button
        _buildModernContinueButton(isDesktop: isDesktop, isTablet: isTablet, l10n: l10n),

        // Skip button - always visible
        SizedBox(height: isDesktop ? 8 : 4),
        _buildModernSkipButton(l10n),
      ],
    );
  }

  // ─── Interest grouping ───────────────────────────────────────────────────────
  // Categories come from the backend, so they are grouped by keywords in their
  // names. Anything unmatched falls into a trailing "other" group.
  static const _groupOrder = ['career', 'education', 'personal', 'other'];

  String _groupFor(String name) {
    final n = name.toLowerCase();
    bool has(List<String> keys) => keys.any(n.contains);
    if (has(['mental', 'parent', 'leader', 'manage', 'personal', 'wellbeing', 'health'])) {
      return 'personal';
    }
    if (has(['primary', 'school', 'academic', 'language', 'laguange', 'exam', 'student', 'university'])) {
      return 'education';
    }
    if (has(['digital', 'tech', 'business', 'entrepreneur', 'job', 'career', 'account', 'finance', 'professional'])) {
      return 'career';
    }
    return 'other';
  }

  String _groupLabel(String group, bool isRw) {
    switch (group) {
      case 'career':
        return isRw ? 'UMWUGA N\'AKAZI' : 'CAREER & PROFESSIONAL';
      case 'education':
        return isRw ? 'UBUREZI' : 'EDUCATION';
      case 'personal':
        return isRw ? 'ITERAMBERE RYAWE BWITE' : 'PERSONAL DEVELOPMENT';
      default:
        return isRw ? 'IBINDI' : 'MORE';
    }
  }

  /// Short "what's inside" line shown under each interest name.
  String? _taglineFor(String name) {
    final n = name.toLowerCase();
    bool has(List<String> keys) => keys.any(n.contains);
    if (has(['digital', 'tech'])) return 'AI • Coding • Digital skills';
    if (has(['entrepreneur', 'business'])) return 'Startups • Innovation • Growth';
    if (has(['job', 'career'])) return 'CVs • Interviews • Careers';
    if (has(['account', 'finance'])) return 'Bookkeeping • Finance • Tax';
    if (has(['language', 'laguange'])) return 'English • French • Kiswahili';
    if (has(['mental', 'parent'])) return 'Wellbeing • Family • Parenting';
    if (has(['leader', 'manage'])) return 'Teams • Leadership • Strategy';
    if (has(['primary'])) return 'Primary pupils • Homework help';
    if (has(['academic', 'school', 'exam'])) return 'Exams • Study skills';
    return null;
  }

  String _displayName(String name) => name.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ' & ');

  Widget _buildInterestsGrid(AppLocalizations? l10n, {required bool isDesktop, bool isTablet = false}) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isRw = Localizations.localeOf(context).languageCode == 'rw';

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, color: _subtitleColor, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.noCategoriesAvailable ?? 'No categories available',
                    style: TextStyle(color: _subtitleColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Order categories by group, then collapse to the first few unless the
        // user asked to see everything. Selected interests always stay visible.
        final ordered = [
          for (final g in _groupOrder) ...categories.where((c) => _groupFor(c.name) == g),
        ];
        final canCollapse = ordered.length > _kCollapsedCount;
        final visible = (!canCollapse || _showAllInterests)
            ? ordered
            : [
                for (var i = 0; i < ordered.length; i++)
                  if (i < _kCollapsedCount || _selectedInterests.contains(ordered[i].name)) ordered[i],
              ];

        final compact = !isDesktop && !isTablet;
        final sections = <Widget>[];
        for (final g in _groupOrder) {
          final items = visible.where((c) => _groupFor(c.name) == g).toList();
          if (items.isEmpty) continue;
          if (sections.isNotEmpty) sections.add(SizedBox(height: compact ? 14 : 18));
          sections.add(Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              _groupLabel(g, isRw),
              style: const TextStyle(
                color: _kAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ));
          sections.add(_buildCardRows(items, compact: compact));
        }

        if (canCollapse) {
          sections.add(const SizedBox(height: 10));
          sections.add(Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAllInterests = !_showAllInterests),
              style: TextButton.styleFrom(foregroundColor: _kAccent),
              icon: Icon(
                _showAllInterests ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
              ),
              label: Text(
                _showAllInterests
                    ? (isRw ? 'Erekana bike' : 'Show fewer')
                    : (isRw ? 'Reba ibindi' : 'View more interests'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections,
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(_kAccent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.loading ?? 'Loading...',
                style: TextStyle(color: _subtitleColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7F1D1D).withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: const Color(0xFFFCA5A5),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                l10n?.failedToLoadCategories ?? 'Failed to load categories',
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lays cards out two per row; each row takes the height of its taller card.
  Widget _buildCardRows(List<models.Category> items, {required bool compact}) {
    final gap = compact ? 10.0 : 12.0;
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildInterestCard(items[i], compact: compact)),
            SizedBox(width: gap),
            Expanded(
              child: i + 1 < items.length
                  ? _buildInterestCard(items[i + 1], compact: compact)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _buildInterestCard(models.Category category, {required bool compact}) {
    final interest = category.name;
    final isSelected = _selectedInterests.contains(interest);
    final isHovered = _hoveredId == category.id;
    final color = CategoryUtils.getCategoryColor(category.id, name: category.name);
    final tagline = _taglineFor(interest);

    return MouseRegion(
      key: ValueKey(category.id),
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredId = category.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: GestureDetector(
        onTap: () => setState(() {
          isSelected
              ? _selectedInterests.remove(interest)
              : _selectedInterests.add(interest);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.14)
                : isHovered
                    ? Colors.white.withOpacity(0.1)
                    : _unselectedCardBg,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.9)
                  : isHovered
                      ? Colors.white.withOpacity(0.2)
                      : _borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 34 : 38,
                    height: compact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.18) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CategoryUtils.getCategoryIcon(category.id, name: category.name),
                      color: isSelected ? color : _subtitleColor,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Text(
                    _displayName(interest),
                    style: TextStyle(
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tagline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11.5,
                        color: _subtitleColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              // Selected tick - the whole card is the tap target, so there is
              // no radio; the tick only appears once chosen.
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedScale(
                  scale: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildModernContinueButton({required bool isDesktop, required bool isTablet, AppLocalizations? l10n}) {
    final hasSelection = _selectedInterests.isNotEmpty;
    final isMobile = !isDesktop && !isTablet;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasSelection ? _handleContinue : null,
        splashColor: hasSelection ? Colors.white.withOpacity(0.2) : Colors.transparent,
        highlightColor: hasSelection ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : (isTablet ? 12 : 10)),
        child: Ink(
          height: isDesktop ? 54 : (isTablet ? 50 : 48),
          decoration: BoxDecoration(
            gradient: hasSelection
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C896), Color(0xFF059669)],
                  )
                : null,
            color: hasSelection ? null : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(isDesktop ? 14 : (isTablet ? 12 : 10)),
            boxShadow: hasSelection
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.35),
                      blurRadius: isDesktop ? 20 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.continueText ?? 'Continue',
                  style: TextStyle(
                    color: hasSelection
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (hasSelection) ...[
                  SizedBox(width: isDesktop ? 8 : 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isDesktop ? 18 : (isTablet ? 16 : 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSkipButton(AppLocalizations? l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleSkip,
        splashColor: _subtitleColor.withOpacity(0.2),
        highlightColor: _subtitleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            l10n?.skipForNow ?? 'Skip for now',
            style: TextStyle(
              color: _subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() async {
    // Store selected interests and check phone number
    try {
      await ref.read(authProvider.notifier).updateProfile(
        interests: _selectedInterests.toList(),
      );
      
      if (mounted) {
        // In edit mode, just go back to previous screen
        if (widget.isEditMode) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
          return;
        }

        await _goToNextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSkip() async {
    // Skip interests and check phone number
    if (mounted) {
      // In edit mode, just go back to previous screen
      if (widget.isEditMode) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
        return;
      }

      await _goToNextStep();
    }
  }

  /// Phone collection only when the user hasn't already given a phone number
  /// (e.g. at registration or via phone sign-in); otherwise finish onboarding.
  Future<void> _goToNextStep() async {
    final user = ref.read(authProvider).user;
    if (user != null && !userHasPhone(user)) {
      context.push('/phone-collection');
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(authProvider.notifier).updateProfile(
        hasCompletedOnboarding: true,
      );

      // Ensure local flag is persisted so the user is not routed back to onboarding
      await _storageManager.saveHasCompletedOnboarding(true);

      if (mounted) await goHome(context, ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
