import 'package:excellencecoachinghub/widgets/school/school_reports_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _student(int i, List<String> subjects) => {
      'id': 'st$i',
      'fullName': i == 0 ? 'Aline Mukamana — Ndayishimiye ✓' : 'Student number $i with a long name',
      'studentCode': 'GSB26${'$i'.padLeft(4, '0')}',
      'gender': i.isEven ? 'female' : 'male',
      'dateOfBirth': '2011-03-02',
      'guardians': [
        {'name': 'Paul Habimana', 'phone': '0788123456', 'relationship': 'father', 'hasAccount': i.isEven}
      ],
      'address': {'district': 'Huye', 'sector': 'Ngoma'},
      'isActive': true,
      'createdAt': '2026-01-10T08:00:00Z',
      'bySubject': {for (var k = 0; k < subjects.length; k++) subjects[k]: k == 1 ? null : 40 + (i * 7 + k * 5) % 60},
      'position': i + 1,
      'stats': {'average': 40 + i % 60, 'handedIn': 4, 'expected': 6, 'missing': 2, 'handInRate': 67, 'examAverage': i.isOdd ? 55 : null},
    };

Map<String, dynamic> _class(String name, int n, int subjectCount) {
  final subjects = [for (var k = 0; k < subjectCount; k++) 'Subject number $k'];
  return {
    'class': {'id': name, 'name': name, 'academicYear': '2026', 'classTeacher': {'fullName': 'Jean Teacher'}},
    'subjects': [
      for (final s in subjects) {'subject': s, 'teacher': {'fullName': 'Marie Maths'}, 'lessonsTaught': 12, 'coveragePercent': 40, 'average': 63}
    ],
    'students': [for (var i = 0; i < n; i++) _student(i, subjects)],
    'summary': {
      'studentCount': n,
      'genders': {'male': n ~/ 2, 'female': n - n ~/ 2, 'other': 0},
      'withParentAccount': 3,
      'assessmentsGiven': 9,
      'classAverage': 61,
      'handInRate': 70,
      'examAverage': null,
      'atRisk': [{'id': 'st0', 'fullName': 'Aline', 'average': 41}],
      'mostMissing': [{'id': 'st1', 'fullName': 'Eric', 'missing': 4}],
    },
  };
}

void main() {
  const school = {'name': 'Groupe Scolaire Butare', 'district': 'Huye', 'phone': '0788000000'};

  test('student report PDF builds (long lists, odd characters, no class data)', () async {
    final bytes = await buildStudentReportPdf({
      'generatedAt': '2026-11-26T10:00:00Z',
      'school': school,
      'student': _student(0, const ['Biology']),
      'classroom': {'name': 'S6 MPC A', 'academicYear': '2026', 'classTeacher': {'fullName': 'Musa'}},
      'subjects': [{'subject': 'Biology', 'teacher': {'fullName': 'Jean'}, 'lessonsTaught': 4, 'syllabusLessons': 20, 'average': 80}],
      'assessments': [
        for (var i = 0; i < 80; i++)
          {'title': 'Homework $i “quotes”', 'subject': 'Biology', 'type': 'homework', 'dueAt': '2026-10-01', 'maxScore': 10, 'state': i.isEven ? 'graded' : 'missing', 'score': i.isEven ? 8 : null, 'percent': i.isEven ? 80 : null, 'isLate': i % 3 == 0}
      ],
      'exams': [{'title': 'Mock exam', 'score': 45, 'maxScore': 60, 'percentage': 75, 'completedAt': '2026-11-01'}],
      'stats': {'average': 80, 'handInRate': 50, 'handedIn': 40, 'expected': 80, 'missing': 40, 'examAverage': 75},
    });
    expect(bytes.length, greaterThan(2000));
    final empty = await buildStudentReportPdf({'school': school, 'student': {'fullName': 'No Class Kid'}, 'classroom': null, 'stats': {}});
    expect(empty.length, greaterThan(1000));
  });

  test('class report PDF builds with many students and subjects', () async {
    final bytes = await buildClassReportPdf({'school': school, 'generatedAt': '2026-11-26', ..._class('S6 MPC A', 60, 11)});
    expect(bytes.length, greaterThan(5000));
  });

  test('school report PDF builds with several classes', () async {
    final bytes = await buildSchoolReportPdf({
      'school': school,
      'summary': {'classCount': 3, 'studentCount': 70, 'teacherCount': 8, 'schoolAverage': 58, 'handInRate': 66, 'atRiskCount': 9},
      'classes': [_class('S1 A', 30, 4), _class('S2 B', 0, 0), _class('S6 MPC A', 40, 9)],
      'unassignedStudents': [{'fullName': 'Lost Kid', 'studentCode': 'GSB260099'}],
    });
    expect(bytes.length, greaterThan(5000));
  });
}
