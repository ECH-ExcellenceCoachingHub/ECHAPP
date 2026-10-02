import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/models/question.dart';

class QuizService {
  static String get _baseUrl => ApiConfig.quizzes;

  // Helper method to get auth token
  static Future<String> _getAuthToken() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);
        return token ?? '';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return '';
  }

  // Create a new quiz (exam)
  static Future<Map<String, dynamic>> createQuiz({
    required String sectionId,
    required String courseId,
    required String title,
    required String type,
    String category = 'lesson_quiz', // New category parameter
    int passingScore = 70,
    int timeLimit = 30,
    bool isPublished = true,
    List<Map<String, dynamic>>? preparedQuestions,
  }) async {
    try {
      final List<Map<String, dynamic>> examQuestions = preparedQuestions ?? [];
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'sectionId': sectionId,
          'courseId': courseId,
          'title': title,
          'type': type,
          'category': category, // Add category to request
          'passingScore': passingScore,
          'timeLimit': timeLimit,
          'questions': examQuestions,
          'isPublished': isPublished,
        }),
      );

      if (response.statusCode == 201) {
        print('=== QUIZ CREATION SUCCESS ===');
        print('Response body: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print('=== QUIZ CREATION FAILED ===');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        print('Headers: ${response.headers}');
        throw Exception('Failed to create quiz: ${response.body}');
      }
    } catch (e) {
      print('=== QUIZ CREATION EXCEPTION ===');
      print('Exception: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Error creating quiz: $e');
    }
  }

  // Get quiz with all questions
  static Future<Map<String, dynamic>> getQuiz(String examId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$examId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting quiz: $e');
    }
  }

  // Get all exams for a section (admin)
  static Future<List<Map<String, dynamic>>> getSectionExamsAdmin(String sectionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/section/$sectionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? data);
      } else {
        throw Exception('Failed to get section exams: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting section exams: $e');
    }
  }

  // Add question to existing quiz
  static Future<Question> addQuestion(String examId, Question question) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$examId/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(question.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Question.fromJson(data['data']);
      } else {
        throw Exception('Failed to add question: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding question: $e');
    }
  }

  // Update question
  static Future<Question> updateQuestion(String questionId, Question question) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/questions/$questionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(question.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Question.fromJson(data['data']);
      } else {
        throw Exception('Failed to update question: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating question: $e');
    }
  }

  // Delete question
  static Future<void> deleteQuestion(String questionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/questions/$questionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete question: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting question: $e');
    }
  }

  // Submit quiz answers and get grading
  static Future<Map<String, dynamic>> submitQuiz(
    String examId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$examId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? decoded;
      } else {
        throw Exception('Failed to submit quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting quiz: $e');
    }
  }

  // Get quiz templates for easy creation
  static Future<List<Map<String, dynamic>>> getQuizTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/templates'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get quiz templates: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting quiz templates: $e');
    }
  }

  // Duplicate quiz with all questions
  static Future<Map<String, dynamic>> duplicateQuiz(
    String examId,
    String newTitle,
    String? newSectionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$examId/duplicate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'newTitle': newTitle,
          'newSectionId': newSectionId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to duplicate quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error duplicating quiz: $e');
    }
  }

  // Upload question media (image, audio, video)
  static Future<String> uploadQuestionMedia(
    String examId,
    String filePath,
    String mediaType,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$examId/upload-media'),
      );
      
      request.headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      final file = await http.MultipartFile.fromPath(
        'media',
        filePath,
        filename: filePath.split('/').last,
      );
      
      request.files.add(file);
      request.fields['mediaType'] = mediaType;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        throw Exception('Failed to upload media: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading media: $e');
    }
  }

  // Get quiz statistics
  static Future<Map<String, dynamic>> getQuizStatistics(String examId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$examId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get quiz statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting quiz statistics: $e');
    }
  }

  // Get quiz submissions for admin
  static Future<List<Map<String, dynamic>>> getQuizSubmissions(String examId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$examId/submissions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get quiz submissions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting quiz submissions: $e');
    }
  }

  // Get all of the current student's quiz attempts, newest first
  static Future<List<Map<String, dynamic>>> getAllMyQuizAttempts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-attempts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get quiz attempts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting quiz attempts: $e');
    }
  }

  // Get student's quiz attempts for a specific quiz
  static Future<List<Map<String, dynamic>>> getStudentQuizAttempts(String examId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$examId/my-attempts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get student quiz attempts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting student quiz attempts: $e');
    }
  }

  // Grade essay question manually
  static Future<Map<String, dynamic>> gradeEssayQuestion(
    String submissionId,
    String questionId,
    int score,
    String feedback,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/grade-essay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'submissionId': submissionId,
          'questionId': questionId,
          'score': score,
          'feedback': feedback,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to grade essay: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error grading essay: $e');
    }
  }

  // Publish/Unpublish quiz
  static Future<Map<String, dynamic>> updateQuizPublishStatus(
    String examId,
    bool isPublished,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$examId/publish'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'isPublished': isPublished,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update quiz publish status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating quiz publish status: $e');
    }
  }

  // Delete quiz
  static Future<void> deleteQuiz(String examId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$examId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting quiz: $e');
    }
  }
}
