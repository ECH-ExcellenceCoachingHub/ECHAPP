import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/services/api/course_builder_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';
import 'package:excellencecoachinghub/services/achievement_sound_service.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exam_question_details_screen.dart';
import 'package:excellencecoachinghub/widgets/quiz/drag_drop_question_widget.dart';

class ExamTakingScreen extends StatefulWidget {
  final Map<String, dynamic> exam;

  /// When set, the quiz is an AI Course Builder draft: questions come from the
  /// draft and the attempt is graded without being saved (teacher preview).
  final String? previewItemId;

  const ExamTakingScreen({
    super.key,
    required this.exam,
    this.previewItemId,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _questions = [];
  final Map<int, dynamic> _answers = {}; // Stores selectedOption (Number/String) and answerText (String) for each question
  final Map<int, TextEditingController> _textControllers = {}; // Controllers for text input fields
  int _currentQuestionIndex = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Security & Anti-cheating
  int _warningCount = 0;
  final int _maxWarnings = 3;
  bool _isWarningDialogVisible = false;

  // Helper function to convert question map to Question object
  Question _convertMapToQuestion(Map<String, dynamic> questionMap) {
    return Question(
      id: questionMap['_id']?.toString() ?? questionMap['id']?.toString() ?? '',
      examId: questionMap['examId']?.toString() ?? '',
      question: questionMap['question'] ?? '',
      type: questionMap['type'] ?? 'mcq',
      questionImage: questionMap['questionImage'],
      questionAudio: questionMap['questionAudio'],
      questionVideo: questionMap['questionVideo'],
      options: questionMap['options'] != null 
        ? (questionMap['options'] as List).map((e) => Option.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      dragDropItems: questionMap['dragDropItems'] != null
        ? (questionMap['dragDropItems'] as List).map((e) => DragDropItem.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      dropZones: questionMap['dropZones'] != null
        ? (questionMap['dropZones'] as List).map((e) => DropZone.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      matchingPairs: questionMap['matchingPairs'] != null
        ? (questionMap['matchingPairs'] as List).map((e) => MatchingPair.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      correctOrder: questionMap['correctOrder'] != null
        ? (questionMap['correctOrder'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      hotspots: questionMap['hotspots'] != null
        ? (questionMap['hotspots'] as List).map((e) => Hotspot.fromJson(e as Map<String, dynamic>)).toList()
        : null,
      hotspotImage: questionMap['hotspotImage'],
      correctAnswer: questionMap['correctAnswer'],
      points: questionMap['points'] ?? 1,
      partialCredit: questionMap['partialCredit'] ?? false,
      explanation: questionMap['explanation'] ?? '',
      difficulty: questionMap['difficulty'] ?? 'medium',
      category: questionMap['category'],
      tags: questionMap['tags'] != null 
        ? List<String>.from(questionMap['tags'])
        : null,
      timeLimit: questionMap['timeLimit'] ?? 0,
      maxAttempts: questionMap['maxAttempts'] ?? 1,
      randomizeOptions: questionMap['randomizeOptions'] ?? false,
      section: questionMap['section'],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureMode();
    _loadExamData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableSecureMode();
    _timer?.cancel();
    // Dispose all text controllers
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _enableSecureMode() async {
    // Enable Fullscreen
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Disable Screen Capture/Recording (Android/iOS only)
    // Note: requires flutter_windowmanager for Android, but not in pubspec.
    // We'll stick to basic Flutter lifecycle for now.
  }

  void _disableSecureMode() async {
    // Restore System UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Detect if user leaves the app or changes tab (Web)
    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused || 
        state == AppLifecycleState.hidden) {
      _handleSecurityViolation("App backgrounded or tab switched");
    }
  }

  void _handleSecurityViolation(String reason) {
    if (_isSubmitting || _isLoading || _isWarningDialogVisible) return;
    
    setState(() {
      _warningCount++;
    });

    if (_warningCount >= _maxWarnings) {
      _autoSubmitDueToViolation();
    } else {
      _showWarningDialog(reason);
    }
  }

  void _autoSubmitDueToViolation() {
    _timer?.cancel();
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Security Violation', style: TextStyle(color: Colors.red)),
          content: Text('You have exceeded the maximum number of warnings ($_maxWarnings). Your exam will be submitted automatically.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitExam();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showWarningDialog(String reason) {
    _isWarningDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Warning: Security Violation', style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are not allowed to switch tabs or leave the exam screen.'),
            const SizedBox(height: 12),
            Text('Warning $_warningCount of $_maxWarnings', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Further violations will result in automatic submission.', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _isWarningDialogVisible = false;
              Navigator.of(context).pop();
              // Re-enable fullscreen in case it was lost
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  /// Questions answered by typing (kept in a persistent text controller).
  bool _isTextType(dynamic type) =>
      type == 'fill_blank' || type == 'open' || type == 'essay' || type == 'programming';

  Future<Map<String, dynamic>> _loadExamData() async {
    try {
      final quizData = widget.previewItemId != null
          ? {'data': {'questions': (await CourseBuilderService().previewItem(widget.previewItemId!))['questions']}}
          : await QuizService.getQuiz(widget.exam['id']);
      
      final questions = (quizData['data']?['questions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      
      setState(() {
        _questions = questions;
        _timeRemaining = (widget.exam['timeLimit'] ?? 30) * 60; // Convert minutes to seconds
        _isLoading = false;
        
        // Initialize text controllers for text input questions
        for (int i = 0; i < _questions.length; i++) {
          final question = _questions[i];
          if (_isTextType(question['type'])) {
            if (!_textControllers.containsKey(i)) {
              // Initialize with existing answer if available
              String initialText = '';
              if (_answers[i] != null) {
                if (_answers[i] is Map) {
                  initialText = _answers[i]['answerText']?.toString() ?? '';
                } else {
                  initialText = _answers[i]?.toString() ?? '';
                }
              }
              _textControllers[i] = TextEditingController(text: initialText);
              
              // Add listener to update answers when text changes
              _textControllers[i]!.addListener(() {
                _updateAnswer(i, _textControllers[i]!.text);
              });
            }
          }
          // Note: Drag-drop questions don't need text controllers as they use DragDropQuestionWidget
        }
      });

      // Start timer if time limit is set
      if ((widget.exam['timeLimit'] ?? 0) > 0) {
        _startTimer();
      }

      return quizData;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      rethrow;
    }
  }

  void _startTimer() {
    if (_timeRemaining <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _submitExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _selectAnswer(dynamic answer) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    setState(() {
      if (currentQuestion['type'] == 'mcq' || currentQuestion['type'] == 'true_false') {
        // For MCQ and True/False, store the selected option index
        int optionIndex = 0;
        if (currentQuestion['type'] == 'true_false') {
          // For True/False, use simple index mapping
          optionIndex = answer == 'True' ? 0 : 1;
        } else {
          // For MCQ, find the option object that matches the answer text
          final options = currentQuestion['options'] as List<dynamic>? ?? [];
          for (int i = 0; i < options.length; i++) {
            final option = options[i];
            final optionText = option is Map ? option['text'] ?? option.toString() : option.toString();
            if (optionText == answer) {
              optionIndex = i;
              break;
            }
          }
        }
        _answers[_currentQuestionIndex] = {
          'selectedOption': optionIndex,
          'answerText': answer,
        };
      } else if (currentQuestion['type'] == 'drag_drop') {
        // For drag-drop questions, store list of drag answers
        _answers[_currentQuestionIndex] = {
          'dragAnswers': answer,
          'answerText': '', // Not used for drag-drop
        };
      } else if (_isTextType(currentQuestion['type'])) {
        // For fill-in-blank and open questions, store text answer
        _answers[_currentQuestionIndex] = {
          'selectedOption': answer,
          'answerText': answer,
        };
        
        // Also update the text controller if it exists
        if (_textControllers.containsKey(_currentQuestionIndex)) {
          _textControllers[_currentQuestionIndex]!.text = answer.toString();
        }
      }
    });
  }

  void _updateAnswer(int questionIndex, String text) {
    final question = _questions[questionIndex];
    if (_isTextType(question['type'])) {
      setState(() {
        _answers[questionIndex] = {
          'selectedOption': text,
          'answerText': text,
        };
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      // Ensure text controller exists for the next question if it's a text input type
      final nextQuestion = _questions[_currentQuestionIndex + 1];
      if (_isTextType(nextQuestion['type'])) {
        if (!_textControllers.containsKey(_currentQuestionIndex + 1)) {
          String initialText = '';
          if (_answers[_currentQuestionIndex + 1] != null) {
            if (_answers[_currentQuestionIndex + 1] is Map) {
              initialText = _answers[_currentQuestionIndex + 1]['answerText']?.toString() ?? '';
            } else {
              initialText = _answers[_currentQuestionIndex + 1]?.toString() ?? '';
            }
          }
          _textControllers[_currentQuestionIndex + 1] = TextEditingController(text: initialText);
          
          // Add listener to update answers when text changes
          _textControllers[_currentQuestionIndex + 1]!.addListener(() {
            _updateAnswer(_currentQuestionIndex + 1, _textControllers[_currentQuestionIndex + 1]!.text);
          });
        }
      }
      
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      // Ensure text controller exists for the previous question if it's a text input type
      final prevQuestion = _questions[_currentQuestionIndex - 1];
      if (_isTextType(prevQuestion['type'])) {
        if (!_textControllers.containsKey(_currentQuestionIndex - 1)) {
          String initialText = '';
          if (_answers[_currentQuestionIndex - 1] != null) {
            if (_answers[_currentQuestionIndex - 1] is Map) {
              initialText = _answers[_currentQuestionIndex - 1]['answerText']?.toString() ?? '';
            } else {
              initialText = _answers[_currentQuestionIndex - 1]?.toString() ?? '';
            }
          }
          _textControllers[_currentQuestionIndex - 1] = TextEditingController(text: initialText);
          
          // Add listener to update answers when text changes
          _textControllers[_currentQuestionIndex - 1]!.addListener(() {
            _updateAnswer(_currentQuestionIndex - 1, _textControllers[_currentQuestionIndex - 1]!.text);
          });
        }
      }
      
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitExam() async {
    if (_isSubmitting) return;

    // Ensure all text field values are synced to answers before submitting
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if ((_isTextType(question['type'])) && _textControllers.containsKey(i)) {
        final textValue = _textControllers[i]!.text;
        if (textValue.isNotEmpty) {
          _answers[i] = {
            'selectedOption': textValue,
            'answerText': textValue,
          };
        }
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare answers in required format
      final answers = _answers.entries
          .where((entry) => entry.value != null)
          .map((entry) {
            final question = _questions[entry.key];
            final answerData = entry.value;
            
            // Handle the new answer format (Map with selectedOption and answerText)
            if (answerData is Map) {
              // Handle drag-drop questions specifically
              if (question['type'] == 'drag_drop') {
                return {
                  'questionId': question['_id']?.toString() ?? question['id']?.toString(),
                  'dragAnswers': answerData['dragAnswers'] ?? [],
                };
              }
              
              return {
                'questionId': question['_id']?.toString() ?? question['id']?.toString(),
                'selectedOption': answerData['selectedOption'],
                'answerText': answerData['answerText'],
              };
            } else {
              // Fallback for old format
              if (question['type'] == 'mcq' || question['type'] == 'true_false') {
                int answerIndex = 0;
                if (question['type'] == 'true_false') {
                  // For True/False, use simple index mapping
                  answerIndex = answerData.toString() == 'True' ? 0 : 1;
                } else {
                  // For MCQ, find option index by comparing with option text
                  final options = question['options'] as List<dynamic>? ?? [];
                  for (int i = 0; i < options.length; i++) {
                    final option = options[i];
                    final optionText = option is Map ? option['text'] ?? option.toString() : option.toString();
                    if (optionText == answerData.toString()) {
                      answerIndex = i;
                      break;
                    }
                  }
                }
                return {
                  'questionId': question['_id']?.toString() ?? question['id']?.toString(),
                  'selectedOption': answerIndex,
                };
              } else {
                return {
                  'questionId': question['_id']?.toString() ?? question['id']?.toString(),
                  'selectedOption': answerData.toString(),
                  'answerText': answerData.toString(),
                };
              }
            }
          })
          .toList();

      final result = widget.previewItemId != null
          ? await CourseBuilderService().previewSubmit(widget.previewItemId!, answers)
          : await QuizService.submitQuiz(
              widget.exam['id'],
              answers,
            );

      _disableSecureMode();

      if (mounted) {
        // Navigate to results screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultsScreen(
              exam: widget.exam,
              result: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit exam: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // The screen is usually already replaced by the results page here.
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary.withOpacity(0.1),
                AppTheme.getBackgroundColor(context),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preparing Your Exam',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context)
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading questions and setting up your test environment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getTextColor(context).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.getBackgroundColor(context),
                AppTheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      size: 50,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Questions Available',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context)
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This exam doesn\'t have any questions configured yet. Please contact your instructor or try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.greyColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(fontSize: 16),
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

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswerData = _answers[_currentQuestionIndex];
    final selectedAnswer = selectedAnswerData is Map ? selectedAnswerData['answerText'] : selectedAnswerData;
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final bool? shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Exam?'),
            content: const Text('Are you sure you want to exit the exam? Your progress will be lost and your attempt might be counted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exit Exam'),
              ),
            ],
          ),
        );
        
        if ((shouldPop ?? false) && context.mounted) {
          _disableSecureMode();
          Navigator.of(context).pop();
        }
      },
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          // Block common cheating shortcuts
          if (event is KeyDownEvent) {
            final isControlPressed = event.logicalKey == LogicalKeyboardKey.controlLeft || 
                                     event.logicalKey == LogicalKeyboardKey.controlRight ||
                                     HardwareKeyboard.instance.isControlPressed;
            final isAltPressed = event.logicalKey == LogicalKeyboardKey.altLeft || 
                                 event.logicalKey == LogicalKeyboardKey.altRight ||
                                 HardwareKeyboard.instance.isAltPressed;
            
            // Block Ctrl+C, Ctrl+V, Ctrl+U (view source), F12, Ctrl+Shift+I, Alt+Tab
            if (isControlPressed && (
                event.logicalKey == LogicalKeyboardKey.keyC || 
                event.logicalKey == LogicalKeyboardKey.keyV ||
                event.logicalKey == LogicalKeyboardKey.keyU ||
                event.logicalKey == LogicalKeyboardKey.keyI ||
                event.logicalKey == LogicalKeyboardKey.keyJ)) {
              _handleSecurityViolation("Prohibited keyboard shortcut used");
            }
            
            if (event.logicalKey == LogicalKeyboardKey.f12 || 
                event.logicalKey == LogicalKeyboardKey.f11) {
              _handleSecurityViolation("Prohibited function key used");
            }
            
            if (isAltPressed && event.logicalKey == LogicalKeyboardKey.tab) {
               _handleSecurityViolation("Alt+Tab detected");
            }
          }
        },
        child: Listener(
          onPointerDown: (event) {
            // Block right click (secondary button)
            if (event.buttons == 2) { // 2 is for secondary mouse button (right-click)
              _handleSecurityViolation("Right-click is prohibited");
            }
          },
          child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.getBackgroundColor(context),
                AppTheme.primary.withOpacity(0.03),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildModernAppBar(context),
                
                // Progress Section
                _buildProgressSection(progress),
                
                // Question Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildQuestionCard(currentQuestion, selectedAnswer),
                  ),
                ),
                
                // Navigation Section
                _buildNavigationSection(),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  // Helper methods for building UI components
  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          
          // Exam title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.exam['type'].toString().toUpperCase()} EXAM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Timer
          if ((widget.exam['timeLimit'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining < 300 
                  ? Colors.red.shade500 
                  : _timeRemaining < 600 
                    ? Colors.orange.shade500 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _timeRemaining < 300 ? Icons.timer : Icons.access_time,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress bar with percentage
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context)
                ),
              ),
              const Spacer(),
              Text(
                '${(_currentQuestionIndex + 1)}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${(progress.isFinite ? (progress * 100) : 0).toInt()}%',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Question navigation dots
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentQuestionIndex;
                final isAnswered = _answers[index] != null;
                final isVisited = index <= _currentQuestionIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      if (isVisited) {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent 
                          ? AppTheme.primary 
                          : isAnswered 
                            ? Colors.green 
                            : isVisited 
                              ? Colors.grey.shade300 
                              : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? AppTheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent || isAnswered 
                              ? Colors.white 
                              : AppTheme.getTextColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
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

  Widget _buildQuestionCard(Map<String, dynamic> question, dynamic selectedAnswer) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.question_mark,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (question['section'] != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        question['section']!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${question['points'] ?? 1} pts',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Question text - make it flexible so it doesn't push options out
            Flexible(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (question['type'] == 'fill_blank')
                      _buildFillBlankQuestion(question['text'] ?? '', selectedAnswer)
                    else
                      Text(
                        question['text'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppTheme.getTextColor(context)
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Different UI for different question types - give more flex to options
            if (question['type'] == 'mcq' || question['type'] == 'true_false')
              // MCQ and True/False Options
              Expanded(
                flex: 2,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _getOptionsCount(question),
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final optionText = _getOptionText(question, index);
                    final isSelected = selectedAnswer == optionText;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? AppTheme.primary 
                            : AppTheme.getBorderColor(context),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected 
                          ? AppTheme.primary.withOpacity(0.08) 
                          : AppTheme.getCardColor(context),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectAnswer(optionText),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Option indicator
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? AppTheme.primary 
                                      : AppTheme.getBorderColor(context).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: isSelected 
                                        ? AppTheme.primary 
                                        : AppTheme.getBorderColor(context),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                                ),
                                const SizedBox(width: 12),
                                
                                // Option text
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                      color: isSelected 
                                        ? AppTheme.primary 
                                        : AppTheme.getTextColor(context),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (question['type'] == 'fill_blank')
              // Fill-in-the-blank Text Field
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  controller: _textControllers[_currentQuestionIndex] ?? TextEditingController(text: selectedAnswer?.toString()),
                  onChanged: (value) => _selectAnswer(value),
                  decoration: InputDecoration(
                    hintText: 'Fill in the blank...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              )
            else if (question['type'] == 'drag_drop')
              // Drag and Drop Question
              Expanded(
                flex: 2,
                child: DragDropQuestionWidget(
                  question: _convertMapToQuestion(question),
                  onAnswerChanged: (answer) => _selectAnswer(answer),
                  currentAnswer: selectedAnswer is Map ? selectedAnswer['dragAnswers'] : null,
                  isReadOnly: false,
                ),
              )
            else
              // Open Question Text Field
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  controller: _textControllers[_currentQuestionIndex] ?? TextEditingController(text: selectedAnswer?.toString()),
                  onChanged: (value) => _selectAnswer(value),
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    contentPadding: const EdgeInsets.all(16),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get options count for different question types
  int _getOptionsCount(Map<String, dynamic> question) {
    if (question['type'] == 'true_false') {
      // For True/False questions, always return 2 (True and False)
      return 2;
    }
    // For MCQ and other types, return the actual options count
    final options = question['options'] as List<dynamic>? ?? [];
    return options.length;
  }

  // Helper method to get option text for different question types
  String _getOptionText(Map<String, dynamic> question, int index) {
    if (question['type'] == 'true_false') {
      // For True/False questions, return "True" or "False"
      return index == 0 ? 'True' : 'False';
    }
    // For MCQ and other types, extract text from option object
    final options = question['options'] as List<dynamic>? ?? [];
    if (index < options.length) {
      final option = options[index];
      if (option is Map) {
        return option['text'] ?? option.toString();
      }
      return option.toString();
    }
    return '';
  }

  Widget _buildFillBlankQuestion(String questionText, dynamic selectedAnswer) {
    // Split the question text by underscores or use a placeholder
    final parts = questionText.split('_____');
    
    // Get the current text from the controller if available
    String currentText = '';
    if (_textControllers.containsKey(_currentQuestionIndex)) {
      currentText = _textControllers[_currentQuestionIndex]!.text;
    } else {
      currentText = selectedAnswer?.toString() ?? '';
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppTheme.getTextColor(context),
        ),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                child: Container(
                  width: 100,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                  child: Text(
                    currentText,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: SizedBox(
              height: 45,
              child: OutlinedButton(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _currentQuestionIndex > 0 
                      ? AppTheme.greyColor 
                      : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Next/Submit button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentQuestionIndex < _questions.length - 1) {
                        _nextQuestion();
                      } else {
                        _submitExam();
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isSubmitting ? 0 : 4,
                ),
                child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentQuestionIndex < _questions.length - 1 
                            ? Icons.arrow_forward 
                            : Icons.check_circle,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentQuestionIndex < _questions.length - 1
                            ? 'Next Question'
                            : 'Submit Exam',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class ExamResultsScreen extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> result;

  const ExamResultsScreen({
    super.key,
    required this.exam,
    required this.result,
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    final sounds = AchievementSoundService.instance;
    if (widget.result['passed'] == true) {
      sounds.playSequence(AchievementSound.quizPassed, AchievementSound.xpGain);
    } else {
      sounds.play(AchievementSound.quizFailed);
    }
  }

  Future<void> _downloadCertificate() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final certificateRepo = CertificateRepository();
      
      // Fetch certificates for this course to find the one just earned
      final certificates = await certificateRepo.getCertificatesByCourse(widget.exam['courseId']);
      
      if (certificates.isNotEmpty) {
        // Try to find certificate for this specific exam, or just take the latest one
        final certificate = certificates.firstWhere(
          (c) => c.examId == widget.exam['id'],
          orElse: () => certificates.first,
        );
        
        final savePath = await certificateRepo.downloadAndSaveCertificate(
          certificate.id,
          fileName: 'certificate_${certificate.id}.pdf',
        );
        
        if (mounted && savePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certificate saved to: $savePath'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  final Uri uri = Uri.file(savePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate not yet available. It might take a few minutes to generate.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading certificate: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.result['passed'] ?? false;
    final percentage = (widget.result['percentage']?.toDouble() ?? 0.0);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isPassed 
                ? AppTheme.primary.withOpacity(0.1) 
                : Colors.red.shade50.withOpacity(0.3),
              AppTheme.getBackgroundColor(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with back button
                Row(
                  children: [
                    if (context.canPop())
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.getIconColor(context)),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Exam Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context)
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Main result card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Result status icon
                          _buildResultIcon(isPassed),
                          
                          const SizedBox(height: 24),
                          
                          // Result title
                          Text(
                            isPassed ? 'Congratulations!' : 'Keep Practicing!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? AppTheme.primary : Colors.red.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Result message
                          Text(
                            widget.result['message'] ?? 'Quiz completed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.getTextColor(context).withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Score card
                          _buildScoreCard(isPassed, percentage),
                          
                          const SizedBox(height: 24),
                          
                          // Performance breakdown
                          _buildPerformanceBreakdown(isPassed, percentage),
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          _buildActionButtons(context),
                        ],
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

  Widget _buildResultIcon(bool isPassed) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            isPassed 
              ? AppTheme.primary.withOpacity(0.3) 
              : Colors.red.shade200.withOpacity(0.5),
            isPassed 
              ? AppTheme.primary.withOpacity(0.1) 
              : Colors.red.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPassed ? AppTheme.primary : Colors.red.shade500,
          borderRadius: BorderRadius.circular(58),
          boxShadow: [
            BoxShadow(
              color: isPassed 
                ? AppTheme.primary.withOpacity(0.4) 
                : Colors.red.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isPassed ? Icons.celebration : Icons.tips_and_updates,
            size: 70,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(bool isPassed, double percentage) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context)
              ),
            ),
            const SizedBox(height: 16),
            
            // Large score display
            Text(
              '${widget.result['totalScore'] ?? 0}/${widget.result['maxScore'] ?? 0}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context)
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isPassed 
                  ? AppTheme.primary.withOpacity(0.1) 
                  : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  color: isPassed ? AppTheme.primary : Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      height: 16,
                      width: (percentage / 100) * constraints.maxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isPassed ? AppTheme.primary : Colors.red.shade500,
                            isPassed ? AppTheme.primaryDark : Colors.red.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status message
            Text(
              isPassed 
                ? 'You passed the exam! Great job!' 
                : 'You need ${((widget.exam['passingScore'] ?? 70 - percentage).clamp(0, 100)).toStringAsFixed(1)}% more to pass',
              style: TextStyle(
                fontSize: 16,
                color: isPassed ? AppTheme.primary : Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBreakdown(bool isPassed, double percentage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context)
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatRow('Total Points', '${widget.result['maxScore'] ?? 0}', Icons.star),
            const SizedBox(height: 12),
            _buildStatRow('Your Score', '${widget.result['totalScore'] ?? 0}', Icons.emoji_events, isGood: isPassed),
            const SizedBox(height: 12),
            _buildStatRow('Percentage', '${percentage.toStringAsFixed(1)}%', Icons.percent, isGood: isPassed),
            const SizedBox(height: 12),
            _buildStatRow('Status', isPassed ? 'Passed' : 'Not Passed', 
              isPassed ? Icons.check_circle : Icons.cancel, isGood: isPassed),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {bool? isGood}) {
    Color? valueColor;
    if (isGood != null) {
      valueColor = isGood ? AppTheme.primary : Colors.red.shade600;
    }
    
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context)
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final percentage = widget.result['percentage']?.toDouble() ?? 0.0;
    // Show download button only for final exams with score >= 50%
    final isFinalExam = widget.exam['type']?.toString().toLowerCase() == 'final';
    final isEligible = isFinalExam && percentage >= 50.0;

    return Column(
      children: [
        if (isEligible) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isDownloading ? null : _downloadCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), // Amber color for certificates
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Download Certificate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 24),
                SizedBox(width: 12),
                Text(
                  'Return to Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              // Navigate to question details screen to review answers
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamQuestionDetailsScreen(
                    examResult: widget.result,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.greyColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Review Answers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
