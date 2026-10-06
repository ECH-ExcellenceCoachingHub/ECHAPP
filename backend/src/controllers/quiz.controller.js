const Question = require('../models/Question');
const Quiz = require('../models/Quiz');
const Submission = require('../../models/Submission');
const { gradeOpenAnswers } = require('../services/answer-grading.service');
const Certificate = require('../models/Certificate');
const Course = require('../models/Course');
const User = require('../models/User');
const CertificatePDFService = require('../services/certificate_pdf_service');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');
const notificationController = require('./notification.controller');

// Fisher-Yates shuffle algorithm for better randomization
const fisherYatesShuffle = (array) => {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
};

// Create comprehensive quiz with multiple question types
const createQuiz = async (req, res, next) => {
  try {
    const { sectionId, courseId, title, type, passingScore, timeLimit, questions, isPublished, shuffleQuestions, shuffleOptions } = req.body;

    // Validate required fields
    if (!sectionId || !courseId || !title || !type) {
      return sendError(res, 'Missing required fields: sectionId, courseId, title, type', 400);
    }

    // Create quiz document
    const quiz = await Quiz.create({
      courseId,
      sectionId,
      title,
      type,
      passingScore: passingScore || 70,
      timeLimit: timeLimit || 600,
      isPublished: isPublished || false,
      shuffleQuestions: shuffleQuestions || false,
      shuffleOptions: shuffleOptions || false,
      questionsCount: 0
    });

    // Create questions if provided
    let createdQuestions = [];
    if (questions && questions.length > 0) {
      try {
        createdQuestions = await Promise.all(
          questions.map(questionData => createQuestion(quiz._id, questionData))
        );
        
        // Update quiz question count
        await Quiz.findByIdAndUpdate(quiz._id, {
          questionsCount: createdQuestions.length
        });
      } catch (questionError) {
        console.error('Error creating questions:', questionError);
        throw new Error(`Failed to create questions: ${questionError.message}`);
      }
    }

    sendSuccess(res, { quiz, questions: createdQuestions }, 'Quiz created successfully', 201);
  } catch (error) {
    console.error('CREATE QUIZ ERROR:', error);
    console.error('ERROR TYPE:', typeof error);
    console.error('ERROR MESSAGE:', error.message);
    console.error('ERROR STACK:', error.stack);
    sendError(res, 'Failed to create quiz', 500, error.message);
  }
};

