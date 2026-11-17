import 'dart:convert';
import '../../utils/date_utils.dart';

class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': DateUtils.toTimestamp(createdAt),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      createdAt: DateUtils.parseDate(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, phone: $phone, role: $role, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is User &&
      other.id == id &&
      other.fullName == fullName &&
      other.email == email &&
      other.phone == phone &&
      other.role == role &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      role.hashCode ^
      createdAt.hashCode;
  }
}

class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  AuthResponse copyWith({
    User? user,
    String? token,
    String? refreshToken,
  }) {
    return AuthResponse(
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      user: User.fromMap(map['user'] as Map<String, dynamic>),
      token: map['token'] as String,
      refreshToken: map['refreshToken'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthResponse.fromJson(String source) => AuthResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AuthResponse(user: $user, token: $token, refreshToken: $refreshToken)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AuthResponse &&
      other.user == user &&
      other.token == token &&
      other.refreshToken == refreshToken;
  }

  @override
  int get hashCode => user.hashCode ^ token.hashCode ^ refreshToken.hashCode;
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  LoginRequest copyWith({
    String? email,
    String? password,
  }) {
    return LoginRequest(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequest.fromMap(Map<String, dynamic> map) {
    return LoginRequest(
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginRequest.fromJson(String source) => LoginRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'LoginRequest(email: $email, password: $password)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is LoginRequest &&
      other.email == email &&
      other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String? role;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.role,
  });

  RegisterRequest copyWith({
    String? fullName,
    String? email,
    String? password,
    String? phone,
    String? role,
  }) {
    return RegisterRequest(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    };
  }

  factory RegisterRequest.fromMap(Map<String, dynamic> map) {
    return RegisterRequest(
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      phone: map['phone'] as String?,
      role: map['role'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RegisterRequest.fromJson(String source) => RegisterRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'RegisterRequest(fullName: $fullName, email: $email, password: $password, phone: $phone, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is RegisterRequest &&
      other.fullName == fullName &&
      other.email == email &&
      other.password == password &&
      other.phone == phone &&
      other.role == role;
  }

  @override
  int get hashCode => fullName.hashCode ^ email.hashCode ^ password.hashCode ^ phone.hashCode ^ role.hashCode;
}
