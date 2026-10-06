import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/video.dart';
import 'package:excellencecoachinghub/data/repositories/lesson_repository.dart';
import 'package:excellencecoachinghub/data/repositories/video_repository.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/optimized_video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/services/api/video_api_service.dart';
import 'package:excellencecoachinghub/services/api/enrollment_service.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';
import 'package:excellencecoachinghub/services/achievement_sound_service.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/ai_study_guide.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _T {
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const greenMid = Color(0xFF86EFAC);
  static const greenDark = Color(0xFF14532D);
  static const orange = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFEF3C7);
  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFFEFF6FF);
  static const purple = Color(0xFF4F46E5);
  static const purpleLight = Color(0xFFF5F3FF);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF8FAF9);
  static const border = Color(0xFFE5E7EB);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const subtle = Color(0xFF9CA3AF);

  // Dark mode equivalents
  static const darkBg = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF1F5F9);
  static const darkMuted = Color(0xFF94A3B8);
}

enum _NotesView { guide, pdf, text }
enum _Tab { video, notes, quiz, feedback, ai }

class ProfessionalLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final bool isAdminPreview;

  /// Tab to open on: 'video', 'notes', 'quiz', 'feedback' or 'ai'.
  /// Ignored when the lesson has no content of that kind.
  final String? initialTab;

  /// AI Course Builder draft to show exactly as students will see it once
  /// published. Nothing (progress, feedback, quiz attempts) is saved.
  final String? draftItemId;

  const ProfessionalLessonScreen({
    super.key,
    required this.lessonId,
    this.isAdminPreview = false,
    this.initialTab,
    this.draftItemId,
  });

  @override
  ConsumerState<ProfessionalLessonScreen> createState() =>
      _ProfessionalLessonScreenState();
}

