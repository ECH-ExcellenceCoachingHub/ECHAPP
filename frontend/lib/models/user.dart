
class User {
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final String? phone;
  final String role;
  final String? deviceId;
  final bool disabled;
  final DateTime createdAt;
  final DateTime? lastActive;
  final List<String>? interests;
  final String? shortTermGoal;
  final String? midTermGoal;
  final String? longTermGoal;
  final bool hasCompletedOnboarding;
  /// Self-registered teachers: profile_incomplete | pending | approved | rejected (null otherwise).
  final String? teacherStatus;
  /// New Google / phone accounts that still have to pick Student or Teacher.
  final bool needsRoleSelection;
  /// School this user belongs to. Null = private (self-registered) student.
  final String? schoolId;
  /// True for students who registered themselves (not added under a school).
  final bool isPrivateStudent;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.phone,
    required this.role,
    this.deviceId,
    this.disabled = false,
    required this.createdAt,
    this.lastActive,
    this.interests,
    this.shortTermGoal,
    this.midTermGoal,
    this.longTermGoal,
    this.hasCompletedOnboarding = false,
    this.teacherStatus,
    this.needsRoleSelection = false,
    this.schoolId,
    this.isPrivateStudent = false,
  });

  /// Alias for fullName to maintain compatibility with legacy code
  String get name => fullName;

  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      // If it's a Map, try to convert to string representation
      return value.toString();
    }
    // For other types, convert to string
    return value.toString();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _getStringValue(json['id']) ?? _getStringValue(json['_id']) ?? '',
      fullName: _getStringValue(json['fullName']) ?? _getStringValue(json['name']) ?? 'Unknown User',
      email: _getStringValue(json['email']) ?? '',
      profilePicture: _getStringValue(json['profilePicture']) ?? _getStringValue(json['avatar']),
      phone: _getStringValue(json['phone']),
      role: _getStringValue(json['role']) ?? 'user',
      deviceId: _getStringValue(json['deviceId']),
      disabled: json['disabled'] == true,
      createdAt: _parseDateTime(json['createdAt']),
      lastActive: json['lastActive'] != null ? _parseDateTime(json['lastActive']) : null,
      interests: json['interests'] != null 
          ? List<String>.from(json['interests']) 
          : null,
      shortTermGoal: _getStringValue(json['shortTermGoal']),
      midTermGoal: _getStringValue(json['midTermGoal']),
      longTermGoal: _getStringValue(json['longTermGoal']),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] == true,
      teacherStatus: _getStringValue(json['teacherStatus']),
      needsRoleSelection: json['needsRoleSelection'] == true,
      schoolId: _getStringValue(json['schoolId']),
      isPrivateStudent: json['isPrivateStudent'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'name': fullName, // Support both fields
      'email': email,
      'profilePicture': profilePicture,
      'phone': phone,
      'role': role,
      'deviceId': deviceId,
      'disabled': disabled,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'interests': interests,
      'shortTermGoal': shortTermGoal,
      'midTermGoal': midTermGoal,
      'longTermGoal': longTermGoal,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'teacherStatus': teacherStatus,
      'needsRoleSelection': needsRoleSelection,
      'schoolId': schoolId,
      'isPrivateStudent': isPrivateStudent,
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is Map<String, dynamic>) {
      // Handle case where date is stored as an object (e.g., Firestore timestamp)
      try {
        // Check if it's a Firestore Timestamp-like object with seconds and nanoseconds
        if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
          int seconds = dateValue['seconds'] as int? ?? 0;
          int nanoseconds = dateValue['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else if (dateValue.containsKey('_seconds')) {
          // Alternative format with _seconds
          int seconds = dateValue['_seconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        // If conversion fails, return current time
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Creates an empty User instance for fallback scenarios
  factory User.empty() {
    return User(
      id: '',
      fullName: 'Unknown User',
      email: '',
      role: 'user',
      createdAt: DateTime.now(),
    );
  }
}

/// Authentication response model
class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  @override
  String toString() {
    return 'AuthResponse(user: $user, token: $token)';
  }
}