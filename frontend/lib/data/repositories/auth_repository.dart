import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/models/user.dart';

class PasswordResetResponse {
  final bool success;
  final String? message;

  PasswordResetResponse({
    required this.success,
    this.message,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();
  
  void _handleError(dynamic e, [String? defaultMessage]) {
    if (e is SocketException) {
      throw Exception('Network connection error. Please check your internet connection and try again.');
    } else if (e is http.ClientException) {
      throw Exception('Network connection error. Please check your network connection.');
    } else if (e is TimeoutException) {
      throw Exception('The request timed out. Please check your connection or try again later.');
    } else {
      String message = e.toString().replaceFirst('Exception: ', '');
      // Remove any redundant error prefixes
      message = message.replaceFirst('Firebase login error: ', '');
      message = message.replaceFirst('Login error: ', '');
      message = message.replaceFirst('Registration error: ', '');
      // Scrub Firebase references from user-facing messages
      message = message.replaceAll('Firebase', 'Authentication').replaceAll('firebase', 'authentication');
      
      throw Exception(message);
    }
  }

  /// School students (student code) and parents (phone) sign in with a PIN.
  /// [accessCode] is the class/school code of "School only" schools;
  /// young pupils send [studentId] + [accessCode] instead of a PIN.
  /// Returns the auth response and a Firebase custom token (may be null).
  Future<(AuthResponse, String?)> pinLogin(String identifier, String pin, {String? deviceId, String? accessCode, String? studentId}) async {
    final json = await _postPublic('/auth/pin-login', {
      'identifier': identifier,
      'pin': pin,
      if (deviceId != null) 'deviceId': deviceId,
      if (accessCode != null && accessCode.isNotEmpty) 'accessCode': accessCode,
      if (studentId != null) 'studentId': studentId,
    });
    final data = json['data'] as Map<String, dynamic>;
    return (AuthResponse.fromJson(data), data['firebaseCustomToken'] as String?);
  }

  /// What a class code opens: the class list (young pupils) or "use code + PIN".
  Future<Map<String, dynamic>> classCodeInfo(String code) async {
    final json = await _postPublic('/auth/class-code', {'code': code});
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> _postPublic(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw PinLoginException('The server took too long to answer. Please try again.');
    } on SocketException {
      throw PinLoginException('Network connection error. Please check your internet connection and try again.');
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PinLoginException('The server is waking up. Please try again in a moment.');
    }
    if (response.statusCode != 200 || json['success'] != true) {
      throw PinLoginException((json['message'] as String?) ?? 'Sign-in failed', code: json['code'] as String?);
    }
    return json;
  }

  Future<AuthResponse> login(String emailOrPhone, String password, {String? deviceId}) async {
    try {
      final body = {
        'emailOrPhone': emailOrPhone,
        'password': password,
      };
      
      if (deviceId != null) {
        body['deviceId'] = deviceId;
      }
      
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Ensure data['data'] is properly formatted for fromJson
        if (data['data'] is Map<String, dynamic>) {
          return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // If it's already a string, parse it again
          final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
          return AuthResponse.fromJson(mapData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      _handleError(e);
      rethrow; // For static analysis, though _handleError always throws
    }
  }

  Future<AuthResponse> register(String fullName, String? email, String password, String? phone, {String? role}) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName,
        'password': password,
      };
      if (role != null && role.trim().isNotEmpty) body['role'] = role.trim();
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Ensure data['data'] is properly formatted for fromJson
        if (data['data'] is Map<String, dynamic>) {
          return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // If it's already a string, parse it again
          final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
          return AuthResponse.fromJson(mapData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // In a real implementation, you would call the logout endpoint
      // and invalidate the token on the server side
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
    } catch (e) {
      _handleError(e, 'Logout failed');
    }
  }

  Future<AuthResponse> firebaseLogin(String idToken, {String? fullName, String? deviceId, String? role}) async {
    print('AuthRepository.firebaseLogin called with idToken length: ${idToken.length}');
    
    // Automatic retry logic for connection issues on Render
    int retryCount = 0;
    const int maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        String encodedBody;
        final body = {
          'idToken': idToken,
        };
        if (fullName != null) body['fullName'] = fullName;
        if (deviceId != null) body['deviceId'] = deviceId;
        if (role != null && role.trim().isNotEmpty) body['role'] = role.trim();
        encodedBody = jsonEncode(body);
        
        final client = http.Client();
        try {
          print('AuthRepository: Attempting backend login (Attempt ${retryCount + 1})');
          final response = await client.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/firebase-login'),
            headers: {
              'Content-Type': 'application/json',
              'Connection': 'close',
              'Accept': 'application/json',
            },
            body: encodedBody,
          ).timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic> && data.containsKey('data')) {
              if (data['data'] is Map<String, dynamic>) {
                return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
              } else {
                final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
                return AuthResponse.fromJson(mapData);
              }
            } else {
              return AuthResponse.fromJson(data as Map<String, dynamic>);
            }
          } else {
            // Handle specific status codes
            print('AuthRepository: Request failed with status code ${response.statusCode}');
            print('AuthRepository: Response body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
            
            try {
              final errorData = jsonDecode(response.body);
              final message = errorData['message'] ?? 'Authentication failed';
              print('AuthRepository: Parsed error message: $message');
              throw Exception(message);
            } catch (e) {
              if (e is Exception && !e.toString().contains('FormatException')) {
                rethrow;
              }
              
              if (response.statusCode == 401) {
                throw Exception('This account is already registered on another device. For security, we only allow one device per user.');
              }
              throw Exception('Authentication failed with status code ${response.statusCode}');
            }
          }
        } finally {
          client.close();
        }
      } catch (e) {
        bool isConnectionError = e.toString().contains('Connection closed before full header was received') || 
                               e.toString().contains('SocketException') ||
                               e.toString().contains('ClientException');
                               
        if (isConnectionError && retryCount < maxRetries) {
          retryCount++;
          print('AuthRepository: Connection error detected, retrying in ${retryCount * 2}s... ($retryCount/$maxRetries)');
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue; // Try again
        }
        
        print('AuthRepository: Final login error: $e');
        _handleError(e);
        rethrow;
      }
    }
    
