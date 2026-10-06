import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class ExamQuestionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> examResult;

  const ExamQuestionDetailsScreen({
    super.key,
    required this.examResult,
  });

  @override
  State<ExamQuestionDetailsScreen> createState() => _ExamQuestionDetailsScreenState();
}

class _ExamQuestionDetailsScreenState extends State<ExamQuestionDetailsScreen> {
  List<Map<String, dynamic>> results = [];
  int totalScore = 0;
  int maxScore = 0;
  double percentage = 0.0;
  bool passed = false;

  @override
  void initState() {
    super.initState();
    results = List<Map<String, dynamic>>.from(widget.examResult['results'] ?? []);
    totalScore = (widget.examResult['totalScore'] as num?)?.toInt() ?? 0;
    maxScore = (widget.examResult['maxScore'] as num?)?.toInt() ?? 0;
    percentage = (widget.examResult['percentage'] as num?)?.toDouble() ?? 0.0;
    // The submission stores the verdict graded against the quiz's own passing
    // score; only guess when it's missing.
    passed = widget.examResult['passed'] as bool? ?? percentage >= 70;
    
    // Debug logging
    print('Exam result received: ${widget.examResult}');
    if (results.isNotEmpty) {
      print('First question result: ${results.first}');
    }
  }

  Color _getScoreColor(bool isCorrect) {
    return isCorrect ? Colors.green.shade600 : Colors.red.shade600;
  }

  String _formatAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    final questionType = question['questionType'];
    final selectedOption = userAnswer?['selectedOption'];
    final answerText = userAnswer?['answerText'];
    final options = question['options'] as List<dynamic>?;
    
