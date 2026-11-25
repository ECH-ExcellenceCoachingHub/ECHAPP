import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/widgets/enhanced_course_navigation.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/widgets/search/search_suggestions.dart';

// Desktop course-grid metrics. The card height is derived from these, so any
// change to the card's padding or body rows belongs here too.
const double _kDesktopCardMaxWidth = 300;
const double _kDesktopCardSpacing = 16;
const double _kDesktopCardPadding = 14;

/// Everything below the thumbnail: padding, title (2 lines), instructor, meta
/// row, rating row and the price/action row. Measured content is ~176px; the
/// remainder is slack absorbed by the Spacer so font-metric differences across
/// platforms cannot overflow the cell.
const double _kDesktopCardBodyHeight = 206;

class CoursesScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? searchQuery;

  const CoursesScreen(
      {super.key, this.categoryId, this.categoryName, this.searchQuery});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all';
  String? _selectedCategoryName;
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  Timer? _searchDebounce;
  static const int _pageSize = 20;

  String? _errorMessage;
  bool _showCategoryDropdown = false;
  bool _showFiltersPanel = false;
  List<String> _userInterests = [];

  // Filter states
  String _selectedPriceFilter = 'all'; // all, free, paid
  String _selectedLevelFilter = 'all'; // all, beginner, intermediate, advanced
  String _selectedDurationFilter = 'all'; // all, short, medium, long
  String _selectedRatingFilter = 'all'; // all, 4plus, 4.5plus

  final CourseRepository _repository = CourseRepository();
  final LiveSessionService _liveSessionService = LiveSessionService();

  // Track courses with upcoming sessions
  final Map<String, List<LiveSession>> _courseUpcomingSessions = {};
  Future<void>? _loadUpcomingSessionsFuture;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    // Preload categories for faster access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryPreloadProvider);
    });

    _scrollController.addListener(_onScroll);

    // Initialize from widget parameters
    _initializeFromWidgetParams();

    // Load user interests and then courses
    _loadUserInterestsAndCourses();
  }

  Future<void> _loadUpcomingSessionsForEnrolledCourses(List<Course> enrolledCourses) async {
    if (enrolledCourses.isEmpty) return;
    
    _courseUpcomingSessions.clear();
    
    for (final course in enrolledCourses) {
      try {
        final response = await _liveSessionService.getCourseSessions(
          course.id,
          status: 'scheduled',
          limit: 5,
        );
        final now = DateTime.now();
        final upcoming = response.sessions.where((s) {
          return !s.isEnded &&
              !s.isCancelled &&
              s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
        }).toList();
        
        if (upcoming.isNotEmpty) {
          _courseUpcomingSessions[course.id] = upcoming;
        }
      } catch (e) {
        debugPrint('Error loading sessions for course ${course.id}: $e');
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeFromWidgetParams() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _searchController.text = widget.searchQuery!;
    }
    if (widget.categoryId != null) {
      _selectedCategory = widget.categoryId!;
      _selectedCategoryName = widget.categoryName;
    }
  }

  @override
  void didUpdateWidget(CoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // With unique keys in router, this rarely gets called for new navigation
    // Only handle case where widget is updated in-place (same screen, new params)
    if (widget.searchQuery != oldWidget.searchQuery || 
        widget.categoryId != oldWidget.categoryId) {
      if (widget.searchQuery != null) {
        _searchController.text = widget.searchQuery!;
      }
      if (widget.categoryId != null) {
        _selectedCategory = widget.categoryId!;
        _selectedCategoryName = widget.categoryName;
      }
      
      if (mounted) {
        _loadPage(1, reset: true);
      }
    }
  }

  Future<void> _loadUserInterestsAndCourses() async {
    // Load user interests from storage
    final storageManager = StorageManager();
    final interests = await storageManager.getUserInterests();
    final authState = ref.read(authProvider);
    
    // Use interests from auth state if available, otherwise from storage
    final userInterests = authState.user?.interests ?? interests ?? [];
    
    if (mounted) {
      setState(() {
        _userInterests = userInterests;
      });
    }
    
    debugPrint('CoursesScreen: User interests loaded: $_userInterests');
    
    // Load initial page with debounce for better performance
    await _loadPage(1, reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadPage(int page, {bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final effectiveCategory = _selectedCategory == 'all' ? null : _selectedCategory;
      final effectiveSearch = _searchController.text.isNotEmpty ? _searchController.text : null;
      
      final result = await _repository.getCoursesPaged(
        page: page,
        limit: _pageSize,
        categoryId: effectiveCategory,
        search: effectiveSearch,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _allCourses = result.courses;
        } else {
          _allCourses = [..._allCourses, ...result.courses];
        }
        _currentPage = result.currentPage;
        _hasMore = result.hasNextPage;
        _isLoading = false;
        _isLoadingMore = false;
        // Apply filters and sort by interests
        var courses = _applyFilters(_allCourses);
        _filteredCourses = _sortCoursesByInterests(courses);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_currentPage + 1);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCourses() {
    if (!mounted) return;
    debugPrint(
        'CoursesScreen: Reloading courses for category $_selectedCategory');
    _loadPage(1, reset: true);
  }

  /// Apply client-side filters to courses
  List<Course> _applyFilters(List<Course> courses) {
    return courses.where((course) {
      // Price filter
      if (_selectedPriceFilter != 'all') {
        final price = course.price ?? 0;
        if (_selectedPriceFilter == 'free' && price > 0) return false;
        if (_selectedPriceFilter == 'paid' && price == 0) return false;
      }

      // Level filter
      if (_selectedLevelFilter != 'all') {
        final level = course.level.toLowerCase();
        if (_selectedLevelFilter == 'beginner' && !level.contains('beginner')) return false;
        if (_selectedLevelFilter == 'intermediate' && !level.contains('intermediate')) return false;
        if (_selectedLevelFilter == 'advanced' && !level.contains('advanced')) return false;
      }

      // Duration filter (in minutes)
      if (_selectedDurationFilter != 'all') {
        final duration = course.duration ?? 0;
        if (_selectedDurationFilter == 'short' && duration > 60) return false;
        if (_selectedDurationFilter == 'medium' && (duration <= 60 || duration > 180)) return false;
        if (_selectedDurationFilter == 'long' && duration <= 180) return false;
      }

      // Rating filter
      if (_selectedRatingFilter != 'all') {
        final rating = course.averageRating ?? 0;
        if (_selectedRatingFilter == '4plus' && rating < 4.0) return false;
        if (_selectedRatingFilter == '4.5plus' && rating < 4.5) return false;
      }

      return true;
    }).toList();
  }

  /// Sort courses to prioritize those matching user interests
  List<Course> _sortCoursesByInterests(List<Course> courses) {
    if (_userInterests.isEmpty) return courses;

    return courses.toList()..sort((a, b) {
      final aScore = _getCourseInterestScore(a);
      final bScore = _getCourseInterestScore(b);
      // Higher score comes first (descending order)
      return bScore.compareTo(aScore);
    });
  }

  /// Calculate how well a course matches user interests (0-10 scale)
  int _getCourseInterestScore(Course course) {
    if (_userInterests.isEmpty) return 0;

    int score = 0;
    final courseCategory = _getCourseCategoryName(course).toLowerCase();
    
    for (final interest in _userInterests) {
      final interestLower = interest.toLowerCase();
      
      // Direct category match (highest priority)
      if (courseCategory.contains(interestLower) || 
          interestLower.contains(courseCategory)) {
        score += 5;
      }
      
      // Title match
      final title = (course.title ?? '').toLowerCase();
      if (title.contains(interestLower)) {
        score += 3;
      }
      
      // Description match
      final description = (course.description ?? '').toLowerCase();
      if (description.contains(interestLower)) {
        score += 2;
      }
    }
    
    return score;
  }

  /// Get category name from course
  String _getCourseCategoryName(Course course) {
    if (course.category != null) {
      final categoryMap = course.category!;
      return categoryMap['name'] as String? ?? '';
    }
    
    // Fallback to categoryId mapping
    final categoryMapping = {
      '69c503cb27858856e87d0027': 'Digital and Tech coaching',
      '69c50aa727858856e87d003f': 'Entrepreneurship & Innovation Hub',
      '69c5067c27858856e87d002f': 'Jobseeker Coaching',
      '69c5017a27858856e87d001f': 'Language coaching',
      '69c5116627858856e87d004f': 'Mental Health & Parental Coaching',
      '69c50a3327858856e87d0037': 'Professional Coaching',
    };
    
    return categoryMapping[course.categoryId] ?? '';
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _filterCourses);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

    // Cache MediaQuery results to avoid repeated expensive lookups
    final mediaQueryData = MediaQuery.of(context);
    final screenWidth = mediaQueryData.size.width;
    final isDark = mediaQueryData.platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let MainLayout background show through
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            // Search Bar
            _buildResponsiveSearchBar(context),
            _buildActiveCategoryChip(context),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                ResponsiveBreakpoints.getPadding(context).left,
                                4,
                                ResponsiveBreakpoints.getPadding(context)
                                    .right,
                                16,
                              ),
                              sliver: enrolledCoursesAsync.when(
                                data: (enrolledCourses) {
                                  // Load upcoming sessions for enrolled courses
                                  if (_loadUpcomingSessionsFuture == null) {
                                    _loadUpcomingSessionsFuture = _loadUpcomingSessionsForEnrolledCourses(enrolledCourses);
                                  }
                                  return _buildSliverAllCourses(context,
                                      _filteredCourses, enrolledCourses);
                                },
                                loading: () => const SliverToBoxAdapter(
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                error: (err, stack) => _buildSliverAllCourses(
                                    context, _filteredCourses, []),
                              ),
                            ),
                            if (_isLoadingMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primaryGreen),
                                  ),
                                ),
                              ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 40)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: _getResponsiveHorizontalPadding(context),
            vertical: _getResponsiveVerticalPadding(context) * 0.5,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: SearchSuggestions(
                  controller: _searchController,
                  load: CourseSuggestionsApi.load,
                  onSelected: (s) => context.push('/course/${s.id}'),
                  onSearchAll: (_) {},
                  child: 
TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: _getResponsiveTextSize(context) * 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedCategory == 'all'
                        ? (l10n?.searchCourses ?? 'Search courses, instructors...')
                        : 'Search in ${_selectedCategoryName ?? ''}...',
                    hintStyle: TextStyle(
                      color: AppTheme.greyColor.withOpacity(0.7),
                      fontSize: _getResponsiveTextSize(context) * 1.1,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF10B981),
                        size: _getResponsiveIconSize(context) * 0.8,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            tooltip: l10n?.clear ?? 'Clear search',
                            icon: Icon(
                              Icons.clear_rounded,
                              color: AppTheme.greyColor,
                              size: _getResponsiveIconSize(context) * 0.7,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterCourses();
                              setState(() {});
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            tooltip: l10n?.filterCourses ?? 'Filter courses',
                            onPressed: () {
                              setState(() => _showFiltersPanel = !_showFiltersPanel);
                            },
                            icon: Icon(
                              _showFiltersPanel
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.tune_rounded,
                              color: _hasActiveFilters()
                                  ? const Color(0xFF0F766E)
                                  : (isDark ? Colors.white70 : const Color(0xFF9A8A76)),
                              size: _getResponsiveIconSize(context) * 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveHorizontalPadding(context) * 0.5,
                      vertical: _getResponsiveVerticalPadding(context) * 1.2,
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
        if (_showCategoryDropdown)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding(context),
            ),
            child: _buildCategoryDropdown(context),
          ),
        // Filters Panel
        if (_showFiltersPanel)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding(context),
            ),
            child: _buildFiltersPanel(context),
          ),
        // Active Filters Chips
        if (_hasActiveFilters())
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding(context),
              vertical: 8,
            ),
            child: _buildActiveFiltersChips(context),
          ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedPriceFilter != 'all' ||
        _selectedLevelFilter != 'all' ||
        _selectedDurationFilter != 'all' ||
        _selectedRatingFilter != 'all';
  }

  Widget _buildFiltersPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.filterCourses ?? 'Filter Courses',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPriceFilter = 'all';
                    _selectedLevelFilter = 'all';
                    _selectedDurationFilter = 'all';
                    _selectedRatingFilter = 'all';
                  });
                  _filterCourses();
                },
                icon: Icon(Icons.clear_all, size: 16, color: AppTheme.greyColor),
                label: Text(
                  l10n?.clearAll ?? 'Clear All',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Price Filter
          _buildFilterSection(
            context,
            l10n?.price ?? 'Price',
            [
              _buildFilterChip(l10n?.all ?? 'All', 'all', _selectedPriceFilter, (val) {
                setState(() => _selectedPriceFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.free ?? 'Free', 'free', _selectedPriceFilter, (val) {
                setState(() => _selectedPriceFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.paid ?? 'Paid', 'paid', _selectedPriceFilter, (val) {
                setState(() => _selectedPriceFilter = val);
                _filterCourses();
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Level Filter
          _buildFilterSection(
            context,
            l10n?.level ?? 'Level',
            [
              _buildFilterChip(l10n?.all ?? 'All', 'all', _selectedLevelFilter, (val) {
                setState(() => _selectedLevelFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.beginner ?? 'Beginner', 'beginner', _selectedLevelFilter, (val) {
                setState(() => _selectedLevelFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.intermediate ?? 'Intermediate', 'intermediate', _selectedLevelFilter, (val) {
                setState(() => _selectedLevelFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.advanced ?? 'Advanced', 'advanced', _selectedLevelFilter, (val) {
                setState(() => _selectedLevelFilter = val);
                _filterCourses();
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Duration Filter
          _buildFilterSection(
            context,
            l10n?.duration ?? 'Duration',
            [
              _buildFilterChip(l10n?.all ?? 'All', 'all', _selectedDurationFilter, (val) {
                setState(() => _selectedDurationFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.short ?? 'Short (<1h)', 'short', _selectedDurationFilter, (val) {
                setState(() => _selectedDurationFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.medium ?? 'Medium (1-3h)', 'medium', _selectedDurationFilter, (val) {
                setState(() => _selectedDurationFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.long ?? 'Long (>3h)', 'long', _selectedDurationFilter, (val) {
                setState(() => _selectedDurationFilter = val);
                _filterCourses();
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Rating Filter
          _buildFilterSection(
            context,
            l10n?.rating ?? 'Rating',
            [
              _buildFilterChip(l10n?.all ?? 'All', 'all', _selectedRatingFilter, (val) {
                setState(() => _selectedRatingFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.stars4Plus ?? '4+ Stars', '4plus', _selectedRatingFilter, (val) {
                setState(() => _selectedRatingFilter = val);
                _filterCourses();
              }),
              _buildFilterChip(l10n?.stars4_5Plus ?? '4.5+ Stars', '4.5plus', _selectedRatingFilter, (val) {
                setState(() => _selectedRatingFilter = val);
                _filterCourses();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final isSelected = value == selectedValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.getTextColor(context),
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chips = <Widget>[];

    if (_selectedPriceFilter != 'all') {
      chips.add(_buildActiveFilterChip(
        _getFilterLabel('price', _selectedPriceFilter),
        () {
          setState(() => _selectedPriceFilter = 'all');
          _filterCourses();
        },
      ));
    }
    if (_selectedLevelFilter != 'all') {
      chips.add(_buildActiveFilterChip(
        _getFilterLabel('level', _selectedLevelFilter),
        () {
          setState(() => _selectedLevelFilter = 'all');
          _filterCourses();
        },
      ));
    }
    if (_selectedDurationFilter != 'all') {
      chips.add(_buildActiveFilterChip(
        _getFilterLabel('duration', _selectedDurationFilter),
        () {
          setState(() => _selectedDurationFilter = 'all');
          _filterCourses();
        },
      ));
    }
    if (_selectedRatingFilter != 'all') {
      chips.add(_buildActiveFilterChip(
        _getFilterLabel('rating', _selectedRatingFilter),
        () {
          setState(() => _selectedRatingFilter = 'all');
          _filterCourses();
        },
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDelete) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: const Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String type, String value) {
    switch (type) {
      case 'price':
        return {
          'free': l10n?.free ?? 'Free',
          'paid': l10n?.paid ?? 'Paid',
        }[value] ?? value;
      case 'level':
        return {
          'beginner': l10n?.beginner ?? 'Beginner',
          'intermediate': l10n?.intermediate ?? 'Intermediate',
          'advanced': l10n?.advanced ?? 'Advanced',
        }[value] ?? value;
      case 'duration':
        return {
          'short': l10n?.short ?? 'Short',
          'medium': l10n?.medium ?? 'Medium',
          'long': l10n?.long ?? 'Long',
        }[value] ?? value;
      case 'rating':
        return {
          '4plus': l10n?.stars4Plus ?? '4+ Stars',
          '4.5plus': l10n?.stars4_5Plus ?? '4.5+ Stars',
        }[value] ?? value;
      default:
        return value;
    }
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _getResponsiveHorizontalPadding(context),
        _getResponsiveVerticalPadding(context),
        _getResponsiveHorizontalPadding(context),
        0,
      ),
      child: Row(
        children: [
          Material(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n?.courses ?? 'Courses',
              style: TextStyle(
                fontSize: _getResponsiveTextSize(context) * 1.45,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCategoryChip(BuildContext context) {
    if (_selectedCategory == 'all') return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final selectedName = categoriesAsync.maybeWhen(
      data: (categories) {
        for (final category in categories) {
          if (category.id == _selectedCategory) return category.name;
        }
        return widget.categoryName ?? (l10n?.selectedCategory ?? 'Selected category');
      },
      orElse: () => widget.categoryName ?? (l10n?.selectedCategory ?? 'Selected category'),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _getResponsiveHorizontalPadding(context),
        0,
        _getResponsiveHorizontalPadding(context),
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: const Icon(Icons.category_rounded, size: 18),
          label: Text(
            selectedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            setState(() {
              _selectedCategory = 'all';
              _selectedCategoryName = null;
            });
            _filterCourses();
          },
          backgroundColor:
              isDark ? const Color(0xFF14372E) : AppTheme.primarySoft,
          deleteIconColor: AppTheme.primaryDark,
          labelStyle: const TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: AppTheme.primary.withOpacity(0.18)),
        ),
      ),
    );
  }

  double _getResponsiveHorizontalPadding(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 8; // Ultra small screens
    } else if (screenWidth < 480) {
      return 12; // Small mobile screens
    } else if (screenWidth < 768) {
      return 16; // Standard mobile
    } else if (screenWidth < 1024) {
      return 20; // Tablets
    } else if (screenWidth < 1440) {
      return 24; // Small desktop
    } else {
      return 32; // Large desktop
    }
  }

  double _getResponsiveVerticalPadding(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 12; // Standard mobile
    } else if (screenWidth < 1024) {
      return 16; // Tablets
    } else if (screenWidth < 1440) {
      return 20; // Small desktop
    } else {
      return 24; // Large desktop
    }
  }

  int _getResponsiveCrossAxisCount(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 1; // Ultra small screens (old phones)
    } else if (screenWidth < 480) {
      return 2; // Small mobile screens
    } else if (screenWidth < 768) {
      return 2; // Standard mobile
    } else if (screenWidth < 1024) {
      return 3; // Tablets
    } else if (screenWidth < 1440) {
      return 4; // Small desktop
    } else {
      return 5; // Large desktop
    }
  }

  double _getResponsiveSpacing(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 4; // Ultra small screens
    } else if (screenWidth < 480) {
      return 6; // Small mobile screens
    } else if (screenWidth < 768) {
      return 8; // Standard mobile
    } else if (screenWidth < 1024) {
      return 10; // Tablets
    } else if (screenWidth < 1440) {
      return 12; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveAspectRatio(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 0.9; // Ultra small screens - more square
    } else if (screenWidth < 480) {
      return 1.0; // Small mobile screens
    } else if (screenWidth < 768) {
      return 1.1; // Standard mobile
    } else if (screenWidth < 1024) {
      return 1.2; // Tablets
    } else if (screenWidth < 1440) {
      return 1.3; // Small desktop
    } else {
      return 1.4; // Large desktop
    }
  }

  double _getResponsiveCardPadding(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 10; // Standard mobile
    } else if (screenWidth < 1024) {
      return 12; // Tablets
    } else if (screenWidth < 1440) {
      return 14; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveBorderRadius(BuildContext context,
      {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 10; // Standard mobile
    } else if (screenWidth < 1024) {
      return 12; // Tablets
    } else if (screenWidth < 1440) {
      return 14; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveIconSize(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 20; // Ultra small screens
    } else if (screenWidth < 480) {
      return 24; // Small mobile screens
    } else if (screenWidth < 768) {
      return 28; // Standard mobile
    } else if (screenWidth < 1024) {
      return 32; // Tablets
    } else if (screenWidth < 1440) {
      return 36; // Small desktop
    } else {
      return 40; // Large desktop
    }
  }

  double _getResponsiveIconRadius(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 4; // Ultra small screens
    } else if (screenWidth < 480) {
      return 6; // Small mobile screens
    } else if (screenWidth < 768) {
      return 8; // Standard mobile
    } else if (screenWidth < 1024) {
      return 10; // Tablets
    } else if (screenWidth < 1440) {
      return 12; // Small desktop
    } else {
      return 14; // Large desktop
    }
  }

  double _getResponsiveTextSize(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 11; // Ultra small screens
    } else if (screenWidth < 480) {
      return 12; // Small mobile screens
    } else if (screenWidth < 768) {
      return 13; // Standard mobile
    } else if (screenWidth < 1024) {
      return 14; // Tablets
    } else if (screenWidth < 1440) {
      return 15; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  Widget _buildCategoryLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 20),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.failedToLoadCategories ?? 'Failed to load categories',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.pleaseTryAgainLater ?? 'Please try again later',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCourseCard(BuildContext context, Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius:
              BorderRadius.circular(_getResponsiveBorderRadius(context) * 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Course Image with Overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              _getResponsiveBorderRadius(context) * 1.2),
                          topRight: Radius.circular(
                              _getResponsiveBorderRadius(context) * 1.2),
                        ),
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              _getResponsiveBorderRadius(context) * 1.2),
                          topRight: Radius.circular(
                              _getResponsiveBorderRadius(context) * 1.2),
                        ),
                        child: course.thumbnail != null &&
                                course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: course.thumbnail!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: Container(
                                  color: AppTheme.greyColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.greyColor,
                                    size: _getResponsiveIconSize(context) * 0.8,
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: const Color(0xFF10B981),
                                  size: _getResponsiveIconSize(context) * 0.8,
                                ),
                              ),
                      ),
                    ),
                    // Duration Badge
                    Positioned(
                      top: _getResponsiveSpacing(context) * 0.5,
                      right: _getResponsiveSpacing(context) * 0.5,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              _getResponsiveHorizontalPadding(context) * 0.3,
                          vertical:
                              _getResponsiveVerticalPadding(context) * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: _getResponsiveIconSize(context) * 0.4,
                            ),
                            SizedBox(
                                width: _getResponsiveSpacing(context) * 0.2),
                            Text(
                              course.formattedDuration,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveTextSize(context) * 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Course Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(_getResponsiveCardPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        course.title ?? (l10n?.untitledCourse ?? 'Untitled Course'),
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontSize: _getResponsiveTextSize(context) * 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context) * 0.3),
                      // Instructor
                      Text(
                        'by ${course.displayInstructor}',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: _getResponsiveTextSize(context) * 0.9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context) * 0.5),
                      // Stats Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  _getResponsiveHorizontalPadding(context) *
                                      0.3,
                              vertical:
                                  _getResponsiveVerticalPadding(context) * 0.2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  color: const Color(0xFF10B981),
                                  size: _getResponsiveIconSize(context) * 0.4,
                                ),
                                SizedBox(
                                    width:
                                        _getResponsiveSpacing(context) * 0.2),
                                Text(
                                  '${course.enrollmentCount ?? 0}',
                                  style: TextStyle(
                                    color: const Color(0xFF10B981),
                                    fontSize:
                                        _getResponsiveTextSize(context) * 0.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n?.failedToLoadCourses ?? 'Failed to load courses',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                initState();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.tryAgain ?? 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAllCourses(BuildContext context, List<Course> courses,
      List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (courses.isEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoursesHeader(context, courses.length),
            const SizedBox(height: 12),
            _buildNoCoursesFound(context),
          ],
        ),
      );
    }

    // Group courses by category (dynamically based on user interests)
    final groupedCourses = _groupCoursesByCategory(courses);

    // Build slivers for each category
    final slivers = <Widget>[];

    for (final entry in groupedCourses.entries) {
      final categoryName = entry.key;
      final categoryCourses = entry.value;

      if (categoryCourses.isEmpty) continue;

      // Add category header
      slivers.add(SliverToBoxAdapter(
        child:
            _buildCategoryHeader(context, categoryName, categoryCourses.length),
      ));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));

      // Add courses for this category
      if (categoryName == 'Recommended for You' || categoryName == l10n?.recommendedForYou) {
        // Use horizontal layout for recommended courses (like dashboard)
        final isMobile = ResponsiveBreakpoints.isMobile(context);
        slivers.add(SliverToBoxAdapter(
          child: SizedBox(
            height: isMobile ? 244 : 264,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categoryCourses.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildRecommendedCourseCard(
                    context, categoryCourses[index], enrolledCourses,
                  ),
                );
              },
            ),
          ),
        ));
      } else if (isDesktop) {
        // A ratio-based grid made cards taller as the window widened, leaving a
        // large dead gap above the price row. Cap the card width instead and
        // derive the height from the 16:9 thumbnail plus a fixed body.
        slivers.add(SliverLayoutBuilder(
          builder: (context, constraints) {
            final double available = constraints.crossAxisExtent;
            final int columns = (available /
                    (_kDesktopCardMaxWidth + _kDesktopCardSpacing))
                .ceil()
                .clamp(1, 8);
            final double cardWidth =
                (available - _kDesktopCardSpacing * (columns - 1)) / columns;
            final double thumbHeight =
                (cardWidth - _kDesktopCardPadding * 2) * 9 / 16;

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: _kDesktopCardSpacing,
                mainAxisSpacing: _kDesktopCardSpacing,
                mainAxisExtent: thumbHeight + _kDesktopCardBodyHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildResponsiveCourseCard(
                    context, categoryCourses[index], enrolledCourses),
                childCount: categoryCourses.length,
              ),
            );
          },
        ));
      } else {
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              child: _buildCourseListItem(
                  context, categoryCourses[index], enrolledCourses),
            ),
            childCount: categoryCourses.length,
          ),
        ));
      }

      // Add spacing between categories
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 18)));
    }

    return SliverMainAxisGroup(
      slivers: slivers,
    );
  }

  Widget _buildCategoryHeader(
      BuildContext context, String categoryName, int courseCount) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRecommended = categoryName == 'Recommended for You' || categoryName == l10n?.recommendedForYou;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isRecommended
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    )
                  : const LinearGradient(
                      colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecommended) ...[
                  Icon(
                    Icons.recommend_rounded,
                    color: Colors.white,
                    size: isDesktop ? 16 : 14,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isRecommended)
            Expanded(
              child: Text(
                'Based on your interests: ${_userInterests.take(3).join(", ")}${_userInterests.length > 3 ? "..." : ""}',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: isDesktop ? 13 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              '$courseCount courses',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: isDesktop ? 14 : 12,
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<Course>> _groupCoursesByCategory(List<Course> courses) {
    final Map<String, List<Course>> grouped = {};
    final List<String> interestMatchingCategories = [];
    final List<String> otherCategories = [];

    // First pass: categorize all courses and identify interest-matching categories
    for (final course in courses) {
      final categoryName = _getCourseCategoryName(course);
      
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
        
        // Check if this category matches user interests
        if (_categoryMatchesInterests(categoryName)) {
          interestMatchingCategories.add(categoryName);
        } else {
          otherCategories.add(categoryName);
        }
      }
      
      grouped[categoryName]!.add(course);
    }

    // Create final ordered map: Recommended (if interests exist) -> Interest categories -> Other categories -> Uncategorized
    final orderedGrouped = <String, List<Course>>{};
    
    // If user has interests, create a "Recommended for You" section with all matching courses
    if (_userInterests.isNotEmpty) {
      final recommendedCourses = <Course>[];
      for (final categoryName in interestMatchingCategories) {
        recommendedCourses.addAll(grouped[categoryName]!);
      }
      
      // Sort recommended courses by interest score
      recommendedCourses.sort((a, b) {
        final aScore = _getCourseInterestScore(a);
        final bScore = _getCourseInterestScore(b);
        return bScore.compareTo(aScore);
      });
      
      if (recommendedCourses.isNotEmpty) {
        orderedGrouped[l10n?.recommendedForYou ?? 'Recommended for You'] = recommendedCourses;
      }
    }
    
    // Add interest-matching categories first (sorted alphabetically)
    interestMatchingCategories.sort();
    for (final categoryName in interestMatchingCategories) {
      if (grouped[categoryName]!.isNotEmpty) {
        orderedGrouped[categoryName] = grouped[categoryName]!;
      }
    }
    
    // Then add other categories (sorted alphabetically)
    otherCategories.sort();
    for (final categoryName in otherCategories) {
      if (grouped[categoryName]!.isNotEmpty && categoryName != 'Uncategorized') {
        orderedGrouped[categoryName] = grouped[categoryName]!;
      }
    }
    
    // Add Uncategorized last if it has courses
    if (grouped.containsKey('Uncategorized') && grouped['Uncategorized']!.isNotEmpty) {
      orderedGrouped['Uncategorized'] = grouped['Uncategorized']!;
    }

    return orderedGrouped;
  }

  /// Check if a category name matches any user interest
  bool _categoryMatchesInterests(String categoryName) {
    if (_userInterests.isEmpty) return false;
    
    final categoryLower = categoryName.toLowerCase();
    for (final interest in _userInterests) {
      final interestLower = interest.toLowerCase();
      if (categoryLower.contains(interestLower) || interestLower.contains(categoryLower)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCoursesHeader(BuildContext context, int count) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Courses',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count courses',
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: isDesktop ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCoursesFound(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Container(
      padding: EdgeInsets.all(isDesktop ? 60 : 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: isDesktop ? 80 : 64,
            color: AppTheme.greyColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No courses found',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final upcomingSessions = _courseUpcomingSessions[course.id] ?? [];
    final hasUpcomingSessions = upcomingSessions.isNotEmpty;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: isDesktop ? 10 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: hasUpcomingSessions 
                ? Colors.orange.withOpacity(0.5)
                : Theme.of(context).dividerColor.withOpacity(0.1),
            width: hasUpcomingSessions ? 2 : 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? _kDesktopCardPadding : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.thumbnail != null &&
                                course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: course.thumbnail!,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: AppTheme.greyColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.greyColor,
                                    size: isDesktop ? 36.0 : 30.0,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppTheme.greyColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: AppTheme.greyColor,
                                  size: isDesktop ? 36.0 : 30.0,
                                ),
                              ),
                      ),
                    ),
                    if (isEnrolled)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasUpcomingSessions)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule,
                                        color: Colors.white, size: 10),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${upcomingSessions.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasUpcomingSessions && isEnrolled)
                              const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n?.enrolled ?? 'ENROLLED',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n?.discount ?? '20% OFF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 10 : 10),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      course.title ?? 'Untitled Course',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: isDesktop ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 3 : 2),

                    // Instructor
                    Text(
                      'by ${course.displayInstructor}',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: isDesktop ? 11 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 6 : 4),

                    // Duration and Students
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.greyColor,
                          size: isDesktop ? 14 : 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.formattedDuration,
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: isDesktop ? 11 : 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.people_outline,
                          color: AppTheme.greyColor,
                          size: isDesktop ? 14 : 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrollmentCount ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 6 : 4),

                    // Rating and Level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (course.averageRating ?? 0.0).toStringAsFixed(1),
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6,
                            vertical: isDesktop ? 2 : 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.level,
                            style: TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: isDesktop ? 10 : 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Price and Enroll Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if ((course.price ?? 0) > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 10 : 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.greyColor.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: isDesktop ? 15 : 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            l10n?.free ?? 'FREE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: isDesktop ? 15 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8,
                            vertical: isDesktop ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                Color(0xFF00cdac)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isEnrolled
                                ? (l10n?.open ?? 'Open')
                                : (l10n?.enroll ?? 'Enroll'),
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: isDesktop ? 11 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isEnrolled = enrolledCourses.any((c) => c.id == course.id);
    final upcomingSessions = _courseUpcomingSessions[course.id] ?? [];
    final hasUpcomingSessions = upcomingSessions.isNotEmpty;

    final cardWidth = isMobile ? 178.0 : 206.0;
    final price = course.price ?? 0;
    final isFree = price == 0;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111C2F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF263449) : const Color(0xFFF1E6D1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppTheme.primary)
                  .withOpacity(isDark ? 0.24 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: course.thumbnail != null &&
                            course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: NetworkImageWidget(
                              imageUrl: course.thumbnail!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              size: 40,
                            ),
                          ),
                  ),
                  if (isEnrolled)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasUpcomingSessions)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule,
                                      color: Colors.white, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${upcomingSessions.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          if (hasUpcomingSessions && isEnrolled)
                            const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Enrolled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isFree ? 'FREE' : 'RWF ${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (course.category != null)
                      Text(
                        course.category is String
                            ? course.category as String
                            : 'Category',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: AppTheme.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFF59E0B),
                          size: isMobile ? 14 : 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          (course.averageRating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseListItem(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final upcomingSessions = _courseUpcomingSessions[course.id] ?? [];
    final hasUpcomingSessions = upcomingSessions.isNotEmpty;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: course.thumbnail != null &&
                              course.thumbnail!.isNotEmpty
                          ? NetworkImageWidget(
                              imageUrl: course.thumbnail!,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                              placeholder: Container(
                                color: AppTheme.greyColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: AppTheme.greyColor,
                                  size: 35,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.greyColor,
                              size: 35,
                            ),
                    ),
                    if (isEnrolled)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasUpcomingSessions)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule,
                                        color: Colors.white, size: 8),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${upcomingSessions.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasUpcomingSessions && isEnrolled)
                              const SizedBox(width: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 10),
                            ),
                          ],
                        ),
                      )
                    else if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title ?? 'Untitled Course',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'by ${course.displayInstructor}',
                      style: const TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.greyColor,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          course.formattedDuration,
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.people_outline,
                          color: AppTheme.greyColor,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${course.enrollmentCount ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          (course.averageRating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.level,
                            style: const TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price and Enroll
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if ((course.price ?? 0) > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RWF ${course.price}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      l10n?.free ?? 'Free',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isEnrolled ? (l10n?.open ?? 'Open') : (l10n?.enroll ?? 'Enroll'),
                      style: const TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Category',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _showCategoryDropdown = false);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.getSecondaryTextColor(context),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Category List
          Container(
            constraints: BoxConstraints(
              maxHeight: screenWidth < 768 ? 200 : 300,
            ),
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No categories available',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    // All Categories Option
                    _buildCategoryOption(
                      context,
                      'all',
                      'All Categories',
                      'Browse all available courses',
                      Icons.grid_view_rounded,
                      const Color(0xFF10B981),
                    ),
                    // Category Options
                    ...categories
                        .where((category) => category != null)
                        .map((category) => _buildCategoryOption(
                              context,
                              category.id,
                              category.name,
                              'Courses in ${category.name}',
                              CategoryUtils.getCategoryIcon(category.id,
                                  name: category.name),
                              CategoryUtils.getCategoryColor(category.id,
                                  name: category.name),
                            )),
                  ],
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
              error: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    l10n?.failedToLoadCategories ?? 'Failed to load categories',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 14,
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

  Widget _buildCategoryOption(
    BuildContext context,
    String categoryId,
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == categoryId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = categoryId;
            _selectedCategoryName = categoryId == 'all' ? null : name;
            _showCategoryDropdown = false;
          });
          _filterCourses();
        },
        splashColor: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : isDark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : color.withOpacity(0.8),
                  size: isMobile ? 18 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? color
                            : AppTheme.getTextColor(context),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: isMobile ? 11 : 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: isMobile ? 20 : 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
