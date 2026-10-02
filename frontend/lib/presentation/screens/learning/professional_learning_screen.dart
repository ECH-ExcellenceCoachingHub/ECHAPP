import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/models/payment.dart';
import 'package:excellencecoachinghub/models/payment_status.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/book_download.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/services/book_service.dart';
import 'package:excellencecoachinghub/presentation/screens/library/book_reader_screen.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/services/api/video_api_service.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/live_session_countdown.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';
import 'package:excellencecoachinghub/services/achievement_sound_service.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/course_exam_history_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/community/course_community_screen.dart';

/// Everything the Lessons tab needs to launch a quiz: the quiz document,
/// the student's previous attempts (newest first) and how many questions it has.
typedef _QuizLaunch = ({
  Map<String, dynamic> quiz,
  List<Map<String, dynamic>> attempts,
  int questionCount,
});

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
class _DT {
  // Brand
  static const primary    = Color(0xFF00C853);
  static const primaryDim = Color(0xFF00A846);
  static const accent     = Color(0xFF7C4DFF);
  static const accentDim  = Color(0xFF6E35F5);

  // Gradients
  static const List<Color> heroGrad   = [Color(0xFF00C853), Color(0xFF00897B)];
  static const List<Color> darkGrad   = [Color(0xFF1A1F2E), Color(0xFF111522)];
  static const List<Color> purpleGrad = [Color(0xFF7C4DFF), Color(0xFF5C35E0)];

  // Surfaces
  static const bg        = Color(0xFFF7F8FC);
  static const bgDark    = Color(0xFF111522);
  static const card      = Colors.white;
  static const cardDark  = Color(0xFF1C2333);
  static const surface   = Color(0xFFF0F2F8);
  static const surfaceDk = Color(0xFF242C42);

  // Text
  static const textPrimary   = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFFADB5BD);
  static const textLight     = Colors.white;

  // Borders
  static const border     = Color(0xFFE5E9F2);
  static const borderDark = Color(0xFF2D3748);

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: const Color(0xFF00C853).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get floatShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 12)),
  ];

  // Radius
  static const r4  = BorderRadius.all(Radius.circular(4));
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r32 = BorderRadius.all(Radius.circular(32));
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class ProfessionalLearningScreen extends ConsumerStatefulWidget {
  final String courseId;
  const ProfessionalLearningScreen({super.key, required this.courseId});

  @override
  ConsumerState<ProfessionalLearningScreen> createState() =>
      _ProfessionalLearningScreenState();
}