    if (questionType == 'mcq') {
      if (selectedOption != null && options != null && selectedOption < options.length) {
        final option = options[selectedOption];
        final optionText = option is Map ? option['text'] ?? option.toString() : option.toString();
        return 'Option ${selectedOption + 1}: $optionText';
      }
      return selectedOption != null ? 'Option ${selectedOption + 1}' : 'Not answered';
    } else if (questionType == 'true_false') {
      if (selectedOption != null) {
        return selectedOption == 0 ? 'True' : 'False';
      }
      return 'Not answered';
    } else if (questionType == 'fill_blank' || questionType == 'open') {
      return answerText?.toString() ?? 'Not answered';
    } else if (questionType == 'drag_drop') {
      final dragAnswers = userAnswer?['dragAnswers'] as List<dynamic>?;
      if (dragAnswers == null || dragAnswers.isEmpty) {
        return 'Not answered';
      }
      
      final dropZones = question['dropZones'] as List<dynamic>?;
      final dragItems = question['dragDropItems'] as List<dynamic>?;
      
      if (dropZones == null || dragItems == null) {
        return 'Invalid question structure';
      }
      
      final answerTexts = <String>[];
      for (final zone in dropZones) {
        final zoneId = zone['id'] as String?;
        final zoneLabel = zone['label'] as String?;
        if (zoneId == null || zoneLabel == null) continue;
        
        final itemsInZone = dragAnswers.where((answer) => answer['zoneId'] == zoneId).toList();
        if (itemsInZone.isNotEmpty) {
          final itemNames = <String>[];
          for (final itemAnswer in itemsInZone) {
            final itemId = itemAnswer['itemId'] as String?;
            if (itemId != null) {
              final item = dragItems.firstWhere((i) => i['id'] == itemId, orElse: () => null);
              if (item != null) {
                itemNames.add(item['content'] as String? ?? itemId);
              }
            }
          }
          if (itemNames.isNotEmpty) {
            answerTexts.add('$zoneLabel: ${itemNames.join(', ')}');
          }
        }
      }
      
      return answerTexts.isEmpty ? 'No items placed' : answerTexts.join('\n');
    }
    return 'Not answered';
  }

  String _getCorrectAnswer(Map<String, dynamic> question) {
    final questionType = question['questionType'];
    final correctAnswer = question['correctAnswer'];
    final options = question['options'] as List<dynamic>?;
    
    print('Getting correct answer for type: $questionType, correctAnswer: $correctAnswer, options: $options');
    
    if (questionType == 'mcq') {
      if (correctAnswer != null && options != null && correctAnswer < options.length) {
        final option = options[correctAnswer];
        final optionText = option is Map ? option['text'] ?? option.toString() : option.toString();
        return 'Option ${correctAnswer + 1}: $optionText';
      }
      return correctAnswer != null ? 'Option ${correctAnswer + 1}' : 'N/A';
    } else if (questionType == 'true_false') {
      if (correctAnswer != null) {
        return correctAnswer == 0 ? 'True' : 'False';
      }
      return 'N/A';
    } else if (questionType == 'fill_blank' || questionType == 'open') {
      return correctAnswer?.toString() ?? 'N/A';
    } else if (questionType == 'drag_drop') {
      // For drag_drop, correctAnswer contains the full structure with dragDropItems and dropZones
      print('=== CORRECT ANSWER DEBUG ===');
      print('Full correctAnswer: $correctAnswer');
      print('correctAnswer type: ${correctAnswer.runtimeType}');
      
      if (correctAnswer is Map<String, dynamic>) {
        final dropZones = correctAnswer['dropZones'] as List<dynamic>?;
        final dragItems = correctAnswer['dragDropItems'] as List<dynamic>?;
        
        print('dropZones: $dropZones');
        print('dragItems: $dragItems');
        
        if (dropZones == null || dragItems == null) {
          return 'Invalid correct answer structure';
        }
        
        final correctTexts = <String>[];
        for (final zone in dropZones) {
          final zoneId = zone['id'] as String?;
          final zoneLabel = zone['label'] as String?;
          final correctItems = zone['correctItems'] as List<dynamic>?;
          
          if (zoneId == null || zoneLabel == null || correctItems == null) continue;
          
          final itemNames = <String>[];
          for (final itemId in correctItems) {
            if (itemId is String) {
              final item = dragItems.firstWhere((i) => i['id'] == itemId, orElse: () => null);
              if (item != null) {
                itemNames.add(item['content'] as String? ?? itemId);
              }
            }
          }
          
          if (itemNames.isNotEmpty) {
            correctTexts.add('$zoneLabel: ${itemNames.join(', ')}');
          }
        }
        
        return correctTexts.isEmpty ? 'No correct items specified' : correctTexts.join('\n');
      }
      return 'N/A';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Card and text colors below follow the theme, so the page behind them
      // has to as well or dark mode renders light text on a light background.
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          'Review Answers',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      '$totalScore/$maxScore',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Percentage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: passed ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        passed ? 'PASSED' : 'FAILED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: passed ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final isCorrect = result['isCorrect'] ?? false;
                final questionType = result['questionType'] ?? 'unknown';
                final questionText = result['question'] ?? 'Question not available';
                final userAnswer = result['userAnswer'];
                final score = result['score'] ?? 0;
                final maxScore = result['maxScore'] ?? 1;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getScoreColor(isCorrect).withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getScoreColor(isCorrect).withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getScoreColor(isCorrect),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getQuestionTypeLabel(questionType),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getSecondaryTextColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCorrect ? 'Correct' : ((score is num && score > 0) ? 'Partly correct' : 'Incorrect'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(isCorrect),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$score/$maxScore',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(isCorrect),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Question Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // User Answer
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.getCardColor(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.getBorderColor(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Answer:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getSecondaryTextColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      print('=== FORMATTING ANSWER ===');
                                      print('Question type: ${result['questionType']}');
                                      print('User answer data: $userAnswer');
                                      print('User answer type: ${userAnswer.runtimeType}');
                                      
                                      final formattedAnswer = _formatAnswer(result, userAnswer);
                                      print('Formatted answer: $formattedAnswer');
                                      
                                      return Text(
                                        formattedAnswer,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.getTextColor(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Correct Answer
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Correct Answer:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getCorrectAnswer(result),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((result['feedback'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      result['gradedBy'] == 'ai' ? Icons.auto_awesome : Icons.rate_review_outlined,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        result['feedback'].toString(),
                                        style: TextStyle(fontSize: 13.5, color: Colors.blue.shade900, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'mcq':
        return 'Multiple Choice';
      case 'true_false':
        return 'True/False';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'essay':
        return 'Essay';
      case 'drag_drop':
        return 'Drag and Drop';
      default:
        return type.toUpperCase();
    }
  }
}
