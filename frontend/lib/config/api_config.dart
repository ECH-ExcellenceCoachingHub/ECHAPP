
class ApiConfig {
  // Dynamic base URL that works across platforms
  static String get baseUrl {
    return 'https://echappbackend.onrender.com/api';
  }
  
  // AI endpoints
  static String get aiBaseUrl => '${baseUrl.replaceFirst('/api', '')}/api/ai';
  static String get voiceBaseUrl => '${baseUrl.replaceFirst('/api', '')}/api/voice';
  
  // Auth endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get refreshToken => '$baseUrl/auth/refresh-token';
  static String get profile => '$baseUrl/auth/profile';
  static String get logout => '$baseUrl/auth/logout';
  static String get firebaseLogin => '$baseUrl/auth/firebase-login';
  static String get sessionStart => '$baseUrl/auth/session/start';
  static String get sessionHeartbeat => '$baseUrl/auth/session/heartbeat';
  
  // Course endpoints
  static String get courses => '$baseUrl/courses';
  
  // Category endpoints
  static String get categories => '$baseUrl/categories';
  
  // Enrollment endpoints
  static String get enrollments => '$baseUrl/enrollments';
  
  // Quiz endpoints
  static String get quizzes => '$baseUrl/quizzes';
  
  // Payment endpoints
  static String get payments => '$baseUrl/payments';
  
  // Video endpoints
  static String get videos => '$baseUrl/videos';
  
  // Upload endpoints
  static String get upload => '$baseUrl/upload';
  
  // Admin endpoints
  static String get admin => '$baseUrl/admin';

  // School management endpoints
  
  // Section endpoints
  static String get sections => '$baseUrl/sections';
  
  // Lesson endpoints
  static String get lessons => '$baseUrl/lessons';
  
  // Notification endpoints
  static String get notifications => '$baseUrl/notifications';
  
  // Platform settings endpoints
  static String get platformSettings => '$baseUrl/platform-settings';

  // Feedback endpoints
  static String get feedback => '$baseUrl/feedback';

  // Course Community endpoints (students, groups, discussions, assignments)
  static String get community => '$baseUrl/community';
  static String communityCourse(String courseId) => '$community/$courseId';

  // Direct messaging endpoints (one-to-one chat)
  static String get messages => '$baseUrl/messages';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
}