// Helper function to create individual questions
const createQuestion = async (quizId, questionData) => {
  // Validate quizId
  if (!quizId) {
    throw new Error('Quiz ID is required for creating questions');
  }

  // Handle case where options is sent as stringified array
  let options = questionData.options;
  if (typeof options === 'string') {
    try {
      // Try to parse the stringified array
      options = JSON.parse(options);
      if (!Array.isArray(options)) {
        throw new Error('Options must be an array');
      }
    } catch (parseError) {
      // If parsing fails, treat as empty array
      options = [];
    }
  }

  // Validate options structure for MCQ questions
  if (questionData.type === 'mcq' && options && options.length > 0) {
    // Ensure each option has the required structure
    options = options.map(option => {
      if (typeof option === 'string') {
        // Convert string options to object format
        return {
          id: null,
          text: option.trim(),
          image: null,
          isCorrect: false
        };
      } else if (option && typeof option === 'object') {
        // Ensure object options have required fields
        return {
          id: option.id || null,
          text: option.text || '',
          image: option.image || null,
          isCorrect: option.isCorrect || false
        };
      }
      return option;
    });
  }

  // Prepare question data with proper validation
  const preparedQuestionData = {
    quizId,
    ...questionData,
    // Map frontend field names to backend schema field names
    text: questionData.question || questionData.text,
    options: options
  };
  
  // Remove the original 'question' field to avoid conflicts
  delete preparedQuestionData.question;

  // For MCQ questions, ensure correctAnswer is set based on options
  if (questionData.type === 'mcq' && options && options.length > 0) {
    console.log('MCQ Question Data:', JSON.stringify(questionData, null, 2));
    const correctOption = options.find(opt => opt.isCorrect);
    console.log('Correct option found:', correctOption);
    if (correctOption) {
      // Store the correct answer as the option index (0, 1, 2, 3) to match frontend submission
      const correctIndex = options.findIndex(opt => opt.isCorrect);
      console.log('Correct index calculated:', correctIndex);
      preparedQuestionData.correctAnswer = correctIndex;
    } else {
      throw new Error('MCQ questions must have at least one correct option');
    }
  }

  // For true_false questions, convert boolean to index (0 for True, 1 for False)
  if (questionData.type === 'true_false') {
    if (questionData.correctAnswer === undefined || questionData.correctAnswer === null) {
      throw new Error('True/false questions must have a correct answer');
    }
    // Convert boolean to index: true = 0, false = 1
    preparedQuestionData.correctAnswer = questionData.correctAnswer === true ? 0 : 1;
  }
  
  // For fill_blank questions, ensure correctAnswer is provided
  if (questionData.type === 'fill_blank') {
    if (questionData.correctAnswer === undefined || questionData.correctAnswer === null) {
      throw new Error('Fill-in-the-blank questions must have a correct answer');
    }
  }

  // For essay questions, ensure correctAnswer is provided
  if (questionData.type === 'essay') {
    if (questionData.correctAnswer === undefined || questionData.correctAnswer === null || questionData.correctAnswer.toString().trim() === '') {
      throw new Error('Essay questions must have a correct answer for grading');
    }
  }

  // For interactive question types, ensure proper answer structure is provided
  if (['drag_drop', 'matching', 'ordering', 'hotspot', 'programming'].includes(questionData.type)) {
    if (questionData.type === 'drag_drop') {
      // Debug logging to see what we're receiving
      console.log('=== DRAG DROP DEBUG ===');
      console.log('Full questionData:', JSON.stringify(questionData, null, 2));
      console.log('dragDropItems type:', typeof questionData.dragDropItems);
      console.log('dragDropItems value:', questionData.dragDropItems);
      console.log('dropZones type:', typeof questionData.dropZones);
      console.log('dropZones value:', questionData.dropZones);
      
      // Handle case where dragDropItems or dropZones might be null or empty arrays
      const dragItems = questionData.dragDropItems;
      const dropZones = questionData.dropZones;
      
      if (!dragItems || !Array.isArray(dragItems) || dragItems.length === 0) {
        console.log('DRAG ITEMS VALIDATION FAILED');
        console.log('Please ensure you fill in the drag items (text fields) in the question form before creating a drag-drop question.');
        throw new Error('drag_drop questions must have dragDropItems array with at least one item. Please add at least one drag item in the question form.');
      }
      if (!dropZones || !Array.isArray(dropZones) || dropZones.length === 0) {
        console.log('DROP ZONES VALIDATION FAILED');
        console.log('Please ensure you fill in the drop zones (target zones) in the question form before creating a drag-drop question.');
        throw new Error('drag_drop questions must have dropZones array with at least one zone. Please add at least one drop zone in the question form.');
      }
      
      // Validate dragDropItems structure
      for (const item of dragItems) {
        if (!item.id || !item.content || !item.targetZone) {
          throw new Error('Each dragDropItem must have id, content, and targetZone');
        }
      }
      
      // Validate dropZones structure
      for (const zone of dropZones) {
        if (!zone.id || !zone.label || !zone.correctItems) {
          throw new Error('Each dropZone must have id, label, and correctItems');
        }
      }
    } else if (questionData.type === 'matching') {
      if (!questionData.matchingPairs || !Array.isArray(questionData.matchingPairs) || questionData.matchingPairs.length === 0) {
        throw new Error('matching questions must have matchingPairs array with at least one pair');
      }
    } else if (questionData.type === 'ordering') {
      if (!questionData.correctOrder || !Array.isArray(questionData.correctOrder) || questionData.correctOrder.length === 0) {
        throw new Error('ordering questions must have correctOrder array with at least one item');
      }
    } else if (questionData.type === 'hotspot') {
      if (!questionData.hotspots || !Array.isArray(questionData.hotspots) || questionData.hotspots.length === 0) {
        throw new Error('hotspot questions must have hotspots array with at least one hotspot');
      }
    } else if (questionData.type === 'programming') {
      if (!questionData.correctAnswer) {
        throw new Error('programming questions must have correctAnswer specified');
      }
    }
  }

  const question = await Question.create(preparedQuestionData);
  return question;
};

