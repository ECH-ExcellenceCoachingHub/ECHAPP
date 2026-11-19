class School {
  final String id;
  final String name;
  final String? description;
  final String? adminId;
  final String? adminFullName;
  final String? adminEmail;
  final String plan;
  final int studentLimit;
  final int studentCount;
  final int teacherCount;
  final bool isActive;
  final DateTime createdAt;

  School({
    required this.id,
    required this.name,
    this.description,
    this.adminId,
    this.adminFullName,
    this.adminEmail,
    required this.plan,
    required this.studentLimit,
    required this.studentCount,
    this.teacherCount = 0,
    required this.isActive,
    required this.createdAt,
  });

  int get remainingSlots => studentLimit - studentCount;
  bool get isFull => studentCount >= studentLimit;

  String get planLabel {
    switch (plan) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic';
      case 'premium':
        return 'Premium';
      default:
        return plan.toUpperCase();
    }
  }

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: _str(json['id']) ?? _str(json['_id']) ?? '',
      name: _str(json['name']) ?? 'Unnamed School',
      description: _str(json['description']),
      adminId: _str(json['adminId']) ?? _str(json['admin']),
      adminFullName: _str(json['adminFullName']),
      adminEmail: _str(json['adminEmail']),
      plan: _str(json['plan']) ?? 'free',
      studentLimit: _toInt(json['studentLimit']),
      studentCount: _toInt(json['studentCount']),
      teacherCount: _toInt(json['teacherCount']),
      isActive: json['isActive'] == true,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'adminFullName': adminFullName,
      'adminEmail': adminEmail,
      'plan': plan,
      'studentLimit': studentLimit,
      'studentCount': studentCount,
      'teacherCount': teacherCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return DateTime.now();
      }
    }
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  @override
  String toString() => 'School(id: $id, name: $name, plan: $plan, students: $studentCount/$studentLimit)';
}

class SchoolCreateRequest {
  final String name;
  final String? description;
  final String adminFullName;
  final String adminEmail;
  final String? adminPhone;
  final String? adminPassword;
  final String plan;
  final int? studentLimit;

  SchoolCreateRequest({
    required this.name,
    this.description,
    required this.adminFullName,
    required this.adminEmail,
    this.adminPhone,
    this.adminPassword,
    this.plan = 'free',
    this.studentLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'adminFullName': adminFullName,
      'adminEmail': adminEmail,
      if (adminPhone != null && adminPhone!.isNotEmpty) 'adminPhone': adminPhone,
      if (adminPassword != null && adminPassword!.isNotEmpty) 'adminPassword': adminPassword,
      'plan': plan,
      if (studentLimit != null) 'studentLimit': studentLimit,
    };
  }
}

class SchoolPlanUpdateRequest {
  final String plan;
  final int studentLimit;

  SchoolPlanUpdateRequest({required this.plan, required this.studentLimit});

  Map<String, dynamic> toJson() {
    return {'plan': plan, 'studentLimit': studentLimit};
  }
}

class MemberCreateRequest {
  final String fullName;
  final String? email;
  final String? phone;
  final String? password;

  MemberCreateRequest({
    required this.fullName,
    this.email,
    this.phone,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (password != null && password!.isNotEmpty) 'password': password,
    };
  }
}

class SchoolMember {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? firebaseUid;

  SchoolMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    this.firebaseUid,
  });

  factory SchoolMember.fromJson(Map<String, dynamic> json) {
    return SchoolMember(
      id: _str(json['id']) ?? _str(json['_id']) ?? '',
      fullName: _str(json['fullName']) ?? 'Unknown User',
      email: _str(json['email']) ?? '',
      phone: _str(json['phone']),
      role: _str(json['role']) ?? 'student',
      isActive: json['isActive'] == true,
      firebaseUid: _str(json['firebaseUid']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}
