import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/presentation/widgets/downloaded_material_viewer.dart';
import 'package:excellencecoachinghub/services/book_service.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/utils/book_download.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  List<dynamic> _adminBooks = [];
  List<dynamic> _filteredAdminBooks = [];
  bool _isLoadingAdminBooks = true;
  bool _isLoadingGutenberg = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  final GutenbergService _gutenbergService = GutenbergService();
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'All';
  String _selectedSubject = 'All';
  bool _showFilters = false;
  bool _filterByEnrolledCourses = false;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    // Load admin books first for instant display, then Gutenberg in background
    Future.microtask(() => _loadAdminBooksFirst());
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Keeps every card's download badge in step with the service as books are
    // saved, paused or deleted.
    ref.watch(downloadServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: Icon(Icons.arrow_back_rounded, color: AppTheme.getTextColor(context)),
                      onPressed: () {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          final user = ref.read(authProvider).user;
                          router.go(user?.isSchoolStudent == true ? '/school/home?tab=2' : '/dashboard');
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'My Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    'Books and study materials',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterBooks,
                      decoration: InputDecoration(
                        hintText: 'Search books...',
                        hintStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                            color: _showFilters ? const Color(0xFF10B981) : AppTheme.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filters
            if (_showFilters) _buildFilters(context),
            // Content
            Expanded(
              child: _isLoadingAdminBooks && _adminBooks.isEmpty && _allBooks.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : _errorMessage != null && _adminBooks.isEmpty && _allBooks.isEmpty
                      ? _buildErrorWidget()
                      : _buildCoursesList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading courses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInitialBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLanguages = <String>[
      'All',
      ..._allBooks
          .where((book) => book.languages.isNotEmpty)
          .map((book) => book.languages.first)
          .where((lang) => lang.isNotEmpty)
          .toSet()
    ];
    
    // Use academic categories from the service with priority subjects first
    final academicCategories = <String>[
      'All Academic',
      'ICT',
      'Math',
      'Science',
      'Geography',
      ..._gutenbergService.getAcademicCategories()
    ];
    
    // Get unique subjects from both Gutenberg and admin books
    final allSubjects = <String>[
      'All',
      ..._allBooks
          .where((book) => book.subjects.isNotEmpty)
          .map((book) => book.subjects.first)
          .where((subj) => subj.isNotEmpty)
          .toSet(),
      ..._adminBooks
          .map((book) => book['subject'] as String? ?? '')
          .where((subj) => subj.isNotEmpty)
          .toSet()
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Language Filter
          Text(
            'Language',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allLanguages.length,
              itemBuilder: (context, index) {
                final language = allLanguages[index];
                final isSelected = _selectedLanguage == language;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(language),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLanguage = language;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Subject Filter
          Text(
            'Subject',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allSubjects.length,
              itemBuilder: (context, index) {
                final subject = allSubjects[index];
                final isSelected = _selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = subject;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Filter by Enrolled Courses Toggle
          Row(
            children: [
              Switch(
                value: _filterByEnrolledCourses,
                onChanged: (value) {
                  setState(() {
                    _filterByEnrolledCourses = value;
                    _applyFilters();
                  });
                },
                activeThumbColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Show books from my enrolled courses',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Academic Category Filter
          Text(
            'Academic Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: academicCategories.length,
              itemBuilder: (context, index) {
                final category = academicCategories[index];
                final isSelected = _selectedSubject == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.length > 15 ? '${category.substring(0, 15)}...' : category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = category;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Subject Filter
          Text(
            'General Subject',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allSubjects.length,
              itemBuilder: (context, index) {
                final subject = allSubjects[index];
                final isSelected = _selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(subject.length > 15 ? '${subject.substring(0, 15)}...' : subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = subject;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context) {
    // Show admin books FIRST, then Gutenberg books
    final allDisplayBooks = [..._filteredAdminBooks, ..._filteredBooks];
    
    if (allDisplayBooks.isEmpty && !_isLoadingAdminBooks && !_isLoadingGutenberg) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_rounded,
              color: AppTheme.getSecondaryTextColor(context),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _allBooks.isEmpty && _adminBooks.isEmpty ? 'No books available' : 'No books found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _allBooks.isEmpty && _adminBooks.isEmpty ? 'Check back later for new books' : 'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            if ((_allBooks.isNotEmpty || _adminBooks.isNotEmpty) && allDisplayBooks.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshBooks,
      color: const Color(0xFF10B981),
      child: GridView.builder(
        controller: _scrollController,
        padding: ResponsiveBreakpoints.getPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveBreakpoints.isDesktop(context) ? 4 : ResponsiveBreakpoints.isTablet(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ResponsiveBreakpoints.isDesktop(context) ? 0.65 : ResponsiveBreakpoints.isTablet(context) ? 0.6 : 0.55,
        ),
        itemCount: allDisplayBooks.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == allDisplayBooks.length && _hasMore) {
            return _buildLoadingIndicator();
          }
          final book = allDisplayBooks[index];
          // Check if it's a Gutenberg Book or admin book
          if (book is Book) {
            return _buildBookCard(context, book);
          } else {
            return _buildAdminBookCard(context, book);
          }
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _openBook(context, book);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: mediaProxyUrl(book.coverUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 48,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: const Color(0xFF10B981),
                              size: 48,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDownloadBadge(context, book),
                  ),
                ],
              ),
            ),
            // Book Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        book.title,
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.isMobile(context) ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        book.displayAuthor,
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                          color: AppTheme.getSecondaryTextColor(context),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: const Color(0xFF10B981),
                          size: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${book.downloadCount ?? 0}',
                            style: TextStyle(
                              fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (book.languages.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.language_rounded,
                            color: const Color(0xFF10B981),
                            size: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              book.languages[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                                color: AppTheme.getSecondaryTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _buildAdminBookCard(BuildContext context, dynamic book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _openAdminBook(context, book);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: book['coverUrl'] != null && book['coverUrl'].isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: mediaProxyUrl(book['coverUrl']),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 48,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: const Color(0xFF10B981),
                              size: 48,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDownloadBadge(context, book),
                  ),
                ],
              ),
            ),
            // Book Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        book['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.isMobile(context) ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        book['author'] ?? 'Unknown Author',
                        style: TextStyle(
                          fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                          color: AppTheme.getSecondaryTextColor(context),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: const Color(0xFF10B981),
                          size: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${book['downloadCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (book['language'] != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.language_rounded,
                            color: const Color(0xFF10B981),
                            size: ResponsiveBreakpoints.isMobile(context) ? 12 : 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              book['language'].toUpperCase(),
                              style: TextStyle(
                                fontSize: ResponsiveBreakpoints.isMobile(context) ? 11 : 12,
                                color: AppTheme.getSecondaryTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  /// Save-for-offline control drawn on a book cover.
  ///
  /// A saved book is stored through [DownloadService] as a material, so it
  /// shows up under Downloads › Materials and opens from local storage with no
  /// connection. Books with no downloadable file get no badge at all.
  Widget _buildDownloadBadge(BuildContext context, dynamic book) {
    final target = resolveBookDownload(book);
    if (target == null) return const SizedBox.shrink();

    final downloadService = ref.watch(downloadServiceProvider);
    final download = downloadService.getDownloadById(target.downloadId);
    final status = download?.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color color;
    String tooltip;

    if (status == DownloadStatus.completed) {
      icon = Icons.offline_pin_rounded;
      color = const Color(0xFF10B981);
      tooltip = 'Saved — tap to read offline';
    } else if (status == DownloadStatus.downloading || status == DownloadStatus.pending) {
      icon = Icons.pause_rounded;
      color = const Color(0xFF10B981);
      tooltip = 'Pause download';
    } else if (status == DownloadStatus.paused) {
      icon = Icons.play_arrow_rounded;
      color = const Color(0xFFF59E0B);
      tooltip = 'Resume download';
    } else if (status == DownloadStatus.failed) {
      icon = Icons.refresh_rounded;
      color = const Color(0xFFEF4444);
      tooltip = 'Download failed — tap to retry';
    } else {
      icon = Icons.download_rounded;
      color = const Color(0xFF10B981);
      tooltip = 'Download for offline reading';
    }

    final progress = download?.downloadProgress ?? 0.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: (isDark ? const Color(0xFF1F2937) : Colors.white).withOpacity(0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: () => _handleDownloadBadgeTap(target, status),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (status == DownloadStatus.downloading)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      // A negative progress means the server didn't send a
                      // content length, so spin instead of showing a fake bar.
                      value: progress < 0 ? null : progress,
                      strokeWidth: 2.5,
                      color: color,
                      backgroundColor: color.withOpacity(0.15),
                    ),
                  ),
                Icon(icon, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadBadgeTap(
    BookDownloadTarget target,
    DownloadStatus? status,
  ) async {
    final downloadService = ref.read(downloadServiceProvider);

    if (status == DownloadStatus.completed) {
      final download = downloadService.getDownloadById(target.downloadId);
      if (download != null) {
        await openDownloadedMaterial(context, download);
      }
      return;
    }

    if (status == DownloadStatus.downloading || status == DownloadStatus.pending) {
      downloadService.pauseDownload(target.downloadId);
      return;
    }

    try {
      if (status == DownloadStatus.paused || status == DownloadStatus.failed) {
        await downloadService.resumeDownload(target.downloadId, newUrl: target.url);
        return;
      }
      await _startBookDownload(target, downloadService);
    } catch (_) {
      // The service reports failures through onError / the download record.
    }
  }

  Future<void> _startBookDownload(
    BookDownloadTarget target,
    DownloadService downloadService,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${target.title}"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await downloadService.downloadNotesOrMaterial(
      url: target.url,
      title: target.title,
      lessonId: target.lessonId,
      type: DownloadType.material,
      lessonTitle: target.author,
      sectionTitle: 'Library',
      fileExtension: target.fileExtension,
      thumbnailUrl: target.coverUrl,
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${target.title}" saved for offline reading'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => context.push('/downloads?tab=materials'),
            ),
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      },
    );
  }

  void _filterBooks(String query) {
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        return book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.displayAuthor.toLowerCase().contains(query.toLowerCase()) ||
          book.languages.any((language) => language.toLowerCase().contains(query.toLowerCase())) ||
          book.subjects.any((subject) => subject.toLowerCase().contains(query.toLowerCase()));
      }).toList();
      
      // Filter admin books by subject and search
      _filteredAdminBooks = _adminBooks.where((book) {
        final subject = (book['subject'] ?? '').toLowerCase();
        final title = (book['title'] ?? '').toLowerCase();
        final author = (book['author'] ?? '').toLowerCase();
        
        // Subject filter
        if (_selectedSubject != 'All' && !subject.contains(_selectedSubject.toLowerCase())) {
          return false;
        }
        
        // Search filter
        if (query.isNotEmpty && !title.contains(query.toLowerCase()) && !author.contains(query.toLowerCase())) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  Future<void> _applyFilters() async {
    try {
      List<Book> booksToFilter = _allBooks;

      // If a priority subject is selected, fetch subject-specific books
      if (['ICT', 'Math', 'Science', 'Geography'].contains(_selectedSubject)) {
        final subjectBooks = await _gutenbergService.searchBySubject(_selectedSubject, limit: 100);
        booksToFilter = subjectBooks;
      }

      // Filter admin books
      List<dynamic> adminBooksToFilter = _adminBooks;
      
      // Apply subject filter to admin books
      if (_selectedSubject != 'All') {
        adminBooksToFilter = adminBooksToFilter
            .where((book) {
              final subject = (book['subject'] ?? '').toLowerCase();
              return subject.contains(_selectedSubject.toLowerCase());
            })
            .toList();
      }
      
      // Apply language filter to admin books
      if (_selectedLanguage != 'All') {
        adminBooksToFilter = adminBooksToFilter
            .where((book) {
              final language = (book['language'] ?? '').toLowerCase();
              return language == _selectedLanguage.toLowerCase();
            })
            .toList();
      }
      
      // Apply enrolled courses filter
      if (_filterByEnrolledCourses) {
        // Filter admin books that have relatedCourses
        adminBooksToFilter = adminBooksToFilter
            .where((book) {
              final relatedCourses = book['relatedCourses'] as List<dynamic>? ?? [];
              return relatedCourses.isNotEmpty;
            })
            .toList();
      }

      setState(() {
        _filteredBooks = booksToFilter.where((book) {
          final languageMatch = _selectedLanguage == 'All' || book.languages.contains(_selectedLanguage);
          
          // Handle academic category filtering
          bool subjectMatch = false;
          if (_selectedSubject == 'All') {
            subjectMatch = true;
          } else if (_selectedSubject == 'All Academic') {
            // Show all academic books
            subjectMatch = _isAcademicBook(book);
          } else if (['ICT', 'Math', 'Science', 'Geography'].contains(_selectedSubject)) {
            // Already filtered by searchBySubject
            subjectMatch = true;
          } else {
            // Filter by specific academic category or general subject
            subjectMatch = book.subjects.any((subject) => 
                subject.toLowerCase().contains(_selectedSubject.toLowerCase()));
          }
          
          return languageMatch && subjectMatch;
        }).toList();
        _filteredAdminBooks = adminBooksToFilter;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering books: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Helper method to check if a book is academic
  bool _isAcademicBook(Book book) {
    final titleLower = book.title.toLowerCase();
    final subjectsLower = book.subjects.map((s) => s.toLowerCase()).join(' ');
    
    // Check for academic keywords
    final academicKeywords = [
      'textbook', 'handbook', 'manual', 'guide', 'introduction', 
      'principles', 'theory', 'methods', 'studies', 'research',
      'academic', 'scholar', 'university', 'college', 'education',
      'learning', 'course', 'lecture', 'treatise', 'dissertation', 'thesis'
    ];
    
    final hasAcademicKeyword = academicKeywords.any((keyword) =>
        titleLower.contains(keyword) || subjectsLower.contains(keyword));
    
    // Check for academic subjects
    final academicSubjects = [
      'Science', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Medicine',
      'Engineering', 'Computer Science', 'Philosophy', 'History', 'Literature',
      'Psychology', 'Sociology', 'Economics', 'Political Science', 'Education',
      'Law', 'Business', 'Technology', 'Religion', 'Art', 'Music', 'Linguistics',
      'Anthropology', 'Geography', 'Archaeology', 'Astronomy', 'Geology',
      'Botany', 'Zoology'
    ];
    
    final hasAcademicSubject = book.subjects.any((subject) =>
        academicSubjects.any((academicSubject) =>
            subject.toLowerCase().contains(academicSubject.toLowerCase())));
    
    return hasAcademicKeyword || hasAcademicSubject;
  }

  void _openBook(BuildContext context, Book book) {
    // Navigate to the book reader screen using GoRouter
    context.push('/books/${book.id}', extra: book);
  }

  void _openAdminBook(BuildContext context, dynamic book) {
    // For admin books, we need to convert to a Book-like object or handle differently
    // For now, we'll open the PDF URL directly
    if (book['pdfUrl'] != null) {
      // Navigate to book reader with admin book data
      context.push('/books/${book['_id']}', extra: book);
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedLanguage = 'All';
      _selectedSubject = 'All';
      _filterByEnrolledCourses = false;
      _filteredBooks = _allBooks;
      _filteredAdminBooks = _adminBooks;
    });
  }

  Future<void> _loadAdminBooksFirst() async {
    // Show existing cached books immediately while we refresh in the background.
    setState(() {
      _errorMessage = null;
      _currentPage = 1;
      _isLoadingAdminBooks = true;
    });

    // Load admin books FIRST for instant display.
    List<dynamic> adminBooks = [];
    try {
      adminBooks = await _bookService.fetchBooks(page: 1, limit: 50);
    } catch (e) {
      print('Error fetching admin books: $e');
    }

    if (mounted) {
      setState(() {
        _adminBooks = adminBooks;
        _filteredAdminBooks = adminBooks;
        _isLoadingAdminBooks = false;
      });
    }

    // Load Gutenberg books in background after admin books are shown.
    _loadGutenbergBooks();
  }

  Future<void> _loadGutenbergBooks() async {
    setState(() {
      _isLoadingGutenberg = true;
    });

    try {
      final gutenbergBooks = await _gutenbergService.fetchAcademicBooks(page: 1, limit: _pageSize);

      if (mounted) {
        setState(() {
          _allBooks = gutenbergBooks;
          _filteredBooks = gutenbergBooks;
          _isLoadingGutenberg = false;
          _hasMore = gutenbergBooks.length == _pageSize;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingGutenberg = false;
        });
      }
    }
  }
  
  Future<void> _loadInitialBooks() async {
    await _loadAdminBooksFirst();
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final newBooks = await _gutenbergService.fetchAcademicBooks(page: _currentPage + 1, limit: _pageSize);
      if (mounted) {
        setState(() {
          _currentPage++;
          _allBooks.addAll(newBooks);
          _filteredBooks = _allBooks;
          _isLoadingMore = false;
          // Consider hasMore true if we got any books, not just full page
          _hasMore = newBooks.isNotEmpty;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 300.0; // Load more when 300px from the bottom
    
    if (maxScroll - currentScroll <= delta && !_isLoadingMore && _hasMore) {
      _loadMoreBooks();
    }
  }

  Future<void> _refreshBooks() async {
    await _loadAdminBooksFirst();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF10B981)),
            const SizedBox(height: 8),
            Text(
              'Loading more books...',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
