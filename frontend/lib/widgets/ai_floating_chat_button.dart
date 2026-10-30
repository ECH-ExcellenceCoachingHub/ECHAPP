import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/assistant_voice.dart';

/// Floating AI Chat Button that expands to full chat when clicked
class AIFloatingChatButton extends ConsumerStatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final List<Section>? allSections;
  final Map<String, List<Lesson>>? sectionLessons;
  final VoidCallback? onChatOpen;
  final bool showWelcome;

  const AIFloatingChatButton({
    super.key,
    this.currentCourse,
    this.currentLesson,
    this.allSections,
    this.sectionLessons,
    this.onChatOpen,
    this.showWelcome = false,
  });

  @override
  ConsumerState<AIFloatingChatButton> createState() => _AIFloatingChatButtonState();
}

class _AIFloatingChatButtonState extends ConsumerState<AIFloatingChatButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _welcomeController;
  late Animation<double> _welcomeScaleAnimation;
  bool _isExpanded = false;
  bool _showWelcomeBubble = false;
  late AssistantVoice _voice;
  late RealAIChatService _aiChatService;
  late String _conversationId;

  @override
  void initState() {
    super.initState();
    _aiChatService = RealAIChatService();
    _conversationId = 'conversation_${DateTime.now().millisecondsSinceEpoch}';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Enhanced pulse animation with breathing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _welcomeScaleAnimation = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOutBack,
    );

    _voice = AssistantVoice();

    if (widget.showWelcome) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showWelcomeBubble = true;
          });
          _welcomeController.forward();
          _speakWelcome();
          
          // Hide welcome bubble after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && _showWelcomeBubble) {
              _welcomeController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _showWelcomeBubble = false;
                  });
                }
              });
            }
          });
        }
      });
    }
  }

  void _speakWelcome() {
    String welcomeText = "Hello! I'm your AI learning assistant. I can help you summarize lessons, explain concepts, or answer any questions about your course. Just click me if you need help!";
    _voice.speak(welcomeText);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _welcomeController.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _toggleChat() {
    // The chat dialog greets the student itself; don't talk over it.
    _voice.stop();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _showWelcomeBubble) {
        _showWelcomeBubble = false;
        _welcomeController.reverse();
      }
    });
    
    if (_isExpanded) {
      _animationController.forward();
      _pulseController.stop(); // Stop pulse when expanded
    } else {
      _animationController.reverse();
      _pulseController.repeat(reverse: true); // Resume pulse when closed
    }
    
    if (widget.onChatOpen != null) {
      widget.onChatOpen!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Modern theme-aware label with animation
        Positioned(
          right: 12,
          bottom: 85,
          child: AnimatedOpacity(
            opacity: _isExpanded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.95),
                    AppTheme.accent.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Welcome Popup Bubble
        if (widget.showWelcome && _showWelcomeBubble)
          Positioned(
            right: 20,
            bottom: 120,
            child: ScaleTransition(
              scale: _welcomeScaleAnimation,
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "AI Tutor",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _welcomeController.reverse().then((_) {
                              if (mounted) {
                                setState(() {
                                  _showWelcomeBubble = false;
                                });
                              }
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hello! I can help you summarize this course and answer any questions. How can I assist you today?",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Enhanced floating chat button with modern glass morphism effect
        Positioned(
          right: 16,
          bottom: 16,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryDark,
                  ],
                ),
                boxShadow: [
                  // Primary glow effect
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  // Secondary accent glow
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  // Subtle ambient light
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Inner glow effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: _toggleChat,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    mini: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.8,
                            end: 1.0,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: RotationTransition(
                              turns: Tween<double>(
                                begin: 0.0,
                                end: 0.25,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutBack,
                              )),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _isExpanded
                          ? const Icon(Icons.close, key: ValueKey('close'), size: 24)
                          : const Icon(Icons.auto_awesome, key: ValueKey('chat'), size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Chat overlay (appears when expanded)
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleChat, // Close when tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on dialog
                    child: ModernAIChatDialog(
                      currentCourse: widget.currentCourse,
                      currentLesson: widget.currentLesson,
                      allSections: widget.allSections,
                      sectionLessons: widget.sectionLessons,
                      chatService: _aiChatService,
                      conversationId: _conversationId,
                      onClose: _toggleChat,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