// Add question to existing quiz
const addQuestion = async (req, res, next) => {
  try {
    const { quizId } = req.params;
    const questionData = req.body;

    // Verify quiz exists
    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      return sendNotFound(res, 'Quiz not found');
    }

    // Create question
    const question = await Question.create({
      quizId,
      ...questionData
    });

    // Update quiz question count
    await Quiz.findByIdAndUpdate(quizId, {
      $inc: { questionsCount: 1 }
    });

    sendSuccess(res, question, 'Question added successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to add question', 500, error.message);
  }
};

// Get quiz with all questions
const getQuiz = async (req, res, next) => {
  try {
    const { examId } = req.params;

    const quiz = await Quiz.findById(examId);
    if (!quiz) {
      return sendNotFound(res, 'Quiz not found');
    }

    
    let questions = await Question.find({ quizId: examId }).sort({ createdAt: 1 });

    // Apply shuffle logic if enabled
    if (quiz.shuffleQuestions) {
      // Shuffle question order using Fisher-Yates algorithm
      questions = fisherYatesShuffle(questions);
    }

    // Apply option shuffle if enabled
    if (quiz.shuffleOptions) {
      questions = questions.map(question => {
        const questionObj = question.toObject();
        
        if (question.type === 'mcq' && question.options) {
          // Shuffle MCQ options using Fisher-Yates algorithm
          const shuffledOptions = fisherYatesShuffle([...question.options]);
          return { ...questionObj, options: shuffledOptions };
        } else if (question.type === 'matching' && question.matchingPairs) {
          // Shuffle matching pairs using Fisher-Yates algorithm
          const shuffledPairs = fisherYatesShuffle([...question.matchingPairs]);
          return { ...questionObj, matchingPairs: shuffledPairs };
        } else if (question.type === 'ordering' && question.correctOrder) {
          // Shuffle ordering items using Fisher-Yates algorithm
          const shuffledOrder = fisherYatesShuffle([...question.correctOrder]);
          return { ...questionObj, correctOrder: shuffledOrder };
        }
        // For other question types, return as-is
        return questionObj;
      });
    }

    sendSuccess(res, { quiz, questions }, 'Quiz retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve quiz', 500, error.message);
  }
};

// Update question
const updateQuestion = async (req, res, next) => {
  try {
    const { questionId } = req.params;
    const updateData = req.body;

    const question = await Question.findByIdAndUpdate(
      questionId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!question) {
      return sendNotFound(res, 'Question not found');
    }

    sendSuccess(res, question, 'Question updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update question', 500, error.message);
  }
};

// Delete question
const deleteQuestion = async (req, res, next) => {
  try {
    const { questionId } = req.params;

    const question = await Question.findByIdAndDelete(questionId);
    if (!question) {
      return sendNotFound(res, 'Question not found');
    }

    // Update quiz question count
    await Quiz.findByIdAndUpdate(question.quizId, {
      $inc: { questionsCount: -1 }
    });

    sendSuccess(res, null, 'Question deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete question', 500, error.message);
  }
};

