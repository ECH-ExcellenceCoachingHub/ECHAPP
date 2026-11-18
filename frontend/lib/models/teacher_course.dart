import 'course.dart';

/// Teacher Course Model
/// Represents a course with teacher-specific metadata
class TeacherCourse {
  final String assignmentId;
  final DateTime assignedAt;
  final String? notes;
  final Course course;
  final int enrollmentCount;
  final int activeStudents;
  final int completedStudents;
  final int upcomingSessions;
  /// 'admin' (assigned by ECH, with students) or 'guide_purchase' (teacher guide only).
  final String source;
  /// The course has a published teacher guide the teacher can open.
  final bool guideAvailable;
  final List<String> guideClassLevels;

  bool get isGuideOnly => source == 'guide_purchase';

  TeacherCourse({
    required this.assignmentId,
    required this.assignedAt,
    this.notes,
    required this.course,
    this.enrollmentCount = 0,
    this.activeStudents = 0,
    this.completedStudents = 0,
    this.upcomingSessions = 0,
    this.source = 'admin',
    this.guideAvailable = false,
    this.guideClassLevels = const [],
  });

  factory TeacherCourse.fromJson(Map<String, dynamic> json) {
    // Per-course numbers are sent inside "course"; older servers sent them at the top.
    final c = (json['course'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    int n(String k) => ((json[k] ?? c[k]) as num?)?.toInt() ?? 0;
    final guide = (c['teacherGuide'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return TeacherCourse(
      assignmentId: json['assignmentId'] ?? '',
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : DateTime.now(),
      notes: json['notes'],
      course: json['course'] != null
          ? Course.fromJson(json['course'])
          : Course.empty(),
      enrollmentCount: n('enrollmentCount'),
      activeStudents: n('activeStudents'),
      completedStudents: n('completedStudents'),
      upcomingSessions: n('upcomingSessions'),
      source: json['source']?.toString() ?? 'admin',
      guideAvailable: guide['available'] == true,
      guideClassLevels: ((guide['classLevels'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'assignedAt': assignedAt.toIso8601String(),
      'notes': notes,
      'course': course.toJson(),
      'enrollmentCount': enrollmentCount,
      'activeStudents': activeStudents,
      'completedStudents': completedStudents,
      'upcomingSessions': upcomingSessions,
    };
  }
}

/// Course Content Model (Sections with Lessons)
class CourseContent {
  final Course course;
  final List<SectionWithLessons> sections;
  /// False for a course held only through a teacher's-guide request.
  final bool canSeeStudents;
  /// False for self-registered teachers (ECH admins manage course content).
  final bool canEditContent;
  /// The course has a published teacher's guide.
  final bool guideAvailable;

  CourseContent({
    required this.course,
    required this.sections,
    this.canSeeStudents = true,
    this.canEditContent = true,
    this.guideAvailable = false,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    final access = (json['access'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return CourseContent(
      canSeeStudents: access['canSeeStudents'] != false,
      canEditContent: access['canEditContent'] != false,
      guideAvailable: access['guideAvailable'] == true,
      course: json['course'] != null
          ? Course.fromJson(json['course'])
          : Course.empty(),
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => SectionWithLessons.fromJson(s))
              .toList()
          : [],
    );
  }
}

/// Section with Lessons Model
class SectionWithLessons {
  final String id;
  final String courseId;
  final String title;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LessonWithSessions> lessons;

  SectionWithLessons({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.lessons,
  });

  factory SectionWithLessons.fromJson(Map<String, dynamic> json) {
    return SectionWithLessons(
      id: json['_id'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      lessons: json['lessons'] != null
          ? (json['lessons'] as List)
              .map((l) => LessonWithSessions.fromJson(l))
              .toList()
          : [],
    );
  }
}

/// Lesson with Session Info Model
class LessonWithSessions {
  final String id;
  final String sectionId;
  final String courseId;
  final String title;
  final String? description;
  final String? videoId;
  final String? notes;
  final String? notesPdfUrl;
  final int order;
  final int duration;
  final String status;
  final String? quizId;
  final List<String> materials;
  final String lessonType;
  final bool isPublished;
  final int liveSessionCount;
  final bool hasRecording;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonWithSessions({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.title,
    this.description,
    this.videoId,
    this.notes,
    this.notesPdfUrl,
    required this.order,
    this.duration = 0,
    this.status = 'completed',
    this.quizId,
    this.materials = const [],
    this.lessonType = 'Content',
    this.isPublished = true,
    this.liveSessionCount = 0,
    this.hasRecording = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonWithSessions.fromJson(Map<String, dynamic> json) {
    return LessonWithSessions(
      id: json['_id'] ?? json['id'] ?? '',
      sectionId: json['sectionId'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      videoId: json['videoId'],
      notes: json['notes'],
      notesPdfUrl: json['notesPdfUrl'],
      order: json['order'] ?? 0,
      duration: json['duration'] ?? 0,
      status: json['status'] ?? 'completed',
      quizId: json['quizId'],
      materials: json['materials'] != null
          ? List<String>.from(json['materials'])
          : [],
      lessonType: json['lessonType'] ?? 'Content',
      isPublished: json['isPublished'] ?? true,
      liveSessionCount: json['liveSessionCount'] ?? 0,
      hasRecording: json['hasRecording'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
