class Lesson {
  final String id;
  final String sectionId;
  final String courseId;
  final String title;
  final String? description;
  final String? videoId;
  final String? videoUrl; // Direct video URL from API
  final String? notes;
  final String? notesPdfUrl;
  final String? status;
  final int order;
  final int duration;
  final String? quizId; // Add quiz association
  final List<String>? materials; // Additional materials (PDFs, etc.)
  final String? lessonType; // video, text, quiz, mixed
  final bool? isPublished;
  /// Structured study guide from the AI Course Builder (summary, objectives,
  /// notes, visuals, key terms, formulas, examples, flashcards, sources).
  final Map<String, dynamic>? aiContent;
  final bool aiGenerated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.title,
    this.description,
    this.videoId,
    this.videoUrl,
    this.notes,
    this.notesPdfUrl,
    this.status,
    required this.order,
    required this.duration,
    this.quizId,
    this.materials,
    this.lessonType,
    this.isPublished,
    this.aiContent,
    this.aiGenerated = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? json['id'] ?? '',
      sectionId: json['sectionId'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      videoId: json['videoId'] as String?,
      videoUrl: json['videoUrl'] as String?,
      notes: json['notes'] as String?,
      notesPdfUrl: json['notesPdfUrl'] as String?,
      status: json['status'] as String?,
      order: _parseInt(json['order']),
      duration: _parseInt(json['duration']),
      quizId: json['quizId'] as String?,
      materials: (json['materials'] as List<dynamic>?)?.cast<String>(),
      lessonType: json['lessonType'] as String?,
      isPublished: json['isPublished'] as bool?,
      aiContent: json['aiContent'] is Map ? Map<String, dynamic>.from(json['aiContent'] as Map) : null,
      aiGenerated: json['aiGenerated'] == true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    // Handle case where value is an empty Map or other invalid type
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoId': videoId,
      'notes': notes,
      'notesPdfUrl': notesPdfUrl,
      'status': status,
      'order': order,
      'duration': duration,
      'quizId': quizId,
      'materials': materials,
      'lessonType': lessonType,
      'isPublished': isPublished,
      'aiContent': aiContent,
      'aiGenerated': aiGenerated,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Lesson copyWith({
    String? id,
    String? sectionId,
    String? courseId,
    String? title,
    String? description,
    String? videoId,
    String? notes,
    String? notesPdfUrl,
    String? status,
    int? order,
    int? duration,
    String? quizId,
    List<String>? materials,
    String? lessonType,
    bool? isPublished,
    Map<String, dynamic>? aiContent,
    bool? aiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoId: videoId ?? this.videoId,
      notes: notes ?? this.notes,
      notesPdfUrl: notesPdfUrl ?? this.notesPdfUrl,
      status: status ?? this.status,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      quizId: quizId ?? this.quizId,
      materials: materials ?? this.materials,
      lessonType: lessonType ?? this.lessonType,
      isPublished: isPublished ?? this.isPublished,
      aiContent: aiContent ?? this.aiContent,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for lesson content
  bool get hasVideo => videoId != null && videoId!.isNotEmpty;
  bool get hasAiGuide => aiContent != null && aiContent!.isNotEmpty;
  bool get hasNotes => hasAiGuide || (notes != null && notes!.isNotEmpty) || (notesPdfUrl != null && notesPdfUrl!.isNotEmpty);
  bool get hasQuiz => quizId != null && quizId!.isNotEmpty;
  bool get hasMaterials => materials != null && materials!.isNotEmpty;
  
  String get displayType {
    if (lessonType != null) return lessonType!;
    if (hasVideo && hasNotes) return 'Mixed';
    if (hasVideo) return 'Video';
    if (hasNotes) return 'Notes';
    if (hasQuiz) return 'Quiz';
    return 'Content';
  }
  
  List<String> get availableMaterials {
    List<String> materials = [];
    if (hasVideo) materials.add('Video');
    if (hasNotes) materials.add('Notes');
    if (hasQuiz) materials.add('Quiz');
    if (this.materials != null) materials.addAll(this.materials!);
    return materials;
  }
}