// Submit quiz answers and get automatic grading
const submitQuiz = async (req, res, next) => {
  try {
    const { examId } = req.params;
    const { answers } = req.body;
    const userId = req.user.id; // Use authenticated user's MongoDB ObjectId

    // Verify exam exists
    const exam = await Quiz.findById(examId);
    if (!exam) {
      return sendNotFound(res, 'Quiz not found');
    }

    // Get all questions
    const questions = await Question.find({ quizId: examId });
    console.log('Found questions:', questions.length);
    console.log('Exam ID:', examId);
    console.log('Received answers:', answers.length);
    console.log('Question IDs:', questions.map(q => q._id.toString()));
    console.log('Answer question IDs:', answers.map(a => a.questionId));

    // Grade each question
    const results = [];
    let totalScore = 0;
    let maxScore = 0;
    let needsManualGrading = false;
    // Written answers that need judgement are collected here and marked by AI after the loop
    const pendingOpen = [];

    for (const question of questions) {
      const userAnswerData = answers.find(a => a.questionId === question._id.toString());
      console.log('Question ID:', question._id.toString(), 'Has answer:', !!userAnswerData);
      const selectedOption = userAnswerData?.selectedOption;
      const answerText = userAnswerData?.answerText;
      
      console.log('Question type:', question.type);
      console.log('Selected option:', selectedOption);
      console.log('Answer text:', answerText);
      console.log('Correct answer:', question.correctAnswer);
      console.log('Points:', question.points);
      
      // Grading logic based on question type
      let isCorrect = false;
      let score = 0;
      const points = question.points || 1;
      
      if (question.type === 'mcq' || question.type === 'true_false') {
        // For MCQ and true_false, compare selected option index with correct answer
        isCorrect = selectedOption === question.correctAnswer;
        score = isCorrect ? points : 0;
        console.log('MCQ/TF grading - isCorrect:', isCorrect, 'score:', score);
      } else if (question.type === 'fill_blank') {
        // For fill-in-the-blank, compare answer text (case-insensitive)
        const userText = (answerText || '').toString().trim().toLowerCase();
        const correctText = question.correctAnswer?.toString().trim().toLowerCase();
        isCorrect = userText === correctText;
        score = isCorrect ? points : 0;
        // Not an exact match: let the AI judge spelling, synonyms and rounding
        if (!isCorrect && userText) {
          pendingOpen.push({ index: results.length, question, answerText, points });
        }
      } else if (question.type === 'essay' || question.type === 'programming') {
        // Marked automatically by AI against the model answer (see below)
        score = 0;
        pendingOpen.push({ index: results.length, question, answerText, points });
      } else if (question.type === 'drag_drop') {
        // Grade drag-drop questions
        const userDragAnswers = userAnswerData?.dragAnswers || [];
        console.log('Drag-drop user answers:', userDragAnswers);
        console.log('Expected drop zones:', question.dropZones);
        
        if (userDragAnswers.length === 0) {
          score = 0;
          isCorrect = false;
        } else {
          let correctPlacements = 0;
          let totalPlacements = 0;
          
          for (const zone of question.dropZones) {
            const userItemsInZone = userDragAnswers.filter(answer => answer.zoneId === zone.id);
            const correctItemsInZone = zone.correctItems;
            
            totalPlacements += correctItemsInZone.length;
            
            for (const correctItem of correctItemsInZone) {
              if (userItemsInZone.some(userAnswer => userAnswer.itemId === correctItem)) {
                correctPlacements++;
              }
            }
          }
          
          console.log('Correct placements:', correctPlacements, 'Total placements:', totalPlacements);
          
          if (question.partialCredit) {
            score = Math.round((correctPlacements / totalPlacements) * points);
            isCorrect = correctPlacements === totalPlacements;
          } else {
            score = correctPlacements === totalPlacements ? points : 0;
            isCorrect = correctPlacements === totalPlacements;
          }
        }
        console.log('Drag-drop grading - isCorrect:', isCorrect, 'score:', score);
      } else if (question.type === 'matching') {
        // Grade matching questions
        const userMatches = userAnswerData?.matches || [];
        if (userMatches.length === 0) {
          score = 0;
          isCorrect = false;
        } else {
          let correctMatches = 0;
          for (const pair of question.matchingPairs) {
            const userMatch = userMatches.find(match => match.leftId === pair.leftId);
            if (userMatch && userMatch.rightId === pair.rightId) {
              correctMatches++;
            }
          }
          
          if (question.partialCredit) {
            score = Math.round((correctMatches / question.matchingPairs.length) * points);
            isCorrect = correctMatches === question.matchingPairs.length;
          } else {
            score = correctMatches === question.matchingPairs.length ? points : 0;
            isCorrect = correctMatches === question.matchingPairs.length;
          }
        }
        console.log('Matching grading - isCorrect:', isCorrect, 'score:', score);
      } else if (question.type === 'ordering') {
        // Grade ordering questions
        const userOrder = userAnswerData?.orderedItems || [];
        if (userOrder.length === 0) {
          score = 0;
          isCorrect = false;
        } else {
          const correctOrder = question.correctOrder;
          let correctPositions = 0;
          
          for (let i = 0; i < correctOrder.length; i++) {
            if (userOrder[i] === correctOrder[i]) {
              correctPositions++;
            }
          }
          
          if (question.partialCredit) {
            score = Math.round((correctPositions / correctOrder.length) * points);
            isCorrect = correctPositions === correctOrder.length;
          } else {
            score = correctPositions === correctOrder.length ? points : 0;
            isCorrect = correctPositions === correctOrder.length;
          }
        }
        console.log('Ordering grading - isCorrect:', isCorrect, 'score:', score);
      } else {
        // Other question types need manual grading for now
        needsManualGrading = true;
        score = 0;
        console.log('Other type - needs manual grading');
      }
      
      // Prepare user answer object based on question type
      let userAnswer;
      if (question.type === 'drag_drop') {
        userAnswer = {
          dragAnswers: userAnswerData?.dragAnswers || [],
          selectedOption: null,
          answerText: ''
        };
      } else if (question.type === 'matching') {
        userAnswer = {
          matches: userAnswerData?.matches || [],
          selectedOption: null,
          answerText: ''
        };
      } else if (question.type === 'ordering') {
        userAnswer = {
          orderedItems: userAnswerData?.orderedItems || [],
          selectedOption: null,
          answerText: ''
        };
      } else {
        userAnswer = { selectedOption, answerText };
      }
      
      // Prepare correct answer object based on question type
      let correctAnswer = question.correctAnswer;
      if (question.type === 'drag_drop') {
        correctAnswer = {
          dragDropItems: question.dragDropItems,
          dropZones: question.dropZones
        };
      } else if (question.type === 'matching') {
        correctAnswer = question.matchingPairs;
      } else if (question.type === 'ordering') {
        correctAnswer = question.correctOrder;
      }
      
      results.push({
        questionId: question._id,
        questionType: question.type,
        question: question.text,
        options: question.options,
        correctAnswer,
        userAnswer,
        isCorrect,
        score,
        maxScore: points
      });
      
      console.log('Question result:', {
        questionType: question.type,
        correctAnswer,
        options: question.options,
        userAnswer
      });

      totalScore += score;
      maxScore += points;
    }

    if (pendingOpen.length) {
      const graded = await gradeOpenAnswers(pendingOpen.map(p => ({
        id: String(p.index),
        question: p.question.text,
        type: p.question.type,
        modelAnswer: p.question.correctAnswer,
        guidance: p.question.explanation,
        studentAnswer: p.answerText,
        points: p.points,
      })));
      for (const p of pendingOpen) {
        const g = graded.get(String(p.index));
        if (!g) continue;
        const r = results[p.index];
        totalScore += g.earnedPoints - r.score;
        r.score = g.earnedPoints;
        r.isCorrect = g.isCorrect;
        r.feedback = g.feedback;
        r.gradedBy = g.gradedBy;
      }
    }

    const percentage = maxScore > 0 ? Math.round((totalScore / maxScore) * 100) : 0;
    const passed = percentage >= (exam.passingScore || 70);

    console.log('Final totals - totalScore:', totalScore, 'maxScore:', maxScore, 'percentage:', percentage, 'passed:', passed);

    const submission = {
      examId,
      userId,
      totalScore,
      maxScore,
      percentage,
      passed,
      needsManualGrading,
      results,
      submittedAt: new Date()
    };

    // Save the submission to the database
    const savedSubmission = await Submission.create(submission);

    // Send exam result notification to user
    try {
      const NotificationController = notificationController.NotificationController;
      await NotificationController.createExamResultNotification(
        userId,
        exam.title,
        percentage,
        exam.courseId
      );
    } catch (notificationError) {
      console.error('Error creating exam result notification:', notificationError);
    }

    // Generate certificate for final exams if user passed
    if (passed && exam.type === 'final') {
      try {
        console.log('User passed final exam, generating certificate...');
        
        // Check if certificate already exists
        const existingCertificate = await Certificate.findOne({
          userId,
          courseId: exam.courseId
        });
        
        if (!existingCertificate) {
          // Get course and user details for certificate
          const course = await Course.findById(exam.courseId);
          const user = await User.findById(userId).select('fullName email');
          
          if (course && user) {
            // Generate certificate
            const certificateData = {
              userId,
              courseId: exam.courseId,
              examId: examId,
              score: percentage,
              percentage: percentage,
              issuedDate: new Date(),
              isValid: true,
              serialNumber: `CERT-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`
            };
            
            const certificate = await Certificate.create(certificateData);
            
            // Generate PDF certificate
            const pdfPath = await CertificatePDFService.generateCertificatePDF({
              studentName: user.fullName,
              userFullName: user.fullName,
              courseTitle: course.title,
              completionDate: new Date(),
              score: percentage,
              serialNumber: certificate.serialNumber
            });
            
            // Update certificate with PDF path
            certificate.certificatePdfPath = pdfPath;
            await certificate.save();
            
            console.log(`Certificate generated successfully for user ${userId}, course ${exam.courseId}`);
          }
        } else {
          console.log(`Certificate already exists for user ${userId}, course ${exam.courseId}`);
        }
      } catch (certError) {
        console.error('Certificate generation error:', certError);
        // Don't fail the quiz submission if certificate generation fails
      }
    }

    sendSuccess(res, savedSubmission, 'Quiz submitted and graded successfully');
  } catch (error) {
    console.error('SUBMIT QUIZ ERROR:', error);
    sendError(res, 'Failed to submit quiz', 500, error.message);
  }
};

