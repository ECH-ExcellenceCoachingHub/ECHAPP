import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';

/// Error from the teacher-access API, keeping the server's code
/// (TEACHER_PENDING_APPROVAL, TEACHER_COURSE_REQUIRED, …).
class TeacherAccessException implements Exception {
  final String message;
  final int? status;
  final String? code;
  TeacherAccessException(this.message, {this.status, this.code});
  @override
  String toString() => message;
}

/// Classes grouped for the picker (Nursery, Primary, Secondary…).
class LevelGroup {
  final String group;
  final List<String> levels;
  const LevelGroup(this.group, this.levels);

  factory LevelGroup.fromJson(Map<String, dynamic> j) =>
      LevelGroup(j['group']?.toString() ?? '', ((j['levels'] as List?) ?? const []).map((e) => e.toString()).toList());

  static const defaults = [
    LevelGroup('Nursery', ['N1', 'N2', 'N3']),
    LevelGroup('Primary', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6']),
    LevelGroup('Secondary (O-Level)', ['S1', 'S2', 'S3']),
    LevelGroup('Secondary (A-Level)', ['S4', 'S5', 'S6']),
    LevelGroup('TVET', ['L3', 'L4', 'L5']),
    LevelGroup('Higher education', ['University', 'Professional']),
  ];
}

class TeacherProfile {
  String school;
  String schoolType;
  String district;
  String province;
  String country;
  List<String> levels;
  List<String> subjects;
  int? yearsExperience;
  String qualification;
  String phone;
  String bio;
  DateTime? submittedAt;

  TeacherProfile({
    this.school = '',
    this.schoolType = '',
    this.district = '',
    this.province = '',
    this.country = 'Rwanda',
    List<String>? levels,
    List<String>? subjects,
    this.yearsExperience,
    this.qualification = '',
    this.phone = '',
    this.bio = '',
    this.submittedAt,
  })  : levels = levels ?? [],
        subjects = subjects ?? [];