    throw Exception('Authentication failed after multiple attempts.');
  }

  // Deprecated method - kept for backward compatibility
  @deprecated
  AuthResponse createFirebaseOnlyAuthResponse(User user) {
    return AuthResponse(
      user: user,
      token: 'firebase_only_token_${user.id}',
      refreshToken: 'firebase_refresh_token_${user.id}',
    );
  }

  Future<PasswordResetResponse> sendPasswordResetEmail(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Return a success response
        return PasswordResetResponse(
          success: true,
          message: data['message'] ?? 'Password reset email sent successfully!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<PasswordResetResponse> resetPassword(String token, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Return a success response
        return PasswordResetResponse(
          success: true,
          message: data['message'] ?? 'Password reset successfully!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<bool> verifyResetToken(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid or expired reset token');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Fetch user profile from backend using a bearer token.
  /// Used by AuthProvider to restore session on app restart.
  Future<User?> getUserProfile(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Expected shapes:
        // 1) { data: { ...user } }
        // 2) { user: { ...user } }
        // 3) { ...user } (fallback)
        final userJson =
            (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
                ? (data['data'] as Map<String, dynamic>)
                : (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>)
                    ? (data['user'] as Map<String, dynamic>)
                    : (data is Map<String, dynamic>)
                        ? data
                        : null;

        if (userJson == null) {
          throw Exception('Invalid profile response from server');
        }

        return User.fromJson(userJson);
      }

      // If unauthorized/expired token, just return null (do not hard-fail logout here)
      if (response.statusCode == 401 || response.statusCode == 403) {
        return null;
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch user profile');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Kept for backward compatibility with older code paths.
  // Prefer getUserProfile(token).
  @deprecated
  Future<User> getProfile() async {
    throw Exception('Not implemented - use getUserProfile(token) instead');
  }


  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : jsonDecode(data['data'].toString()) as Map<String, dynamic>;
        
        // Use a dummy user or handle the fact that refresh-token might not return user data
        // Based on backend code, it returns { token, refreshToken }
        return AuthResponse(
          token: tokenData['token'],
          refreshToken: tokenData['refreshToken'],
          user: User(id: '', fullName: '', email: '', role: '', createdAt: DateTime.now()), // Dummy user
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to refresh token');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<User> updateProfile(String token, {
    String? fullName,
    String? email,
    String? phone, 
    String? role,
    String? avatar,
    List<String>? interests,
    String? shortTermGoal,
    String? midTermGoal,
    String? longTermGoal,
    bool? hasCompletedOnboarding,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (role != null) 'role': role,
          if (avatar != null) 'avatar': avatar,
          if (interests != null) 'interests': interests,
          if (shortTermGoal != null) 'shortTermGoal': shortTermGoal,
          if (midTermGoal != null) 'midTermGoal': midTermGoal,
          if (longTermGoal != null) 'longTermGoal': longTermGoal,
          if (hasCompletedOnboarding != null) 'hasCompletedOnboarding': hasCompletedOnboarding,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'] is Map<String, dynamic> 
            ? data['data'] as Map<String, dynamic>
            : jsonDecode(data['data'].toString()) as Map<String, dynamic>;
        return User.fromJson(userData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Choose Student or Teacher once, after a Google / phone sign-up.
  Future<User> chooseRole(String token, String role) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return User.fromJson(Map<String, dynamic>.from(data['data']['user'] as Map));
    }
    throw Exception(data['message'] ?? 'Could not save your role');
  }

  Future<String> uploadImage(String token, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload/image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: path.basename(imageFile.path),
        contentType: MediaType('image', path.extension(imageFile.path).replaceFirst('.', '')),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['data']['imageUrl'];
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> updateFCMToken(String token, String fcmToken) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update FCM token');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> deleteAccount(String token) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/auth/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Sign-in error with the server's reason code (e.g. ACCESS_CODE_REQUIRED).
class PinLoginException implements Exception {
  PinLoginException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