class _ProfessionalLearningScreenState
    extends ConsumerState<ProfessionalLearningScreen>
    with TickerProviderStateMixin<ProfessionalLearningScreen> {

  Course? _course;
  List<Section>? _chapters;
  final Map<String, List<Lesson>> _chapterLessons = {};
  final Map<String, bool> _chapterCompletionStatus = {};
  final Map<String, bool> _chapterUnlockedStatus = {};
  final Map<String, bool> _lessonCompletionStatus = {};
  int _currentSectionIndex = 0;
  // Chapter shown in the desktop detail pane; null follows _currentSectionIndex.
  String? _selectedChapterId;
  // Mobile chapter cards, so "next chapter" can scroll one into view.
  final Map<String, GlobalKey> _chapterCardKeys = {};
  bool _isChatExpanded = false;
  bool _isLoading = false;
  final bool _isLoadingChapterDetails = false;
  final GlobalKey<StudentGuideWidgetState> _guideKey = GlobalKey<StudentGuideWidgetState>();
  List<Certificate>? _courseCertificates;
  Map<String, dynamic>? _courseAccessData;

  final TextEditingController _searchController = TextEditingController();
  List<Section>? _filteredChapters;
  bool _isSearchActive = false;
  final RealAIChatService _aiChatService = RealAIChatService();
  final String _conversationId =
      'conversation_${DateTime.now().millisecondsSinceEpoch}';

  int _totalLessons = 0;
  int _completedLessonsCount = 0;
  int _totalDurationMinutes = 0;
  int _completedDurationMinutes = 0;
  int _xpPoints = 0;
  int _completedChaptersCount = 0;
  final Set<String> _celebratedChapters = {};
  String? _markingCompleteChapterId;

  // Library tab state
  List<dynamic> _courseBooks = [];
  bool _isLoadingBooks = false;
  String? _booksError;
  final BookService _bookService = BookService();

  // Saved/Bookmarks tab state
  List<Lesson> _bookmarkedLessons = [];
  bool _bookmarksLoaded = false;

  // Course-wide download state
  bool _isCourseDownloading = false;
  int _courseDownloadTotal = 0;
  int _courseDownloadDone = 0;
  int _courseDownloadFailed = 0;

  late TabController _tabController;
  late AnimationController _heroAnimCtrl;
  late AnimationController _fabAnimCtrl;
  late AnimationController _fabPulseCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _fabScale;
  Animation<double>? _fabPulse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _liveSessionsTabController = TabController(length: 4, vsync: this);
    _liveSessionsTabController.addListener(() {
      if (mounted) setState(() {});
    });

    _heroAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fabAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fabPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _heroFade  = CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut));
    _fabScale  = CurvedAnimation(parent: _fabAnimCtrl,  curve: Curves.elasticOut);
    _fabPulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut));

    _searchController.addListener(_onSearchChanged);
    _checkPermissions();
    _loadCourseData();
    _loadCourseBooks();
    _tabController.addListener(() => setState(() {}));

    // Check for live sessions early to determine default tab
    _checkAndSwitchToLiveSessions();
  }

  void _checkPermissions() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // For students, we'll filter content based on enrollment permissions
    // No need to block the entire screen - just show content from courses they have access to
  }
  
  /// Load live sessions and switch to the Live tab only if one is live now or upcoming
  Future<void> _checkAndSwitchToLiveSessions() async {
    await _loadLiveSessions();
    if (!mounted) return;
    if (_liveNowSessions.isNotEmpty || _upcomingSessions.isNotEmpty) {
      _tabController.animateTo(1);
    }
    // Default the Live Sessions sub-tab: Live Now if something is live right
    // now, otherwise Upcoming (rather than sitting on an empty Live Now tab).
    if (_liveNowSessions.isNotEmpty) {
      _liveSessionsTabController.animateTo(0);
    } else if (_upcomingSessions.isNotEmpty) {
      _liveSessionsTabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveSessionsTabController.dispose();
    _heroAnimCtrl.dispose();
    _fabAnimCtrl.dispose();
    _fabPulseCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────
  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);
    try {
      _course = await ref.read(courseProvider(widget.courseId).future);
      _courseAccessData = await ref
          .read(enrollmentRepositoryProvider)
          .checkCourseAccess(widget.courseId);

      final sectionService = SectionService();
      final courseContent = await sectionService.getCourseContent(widget.courseId);

      try {
        _courseCertificates =
            await CertificateRepository().getCertificatesByCourse(widget.courseId);
      } catch (_) {
        _courseCertificates = [];
      }

      final courseSections =
          courseContent['sections'] ?? courseContent['chapters'];
      debugPrint('Course sections: $courseSections');
      debugPrint('Course sections type: ${courseSections.runtimeType}');
      debugPrint('Course sections is null: ${courseSections == null}');
      debugPrint('Course sections is List: ${courseSections is List}');
      if (courseSections is List) {
        debugPrint('Course sections length: ${(courseSections).length}');
      }

      if (courseSections != null && courseSections is List && courseSections.isNotEmpty) {
        final sectionsData = courseSections;
        _chapters =
            sectionsData.map((s) => Section.fromJson(s as Map<String, dynamic>)).toList();
        _chapters?.sort((a, b) => a.order.compareTo(b.order));

        _totalLessons = 0;
        _totalDurationMinutes = 0;
        _chapterLessons.clear();

        for (final chapterData in sectionsData) {
          final cData = chapterData as Map<String, dynamic>;
          final chapterId = (cData['_id'] ?? cData['id']).toString();
          final lessonsData = cData['lessons'] as List?;
          if (lessonsData != null) {
            // Only keep lessons that have real content (video / notes / quiz / materials)
            final lessons = lessonsData
                .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                .where((l) => l.hasVideo || l.hasNotes || l.hasQuiz || l.hasMaterials)
                .toList();
            _chapterLessons[chapterId] = lessons;
            _totalLessons += lessons.length;
            for (var l in lessons) {
              _totalDurationMinutes += l.duration;
            }
          }
        }

        // Remove chapters that have no content lessons at all
        // (e.g. sections created only to host live sessions)
        _chapters?.removeWhere((chapter) {
          final lessons = _chapterLessons[chapter.id] ?? [];
          return lessons.isEmpty;
        });
      } else {
        // Set chapters to empty list if sections data is missing or empty
        // This will show the empty state instead of continuous loading
        debugPrint('Setting chapters to empty list - no data available');
        _chapters = [];
      }

      _initializeCompletionStatus();
      // Baseline, so only achievements earned from now on make a sound.
      _knownUnlockedAchievements = _unlockedAchievementTitles();
      _filteredChapters = _chapters;
      
      // Load user payments for this course
      try {
        await ref.read(paymentProvider.notifier).loadUserPayments();
      } catch (e) {
        debugPrint('Error loading user payments: $e');
      }
      
      _heroAnimCtrl.forward();
      _fabAnimCtrl.forward();
    } catch (e) {
      debugPrint('Error loading course data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCourseBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      _courseBooks = await _bookService.fetchBooksByCourse(widget.courseId);
      setState(() => _booksError = null);
    } catch (e) {
      debugPrint('Error loading course books: $e');
      setState(() => _booksError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingBooks = false);
    }
  }

  // ── Mark chapter complete ─────────────────────
  Future<void> _markChapterComplete(Section chapter, int chapterIndex) async {
    if (_celebratedChapters.contains(chapter.id) ||
        _markingCompleteChapterId != null) return;
    final lessons = _chapterLessons[chapter.id] ?? [];
    final completedLessons = lessons.where((l) => _lessonCompletionStatus[l.id] == true).length;

    // Require at least one lesson to be completed
    if (completedLessons == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least one lesson before marking this chapter as complete.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isLastChapter(chapter)
            ? 'Complete Your Course'
            : 'Continue to Next Chapter'),
        content: Text(
          _isLastChapter(chapter)
              ? 'You have completed $completedLessons of ${lessons.length} lessons in this final chapter. Mark your course as complete?'
              : 'You have completed $completedLessons of ${lessons.length} lessons. Finish this chapter and continue to the next one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DT.primary,
            ),
            child: Text(_isLastChapter(chapter) ? 'Complete Course' : 'Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get enrollmentId from course access data
    final enrollmentId = _courseAccessData?['enrollmentId']?.toString();
    if (enrollmentId == null) {
      debugPrint('Error: No enrollmentId found in course access data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark chapter complete: Enrollment not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state
    setState(() => _markingCompleteChapterId = chapter.id);

    // Call backend API to mark section as complete
    try {
      final enrollmentNotifier = ref.read(enrollmentNotifierProvider.notifier);
      await enrollmentNotifier.completeSection(enrollmentId, chapter.id, _course?.id ?? '');
      debugPrint('Successfully marked chapter ${chapter.id} as complete');
    } catch (e) {
      debugPrint('Error marking chapter complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark chapter complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _markingCompleteChapterId = null);
      return;
    }

    _celebratedChapters.add(chapter.id);
    setState(() {
      // Mark all lessons in this chapter as complete
      final chapterLessons = _chapterLessons[chapter.id] ?? [];
      for (var lesson in chapterLessons) {
        _lessonCompletionStatus[lesson.id] = true;
      }
      _completedLessonsCount = _lessonCompletionStatus.values.where((v) => v).length;

      // Mark chapter as complete
      _chapterCompletionStatus[chapter.id] = true;
      _completedChaptersCount = _chapterCompletionStatus.values.where((v) => v).length;

      // Unlock next chapter
      if (_chapters != null && chapterIndex + 1 < _chapters!.length) {
        final nextChapter = _chapters![chapterIndex + 1];
        _chapterUnlockedStatus[nextChapter.id] = true;
        _currentSectionIndex = chapterIndex + 1;
      }

      // XP reward: 100 chapter bonus
      _xpPoints += 100;
      
      // Clear loading state
      _markingCompleteChapterId = null;
    });

    // Send congratulatory push notification
    try {
      await PushNotificationService.sendCongratulatoryNotification(
        'Chapter Complete! 🎉',
        'Congratulations! You completed "Chapter ${chapterIndex + 1}: ${chapter.title}"',
      );
      debugPrint('Chapter completion notification sent');
    } catch (e) {
      debugPrint('Error sending chapter completion notification: $e');
    }

    _showChapterCompletionCelebration(chapter, chapterIndex, lessons.length);
    // After the chapter/course jingle (longest is ~1.4 s).
    _checkNewAchievements(delay: const Duration(milliseconds: 1800));
  }

  void _showChapterCompletionCelebration(Section chapter, int chapterIndex, int lessonCount) {
    final xpEarned = 100 + (lessonCount * 10);
    final totalChapters = _chapters?.length ?? 1;
    final isLastChapter = chapterIndex + 1 >= totalChapters;
    final nextChapterName = (!isLastChapter && _chapters != null)
        ? 'Chapter ${chapterIndex + 2}: ${_chapters![chapterIndex + 1].title}'
        : null;

    AchievementSoundService.instance.play(isLastChapter
        ? AchievementSound.courseComplete
        : AchievementSound.chapterComplete);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => _ChapterCompletionDialog(
        chapterName: 'Chapter ${chapterIndex + 1}: ${chapter.title}',
        chapterNumber: chapterIndex + 1,
        xpEarned: xpEarned,
        totalXp: _xpPoints,
        lessonCount: lessonCount,
        isLastChapter: isLastChapter,
        nextChapterName: nextChapterName,
        overallProgress: _progress,
        isDark: _isDark,
        onClose: () => Navigator.of(ctx).pop(),
        onContinue: () {
          Navigator.of(ctx).pop();
          // "Continue Learning →" goes straight to the newly unlocked chapter.
          if (!isLastChapter && _chapters != null) {
            _goToChapter(_chapters![chapterIndex + 1]);
          }
        },
      ),
    );
  }

  void _initializeCompletionStatus() {
    if (_chapters == null) return;
    
    // Initialize all chapters as not completed
    for (int i = 0; i < _chapters!.length; i++) {
      _chapterCompletionStatus[_chapters![i].id] = false;
      _chapterUnlockedStatus[_chapters![i].id] = false;
    }
    
    // First chapter is always unlocked
    if (_chapters!.isNotEmpty) {
      _chapterUnlockedStatus[_chapters![0].id] = true;
    }
    
    if (_courseAccessData?['completedLessons'] != null) {
      final completedList = _courseAccessData!['completedLessons'] as List;
      _completedLessonsCount = completedList.length;
      for (var id in completedList) {
        _lessonCompletionStatus[id.toString()] = true;
      }
    }
    
    if (_courseAccessData?['completedSections'] != null) {
      final completedSectionsList =
          _courseAccessData!['completedSections'] as List;
      final completedSet =
          completedSectionsList.map((e) => e.toString()).toSet();
      
      // Mark completed chapters
      for (var id in completedSectionsList) {
        _chapterCompletionStatus[id.toString()] = true;
      }
      
      // Unlock chapters based on completion
      if (_chapters != null) {
        for (int i = 0; i < _chapters!.length; i++) {
          // First chapter is always unlocked
          if (i == 0) {
            _chapterUnlockedStatus[_chapters![i].id] = true;
          }
          // Unlock next chapter if current is completed
          if (completedSet.contains(_chapters![i].id) &&
              i + 1 < _chapters!.length) {
            _chapterUnlockedStatus[_chapters![i + 1].id] = true;
          }
        }
        
        // Find current section index (first incomplete chapter)
        _currentSectionIndex = _chapters!.length - 1;
        for (int i = 0; i < _chapters!.length; i++) {
          if (!completedSet.contains(_chapters![i].id)) {
            _currentSectionIndex = i;
            break;
          }
        }
      }
    }
    
    _completedChaptersCount = _chapterCompletionStatus.values.where((v) => v).length;
    _xpPoints = (_completedLessonsCount * 10) + (_completedChaptersCount * 100);
    // Pre-mark already-completed chapters so no stale celebration fires
    for (final entry in _chapterCompletionStatus.entries) {
      if (entry.value) _celebratedChapters.add(entry.key);
    }
  }

  // ── Search ────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredChapters = q.isEmpty
          ? _chapters
          : _chapters?.where((s) =>
              s.title.toLowerCase().contains(q) ||
              (s.description?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  // ── Helpers ───────────────────────────────────
  // Counted from the course's own lessons: the server's completed list can
  // hold hidden (content-less) lessons or duplicates, which pushed this >100%.
  double get _progress {
    if (_totalLessons == 0) return 0.0;
    var done = 0;
    for (final lessons in _chapterLessons.values) {
      done += lessons.where((l) => _lessonCompletionStatus[l.id] == true).length;
    }
    return (done / _totalLessons).clamp(0.0, 1.0);
  }

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _cardBg => _isDark ? _DT.cardDark : _DT.card;

  Color get _surfaceBg => _isDark ? _DT.surfaceDk : _DT.surface;

  Color get _borderColor => _isDark ? _DT.borderDark : _DT.border;

  Color get _textPrimary =>
      _isDark ? Colors.white : _DT.textPrimary;

  Color get _textSecondary => _DT.textSecondary;

  /// Get the user's payment for the current course (if any)
  Payment? _getUserPaymentForCurrentCourse() {
    final userPayments = ref.read(paymentProvider).userPayments;
    try {
      return userPayments.firstWhere(
        (payment) => payment.courseId == widget.courseId,
      );
    } catch (e) {
      return null; // No payment found for this course
    }
  }

  /// Check if user has a completed payment for this course
  bool get _hasPaidForCourse {
    final payment = _getUserPaymentForCurrentCourse();
    return payment != null && 
           (payment.status == PaymentStatus.completed || 
            payment.status == PaymentStatus.approved);
  }

  /// Download invoice for the current course
  Future<void> _downloadInvoice() async {
    final payment = _getUserPaymentForCurrentCourse();
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment found for this course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(paymentProvider.notifier).downloadInvoice(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice saved to Downloads folder'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _course == null) return _buildSplash();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
        body: Stack(
          children: [
            _buildBody(),
            if (_isChatExpanded) _buildAIChatOverlay(),
          ],
        ),
        floatingActionButton: _isChatExpanded ? null : _buildAIChatFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SPLASH / LOADING
  // ─────────────────────────────────────────────
  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _DT.heroGrad),
                borderRadius: _DT.r20,
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: _DT.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text('Loading your course...',
                style: TextStyle(
                  color: _DT.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTENT LOADING STATE (for lazy loading)
  // ─────────────────────────────────────────────
  Widget _buildContentLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _DT.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait, loading content...',
            style: TextStyle(
              color: _DT.textSecondary,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BODY (CustomScrollView with SliverAppBar)
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(innerBoxIsScrolled),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChaptersTab(),
          _buildLiveSessionsTab(),
          _buildProgressTab(),
          _buildCommunityTab(),
          _buildMaterialsTab(),
          _buildLibraryTab(),
        ],
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────
  Widget _buildSliverAppBar(bool innerScrolled) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 280 : 310,
      pinned: true,
      backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _buildBackButton(),
      actions: _buildActions(),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => context.go('/dashboard'),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: _DT.r12,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textPrimary),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    final actions = [
      // Search toggle
      _ActionChip(
        icon: _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
        active: _isSearchActive,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: () => setState(() {
          _isSearchActive = !_isSearchActive;
          if (!_isSearchActive) {
            _searchController.clear();
            _filteredChapters = _chapters;
          }
        }),
      ),
      // Invoice download (only if user has paid)
      if (_hasPaidForCourse)
        _ActionChip(
          icon: Icons.download_rounded,
          isDark: _isDark,
          cardBg: _cardBg,
          onTap: _downloadInvoice,
        ),
      // Download whole course
      _ActionChip(
        icon: _isCourseDownloading
            ? Icons.downloading_rounded
            : Icons.download_for_offline_rounded,
        active: _isCourseDownloading,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _isCourseDownloading ? null : _downloadWholeCourse,
      ),
      // Saved lessons (moved out of the tab row to make space for Community)
      _ActionChip(
        icon: Icons.bookmark_rounded,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _openSavedLessons,
      ),
      // Exam history
      _ActionChip(
        icon: Icons.history_edu_rounded,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _openExamHistory,
      ),
      // Refresh
      _ActionChip(
        icon: Icons.refresh_rounded,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _refreshData,
      ),
      const SizedBox(width: 8),
    ];
    return actions;
  }

  Widget _buildHeroHeader() {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final completedChapters =
        _chapterCompletionStatus.values.where((v) => v).length;

    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: thumbnail or fallback gradient ──
            if (_course?.thumbnail != null && _course!.thumbnail!.isNotEmpty)
              Image.network(
                mediaProxyUrl(_course!.thumbnail),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00897B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // ── Dark gradient overlay so text is always readable ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.70),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // ── Content ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24, 72, isMobile ? 16 : 24, 20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Course badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: _DT.r32,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _course?.level.toUpperCase() ?? 'BEGINNER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    _course?.title ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Upcoming sessions warning
                  if (_upcomingSessions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_upcomingSessions.length} upcoming session${_upcomingSessions.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _HeroStat(
                                  icon: Icons.library_books_rounded,
                                  value: '$completedChapters/${_chapters?.length ?? 0}',
                                  label: 'Chapters'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.play_circle_rounded,
                                  value: '$_completedLessonsCount/$_totalLessons',
                                  label: 'Lessons'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.trending_up_rounded,
                                  value: '${(_progress.isFinite ? (_progress * 100).clamp(0, 100) : 0).toInt()}%',
                                  label: 'Done'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.bolt_rounded,
                                  value: '$_xpPoints',
                                  label: 'XP'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini circular progress
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              strokeWidth: 3.5,
                            ),
                            Text(
                              '${(_progress.isFinite ? (_progress * 100).clamp(0, 100) : 0).toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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

  Widget _buildTabBar() {
    return Container(
      color: _isDark ? _DT.bgDark : Colors.white,
      child: Column(
        children: [
          // Search bar (expanded when active)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isSearchActive
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: _DT.r12,
                        border: Border.all(
                            color: _DT.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search_rounded,
                              size: 18, color: _DT.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: 14, color: _textPrimary),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search chapters or lessons…',
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: _textSecondary),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () =>
                                  setState(() => _searchController.clear()),
                              icon: Icon(Icons.close_rounded,
                                  size: 18, color: _textSecondary),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _DT.primary,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _DT.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 11),
            dividerColor: _borderColor,
            dividerHeight: 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Chapters'),
              Tab(icon: Icon(Icons.live_tv_rounded, size: 18), text: 'Live'),
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Progress'),
              Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Community'),
              Tab(icon: Icon(Icons.play_lesson_rounded, size: 18), text: 'Lessons'),
              Tab(icon: Icon(Icons.local_library_rounded, size: 18), text: 'Library'),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAPTERS TAB
  // ─────────────────────────────────────────────
  Widget _buildChaptersTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    final chapters = _filteredChapters ?? _chapters;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final screenW = MediaQuery.of(context).size.width;

    // Show loading state if:
    // 1. Still loading initial data
    // 2. Chapters is null (lazy loading - data not ready yet)
    if (_isLoading || _chapters == null) {
      return _buildContentLoadingState();
    }

    // At this point, chapters is not null (it's either a list or empty list)
    if (chapters!.isEmpty) {
      return _buildEmptyState(
          icon: Icons.library_books_rounded,
          title: _isSearchActive
              ? 'No chapters match your search'
              : 'No recorded material yet',
          subtitle: _isSearchActive
              ? 'Try a different keyword'
              : 'Check back soon for content');
    }

    return isDesktop && screenW > 1100
        ? _buildChaptersDesktop(chapters)
        : _buildChaptersList(chapters);
  }

  // Checked against the full list so search filtering doesn't change it.
  bool _isLastChapter(Section s) =>
      _chapters != null && _chapters!.isNotEmpty && _chapters!.last.id == s.id;

  Section? _nextChapterOf(Section s) {
    final i = _chapters?.indexWhere((c) => c.id == s.id) ?? -1;
    if (i < 0 || i + 1 >= _chapters!.length) return null;
    return _chapters![i + 1];
  }

  VoidCallback? _goToNextChapter(Section s) {
    final next = _nextChapterOf(s);
    return next == null ? null : () => _goToChapter(next);
  }

  /// Takes the learner straight to [chapter]: on desktop it opens in the
  /// detail pane, on mobile the list scrolls to its card.
  void _goToChapter(Section chapter) {
    if (_tabController.index != 0) _tabController.animateTo(0);
    if (_isSearchActive) _searchController.clear();
    setState(() {
      _filteredChapters = null;
      _isSearchActive = false;
      _selectedChapterId = chapter.id;
    });
    // Mobile: wait for the list to rebuild, then bring the card into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chapterCardKeys[chapter.id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      }
    });
  }

  /// Desktop: chapter outline on the left, the selected chapter's full
  /// lesson list on the right — every lesson is visible without extra taps.
  Widget _buildChaptersDesktop(List<Section> chapters) {
    var selected = chapters.indexWhere((s) => s.id == _selectedChapterId);
    if (selected < 0) {
      // Search results use their own indices, so map the "current" chapter by id.
      final currentId = (_chapters != null &&
              _currentSectionIndex < _chapters!.length)
          ? _chapters![_currentSectionIndex].id
          : null;
      selected = chapters.indexWhere((s) => s.id == currentId);
      if (selected < 0) selected = 0;
    }
    final s = chapters[selected];
    // Chapter numbers always come from the full list, not the filtered one.
    int numberOf(Section sec) {
      final i = _chapters?.indexWhere((c) => c.id == sec.id) ?? -1;
      return i < 0 ? chapters.indexOf(sec) : i;
    }

    final screenW = MediaQuery.of(context).size.width;
    final sidebarW = screenW > 1600 ? 380.0 : 330.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sidebarW,
            child: _buildChapterOutline(chapters, selected, numberOf),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              // New key per chapter so switching chapters starts at the top.
              key: ValueKey('chapter-scroll-${s.id}'),
              padding: const EdgeInsets.only(bottom: 120),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: _ChapterCard(
                    key: ValueKey('chapter-detail-${s.id}'),
                    section: s,
                    chapterIndex: numberOf(s),
                    lessons: _chapterLessons[s.id] ?? [],
                    isUnlocked: _chapterUnlockedStatus[s.id] ?? false,
                    isCurrent: numberOf(s) == _currentSectionIndex,
                    isChapterCompleted: _chapterCompletionStatus[s.id] ?? false,
                    lessonCompletionStatus: _lessonCompletionStatus,
                    isDark: _isDark,
                    isCompact: false,
                    showLessonNumbers: true,
                    isLastChapter: _isLastChapter(s),
                    nextChapterTitle: _nextChapterOf(s)?.title,
                    onNextChapter: _goToNextChapter(s),
                    onLessonTap: _openLesson,
                    onMoreTap: () => _openChapterDetails(s, numberOf(s)),
                    onMarkComplete: () => _markChapterComplete(s, numberOf(s)),
                    isLoading: _markingCompleteChapterId == s.id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterOutline(
    List<Section> chapters,
    int selected,
    int Function(Section) numberOf,
  ) {
    final total = _totalLessons;
    final progress = _progress;
    final done = (progress * total).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r16,
        border: Border.all(
            color: _isDark ? _DT.borderDark : _DT.border, width: 0.8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? Colors.white : _DT.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${chapters.length} ${chapters.length == 1 ? "chapter" : "chapters"}'
                  ' · $done/$total lessons done',
                  style: const TextStyle(
                      fontSize: 12, color: _DT.textSecondary),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: _DT.r32,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: _isDark ? _DT.surfaceDk : _DT.surface,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_DT.primary),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: _isDark ? _DT.borderDark : _DT.border),
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chapters.length,
              itemBuilder: (ctx, i) {
                final s = chapters[i];
                final lessons = _chapterLessons[s.id] ?? const <Lesson>[];
                return _ChapterOutlineTile(
                  number: numberOf(s) + 1,
                  title: s.title,
                  lessonCount: lessons.length,
                  completedCount: lessons
                      .where((l) => _lessonCompletionStatus[l.id] == true)
                      .length,
                  isUnlocked: _chapterUnlockedStatus[s.id] ?? false,
                  isCompleted: _chapterCompletionStatus[s.id] ?? false,
                  isSelected: i == selected,
                  isDark: _isDark,
                  onTap: () => setState(() => _selectedChapterId = s.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList(List<Section> chapters) {
    // Not a lazy ListView: every card must be built so "next chapter" can
    // scroll to it. Courses have few chapters, so this stays cheap.
    final hPad = ResponsiveBreakpoints.isSmallMobile(context) ? 12.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in chapters) ...[
            if (s != chapters.first) const SizedBox(height: 20),
            Builder(builder: (_) {
              // Index in the full course, not the (possibly filtered) list.
              final idx = _chapters!.indexWhere((c) => c.id == s.id);
              return _ChapterCard(
                key: _chapterCardKeys.putIfAbsent(s.id, GlobalKey.new),
                section: s,
                chapterIndex: idx,
                lessons: _chapterLessons[s.id] ?? [],
                isUnlocked: _chapterUnlockedStatus[s.id] ?? false,
                isCurrent: idx == _currentSectionIndex,
                isChapterCompleted: _chapterCompletionStatus[s.id] ?? false,
                lessonCompletionStatus: _lessonCompletionStatus,
                isDark: _isDark,
                isCompact: false,
                isLastChapter: _isLastChapter(s),
                nextChapterTitle: _nextChapterOf(s)?.title,
                onNextChapter: _goToNextChapter(s),
                onLessonTap: _openLesson,
                onMoreTap: () => _openChapterDetails(s, idx),
                onMarkComplete: () => _markChapterComplete(s, idx),
                isLoading: _markingCompleteChapterId == s.id,
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LIVE SESSIONS TAB
  // ─────────────────────────────────────────────
  List<LiveSession> _courseSessions = [];
  List<LiveSession> _liveNowSessions = [];
  List<LiveSession> _upcomingSessions = [];
  List<LiveSession> _pastSessions = [];
  List<LiveSession> _missedSessions = [];
  bool _isLoadingSessions = false;
  bool _sessionsLoaded = false;
  late TabController _liveSessionsTabController;

  Future<void> _loadLiveSessions() async {
    if (_isLoadingSessions) return;
    setState(() {
      _isLoadingSessions = true;
      _sessionsLoaded = false;
    });
    try {
      final service = LiveSessionService();
      // Load every session for this course (scheduled, live, ended, cancelled)
      // so Past/Missed tabs have data to show, not just upcoming ones.
      final response = await service.getCourseSessions(
        widget.courseId,
        status: 'all',
        limit: 100,
      );
      if (mounted) {
        final now = DateTime.now();
        final allSessions = response.sessions;

        // Filter into categories
        _liveNowSessions = allSessions.where((s) {
          // Live if status is 'live' OR if scheduled time has passed but session hasn't ended
          final isLive = s.status == 'live';
          final hasStartedAndNotEnded = !s.isEnded && !s.isCancelled &&
              (s.scheduledAt.isBefore(now) || s.scheduledAt.isAtSameMomentAs(now)) &&
              s.calculatedEndTime.isAfter(now);
          return isLive || hasStartedAndNotEnded;
        }).toList();

        _upcomingSessions = allSessions.where((s) {
          // Upcoming if scheduled time is in the future (or within 5 minutes) and not ended/cancelled
          return !s.isEnded && !s.isCancelled &&
              s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
        }).toList();

        _pastSessions = allSessions.where((s) {
          // Past only if status is 'ended' or 'cancelled'
          return s.isEnded || s.isCancelled;
        }).toList();

        // Missed sessions: ended/cancelled that the user didn't attend.
        // Attendee ids from the backend are Mongo user ids, so we must compare
        // against the app-level user id (authProvider), not the Firebase uid.
        final currentUserId = ref.read(authProvider)?.user?.id;

        String? extractAttendeeId(dynamic a) {
          if (a is Map) {
            final nested = a['userId'];
            if (nested is Map) return (nested['_id'] ?? nested['id'])?.toString();
            return (nested ?? a['_id'] ?? a['id'])?.toString();
          }
          return a?.toString();
        }

        _missedSessions = allSessions.where((s) {
          if (!(s.isEnded || s.isCancelled)) return false;

          // Check if user attended this session
          if (currentUserId != null && currentUserId.isNotEmpty) {
            final attendees = s.attendees ?? [];
            final attendedAt = s.attendedAt ?? [];

            // User attended if they're in attendees list or attendedAt list
            final didAttend = attendees.any((a) => extractAttendeeId(a) == currentUserId) ||
                attendedAt.any((a) => extractAttendeeId(a) == currentUserId);

            // Only show in missed if user did NOT attend
            return !didAttend;
          }

          // If no current user, show all ended/cancelled as potentially missed
          return true;
        }).toList();

        // Sort each list
        _liveNowSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _upcomingSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _pastSessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        _missedSessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        setState(() {
          _courseSessions = allSessions;
          _isLoadingSessions = false;
          _sessionsLoaded = true;
        });
        // Schedule push notifications for upcoming sessions
        PushNotificationService.scheduleLiveSessionNotifications(_upcomingSessions);
      }
    } catch (e) {
      debugPrint('Error loading live sessions: $e');
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _joinStudentSession(LiveSession session) async {
    try {
      final service = LiveSessionService();
      final response = await service.joinSession(session.id);
      if (!mounted) return;
      if (response.joinUrl.isNotEmpty) {
        final uri = Uri.parse(response.joinUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: ${response.joinUrl}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining session: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLiveSessionsTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has live session access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have live session access, show permission denied
      if (enrollment != null && !enrollment.canAccessLiveSessions) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessLiveSessions,
          subtitle: 'Please contact your administrator for access to live sessions',
        );
      }
    }

    // Load sessions exactly once
    if (!_sessionsLoaded && !_isLoadingSessions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_sessionsLoaded && !_isLoadingSessions) _loadLiveSessions();
      });
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Header
        Container(
          margin: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 16, isMobile ? 12 : 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_call, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Live Sessions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadLiveSessions,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Join live classes and interact with your instructor in real time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs
        Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
          decoration: BoxDecoration(
            color: _isDark ? _DT.surfaceDk : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _liveSessionsTabController,
            indicator: BoxDecoration(
              color: _isDark ? _DT.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: const Color(0xFF00C853),
            unselectedLabelColor: _isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Live Now'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Missed'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _liveSessionsTabController,
            children: [
              _buildSessionsList(_liveNowSessions, 'liveNow', isMobile),
              _buildSessionsList(_upcomingSessions, 'upcoming', isMobile),
              _buildSessionsList(_pastSessions, 'past', isMobile),
              _buildSessionsList(_missedSessions, 'missed', isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList(List<LiveSession> sessions, String type, bool isMobile) {
    if (_isLoadingSessions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      String message;
      IconData icon;
      switch (type) {
        case 'liveNow':
          message = 'No live sessions right now';
          icon = Icons.live_tv;
          break;
        case 'upcoming':
          message = 'No upcoming live sessions';
          icon = Icons.schedule;
          break;
        case 'past':
          message = 'No past sessions yet';
          icon = Icons.history;
          break;
        case 'missed':
          message = 'No missed sessions';
          icon = Icons.event_busy;
          break;
        default:
          message = 'No sessions found';
          icon = Icons.video_call;
      }

      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              icon,
              size: 64,
              color: _isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: _isDark ? Colors.grey[300] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'liveNow' ? 'Live sessions will appear here when they start' :
              type == 'upcoming' ? 'Check back later for scheduled sessions' : 'Sessions will appear here',
              style: TextStyle(
                color: _isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 0, isMobile ? 12 : 20, 100),
      children: sessions.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Future<void> _watchRecording(LiveSession session) async {
    final url = session.recordingUrl;
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open recording: $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening recording: $e')),
        );
      }
    }
  }

  Widget _buildSessionCard(LiveSession session) {
    final now = DateTime.now();
    final isActuallyEnded = session.isEnded ||
        session.isCancelled ||
        session.calculatedEndTime.isBefore(now);
    final isLive =
        session.status == 'live' && !isActuallyEnded && !session.isCancelled;
    // Joinable only if session is actually live
    final canJoin = isLive;
    final mutedText = _isDark ? Colors.grey[400] : Colors.grey[600];

    late final String badgeLabel;
    late final MaterialColor badgeColor;
    if (isLive) {
      badgeLabel = 'LIVE NOW';
      badgeColor = Colors.red;
    } else if (session.isCancelled) {
      badgeLabel = 'CANCELLED';
      badgeColor = Colors.grey;
    } else if (isActuallyEnded) {
      badgeLabel = 'ENDED';
      badgeColor = Colors.blueGrey;
    } else {
      badgeLabel = 'UPCOMING';
      badgeColor = Colors.orange;
    }
    final badgeTextColor = _isDark ? badgeColor[300]! : badgeColor[700]!;

    return Card(
      color: _cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(_isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isLive) const SizedBox(width: 6),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: mutedText),
                const SizedBox(width: 4),
                Text(
                  session.timeProgressInfo,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            if (session.description != null && session.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                session.description!,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            LiveSessionCountdown(
              scheduledAt: session.scheduledAt,
              durationMinutes: session.duration,
              isLive: session.isLive,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: mutedText),
                const SizedBox(width: 4),
                Text(
                  '${session.duration} min',
                  style: TextStyle(color: mutedText, fontSize: 12),
                ),
                const Spacer(),
                if (canJoin)
                  ElevatedButton.icon(
                    onPressed: () => _joinStudentSession(session),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: Text(isLive ? 'Join Live' : 'Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isLive ? Colors.red : const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (isActuallyEnded && session.hasRecording)
                  ElevatedButton.icon(
                    onPressed: () => _watchRecording(session),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: const Text('Watch Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DT.accent,
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (isActuallyEnded)
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(session.isCancelled
                        ? Icons.event_busy_rounded
                        : Icons.check_circle_outline_rounded),
                    label: Text(session.isCancelled ? 'Cancelled' : 'Ended'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: mutedText,
                      side: BorderSide(color: _borderColor),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Scheduled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: mutedText,
                      side: BorderSide(color: _borderColor),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PROGRESS TAB
  // ─────────────────────────────────────────────
  Widget _buildProgressTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ListView(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 16, isMobile ? 12 : 20, 100),
      children: [
        _buildXpLevelBanner(),
        const SizedBox(height: 16),
        _buildProgressHeroCard(),
        const SizedBox(height: 16),
        _buildChapterProgressList(),
        const SizedBox(height: 16),
        _buildAchievementsGrid(),
      ],
    );
  }

  Widget _buildXpLevelBanner() {
    final level = (_xpPoints ~/ 500) + 1;
    final xpInLevel = _xpPoints % 500;
    final xpToNextLevel = 500;
    final levelPct = xpInLevel / xpToNextLevel;
    final levelTitles = ['Beginner', 'Explorer', 'Learner', 'Achiever', 'Expert', 'Master'];
    final levelTitle = levelTitles[(level - 1).clamp(0, levelTitles.length - 1)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF5C35E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        boxShadow: [
          BoxShadow(
              color: _DT.accent.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Lv$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_xpPoints XP  •  ${xpToNextLevel - xpInLevel} to next',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r32,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$_xpPoints XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $level progress',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  Text('$xpInLevel / $xpToNextLevel XP',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: _DT.r32,
                child: LinearProgressIndicator(
                  value: levelPct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeroCard() {
    final completedChapters =
        _chapterCompletionStatus.values.where((v) => v).length;
    final totalChapters = _chapters?.length ?? 0;
    final screenW = MediaQuery.of(context).size.width;
    final isNarrow = screenW < 380;
    final ringSize = isNarrow ? 80.0 : 96.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big ring
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: _progress,
                        backgroundColor: _borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            _DT.primary),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: isNarrow ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: _DT.primary,
                          ),
                        ),
                        Text('Done',
                            style: TextStyle(
                                fontSize: 10,
                                color: _textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressStatRow(
                      label: 'Lessons done',
                      value: '$_completedLessonsCount / $_totalLessons',
                      color: _DT.primary,
                      isDark: _isDark,
                    ),
                    const SizedBox(height: 10),
                    _ProgressStatRow(
                      label: 'Chapters done',
                      value: '$completedChapters / $totalChapters',
                      color: _DT.accent,
                      isDark: _isDark,
                    ),
                    const SizedBox(height: 10),
                    _ProgressStatRow(
                      label: 'Time invested',
                      value: '${_completedDurationMinutes}m',
                      color: const Color(0xFF00ACC1),
                      isDark: _isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall completion',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500)),
                  Text('${(_progress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: _DT.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: _DT.r8,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: _borderColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_DT.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterProgressList() {
    if (_chapters == null || _chapters!.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Chapter breakdown',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ),
          ..._chapters!.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final lessons = _chapterLessons[s.id] ?? [];
            final done =
                lessons.where((l) => _lessonCompletionStatus[l.id] == true).length;
            final pct = lessons.isEmpty ? 0.0 : done / lessons.length;
            final isCompleted = _chapterCompletionStatus[s.id] ?? false;

            return _ChapterProgressRow(
              index: i + 1,
              title: 'Chapter ${i + 1}: ${s.title}',
              done: done,
              total: lessons.length,
              pct: pct,
              isCompleted: isCompleted,
              isDark: _isDark,
              isLast: i == _chapters!.length - 1,
            );
          }),
        ],
      ),
    );
  }

  /// Titles of achievements already unlocked; null until the course loads.
  Set<String>? _knownUnlockedAchievements;

  Set<String> _unlockedAchievementTitles() =>
      _achievements().where((a) => a.unlocked).map((a) => a.title).toSet();

  /// Plays the unlock sound and shows a banner for achievements earned since
  /// the last check. [delay] lets a bigger celebration sound finish first.
  void _checkNewAchievements({Duration delay = Duration.zero}) {
    final known = _knownUnlockedAchievements;
    if (known == null) return;
    final now = _unlockedAchievementTitles();
    final fresh = now.difference(known);
    _knownUnlockedAchievements = now;
    if (fresh.isEmpty) return;

    Future.delayed(delay, () {
      if (!mounted) return;
      AchievementSoundService.instance.play(AchievementSound.achievementUnlocked);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _DT.accent,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Achievement unlocked: ${fresh.join(', ')}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ));
    });
  }

  List<_Achievement> _achievements() {
    final completedChaptersCount =
        _chapterCompletionStatus.values.where((v) => v).length;
    return [
      _Achievement(
        title: 'First Steps',
        desc: 'Complete your first lesson',
        icon: Icons.emoji_events_rounded,
        unlocked: _completedLessonsCount > 0,
        color: const Color(0xFFFFC107),
        xp: 10,
      ),
      _Achievement(
        title: 'Quick Learner',
        desc: 'Complete 5 lessons',
        icon: Icons.flash_on_rounded,
        unlocked: _completedLessonsCount >= 5,
        color: const Color(0xFFFF7043),
        xp: 50,
      ),
      _Achievement(
        title: 'Chapter Hero',
        desc: 'Complete your first chapter',
        icon: Icons.book_rounded,
        unlocked: completedChaptersCount >= 1,
        color: _DT.accent,
        xp: 100,
      ),
      _Achievement(
        title: 'Halfway There',
        desc: '50% course completion',
        icon: Icons.trending_up_rounded,
        unlocked: _progress >= 0.5,
        color: _DT.primary,
        xp: 200,
      ),
      _Achievement(
        title: 'Dedicated',
        desc: 'Complete 3 chapters',
        icon: Icons.workspace_premium_rounded,
        unlocked: completedChaptersCount >= 3,
        color: const Color(0xFF00ACC1),
        xp: 300,
      ),
      _Achievement(
        title: 'Graduate',
        desc: 'Finish the entire course',
        icon: Icons.military_tech_rounded,
        unlocked: _totalLessons > 0 && _progress >= 1.0,
        color: const Color(0xFFFFD700),
        xp: 500,
      ),
    ];
  }

  Widget _buildAchievementsGrid() {
    final achievements = _achievements();
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Achievements',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DT.accent.withOpacity(0.1),
                  borderRadius: _DT.r32,
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length} unlocked',
                  style: const TextStyle(
                    color: _DT.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final crossCount = w < 300 ? 1 : (w < 500 ? 2 : 3);
              final aspectRatio = w < 300 ? 3.5 : (w < 500 ? 1.55 : 1.7);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final a = achievements[index];
                  return _AchievementCard(a: a, isDark: _isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  COMMUNITY TAB
  // ─────────────────────────────────────────────
  /// The course community sits in the main tab row (where "Saved" used to be)
  /// so collaboration is as visible as the lessons themselves. Saved lessons
  /// moved to the bookmark action in the app bar.
  Widget _buildCommunityTab() {
    return CourseCommunityView(courseId: widget.courseId);
  }

  // ─────────────────────────────────────────────
  //  SAVED LESSONS (opened from the app bar)
  // ─────────────────────────────────────────────
  void _openSavedLessons() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
          appBar: AppBar(
            backgroundColor: _cardBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Saved lessons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
          body: _buildBookmarksTab(),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab() {
    // Load bookmarks exactly once
    if (!_bookmarksLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_bookmarksLoaded) _loadBookmarks();
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookmarkedLessons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No bookmarked lessons',
        subtitle: 'Bookmark lessons to find them here quickly',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        20,
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        100,
      ),
      itemCount: _bookmarkedLessons.length,
      itemBuilder: (context, index) {
        final lesson = _bookmarkedLessons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BookmarkedLessonCard(
            lesson: lesson,
            isDark: _isDark,
            onTap: () => _openLesson(lesson),
            onRemoveBookmark: () => _removeBookmark(lesson.id),
          ),
        );
      },
    );
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <Lesson>[];
      if (_chapterLessons.isNotEmpty) {
        for (final sectionId in _chapterLessons.keys) {
          for (final lesson in _chapterLessons[sectionId] ?? []) {
            if (prefs.getBool('bookmarked_lesson_${lesson.id}') == true) {
              result.add(lesson);
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _bookmarkedLessons = result;
          _bookmarksLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      if (mounted) setState(() => _bookmarksLoaded = true);
    }
  }

  Future<void> _removeBookmark(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bookmarked_lesson_$lessonId', false);
      setState(() {
        _bookmarkedLessons.removeWhere((l) => l.id == lessonId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookmark removed'),
          backgroundColor: _DT.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove bookmark: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  LESSONS TAB
  // ─────────────────────────────────────────────
  Widget _buildMaterialsTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    if (_chapters == null || _chapters!.isEmpty) {
      return _buildEmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No lessons yet',
          subtitle: 'Lessons appear as chapters are added');
    }

    // Pre-filter chapters with materials for efficient rendering
    final chaptersWithMaterials = _chapters!.asMap().entries.where((e) {
      final s = e.value;
      final lessons = _chapterLessons[s.id] ?? [];
      final materials = _extractChapterMaterials(s, lessons);
      return materials.isNotEmpty;
    }).toList();

    // Fixed header count: download banner always present + optional description + optional invoice
    final int descOffset = 1; // download banner is always index 0
    final int invoiceOffset = descOffset + (_course?.description != null ? 1 : 0);
    final int chaptersOffset = invoiceOffset + (_hasPaidForCourse ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: chaptersOffset + chaptersWithMaterials.length,
      itemBuilder: (context, index) {
        // ── Download whole course banner (always at top) ──
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCourseDownloadBanner(),
          );
        }

        // Course description card
        if (_course?.description != null && index == descOffset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCourseSummaryCard(),
          );
        }

        // Invoice download card
        if (_hasPaidForCourse && index == invoiceOffset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildInvoiceDownloadCard(),
          );
        }

        // Chapter materials cards
        final chapterIndex = index - chaptersOffset;
        if (chapterIndex >= 0 && chapterIndex < chaptersWithMaterials.length) {
          final e = chaptersWithMaterials[chapterIndex];
          final i = e.key;
          final s = e.value;
          final lessons = _chapterLessons[s.id] ?? [];
          final materials = _extractChapterMaterials(s, lessons);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ChapterMaterialsCard(
              section: s,
              materials: materials,
              chapterIndex: i,
              lessons: lessons,
              lessonCompletionStatus: _lessonCompletionStatus,
              isDark: _isDark,
              onTap: _openMaterial,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCourseDownloadBanner() {
    final downloadService = ref.watch(downloadServiceProvider);
    final allLessons = <Lesson>[];
    for (final chapter in _chapters ?? []) {
      allLessons.addAll((_chapterLessons[chapter.id] ?? []).where((l) => l.hasVideo));
    }
    final totalVideos = allLessons.length;
    final downloadedCount = allLessons.where((l) {
      final s = downloadService.getDownloadStatus(l.id);
      return s?.status == DownloadStatus.completed;
    }).length;
    final allDone = totalVideos > 0 && downloadedCount == totalVideos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [const Color(0xFF00C853).withOpacity(0.12), const Color(0xFF00897B).withOpacity(0.08)]
              : [const Color(0xFF1A1F2E), const Color(0xFF111522)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(
          color: allDone ? _DT.primary.withOpacity(0.3) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: allDone
                      ? _DT.primary.withOpacity(0.15)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: _DT.r12,
                ),
                child: Icon(
                  allDone ? Icons.offline_pin_rounded : Icons.download_for_offline_rounded,
                  color: allDone ? _DT.primary : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? 'Course Downloaded' : 'Download Whole Course',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: allDone ? _textPrimary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      allDone
                          ? '$downloadedCount/$totalVideos lessons ready offline'
                          : 'Watch all $totalVideos video lesson${totalVideos != 1 ? "s" : ""} offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: allDone ? _textSecondary : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isCourseDownloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: _DT.r8,
              child: LinearProgressIndicator(
                value: _courseDownloadTotal > 0
                    ? (_courseDownloadDone + _courseDownloadFailed) / _courseDownloadTotal
                    : null,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(_DT.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_courseDownloadDone/$_courseDownloadTotal lessons downloaded'
              '${_courseDownloadFailed > 0 ? " · $_courseDownloadFailed failed" : ""}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
          if (!_isCourseDownloading) ...[
            const SizedBox(height: 16),
            if (totalVideos > 0 && downloadedCount > 0 && !allDone)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: _DT.r8,
                        child: LinearProgressIndicator(
                          value: downloadedCount / totalVideos,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(_DT.primary),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$downloadedCount/$totalVideos',
                      style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: totalVideos == 0 ? null : (allDone ? () => context.go('/downloads') : _downloadWholeCourse),
                    icon: Icon(
                      allDone ? Icons.folder_open_rounded : Icons.download_rounded,
                      size: 18,
                    ),
                    label: Text(allDone ? 'View Downloads' : (downloadedCount > 0 ? 'Resume Download' : 'Download All')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DT.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                if (!allDone && downloadedCount > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/downloads'),
                    icon: const Icon(Icons.offline_pin_rounded, size: 16),
                    label: const Text('My Downloads'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DT.primary.withOpacity(0.08), _DT.accent.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(color: _DT.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _DT.primary.withOpacity(0.12),
              borderRadius: _DT.r12,
            ),
            child: const Icon(Icons.description_rounded,
                color: _DT.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course Overview',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _textPrimary)),
                const SizedBox(height: 4),
                Text(
                  _course!.description ?? '',
                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDownloadCard() {
    final payment = _getUserPaymentForCurrentCourse();
    final isDownloading = ref.watch(paymentProvider).isProcessing;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DT.accent.withOpacity(0.08), _DT.primary.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(color: _DT.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DT.accent.withOpacity(0.12),
                  borderRadius: _DT.r12,
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: _DT.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Invoice',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Download your payment receipt for this course',
                      style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (payment != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: _DT.r12,
                border: Border.all(color: _borderColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Details',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
                          borderRadius: _DT.r8,
                        ),
                        child: Text(
                          payment.status.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getPaymentStatusColor(payment.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PaymentDetailRow(
                    label: 'Amount',
                    value: '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                    isDark: _isDark,
                  ),
                  _PaymentDetailRow(
                    label: 'Payment ID',
                    value: '${payment.id.substring(0, 8)}...',
                    isDark: _isDark,
                  ),
                  _PaymentDetailRow(
                    label: 'Date',
                    value: payment.createdAt.toString().substring(0, 10),
                    isDark: _isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : _downloadInvoice,
              icon: isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(isDownloading ? 'Downloading...' : 'Download Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DT.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
      case PaymentStatus.approved:
        return _DT.primary;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return _textSecondary;
      default:
        return _textSecondary;
    }
  }

  // ─────────────────────────────────────────────
  //  LIBRARY TAB
  // ─────────────────────────────────────────────
  Widget _buildLibraryTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    if (_isLoadingBooks) {
      return Center(
        child: CircularProgressIndicator(color: _DT.primary),
      );
    }

    if (_booksError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'Failed to load books',
                style: TextStyle(fontSize: 16, color: _textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _booksError!,
                style: TextStyle(fontSize: 12, color: _textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCourseBooks,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DT.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courseBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No books available',
        subtitle: 'No books have been linked to this course yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _courseBooks.length,
      itemBuilder: (context, index) {
        final book = _courseBooks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBookCard(book),
        );
      },
    );
  }

  Widget _buildBookCard(dynamic book) {
    final String coverUrl = book['coverUrl'] ?? '';
    final String title = book['title'] ?? 'Untitled';
    final String author = book['author'] ?? 'Unknown Author';
    final String? description = book['description'];
    final String pdfUrl = book['pdfUrl'] ?? '';
    final String subject = book['subject'] ?? 'General';
    final String language = book['language'] ?? 'en';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r16,
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        boxShadow: _DT.cardShadow,
      ),
      child: InkWell(
        borderRadius: _DT.r16,
        onTap: () {
          if (pdfUrl.isNotEmpty) {
            _openBookReader(book);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            if (coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  mediaProxyUrl(coverUrl),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_DT.primary.withOpacity(0.1), _DT.accent.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.menu_book_rounded, size: 64, color: _DT.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_DT.primary.withOpacity(0.1), _DT.accent.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.menu_book_rounded, size: 64, color: _DT.primary.withOpacity(0.3)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _DT.primary.withOpacity(0.1),
                      borderRadius: _DT.r8,
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _DT.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Author
                  Text(
                    'By $author',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Language badge
                  Row(
                    children: [
                      Icon(Icons.language_rounded, size: 14, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        language.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: _DT.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pdfUrl.isNotEmpty ? () => _openBookReader(book) : null,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Read'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DT.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pdfUrl.isNotEmpty ? () => _downloadBookToApp(book) : null,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _DT.primary,
                            side: BorderSide(color: _DT.primary),
                            shape: RoundedRectangleBorder(borderRadius: _DT.r12),
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
    );
  }

  void _openBookReader(dynamic book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(book: book),
      ),
    );
  }

  Future<void> _downloadBookToApp(dynamic book) async {
    final String pdfUrl = book['pdfUrl'] ?? '';
    final String title = book['title'] ?? 'Untitled';

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF available for download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "$title"...'),
        backgroundColor: _DT.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final downloadService = DownloadService();
      // Resolved the same way the Library does it, so a book saved from either
      // place is the one download record with the same cover art.
      final target = resolveBookDownload(book);
      final bookId = book['_id'] ?? book['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await downloadService.downloadNotesOrMaterial(
        url: pdfUrl,
        title: title,
        lessonId: target?.lessonId ?? 'book_$bookId',
        type: DownloadType.material,
        lessonTitle: target?.author,
        sectionTitle: 'Library',
        thumbnailUrl: target?.coverUrl ?? book['coverUrl']?.toString(),
        onProgress: (progress) {
          // Optional: Show progress updates
        },
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────
  //  AI CHAT FAB
  // ─────────────────────────────────────────────
  Widget _buildAIChatFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: AnimatedBuilder(
        animation: _fabPulse ?? const AlwaysStoppedAnimation(1.0),
        builder: (context, child) => Transform.scale(
          scale: _isChatExpanded ? 1.0 : (_fabPulse?.value ?? 1.0),
          child: child,
        ),
        child: GestureDetector(
          onTap: () => setState(() => _isChatExpanded = !_isChatExpanded),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isChatExpanded
                    ? [const Color(0xFF6E35F5), const Color(0xFF4A1FCC)]
                    : [const Color(0xFF7C4DFF), const Color(0xFF5C35E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: _DT.r20,
              boxShadow: [
                BoxShadow(
                    color: _DT.accent.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: _DT.accent.withOpacity(0.15),
                    blurRadius: 48,
                    spreadRadius: 8,
                    offset: const Offset(0, 16)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                if (!_isChatExpanded)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _fabPulse ?? const AlwaysStoppedAnimation(1.0),
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          borderRadius: _DT.r20,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                                ((_fabPulse?.value ?? 1.0) - 1.0) * 3.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Brain icon
                const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 30),
                // Sparkle top-right
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _DT.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: _DT.primary.withOpacity(0.6),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 10),
                  ),
                ),
                // "AI" label bottom
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00897B)]),
                      borderRadius: _DT.r32,
                      boxShadow: [
                        BoxShadow(
                            color: _DT.primary.withOpacity(0.4),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Text(
                      'AI Teacher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  AI CHAT OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildAIChatOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _isChatExpanded = false),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ModernAIChatDialog(
                currentCourse: _course,
                allSections: _chapters,
                sectionLessons: _chapterLessons,
                chatService: _aiChatService,
                conversationId: _conversationId,
                guideKey: _guideKey,
                onClose: () => setState(() => _isChatExpanded = false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAPTER DETAILS MODAL
  // ─────────────────────────────────────────────
  void _openChapterDetails(Section section, int chapterIndex) {
    final lessons = _chapterLessons[section.id] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChapterDetailsSheet(
        section: section,
        chapterIndex: chapterIndex,
        lessons: lessons,
        lessonCompletionStatus: _lessonCompletionStatus,
        isDark: _isDark,
        isLoading: _isLoadingChapterDetails,
        onLessonTap: (l) {
          Navigator.pop(ctx);
          _openLesson(l);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>> _extractChapterMaterials(
      Section section, List<Lesson> lessons) {
    final materials = <Map<String, dynamic>>[];
    for (var lesson in lessons) {
      if (lesson.hasVideo) {
        materials.add({
          'title': lesson.title,
          'type': 'video',
          'icon': Icons.play_circle_rounded,
          'color': _DT.primary,
          'videoId': lesson.videoId,
          'duration': lesson.duration,
          'lessonId': lesson.id,
          'subtitle': '${lesson.duration} min video',
        });
      }
      if (lesson.hasNotes) {
        materials.add({
          'title': '${lesson.title} — Notes',
          'type': 'notes',
          'icon': Icons.description_rounded,
          'color': _DT.accent,
          'notes': lesson.notes,
          'notesPdfUrl': lesson.notesPdfUrl,
          'lessonId': lesson.id,
          'subtitle': 'Study notes',
        });
      }
      if (lesson.hasQuiz) {
        materials.add({
          'title': '${lesson.title} — Quiz',
          'type': 'quiz',
          'icon': Icons.quiz_rounded,
          'color': const Color(0xFFF59E0B),
          'quizId': lesson.quizId,
          'lessonId': lesson.id,
          'subtitle': 'Knowledge check',
        });
      }
      if (lesson.hasMaterials)
        for (var url in lesson.materials!) {
          materials.add({
            'title': url.split('/').last,
            'type': 'document',
            'icon': Icons.insert_drive_file_rounded,
            'color': const Color(0xFF8B5CF6),
            'url': url,
            'lessonId': lesson.id,
            'subtitle': 'Resource file',
          });
        }
    }
    return materials;
  }

  Future<void> _openLesson(Lesson lesson) => _openLessonById(lesson.id);

  /// Opens a lesson, optionally landing directly on one of its tabs
  /// ('video', 'notes', 'quiz'), then syncs the owning chapter's progress.
  Future<void> _openLessonById(String lessonId, {String? tab}) async {
    // Snapshot completion before navigating
    final wasCompleted = _lessonCompletionStatus[lessonId] == true;

    final query = (tab != null && tab.isNotEmpty) ? '?tab=$tab' : '';
    await context.push('/lesson/$lessonId$query');

    if (!mounted) return;

    await _syncChapterProgressForLesson(lessonId,
        optimisticFallback: !wasCompleted);
  }

  /// Refreshes completion for the chapter that owns [lessonId] so progress
  /// always lands on the right chapter, whichever material was opened.
  Future<void> _syncChapterProgressForLesson(String lessonId,
      {bool optimisticFallback = false}) async {
    // Find which chapter this lesson belongs to
    String? chapterId;
    int? chapterIndex;
    for (int i = 0; i < (_chapters?.length ?? 0); i++) {
      final ch = _chapters![i];
      final lessons = _chapterLessons[ch.id] ?? [];
      if (lessons.any((l) => l.id == lessonId)) {
        chapterId = ch.id;
        chapterIndex = i;
        break;
      }
    }
    if (chapterId == null || chapterIndex == null) return;

    // Refresh completion status from server for this chapter's lessons
    try {
      final accessData = await ref
          .read(enrollmentRepositoryProvider)
          .checkCourseAccess(widget.courseId);
      if (!mounted) return;

      final completedList =
          (accessData?['completedLessons'] as List?)?.map((e) => e.toString()).toSet() ?? {};

      final chapterLessons = _chapterLessons[chapterId] ?? [];
      bool anyNewlyCompleted = false;

      setState(() {
        for (final l in chapterLessons) {
          final nowDone = completedList.contains(l.id);
          if (nowDone && _lessonCompletionStatus[l.id] != true) {
            _lessonCompletionStatus[l.id] = true;
            _completedLessonsCount++;
            _completedDurationMinutes += l.duration;
            anyNewlyCompleted = true;
          }
        }
        // Recompute XP
        _xpPoints = (_completedLessonsCount * 10) +
            (_chapterCompletionStatus.values.where((v) => v).length * 100);
      });
      // Delay past the lesson screen's own "lesson complete" ding.
      if (anyNewlyCompleted) {
        _checkNewAchievements(delay: const Duration(milliseconds: 600));
      }

      // Check if this lesson being completed finishes the whole chapter
      final allDone = chapterLessons.isNotEmpty &&
          chapterLessons.every((l) => _lessonCompletionStatus[l.id] == true);

      if (anyNewlyCompleted && allDone) {
        await _markChapterComplete(_chapters![chapterIndex], chapterIndex);
      }
    } catch (e) {
      // Fallback: optimistically mark the lesson done if it wasn't before
      if (optimisticFallback && mounted) {
        setState(() {
          _lessonCompletionStatus[lessonId] = true;
          _completedLessonsCount++;
          _xpPoints += 10;
        });
        _checkNewAchievements(delay: const Duration(milliseconds: 600));

        final chapterLessons = _chapterLessons[chapterId] ?? [];
        final allDone = chapterLessons.isNotEmpty &&
            chapterLessons.every((l) => _lessonCompletionStatus[l.id] == true);
        if (allDone) {
          await _markChapterComplete(_chapters![chapterIndex], chapterIndex);
        }
      }
    }
  }

  Future<void> _openMaterial(Map<String, dynamic> m) async {
    final lessonId = m['lessonId'] as String? ?? '';

    switch (m['type'] as String) {
      // Land on the tab matching the material that was tapped: a notes card
      // opens the notes, a video card opens the player
      case 'video':
        if (lessonId.isNotEmpty) await _openLessonById(lessonId, tab: 'video');
        break;
      case 'notes':
        if (lessonId.isNotEmpty) await _openLessonById(lessonId, tab: 'notes');
        break;
      case 'quiz':
        await _openQuizMaterial(m);
        break;
      case 'document':
        final url = m['url'] as String? ?? m['notesPdfUrl'] as String?;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          launchUrl(Uri.parse(url));
        }
        break;
    }
  }

  // ─────────────────────────────────────────────
  //  QUIZ FLOW (Lessons tab)
  //  Same process as the lesson screen: load the quiz and the student's
  //  attempts, show the instructions, run the proctored ExamTakingScreen,
  //  then refresh progress and certificates with the result.
  // ─────────────────────────────────────────────

  Future<void> _openQuizMaterial(Map<String, dynamic> m) async {
    final quizId = m['quizId'] as String? ?? '';
    final lessonId = m['lessonId'] as String? ?? '';

    if (quizId.isEmpty) {
      _snack('This quiz is not available yet', isError: true);
      return;
    }

    final launch = await _loadQuizForLaunch(quizId);
    if (!mounted || launch == null) return;

    final quiz = launch.quiz;

    // Final exams are one-shot and gate the course certificate
    if (_isFinalQuiz(quiz)) {
      if (_validCourseCertificate() != null) {
        _showCertificateEarnedDialog();
        return;
      }
      if (launch.attempts.isNotEmpty) {
        if (_hasPassedQuiz(quiz, launch.attempts)) {
          _showCertificateProcessingDialog();
        } else {
          _showFinalExamFailedDialog();
        }
        return;
      }
    }

    if (launch.questionCount == 0) {
      _snack('This quiz has no questions yet', isError: true);
      return;
    }

    final confirmed = await _showQuizInstructionsDialog(launch);
    if (confirmed != true || !mounted) return;

    await _runQuiz(quiz: quiz, quizId: quizId, lessonId: lessonId);
  }

  /// Fetches the quiz and the student's attempts behind a blocking loader.
  /// Returns null (after showing an error) when the quiz can't be loaded.
  Future<_QuizLaunch?> _loadQuizForLaunch(String quizId) async {
    // canPop is false so a back press can't dismiss the loader and leave the
    // pop below to close the learning screen instead
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: _DT.primary)),
      ),
    );

    Map<String, dynamic>? quiz;
    List<Map<String, dynamic>> attempts = const [];
    int questionCount = 0;
    Object? error;

    try {
      final response = await QuizService.getQuiz(quizId);
      final data = response['data'] as Map<String, dynamic>?;
      quiz = (data?['quiz'] as Map<String, dynamic>?) ?? data;
      if (quiz == null) throw Exception('Quiz not found');

      // The API returns questions alongside the quiz, not nested inside it
      questionCount = (data?['questions'] as List?)?.length ??
          (quiz['questions'] as List?)?.length ??
          0;

      try {
        attempts = await QuizService.getStudentQuizAttempts(quizId);
      } catch (e) {
        // Attempt history is optional — the quiz can still be taken without it
        debugPrint('Failed to load quiz attempts: $e');
      }
    } catch (e) {
      error = e;
    }

    if (!mounted) return null;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss the loader

    if (error != null || quiz == null) {
      debugPrint('Failed to load quiz $quizId: $error');
      _snack('Could not open this quiz. Please try again.', isError: true);
      return null;
    }

    return (quiz: quiz, attempts: attempts, questionCount: questionCount);
  }

  /// Runs the quiz, then syncs everything the result can change.
  Future<void> _runQuiz({
    required Map<String, dynamic> quiz,
    required String quizId,
    required String lessonId,
  }) async {
    final exam = <String, dynamic>{
      'id': quizId,
      'title': quiz['title'] ?? 'Quiz',
      'type': quiz['type'] ?? 'quiz',
      'timeLimit': quiz['timeLimit'] ?? 30,
      'passingScore': quiz['passingScore'] ?? 70,
      'courseId': widget.courseId,
      'questions': const [], // ExamTakingScreen loads these itself
    };

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExamTakingScreen(exam: exam)),
    );
    if (!mounted) return;

    // Re-read attempts so progress reflects what was just submitted
    List<Map<String, dynamic>> attempts = const [];
    try {
      attempts = await QuizService.getStudentQuizAttempts(quizId);
    } catch (e) {
      debugPrint('Failed to refresh quiz attempts: $e');
    }
    if (!mounted) return;

    final passed = _hasPassedQuiz(quiz, attempts);

    // A passed quiz completes its lesson — the Lessons tab shows chapter
    // progress, so record it before re-syncing
    if (passed &&
        lessonId.isNotEmpty &&
        _lessonCompletionStatus[lessonId] != true) {
      try {
        await ref
            .read(enrollmentNotifierProvider.notifier)
            .markLessonComplete(lessonId, widget.courseId);
      } catch (e) {
        debugPrint('Failed to mark lesson complete after quiz: $e');
      }
      if (!mounted) return;
    }

    if (lessonId.isNotEmpty) {
      await _syncChapterProgressForLesson(lessonId, optimisticFallback: passed);
      if (!mounted) return;
    }

    // Passing a final exam generates a certificate server-side
    if (passed && _isFinalQuiz(quiz)) {
      final hadCertificate = _validCourseCertificate() != null;
      await _refreshCourseCertificates();
      if (!hadCertificate) {
        AchievementSoundService.instance.play(AchievementSound.certificateEarned);
      }
    }
  }

  /// Opens the attempt history for this course's quizzes.
  ///
  /// Pushed imperatively rather than with `context.push('/exams/history')`:
  /// that route lives inside the MainLayout ShellRoute, and this screen sits
  /// above the shell, so routing to it would put a second shell page — with
  /// the same page key — into the root navigator and trip Navigator's
  /// duplicate-page-key assertion.
  void _openExamHistory() {
    final quizzes = <CourseQuizRef>[];
    for (final chapter in _chapters ?? const <Section>[]) {
      for (final lesson in _chapterLessons[chapter.id] ?? const <Lesson>[]) {
        if (lesson.hasQuiz) {
          quizzes.add(CourseQuizRef(
            quizId: lesson.quizId!,
            lessonTitle: lesson.title,
            chapterTitle: chapter.title,
          ));
        }
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseExamHistoryScreen(
          courseTitle: _course?.title ?? 'this course',
          quizzes: quizzes,
        ),
      ),
    );
  }

  /// Same shell-route caveat as [_openExamHistory] — `/certificates` is a
  /// MainLayout route, so it is pushed as a plain page from here.
  void _openCertificates() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CertificatesScreen()),
    );
  }

  bool _isFinalQuiz(Map<String, dynamic> quiz) {
    final type = quiz['type']?.toString().toLowerCase() ?? '';
    final title = quiz['title']?.toString().toLowerCase() ?? '';
    return type == 'final' || title.contains('final');
  }

  /// True when any attempt reached the passing score.
  bool _hasPassedQuiz(
      Map<String, dynamic> quiz, List<Map<String, dynamic>> attempts) {
    final passingScore = (quiz['passingScore'] as num?) ?? 70;
    return attempts.any((a) {
      if (a['passed'] == true) return true;
      final percentage = (a['percentage'] as num?) ?? (a['score'] as num?) ?? 0;
      return percentage >= passingScore;
    });
  }

  /// Highest percentage across attempts, or null when there are none.
  num? _bestAttemptScore(List<Map<String, dynamic>> attempts) {
    num? best;
    for (final a in attempts) {
      final percentage = (a['percentage'] as num?) ?? (a['score'] as num?);
      if (percentage != null && (best == null || percentage > best)) {
        best = percentage;
      }
    }
    return best;
  }

  Certificate? _validCourseCertificate() {
    for (final c in _courseCertificates ?? const <Certificate>[]) {
      if (c.courseId == widget.courseId && c.isValid) return c;
    }
    return null;
  }

  Future<void> _refreshCourseCertificates() async {
    try {
      final certificates =
          await CertificateRepository().getCertificatesByCourse(widget.courseId);
      if (!mounted) return;
      setState(() => _courseCertificates = certificates);
    } catch (e) {
      debugPrint('Failed to refresh certificates: $e');
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _DT.primary,
      ),
    );
  }

  // ── Quiz dialogs ─────────────────────────────

  /// Briefs the student before the quiz starts. Resolves true when they
  /// choose to begin.
  Future<bool?> _showQuizInstructionsDialog(_QuizLaunch launch) {
    final quiz = launch.quiz;
    final attempts = launch.attempts;
    final l10n = AppLocalizations.of(context);

    final title = quiz['title']?.toString() ?? 'Lesson Quiz';
    final type = quiz['type']?.toString() ?? 'quiz';
    final rawInstructions = quiz['instructions']?.toString().trim() ?? '';
    final instructions = rawInstructions.isNotEmpty
        ? rawInstructions
        : 'Test your understanding of this lesson.';
    final passingScore = quiz['passingScore'] ?? 70;
    final timeLimit = quiz['timeLimit'] ?? 30;
    final isFinal = _isFinalQuiz(quiz);
    final bestScore = _bestAttemptScore(attempts);

    final textPrimary = _textPrimary;
    final details = <(String, String)>[
      ('Questions', '${launch.questionCount}'),
      ('Time limit', '$timeLimit minutes'),
      ('Passing score', '$passingScore%'),
      if (attempts.isNotEmpty)
        ('Attempts taken', '${attempts.length}'),
      if (bestScore != null)
        ('Best score', '${bestScore.toStringAsFixed(0)}%'),
    ];

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.quiz_rounded,
                color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.quizInstructions ?? 'Quiz Instructions',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DT.primary.withOpacity(0.12),
                  borderRadius: _DT.r32,
                ),
                child: Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                      color: _DT.primaryDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              if (isFinal) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: _DT.r8,
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFF856404), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Final exam — passing it earns your certificate. '
                          'It can only be taken once.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF856404),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: _DT.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('${d.$1}: ',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textPrimary)),
                        Text(d.$2,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _DT.primaryDim)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              Text('Instructions',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const SizedBox(height: 6),
              Text(instructions,
                  style: TextStyle(
                      fontSize: 13, height: 1.5, color: _textSecondary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceBg,
                  borderRadius: _DT.r8,
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: _DT.accent, size: 18),
                        const SizedBox(width: 8),
                        Text('Before you start',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'Read each question carefully before answering',
                      'The timer starts as soon as the quiz opens',
                      'Leaving the app is recorded and auto-submits after 3 warnings',
                      if (isFinal)
                        'Final exams cannot be retaken'
                      else
                        'You can retake this quiz if needed',
                    ].map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 26),
                          child: Text('• $tip',
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: _textSecondary)),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(attempts.isNotEmpty ? 'Retake quiz' : 'Start quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DT.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificateEarnedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: _DT.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Certificate earned',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
            ),
          ],
        ),
        content: Text(
          'You already passed this final exam and your certificate has been '
          'issued, so it cannot be retaken.',
          style: TextStyle(fontSize: 14, height: 1.5, color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close',
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openCertificates();
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(
                AppLocalizations.of(context)?.viewCertificates ??
                    'View certificate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DT.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificateProcessingDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                color: _DT.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  AppLocalizations.of(context)?.certificateProcessing ??
                      'Certificate processing',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Congratulations! You have passed the final exam.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Your certificate is being generated and will appear in the '
              'Certificates section shortly.',
              style: TextStyle(fontSize: 13, height: 1.5, color: _textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it',
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openCertificates();
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(
                AppLocalizations.of(context)?.viewCertificates ??
                    'View certificates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DT.accent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalExamFailedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  AppLocalizations.of(context)?.finalExamFailed ??
                      'Final exam failed',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
            ),
          ],
        ),
        content: Text(
          'You did not pass this final exam and it cannot be retaken. To try '
          'again you would need to unenroll and take the course from the start.',
          style: TextStyle(fontSize: 14, height: 1.5, color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  COURSE-WIDE DOWNLOAD
  // ─────────────────────────────────────────────
  Future<void> _downloadWholeCourse() async {
    if (_isCourseDownloading) return;
    if (_chapters == null || _chapters!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No course content to download yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Collect every lesson in the course (videos and/or materials)
    final allLessons = <Lesson>[];
    for (final chapter in _chapters!) {
      allLessons.addAll(_chapterLessons[chapter.id] ?? []);
    }

    if (allLessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lessons found in this course'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final downloadService = ref.read(downloadServiceProvider);

    // Filter out already-downloaded videos
    final videoTasks = allLessons.where((l) {
      if (!l.hasVideo) return false;
      final status = downloadService.getDownloadStatus(l.id);
      return status == null || status.status != DownloadStatus.completed;
    }).toList();

    // Filter out already-downloaded materials (PDFs / notes attachments)
    final materialTasks = <Lesson>[];
    for (final l in allLessons) {
      if (l.notesPdfUrl == null || l.notesPdfUrl!.isEmpty) continue;
      final alreadyDownloaded = await downloadService.isContentDownloaded(l.id, DownloadType.material);
      if (!alreadyDownloaded) materialTasks.add(l);
    }

    final totalTasks = videoTasks.length + materialTasks.length;

    if (totalTasks == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All videos and materials are already downloaded!'),
            backgroundColor: _DT.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCourseDownloading = true;
        _courseDownloadTotal = totalTasks;
        _courseDownloadDone = 0;
        _courseDownloadFailed = 0;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting download of $totalTasks item${totalTasks > 1 ? "s" : ""}… it will keep going even if you leave this page.'),
          backgroundColor: _DT.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // NOTE: this loop intentionally keeps running after the user navigates
    // away from this screen (no `mounted` guard on the loop itself) so the
    // whole course keeps downloading in the background. `mounted` is only
    // checked before touching widget state/UI below.
    final videoApiService = VideoApiService();

    for (final lesson in videoTasks) {
      try {
        final signedUrl = await videoApiService.getVideoStreamUrl(lesson.id);
        if (signedUrl.isEmpty) throw Exception('Empty URL');

        await downloadService.downloadVideo(
          url: signedUrl,
          fileName: lesson.id,
          originalTitle: lesson.title,
          lessonId: lesson.id,
          thumbnailUrl: _course?.thumbnail,
          onSuccess: () {
            if (mounted) setState(() => _courseDownloadDone++);
          },
          onError: (_) {
            if (mounted) setState(() => _courseDownloadFailed++);
          },
        );
      } catch (e) {
        if (mounted) setState(() => _courseDownloadFailed++);
        debugPrint('Course download: video failed for lesson ${lesson.id}: $e');
      }
    }

    for (final lesson in materialTasks) {
      try {
        await downloadService.downloadNotesOrMaterial(
          url: lesson.notesPdfUrl!,
          title: 'Lesson Material',
          lessonId: lesson.id,
          type: DownloadType.material,
          lessonTitle: lesson.title,
          sectionTitle: null,
          thumbnailUrl: _course?.thumbnail,
          onSuccess: () {
            if (mounted) setState(() => _courseDownloadDone++);
          },
          onError: (_) {
            if (mounted) setState(() => _courseDownloadFailed++);
          },
        );
      } catch (e) {
        if (mounted) setState(() => _courseDownloadFailed++);
        debugPrint('Course download: material failed for lesson ${lesson.id}: $e');
      }
    }

    if (mounted) {
      setState(() => _isCourseDownloading = false);
      final failed = _courseDownloadFailed;
      final done = _courseDownloadDone;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '$done item${done > 1 ? "s" : ""} downloaded successfully!'
                : '$done downloaded, $failed failed.',
          ),
          backgroundColor: failed == 0 ? _DT.primary : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadCourseData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Content refreshed'),
          backgroundColor: _DT.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DT.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _DT.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: _textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER CARD
// ═════════════════════════════════════════════
class _ChapterCard extends StatelessWidget {
  final Section section;
  final int chapterIndex;
  final List<Lesson> lessons;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isChapterCompleted;
  final Map<String, bool> lessonCompletionStatus;
  final bool isDark;
  final bool isCompact;
  /// Numbered lessons, "next up" highlight and a preview of locked lessons.
  final bool showLessonNumbers;
  final bool isLastChapter;
  /// Shown as an "Up next" button once this chapter is completed.
  final String? nextChapterTitle;
  final VoidCallback? onNextChapter;
  final void Function(Lesson) onLessonTap;
  final VoidCallback onMoreTap;
  final Future<void> Function() onMarkComplete;
  final bool isLoading;

  const _ChapterCard({
    super.key,
    required this.section,
    required this.chapterIndex,
    required this.lessons,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isChapterCompleted,
    required this.lessonCompletionStatus,
    required this.isDark,
    required this.isCompact,
    this.showLessonNumbers = false,
    this.isLastChapter = false,
    this.nextChapterTitle,
    this.onNextChapter,
    required this.onLessonTap,
    required this.onMoreTap,
    required this.onMarkComplete,
    this.isLoading = false,
  });

  int get completedCount =>
      lessons.where((l) => lessonCompletionStatus[l.id] == true).length;

  double get chapterProgress =>
      lessons.isEmpty ? 0.0 : completedCount / lessons.length;

  bool get isFullyCompleted =>
      lessons.isNotEmpty && lessons.every((l) => lessonCompletionStatus[l.id] == true);

  String? get _nextUpLessonId {
    for (final l in lessons) {
      if (lessonCompletionStatus[l.id] != true) return l.id;
    }
    return null;
  }

  Color get _cardBg => isDark ? _DT.cardDark : _DT.card;
  Color get _textPrimary => isDark ? Colors.white : _DT.textPrimary;
  Color get _borderColor => isDark ? _DT.borderDark : _DT.border;
  Color get _surfaceBg => isDark ? _DT.surfaceDk : _DT.surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        border: isChapterCompleted
            ? Border.all(color: _DT.primary, width: 2)
            : isCurrent
                ? Border.all(color: _DT.primary.withOpacity(0.5), width: 1.5)
                : Border.all(color: _borderColor, width: 0.5),
        boxShadow: isChapterCompleted
            ? [
                BoxShadow(
                    color: _DT.primary.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 8)),
              ]
            : _DT.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (!isUnlocked) _buildLockedFooter(),
          if ((isUnlocked || showLessonNumbers) && lessons.isNotEmpty)
            _buildLessonsSection(),
          if (isUnlocked) _buildMarkCompleteFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? _DT.heroGrad
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r8,
                ),
                child: Icon(
                  isUnlocked ? Icons.book_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: isCompact ? 14 : 18,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Text(
                  'Chapter ${chapterIndex + 1}: ${section.title}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13 : 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              // Count badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 7 : 10,
                    vertical: isCompact ? 3 : 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r32,
                ),
                child: Text(
                  '$completedCount/${lessons.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (section.description != null && section.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              section.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Progress bar inside header
          if (isUnlocked && lessons.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8 : 12),
            ClipRRect(
              borderRadius: _DT.r32,
              child: LinearProgressIndicator(
                value: chapterProgress,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonsSection() {
    final displayLessons = isCompact ? _getVisibleLessons() : lessons;
    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 12 : 16, 14, isCompact ? 12 : 16, isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact) ...[
            Row(
              children: [
                Icon(Icons.list_rounded, size: 15, color: _DT.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${lessons.length} ${lessons.length == 1 ? "Lesson" : "Lessons"}'
                  '${showLessonNumbers ? ' · ${lessons.fold<int>(0, (sum, l) => sum + l.duration)} min total' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _DT.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...displayLessons.asMap().entries.map((e) {
            final l = e.value;
            final done = lessonCompletionStatus[l.id] == true;
            return _LessonRow(
              lesson: l,
              isCompleted: done,
              isCompact: isCompact,
              isDark: isDark,
              number: showLessonNumbers ? e.key + 1 : null,
              isNextUp: showLessonNumbers && isUnlocked && l.id == _nextUpLessonId,
              isLocked: !isUnlocked,
              onTap: isUnlocked ? () => onLessonTap(l) : null,
            );
          }),
          if (isCompact && _shouldShowMoreButton())
            GestureDetector(
              onTap: onMoreTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _DT.primary.withOpacity(0.06),
                  borderRadius: _DT.r12,
                  border:
                      Border.all(color: _DT.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '+${_getHiddenLessonCount()} more lessons',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _DT.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Returns the lessons that should be visible based on completion status
  List<Lesson> _getVisibleLessons() {
    if (!isCompact || lessons.isEmpty) return lessons;
    
    List<Lesson> visibleLessons = [];
    
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      
      // Always show the first lesson
      if (i == 0) {
        visibleLessons.add(lesson);
        continue;
      }
      
      // Check if previous lesson is completed
      final previousLesson = lessons[i - 1];
      final isPreviousCompleted = lessonCompletionStatus[previousLesson.id] == true;
      
      if (isPreviousCompleted) {
        visibleLessons.add(lesson);
      } else {
        // Stop at the first incomplete lesson
        break;
      }
    }
    
    return visibleLessons;
  }

  // Determines if the "more lessons" button should be shown
  bool _shouldShowMoreButton() {
    if (!isCompact || lessons.length <= 2) return false;
    
    final visibleLessons = _getVisibleLessons();
    final hiddenCount = lessons.length - visibleLessons.length;
    
    return hiddenCount > 0;
  }

  // Returns the count of hidden lessons
  int _getHiddenLessonCount() {
    if (!isCompact) return 0;
    
    final visibleLessons = _getVisibleLessons();
    return lessons.length - visibleLessons.length;
  }

  Widget _buildLockedFooter() {
    return Container(
      margin: EdgeInsets.all(isCompact ? 10 : 14),
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16, vertical: isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: isDark ? _surfaceBg : Colors.grey.shade100,
        borderRadius: _DT.r12,
        border: Border.all(
            color: isDark ? _borderColor : Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? _cardBg : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: isCompact ? 14 : 16, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter Locked',
                  style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete the previous chapter to unlock this one',
                  style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      color: Colors.grey.shade400),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextChapterButton() {
    final hPad = isCompact ? 10.0 : 14.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, isCompact ? 10 : 14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onNextChapter,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 18, vertical: isCompact ? 10 : 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: _DT.heroGrad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: _DT.r12,
              boxShadow: [
                BoxShadow(
                  color: _DT.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UP NEXT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isCompact ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chapter ${chapterIndex + 2}: ${nextChapterTitle ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: isCompact ? 16 : 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkCompleteFooter() {
    if (isChapterCompleted) {
      final banner = Container(
        margin: EdgeInsets.fromLTRB(isCompact ? 10 : 14, 0, isCompact ? 10 : 14, isCompact ? 10 : 14),
        padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: _DT.primary.withOpacity(0.08),
          borderRadius: _DT.r12,
          border: Border.all(color: _DT.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: _DT.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              isLastChapter ? 'Course Completed!' : 'Chapter Completed!',
              style: TextStyle(
                fontSize: isCompact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: _DT.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '🏆',
              style: TextStyle(fontSize: isCompact ? 13 : 16),
            ),
          ],
        ),
      );
      if (onNextChapter == null) return banner;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          banner,
          _buildNextChapterButton(),
        ],
      );
    }
    // Show "Mark Complete" button when chapter is unlocked but not yet marked complete
    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 10 : 14, 0, isCompact ? 10 : 14, isCompact ? 10 : 14),
      child: GestureDetector(
        onTap: isLoading ? null : () => onMarkComplete(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: isCompact ? 10 : 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: _DT.heroGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: _DT.r12,
            boxShadow: [
              BoxShadow(
                color: _DT.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: isCompact ? 14 : 16,
                  height: isCompact ? 14 : 16,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                    isLastChapter
                        ? Icons.emoji_events_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isCompact ? 14 : 16),
              const SizedBox(width: 8),
              Text(
                isLoading
                    ? (isLastChapter ? 'Completing course...' : 'Unlocking next chapter...')
                    : (isLastChapter
                        ? 'Click here to mark your course complete'
                        : 'Click to continue to next chapter'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isLoading) ...[
                const SizedBox(width: 6),
                Text(
                  '+100 XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  LESSON ROW
// ═════════════════════════════════════════════
class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final bool isCompact;
  final bool isDark;
  final int? number;
  final bool isNextUp;
  final bool isLocked;
  final VoidCallback? onTap;

  const _LessonRow({
    required this.lesson,
    required this.isCompleted,
    required this.isCompact,
    required this.isDark,
    this.number,
    this.isNextUp = false,
    this.isLocked = false,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (lesson.displayType.toLowerCase()) {
      case 'video': return Icons.play_circle_rounded;
      case 'notes': return Icons.description_rounded;
      case 'quiz':  return Icons.quiz_rounded;
      case 'mixed': return Icons.layers_rounded;
      default:      return Icons.article_rounded;
    }
  }

  Color get _typeColor {
    switch (lesson.displayType.toLowerCase()) {
      case 'video': return _DT.primary;
      case 'notes': return _DT.accent;
      case 'quiz':  return const Color(0xFFF59E0B);
      case 'mixed': return const Color(0xFF8B5CF6);
      default:      return _DT.textSecondary;
    }
  }

  Color get _surface => isDark ? _DT.surfaceDk : _DT.surface;
  Color get _border  => isDark ? _DT.borderDark : _DT.border;
  Color get _text    => isDark ? Colors.white : _DT.textPrimary;

  @override
  Widget build(BuildContext context) {
    final row = Container(
        margin: EdgeInsets.only(bottom: isCompact ? 6 : 10),
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        decoration: BoxDecoration(
          color: isCompleted
              ? _DT.primary.withOpacity(0.06)
              : isNextUp
                  ? _DT.primary.withOpacity(0.10)
                  : _surface,
          borderRadius: _DT.r12,
          border: Border.all(
            color: isCompleted || isNextUp
                ? _DT.primary.withOpacity(isNextUp ? 0.6 : 0.3)
                : _border,
            width: isNextUp ? 1.5 : isCompleted ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (number != null) ...[
              SizedBox(
                width: 28,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isNextUp ? _DT.primary : _DT.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              padding: EdgeInsets.all(isCompact ? 5 : 8),
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: _DT.r8,
              ),
              child: Icon(_typeIcon,
                  color: _typeColor, size: isCompact ? 13 : 17),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: _text,
                      height: 1.3,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: _DT.textSecondary,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 4),
                  Text(
                      number != null && lesson.displayType.isNotEmpty
                          ? '${lesson.displayType[0].toUpperCase()}${lesson.displayType.substring(1)} · ${lesson.duration} min'
                          : '${lesson.duration} min',
                      style: TextStyle(
                          fontSize: isCompact ? 10 : 12, color: _DT.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLocked)
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: _DT.textSecondary)
            else if (isCompleted)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: _DT.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 11),
              )
            else if (isNextUp)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: _DT.primary,
                  borderRadius: _DT.r32,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Start',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: _DT.textSecondary),
          ],
        ),
      );

    if (isLocked) return Opacity(opacity: 0.55, child: row);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: row),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER OUTLINE TILE (desktop sidebar)
// ═════════════════════════════════════════════
class _ChapterOutlineTile extends StatelessWidget {
  final int number;
  final String title;
  final int lessonCount;
  final int completedCount;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ChapterOutlineTile({
    required this.number,
    required this.title,
    required this.lessonCount,
    required this.completedCount,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : _DT.textPrimary;
    final progress = lessonCount == 0 ? 0.0 : completedCount / lessonCount;

    final Widget badge;
    if (isCompleted) {
      badge = const CircleAvatar(
        radius: 14,
        backgroundColor: _DT.primary,
        child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    } else if (!isUnlocked) {
      badge = CircleAvatar(
        radius: 14,
        backgroundColor: isDark ? _DT.surfaceDk : _DT.surface,
        child: const Icon(Icons.lock_rounded,
            color: _DT.textSecondary, size: 14),
      );
    } else {
      badge = CircleAvatar(
        radius: 14,
        backgroundColor:
            isSelected ? _DT.primary : _DT.primary.withOpacity(0.15),
        child: Text(
          '$number',
          style: TextStyle(
            color: isSelected ? Colors.white : _DT.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            color: isSelected ? _DT.primary.withOpacity(0.10) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? _DT.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHAPTER $number',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _DT.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isUnlocked
                            ? textColor
                            : textColor.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: _DT.r32,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor:
                                  isDark ? _DT.surfaceDk : _DT.surface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  _DT.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completedCount/$lessonCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _DT.textSecondary,
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
}

// ═════════════════════════════════════════════
//  CHAPTER DETAILS BOTTOM SHEET
// ═════════════════════════════════════════════
class _ChapterDetailsSheet extends StatelessWidget {
  final Section section;
  final int chapterIndex;
  final List<Lesson> lessons;
  final Map<String, bool> lessonCompletionStatus;
  final bool isDark;
  final bool isLoading;
  final void Function(Lesson) onLessonTap;

  const _ChapterDetailsSheet({
    required this.section,
    required this.chapterIndex,
    required this.lessons,
    required this.lessonCompletionStatus,
    required this.isDark,
    required this.onLessonTap,
    this.isLoading = false,
  });

  // Returns the lessons that should be visible based on completion status
  List<Lesson> _getVisibleLessons() {
    if (lessons.isEmpty) return lessons;
    
    List<Lesson> visibleLessons = [];
    
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      
      // Always show the first lesson
      if (i == 0) {
        visibleLessons.add(lesson);
        continue;
      }
      
      // Check if previous lesson is completed
      final previousLesson = lessons[i - 1];
      final isPreviousCompleted = lessonCompletionStatus[previousLesson.id] == true;
      
      if (isPreviousCompleted) {
        visibleLessons.add(lesson);
      } else {
        // Stop at the first incomplete lesson
        break;
      }
    }
    
    return visibleLessons;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : Colors.white;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? _DT.borderDark : _DT.border,
              borderRadius: _DT.r32,
            ),
          ),
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: _DT.heroGrad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: _DT.r16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: _DT.r12),
                  child: const Icon(Icons.book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chapter ${chapterIndex + 1}: ${section.title}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      Text('${lessons.length} ${lessons.length == 1 ? "lesson" : "lessons"}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _DT.primary),
                    SizedBox(height: 16),
                    Text('Loading lessons...',
                        style: TextStyle(color: _DT.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final l = lessons[i];
                  return _LessonRow(
                    lesson: l,
                    isCompleted: lessonCompletionStatus[l.id] == true,
                    isCompact: false,
                    isDark: isDark,
                    onTap: () => onLessonTap(l),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER MATERIALS CARD
// ═════════════════════════════════════════════
class _ChapterMaterialsCard extends StatelessWidget {
  final Section section;
  final List<Map<String, dynamic>> materials;
  final int chapterIndex;
  final List<Lesson> lessons;
  final Map<String, bool> lessonCompletionStatus;
  final bool isDark;
  final void Function(Map<String, dynamic>) onTap;

  const _ChapterMaterialsCard({
    required this.section,
    required this.materials,
    required this.chapterIndex,
    required this.lessons,
    required this.lessonCompletionStatus,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : Colors.white;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final border = isDark ? _DT.borderDark : _DT.border;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Progress for this chapter only — a material always belongs to one chapter
    final doneCount =
        lessons.where((l) => lessonCompletionStatus[l.id] == true).length;
    final progress = lessons.isEmpty ? 0.0 : doneCount / lessons.length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _DT.r20,
        border: Border.all(color: border, width: 0.5),
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _DT.primary,
                    borderRadius: _DT.r32,
                  ),
                  child: Text(
                    'Ch. ${chapterIndex + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Chapter ${chapterIndex + 1}: ${section.title}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${materials.length} items',
                    style: TextStyle(
                        fontSize: 12, color: _DT.textSecondary)),
              ],
            ),
          ),
          // Chapter progress — updates as lessons in this chapter complete
          if (lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor:
                            isDark ? _DT.borderDark : _DT.border,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_DT.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$doneCount/${lessons.length} lessons',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _DT.textSecondary)),
                ],
              ),
            ),
          // Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isDesktop ? 1.8 : 1.5,
              children: materials
                  .map((m) => _MaterialTile(
                        material: m,
                        isDark: isDark,
                        isCompleted:
                            lessonCompletionStatus[m['lessonId']] == true,
                        onTap: () => onTap(m),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isDark;
  final bool isCompleted;
  final VoidCallback onTap;

  const _MaterialTile(
      {required this.material,
      required this.isDark,
      this.isCompleted = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color c = material['color'] as Color;
    final bg = isDark ? _DT.surfaceDk : _DT.surface;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: _DT.r12,
          border: Border.all(color: c.withOpacity(0.25), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: _DT.r8),
                  child:
                      Icon(material['icon'] as IconData, color: c, size: 14),
                ),
                const Spacer(),
                if (isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle_rounded,
                        color: _DT.primary, size: 14),
                  ),
                if (material['duration'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: _DT.r4),
                    child: Text('${material["duration"]}m',
                        style: TextStyle(
                            color: c,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              material['title'] as String,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              material['subtitle'] as String? ?? '',
              style:
                  const TextStyle(fontSize: 9, color: _DT.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ═════════════════════════════════════════════
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final Color cardBg;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    this.active = false,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? _DT.primary : cardBg,
          borderRadius: _DT.r12,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon,
            size: 18,
            color: active
                ? Colors.white
                : (isDark ? Colors.white : _DT.textPrimary)),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _ProgressStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _ProgressStatRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: _DT.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _DT.textPrimary)),
      ],
    );
  }
}

class _ChapterProgressRow extends StatelessWidget {
  final int index;
  final String title;
  final int done;
  final int total;
  final double pct;
  final bool isCompleted;
  final bool isDark;
  final bool isLast;

  const _ChapterProgressRow({
    required this.index,
    required this.title,
    required this.done,
    required this.total,
    required this.pct,
    required this.isCompleted,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final border = isDark ? _DT.borderDark : _DT.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: border, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _DT.primary
                  : _DT.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : Text('$index',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _DT.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: _DT.r32,
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor:
                              _DT.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? _DT.primary
                                  : _DT.primary.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$done/$total',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _DT.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;
  final Color color;
  final int xp;
  const _Achievement(
      {required this.title,
      required this.desc,
      required this.icon,
      required this.unlocked,
      required this.color,
      this.xp = 0});
}

class _BookmarkedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemoveBookmark;

  const _BookmarkedLessonCard({
    required this.lesson,
    required this.isDark,
    required this.onTap,
    required this.onRemoveBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : _DT.card;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final textSecondary = isDark ? _DT.textLight : _DT.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _DT.r16,
        border: Border.all(
          color: isDark ? _DT.borderDark : _DT.border,
          width: 0.5,
        ),
        boxShadow: _DT.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: _DT.r16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Lesson icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DT.primary.withOpacity(0.1),
                  borderRadius: _DT.r12,
                ),
                child: Icon(
                  lesson.hasVideo ? Icons.play_circle_rounded : Icons.article_rounded,
                  color: _DT.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (lesson.duration > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Remove bookmark button
              IconButton(
                icon: const Icon(Icons.bookmark),
                color: _DT.primary,
                onPressed: onRemoveBookmark,
                tooltip: 'Remove bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final _Achievement a;
  final bool isDark;
  const _AchievementCard({required this.a, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.surfaceDk : _DT.surface;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: a.unlocked ? a.color.withOpacity(0.09) : bg,
            borderRadius: _DT.r16,
            border: Border.all(
              color: a.unlocked
                  ? a.color.withOpacity(0.35)
                  : (isDark ? _DT.borderDark : _DT.border),
              width: a.unlocked ? 1.5 : 0.5,
            ),
            boxShadow: a.unlocked
                ? [BoxShadow(color: a.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: a.unlocked ? a.color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon,
                        color: a.unlocked ? a.color : _DT.textHint,
                        size: 20),
                  ),
                  if (!a.unlocked)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: _DT.textSecondary, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 7),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(a.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: a.unlocked ? a.color : _DT.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(a.desc,
                  style: TextStyle(
                      fontSize: 9,
                      color: a.unlocked
                          ? a.color.withOpacity(0.75)
                          : _DT.textHint),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (a.xp > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: a.unlocked ? a.color : Colors.grey.shade300,
                borderRadius: _DT.r32,
              ),
              child: Text(
                '+${a.xp} XP',
                style: TextStyle(
                  color: a.unlocked ? Colors.white : Colors.grey.shade500,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER COMPLETION DIALOG
// ═════════════════════════════════════════════
class _ChapterCompletionDialog extends StatefulWidget {
  final String chapterName;
  final int chapterNumber;
  final int xpEarned;
  final int totalXp;
  final int lessonCount;
  final bool isLastChapter;
  final String? nextChapterName;
  final double overallProgress;
  final bool isDark;
  final VoidCallback onContinue;
  final VoidCallback onClose;

  const _ChapterCompletionDialog({
    required this.chapterName,
    required this.chapterNumber,
    required this.xpEarned,
    required this.totalXp,
    required this.lessonCount,
    required this.isLastChapter,
    required this.nextChapterName,
    required this.overallProgress,
    required this.isDark,
    required this.onContinue,
    required this.onClose,
  });

  @override
  State<_ChapterCompletionDialog> createState() => _ChapterCompletionDialogState();
}

class _ChapterCompletionDialogState extends State<_ChapterCompletionDialog>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _trophyScale;
  late final Animation<double> _progressAnim;
  late final Animation<int> _xpCount;

  static const _gold = [Color(0xFFFFB300), Color(0xFFFF6F00)];

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _trophyScale = CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.1, 0.8, curve: Curves.elasticOut));
    _xpCount = IntTween(begin: 0, end: widget.xpEarned).animate(CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(
            begin: 0, end: widget.overallProgress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _progressCtrl.forward();
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  /// "Chapter 2: Key Features" -> "Key Features"; the number is shown apart.
  String get _chapterTitle {
    final name = widget.chapterName;
    final i = name.indexOf(': ');
    return i >= 0 ? name.substring(i + 2) : name;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 480;
    final pad = compact ? 20.0 : 28.0;
    final isCourse = widget.isLastChapter;
    final headerGrad = isCourse ? _gold : _DT.heroGrad;
    final bg = widget.isDark ? _DT.cardDark : Colors.white;
    final textPrimary = widget.isDark ? Colors.white : _DT.textPrimary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: size.height - 48,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: _DT.r24,
                border: Border.all(
                    color: headerGrad.first.withOpacity(0.35), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: headerGrad.first.withOpacity(0.25),
                      blurRadius: 60,
                      spreadRadius: -8),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 20)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(headerGrad, isCourse, compact),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 22, pad, pad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _buildXpPill()),
                          const SizedBox(height: 22),
                          _buildStats(compact),
                          const SizedBox(height: 22),
                          _buildProgress(textPrimary),
                          const SizedBox(height: 20),
                          if (!isCourse && widget.nextChapterName != null) ...[
                            _buildUpNext(textPrimary),
                            const SizedBox(height: 20),
                          ],
                          _buildActions(isCourse, compact),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Color> grad, bool isCourse, bool compact) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative sparkles
          ..._sparkles(),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, compact ? 28 : 34, 24, compact ? 24 : 28),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _trophyScale,
                  child: Container(
                    width: compact ? 78 : 92,
                    height: compact ? 78 : 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.55), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.35),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(isCourse ? '🎓' : '🏆',
                          style: TextStyle(fontSize: compact ? 38 : 46)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: _DT.r32,
                  ),
                  child: Text(
                    isCourse
                        ? 'COURSE COMPLETE'
                        : 'CHAPTER ${widget.chapterNumber} COMPLETE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isCourse ? 'You did it! 🎉' : 'Great work!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _chapterTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sparkles() {
    const spots = [
      (left: 0.08, top: 0.18, size: 18.0, o: 0.55),
      (left: 0.20, top: 0.62, size: 12.0, o: 0.40),
      (left: 0.30, top: 0.10, size: 10.0, o: 0.35),
      (left: 0.72, top: 0.14, size: 12.0, o: 0.45),
      (left: 0.84, top: 0.55, size: 20.0, o: 0.50),
      (left: 0.66, top: 0.78, size: 10.0, o: 0.35),
    ];
    return [
      for (final s in spots)
        Positioned.fill(
          child: Align(
            alignment: Alignment(s.left * 2 - 1, s.top * 2 - 1),
            child: FadeTransition(
              opacity: _introCtrl,
              child: Icon(Icons.auto_awesome,
                  size: s.size, color: Colors.white.withOpacity(s.o)),
            ),
          ),
        ),
    ];
  }

  Widget _buildXpPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _DT.purpleGrad),
        borderRadius: _DT.r32,
        boxShadow: [
          BoxShadow(
              color: _DT.accent.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 22),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _xpCount,
            builder: (_, __) => Text(
              '+${_xpCount.value} XP earned',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool compact) {
    final gap = compact ? 8.0 : 12.0;
    return Row(
      children: [
        _DialogStat(
          icon: Icons.task_alt_rounded,
          value: '${widget.lessonCount}',
          label: widget.lessonCount == 1 ? 'Lesson' : 'Lessons',
          color: _DT.primary,
          isDark: widget.isDark,
        ),
        SizedBox(width: gap),
        _DialogStat(
          icon: Icons.bolt_rounded,
          value: '${widget.totalXp}',
          label: 'Total XP',
          color: _DT.accent,
          isDark: widget.isDark,
        ),
        SizedBox(width: gap),
        _DialogStat(
          icon: Icons.donut_large_rounded,
          value: '${(widget.overallProgress.clamp(0.0, 1.0) * 100).round()}%',
          label: 'Course done',
          color: const Color(0xFF00ACC1),
          isDark: widget.isDark,
        ),
      ],
    );
  }

  Widget _buildProgress(Color textPrimary) {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        final v = _progressAnim.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Course progress',
                    style: TextStyle(
                        fontSize: 13,
                        color: textPrimary.withOpacity(0.75),
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(v * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 13,
                        color: _DT.primary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: _DT.primary.withOpacity(0.12),
                borderRadius: _DT.r32,
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _DT.heroGrad),
                    borderRadius: _DT.r32,
                    boxShadow: [
                      BoxShadow(
                          color: _DT.primary.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpNext(Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DT.primary.withOpacity(0.08),
        borderRadius: _DT.r16,
        border: Border.all(color: _DT.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _DT.primary.withOpacity(0.18),
              borderRadius: _DT.r12,
            ),
            child: const Icon(Icons.lock_open_rounded,
                color: _DT.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UP NEXT · UNLOCKED',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: _DT.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.nextChapterName!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isCourse, bool compact) {
    final nextNumber = widget.chapterNumber + 1;
    final primary = ElevatedButton.icon(
      onPressed: widget.onContinue,
      icon: Icon(isCourse ? Icons.insights_rounded : Icons.arrow_forward_rounded,
          size: 20),
      label: Text(
        isCourse ? 'View my progress' : 'Continue to Chapter $nextNumber',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCourse ? _gold.last : _DT.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
    final secondary = OutlinedButton(
      onPressed: widget.onClose,
      style: OutlinedButton.styleFrom(
        foregroundColor: _DT.textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        side: BorderSide(
            color: widget.isDark ? _DT.borderDark : _DT.border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Stay here',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );

    // Phones stack the buttons; wider screens put them side by side.
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [primary, const SizedBox(height: 10), secondary],
      );
    }
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: primary),
      ],
    );
  }
}

class _DialogStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  const _DialogStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.14), color.withOpacity(0.04)],
          ),
          borderRadius: _DT.r16,
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : _DT.textPrimary)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _PaymentDetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final textSecondary = _DT.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}