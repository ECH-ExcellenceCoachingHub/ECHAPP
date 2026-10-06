import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  final bool _hasLoadedInitialData = false;
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Load courses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCourseProvider.notifier).loadCourses();
    });
  }

  void _handleGlobalRefresh() {
    // Refresh all key providers
    // NOTE: We DO NOT invalidate authProvider here because it causes the user to be logged out.
    ref.invalidate(coursesProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(backendCategoriesProvider);
    ref.invalidate(notificationCountProvider);
    ref.invalidate(adminCourseProvider);
    ref.invalidate(adminDashboardProvider);
    
    // Explicitly reload courses after invalidation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminCourseProvider.notifier).loadCourses();
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

  @override
  Widget build(BuildContext context) {
    // Watch the admin course provider
    final courseState = ref.watch(adminCourseProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: (context.canPop() || GoRouterState.of(context).uri.path != '/admin') 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin');
                }
              },
              tooltip: 'Back',
            ) 
          : null,
        title: const Text('Course Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: () => _showCategoryManagementModal(context),
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/courses/create'),
            tooltip: 'Add Course',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminCourseProvider.notifier).loadCourses(),
            tooltip: 'Refresh Courses',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_all') {
                _confirmDeleteAllCourses(ref, courseState.courses);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete All Courses'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCoursesContent(context, ref, courseState),
    );
  }

  void _showCategoryManagementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryManagementModal(),
    );
  }

  Widget _buildCoursesContent(BuildContext context, WidgetRef ref, AdminCourseState courseState) {
    if (courseState.isLoading && courseState.courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading courses...'),
          ],
        ),
      );
    }

    if (courseState.error != null && courseState.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error loading courses: ${courseState.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(adminCourseProvider.notifier).loadCourses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          _buildSearchAndFilter(context),
          
          const SizedBox(height: 20),
          
          // Courses List
          _buildCoursesList(context, ref, courseState.courses),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  ref.read(adminCourseProvider.notifier).searchCourses(query);
                } else {
                  ref.read(adminCourseProvider.notifier).loadCourses();
                }
              },
              onChanged: (query) {
                // Optional: Implement debounced search
                if (query.isEmpty) {
                  ref.read(adminCourseProvider.notifier).loadCourses();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value == 'all' ? 'All' : 
                               value == 'published' ? 'Published' : 'Draft';
              });
              ref.read(adminCourseProvider.notifier).filterCoursesByStatus(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Courses'),
              ),
              const PopupMenuItem(
                value: 'published',
                child: Text('Published'),
              ),
              const PopupMenuItem(
                value: 'draft',
                child: Text('Draft'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList(BuildContext context, WidgetRef ref, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Courses (${courses.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            if (courses.isNotEmpty)
              TextButton(
                onPressed: () {
                  _confirmDeleteAllCourses(ref, courses);
                },
                child: const Text(
                  'Delete All',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(Icons.school_outlined, size: 60, color: AppTheme.greyColor),
                SizedBox(height: 15),
                Text(
                  'No courses found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Create your first course to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(context, ref, course);
            },
          ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, WidgetRef ref, Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 768;
            final isMediumScreen = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Thumbnail
                    Container(
                      width: isSmallScreen ? 60 : 80,
                      height: isSmallScreen ? 60 : 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: NetworkImageWidget(
                                imageUrl: course.thumbnail!,
                                fit: BoxFit.cover,
                                width: isSmallScreen ? 60 : 80,
                                height: isSmallScreen ? 60 : 80,
                                errorWidget: Container(
                                  width: isSmallScreen ? 60 : 80,
                                  height: isSmallScreen ? 60 : 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    color: AppTheme.primaryGreen,
                                    size: isSmallScreen ? 30 : 40,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: isSmallScreen ? 60 : 80,
                              height: isSmallScreen ? 60 : 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.school,
                                color: AppTheme.primaryGreen,
                                size: isSmallScreen ? 30 : 40,
                              ),
                            ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  course.title ?? 'Untitled Course',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.blackColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: course.isPublished 
                                    ? AppTheme.primaryGreen.withOpacity(0.1)
                                    : AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  course.isPublished ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    color: course.isPublished 
                                      ? AppTheme.primaryGreen
                                      : AppTheme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            course.description,
                            style: const TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: 14,
                            ),
                            maxLines: isSmallScreen ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                Icons.access_time,
                                course.formattedDuration,
                                AppTheme.primaryGreen,
                                isSmall: isSmallScreen,
                              ),
                              _buildInfoChip(
                                Icons.speed,
                                course.level.capitalize(),
                                AppTheme.accent,
                                isSmall: isSmallScreen,
                              ),
                              if (course.category != null || course.categoryId != null)
                                _buildInfoChip(
                                  Icons.category,
                                  _getCategoryName(ref, course),
                                  AppTheme.primaryGreen,
                                  isSmall: isSmallScreen,
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RWF ${course.price.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                )}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Row(
                                children: [
                                  // Publish Toggle Button
                                  Switch(
                                    value: course.isPublished,
                                    onChanged: (value) {
                                      ref.read(adminCourseProvider.notifier)
                                          .toggleCoursePublish(course.id, course.isPublished);
                                    },
                                    activeThumbColor: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSmallScreen)
                                    _buildCompactActionButtons(context, ref, course)
                                  else
                                    _buildFullActionButtons(context, ref, course),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  void _confirmDeleteCourse(WidgetRef ref, Course course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete "${course.title ?? 'Untitled Course'}"? This will permanently remove all associated content including videos, materials, and exams. This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(adminCourseProvider.notifier).deleteCourse(course.id);
                  
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Course "${course.title ?? 'Untitled Course'}" deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  
  void _confirmDeleteAllCourses(WidgetRef ref, List<Course> courses) {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No courses to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
  
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Courses'),
          content: Text(
            'Are you sure you want to delete ALL ${courses.length} courses? This will permanently remove all courses and their associated content. This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                  
                // Delete all courses one by one
                for (var course in courses) {
                  ref.read(adminCourseProvider.notifier).deleteCourse(course.id);
                }
                  
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All ${courses.length} courses deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('DELETE ALL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryName(WidgetRef ref, Course course) {
    // If name is already in the category map, use it
    if (course.category != null && course.category!['name'] != null) {
      return course.category!['name'].toString();
    }
    
    // Otherwise, try to find it in the backend categories list using the ID
    final catId = course.categoryId ?? (course.category != null ? (course.category!['id'] ?? course.category!['_id'])?.toString() : null);
    
    if (catId == null) return 'Uncategorized';
    
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        for (var c in categories) {
          if (c.id == catId || c.id.toString() == catId) {
            return c.name;
          }
        }
        return 'Uncategorized';
      },
      loading: () => '...',
      error: (_, __) => 'Uncategorized',
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8, vertical: isSmall ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: color),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullActionButtons(BuildContext context, WidgetRef ref, Course course) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Edit Course',
          onPressed: () {
            context.push('/admin/courses/${course.id}/edit');
          },
        ),
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'View Content',
          onPressed: () {
            context.push('/admin/courses/${course.id}/content');
          },
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome, size: 20, color: AppTheme.accent),
          tooltip: 'Build content from a book with AI',
          onPressed: () {
            context.push('/admin/courses/${course.id}/ai-builder');
          },
        ),
        IconButton(
          icon: const Icon(Icons.analytics, size: 20, color: AppTheme.primaryGreen),
          tooltip: 'Course Analytics',
          onPressed: () {
            context.push('/admin/courses/${course.id}/analytics');
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Delete Course',
          onPressed: () {
            _confirmDeleteCourse(ref, course);
          },
        ),
      ],
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, WidgetRef ref, Course course) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Course Actions',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.push('/admin/courses/${course.id}/edit');
            break;
          case 'content':
            context.push('/admin/courses/${course.id}/content');
            break;
          case 'ai':
            context.push('/admin/courses/${course.id}/ai-builder');
            break;
          case 'analytics':
            context.push('/admin/courses/${course.id}/analytics');
            break;
          case 'delete':
            _confirmDeleteCourse(ref, course);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 10),
              Text('Edit Course'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'content',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 10),
              Text('View Content'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'ai',
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppTheme.accent),
              SizedBox(width: 10),
              Text('Build with AI'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'analytics',
          child: Row(
            children: [
              Icon(Icons.analytics, size: 20, color: AppTheme.primaryGreen),
              SizedBox(width: 10),
              Text('Course Analytics'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Course', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryManagementModal extends ConsumerStatefulWidget {
  const CategoryManagementModal({super.key});

  @override
  ConsumerState<CategoryManagementModal> createState() => _CategoryManagementModalState();
}

class _CategoryManagementModalState extends ConsumerState<CategoryManagementModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.createCategory(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: 'school', // Default icon
        subcategories: [], // Empty subcategories array
        level: 1, // Default level
      );
      
      if (mounted) {
        _nameController.clear();
        _descriptionController.clear();
        ref.invalidate(backendCategoriesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure? This will affect courses in this category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(id);
      ref.invalidate(backendCategoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Categories',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // Create New Category Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Mathematics, Science...',
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add Category'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            const Text(
              'Existing Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: categoriesAsync.when(
                data: (categories) => categories.isEmpty
                  ? const Center(child: Text('No categories found'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(category.name),
                          subtitle: Text(category.description ?? 'No description'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteCategory(category.id),
                          ),
                        );
                      },
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