// Get student's quiz attempts for a specific quiz
const getStudentQuizAttempts = async (req, res, next) => {
  try {
    const { examId } = req.params;
    const userId = req.user.id; // Get from authenticated user

    // Verify exam exists
    const exam = await Quiz.findById(examId);
    if (!exam) {
      return sendNotFound(res, 'Quiz not found');
    }

    // Get all submissions for this user and exam, sorted by most recent
    const submissions = await Submission.find({ 
      examId, 
      userId 
    })
    .sort({ submittedAt: -1 })
    .populate('examId', 'title passingScore')
    .lean();

    sendSuccess(res, submissions, 'Quiz attempts retrieved successfully');
  } catch (error) {
    console.error('GET STUDENT ATTEMPTS ERROR:', error);
    sendError(res, 'Failed to retrieve quiz attempts', 500, error.message);
  }
};

// Get every quiz attempt of the authenticated student, across all quizzes
const getAllMyQuizAttempts = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const limit = Math.min(parseInt(req.query.limit, 10) || 200, 500);

    const submissions = await Submission.find({ userId })
      .sort({ submittedAt: -1 })
      .limit(limit)
      .populate({
        path: 'examId',
        select: 'title passingScore type courseId',
        populate: { path: 'courseId', select: 'title' }
      })
      .lean();

    // Flatten quiz/course titles so clients don't need to dig into populated docs.
    // Attempts whose quiz was deleted keep their scores but get a fallback title.
    const attempts = submissions.map((s) => {
      const exam = s.examId && typeof s.examId === 'object' ? s.examId : null;
      const course = exam && exam.courseId && typeof exam.courseId === 'object' ? exam.courseId : null;
      return {
        ...s,
        examTitle: exam ? exam.title : 'Deleted quiz',
        examType: exam ? exam.type : null,
        courseId: course ? course._id : (exam ? exam.courseId : null),
        courseTitle: course ? course.title : null
      };
    });

    sendSuccess(res, attempts, 'Quiz attempts retrieved successfully');
  } catch (error) {
    console.error('GET ALL STUDENT ATTEMPTS ERROR:', error);
    sendError(res, 'Failed to retrieve quiz attempts', 500, error.message);
  }
};