class _ProfessionalLessonScreenState
    extends ConsumerState<ProfessionalLessonScreen>
    with TickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────────
  Lesson? _lesson;
  Video? _video;
  Map<String, dynamic>? _exam;
  bool _isLoading = true;
  bool _isCompletingLesson = false;
  bool _isLessonCompleted = false;
  List<Map<String, dynamic>> _quizAttempts = [];
  bool _isLoadingQuizAttempts = false;
  
  // ── Certificate state ─────────────────────────────────────────────────────
  List<Certificate> _certificates = [];
  bool _isLoadingCertificates = false;
  bool _justCompletedFinalExam = false;

  // ── Navigation ────────────────────────────────────────────────────────────
  Lesson? _previousLesson;
  Lesson? _nextLesson;
  int _currentLessonIndex = 0;
  int _totalLessonsInSection = 0;

  // ── UI state ──────────────────────────────────────────────────────────────
  _Tab _activeTab = _Tab.video;
  _NotesView _notesTab = _NotesView.pdf;
  bool _isChatOpen = false;
  String? _chatPrompt; // question handed to the AI tutor from the study guide
  bool _sidebarCollapsed = false;
  double _downloadProgress = 0.0;

  AppLocalizations? get l10n => AppLocalizations.of(context);
  bool _isDownloading = false;
  bool _isBookmarked = false;
  String? _currentDownloadLessonId; // Track which lesson is being downloaded
  
  // ── Feedback state ───────────────────────────────────────────────────────────
  double _userRating = 0.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;
  bool _hasSubmittedFeedback = false;
  bool _isLoadingFeedback = false;
  List<Map<String, dynamic>> _courseFeedback = [];

  // ── Services ──────────────────────────────────────────────────────────────
  final GlobalKey<StudentGuideWidgetState> _guideKey = GlobalKey<StudentGuideWidgetState>();
  final GlobalKey<StudentGuideWidgetState> _aiTabGuideKey = GlobalKey<StudentGuideWidgetState>();
  final RealAIChatService _aiChatService = RealAIChatService();
  final String _conversationId =
      'conversation_${DateTime.now().millisecondsSinceEpoch}';

  // ── Checklist ─────────────────────────────────────────────────────────────
  final Map<String, bool> _checklist = {
    'video': false,
    'notes': false,
    'quiz': false,
    'complete': false,
  };

  // ── Screen wakelock ───────────────────────────────────────────────────────
  // Held for the whole lesson: the notes and PDF tabs are read for minutes at a
  // time without a tap, and the video player keeps its own handle on top
  final ScreenWakelock _wakelock = ScreenWakelock();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _wakelock.acquire();
    _loadLessonData();
    // Listen to download service changes
    final downloadService = ref.read(downloadServiceProvider);
    downloadService.addListener(_onDownloadsChanged);
  }

  @override
  void dispose() {
    _wakelock.release();
    final downloadService = ref.read(downloadServiceProvider);
    downloadService.removeListener(_onDownloadsChanged);
    _feedbackController.dispose();
    super.dispose();
  }

  void _onDownloadsChanged() {
    if (mounted) {
      // Sync UI state with download service state
      final downloadService = ref.read(downloadServiceProvider);
      if (_lesson != null) {
        final download = downloadService.getDownloadStatus(_lesson!.id);
        if (download != null) {
          setState(() {
            _isDownloading = download.isDownloading;
            _downloadProgress = download.downloadProgress;
            // Clear current download lesson ID if not downloading
            if (!download.isDownloading) {
              _currentDownloadLessonId = null;
            }
          });
        }
      }
    }
  }

  // Helper method to display appropriate progress text
  String _getProgressText() {
    if (_downloadProgress < 0) {
      return 'Downloading...';
    } else if (_downloadProgress >= 1.0) {
      return 'Complete!';
    } else {
      return '${(_downloadProgress.isFinite ? (_downloadProgress * 100).clamp(0, 100) : 0).toInt()}%';
    }

  }

  bool get _isDraftPreview => widget.draftItemId != null;

  /// Loads an AI draft shaped like a published lesson (see /course-builder/items/:id/preview).
  Future<void> _loadDraftPreview() async {
    try {
      final data = await CourseBuilderService().previewItem(widget.draftItemId!);
      final lesson = Lesson.fromJson(Map<String, dynamic>.from(data['lesson']));
      final siblings = ((data['siblings'] as List?) ?? [])
          .map((s) => Lesson(
                id: s['_id'].toString(),
                sectionId: lesson.sectionId,
                courseId: lesson.courseId,
                title: s['title']?.toString() ?? '',
                order: 0,
                duration: 0,
              ))
          .toList();
      final index = siblings.indexWhere((l) => l.id == lesson.id);
      setState(() {
        _lesson = lesson;
        _notesTab = lesson.hasAiGuide ? _NotesView.guide : _NotesView.pdf;
        _exam = data['quiz'] is Map ? Map<String, dynamic>.from(data['quiz']) : null;
        _previousLesson = index > 0 ? siblings[index - 1] : null;
        _nextLesson = index >= 0 && index < siblings.length - 1 ? siblings[index + 1] : null;
        _currentLessonIndex = index + 1;
        _totalLessonsInSection = siblings.length;
        _activeTab = _resolveInitialTab(lesson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnack('Could not load the draft preview: $e', isError: true);
    }
  }

  void _previewOnly() => _showSnack('Preview mode — nothing is saved until the lesson is published');

  Future<void> _loadLessonData() async {
    setState(() => _isLoading = true);
    if (_isDraftPreview) return _loadDraftPreview();
    try {
      final lessonRepo = LessonRepository();
      final lesson = await lessonRepo.getLessonById(widget.lessonId);
      if (lesson == null) throw Exception('Lesson not found');

      Video? video;
      if (lesson.hasVideo && lesson.videoId != null) {
        final videoRepo = VideoRepository();
        video = await videoRepo.getVideoById(lesson.videoId!);
      }

      Map<String, dynamic>? exam;
      if (lesson.hasQuiz && lesson.quizId != null && lesson.quizId != lesson.id) {
        try {
          final quizData = await QuizService.getQuiz(lesson.quizId!);
          print('=== QUIZ DATA DEBUG ===');
          print('Quiz data: $quizData');
          exam = quizData['data']['quiz'] as Map<String, dynamic>?;
          exam ??= quizData['data'] as Map<String, dynamic>?;
          print('Extracted exam data: $exam');
        } catch (e) {
          print('Warning: Failed to load quiz for lesson: $e');
          // Continue without quiz if it fails
        }
      }

      final allLessons = await lessonRepo.getLessonsBySection(lesson.sectionId);
      Lesson? prev, next;
      for (int i = 0; i < allLessons.length; i++) {
        if (allLessons[i].id == lesson.id) {
          if (i > 0) prev = allLessons[i - 1];
          if (i < allLessons.length - 1) next = allLessons[i + 1];
          break;
        }
      }

      setState(() {
        _lesson = lesson;
        _notesTab = lesson.hasAiGuide ? _NotesView.guide : _NotesView.pdf;
        _video = video;
        _exam = exam;
        _previousLesson = prev;
        _nextLesson = next;
        _currentLessonIndex =
            allLessons.indexWhere((l) => l.id == lesson.id) + 1;
        _totalLessonsInSection = allLessons.length;
        
        // Set initial tab from the caller's request, falling back to whatever
        // content the lesson actually has
        _activeTab = _resolveInitialTab(lesson);

        _isLoading = false;
      });
      
      // Load bookmark status, course feedback, quiz attempts, certificates, and sync download state
      await _loadBookmarkStatus();
      await _loadCourseFeedback();
      if (lesson.hasQuiz && lesson.quizId != null) {
        await _loadQuizAttempts();
      }
      await _loadCertificates();
      
      // Sync with download service state
      final downloadService = ref.read(downloadServiceProvider);
      final download = downloadService.getDownloadStatus(lesson.id);
      if (download != null) {
        setState(() {
          _isDownloading = download.isDownloading;
          _downloadProgress = download.downloadProgress;
          if (download.isDownloading) {
            _currentDownloadLessonId = lesson.id;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack('Error loading lesson: $e', isError: true);
      }
    }
  }

  /// Picks the tab to land on. A requested tab (e.g. the student tapped a
  /// notes card in the Lessons tab) wins whenever the lesson has that
  /// content; otherwise fall back to the lesson's own content.
  _Tab _resolveInitialTab(Lesson lesson) {
    switch (widget.initialTab?.toLowerCase()) {
      case 'notes':
        if (lesson.hasNotes) return _Tab.notes;
        break;
      case 'video':
        if (lesson.hasVideo) return _Tab.video;
        break;
      case 'quiz':
        if (lesson.hasQuiz) return _Tab.quiz;
        break;
      case 'feedback':
        return _Tab.feedback;
      case 'ai':
        return _Tab.ai;
    }

    // No usable request — open whatever the lesson actually contains
    if (lesson.hasVideo) return _Tab.video;
    if (lesson.hasNotes) return _Tab.notes;
    if (lesson.hasQuiz) return _Tab.quiz;
    return _Tab.video;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quiz attempts
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadQuizAttempts() async {
    if (_lesson?.quizId == null) return;
    
    setState(() => _isLoadingQuizAttempts = true);
    try {
      final attempts = await QuizService.getStudentQuizAttempts(_lesson!.quizId!);
      if (mounted) {
        setState(() {
          _quizAttempts = attempts;
          _isLoadingQuizAttempts = false;
        });
      }
    } catch (e) {
      print('Error loading quiz attempts: $e');
      if (mounted) {
        setState(() => _isLoadingQuizAttempts = false);
      }
    }
  }

  // Certificates
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadCertificates() async {
    if (_lesson?.courseId == null) return;
    
    setState(() => _isLoadingCertificates = true);
    try {
      final certificateRepo = CertificateRepository();
      final certificates = await certificateRepo.getCertificatesByCourse(_lesson!.courseId);
      
      print('=== CERTIFICATES DEBUG ===');
      print('Course ID: ${_lesson!.courseId}');
      print('Certificates found: ${certificates.length}');
      for (var cert in certificates) {
        print('Certificate: ${cert.id}, Course: ${cert.courseId}, Valid: ${cert.isValid}');
      }
      print('========================');
      
      if (mounted) {
        setState(() {
          _certificates = certificates;
          _isLoadingCertificates = false;
        });
      }
    } catch (e) {
      print('Error loading certificates: $e');
      if (mounted) {
        setState(() => _isLoadingCertificates = false);
      }
    }
  }

  Widget _buildCertificateStatus() {
    // Check if user has earned a certificate for this course
    final hasCertificate = _certificates.any((cert) => 
        cert.courseId == _lesson?.courseId && 
        cert.isValid);
    
    // Check if user has passed the quiz but certificate might not be generated yet
    final hasPassedQuiz = _quizAttempts.any((attempt) {
      final score = attempt['score'] as num? ?? 0;
      final passingScore = _exam?['passingScore'] as num? ?? 70;
      return score >= passingScore;
    });
    
    if (hasCertificate) {
      final certificate = _certificates.firstWhere((cert) => 
          cert.courseId == _lesson?.courseId && 
          cert.isValid);
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, 
                    color: const Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certificate Earned! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${certificate.score.toStringAsFixed(1)}% • Issued: ${_formatDate(certificate.issuedDate.toIso8601String())}',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCertificate(certificate),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text(
                      'View Certificate',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadCertificate(certificate),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text(
                      'Download',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (hasPassedQuiz) {
      // User has passed quiz but certificate is being generated
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0EA5E9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top, 
                    color: const Color(0xFF0EA5E9), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certificate Processing... 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0C4A6E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! You passed the final exam. Your certificate is being generated and will appear shortly.',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF0C4A6E),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton.icon(
                onPressed: () {
                  _loadCertificates(); // Refresh certificates
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text(
                  'Check Again',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // No certificate earned yet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD700)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined, 
                color: const Color(0xFF856404), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Certificate Available! Pass this final exam to earn your completion certificate.',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF856404),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _viewCertificate(Certificate certificate) async {
    _openCertificates();
  }

  /// `/certificates` lives inside the MainLayout ShellRoute while this screen
  /// sits above the shell, so `context.push` would add a second shell page
  /// with the same page key and trip Navigator's duplicate-key assertion.
  /// Pushing the screen directly keeps the lesson underneath it.
  void _openCertificates() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CertificatesScreen()),
    );
  }

  Future<void> _generateCertificateManually() async {
    try {
      _showSnack('Generating certificate...', isError: false);
      
      // Call certificate generation API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/enrollments/generate-certificate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'courseId': _lesson!.courseId,
          'examId': _lesson!.quizId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnack('Certificate generated successfully!');
        // Refresh certificates
        await _loadCertificates();
      } else {
        _showSnack('Failed to generate certificate', isError: true);
      }
    } catch (e) {
      _showSnack('Error generating certificate: $e', isError: true);
    }
  }

  Future<String> _getAuthToken() async {
    // Get the current Firebase user
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    
    // Get the Firebase ID token
    final idToken = await user.getIdToken();
    return idToken ?? '';
  }

  Future<void> _downloadCertificate(Certificate certificate) async {
    try {
      final certificateRepo = CertificateRepository();
      final savePath = await certificateRepo.downloadAndSaveCertificate(
        certificate.id,
        fileName: 'certificate_${certificate.id}.pdf',
      );
      
      if (savePath != null) {
        _showSnack('Certificate saved to: $savePath');
      }
    } catch (e) {
      _showSnack('Error downloading certificate: $e', isError: true);
    }
  }

  void _showQuizInstructions() {
    final quizTitle = _exam?['title'] ?? 'Lesson Quiz';
    final quizType = _exam?['type'] ?? _lesson?.lessonType ?? 'Quiz';
    final quizInstructions = _exam?['instructions'] ?? 'Test your understanding of this lesson';
    final isFinalExam = (quizType.toLowerCase().contains('final') || 
                         (_exam?['isFinal'] == true) || 
                         (_lesson?.lessonType?.toLowerCase().contains('final') == true));
    final passingScore = _exam?['passingScore'] ?? 70;
    final timeLimit = _exam?['timeLimit'] ?? 30; // in minutes
    final totalQuestions = _exam?['totalQuestions'] ?? 'Unknown';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.quiz_outlined, color: _T.green, size: 24),
              const SizedBox(width: 12),
              Text(l10n?.quizInstructions ?? 'Quiz Instructions'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _T.greenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quizType,
                    style: TextStyle(
                      color: _T.greenDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isFinalExam) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium_outlined, 
                            color: const Color(0xFF856404), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Final Exam - Certificate Available upon passing!',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF856404),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Quiz Details:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  ('Questions', totalQuestions.toString()),
                  ('Time Limit', '$timeLimit minutes'),
                  ('Passing Score', '$passingScore%'),
                ].map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, 
                          color: _T.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${detail.$1}: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
                        ),
                      ),
                      Text(
                        detail.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _T.green,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quizInstructions,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.blueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, 
                              color: _T.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Important Tips:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _T.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'Read each question carefully before answering',
                        'Manage your time wisely',
                        'Review your answers before submitting',
                        if (isFinalExam) 
                          'Certificate already earned - cannot retake'
                        else 
                          'You can retake quiz if needed',
                        'Security related: Do not share your screen or answers',
                        'Security related: Ensure you are in a quiet environment',
                        'Security related: Use only your own knowledge and resources',
                      ].map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 28),
                        child: Text(
                          '• $tip',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textColor,
                            height: 1.4,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startQuiz();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _getQuizButtonText(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quiz-only lesson helpers
  // ─────────────────────────────────────────────────────────────────────────

  bool _isQuizOnlyLesson() {
    return _lesson?.hasQuiz == true && 
           _lesson?.hasVideo != true && 
           _lesson?.hasNotes != true;
  }

  void _showQuizOnlyNotification() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.quiz_outlined, color: _T.green, size: 24),
              const SizedBox(width: 12),
              Text(l10n?.quizOnlyLesson ?? 'Quiz-Only Lesson'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This lesson contains only a quiz. To complete the quiz, please stay on the Quiz tab.',
                style: TextStyle(fontSize: 14, color: _textColor),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.greenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.greenMid),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _T.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can access other lesson features after completing the quiz.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _T.greenDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: _T.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _T.green,
    ));
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _extractVideoUrl() {
    if (_lesson!.videoUrl?.isNotEmpty == true) return _lesson!.videoUrl!;
    if (_video?.url?.isNotEmpty == true) return _video!.url!;
    if (_lesson!.videoId?.isNotEmpty == true) {
      if (_lesson!.videoId!.startsWith('http')) return _lesson!.videoId!;
      return 'https://d3ofk5ujo941v.cloudfront.net/${_lesson!.videoId}';
    }
    return '';
  }

  double get _progress =>
      _totalLessonsInSection > 0
          ? _currentLessonIndex / _totalLessonsInSection
          : 0.0;

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _surfaceColor => _isDark ? _T.darkSurface : _T.surface;
  Color get _bgColor => _isDark ? _T.darkBg : _T.bg;
  Color get _borderColor => _isDark ? _T.darkBorder : _T.border;
  Color get _textColor => _isDark ? _T.darkText : _T.text;
  Color get _mutedColor => _isDark ? _T.darkMuted : _T.muted;

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_lesson == null) return _buildNotFoundScreen();

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final body = isDesktop ? _buildDesktop() : _buildMobile();
    return Scaffold(
      backgroundColor: _bgColor,
      body: _isDraftPreview ? Column(children: [_buildDraftBanner(), Expanded(child: body)]) : body,
    );
  }

  Widget _buildDraftBanner() {
    return Material(
      color: const Color(0xFF4F46E5),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Student view preview — this AI draft is not published yet. Nothing you do here is saved.',
                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              label: const Text('Exit preview', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Loading / error ───────────────────────────────────────────────────────

  Widget _buildLoadingScreen() => Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _T.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: _T.green,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 12),
              Text('Loading lesson…',
                  style: TextStyle(color: _T.muted, fontSize: 14)),
            ],
          ),
        ),
      );

  Widget _buildNotFoundScreen() => Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 56, color: _T.subtle),
              const SizedBox(height: 16),
              Text('Lesson not found',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textColor)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(color: _T.green)),
              ),
            ],
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDesktop() {
    return Row(
      children: [
        // Sidebar
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _sidebarCollapsed ? 0 : 260,
          child: _sidebarCollapsed ? const SizedBox() : _buildSidebar(),
        ),
        // Main
        Expanded(
          child: Column(
            children: [
              _buildDesktopTopbar(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
              _buildDesktopFooter(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F1A24) : Colors.white,
        border: Border(
          right: BorderSide(
            color: _isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE7ECEF),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarBrand(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSidebarSection('Navigation', [
                    _SidebarItem(Icons.home_rounded, 'Home', false,
                        () => context.pop()),
                    _SidebarItem(Icons.play_circle_outline, 'Video',
                        _activeTab == _Tab.video,
                        () {
                          if (_isQuizOnlyLesson() && _activeTab == _Tab.quiz) {
                            _showQuizOnlyNotification();
                          } else {
                            setState(() => _activeTab = _Tab.video);
                          }
                        }, color: _T.blue),
                    _SidebarItem(Icons.description_outlined, 'Notes',
                        _activeTab == _Tab.notes,
                        () {
                          if (_isQuizOnlyLesson() && _activeTab == _Tab.quiz) {
                            _showQuizOnlyNotification();
                          } else {
                            _setActiveTab(_Tab.notes);
                          }
                        }, color: const Color(0xFF0D9488)),
                    _SidebarItem(Icons.quiz_outlined, 'Quiz',
                        _activeTab == _Tab.quiz,
                        () => setState(() => _activeTab = _Tab.quiz),
                        color: _T.orange),
                    _SidebarItem(Icons.rate_review_outlined, 'Feedback',
                        _activeTab == _Tab.feedback,
                        () {
                          if (_isQuizOnlyLesson() && _activeTab == _Tab.quiz) {
                            _showQuizOnlyNotification();
                          } else {
                            setState(() => _activeTab = _Tab.feedback);
                          }
                        }, color: const Color(0xFFE11D48)),
                    _SidebarItem(Icons.psychology_outlined, 'AI Help',
                        _activeTab == _Tab.ai,
                        () {
                          if (_isQuizOnlyLesson() && _activeTab == _Tab.quiz) {
                            _showQuizOnlyNotification();
                          } else {
                            setState(() => _activeTab = _Tab.ai);
                          }
                        }, color: const Color(0xFF7C3AED)),
                  ]),
                  _buildSidebarSection('This section', [
                    _SidebarLesson('Introduction', true, false),
                    _SidebarLesson(
                        _lesson?.title ?? 'Current lesson', false, true),
                    _SidebarLesson('Advanced topics', false, false,
                        locked: true),
                  ]),
                ],
              ),
            ),
          ),
          _buildSidebarProgress(),
        ],
      ),
    );
  }

  // Mirrors the header card of the app's main sidebar
  // (ResponsiveNavigationDrawer) so the lesson page carries the same brand.
  Widget _buildSidebarBrand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A6A4B), Color(0xFF0F7A56), Color(0xFF0B6347)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, color: _T.green),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.appName ?? 'Excellence Coaching Hub',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n?.drawerTagline ??
                            'Learn • Grow • Build Your Future',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _sidebarCollapsed = true),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 22),
                  tooltip: 'Collapse sidebar',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSection(
      String label, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 16, 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF5B7083),
                letterSpacing: 1.6),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSidebarProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: _borderColor))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    backgroundColor: _borderColor,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_T.green),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _T.green),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep it up!',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textColor)),
                Text(
                  '$_currentLessonIndex of $_totalLessonsInSection lessons',
                  style: TextStyle(fontSize: 11, color: _mutedColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop topbar ────────────────────────────────────────────────────────

  Widget _buildDesktopTopbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          if (_sidebarCollapsed)
            _TopbarIconBtn(
              Icons.menu,
              _mutedColor,
              () => setState(() => _sidebarCollapsed = false),
            ),
          _TopbarPillBtn(
            Icons.arrow_back_ios_new,
            'Back',
            _bgColor,
            _borderColor,
            _mutedColor,
            () => context.pop(),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _T.greenLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Lesson $_currentLessonIndex of $_totalLessonsInSection',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _T.greenDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lesson?.title ?? '',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _TopbarPillBtn(
            Icons.psychology_outlined,
            'Ask AI',
            _bgColor,
            _borderColor,
            _mutedColor,
            () => setState(() => _activeTab = _Tab.ai),
          ),
          const SizedBox(width: 8),
          _CompleteButton(
            isCompleted: _isLessonCompleted,
            isLoading: _isCompletingLesson,
            onTap: _markComplete,
          ),
        ],
      ),
    );
  }

  void _setActiveTab(_Tab tab) {
    final wasNotes = _activeTab == _Tab.notes;
    setState(() => _activeTab = tab);
    if (tab == _Tab.notes && !wasNotes) {
      final url = _lesson?.notesPdfUrl;
      if (url != null && url.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeTab == _Tab.notes) {
            _openPdfFullScreen(url);
          }
        });
      }
    }
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = <(_Tab tab, IconData icon, String label)>[
      (_Tab.video, Icons.play_circle_outline, 'Video'),
      if (_lesson?.hasQuiz == true)
        (_Tab.quiz, Icons.quiz_outlined, 'Quiz'),
      if (_lesson?.hasNotes == true)
        (_Tab.notes, Icons.description_outlined, 'Notes'),
      (_Tab.feedback, Icons.rate_review_outlined, 'Feedback'),
      (_Tab.ai, Icons.psychology_outlined, 'AI Help'),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: tabs.map((tabData) {
            final (tab, icon, label) = tabData;
            final active = _activeTab == tab;
            return GestureDetector(
              onTap: () {
                // Check if this is a quiz-only lesson and user is trying to navigate away from quiz
                if (_isQuizOnlyLesson() && _activeTab == _Tab.quiz && tab != _Tab.quiz) {
                  _showQuizOnlyNotification();
                } else {
                  _setActiveTab(tab);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _T.green : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: active ? _T.green : _mutedColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: active ? _T.green : _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    return switch (_activeTab) {
      _Tab.video => _buildVideoTab(),
      _Tab.notes => _buildNotesTab(),
      _Tab.quiz => _buildQuizTab(),
      _Tab.feedback => _buildFeedbackTab(),
      _Tab.ai => _buildAITab(),
    };
  }

  // ── Desktop footer ────────────────────────────────────────────────────────

  Widget _buildDesktopFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          _NavBtn(
            label: _previousLesson?.title ?? 'Previous',
            icon: Icons.arrow_back_ios_new,
            iconRight: false,
            enabled: _previousLesson != null,
            isPrimary: false,
            bgColor: _bgColor,
            borderColor: _borderColor,
            mutedColor: _mutedColor,
            textColor: _textColor,
            onTap: () {
              if (_previousLesson != null) _navigateTo(_previousLesson!);
            },
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildProgressTrack()),
          const SizedBox(width: 12),
          _NavBtn(
            label: _nextLesson?.title ?? 'Next lesson',
            icon: Icons.arrow_forward_ios,
            iconRight: true,
            enabled: _nextLesson != null,
            isPrimary: true,
            bgColor: _bgColor,
            borderColor: _borderColor,
            mutedColor: _mutedColor,
            textColor: _textColor,
            onTap: () {
              if (_nextLesson != null) _navigateTo(_nextLesson!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTrack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: _borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(_T.green),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lesson $_currentLessonIndex of $_totalLessonsInSection',
          style: TextStyle(fontSize: 11, color: _mutedColor),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildMobileAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildMobileProgress(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
          // AI chat overlay
          if (_isChatOpen) _buildChatOverlay(),
          // Floating AI button (only on non-AI tabs)
          if (_activeTab != _Tab.ai && !_isChatOpen)
            Positioned(
              bottom: 90,
              right: 20,
              child: _FloatingAIButton(
                onTap: () => setState(() => _isChatOpen = true),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _bgColor,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 16, color: _mutedColor),
          onPressed: () => context.pop(),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lesson?.title ?? 'Lesson',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Section · Lesson $_currentLessonIndex',
              style: TextStyle(fontSize: 11, color: _mutedColor),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _T.greenLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_currentLessonIndex / $_totalLessonsInSection',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.greenDark),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _borderColor),
      ),
    );
  }

  Widget _buildMobileProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: _borderColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_T.green),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _T.green),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _MobNavItem(
                Icons.arrow_back_ios_new,
                'Previous',
                _previousLesson != null,
                false,
                () {
                  if (_previousLesson != null) _navigateTo(_previousLesson!);
                },
                _bgColor,
                _borderColor,
                _mutedColor,
                _textColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _CompleteButton(
                    isCompleted: _isLessonCompleted,
                    isLoading: _isCompletingLesson,
                    onTap: _markComplete,
                  ),
                ),
              ),
              _MobNavItem(
                Icons.arrow_forward_ios,
                'Next',
                _nextLesson != null,
                true,
                () {
                  if (_nextLesson != null) _navigateTo(_nextLesson!);
                },
                _bgColor,
                _borderColor,
                _mutedColor,
                _textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _isChatOpen = false),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ModernAIChatDialog(
                    currentCourse: null,
                    currentLesson: _lesson,
                    allSections: null,
                    sectionLessons: null,
                    chatService: _aiChatService,
                    conversationId: _conversationId,
                    guideKey: _guideKey,
                    initialPrompt: _chatPrompt,
                    onClose: () => setState(() {
                      _isChatOpen = false;
                      _chatPrompt = null;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB PANELS
  // ─────────────────────────────────────────────────────────────────────────

  // ── Video tab ─────────────────────────────────────────────────────────────

  Widget _buildVideoTab() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 0,
        vertical: isDesktop ? 24 : 16,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildVideoLeft()),
                const SizedBox(width: 24),
                SizedBox(width: 280, child: _buildVideoRight()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video player takes full width on mobile (no horizontal padding)
                _buildVideoPlayer(),
                const SizedBox(height: 16),
                // Other content keeps normal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildVideoActions(),
                      const SizedBox(height: 16),
                      _buildAboutCard(),
                      const SizedBox(height: 16),
                      _buildMaterialsCard(),
                      if (_lesson!.hasQuiz) ...[
                        const SizedBox(height: 16),
                        _buildVideoQuizSection(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildVideoRight(),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVideoPlayer(),
        const SizedBox(height: 12),
        _buildVideoActions(),
        const SizedBox(height: 16),
        _buildAboutCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        if (_lesson!.hasQuiz) ...[
          const SizedBox(height: 16),
          _buildVideoQuizSection(),
        ],
      ],
    );
  }

  Widget _buildVideoRight() {
    return Column(
      children: [
        _buildChecklistCard(),
        const SizedBox(height: 16),
        _buildAITutorCard(),
        const SizedBox(height: 16),
        _buildProgressStatsCard(),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    final videoUrl = _extractVideoUrl();
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
final videoChild = _lesson!.videoId != null && videoUrl.isNotEmpty
        ? (kIsWeb
            // better_player has no web implementation; use video_player/chewie (CustomVideoPlayer) on browsers.
            ? CustomVideoPlayer(
                videoId: _lesson!.videoId!,
                videoUrl: videoUrl,
                title: _lesson!.title,
                description: _lesson!.description ?? '',
                showAppBar: true,
              )
            : (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
                ? OptimizedVideoPlayer(
                    videoId: _lesson!.videoId!,
                    videoUrl: videoUrl,
                    title: _lesson!.title,
                    description: _lesson!.description ?? '',
                    showAppBar: true,
                  )
                : CustomVideoPlayer(
                    videoId: _lesson!.videoId!,
                    videoUrl: videoUrl,
                    title: _lesson!.title,
                    description: _lesson!.description ?? '',
                    showAppBar: true,
                  )))
        : _buildVideoPlaceholder();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
        boxShadow: isDesktop ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ] : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: isDesktop
          ? AspectRatio(aspectRatio: 16 / 9, child: videoChild)
          : SizedBox(
              height: MediaQuery.of(context).size.width * 9 / 16,
              child: videoChild,
            ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.play_circle_outline,
                color: Colors.white54, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            _lesson?.title ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text('Video not available',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVideoActions() {
    // Check if we have a valid video to download
    final hasValidVideo = _video != null || (_lesson?.hasVideo == true);
    
    return Column(
      children: [
        if (_isDownloading) ...[
          // Progress bar for visual feedback
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: _downloadProgress < 0 ? null : _downloadProgress,
              backgroundColor: _borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(_T.green),
              minHeight: 4,
            ),
          ),
          // Progress text
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Text(
              _getProgressText(),
              style: TextStyle(
                fontSize: 12,
                color: _T.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                _isDownloading ? Icons.downloading : 
                (_isVideoDownloaded() ? Icons.folder_open_outlined : Icons.download_outlined),
                _isDownloading ? _getProgressText() : 
                (_isVideoDownloaded() ? 'View in Downloads' : 'Download'),
                _bgColor,
                _borderColor,
                _mutedColor,
                _textColor,
                _isDownloading || !hasValidVideo ? () {
                  print('Download button disabled - isDownloading: $_isDownloading, hasValidVideo: $hasValidVideo');
                  if (!hasValidVideo) {
                    _showSnack('No video available for download', isError: true);
                  }
                } : _isVideoDownloaded() ? () {
                  _navigateToDownloads();
                } : () {
                  print('Download button clicked - starting download');
                  _downloadVideo();
                },
              ),
            ),
            const SizedBox(width: 8),
            _OutlineIconBtn(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
              _bgColor, 
              _borderColor, 
              _mutedColor, 
              _toggleBookmark
            ),
            const SizedBox(width: 8),
            _OutlineIconBtn(Icons.share_outlined, _bgColor, _borderColor, _mutedColor, _shareLesson),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return _LessonCard(
      title: 'About this lesson',
      icon: Icons.info_outline,
      iconColor: _T.blue,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              _lesson!.description ??
                  'No description available for this lesson.',
              style: TextStyle(
                  fontSize: 13, color: _textColor, height: 1.65),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(Icons.schedule_outlined, '${_lesson!.duration} min',
                  _T.greenLight, _T.greenDark, _T.greenMid),
              _TagChip(Icons.category_outlined, _lesson!.displayType,
                  _T.blueLight, _T.blue, const Color(0xFFBFDBFE)),
              if (_lesson!.availableMaterials.isNotEmpty)
                _TagChip(
                    Icons.attach_file_outlined,
                    '${_lesson!.availableMaterials.length} materials',
                    _T.orangeLight,
                    _T.orange,
                    const Color(0xFFFED7AA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final materials = <_MaterialItem>[];
    final hasNotesPdf = _lesson!.notesPdfUrl?.isNotEmpty == true;
    if (_lesson!.hasNotes) {
      materials.add(_MaterialItem(
        title: hasNotesPdf ? 'Lesson Notes (PDF)' : 'Lesson Notes',
        subtitle: 'Comprehensive study guide',
        icon: Icons.description_outlined,
        color: _T.green,
        bgColor: _T.greenLight,
        url: _lesson!.notesPdfUrl,
        isNotes: true,
      ));
    }
    if (_lesson!.materials != null) {
      for (int i = 0; i < _lesson!.materials!.length; i++) {
        materials.add(_MaterialItem(
          title: 'Material ${i + 1}',
          subtitle: 'Additional learning resource',
          icon: Icons.attach_file_outlined,
          color: _T.blue,
          bgColor: _T.blueLight,
          url: _lesson!.materials![i],
        ));
      }
    }
    if (materials.isEmpty) return const SizedBox.shrink();

    return _LessonCard(
      title: 'Learning materials',
      icon: Icons.folder_open_outlined,
      iconColor: _T.orange,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Column(
        children: materials
            .map((m) => _buildMaterialRow(m))
            .toList(),
      ),
    );
  }

  Widget _buildMaterialRow(_MaterialItem m) {
    return GestureDetector(
      onTap: () {
        if (m.isNotes) {
          _setActiveTab(_Tab.notes);
        } else if (m.url != null && m.url!.isNotEmpty) {
          _openMaterialInApp(m.title, m.url!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: m.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(m.icon, color: m.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColor)),
                  Text(m.subtitle,
                      style:
                          TextStyle(fontSize: 11, color: _mutedColor)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (m.url != null) {
                      if (_isMaterialDownloaded()) {
                        _navigateToDownloads();
                      } else {
                        _downloadMaterial(m.url!);
                      }
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isMaterialDownloaded() ? Icons.folder_open_outlined : Icons.download_outlined,
                      size: 16, 
                      color: _mutedColor
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    final items = <({String key, String label})>[
      if (_lesson!.hasVideo) (key: 'video', label: 'Watch the lesson video'),
      if (_lesson!.hasNotes) (key: 'notes', label: 'Review lesson notes'),
      if (_lesson!.hasQuiz) (key: 'quiz', label: 'Complete the quiz'),
      (key: 'complete', label: 'Mark lesson complete'),
    ];

    return _LessonCard(
      title: 'Lesson overview',
      icon: Icons.checklist_outlined,
      iconColor: _T.green,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Column(
        children: items.map((item) {
          final done = _checklist[item.key] == true;
          return GestureDetector(
            onTap: () => setState(() => _checklist[item.key] = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? _T.green : Colors.transparent,
                      border: Border.all(
                          color: done ? _T.green : _borderColor,
                          width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: done ? _textColor : _mutedColor,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: _T.greenMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAITutorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Tutor',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textColor)),
                  Text('Ask anything about this lesson',
                      style:
                          TextStyle(fontSize: 11, color: _mutedColor)),
                ],
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0xFFDCFCE7),
                        blurRadius: 0,
                        spreadRadius: 3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.purpleLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Color(0xFF6D28D9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Try: "Simplify the main concept for me"',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6D28D9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _activeTab = _Tab.ai),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(l10n?.openAIChat ?? 'Open AI chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatsCard() {
    return _LessonCard(
      title: 'Your progress',
      icon: Icons.bar_chart_outlined,
      iconColor: _T.green,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _T.greenDark),
                  ),
                  const SizedBox(height: 2),
                  const Text('Complete',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _T.green)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    '$_currentLessonIndex / $_totalLessonsInSection',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textColor),
                  ),
                  const SizedBox(height: 2),
                  Text('Lessons done',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _mutedColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes tab ─────────────────────────────────────────────────────────────

  Widget _buildNotesTab() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final hasPdf =
        _lesson!.notesPdfUrl?.isNotEmpty == true;
    final hasText = _lesson!.notes?.isNotEmpty == true;
    final hasGuide = _lesson!.hasAiGuide;
    final viewCount = [hasGuide, hasPdf, hasText && !hasGuide].where((v) => v).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hasGuide ? 'Study Guide' : 'Lesson Notes',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textColor)),
                ),
                if (hasPdf || !hasGuide)
                _OutlineBtn(
                  _isNotesDownloaded() ? Icons.folder_open_outlined : Icons.download_outlined,
                  _isNotesDownloaded() ? 'View in Downloads' : 'Download PDF',
                  _bgColor,
                  _borderColor,
                  _mutedColor,
                  _textColor,
                  _isNotesDownloaded() ? () => _navigateToDownloads() : () => _downloadMaterial(_lesson!.notesPdfUrl ?? ''),
                ),
                if (_hasDownloads()) ...[
                  const SizedBox(width: 8),
                  _OutlineBtn(
                    Icons.folder_open_outlined,
                    'View Downloads',
                    _bgColor,
                    _borderColor,
                    _mutedColor,
                    _textColor,
                    _navigateToDownloads,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (viewCount > 1) ...[
              _buildNotesSwitcher(hasGuide: hasGuide, hasPdf: hasPdf, hasText: hasText && !hasGuide),
              const SizedBox(height: 16),
            ],
            if (_notesTab == _NotesView.guide && hasGuide)
              _buildStudyGuide()
            else if (_notesTab == _NotesView.pdf && hasPdf)
              _buildPdfViewer()
            else if (hasGuide)
              _buildStudyGuide()
            else if (hasText)
              _buildTextNotes()
            else if (hasPdf)
              _buildPdfViewer()
            else
              _buildNoNotes(),
            const SizedBox(height: 16),
            if (_lesson!.hasQuiz) _buildVideoQuizSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyGuide() {
    return AiStudyGuideView(
      content: _lesson!.aiContent!,
      palette: AiGuidePalette(
        text: _textColor,
        muted: _mutedColor,
        surface: _surfaceColor,
        bg: _bgColor,
        border: _borderColor,
        accent: _T.green,
        accentSoft: _isDark ? _T.greenDark : _T.greenLight,
        isDark: _isDark,
      ),
      onAskAi: widget.isAdminPreview
          ? null
          : (prompt) => setState(() {
                _chatPrompt = prompt;
                _isChatOpen = true;
              }),
    );
  }

  Widget _buildNotesSwitcher({bool hasGuide = false, bool hasPdf = true, bool hasText = true}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          if (hasGuide)
            _NotesTabBtn('Study Guide', Icons.auto_awesome,
                _notesTab == _NotesView.guide, () {
              setState(() => _notesTab = _NotesView.guide);
            }),
          if (hasPdf)
            _NotesTabBtn('PDF View', Icons.picture_as_pdf_outlined,
                _notesTab == _NotesView.pdf, () {
              setState(() => _notesTab = _NotesView.pdf);
            }),
          if (hasText)
            _NotesTabBtn('Text View', Icons.text_snippet_outlined,
                _notesTab == _NotesView.text, () {
              setState(() => _notesTab = _NotesView.text);
            }),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    // On web, PDFs on CloudFront/S3 must be fetched via the media proxy to
    // satisfy browser CORS. Native platforms use the direct URL.
    final pdfUrl = mediaProxyUrl(_lesson!.notesPdfUrl);
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (pdfUrl.isNotEmpty)
            SfPdfViewer.network(
              pdfUrl,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoadFailed: (details) {
                _showSnack('Failed to load PDF: ${details.error}', isError: true);
              },
            )
          else
            _buildNoNotes(),
          // Full screen button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () => _openPdfFullScreen(pdfUrl),
                tooltip: 'Full screen',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: MarkdownBody(
        data: _lesson!.notes!,
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textColor,
              height: 1.3),
          h2: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textColor,
              height: 1.4),
          h3: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _T.green,
              height: 1.4),
          p: TextStyle(
              fontSize: 14,
              color: _textColor,
              height: 1.75),
          listBullet: const TextStyle(
              fontSize: 14, color: _T.green, fontWeight: FontWeight.w600),
          code: TextStyle(
              fontSize: 13,
              backgroundColor: _bgColor,
              fontFamily: 'monospace',
              color: _T.orange),
          codeblockDecoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          blockquoteDecoration: BoxDecoration(
            color: _T.greenLight,
            border: const Border(
                left: BorderSide(color: _T.green, width: 4)),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          a: const TextStyle(
              color: _T.green,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNoNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.note_alt_outlined, size: 48, color: _T.subtle),
          const SizedBox(height: 16),
          Text('No notes available',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColor)),
          const SizedBox(height: 6),
          Text('This lesson doesn\'t have notes yet',
              style: TextStyle(fontSize: 13, color: _mutedColor)),
        ],
      ),
    );
  }

  // ── Quiz questions ──────────────────────────────────────────────────────

  Widget _buildQuizQuestions() {
    return FutureBuilder(
      future: _loadQuizQuestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _T.green),
            ),
          );
        }

        if (snapshot.hasError) {
          return _LessonCard(
            title: 'Quiz Questions',
            icon: Icons.error_outline,
            iconColor: _T.orange,
            surfaceColor: _surfaceColor,
            borderColor: _borderColor,
            textColor: _textColor,
            mutedColor: _mutedColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 36, color: _T.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load quiz questions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final questions = snapshot.data;
        if (questions == null || questions.isEmpty) {
          return _LessonCard(
            title: 'Quiz Questions',
            icon: Icons.quiz_outlined,
            iconColor: _mutedColor,
            surfaceColor: _surfaceColor,
            borderColor: _borderColor,
            textColor: _textColor,
            mutedColor: _mutedColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 36, color: _mutedColor),
                    const SizedBox(height: 12),
                    Text(
                      'No questions available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This quiz doesn\'t have any questions yet',
                      style: TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _LessonCard(
          title: '${questions.length} Questions',
          icon: Icons.quiz_outlined,
          iconColor: _T.green,
          surfaceColor: _surfaceColor,
          borderColor: _borderColor,
          textColor: _textColor,
          mutedColor: _mutedColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _QuestionItem(
                    questionNumber: index + 1,
                    question: question,
                    textColor: _textColor,
                    borderColor: _borderColor,
                    bgColor: _bgColor,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _loadQuizQuestions() async {
    if (_exam == null) return [];
    
    try {
      // Use the quiz ID from the lesson, not from the exam data
      final quizId = _lesson?.quizId;
      if (quizId == null) return [];
      
      final quizResponse = await QuizService.getQuiz(quizId);
      print('=== QUIZ QUESTIONS DATA DEBUG ===');
      print('Quiz response: $quizResponse');
      
      // Extract questions from the response
      List<dynamic> questions = [];
      if (quizResponse['data'] != null) {
        final data = quizResponse['data'];
        if (data['questions'] != null) {
          questions = data['questions'] as List<dynamic>? ?? [];
        } else if (data['quiz'] != null && data['quiz']['questions'] != null) {
          questions = data['quiz']['questions'] as List<dynamic>? ?? [];
        }
      }
      
      print('Extracted questions: $questions');
      print('Questions count: ${questions.length}');
      return questions;
    } catch (e) {
      print('Error loading quiz questions: $e');
      return [];
    }
  }

  // ── Quiz section for video/notes tabs ───────────────────────────────────────

  Widget _buildVideoQuizSection() {
    final quizTitle = _exam?['title'] ?? 'Lesson Quiz';
    final hasAttempts = _quizAttempts.isNotEmpty;
    final latestAttempt = hasAttempts ? _quizAttempts.first : null;
    final score = latestAttempt?['totalScore'] ?? 0;
    final maxScore = latestAttempt?['maxScore'] ?? _exam?['totalPoints'] ?? _exam?['maxScore'] ?? 100;
    
    return _LessonCard(
      title: 'Quiz: $quizTitle',
      icon: Icons.quiz_outlined,
      iconColor: _T.green,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Test your understanding of this lesson',
                  style: TextStyle(fontSize: 13, color: _mutedColor),
                ),
              ),
              if (hasAttempts) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _T.greenLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _T.greenMid),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.scoreboard_outlined, 
                          color: _T.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$score/$maxScore',
                        style: TextStyle(
                            color: _T.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exam != null ? _startQuiz : null,
              icon: const Icon(Icons.play_arrow_outlined, size: 16),
              label: Text(_getQuizButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (hasAttempts) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _activeTab = _Tab.quiz),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_outlined, 
                        color: _mutedColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'View attempt history',
                      style: TextStyle(
                          color: _T.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, 
                        color: _T.green, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Quiz tab ──────────────────────────────────────────────────────────────

  Widget _buildQuizTab() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    if (_exam == null) return _buildNoQuizState();
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 :16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _buildQuizHero(),
              const SizedBox(height: 20),
              _buildQuizAttemptHistory(),
              const SizedBox(height: 16),
              _buildQuizTipsCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when the lesson has no quiz, or its quiz couldn't be loaded.
  Widget _buildNoQuizState() {
    final hasQuiz = _lesson?.hasQuiz == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _T.greenLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                    hasQuiz ? Icons.cloud_off_outlined : Icons.quiz_outlined,
                    color: _T.green,
                    size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                hasQuiz ? 'Quiz couldn\'t be loaded' : 'No quiz for this lesson',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textColor),
              ),
              const SizedBox(height: 8),
              Text(
                hasQuiz
                    ? 'Check your connection and try again.'
                    : 'This lesson doesn\'t include a quiz. Keep going with the video and notes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: _mutedColor),
              ),
              if (hasQuiz) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadLessonData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHero() {
    final quizTitle = _exam?['title'] ?? 'Lesson Quiz';
    final quizType = _exam?['type'] ?? _lesson?.lessonType ?? 'Quiz';
    final quizInstructions = _exam?['instructions'] ?? 'Test your understanding of this lesson';
    final isFinalExam = (quizType.toLowerCase().contains('final') || 
                         (_exam?['isFinal'] == true) || 
                         (_lesson?.lessonType?.toLowerCase().contains('final') == true));
    
    // Debug final exam detection
    print('=== FINAL EXAM DEBUG ===');
    print('Quiz Title: $quizTitle');
    print('Quiz Type: $quizType');
    print('Lesson Type: ${_lesson?.lessonType}');
    print('Exam isFinal: ${_exam?['isFinal']}');
    print('isFinalExam: $isFinalExam');
    
    final hasAttempts = _quizAttempts.isNotEmpty;
    final latestAttempt = hasAttempts ? _quizAttempts.first : null;
    final score = latestAttempt?['totalScore'] ?? 0;
    final maxScore = latestAttempt?['maxScore'] ?? _exam?['totalPoints'] ?? _exam?['maxScore'] ?? 100;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _T.greenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.greenMid),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _T.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.quiz_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            quizTitle,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _T.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              quizType,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            quizInstructions,
            style: TextStyle(fontSize: 13, color: _mutedColor),
            textAlign: TextAlign.center,
          ),
          // Certificate notification for final exams
          if (isFinalExam) ...[
            const SizedBox(height: 16),
            _buildCertificateStatus(),
          ],
          if (hasAttempts) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _T.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.scoreboard_outlined, 
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Latest: $score/$maxScore',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exam != null ? _showQuizInstructions : null,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(l10n?.instructions ?? 'Instructions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exam != null ? _startQuiz : null,
                  icon: const Icon(Icons.play_arrow_outlined, size: 18),
                  label: Text(_getQuizButtonText()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: _T.greenMid,
    );
  }

  Widget _buildQuizAttemptHistory() {
    if (_isLoadingQuizAttempts) {
      return _LessonCard(
        title: 'Attempt history',
        icon: Icons.history_outlined,
        iconColor: _mutedColor,
        surfaceColor: _surfaceColor,
        borderColor: _borderColor,
        textColor: _textColor,
        mutedColor: _mutedColor,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _T.green),
          ),
        ),
      );
    }

    if (_quizAttempts.isEmpty) {
      return _LessonCard(
        title: 'Attempt history',
        icon: Icons.history_outlined,
        iconColor: _mutedColor,
        surfaceColor: _surfaceColor,
        borderColor: _borderColor,
        textColor: _textColor,
        mutedColor: _mutedColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 36, color: _T.subtle),
                const SizedBox(height: 10),
                Text('No attempts yet',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textColor)),
                const SizedBox(height: 4),
                Text('Complete the quiz to see your results here',
                    style:
                        TextStyle(fontSize: 12, color: _mutedColor)),
              ],
            ),
          ),
        ),
      );
    }

    return _LessonCard(
      title: 'Attempt history',
      icon: Icons.history_outlined,
      iconColor: _T.green,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Column(
        children: [
          ..._quizAttempts.asMap().entries.map((entry) {
            final index = entry.key;
            final attempt = entry.value;
            final score = attempt['totalScore'] ?? 0;
            final maxScore = attempt['maxScore'] ?? _exam?['totalPoints'] ?? _exam?['maxScore'] ?? 100;
            final percentage = attempt['percentage'] ?? (maxScore > 0 ? (score / maxScore * 100).round() : 0);
            final submittedAt = attempt['submittedAt']?.toString() ?? attempt['createdAt']?.toString() ?? '';
            final isPassed = attempt['passed'] ?? percentage >= (_exam?['passingScore'] ?? 70);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPassed ? _T.greenLight : _T.orangeLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPassed ? Icons.check_circle : Icons.close,
                      color: isPassed ? _T.green : _T.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attempt ${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        if (submittedAt.isNotEmpty)
                          Text(
                            _formatDate(submittedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: _mutedColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score/$maxScore',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isPassed ? _T.green : _T.orange,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuizTipsCard() {
    return _LessonCard(
      title: 'Study tips',
      icon: Icons.lightbulb_outline,
      iconColor: _T.orange,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedColor: _mutedColor,
      child: Text(
        'Review the lesson notes and video before starting. '
        'The quiz covers all three key principles discussed. '
        'You can retake it as many times as needed.',
        style: TextStyle(fontSize: 13, color: _textColor, height: 1.6),
      ),
    );
  }

  // ── Feedback tab ───────────────────────────────────────────────────────────

  Widget _buildFeedbackTab() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeedbackHero(),
              const SizedBox(height: 24),
              if (!_hasSubmittedFeedback) ...[
                _buildRatingSection(),
                const SizedBox(height: 24),
                _buildFeedbackSection(),
                const SizedBox(height: 24),
                _buildSubmitFeedbackButton(),
              ] else ...[
                _buildFeedbackSuccessCard(),
                const SizedBox(height: 24),
                _buildEditFeedbackButton(),
              ],
              const SizedBox(height: 32),
              _buildExistingFeedbackSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _T.purpleLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.purple,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _T.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.rate_review_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Course Feedback',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Share your experience and help us improve',
            style: TextStyle(
                fontSize: 14,
                color: _mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate this course',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _userRating = (index + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: index < _userRating ? Colors.amber : _mutedColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _userRating > 0 ? '${_userRating.toInt()} out of 5' : 'Tap to rate',
              style: TextStyle(
                fontSize: 14,
                color: _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Tell us about your experience with this course...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _T.purple),
              ),
              filled: true,
              fillColor: _bgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitFeedbackButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _userRating > 0 && !_isSubmittingFeedback
            ? _submitFeedback
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmittingFeedback
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFeedbackSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.greenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.greenMid),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: _T.green,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for your feedback!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _T.greenDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your input helps us improve the learning experience for everyone.',
            style: TextStyle(
              fontSize: 14,
              color: _T.greenDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditFeedbackButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => setState(() {
          _hasSubmittedFeedback = false;
          _userRating = 0.0;
          _feedbackController.clear();
        }),
        style: OutlinedButton.styleFrom(
          foregroundColor: _T.purple,
          side: BorderSide(color: _T.purple),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Update Your Feedback',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildExistingFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingFeedback)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_courseFeedback.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: _mutedColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _mutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share your experience!',
                    style: TextStyle(
                      fontSize: 12,
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._courseFeedback.asMap().entries.map((entry) {
              final index = entry.key;
              final feedback = entry.value;
              return _buildFeedbackItem(feedback, index != _courseFeedback.length - 1);
            }),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> feedback, bool showDivider) {
    final rating = (feedback['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = feedback['feedback'] as String? ?? '';
    final userName = feedback['userName'] as String? ?? 'Anonymous Student';
    final createdAt = feedback['createdAt'] as String?;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _T.purple.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        color: _T.purple,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: _mutedColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: index < rating ? Colors.amber : _mutedColor,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showDivider) const SizedBox(height: 12),
      ],
    );
  }

  
  Future<void> _submitFeedback() async {
    if (_userRating == 0 || _lesson == null) return;
    if (_isDraftPreview) return _previewOnly();

    setState(() => _isSubmittingFeedback = true);
    
    try {
      final enrollmentService = EnrollmentService();
      await enrollmentService.submitCourseFeedback(
        _lesson!.courseId,
        _userRating,
        _feedbackController.text.trim(),
      );
      
      setState(() {
        _hasSubmittedFeedback = true;
        _isSubmittingFeedback = false;
      });
      
      // Reload feedback to show the new submission
      await _loadCourseFeedback();
      
      _showSnack('Feedback submitted successfully!');
    } catch (e) {
      setState(() => _isSubmittingFeedback = false);
      _showSnack('Failed to submit feedback: $e', isError: true);
    }
  }

  // ── AI Help tab ───────────────────────────────────────────────────────────

  Widget _buildAITab() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ModernAIChatDialog(
          currentCourse: null,
          currentLesson: _lesson,
          allSections: null,
          sectionLessons: null,
          chatService: _aiChatService,
          conversationId: _conversationId,
          guideKey: _aiTabGuideKey,
          onClose: () {},
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _markComplete() async {
    if (_isLessonCompleted || _isCompletingLesson || _lesson == null) return;
    if (_isDraftPreview) return _previewOnly();
    setState(() => _isCompletingLesson = true);
    try {
      final enrollmentNotifier = ref.read(enrollmentNotifierProvider.notifier);
      await enrollmentNotifier.markLessonComplete(_lesson!.id, _lesson!.courseId);
      setState(() {
        _isLessonCompleted = true;
        _checklist['complete'] = true;
      });
      AchievementSoundService.instance.play(AchievementSound.lessonComplete);
      _showSnack('Lesson marked as completed!');
    } catch (e) {
      _showSnack('Failed to mark complete: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCompletingLesson = false);
    }
  }

  Future<void> _downloadVideo() async {
    print('_downloadVideo method called');
    print('Lesson: ${_lesson?.title}, hasVideo: ${_lesson?.hasVideo}');
    
    // Check if lesson has video before proceeding
    if (_lesson == null || !_lesson!.hasVideo) {
      print('ERROR: No video available for this lesson');
      _showSnack('No video available for this lesson', isError: true);
      return;
    }
    
    final downloadService = ref.read(downloadServiceProvider);
    
    // Check if already downloading this lesson
    if (_isDownloading && _currentDownloadLessonId == _lesson!.id) {
      print('WARNING: Download already in progress for lesson ${_lesson!.id}');
      _showSnack('Download already in progress...');
      return;
    }
    
    // Check if already downloaded
    final existingDownload = downloadService.getDownloadStatus(_lesson!.id);
    if (existingDownload?.status == DownloadStatus.completed) {
      print('INFO: Video already downloaded for lesson ${_lesson!.id}');
      _showSnack('Video already downloaded!');
      return;
    }
    
    print('Starting download process for lesson ${_lesson!.id}');
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _currentDownloadLessonId = _lesson!.id;
    });
    
    try {
      final videoApiService = VideoApiService();
      print('Getting video stream URL for lesson ${_lesson!.id}');
      final signedUrl = await videoApiService.getVideoStreamUrl(_lesson!.id);
      if (signedUrl.isEmpty) {
        print('ERROR: Failed to get download URL - empty URL returned');
        throw Exception('Failed to get download URL');
      }
      
      print('Got video URL: ${signedUrl.substring(0, signedUrl.length > 50 ? 50 : signedUrl.length)}...');
      
      downloadService.downloadVideo(
        url: signedUrl,
        fileName: _lesson!.id,
        originalTitle: _lesson!.title,
        lessonId: _lesson!.id,
        onProgress: (progress) {
          if (mounted && _currentDownloadLessonId == _lesson!.id) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        onSuccess: () {
          if (mounted && _currentDownloadLessonId == _lesson!.id) {
            print('Download completed successfully for lesson ${_lesson!.id}');
            setState(() {
              _isDownloading = false;
              _downloadProgress = 1.0;
              _currentDownloadLessonId = null;
            });
            _showSnack('Video downloaded successfully!');
          }
        },
        onError: (e) {
          if (mounted && _currentDownloadLessonId == _lesson!.id) {
            print('Download failed for lesson ${_lesson!.id}: $e');
            setState(() {
              _isDownloading = false;
              _downloadProgress = 0.0;
              _currentDownloadLessonId = null;
            });
            _showSnack('Download failed: $e', isError: true);
          }
        },
      );
    } catch (e) {
      print('Exception in download process for lesson ${_lesson!.id}: $e');
      if (mounted && _currentDownloadLessonId == _lesson!.id) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _currentDownloadLessonId = null;
        });
        _showSnack('Failed to prepare download: $e', isError: true);
      }
    }
  }

  void _openMaterialInApp(String title, String url) {
    if (url.isEmpty) return;
    final isPdf = url.toLowerCase().endsWith('.pdf');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _surfaceColor,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  border: Border(bottom: BorderSide(color: _borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ),
                    if (isPdf)
                      IconButton(
                        icon: Icon(Icons.fullscreen, color: _mutedColor),
                        onPressed: () {
                          Navigator.pop(context);
                          _openPdfFullScreen(url);
                        },
                        tooltip: 'Full screen',
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: _mutedColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isPdf
                    ? SfPdfViewer.network(
                        mediaProxyUrl(url),
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        onDocumentLoadFailed: (details) {
                          _showSnack('Failed to load PDF: ${details.error}', isError: true);
                          Navigator.pop(context);
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: MarkdownBody(
                          data: url,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: _textColor),
                            h1: TextStyle(
                              color: _textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            h2: TextStyle(
                              color: _textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            h3: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            listBullet: TextStyle(color: _textColor),
                            code: TextStyle(
                              backgroundColor: _bgColor,
                              color: _textColor,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPdfFullScreen(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'PDF Viewer',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pinch to zoom in/out. Use scroll to navigate.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                tooltip: 'Help',
              ),
            ],
          ),
          body: SfPdfViewer.network(
            mediaProxyUrl(url),
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            onDocumentLoadFailed: (details) {
              _showSnack('Failed to load PDF: ${details.error}', isError: true);
              Navigator.pop(context);
            },
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void _downloadMaterial(String url) {
    if (url.isEmpty) return;
    final downloadService = ref.read(downloadServiceProvider);
    downloadService.downloadNotesOrMaterial(
      url: url,
      title: 'Lesson Material',
      lessonId: _lesson!.id,
      type: DownloadType.material,
      lessonTitle: _lesson!.title,
      sectionTitle: null,
      onProgress: (_) {},
      onSuccess: () => _showSnack('Material downloaded!'),
      onError: (e) => _showSnack('Download failed: $e', isError: true),
    );
  }

  void _startQuiz() async {
    if (_isDraftPreview && _exam != null) {
      // Take the draft quiz like a student; it is graded but not saved
      final seconds = (_exam!['timeLimit'] as num?)?.toInt() ?? 600;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExamTakingScreen(
          exam: {'id': _exam!['_id'], 'title': _exam!['title'] ?? 'Quiz', 'timeLimit': (seconds / 60).ceil(), 'questions': []},
          previewItemId: widget.draftItemId,
        ),
      ));
      return;
    }
    if (_exam != null && _lesson?.quizId != null) {
      // Check if this is a final exam and user already has a certificate
      final isFinalExam = (_exam!['type']?.toString().toLowerCase() == 'final' ||
                          (_exam!['title']?.toString().toLowerCase().contains('final') == true));
      
      if (isFinalExam) {
        final hasCertificate = _certificates.any((cert) => 
            cert.courseId == _lesson?.courseId && 
            cert.isValid);
            
        if (hasCertificate) {
          // Navigate to certificates screen to view certificate
          _openCertificates();
          return;
        }
        
        // Check if user has passed quiz but certificate is processing
        if (_quizAttempts.isNotEmpty) {
          final latestAttempt = _quizAttempts.last;
          
          // Use percentage field if available, otherwise fall back to score
          final percentage = latestAttempt['percentage'] as num? ?? latestAttempt['score'] as num? ?? 0;
          final passingScore = _exam?['passingScore'] as num? ?? 70;
          
          if (percentage >= passingScore) {
            // Show certificate processing dialog
            _showCertificateProcessingDialog();
            return;
          } else {
            // Show failed dialog - no retake for final exams
            _showFinalExamFailedDialog();
            return;
          }
        }
      }
      
      // Create a proper Exam object from the Map data
      final exam = {
        'id': _lesson!.quizId, // Use quiz ID from lesson
        'title': _exam!['title'] ?? 'Quiz',
        'timeLimit': _exam!['timeLimit'] ?? 30,
        'questions': [], // Questions will be loaded by ExamTakingScreen
      };
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExamTakingScreen(exam: exam),
        ),
      );
      
      // Refresh quiz attempts and certificates when returning from quiz
      if (mounted && _lesson!.hasQuiz) {
        await _loadQuizAttempts();
        
        // Check if user just completed a final exam
        if (_quizAttempts.isNotEmpty) {
          final latestAttempt = _quizAttempts.last;
          final percentage = latestAttempt['percentage'] as num? ?? 0;
          final passingScore = _exam?['passingScore'] as num? ?? 70;
          
          if (percentage >= passingScore) {
            setState(() => _justCompletedFinalExam = true);
          }
        }
        
        // Give backend time to generate certificate, then refresh
        await Future.delayed(const Duration(seconds: 2));
        
        // Also refresh certificates in case a new one was generated
        await _loadCertificates();
        
        print('=== POST-QUIZ REFRESH ===');
        print('Quiz attempts loaded: ${_quizAttempts.length}');
        print('Certificates loaded: ${_certificates.length}');
        print('Just completed final exam: $_justCompletedFinalExam');
        print('========================');
      }
    }
  }

  void _showCertificateProcessingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hourglass_top, color: _T.blue, size: 24),
            const SizedBox(width: 12),
            Text(l10n?.certificateProcessing ?? 'Certificate Processing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congratulations! You have passed the final exam.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your certificate is being generated and will be available shortly. Please check back in a few minutes.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _T.blueLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _T.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can view your certificate in the Certificates section once it\'s ready.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _T.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: _T.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openCertificates();
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: Text(l10n?.viewCertificates ?? 'View Certificates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.blue,
              foregroundColor: Colors.white,
            ),
          ),
          if (_certificates.isEmpty) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateCertificateManually();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n?.generateNow ?? 'Generate Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showFinalExamFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(l10n?.finalExamFailed ?? 'Final Exam Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unfortunately, you did not pass the final exam.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Final exams cannot be retaken. To retake this course, you will need to unenroll and then enroll again to start the full course from the beginning.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a final exam. No retakes are permitted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Understood',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showCertificateAlreadyEarnedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: _T.green, size: 24),
            const SizedBox(width: 12),
            Text(l10n?.certificateAlreadyEarned ?? 'Certificate Already Earned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have already earned a certificate for this final exam. You cannot retake the final exam once you have received your certificate.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you wish to attempt the final exam again, you will need to unenroll from this course and enroll again.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showUnenrollConfirmation();
            },
            icon: const Icon(Icons.logout, size: 16),
            label: Text(l10n?.unenrollFromCourse ?? 'Unenroll from Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnenrollConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.unenrollFromCourse ?? 'Unenroll from Course'),
        content: const Text(
          'Are you sure you want to unenroll from this course? This will:\n\n• Remove your access to course content\n• Delete your quiz attempts\n• Remove your certificate\n\nYou will need to enroll again to regain access.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _unenrollFromCourse();
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Unenroll'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unenrollFromCourse() async {
    try {
      // Show loading indicator
      _showSnack('Unenrolling from course...');
      
      // Call enrollment service to unenroll
      final enrollmentService = EnrollmentService();
      await enrollmentService.unenrollFromCourse(_lesson!.courseId);
      
      // Navigate back to dashboard
      if (mounted) {
        _showSnack('Successfully unenrolled from course');
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error unenrolling from course: $e', isError: true);
      }
    }
  }

  String _getQuizButtonText() {
    // Built on every quiz-tab render, including lessons with no (or an
    // unloadable) quiz — so _exam may be null here.
    if (_exam == null) return 'Start quiz';
    final isFinalExam = (_exam!['type']?.toString().toLowerCase() == 'final' ||
                        (_exam!['title']?.toString().toLowerCase().contains('final') == true));
    
    if (isFinalExam) {
      final hasCertificate = _certificates.any((cert) => 
          cert.courseId == _lesson?.courseId && 
          cert.isValid);
      
      if (hasCertificate) {
        return 'View Certificate';
      }
      
      // Check if user has passed quiz but certificate is not yet generated
      if (_quizAttempts.isNotEmpty) {
        final latestAttempt = _quizAttempts.last;
        
        // Use percentage field if available, otherwise fall back to score
        final percentage = latestAttempt['percentage'] as num? ?? latestAttempt['score'] as num? ?? 0;
        final passingScore = _exam?['passingScore'] as num? ?? 70;
        
        // Check if quiz was recently completed (within last 5 minutes)
        final submittedAt = latestAttempt['submittedAt'] as String?;
        final isRecentlyCompleted = submittedAt != null 
            ? DateTime.now().difference(DateTime.parse(submittedAt)).inMinutes < 5
            : false;
        
        // Debug logging
        print('=== QUIZ SCORE DEBUG ===');
        print('Latest attempt: $latestAttempt');
        print('Percentage: $percentage (type: ${percentage.runtimeType})');
        print('Passing score: $passingScore (type: ${passingScore.runtimeType})');
        print('Percentage >= Passing: ${percentage >= passingScore}');
        print('Recently completed: $isRecentlyCompleted');
        print('Submitted at: $submittedAt');
        print('========================');
        
        if (percentage >= passingScore) {
          // If just completed and no certificate yet, show generating
          if (_justCompletedFinalExam && !hasCertificate) {
            return 'Generating Certificate...';
          } else if (hasCertificate) {
            return 'View Certificate';
          } else {
            return 'Certificate Processing...';
          }
        } else {
          return 'Failed - No Retake';
        }
      }
    }
    
    return _quizAttempts.isNotEmpty ? 'Retake quiz' : 'Start quiz';
  }

  Future<void> _navigateTo(Lesson lesson) async {
    if (_isDraftPreview) {
      context.pushReplacement('/ai-preview/${lesson.id}');
      return;
    }
    // Mark current lesson as complete before navigating to next
    if (!_isLessonCompleted && _lesson != null) {
      await _markComplete();
    }
    if (mounted) {
      context.pushReplacement('/lesson/${lesson.id}');
    }
  }

  // Check if current lesson has completed downloads
  bool _hasDownloads() {
    if (_lesson == null) return false;
    final downloadService = ref.read(downloadServiceProvider);
    final downloads = downloadService.getDownloadsByLesson(_lesson!.id);
    return downloads.any((download) => download.status == DownloadStatus.completed);
  }

  // Check if video is downloaded
  bool _isVideoDownloaded() {
    if (_lesson == null) return false;
    final downloadService = ref.read(downloadServiceProvider);
    final downloads = downloadService.getDownloadsByLesson(_lesson!.id);
    return downloads.any((download) => 
        download.status == DownloadStatus.completed && download.type == DownloadType.video);
  }

  // Check if notes are downloaded
  bool _isNotesDownloaded() {
    if (_lesson == null) return false;
    final downloadService = ref.read(downloadServiceProvider);
    final downloads = downloadService.getDownloadsByLesson(_lesson!.id);
    return downloads.any((download) => 
        download.status == DownloadStatus.completed && download.type == DownloadType.notes);
  }

  // Check if materials are downloaded
  bool _isMaterialDownloaded() {
    if (_lesson == null) return false;
    final downloadService = ref.read(downloadServiceProvider);
    final downloads = downloadService.getDownloadsByLesson(_lesson!.id);
    return downloads.any((download) => 
        download.status == DownloadStatus.completed && download.type == DownloadType.material);
  }

  // Navigate to downloads page
  void _navigateToDownloads() {
    if (!mounted || _lesson == null) return;
    
    try {
      context.go('/downloads');
    } catch (e) {
      _showSnack('Navigation error: $e', isError: true);
    }
  }

  // Load course feedback
  Future<void> _loadCourseFeedback() async {
    if (_lesson == null) return;
    
    setState(() => _isLoadingFeedback = true);
    try {
      final enrollmentService = EnrollmentService();
      final feedback = await enrollmentService.getCourseFeedback(_lesson!.courseId);
      setState(() {
        _courseFeedback = feedback;
        _isLoadingFeedback = false;
      });
    } catch (e) {
      setState(() => _isLoadingFeedback = false);
      print('Error loading course feedback: $e');
    }
  }

  // Load bookmark status from SharedPreferences
  Future<void> _loadBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = 'bookmarked_lesson_${_lesson!.id}';
      setState(() {
        _isBookmarked = prefs.getBool(bookmarkKey) ?? false;
      });
    } catch (e) {
      print('Error loading bookmark status: $e');
    }
  }

  // Toggle bookmark status
  Future<void> _toggleBookmark() async {
    if (_lesson == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = 'bookmarked_lesson_${_lesson!.id}';
      final newStatus = !_isBookmarked;
      
      await prefs.setBool(bookmarkKey, newStatus);
      setState(() {
        _isBookmarked = newStatus;
      });
      
      _showSnack(newStatus ? 'Lesson bookmarked!' : 'Bookmark removed');
    } catch (e) {
      _showSnack('Failed to update bookmark: $e', isError: true);
    }
  }

  // Share lesson
  Future<void> _shareLesson() async {
    if (_lesson == null) return;
    
    try {
      final title = _lesson!.title;
      final description = _lesson!.description ?? 'Check out this lesson from Excellence Coaching Hub';
      final shareText = '$title\n\n$description\n\nDownload the Excellence Coaching Hub app: https://play.google.com/store/apps/details?id=com.excellencecoachinghub.app&pcampaignid=web_share';
      
      await Share.share(
        shareText,
        subject: title,
      );
    } catch (e) {
      _showSnack('Failed to share: $e', isError: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const _LessonCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color borderColor;

  const _TagChip(this.icon, this.label, this.bg, this.fg, this.borderColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onTap;

  const _CompleteButton({
    required this.isCompleted,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCompleted ? _T.greenLight : _T.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                size: 16,
                color: isCompleted ? _T.green : Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              isLoading
                  ? 'Saving…'
                  : isCompleted
                      ? 'Completed!'
                      : 'Mark complete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCompleted ? _T.green : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color mutedColor;
  final Color textColor;
  final VoidCallback onTap;

  const _OutlineBtn(this.icon, this.label, this.bgColor, this.borderColor,
      this.mutedColor, this.textColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: mutedColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _OutlineIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _OutlineIconBtn(
      this.icon, this.bgColor, this.borderColor, this.mutedColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 18, color: mutedColor),
      ),
    );
  }
}

class _TopbarPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _TopbarPillBtn(this.icon, this.label, this.bgColor, this.borderColor,
      this.mutedColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: mutedColor),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: mutedColor)),
          ],
        ),
      ),
    );
  }
}

class _TopbarIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopbarIconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconRight;
  final bool enabled;
  final bool isPrimary;
  final Color bgColor;
  final Color borderColor;
  final Color mutedColor;
  final Color textColor;
  final VoidCallback onTap;

  const _NavBtn({
    required this.label,
    required this.icon,
    required this.iconRight,
    required this.enabled,
    required this.isPrimary,
    required this.bgColor,
    required this.borderColor,
    required this.mutedColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = isPrimary ? Colors.white : textColor;
    final bg = isPrimary ? _T.green : bgColor;
    final bc = isPrimary ? Colors.transparent : borderColor;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bc),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!iconRight) ...[
                Icon(icon, size: 14, color: c),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (iconRight) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 14, color: c),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color mutedColor;
  final Color textColor;

  const _MobNavItem(this.icon, this.label, this.enabled, this.isPrimary,
      this.onTap, this.bgColor, this.borderColor, this.mutedColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isPrimary ? _T.green : bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isPrimary ? Colors.transparent : borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isPrimary ? Colors.white : mutedColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesTabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NotesTabBtn(this.label, this.icon, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? _T.green : _T.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? _T.green : _T.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizStat extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color mutedColor;

  const _QuizStat(this.value, this.label, this.textColor, this.mutedColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: mutedColor)),
      ],
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final int questionNumber;
  final Map<String, dynamic> question;
  final Color textColor;
  final Color borderColor;
  final Color bgColor;

  const _QuestionItem({
    required this.questionNumber,
    required this.question,
    required this.textColor,
    required this.borderColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final questionText = question['text'] as String? ?? '';
    final questionType = question['type'] as String? ?? 'mcq';
    final options = (question['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final correctAnswer = question['correctAnswer'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _T.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final optionText = option['text'] as String? ?? '';
              final isCorrect = option['isCorrect'] as bool? ?? false;
              
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? _T.greenLight.withOpacity(0.3) : bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? _T.green : borderColor,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrect ? _T.green : borderColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + optionIndex), // A, B, C, D
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCorrect ? _T.green : textColor,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isCorrect) ...[
                      const Spacer(),
                      Icon(Icons.check_circle, color: _T.green, size: 16),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _FloatingAIButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAIButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('Ask AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar helpers ───────────────────────────────────────────────────────────

// Same palette as the main sidebar (ResponsiveNavigationDrawer).
const Color _kSidebarForest = Color(0xFF0B6E4F);
const Color _kSidebarGreen = Color(0xFF0E8A5F);

Color _sidebarActiveFill(bool isDark) =>
    isDark ? const Color(0xFF12352A) : const Color(0xFFE8F5EE);

Color _sidebarActiveText(bool isDark) =>
    isDark ? const Color(0xFF6EE7B7) : _kSidebarForest;

Color _sidebarTint(Color c, bool isDark) =>
    isDark ? Color.lerp(c, Colors.white, 0.3)! : c;

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _SidebarItem(this.icon, this.label, this.active, this.onTap,
      {this.color = _kSidebarGreen});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? _sidebarActiveFill(isDark) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3.5,
                  height: active ? 28 : 0,
                  decoration: BoxDecoration(
                    color: _kSidebarForest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: active ? 6.5 : 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: color.withOpacity(active
                        ? (isDark ? 0.28 : 0.16)
                        : (isDark ? 0.18 : 0.09)),
                  ),
                  child: Icon(icon,
                      size: 18, color: _sidebarTint(color, isDark)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      letterSpacing: -0.2,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active
                          ? _sidebarActiveText(isDark)
                          : (isDark ? Colors.white : const Color(0xFF0F2233)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLesson extends StatelessWidget {
  final String title;
  final bool done;
  final bool current;
  final bool locked;

  const _SidebarLesson(this.title, this.done, this.current,
      {this.locked = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimmed =
        isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF94A3B8);
    final normal =
        isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF334155);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: current ? _sidebarActiveFill(isDark) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            locked
                ? Icons.lock_outline_rounded
                : (done
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_outline_rounded),
            size: 17,
            color: locked
                ? dimmed
                : (done || current
                    ? _sidebarTint(_kSidebarGreen, isDark)
                    : dimmed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                color: locked
                    ? dimmed
                    : (current ? _sidebarActiveText(isDark) : normal),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model helpers ────────────────────────────────────────────────────────

class _MaterialItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? url;

  /// Lesson notes open the Notes tab instead of the generic file viewer, so
  /// text-only notes (no PDF) still open something
  final bool isNotes;

  const _MaterialItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.url,
    this.isNotes = false,
  });
}