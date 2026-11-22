import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;

class DocumentUploadException implements Exception {
  final String message;
  DocumentUploadException(this.message);
  
  @override
  String toString() => 'DocumentUploadException: $message';
}

/// Service for uploading documents for lesson notes processing
class LessonDocumentService {
  Future<Map<String, dynamic>> uploadDocumentForLessonNotes({
    required PlatformFile file,
    required String courseId,
    required String sectionId,
    String? title,
    String? description,
    bool createLesson = false,
    bool processNotes = false,
  }) async {
    try {
      // Create multipart request
      final baseUrl = ApiConfig.baseUrl.replaceFirst('/api', '');
      // Use the generic upload endpoint to have more control
      final url = '$baseUrl/api/documents/upload';
      print('=== DEBUG DOCUMENT UPLOAD ===');
      print('Base URL: $baseUrl');
      print('Full URL: $url');
      print('Course ID: $courseId');
      print('Section ID: $sectionId');
      print('Create Lesson: $createLesson');
      print('Process Notes: $processNotes');
      print('File name: ${file.name}');
      print('File size: ${file.size}');
      print('Is web: $kIsWeb');
      print('===========================');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Add file to request
      if (kIsWeb) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              file.bytes!,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else {
          throw DocumentUploadException('File data is not available for web upload');
        }
      } else {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'document',
              file.path!,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              file.bytes!,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else {
          throw DocumentUploadException('File path or bytes not available for upload');
        }
      }

      // Add form fields
      request.fields['courseId'] = courseId;
      request.fields['sectionId'] = sectionId;
      request.fields['createLesson'] = createLesson.toString();
      request.fields['processNotes'] = processNotes.toString();
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;

      // Add authorization header
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid}');
      print('User email: ${user?.email}');
      
      if (user != null) {
        try {
          final token = await user.getIdToken();
          print('Got auth token');
          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          } else {
            throw DocumentUploadException('Failed to get authentication token');
          }
        } catch (tokenError) {
          print('Error getting token: $tokenError');
          throw DocumentUploadException('Failed to get authentication token: $tokenError');
        }
      } else {
        print('No current user found!');
        throw DocumentUploadException('User not authenticated. Please log in again.');
      }

      // Send request with extended timeout
      var client = http.Client();
      var streamedResponse = await client.send(request).timeout(
        const Duration(minutes: 5), // 5 minute timeout for document processing
      );
      var response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        print('=== SUCCESS RESPONSE ===');
        print('Full response: $responseBody');
        print('Success flag: ${responseBody['success']}');
        print('Data keys: ${responseBody['data']?.keys?.toList()}');
        print('=======================');
        
        if (responseBody['success'] == true) {
          // Return the full response structure to match backend format
          return responseBody;
        } else {
          throw DocumentUploadException(responseBody['message'] ?? 'Upload failed');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw DocumentUploadException(errorBody['message'] ?? 'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('=== DOCUMENT UPLOAD ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${e is Error ? (e).stackTrace : 'No stack trace'}');
      print('=============================');
      
      if (e is DocumentUploadException) rethrow;
      throw DocumentUploadException('Failed to upload document for lesson notes: $e');
    }
  }

  /// Get MIME type based on file extension
  MediaType _getMimeType(String? extension) {
    if (extension == null) return MediaType('application', 'octet-stream');
    
    final mimeTypes = {
      'pdf': MediaType('application', 'pdf'),
      'doc': MediaType('application', 'msword'),
      'docx': MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
      'txt': MediaType('text', 'plain'),
      'ppt': MediaType('application', 'vnd.ms-powerpoint'),
      'pptx': MediaType('application', 'vnd.openxmlformats-officedocument.presentationml.presentation'),
      'xls': MediaType('application', 'vnd.ms-excel'),
      'xlsx': MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    };
    
    return mimeTypes[extension.toLowerCase()] ?? MediaType('application', 'octet-stream');
  }
}