// Get quiz templates for easy creation
const getQuizTemplates = async (req, res, next) => {
  try {
    const templates = [
      {
        id: 'mcq-basic',
        name: 'Basic Multiple Choice',
        description: 'Simple multiple choice questions',
        questionTypes: ['mcq'],
        estimatedTime: 10,
        questionCount: 5,
        template: {
          type: 'quiz',
          passingScore: 70,
          timeLimit: 600,
          questions: [
            {
              type: 'mcq',
              question: 'What is the capital of France?',
              options: [
                { text: 'London', isCorrect: false },
                { text: 'Berlin', isCorrect: false },
                { text: 'Paris', isCorrect: true },
                { text: 'Madrid', isCorrect: false }
              ],
              points: 1,
              difficulty: 'easy'
            }
          ]
        }
      },
      {
        id: 'comprehensive-mixed',
        name: 'Comprehensive Mixed Quiz',
        description: 'Mixed question types for thorough assessment',
        questionTypes: ['mcq', 'true_false', 'fill_blank', 'essay'],
        estimatedTime: 30,
        questionCount: 10,
        template: {
          type: 'quiz',
          passingScore: 75,
          timeLimit: 1800,
          questions: [
            {
              type: 'mcq',
              question: 'Sample multiple choice question',
              options: [
                { text: 'Option A', isCorrect: false },
                { text: 'Option B', isCorrect: true },
                { text: 'Option C', isCorrect: false },
                { text: 'Option D', isCorrect: false }
              ],
              points: 2,
              difficulty: 'medium'
            },
            {
              type: 'true_false',
              question: 'The Earth is flat.',
              correctAnswer: false,
              points: 1,
              difficulty: 'easy'
            },
            {
              type: 'fill_blank',
              question: 'The capital of Japan is _____.',
              correctAnswer: 'Tokyo',
              points: 2,
              difficulty: 'medium'
            },
            {
              type: 'essay',
              question: 'Explain the importance of renewable energy.',
              points: 5,
              difficulty: 'hard'
            }
          ]
        }
      },
      {
        id: 'interactive-drag-drop',
        name: 'Interactive Drag & Drop',
        description: 'Drag and drop questions for engagement',
        questionTypes: ['drag_drop', 'matching', 'ordering'],
        estimatedTime: 20,
        questionCount: 5,
        template: {
          type: 'quiz',
          passingScore: 80,
          timeLimit: 1200,
          questions: [
            {
              type: 'drag_drop',
              question: 'Drag the items to their correct categories',
              dragDropItems: [
                { id: 'item1', content: 'Apple', targetZone: 'fruits' },
                { id: 'item2', content: 'Carrot', targetZone: 'vegetables' },
                { id: 'item3', content: 'Banana', targetZone: 'fruits' }
              ],
              dropZones: [
                { id: 'fruits', label: 'Fruits', correctItems: ['item1', 'item3'] },
                { id: 'vegetables', label: 'Vegetables', correctItems: ['item2'] }
              ],
              points: 3,
              partialCredit: true,
              difficulty: 'medium'
            }
          ]
        }
      }
    ];

    sendSuccess(res, templates, 'Quiz templates retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve quiz templates', 500, error.message);
  }
};

