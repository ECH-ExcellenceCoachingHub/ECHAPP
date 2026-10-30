import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/services/assistant_voice.dart';

/// Modern Widget to display individual chat messages with avatars and animations
class AIChatMessageWidget extends StatefulWidget {
  final AIChatMessage message;
  final bool isCurrentUser;

  const AIChatMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  State<AIChatMessageWidget> createState() => _AIChatMessageWidgetState();
}

class _AIChatMessageWidgetState extends State<AIChatMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AssistantVoice _voice;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.isCurrentUser ? const Offset(0.3, 0.1) : const Offset(-0.3, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _voice = AssistantVoice(onSpeakingChanged: (speaking) {
      if (mounted) setState(() => _isSpeaking = speaking);
    });

    // Staggered animation for better visual flow
    Future.delayed(Duration(milliseconds: widget.isCurrentUser ? 100 : 0), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (widget.message.sender == 'ai' && !_isSpeaking) {
      await _voice.speak(widget.message.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Row(
            mainAxisAlignment:
                widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Avatar for AI messages
              if (!widget.isCurrentUser)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

              // Enhanced Message bubble with modern design
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: widget.isCurrentUser
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary,
                              AppTheme.primaryDark,
                            ],
                          )
                        : (isDarkMode 
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.darkCard,
                                  AppTheme.darkSurface,
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.card,
                                  AppTheme.surface,
                                ],
                              )),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: widget.isCurrentUser
                          ? const Radius.circular(24)
                          : const Radius.circular(6),
                      bottomRight: widget.isCurrentUser
                          ? const Radius.circular(6)
                          : const Radius.circular(24),
                    ),
                    boxShadow: [
                      // Primary shadow
                      BoxShadow(
                        color: widget.isCurrentUser
                            ? AppTheme.primary.withOpacity(0.4)
                            : (isDarkMode 
                                ? Colors.black.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.2)),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      // Subtle highlight
                      BoxShadow(
                        color: widget.isCurrentUser
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isCurrentUser
                          ? Colors.transparent
                          : (isDarkMode
                              ? AppTheme.primary.withOpacity(0.2)
                              : AppTheme.primary.withOpacity(0.1)),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attachment preview
                      if (widget.message.attachmentPath != null) ...[  
                        _buildAttachmentPreview(isDarkMode),
                        const SizedBox(height: 8),
                      ],
                      // Message content
                      Text(
                        widget.message.message,
                        style: TextStyle(
                          color: widget.isCurrentUser
                              ? Colors.white
                              : (isDarkMode ? AppTheme.darkTextPrimary : AppTheme.blackColor),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Timestamp and context indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(widget.message.timestamp),
                            style: TextStyle(
                              color: widget.isCurrentUser
                                  ? Colors.white70
                                  : (isDarkMode ? AppTheme.darkTextSecondary : Colors.grey[600]),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.message.isContextAware) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.isCurrentUser
                                    ? Colors.white24
                                    : (isDarkMode 
                                        ? AppTheme.primary.withOpacity(0.2)
                                        : AppTheme.primary.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: widget.isCurrentUser
                                    ? Colors.white70
                                    : AppTheme.primary,
                              ),
                            ),
                          ],
                          // Speaker icon for AI messages
                          if (!widget.isCurrentUser) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              iconSize: 16,
                              onPressed: _speak,
                              icon: Icon(
                                _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                color: widget.isCurrentUser
                                    ? Colors.white70
                                    : AppTheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Avatar for user messages
              if (widget.isCurrentUser)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue,
                          Colors.purple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(bool isDarkMode) {
    final isImage = widget.message.attachmentType == 'image';
    final attachPath = widget.message.attachmentPath!;
    final name = widget.message.attachmentName ?? attachPath.split(RegExp(r'[/\\]')).last;

    if (isImage) {
      final isRemote = attachPath.startsWith('http://') || attachPath.startsWith('https://');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isRemote
            ? Image.network(
                mediaProxyUrl(attachPath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => _docChip(name, isDarkMode),
              )
            : Image.file(
                File(attachPath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _docChip(name, isDarkMode),
              ),
      );
    }

    return _docChip(name, isDarkMode);
  }

  Widget _docChip(String name, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
