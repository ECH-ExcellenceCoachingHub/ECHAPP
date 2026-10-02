class QuizSubmission {
  final String id;
  final String examId;
  final String userId;
  final int totalScore;
  final int maxScore;
  final int percentage;
  final bool passed;
  final bool needsManualGrading;
  final List<Map<String, dynamic>> results;
  final DateTime submittedAt;
  final String? examTitle;
  final String? courseTitle;

  QuizSubmission({
    required this.id,
    required this.examId,
    required this.userId,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.needsManualGrading,
    required this.results,
    required this.submittedAt,
    this.examTitle,
    this.courseTitle,
  });

  factory QuizSubmission.fromJson(Map<String, dynamic> json) {
    // examId is a plain id, or the populated quiz document.
    final exam = json['examId'];
    final examMap = exam is Map ? exam : null;
    int toInt(dynamic v) => v is num ? v.round() : int.tryParse('$v') ?? 0;

    return QuizSubmission(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      examId: (examMap != null ? examMap['_id'] : exam)?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      totalScore: toInt(json['totalScore']),
      maxScore: toInt(json['maxScore']),
      percentage: toInt(json['percentage']),
      passed: json['passed'] == true,
      needsManualGrading: json['needsManualGrading'] == true,
      results: (json['results'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList(),
      submittedAt: DateTime.tryParse(
              (json['submittedAt'] ?? json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      examTitle: json['examTitle']?.toString() ?? examMap?['title']?.toString(),
      courseTitle: json['courseTitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'examId': examId,
      'userId': userId,
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'passed': passed,
      'needsManualGrading': needsManualGrading,
      'results': results,
      'submittedAt': submittedAt.toIso8601String(),
      'examTitle': examTitle,
      'courseTitle': courseTitle,
    };
  }
}