// Update quiz settings
const updateQuiz = async (req, res, next) => {
  try {
    const { examId } = req.params;
    const { title, description, passingScore, timeLimit, isPublished, shuffleQuestions, shuffleOptions, showResults, showCorrectAnswers, allowReview, instructions, startDate, endDate } = req.body;

    // Verify quiz exists
    const quiz = await Quiz.findById(examId);
    if (!quiz) {
      return sendNotFound(res, 'Quiz not found');
    }

    // Prepare update data
    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (passingScore !== undefined) updateData.passingScore = passingScore;
    if (timeLimit !== undefined) updateData.timeLimit = timeLimit;
    if (isPublished !== undefined) updateData.isPublished = isPublished;
    if (shuffleQuestions !== undefined) updateData.shuffleQuestions = shuffleQuestions;
    if (shuffleOptions !== undefined) updateData.shuffleOptions = shuffleOptions;
    if (showResults !== undefined) updateData.showResults = showResults;
    if (showCorrectAnswers !== undefined) updateData.showCorrectAnswers = showCorrectAnswers;
    if (allowReview !== undefined) updateData.allowReview = allowReview;
    if (instructions !== undefined) updateData.instructions = instructions;
    if (startDate !== undefined) updateData.startDate = startDate;
    if (endDate !== undefined) updateData.endDate = endDate;

    // Update quiz
    const updatedQuiz = await Quiz.findByIdAndUpdate(
      examId,
      updateData,
      { new: true, runValidators: true }
    );

    sendSuccess(res, updatedQuiz, 'Quiz updated successfully');
  } catch (error) {
    console.error('UPDATE QUIZ ERROR:', error);
    sendError(res, 'Failed to update quiz', 500, error.message);
  }
};

