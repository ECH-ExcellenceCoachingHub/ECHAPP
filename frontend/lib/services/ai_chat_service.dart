import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// AI Chat Message model
class AIChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String message;
  final DateTime timestamp;
  final bool isContextAware; // Whether this message uses learning context
  final String? audioUrl; // URL for audio response
  final String? attachmentPath; // Local path of attached file/image
  final String? attachmentType; // 'image' | 'document'
  final String? attachmentName; // Display name

  AIChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isContextAware = false,
    this.audioUrl,
    this.attachmentPath,
    this.attachmentType,
    this.attachmentName,
  });

  AIChatMessage copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? timestamp,
    bool? isContextAware,
    String? audioUrl,
    String? attachmentPath,
    String? attachmentType,
    String? attachmentName,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isContextAware: isContextAware ?? this.isContextAware,
      audioUrl: audioUrl ?? this.audioUrl,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }
}

/// AI Chat Context containing current learning information
class AIChatContext {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final String? studentName;
  final String? studentLevel;
  final List<Section>? allSections;
  final Map<String, List<Lesson>>? sectionLessons;
  final bool isPlatformSupport; // Indicates this is for general platform help, not lesson-specific

  AIChatContext({
    this.currentCourse,
    this.currentLesson,
    this.studentName,
    this.studentLevel,
    this.allSections,
    this.sectionLessons,
    this.isPlatformSupport = false,
  });

  AIChatContext copyWith({
    Course? currentCourse,
    Lesson? currentLesson,
    String? studentName,
    String? studentLevel,
    List<Section>? allSections,
    Map<String, List<Lesson>>? sectionLessons,
    bool? isPlatformSupport,
  }) {
    return AIChatContext(
      currentCourse: currentCourse ?? this.currentCourse,
      currentLesson: currentLesson ?? this.currentLesson,
      studentName: studentName ?? this.studentName,
      studentLevel: studentLevel ?? this.studentLevel,
      allSections: allSections ?? this.allSections,
      sectionLessons: sectionLessons ?? this.sectionLessons,
      isPlatformSupport: isPlatformSupport ?? this.isPlatformSupport,
    );
  }
}

/// AI Chat Service Interface for backend integration
abstract class AIChatService {
  Future<List<AIChatMessage>> getConversation(String conversationId);
  Future<AIChatMessage> sendMessage(String conversationId, String message, AIChatContext context);
  Future<AIChatMessage> sendMessageWithFile(String conversationId, String message, File file, String fileType, AIChatContext context);
  Future<AIChatMessage> sendVoiceMessage(String conversationId, File audioFile, AIChatContext context);
  Future<void> createConversation(AIChatContext context);
  Future<void> updateContext(String conversationId, AIChatContext context);
}

/// Real AI Chat Service that connects to backend Grok AI
class RealAIChatService implements AIChatService {
  static String get _baseUrl => ApiConfig.aiBaseUrl; // Use centralized API config
  static String get _voiceBaseUrl => ApiConfig.voiceBaseUrl; // Use centralized voice API config
  final http.Client _httpClient = http.Client();
  // Temporary client-side ids ("conversation_...") -> real backend ids.
  final Map<String, String> _resolvedConversationIds = {};

