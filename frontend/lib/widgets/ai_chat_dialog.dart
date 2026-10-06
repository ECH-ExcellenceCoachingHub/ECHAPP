import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_messages_list.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_input_widget.dart';
import 'package:excellencecoachinghub/widgets/voice_chat_widget.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Modern AI Chat Dialog Widget with Enhanced Glass Morphism Effect
class ModernAIChatDialog extends StatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final List<Section>? allSections;
  final Map<String, List<Lesson>>? sectionLessons;
  final AIChatService chatService;
  final String conversationId;
  final VoidCallback onClose;
  final GlobalKey<StudentGuideWidgetState>? guideKey;
  final AIChatContext? context;

  /// Sent automatically once the chat opens (e.g. "Explain this term").
  final String? initialPrompt;

  const ModernAIChatDialog({
    super.key,
    this.currentCourse,
    this.currentLesson,
    this.allSections,
    this.sectionLessons,
    required this.chatService,
    required this.conversationId,
    required this.onClose,
    this.guideKey,
    this.context,
    this.initialPrompt,
  });

  @override
  State<ModernAIChatDialog> createState() => _ModernAIChatDialogState();
}

class _ModernAIChatDialogState extends State<ModernAIChatDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  List<AIChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showVoiceChat = false;
  bool _isTyping = false;
  bool _isSpeaking = false;
  bool _isMuted = false;
  bool _showScrollToBottom = false;
  final ScrollController _chatScrollController = ScrollController();
  late FlutterTts _flutterTts;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-GB");
    _flutterTts.setSpeechRate(0.5); // Natural speed
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0); // Normal pitch for a male voice
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
    
    // Try to set a male British voice explicitly if available
    _flutterTts.getVoices.then((voices) {
      try {
        final maleVoice = voices.firstWhere(
          (voice) => 
            (voice['name'].toString().toLowerCase().contains('male') || 
             voice['name'].toString().toLowerCase().contains('daniel') ||
             voice['name'].toString().toLowerCase().contains('george') ||
             voice['name'].toString().toLowerCase().contains('arthur')) &&
            (voice['locale'].toString().toLowerCase().contains('gb') || 
             voice['name'].toString().toLowerCase().contains('british')),
          orElse: () => voices.firstWhere(
            (voice) => 
              voice['name'].toString().toLowerCase().contains('male') || 
              voice['name'].toString().toLowerCase().contains('daniel'),
            orElse: () => voices.first,
          ),
        );
        _flutterTts.setVoice({"name": maleVoice['name'], "locale": maleVoice['locale']});
      } catch (e) {
        print('Error setting male voice: $e');
      }
    });
    
    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _headerAnimationController.forward();
      });
    });
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _chatScrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _speakMessage(String message) {
    if (_isMuted) return;
    _flutterTts.stop();
    _flutterTts.speak(message);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _flutterTts.stop();
    }
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _updateGuideState(String message) {
    if (widget.guideKey?.currentState == null) return;
    
    final msg = message.toLowerCase();
    StudentGuideState state = StudentGuideState.idle;
    
    if (msg.contains('congratulations') || msg.contains('excellent') || msg.contains('great job') || msg.contains('🎉')) {
      state = StudentGuideState.success;
    } else if (msg.contains('thinking') || msg.contains('let me see') || msg.contains('analyzing')) {
      state = StudentGuideState.thinking;
    } else if (msg.contains('hello') || msg.contains('hi ') || msg.contains('welcome')) {
      state = StudentGuideState.greeting;
    } else if (msg.contains('don\'t give up') || msg.contains('try again')) {
      state = StudentGuideState.encouraging;
    } else if (msg.contains('level up') || msg.contains('unlocked')) {
      state = StudentGuideState.levelUp;
    } else if (msg.contains('hint') || msg.contains('tip')) {
      state = StudentGuideState.hintReady;
    } else {
      state = StudentGuideState.cheer;
    }
    
    widget.guideKey!.currentState!.updateState(state, message: null); // We don't want to double bubbles if possible, but guide update triggers movement
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await widget.chatService.getConversation(widget.conversationId);
      setState(() {
        _messages = messages;
      });
      
      if (messages.isEmpty) {
        await _sendWelcomeMessage();
      }
      final prompt = widget.initialPrompt?.trim();
      if (prompt != null && prompt.isNotEmpty && mounted) {
        await _handleSendMessage(prompt);
      }
    } catch (e) {
      print('Error loading initial messages: $e');
      _showErrorMessage('Failed to load chat history');
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final chatContext = widget.context ?? AIChatContext(
      currentCourse: widget.currentCourse,
      currentLesson: widget.currentLesson,
      allSections: widget.allSections,
      sectionLessons: widget.sectionLessons,
    );

    String message;
    
    if (chatContext.isPlatformSupport) {
      message = 'Hello! I\'m your Platform Support Assistant. I\'m here to help you navigate the Excellence Coaching Hub platform. I can assist you with: enrolling in courses, making payments, accessing video lessons, taking exams, managing your account, and any other platform-related questions. How can I help you today?';
    } else {
      message = 'Hello! I\'m your AI Learning Assistant. ';
      
      if (widget.currentCourse != null) {
        message += 'I see you\'re studying "${widget.currentCourse!.title}". ';
        
        if (widget.currentLesson != null) {
          message += 'Currently working on "${widget.currentLesson!.title}". ';
        }
        
        if (widget.allSections != null && widget.allSections!.isNotEmpty) {
          message += 'I have access to all ${widget.allSections!.length} sections and their lessons. ';
        }
      } else if (widget.currentLesson != null) {
        message += 'I see you\'re studying "${widget.currentLesson!.title}". ';
      }
      
      message += 'Ask me anything about your learning materials, and I\'ll help you summarize lessons, understand concepts, or answer any questions!';
    }

    final aiMessage = AIChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'ai',
      message: message,
      timestamp: DateTime.now(),
      isContextAware: true,
    );

    setState(() {
      _messages.add(aiMessage);
    });

    _updateGuideState(aiMessage.message);
    await _flutterTts.speak(aiMessage.message);
  }

  Future<void> _handleSendWithFile(String message, File file, String fileType, String fileName) async {
    final userMessage = AIChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: message.isNotEmpty ? message : 'Please analyze this $fileType.',
      timestamp: DateTime.now(),
      isContextAware: false,
      attachmentPath: file.path,
      attachmentType: fileType,
      attachmentName: fileName,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });

    if (widget.guideKey?.currentState != null) {
      widget.guideKey!.currentState!.updateState(StudentGuideState.thinking);
    }

    try {
      final chatContext = widget.context ?? AIChatContext(
        currentCourse: widget.currentCourse,
        currentLesson: widget.currentLesson,
        allSections: widget.allSections,
        sectionLessons: widget.sectionLessons,
      );

      final aiResponse = await widget.chatService.sendMessageWithFile(
        widget.conversationId,
        userMessage.message,
        file,
        fileType,
        chatContext,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
        _isTyping = false;
      });

      _updateGuideState(aiResponse.message);
      await _flutterTts.speak(aiResponse.message);
    } catch (e) {
      print('Error sending file message: $e');
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      _showErrorMessage('Failed to send attachment');
    }
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = AIChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: message.trim(),
      timestamp: DateTime.now(),
      isContextAware: false,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });

    // Character thinking movement
    if (widget.guideKey?.currentState != null) {
      widget.guideKey!.currentState!.updateState(StudentGuideState.thinking);
    }

    try {
      final chatContext = widget.context ?? AIChatContext(
        currentCourse: widget.currentCourse,
        currentLesson: widget.currentLesson,
      );

      final aiResponse = await widget.chatService.sendMessage(
        widget.conversationId,
        message.trim(),
        chatContext,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
        _isTyping = false;
      });

      _updateGuideState(aiResponse.message);
      await _flutterTts.speak(aiResponse.message);
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      _showErrorMessage('Failed to send message');
    }
  }

  void _toggleVoiceChat() {
    setState(() {
      _showVoiceChat = !_showVoiceChat;
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 1024;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: isDesktop ? 650 : screenWidth * 0.85,
        height: isDesktop ? math.min(800.0, screenHeight * 0.75) : screenHeight * 0.75,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: isDarkMode 
            ? AppTheme.darkCard.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
          border: Border.all(
            color: isDarkMode 
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            // Deep shadow for depth
            BoxShadow(
              color: isDarkMode 
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            // Primary accent glow
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            // Subtle inner light
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDarkMode 
                    ? AppTheme.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.4),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                    ? [
                        AppTheme.darkCard.withOpacity(0.8),
                        AppTheme.darkSurface.withOpacity(0.9),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        AppTheme.surface.withOpacity(0.8),
                      ],
                ),
              ),
              child: Column(
                children: [
                  // Enhanced Chat Header with Modern Glass Effect
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(_headerSlideAnimation),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryDark,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          // Enhanced header shadow
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                          // Subtle inner glow
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'AI Learning Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.currentCourse != null)
                                  Text(
                                    widget.currentCourse!.title,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleMute,
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            tooltip: _isMuted ? 'Unmute' : 'Mute',
                          ),
                          IconButton(
                            onPressed: _toggleVoiceChat,
                            icon: Icon(
                              _showVoiceChat ? Icons.chat : Icons.mic,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Chat messages area or voice chat widget
                  if (_showVoiceChat)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: VoiceChatWidget(
                            conversationId: widget.conversationId,
                            isSpeaking: _isSpeaking,
                            isMuted: _isMuted,
                            onToggleMute: _toggleMute,
                            context: {
                              'courseTitle': widget.currentCourse?.title ?? '',
                              'lessonTitle': widget.currentLesson?.title ?? '',
                              'currentLessonNotes': widget.currentLesson?.notes ?? '',
                              'allSections': widget.allSections,
                              'sectionLessons': widget.sectionLessons,
                            },
                            onAIResponse: (text) {
                              _updateGuideState(text);
                              _speakMessage(text);
                            },
                            onVoiceMessageReceived: (text) {
                              final userMessage = AIChatMessage(
                                id: 'voice_user_${DateTime.now().millisecondsSinceEpoch}',
                                sender: 'user',
                                message: text,
                                timestamp: DateTime.now(),
                                isContextAware: false,
                              );
                              
                              setState(() {
                                _messages.add(userMessage);
                              });

                              if (widget.guideKey?.currentState != null) {
                                widget.guideKey!.currentState!.updateState(StudentGuideState.thinking);
                              }
                            },
                            onTextMessageReceived: (text) {
                              final aiMessage = AIChatMessage(
                                id: 'voice_ai_${DateTime.now().millisecondsSinceEpoch}',
                                sender: 'ai',
                                message: text,
                                timestamp: DateTime.now(),
                                isContextAware: true,
                              );
                              
                              setState(() {
                                _messages.add(aiMessage);
                              });

                              _updateGuideState(aiMessage.message);
                              _speakMessage(aiMessage.message);
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Stack(
                        children: [
                          AIChatMessagesList(
                            messages: _messages,
                            currentUserId: 'user',
                            onScrollPositionChanged: (show) {
                              setState(() {
                                _showScrollToBottom = show;
                              });
                            },
                          ),
                          if (_isTyping)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_showScrollToBottom)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: _scrollToBottom,
                                child: const Icon(Icons.arrow_downward, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Enhanced Input area
                  if (!_showVoiceChat)
                    AIChatInputWidget(
                      onSendMessage: _handleSendMessage,
                      isLoading: _isLoading,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}