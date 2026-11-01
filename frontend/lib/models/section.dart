class Section {
  final String id;
  final String courseId;
  final String title;
  final int order;
  final String? description; // Add chapter description
  final bool? isPublished; // Add publish status
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? objectives; // Learning objectives for this chapter

  Section({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    this.description,
    this.isPublished,
    this.createdAt,
    this.updatedAt,
    this.objectives,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      order: _parseInt(json['order']),
      description: json['description'] as String?,
      isPublished: json['isPublished'] as bool?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      objectives: (json['objectives'] as List<dynamic>?)?.cast<String>(),
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
      'courseId': courseId,
      'title': title,
      'order': order,
      'description': description,
      'isPublished': isPublished,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'objectives': objectives,
    };
  }
  
  // Helper methods
  String get displayName => chapterLabel(order, title);
  bool get isChapter => true; // Always true for consistency
}

final _numberedTitle = RegExp(r'^\s*(chapter|unit|module|part|topic)\s+[0-9ivxlc]+\b', caseSensitive: false);

/// "Chapter 3: Title", unless the title already carries its own number
/// (book-built courses: "Chapter 5: Energy from Respiration").
String chapterLabel(int number, String title) =>
    _numberedTitle.hasMatch(title) ? title : 'Chapter $number: $title';
