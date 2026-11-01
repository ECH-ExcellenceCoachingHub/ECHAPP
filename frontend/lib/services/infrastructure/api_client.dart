import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/api_response.dart';
import '../../models/course.dart';
import '../../config/api_config.dart';
import '../connectivity_service.dart';

/// Centralized HTTP client with interceptors and error handling
class ApiClient {
  static const int _timeoutSeconds = 60;
  final http.Client _httpClient;
  
  ApiClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Get authorization header — Firebase ID token first, stored JWT as fallback
  Future<Map<String, String>> _getAuthHeaders({bool forceRefresh = false}) async {
    // 1. Try Firebase (primary path: mobile / web / Google sign-in)
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      print('ApiClient: Current user: ${user?.uid ?? 'null'}');
      if (user != null) {
        // Force refresh if requested or if token might be stale
        final token = await user.getIdToken(forceRefresh);
        if (token != null) {
          print('ApiClient: Using Firebase token (refreshed: $forceRefresh)');
          return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          };
        }
      }
    } catch (e) {
      print('ApiClient: Firebase token error: $e');
    }

    // 2. Fall back to stored backend JWT (used after direct backend login on Windows desktop)
    try {
      final storedToken = await _storage.read(key: 'access_token');
      if (storedToken != null && storedToken.isNotEmpty) {
        print('ApiClient: Using stored backend JWT token');
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        };
      }
    } catch (e) {
      print('ApiClient: Error reading stored token: $e');
    }

    print('ApiClient: No auth token available - request will be unauthenticated');
    return {'Content-Type': 'application/json'};
  }

  /// Make HTTP GET request
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool authenticate = true,
  }) async {
    // Convert all query parameters to strings to avoid Uri parsing errors
    final stringQueryParams = queryParams?.map(
      (key, value) => MapEntry(key, value.toString()),
    ) ?? {};
    
    print('ApiClient: Query parameters converted to strings: $stringQueryParams');
    
    final uri = stringQueryParams.isEmpty 
        ? Uri.parse(url)
        : Uri.parse(url).replace(queryParameters: stringQueryParams);
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    print('ApiClient: Auth headers received: $authHeaders');
    final mergedHeaders = {...authHeaders, ...?headers};
    print('ApiClient: Final headers being sent: $mergedHeaders');
    
    return _makeRequest(() => _httpClient.get(uri, headers: mergedHeaders));
  }

  /// Make HTTP GET request and return bytes
  Future<http.Response> getBytes(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool authenticate = true,
  }) async {
    final stringQueryParams = queryParams?.map(
      (key, value) => MapEntry(key, value.toString()),
    ) ?? {};
    
    final uri = stringQueryParams.isEmpty 
        ? Uri.parse(url)
        : Uri.parse(url).replace(queryParameters: stringQueryParams);
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};
    
    return _makeRequest(() => _httpClient.get(uri, headers: mergedHeaders));
  }

  /// Make HTTP POST request
  Future<http.Response> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
    bool authenticate = true,
  }) async {
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};
    final encodedBody = body is Map ? jsonEncode(body) : body?.toString();
    
    return _makeRequest(() => _httpClient.post(
      Uri.parse(url),
      headers: mergedHeaders,
      body: encodedBody,
    ), retryOnTimeout: false);
  }

  /// Make HTTP PUT request
  Future<http.Response> put(
    String url, {
    Object? body,
    Map<String, String>? headers,
    bool authenticate = true,
  }) async {
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};
    final encodedBody = body is Map ? jsonEncode(body) : body?.toString();
    
    return _makeRequest(() => _httpClient.put(
      Uri.parse(url),
      headers: mergedHeaders,
      body: encodedBody,
    ), retryOnTimeout: false);
  }

  /// Make HTTP PATCH request
  Future<http.Response> patch(
    String url, {
    Object? body,
    Map<String, String>? headers,
    bool authenticate = true,
  }) async {
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};
    final encodedBody = body is Map ? jsonEncode(body) : body?.toString();
    
    return _makeRequest(() => _httpClient.patch(
      Uri.parse(url),
      headers: mergedHeaders,
      body: encodedBody,
    ), retryOnTimeout: false);
  }

  /// Make HTTP DELETE request
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    bool authenticate = true,
  }) async {
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};
    
    return _makeRequest(() => _httpClient.delete(
      Uri.parse(url),
      headers: mergedHeaders,
    ));
  }

  /// Make HTTP POST request for file uploads (multipart form data)
  Future<http.Response> postFile(
    String url, {
    required String filePath,
    required String fieldName,
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
    bool authenticate = true,
  }) async {
    final authHeaders = authenticate ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    final mergedHeaders = {...authHeaders, ...?headers};

    // Remove Content-Type header as it will be set automatically for multipart
    mergedHeaders.remove('Content-Type');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    
    // Add auth headers
    request.headers.addAll(mergedHeaders);
    
    // Add additional fields if provided
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    // Add file
    final file = await http.MultipartFile.fromPath(fieldName, filePath);
    request.files.add(file);

    final streamedResponse = await _httpClient.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  /// Execute HTTP request with error handling, timeout, and retry mechanism
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn, {
    bool isRetry = false,
    // A timed-out request may still be running on the server; resending a
    // POST/PUT/PATCH would run it twice (e.g. duplicate publishes, payments).
    bool retryOnTimeout = true,
  }) async {
    int maxRetries = 2;
    int retryCount = 0;
    
    while (true) {
      try {
        final response = await requestFn().timeout(
          Duration(seconds: _timeoutSeconds),
        );

        // Any response at all proves the backend is reachable, whatever the
        // status code. Clears an offline state set by an earlier failure.
        ConnectivityService.instance.reportServerReachable();

        // Log request for debugging
        print('API Request: ${response.request?.method} ${response.request?.url}');
        print('Response Status: ${response.statusCode}');
        
        // Handle 401 Unauthorized - try to refresh token and retry once
        if (response.statusCode == 401 && !isRetry) {
          print('Got 401 Unauthorized, attempting to refresh token...');
          
          // Try to refresh Firebase token first
          var refreshed = await _refreshFirebaseToken();
          
          // If Firebase refresh fails, try backend token refresh
          if (!refreshed) {
            print('Firebase token refresh failed, trying backend token refresh...');
            refreshed = await _refreshBackendToken();
          }
          
          if (refreshed) {
            print('Token refreshed successfully, retrying request...');
            // Get the original request details and retry with new token
            final originalRequest = response.request!;
            final url = originalRequest.url.toString();
            final method = originalRequest.method;
            
            // Recreate the request with refreshed token
            switch (method) {
              case 'GET':
                final authHeaders = await _getAuthHeaders(forceRefresh: true);
                return await _makeRequest(() => _httpClient.get(
                  Uri.parse(url),
                  headers: authHeaders,
                ), isRetry: true);
              case 'POST':
                // For POST, we can't retry as body is lost - return 401 to trigger re-auth
                print('Cannot retry POST request automatically, returning original 401');
                return response;
              case 'PUT':
                print('Cannot retry PUT request automatically, returning original 401');
                return response;
              case 'DELETE':
                final deleteAuthHeaders = await _getAuthHeaders(forceRefresh: true);
                return await _makeRequest(() => _httpClient.delete(
                  Uri.parse(url),
                  headers: deleteAuthHeaders,
                ), isRetry: true);
              default:
                print('Cannot retry $method request automatically, returning original 401');
                return response;
            }
          } else {
            print('Failed to refresh token, returning original 401');
            return response;
          }
        }
        
        return response;
      } on SocketException catch (e) {
        print('Socket error: $e');
        
        // Handle host lookup failure specifically
        if (e.osError?.errorCode == 7 || e.message.contains('Failed host lookup')) {
          // DNS is dead — the app is offline for all practical purposes, even
          // if the WiFi/mobile interface still looks up to connectivity_plus.
          ConnectivityService.instance.reportServerUnreachable();
          throw ApiException.network('Cannot connect to the server. Please check your internet connection or DNS settings.');
        }

        // Retry logic for other socket errors
        if (retryCount < maxRetries) {
          retryCount++;
          print('Retrying request... Attempt $retryCount of $maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // Exponential backoff
          continue;
        }

        ConnectivityService.instance.reportServerUnreachable();
        throw ApiException.network('Connection failed. Please check your internet connection and try again.');
      } on http.ClientException catch (e) {
        print('Network error: $e');
        
        // Retry logic for network errors
        if (retryCount < maxRetries) {
          retryCount++;
          print('Retrying request... Attempt $retryCount of $maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // Exponential backoff
          continue;
        }
        
        ConnectivityService.instance.reportServerUnreachable();
        throw ApiException.network('Network error occurred. Please check your network connection.');
      } on TimeoutException catch (e) {
        print('Request timeout: $e');
        
        // Retry logic for timeouts
        if (retryOnTimeout && retryCount < maxRetries) {
          retryCount++;
          print('Retrying request due to timeout... Attempt $retryCount of $maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // Exponential backoff
          continue;
        }
        
        throw ApiException.timeout('The request timed out. Please check your connection or try again later.');
      } catch (e) {
        print('Unexpected error: $e');
        throw ApiException.unknown('An unexpected error occurred: $e');
      }
    }
  }

  /// Try to refresh Firebase token
  Future<bool> _refreshFirebaseToken() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Force refresh the token
        final token = await user.getIdToken(true);
        if (token != null) {
          print('Firebase token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      print('Failed to refresh Firebase token: $e');
    }
    return false;
  }

  /// Try to refresh backend JWT token using refresh token
  Future<bool> _refreshBackendToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        print('No refresh token available');
        return false;
      }

      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'];
          // Store new tokens
          await _storage.write(key: 'access_token', value: data['token']);
          await _storage.write(key: 'refresh_token', value: data['refreshToken']);
          print('Backend token refreshed successfully');
          return true;
        }
      } else {
        print('Backend token refresh failed: ${response.statusCode}');
        // If refresh token is expired/invalid, clear stored tokens
        if (response.statusCode == 401) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
          print('Cleared expired tokens');
        }
      }
    } catch (e) {
      print('Failed to refresh backend token: $e');
    }
    return false;
  }

  /// Dispose of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exceptions for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);

  factory ApiException.network(String message) => ApiException(message, -1);
  factory ApiException.timeout(String message) => ApiException(message, -2);
  factory ApiException.unauthorized(String message) => ApiException(message, 401);
  factory ApiException.forbidden(String message) => ApiException(message, 403);
  factory ApiException.notFound(String message) => ApiException(message, 404);
  factory ApiException.serverError(String message) => ApiException(message, 500);
  factory ApiException.unknown(String message) => ApiException(message, 0);

  @override
  String toString() => message;
}