// Duplicate quiz with all questions
const duplicateQuiz = async (req, res, next) => {
  try {
    const { examId } = req.params;
    const { newTitle, newSectionId } = req.body;

    // Get original quiz
    const originalQuiz = await Quiz.findById(examId);
    if (!originalQuiz) {
      return sendNotFound(res, 'Original quiz not found');
    }

    // Create new Quiz
    const newQuiz = await Quiz.create({
      courseId: originalQuiz.courseId,
      sectionId: newSectionId || originalQuiz.sectionId,
      title: newTitle || `${originalQuiz.title} (Copy)`,
      type: originalQuiz.type,
      passingScore: originalQuiz.passingScore,
      timeLimit: originalQuiz.timeLimit,
      shuffleQuestions: originalQuiz.shuffleQuestions,
      shuffleOptions: originalQuiz.shuffleOptions,
      showResults: originalQuiz.showResults,
      showCorrectAnswers: originalQuiz.showCorrectAnswers,
      allowReview: originalQuiz.allowReview,
      instructions: originalQuiz.instructions,
      startDate: originalQuiz.startDate,
      endDate: originalQuiz.endDate,
      isPublished: false, // Start as draft
      questionsCount: 0
    });

    // Get original questions
    const originalQuestions = await Question.find({ quizId: examId });

    // Create copies of questions
    const newQuestions = await Promise.all(
      originalQuestions.map(q => {
        const questionObj = q.toObject();
        delete questionObj._id;
        delete questionObj.createdAt;
        delete questionObj.updatedAt;
        questionObj.quizId = newQuiz._id;
        return Question.create(questionObj);
      })
    );

    // Update question count
    await Quiz.findByIdAndUpdate(newQuiz._id, { 
      questionsCount: newQuestions.length 
    });

    sendSuccess(res, { quiz: newQuiz, questions: newQuestions }, 'Quiz duplicated successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to duplicate quiz', 500, error.message);
  }
};

module.exports = {
  createQuiz,
  addQuestion,
  getQuiz,
  updateQuiz,
  updateQuestion,
  deleteQuestion,
  submitQuiz,
  getStudentQuizAttempts,
  getAllMyQuizAttempts,
  getQuizTemplates,
  duplicateQuiz
};