  @override
  Future<List<AIChatMessage>> getConversation(String conversationId) async {
    try {
      // If conversationId is a temporary string ID, we need to create a real conversation first
      if (conversationId.startsWith('conversation_')) {
        // Create a new conversation
        await createConversation(AIChatContext());
        // The conversation ID should be updated after creation
        // For now, return empty list as the conversation will be created with proper ID
        return [];
      }
      
      final token = await _getAuthToken();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((item) => _fromMap(item)).toList();
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting conversation: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<AIChatMessage> sendMessage(String conversationId, String message, AIChatContext context) async {
    try {
      // If conversationId is a temporary string ID, create a real conversation
      // once and reuse it for the rest of the chat.
      String actualConversationId = conversationId;
      if (conversationId.startsWith('conversation_')) {
        actualConversationId = _resolvedConversationIds[conversationId] ??=
            await createConversation(context);
      }

      final requestBody = {
        'conversationId': actualConversationId,
        'message': message,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
          'currentLessonNotes': context.currentLesson?.notes ?? '',
          'courseStructure': context.allSections?.map((section) {
            final lessons = context.sectionLessons?[section.id] ?? [];
            return {
              'sectionTitle': section.title,
              'lessons': lessons.map((l) => {
                'title': l.title,
                'description': l.description ?? '',
                'content': l.notes ?? '', // Include actual lesson content/notes
              }).toList(),
            };
          }).toList(),
          'isPlatformSupport': context.isPlatformSupport,
          'platformHelpContext': context.isPlatformSupport 
            ? 'You are a platform support assistant for Excellence Coaching Hub. Help users with: navigating the app, enrolling in courses, making payments, accessing video lessons, taking exams, account management, and general platform usage. Provide clear, step-by-step guidance.'
            : null,
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return AIChatMessage(
          id: responseData['messages'][1]['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: responseData['messages'][1]['message'] ?? 'Sorry, I couldn\'t process that request.',
          timestamp: DateTime.now(),
          isContextAware: true,
          audioUrl: responseData['audioUrl'],
        );
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      // Return a fallback message in case of error
      return AIChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        message: 'I\'m having trouble connecting to my AI brain. Could you try asking again?',
        timestamp: DateTime.now(),
        isContextAware: false,
      );
    }
  }

  @override
  Future<AIChatMessage> sendMessageWithFile(
    String conversationId,
    String message,
    File file,
    String fileType, // 'image' or 'document'
    AIChatContext context,
  ) async {
    try {
      String actualConversationId = conversationId;
      if (conversationId.startsWith('conversation_')) {
        actualConversationId = await createConversation(context);
      }

      final token = await _getAuthToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/chat/send-with-file'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['conversationId'] = actualConversationId;
      request.fields['message'] = message.isNotEmpty ? message : 'Please analyze this $fileType and help me understand it.';
      request.fields['fileType'] = fileType;
      request.fields['context'] = jsonEncode({
        'courseTitle': context.currentCourse?.title ?? '',
        'lessonTitle': context.currentLesson?.title ?? '',
        'studentName': context.studentName ?? '',
        'studentLevel': context.studentLevel ?? '',
        'currentLessonNotes': context.currentLesson?.notes ?? '',
      });

      // Resolve MIME type from actual file extension for accurate Content-Type
      final ext = file.path.split('.').last.toLowerCase();
      final mimeMap = {
        'jpg': MediaType('image', 'jpeg'),
        'jpeg': MediaType('image', 'jpeg'),
        'png': MediaType('image', 'png'),
        'webp': MediaType('image', 'webp'),
        'gif': MediaType('image', 'gif'),
        'pdf': MediaType('application', 'pdf'),
        'doc': MediaType('application', 'msword'),
        'docx': MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
        'txt': MediaType('text', 'plain'),
      };
      final mimeType = mimeMap[ext] ?? (fileType == 'image' ? MediaType('image', 'jpeg') : MediaType('application', 'octet-stream'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path, contentType: mimeType));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        // S3 URL returned by the backend — prefer it over local path for display
        final s3Url = jsonData['messages']?[0]?['s3Url'] as String? ??
            jsonData['s3Url'] as String?;
        return AIChatMessage(
          id: jsonData['messages']?[1]?['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: jsonData['messages']?[1]?['message'] ??
              jsonData['response'] ??
              'I\'ve received your $fileType. Let me analyze it for you.',
          timestamp: DateTime.now(),
          isContextAware: true,
          // Pass s3Url back so the chat bubble can display the hosted file
          attachmentPath: s3Url,
          attachmentType: s3Url != null ? fileType : null,
          attachmentName: file.path.split(RegExp(r'[/\\]')).last,
        );
      } else {
        throw Exception('Failed to send file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message with file: $e');
      return AIChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        message: 'I received your ${fileType == 'image' ? 'image' : 'document'}. I\'m having trouble processing it right now — please try asking your question again.',
        timestamp: DateTime.now(),
        isContextAware: false,
      );
    }
  }

  @override
  Future<AIChatMessage> sendVoiceMessage(String conversationId, File audioFile, AIChatContext context) async {
    try {
      final token = await _getAuthToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_voiceBaseUrl/send'), // Use centralized voice API config
      );
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['conversationId'] = conversationId;
      request.fields['context'] = jsonEncode({
        'courseTitle': context.currentCourse?.title ?? '',
        'lessonTitle': context.currentLesson?.title ?? '',
        'studentName': context.studentName ?? '',
        'studentLevel': context.studentLevel ?? '',
        'currentLessonNotes': context.currentLesson?.notes ?? '',
        'courseStructure': context.allSections?.map((section) {
          final lessons = context.sectionLessons?[section.id] ?? [];
          return {
            'sectionTitle': section.title,
            'lessons': lessons.map((l) => {
              'title': l.title,
              'description': l.description ?? '',
              'content': l.notes ?? '', // Include actual lesson content/notes
            }).toList(),
          };
        }).toList(),
      });
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType('audio', 'mp4'), // Assuming M4A or MP4 audio
        ),
      );
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseBody);
        return AIChatMessage(
          id: 'voice_ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: jsonData['textResponse'] ?? 'I processed your voice message.',
          timestamp: DateTime.now(),
          isContextAware: true,
          audioUrl: jsonData['audioResponse'],
        );
      } else {
        throw Exception('Failed to send voice message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending voice message: $e');
      // Return a fallback message in case of error
      return AIChatMessage(
        id: 'error_voice_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        message: 'I\'m having trouble processing your voice message. Could you try again?',
        timestamp: DateTime.now(),
        isContextAware: false,
      );
    }
  }

  @override
  Future<String> createConversation(AIChatContext context) async {
    try {
      final requestBody = {
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
          'currentLessonNotes': context.currentLesson?.notes ?? '',
          'courseStructure': context.allSections?.map((section) {
            final lessons = context.sectionLessons?[section.id] ?? [];
            return {
              'sectionTitle': section.title,
              'lessons': lessons.map((l) => {
                'title': l.title,
                'description': l.description ?? '',
                'content': l.notes ?? '', // Include actual lesson content/notes
              }).toList(),
            };
          }).toList(),
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/conversations/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['conversation']['id'].toString();
      } else {
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateContext(String conversationId, AIChatContext context) async {
    try {
      // If conversationId is a temporary string ID, we can't update context
      if (conversationId.startsWith('conversation_')) {
        print('Cannot update context for temporary conversation ID');
        return;
      }
      
      final requestBody = {
        'conversationId': conversationId,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
          'currentLessonNotes': context.currentLesson?.notes ?? '',
          'courseStructure': context.allSections?.map((section) {
            final lessons = context.sectionLessons?[section.id] ?? [];
            return {
              'sectionTitle': section.title,
              'lessons': lessons.map((l) => {
                'title': l.title,
                'description': l.description ?? '',
                'content': l.notes ?? '', // Include actual lesson content/notes
              }).toList(),
            };
          }).toList(),
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/conversations/update-context'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update context: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating context: $e');
      rethrow;
    }
  }

  AIChatMessage _fromMap(Map<String, dynamic> json) {
    return AIChatMessage(
      id: json['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: json['sender'] ?? 'ai',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is String 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isContextAware: json['isContextAware'] ?? false,
      audioUrl: json['audioUrl'],
    );
  }

  // Helper method to get auth token (implement based on your auth system)
  Future<String> _getAuthToken() async {
    try {
      // Get the current user from Firebase
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the Firebase ID token
        final token = await user.getIdToken();
        if (token != null) {
          return token;
        } else {
          throw Exception('Failed to get ID token');
        }
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting auth token: $e');
      rethrow;
    }
  }
}
