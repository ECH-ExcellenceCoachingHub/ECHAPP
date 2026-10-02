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

final _storageManager = StorageManager();

// ─── Shared design tokens ─────────────────────────────────────────────────────
const _kAccent      = Color(0xFF10B981);
const _kAccentDark  = Color(0xFF059669);

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
  int _hoveredIndex = -1;
  final ScrollController _desktopScrollController = ScrollController();
  bool _desktopCanScrollMore = false;

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

    _desktopScrollController.addListener(_updateDesktopScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateDesktopScrollHint());
  }

  // Shows a "scroll to continue" hint on desktop whenever the interests list
  // is taller than the visible panel, so the Continue/Skip buttons below it
  // aren't missed. Re-evaluated on every scroll/content-size change.
  void _updateDesktopScrollHint() {
    if (!mounted || !_desktopScrollController.hasClients) return;
    final position = _desktopScrollController.position;
    final canScrollMore = position.maxScrollExtent > 0 &&
        _desktopScrollController.offset < position.maxScrollExtent - 12;
    if (canScrollMore != _desktopCanScrollMore) {
      setState(() => _desktopCanScrollMore = canScrollMore);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _animController.dispose();
    _desktopScrollController.removeListener(_updateDesktopScrollHint);
    _desktopScrollController.dispose();
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
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      controller: _desktopScrollController,
                      padding: const EdgeInsets.fromLTRB(48, 40, 48, 64),
                      child: _buildContent(l10n, isDesktop: true),
                    ),
                  ),
                ),
                _buildDesktopScrollHint(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopScrollHint() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: IgnorePointer(
        ignoring: !_desktopCanScrollMore,
        child: AnimatedOpacity(
          opacity: _desktopCanScrollMore ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (!_desktopScrollController.hasClients) return;
                _desktopScrollController.animateTo(
                  _desktopScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _kAccent.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scroll to continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          SizedBox(height: isTablet ? 18 : (isSmall ? 12 : (isVerySmall ? 8 : 14))),
          if (!isTablet)
            SizedBox(
              height: isVerySmall ? 80 : (isSmall ? 100 : 120),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 4 : 8),
                child: Image.asset(
                  'assets/Course app-bro.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (!isTablet)
            SizedBox(height: isSmall ? 12 : (isVerySmall ? 8 : 16)),
        ] else ...[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00C896).withOpacity(0.3),
                  const Color(0xFF00C896).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.onboardingInterestTitle ?? 'What are you interested in?',
            style: const TextStyle(
              fontSize: 32,
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

        // Interests grid - scrollable for long lists.
        // Desktop content already sits inside a SingleChildScrollView (unbounded
        // height), so it can't use Expanded here - that requires a bounded parent
        // and throws a RenderFlex layout error. Let the grid size itself instead.
        if (isDesktop)
          _buildInterestsGrid(l10n, isDesktop: isDesktop, isTablet: isTablet, isMobile: !isDesktop && !isTablet)
        else
          Expanded(
            child: _buildInterestsGrid(l10n, isDesktop: isDesktop, isTablet: isTablet, isMobile: !isDesktop && !isTablet),
          ),

        SizedBox(height: isDesktop ? 40 : (isTablet ? 28 : (isSmall ? 16 : (isVerySmall ? 12 : 24)))),

        // Continue button
        _buildModernContinueButton(isDesktop: isDesktop, isTablet: isTablet, l10n: l10n),

        // Skip button - always visible
        const SizedBox(height: 16),
        _buildModernSkipButton(l10n),
      ],
    );
  }

  Widget _buildInterestsGrid(AppLocalizations? l10n, {required bool isDesktop, required bool isTablet, required bool isMobile}) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);

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

        // Use GridView for better organization and scrollability
        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 0 : (isTablet ? 16 : (isMobile ? 12 : 0)),
            vertical: isDesktop ? 0 : 8,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // Desktop content sits in a narrow (420px max) column, so 2 columns
            // there leaves too little width for icon + name + checkbox per card
            // (the category name gets squeezed down to a single visible letter).
            crossAxisCount: isDesktop ? 1 : (isTablet ? 2 : 1),
            crossAxisSpacing: isDesktop ? 12 : (isTablet ? 10 : 8),
            mainAxisSpacing: isDesktop ? 16 : (isTablet ? 10 : 8),
            childAspectRatio: isDesktop ? 3.6 : (isTablet ? 3.0 : 4.0),
          ),
          itemCount: categories.length,
          shrinkWrap: true,
          // Desktop nests this grid inside the outer SingleChildScrollView, so it
          // must defer scrolling to that ancestor instead of fighting it for gestures.
          physics: isDesktop ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final category = categories[index];
            final interest = category.name;
            final isSelected = _selectedInterests.contains(interest);
            final isHovered = _hoveredIndex == index;
            final color = CategoryUtils.getCategoryColor(category.id, name: category.name);

            return MouseRegion(
              key: ValueKey(category.id),
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = -1),
              child: GestureDetector(
                onTap: () => setState(() {
                  isSelected
                      ? _selectedInterests.remove(interest)
                      : _selectedInterests.add(interest);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(isDesktop ? 18 : (isTablet ? 14 : (isMobile ? 10 : 12))),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : isHovered
                            ? Colors.white.withOpacity(0.1)
                            : _unselectedCardBg,
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : (isTablet ? 14 : 12)),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : isHovered
                              ? Colors.white.withOpacity(0.2)
                              : _borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: isDesktop ? 16 : 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : isHovered
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: isDesktop ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: isDesktop ? 48 : (isTablet ? 42 : (isMobile ? 36 : 40)),
                        height: isDesktop ? 48 : (isTablet ? 42 : (isMobile ? 36 : 40)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(isDesktop ? 12 : (isTablet ? 10 : 8)),
                          border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CategoryUtils.getCategoryIcon(category.id, name: category.name),
                            color: isSelected ? color : _subtitleColor,
                            size: isDesktop ? 24 : (isTablet ? 20 : (isMobile ? 16 : 18)),
                          ),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : (isTablet ? 10 : (isMobile ? 6 : 8))),

                      // Interest name
                      Expanded(
                        child: Text(
                          interest,
                          style: TextStyle(
                            fontSize: isDesktop ? 17 : (isTablet ? 15 : (isMobile ? 13 : 14)),
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Check indicator
                      SizedBox(width: isDesktop ? 12 : (isTablet ? 10 : (isMobile ? 6 : 8))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isDesktop ? 22 : (isTablet ? 20 : (isMobile ? 18 : 20)),
                        height: isDesktop ? 22 : (isTablet ? 20 : (isMobile ? 18 : 20)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? color : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFF64748B),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: isDesktop ? 14 : (isTablet ? 12 : (isMobile ? 10 : 11)),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