  factory TeacherProfile.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    List<String> strs(dynamic v) => ((v as List?) ?? const []).map((e) => e.toString()).toList();
    return TeacherProfile(
      school: j['school']?.toString() ?? '',
      schoolType: j['schoolType']?.toString() ?? '',
      district: j['district']?.toString() ?? '',
      province: j['province']?.toString() ?? '',
      country: (j['country']?.toString() ?? '').isEmpty ? 'Rwanda' : j['country'].toString(),
      levels: strs(j['levels']),
      subjects: strs(j['subjects']),
      yearsExperience: j['yearsExperience'] is num ? (j['yearsExperience'] as num).toInt() : null,
      qualification: j['qualification']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      bio: j['bio']?.toString() ?? '',
      submittedAt: DateTime.tryParse(j['submittedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'school': school,
        'schoolType': schoolType,
        'district': district,
        'province': province,
        'country': country,
        'levels': levels,
        'subjects': subjects,
        'yearsExperience': yearsExperience,
        'qualification': qualification,
        'phone': phone,
        'bio': bio,
      };
}

/// Where a teacher is in the journey and what they may do.
class TeacherAccessStatus {
  final bool isTeacher;
  final bool selfRegistered;

  /// profile_incomplete | pending | approved | rejected
  final String status;
  final int courseCount;
  final bool canUseTools;
  final bool canEditCourseContent;
  final int pendingRequests;
  final String? reviewReason;
  final TeacherProfile profile;
  final List<LevelGroup> levelGroups;

  const TeacherAccessStatus({
    required this.isTeacher,
    required this.selfRegistered,
    required this.status,
    required this.courseCount,
    required this.canUseTools,
    required this.canEditCourseContent,
    required this.pendingRequests,
    required this.reviewReason,
    required this.profile,
    required this.levelGroups,
  });

  bool get needsProfile => status == 'profile_incomplete';
  bool get waitingApproval => status == 'pending';
  bool get rejected => status == 'rejected';
  bool get approved => status == 'approved';
  bool get needsCourse => approved && courseCount == 0 && selfRegistered;

  /// The route a teacher must see before the dashboard, or null when cleared.
  String? get gateRoute {
    if (!isTeacher || canUseTools) return null;
    if (needsProfile) return '/teacher/onboarding';
    if (waitingApproval || rejected) return '/teacher/pending';
    return '/teacher/choose-course';
  }

  factory TeacherAccessStatus.fromJson(Map<String, dynamic> j) {
    final groups = ((j['levelGroups'] as List?) ?? const []).map((g) => LevelGroup.fromJson(Map<String, dynamic>.from(g))).toList();
    return TeacherAccessStatus(
      isTeacher: j['isTeacher'] == true,
      selfRegistered: j['selfRegistered'] == true,
      status: j['status']?.toString() ?? 'approved',
      courseCount: (j['courseCount'] as num?)?.toInt() ?? 0,
      canUseTools: j['canUseTools'] == true,
      canEditCourseContent: j['canEditCourseContent'] != false,
      pendingRequests: (j['pendingRequests'] as num?)?.toInt() ?? 0,
      reviewReason: j['reviewReason']?.toString(),
      profile: TeacherProfile.fromJson(j['profile'] as Map<String, dynamic>?),
      levelGroups: groups.isEmpty ? LevelGroup.defaults : groups,
    );
  }
}

class GuideRequest {
  final String id;
  final String status; // pending | admin_review | approved | completed | failed | cancelled
  final num amount;
  final String paymentMethod;
  final String transactionId;
  final String adminNotes;
  const GuideRequest({required this.id, required this.status, required this.amount, required this.paymentMethod, required this.transactionId, required this.adminNotes});
  bool get waiting => status == 'pending' || status == 'admin_review';
  bool get refused => status == 'failed';

  factory GuideRequest.fromJson(Map<String, dynamic> j) => GuideRequest(
        id: j['id']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        amount: (j['amount'] as num?) ?? 0,
        paymentMethod: j['paymentMethod']?.toString() ?? '',
        transactionId: j['transactionId']?.toString() ?? '',
        adminNotes: j['adminNotes']?.toString() ?? '',
      );
}

/// A course's teacher's guide in the catalog.
class TeacherGuideSummary {
  final String courseId;
  final String title;
  final String description;
  final String? thumbnail;
  final String? category;
  final String subject;
  final List<String> classLevels;
  final num price;
  final bool ready;
  final int lessons;
  final int videos;
  final int chapters;
  final bool recommended;
  final bool hasAccess;
  final GuideRequest? request;

  const TeacherGuideSummary({
    required this.courseId,
    required this.title,
    required this.description,
    this.thumbnail,
    this.category,
    required this.subject,
    required this.classLevels,
    required this.price,
    required this.ready,
    required this.lessons,
    required this.videos,
    required this.chapters,
    required this.recommended,
    required this.hasAccess,
    this.request,
  });

  bool get isFree => price <= 0;

  factory TeacherGuideSummary.fromJson(Map<String, dynamic> j) {
    final stats = (j['stats'] as Map?) ?? const {};
    return TeacherGuideSummary(
      courseId: j['courseId']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      thumbnail: j['thumbnail']?.toString(),
      category: j['category']?.toString(),
      subject: j['subject']?.toString() ?? '',
      classLevels: ((j['classLevels'] as List?) ?? const []).map((e) => e.toString()).toList(),
      price: (j['price'] as num?) ?? 0,
      ready: j['ready'] == true,
      lessons: (stats['lessons'] as num?)?.toInt() ?? 0,
      videos: (stats['videos'] as num?)?.toInt() ?? 0,
      chapters: (stats['chapters'] as num?)?.toInt() ?? 0,
      recommended: j['recommended'] == true,
      hasAccess: j['hasAccess'] == true,
      request: j['request'] is Map ? GuideRequest.fromJson(Map<String, dynamic>.from(j['request'])) : null,
    );
  }
}

class GuideRequestResult {
  final String transactionId;
  final num amount;
  final String instructions;
  final String adminContact;
  const GuideRequestResult(this.transactionId, this.amount, this.instructions, this.adminContact);
}

class GuideLessonRef {
  final String id;
  final String title;
  final String summary;
  final int? minutes;
  final bool hasVideo;
  const GuideLessonRef(this.id, this.title, this.summary, this.minutes, this.hasVideo);
}

class GuideChapter {
  final int index;
  final String title;
  final String summary;
  final List<GuideLessonRef> lessons;
  const GuideChapter(this.index, this.title, this.summary, this.lessons);
}

class TeacherGuide {
  final String courseId;
  final String title;
  final String description;
  final List<String> classLevels;
  final String subject;
  final bool ready;
  final List<GuideChapter> chapters;
  const TeacherGuide({required this.courseId, required this.title, required this.description, required this.classLevels, required this.subject, required this.ready, required this.chapters});

  factory TeacherGuide.fromJson(Map<String, dynamic> j) {
    final c = (j['course'] as Map?) ?? const {};
    return TeacherGuide(
      courseId: c['id']?.toString() ?? '',
      title: c['title']?.toString() ?? '',
      description: c['description']?.toString() ?? '',
      classLevels: ((c['classLevels'] as List?) ?? const []).map((e) => e.toString()).toList(),
      subject: c['subject']?.toString() ?? '',
      ready: j['ready'] == true,
      chapters: ((j['chapters'] as List?) ?? const []).map((ch) {
        final m = Map<String, dynamic>.from(ch);
        return GuideChapter(
          (m['index'] as num?)?.toInt() ?? 0,
          m['title']?.toString() ?? '',
          m['summary']?.toString() ?? '',
          ((m['lessons'] as List?) ?? const []).map((l) {
            final x = Map<String, dynamic>.from(l);
            return GuideLessonRef(x['id']?.toString() ?? '', x['title']?.toString() ?? '', x['summary']?.toString() ?? '', (x['minutes'] as num?)?.toInt(), x['hasVideo'] == true);
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// One lesson of a teacher's guide (content.guide is the structured part).
class GuideLesson {
  final String id;
  final String title;
  final Map<String, dynamic> content;
  final String? videoUrl;
  final String? captionsUrl;
  final String? videoStatus;
  const GuideLesson({required this.id, required this.title, required this.content, this.videoUrl, this.captionsUrl, this.videoStatus});

  Map<String, dynamic> get guide => Map<String, dynamic>.from((content['guide'] as Map?) ?? const {});

  factory GuideLesson.fromJson(Map<String, dynamic> j) {
    final v = j['video'] as Map?;
    return GuideLesson(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      content: Map<String, dynamic>.from((j['content'] as Map?) ?? const {}),
      videoUrl: v?['url']?.toString(),
      captionsUrl: v?['captionsUrl']?.toString(),
      videoStatus: j['videoStatus']?.toString(),
    );
  }
}

// ─── Admin ────────────────────────────────────────────────────────────────────

class TeacherApplication {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? createdAt;
  final String status;
  final TeacherProfile profile;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String reviewReason;
  final int courseCount;
  final int pendingRequests;

  const TeacherApplication({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.createdAt,
    required this.status,
    required this.profile,
    this.reviewedBy,
    this.reviewedAt,
    required this.reviewReason,
    required this.courseCount,
    required this.pendingRequests,
  });

  factory TeacherApplication.fromJson(Map<String, dynamic> j) {
    final r = j['review'] as Map?;
    return TeacherApplication(
      id: j['id']?.toString() ?? '',
      fullName: j['fullName']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      status: j['status']?.toString() ?? 'pending',
      profile: TeacherProfile.fromJson(j['profile'] as Map<String, dynamic>?),
      reviewedBy: r?['reviewedBy']?.toString(),
      reviewedAt: DateTime.tryParse(r?['reviewedAt']?.toString() ?? ''),
      reviewReason: r?['reason']?.toString() ?? '',
      courseCount: (j['courseCount'] as num?)?.toInt() ?? 0,
      pendingRequests: (j['pendingRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminGuideCourse {
  final String courseId;
  final String title;
  final String? thumbnail;
  final String? category;
  final bool isPublished;
  final bool enabled;
  final num price;
  final List<String> classLevels;
  final String subject;
  final String description;
  final String? buildJobId;
  final DateTime? publishedAt;
  final int publishedLessons;
  final Map<String, dynamic>? latestBuild;
  final int teachers;
  final int pendingRequests;

  const AdminGuideCourse({
    required this.courseId,
    required this.title,
    this.thumbnail,
    this.category,
    required this.isPublished,
    required this.enabled,
    required this.price,
    required this.classLevels,
    required this.subject,
    required this.description,
    this.buildJobId,
    this.publishedAt,
    required this.publishedLessons,
    this.latestBuild,
    required this.teachers,
    required this.pendingRequests,
  });

  String? get latestBuildId => latestBuild?['id']?.toString();
  String? get latestBuildStatus => latestBuild?['status']?.toString();

  factory AdminGuideCourse.fromJson(Map<String, dynamic> j) {
    final g = Map<String, dynamic>.from((j['guide'] as Map?) ?? const {});
    return AdminGuideCourse(
      courseId: j['courseId']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      thumbnail: j['thumbnail']?.toString(),
      category: j['category']?.toString(),
      isPublished: j['isPublished'] == true,
      enabled: g['enabled'] == true,
      price: (g['price'] as num?) ?? 0,
      classLevels: ((g['classLevels'] as List?) ?? const []).map((e) => e.toString()).toList(),
      subject: g['subject']?.toString() ?? '',
      description: g['description']?.toString() ?? '',
      buildJobId: g['buildJobId']?.toString(),
      publishedAt: DateTime.tryParse(g['publishedAt']?.toString() ?? ''),
      publishedLessons: (g['publishedLessons'] as num?)?.toInt() ?? 0,
      latestBuild: j['latestBuild'] is Map ? Map<String, dynamic>.from(j['latestBuild']) : null,
      teachers: (j['teachers'] as num?)?.toInt() ?? 0,
      pendingRequests: (j['pendingRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherAccessService {
  final ApiClient _api;
  TeacherAccessService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  String get _base => ApiConfig.baseUrl;

  dynamic _data(http.Response r) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw TeacherAccessException(
        body?['message']?.toString() ?? 'Something went wrong (HTTP ${r.statusCode}). Please try again.',
        status: r.statusCode,
        code: body?['code']?.toString(),
      );
    }
    return body?['data'];
  }

  Future<T> _wrap<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on TeacherAccessException {
      rethrow;
    } on ApiException catch (e) {
      throw TeacherAccessException(e.message, status: e.statusCode);
    } catch (e) {
      throw TeacherAccessException('Could not reach the server. Check your connection and try again.');
    }
  }

  // Teacher journey
  Future<TeacherAccessStatus> status() => _wrap(() async =>
      TeacherAccessStatus.fromJson(Map<String, dynamic>.from(_data(await _api.get('$_base/teacher-access/status')))));

  Future<TeacherAccessStatus> submitProfile(TeacherProfile p) => _wrap(() async {
        final d = Map<String, dynamic>.from(_data(await _api.put('$_base/teacher-access/profile', body: p.toJson())));
        return TeacherAccessStatus.fromJson(d);
      });

  Future<List<TeacherGuideSummary>> guides({String search = ''}) => _wrap(() async {
        final q = search.trim().isEmpty ? '' : '?search=${Uri.encodeQueryComponent(search.trim())}';
        final d = Map<String, dynamic>.from(_data(await _api.get('$_base/teacher-access/guides$q')));
        return ((d['guides'] as List?) ?? const []).map((g) => TeacherGuideSummary.fromJson(Map<String, dynamic>.from(g))).toList();
      });

  Future<GuideRequestResult> requestGuide(String courseId, {String? paymentMethod, String? contactInfo}) => _wrap(() async {
        final d = Map<String, dynamic>.from(_data(await _api.post('$_base/teacher-access/guides/$courseId/request', body: {
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (contactInfo != null && contactInfo.trim().isNotEmpty) 'contactInfo': contactInfo.trim(),
        })));
        return GuideRequestResult(d['transactionId']?.toString() ?? '', (d['amount'] as num?) ?? 0, d['instructions']?.toString() ?? '', d['adminContact']?.toString() ?? '');
      });

  Future<void> cancelRequest(String paymentId) => _wrap(() async {
        _data(await _api.delete('$_base/teacher-access/requests/$paymentId'));
      });

  // Guide reader
  Future<TeacherGuide> guide(String courseId) => _wrap(() async =>
      TeacherGuide.fromJson(Map<String, dynamic>.from(_data(await _api.get('$_base/teacher-guides/$courseId')))));

  Future<GuideLesson> guideLesson(String courseId, String itemId) => _wrap(() async =>
      GuideLesson.fromJson(Map<String, dynamic>.from(_data(await _api.get('$_base/teacher-guides/$courseId/lessons/$itemId')))));

  // Admin
  Future<(List<TeacherApplication>, Map<String, int>)> applications({String status = 'pending', String search = ''}) => _wrap(() async {
        final q = 'status=$status${search.trim().isEmpty ? '' : '&search=${Uri.encodeQueryComponent(search.trim())}'}';
        final d = Map<String, dynamic>.from(_data(await _api.get('$_base/admin/teacher-applications?$q')));
        final apps = ((d['applications'] as List?) ?? const []).map((a) => TeacherApplication.fromJson(Map<String, dynamic>.from(a))).toList();
        final counts = Map<String, dynamic>.from((d['counts'] as Map?) ?? const {}).map((k, v) => MapEntry(k, (v as num).toInt()));
        return (apps, counts);
      });

  Future<void> reviewApplication(String id, {required bool approve, String reason = ''}) => _wrap(() async {
        _data(await _api.post('$_base/admin/teacher-applications/$id/review', body: {'decision': approve ? 'approve' : 'reject', 'reason': reason}));
      });

  Future<(List<AdminGuideCourse>, List<LevelGroup>)> adminGuides() => _wrap(() async {
        final d = Map<String, dynamic>.from(_data(await _api.get('$_base/admin/teacher-guides')));
        final groups = ((d['levelGroups'] as List?) ?? const []).map((g) => LevelGroup.fromJson(Map<String, dynamic>.from(g))).toList();
        return (
          ((d['courses'] as List?) ?? const []).map((c) => AdminGuideCourse.fromJson(Map<String, dynamic>.from(c))).toList(),
          groups.isEmpty ? LevelGroup.defaults : groups,
        );
      });

  Future<void> updateGuide(String courseId, {bool? enabled, num? price, List<String>? classLevels, String? subject, String? description}) => _wrap(() async {
        _data(await _api.put('$_base/admin/teacher-guides/$courseId', body: {
          if (enabled != null) 'enabled': enabled,
          if (price != null) 'price': price,
          if (classLevels != null) 'classLevels': classLevels,
          if (subject != null) 'subject': subject,
          if (description != null) 'description': description,
        }));
      });
}