/// Extension to handle API response parsing
extension ApiResponseExtension on http.Response {
  /// Parse successful response into ApiResponse<T>
  ApiResponse<T> toApiResponse<T>(T Function(Map<String, dynamic>) fromJsonT) {
    try {
      if (!body.trim().startsWith('{') && !body.trim().startsWith('[')) {
        throw ApiException('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.', statusCode);
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, fromJsonT);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e', statusCode);
    }
  }

  /// Parse successful response into ApiResponse<List<T>>
  ApiResponse<List<T>> toApiResponseList<T>(T Function(Map<String, dynamic>) fromJsonT) {
    try {
      print('API Client: Parsing response body: $body');
      if (!body.trim().startsWith('{') && !body.trim().startsWith('[')) {
        throw ApiException('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.', statusCode);
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      print('API Client: JSON parsed, success: ${json['success']}, data type: ${json['data']?.runtimeType}');
      List<T>? dataList;
      
      if (json['data'] != null) {
        if (json['data'] is List) {
          // Direct array response
          print('API Client: Data is direct list, length: ${(json['data'] as List).length}');
          dataList = (json['data'] as List)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList();
        } else if (json['data'] is Map<String, dynamic>) {
          // Nested object response (like { courses: [...] })
          final dataMap = json['data'] as Map<String, dynamic>;
          print('API Client: Data is map, keys: ${dataMap.keys}');
          // Look for common list properties
          final listData = dataMap['courses'] ?? dataMap['data'] ?? dataMap['items'];
          if (listData != null && listData is List) {
            print('API Client: Found list data in courses/data/items, length: ${listData.length}');
            dataList = listData
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList();
          } else {
            print('API Client: No list data found in expected keys');
          }
        } else if (json['data'] is int || json['data'] is double || json['data'] is num) {
          // If data is a number (like a count), return empty list instead of crashing
          print('API Client: Data is a number (${json['data']}) instead of array, returning empty list');
          dataList = []; // Return empty list instead of crashing
        } else {
          // If data is neither a List nor a Map, it's probably an unexpected type like int
          print('API Client: Unexpected data type: ${json['data'].runtimeType}, value: ${json['data']}');
          dataList = []; // Return empty list instead of crashing
        }
      } else {
        print('API Client: No data found in response');
        dataList = []; // Return empty list if no data
      }
      
      // Additional safety check: if somehow dataList is still null after processing
      if (dataList == null) {
        print('API Client: dataList is null, setting to empty list');
        dataList = [];
      }
      
      print('API Client: Final dataList length: ${dataList.length ?? 0}');
      if (dataList.isNotEmpty) {
        // Print first item's thumbnail if it exists
        if (dataList[0] is Course) {
          final firstCourse = dataList[0] as Course;
          print('API Client: First course thumbnail: ${firstCourse.thumbnail ?? "null"}');
        }
      }
      
      return ApiResponse<List<T>>(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        data: dataList,
        error: json['error'] != null 
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('API Client: Error parsing response: $e');
      throw ApiException('Failed to parse response: $e', statusCode);
    }
  }

  /// Check if response indicates success
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Throw appropriate exception based on status code
  void validateStatus() {
    if (isSuccess) return;
    
    String message;
    try {
      if (!body.trim().startsWith('{') && !body.trim().startsWith('[')) {
        message = 'Server returned HTML instead of JSON. The backend might be waking up or misconfigured.';
      } else {
        final json = jsonDecode(body) as Map<String, dynamic>;
        message = json['message'] as String? ?? 'Request failed';
      }
    } catch (e) {
      message = body.isEmpty ? 'Empty response' : 'Invalid response format';
    }

    switch (statusCode) {
      case 400:
        throw ApiException(message, statusCode);
      case 401:
        throw ApiException.unauthorized(message);
      case 403:
        throw ApiException.forbidden(message);
      case 404:
        throw ApiException.notFound(message);
      case 500:
        throw ApiException.serverError(message);
      default:
        throw ApiException(message, statusCode);
    }
  }
}
