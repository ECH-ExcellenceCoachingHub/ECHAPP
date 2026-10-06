const multer = require('multer');
const mongoose = require('mongoose');
const Course = require('../models/Course');
const CourseBuildJob = require('../models/CourseBuildJob');
const CourseBuildItem = require('../models/CourseBuildItem');
const CourseBuildSource = require('../models/CourseBuildSource');
const runner = require('../services/course-builder/runner.service');
const { publishApproved, contentToMarkdown, toAppQuestion } = require('../services/course-builder/publisher.service');
const { gradeOpenAnswers } = require('../services/answer-grading.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

const ALLOWED_EXT = /\.(pdf|docx?|txt|md)$/i;
const MODES = ['full', 'selected', 'lessons_only', 'quizzes_only', 'exam_prep', 'revision', 'mock_exam'];
const BUSY = ['uploaded', 'extracting', 'analyzing', 'generating'];

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 150 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_EXT.test(file.originalname || '')) return cb(null, true);
    cb(new Error('Only PDF, DOCX, DOC, TXT or MD books are supported'));
  },
});

// ─── Access control ───────────────────────────────────────────────────────────

async function canManageCourse(user, courseId) {
  if (!user || !mongoose.isValidObjectId(courseId)) return false;
  if (user.role === 'admin') return true;
  if (user.role !== 'instructor') return false;
  const course = await Course.findById(courseId).select('assignedTeacherIds createdBy').lean();
  if (!course) return false;
  const uid = String(user._id || user.id);
  return String(course.createdBy) === uid || (course.assignedTeacherIds || []).some(id => String(id) === uid);
}

async function loadJob(req, res) {
  if (!mongoose.isValidObjectId(req.params.jobId)) { sendNotFound(res, 'Build not found'); return null; }
  const job = await CourseBuildJob.findById(req.params.jobId);
  if (!job) { sendNotFound(res, 'Build not found'); return null; }
  if (!(await canManageCourse(req.user, job.courseId))) { sendForbidden(res, 'You cannot manage this course'); return null; }
  return job;
}

async function loadItem(req, res) {
  if (!mongoose.isValidObjectId(req.params.itemId)) { sendNotFound(res, 'Item not found'); return null; }
  const item = await CourseBuildItem.findById(req.params.itemId);
  if (!item) { sendNotFound(res, 'Item not found'); return null; }
  if (!(await canManageCourse(req.user, item.courseId))) { sendForbidden(res, 'You cannot manage this course'); return null; }
  return item;
}

function sanitizeOptions(input = {}, base = {}) {
  const o = { ...base };
  const int = (v, min, max) => Math.max(min, Math.min(max, parseInt(v, 10) || 0));
  if (input.mode && MODES.includes(input.mode)) o.mode = input.mode;
  if (input.questionsPerLesson != null) o.questionsPerLesson = int(input.questionsPerLesson, 0, 30);
  if (input.chapterTestQuestions != null) o.chapterTestQuestions = int(input.chapterTestQuestions, 0, 60);
  if (input.mockExamQuestions != null) o.mockExamQuestions = int(input.mockExamQuestions, 0, 200);
  if (input.difficultyMix) {
    o.difficultyMix = {
      easy: int(input.difficultyMix.easy, 0, 100),
      medium: int(input.difficultyMix.medium, 0, 100),
      hard: int(input.difficultyMix.hard, 0, 100),
    };
  }
  if (Array.isArray(input.questionTypes)) {
    const allowed = ['mcq', 'true_false', 'short_answer', 'calculation', 'scenario'];
    const types = input.questionTypes.filter(t => allowed.includes(t));
    if (types.length) o.questionTypes = types;
  }
  for (const k of ['examStyle', 'instructions', 'language']) {
    if (typeof input[k] === 'string') o[k] = input[k].slice(0, 2000);
  }
  for (const k of ['includeVisuals', 'includeFlashcards', 'autoGenerate']) {
    if (input[k] != null) o[k] = input[k] === true || input[k] === 'true';
  }
  return o;
}

const ITEM_SUMMARY_PROJECTION = {
  kind: 1, chapterIndex: 1, order: 1, title: 1, pageStart: 1, pageEnd: 1, status: 1,
  confidence: 1, warnings: 1, error: 1, published: 1, dirtyAfterPublish: 1, generationMs: 1, updatedAt: 1,
  questionCount: { $size: { $ifNull: ['$questions', []] } },
  unverifiedCount: { $size: { $filter: { input: { $ifNull: ['$questions', []] }, cond: { $eq: ['$$this.verified', false] } } } },
  visualCount: { $size: { $ifNull: ['$content.visuals', []] } },
  hasContent: { $gt: ['$content', null] },
  summary: '$content.summary',
};

function jobPayload(job) {
  const j = job.toObject ? job.toObject() : job;
  j.isRunning = runner.running.has(String(j._id));
  return j;
}

// ─── Jobs ─────────────────────────────────────────────────────────────────────

const listJobs = async (req, res) => {
  try {
    const { courseId } = req.params;
    if (!(await canManageCourse(req.user, courseId))) return sendForbidden(res, 'You cannot manage this course');
    const jobs = await CourseBuildJob.find({ courseId })
      .select('status source.fileName source.pageCount options.mode outline.bookTitle progress stats createdAt updatedAt error')
      .sort({ createdAt: -1 })
      .limit(30)
      .lean();
    sendSuccess(res, jobs.map(jobPayload));
  } catch (err) {
    sendError(res, 'Failed to load AI builds', 500, err.message);
  }
};

const createJob = [
  (req, res, next) => upload.single('book')(req, res, (err) => {
    if (err) return sendError(res, err.message, 400);
    next();
  }),
  async (req, res) => {
    try {
      const { courseId } = req.params;
      if (!(await canManageCourse(req.user, courseId))) return sendForbidden(res, 'You cannot manage this course');
      if (!req.file) return sendError(res, 'Please attach a book file (field "book")', 400);

      let options = {};
      try { options = typeof req.body.options === 'string' ? JSON.parse(req.body.options) : (req.body.options || {}); } catch (_) { /* ignore */ }

      const job = await CourseBuildJob.create({
        courseId,
        createdBy: req.user._id || req.user.id,
        status: 'uploaded',
        source: { fileName: req.file.originalname, mimeType: req.file.mimetype, size: req.file.size },
        options: sanitizeOptions(options, {}),
        progress: { stage: 'uploaded', percent: 1, message: 'Upload received', startedAt: new Date(), updatedAt: new Date() },
        logs: [{ at: new Date(), level: 'info', message: `Uploaded ${req.file.originalname} (${(req.file.size / 1048576).toFixed(1)} MB)` }],
      });

      // Keep a copy in S3 so an interrupted extraction can resume after a restart.
      try {
        const s3 = require('../services/s3.service');
        const stored = await s3.uploadFile(req.file.buffer, req.file.originalname, req.file.mimetype, 'course-builder');
        job.source.s3Key = stored.key;
        job.source.s3Url = stored.url;
        await job.save();
      } catch (e) {
        console.warn('[CourseBuilder] could not store source in S3:', e.message);
      }

      runner.startAnalysis(job._id, req.file.buffer);
      sendSuccess(res, jobPayload(job), 'Book uploaded — analysis started', 201);
    } catch (err) {
      sendError(res, 'Failed to start AI course build', 500, err.message);
    }
  },
];

const getJob = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    const items = await CourseBuildItem.aggregate([
      { $match: { jobId: job._id } },
      { $project: ITEM_SUMMARY_PROJECTION },
      { $sort: { chapterIndex: 1, order: 1 } },
    ]);
    sendSuccess(res, { job: jobPayload(job), items });
  } catch (err) {
    sendError(res, 'Failed to load build', 500, err.message);
  }
};

const updateOutline = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    if (BUSY.includes(job.status)) return sendError(res, 'Wait until the current step finishes', 409);

    const { outline, options } = req.body || {};
    if (outline?.chapters) {
      const pageCount = job.source.pageCount || 1;
      const clamp = (v, d) => Math.min(Math.max(1, parseInt(v, 10) || d), pageCount);
      job.outline.chapters = outline.chapters.map((c, i) => {
        const prev = job.outline.chapters.find(x => x.index === c.index);
        const pageStart = clamp(c.pageStart, 1);
        const pageEnd = Math.max(pageStart, clamp(c.pageEnd, pageCount));
        return {
          index: Number.isInteger(c.index) ? c.index : 1000 + i,
          title: String(c.title || `Chapter ${i + 1}`).slice(0, 200),
          summary: String(c.summary || ''),
          pageStart,
          pageEnd,
          selected: c.selected !== false,
          publishedSectionId: prev?.publishedSectionId || null,
          lessons: (c.lessons || []).filter(l => l && l.title).map(l => {
            const ls = Math.min(Math.max(clamp(l.pageStart, pageStart), pageStart), pageEnd);
            return { title: String(l.title).slice(0, 200), pageStart: ls, pageEnd: Math.min(Math.max(ls, clamp(l.pageEnd, pageEnd)), pageEnd) };
          }),
        };
      });
      for (const k of ['bookTitle', 'subject', 'level', 'description']) {
        if (typeof outline[k] === 'string') job.outline[k] = outline[k];
      }
      job.markModified('outline');
    }
    if (options) job.options = sanitizeOptions(options, job.toObject().options);
    await job.save();
    sendSuccess(res, jobPayload(job), 'Outline saved');
  } catch (err) {
    sendError(res, 'Failed to save outline', 500, err.message);
  }
};

const startGeneration = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    if (!job.outline?.chapters?.length) return sendError(res, 'The book has not been analysed yet', 409);
    if (runner.running.has(String(job._id))) return sendError(res, 'This build is already running', 409);
    if (req.body?.options) {
      job.options = sanitizeOptions(req.body.options, job.toObject().options);
      await job.save();
    }
    if (!job.outline.chapters.some(c => c.selected !== false)) return sendError(res, 'Select at least one chapter', 400);
    runner.startGeneration(job._id);
    sendSuccess(res, { started: true }, 'Generation started');
  } catch (err) {
    sendError(res, 'Failed to start generation', 500, err.message);
  }
};

const cancelJob = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    await runner.cancel(job._id);
    if (!runner.running.has(String(job._id)) && BUSY.includes(job.status)) {
      job.status = 'cancelled';
      await job.save();
    }
    sendSuccess(res, { cancelled: true }, 'Stopping after the items in progress finish');
  } catch (err) {
    sendError(res, 'Failed to cancel', 500, err.message);
  }
};

const retryAnalysis = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    if (runner.running.has(String(job._id))) return sendError(res, 'This build is already running', 409);
    runner.startAnalysis(job._id, null);
    sendSuccess(res, { started: true }, 'Analysis restarted');
  } catch (err) {
    sendError(res, 'Failed to restart analysis', 500, err.message);
  }
};

const deleteJob = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    await runner.cancel(job._id);
    await CourseBuildItem.deleteMany({ jobId: job._id });
    await CourseBuildSource.deleteOne({ jobId: job._id });
    if (job.source?.s3Key) {
      require('../services/s3.service').deleteFile(job.source.s3Key).catch(() => {});
    }
    await job.deleteOne();
    sendSuccess(res, { deleted: true }, 'Draft deleted (published lessons are kept)');
  } catch (err) {
    sendError(res, 'Failed to delete build', 500, err.message);
  }
};

const approveItems = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    const filter = { jobId: job._id, status: { $in: ['draft', 'needs_review'] } };
    if (req.body?.chapterIndex != null) filter.chapterIndex = Number(req.body.chapterIndex);
    if (Array.isArray(req.body?.itemIds)) filter._id = { $in: req.body.itemIds };
    const r = await CourseBuildItem.updateMany(filter, {
      $set: { status: 'approved', reviewedBy: req.user._id || req.user.id, reviewedAt: new Date() },
    });
    sendSuccess(res, { approved: r.modifiedCount }, `${r.modifiedCount} item(s) approved`);
  } catch (err) {
    sendError(res, 'Failed to approve', 500, err.message);
  }
};

const publishJob = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    const result = await publishApproved(job._id, {
      chapterIndex: req.body?.chapterIndex != null ? Number(req.body.chapterIndex) : null,
      itemIds: Array.isArray(req.body?.itemIds) ? req.body.itemIds : null,
    });
    sendSuccess(res, result, result.published ? `${result.published} item(s) published to the course` : 'Nothing approved to publish');
  } catch (err) {
    sendError(res, 'Failed to publish', 500, err.message);
  }
};

const exportQuestionBank = async (req, res) => {
  try {
    const job = await loadJob(req, res);
    if (!job) return;
    const items = await CourseBuildItem.find({ jobId: job._id, status: { $nin: ['rejected', 'error'] } })
      .select('kind title chapterIndex questions').lean();
    const rows = [];
    for (const it of items) {
      for (const q of it.questions || []) {
        rows.push({
          item: it.title, kind: it.kind, type: q.type, difficulty: q.difficulty, question: q.question,
          options: q.options || [], correctIndex: q.correctIndex, answer: q.answer, explanation: q.explanation,
          chapter: q.source?.chapter, section: q.source?.section, page: q.source?.page,
          verified: q.verified, confidence: q.confidence,
        });
      }
    }
    if (req.query.format === 'csv') {
      const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
      const header = ['item', 'kind', 'type', 'difficulty', 'question', 'optionA', 'optionB', 'optionC', 'optionD', 'correct', 'answer', 'explanation', 'chapter', 'section', 'page', 'verified', 'confidence'];
      const lines = rows.map(r => [
        r.item, r.kind, r.type, r.difficulty, r.question, r.options[0], r.options[1], r.options[2], r.options[3],
        r.correctIndex != null ? 'ABCDEFG'[r.correctIndex] : '', r.answer, r.explanation, r.chapter, r.section, r.page, r.verified, r.confidence,
      ].map(esc).join(','));
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="question-bank-${job._id}.csv"`);
      return res.send([header.join(','), ...lines].join('\n'));
    }
    sendSuccess(res, { book: job.outline?.bookTitle, count: rows.length, questions: rows });
  } catch (err) {
    sendError(res, 'Failed to export question bank', 500, err.message);
  }
};

// ─── Items ────────────────────────────────────────────────────────────────────

const getItem = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    sendSuccess(res, item);
  } catch (err) {
    sendError(res, 'Failed to load item', 500, err.message);
  }
};

const updateItem = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    if (item.status === 'generating') return sendError(res, 'This item is being generated — try again in a moment', 409);
    const { title, content, questions } = req.body || {};
    if (typeof title === 'string' && title.trim()) item.title = title.trim().slice(0, 200);
    if (content !== undefined) {
      item.content = content;
      item.markModified('content');
    }
    if (Array.isArray(questions)) {
      item.questions = questions
        .filter(q => q && q.question)
        .map(q => ({
          ...q,
          options: Array.isArray(q.options) ? q.options.map(String) : [],
          // Teacher-edited questions are considered reviewed
          confidence: q.edited ? 100 : q.confidence,
          verified: q.edited ? true : q.verified,
        }));
    }
    if (item.status === 'published') item.dirtyAfterPublish = true;
    else if (['draft', 'needs_review', 'error'].includes(item.status)) item.status = 'draft';
    await item.save();
    await runner.refreshStats(item.jobId);
    sendSuccess(res, item, 'Saved');
  } catch (err) {
    sendError(res, 'Failed to save item', 500, err.message);
  }
};

const setItemStatus = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    const { status } = req.body || {};
    if (!['approved', 'rejected', 'draft'].includes(status)) return sendError(res, 'Invalid status', 400);
    if (item.status === 'published' && status !== 'approved') return sendError(res, 'Already published — edit it, or remove the lesson from the course', 409);
    if (['pending', 'generating'].includes(item.status)) return sendError(res, 'Wait until generation finishes', 409);
    if (item.status !== 'published') item.status = status;
    item.reviewedBy = req.user._id || req.user.id;
    item.reviewedAt = new Date();
    await item.save();
    sendSuccess(res, item);
  } catch (err) {
    sendError(res, 'Failed to update status', 500, err.message);
  }
};

const regenerateItem = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    if (item.status === 'generating') return sendError(res, 'Already generating', 409);
    const part = ['all', 'content', 'questions'].includes(req.body?.part) ? req.body.part : 'all';
    await runner.regenerateItem(item._id, { part, instructions: String(req.body?.instructions || '').slice(0, 1000) });
    sendSuccess(res, { started: true }, 'Regenerating…');
  } catch (err) {
    sendError(res, 'Failed to regenerate', 500, err.message);
  }
};

const regenerateQuestion = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    const q = await runner.regenerateQuestion(item._id, req.params.questionId, String(req.body?.instructions || '').slice(0, 1000));
    sendSuccess(res, q, 'Question regenerated');
  } catch (err) {
    sendError(res, 'Failed to regenerate question', 500, err.message);
  }
};

const getSourcePages = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    const src = await CourseBuildSource.findOne({ jobId: item.jobId }).select('pages').lean();
    const from = Math.max(item.pageStart || 1, parseInt(req.query.from, 10) || item.pageStart || 1);
    const to = Math.min(item.pageEnd || from, parseInt(req.query.to, 10) || item.pageEnd || from, from + 9);
    sendSuccess(res, (src?.pages || []).filter(p => p.n >= from && p.n <= to));
  } catch (err) {
    sendError(res, 'Failed to load source pages', 500, err.message);
  }
};

// ─── Student-view preview of a draft ─────────────────────────────────────────

const PREVIEW_SECONDS_PER_QUESTION = 90;
const LESSON_TYPE_BY_KIND = { revision: 'Notes', chapter_test: 'Quiz', mock_exam: 'Quiz' };

/** The draft as the lesson viewer sees a published lesson: lesson + quiz + questions. */
function draftAsLesson(item) {
  const id = String(item._id);
  const content = item.content || null;
  const hasQuestions = (item.questions || []).length > 0;
  const quizType = item.kind === 'mock_exam' ? 'exam' : item.kind === 'chapter_test' ? 'test' : 'quiz';
  return {
    lesson: {
      _id: id,
      sectionId: `draft-${item.jobId}-${item.chapterIndex}`,
      courseId: String(item.courseId),
      title: item.title,
      description: content?.summary || '',
      notes: content ? contentToMarkdown(item.title, content) : null,
      aiContent: content ? { ...content, kind: item.kind } : null,
      aiGenerated: true,
      quizId: hasQuestions ? `draft-${id}` : null,
      lessonType: LESSON_TYPE_BY_KIND[item.kind] || (content && hasQuestions ? 'Notes + Quiz' : content ? 'Notes' : 'Quiz'),
      duration: content?.estimatedMinutes || 10,
      order: item.order,
      status: 'completed',
      isPublished: false,
    },
    quiz: hasQuestions ? {
      _id: `draft-${id}`,
      title: item.kind === 'lesson' ? `${item.title} — Quiz` : item.title,
      type: quizType,
      passingScore: item.kind === 'mock_exam' ? 60 : 70,
      timeLimit: item.questions.length * PREVIEW_SECONDS_PER_QUESTION,
      questionsCount: item.questions.length,
      isPublished: false,
    } : null,
    questions: (item.questions || []).map(q => ({ ...toAppQuestion(q, `draft-${id}`), _id: String(q._id) })),
  };
}

const previewItem = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    // Neighbouring drafts in the same chapter, for Previous / Next
    const siblings = await CourseBuildItem.find({
      jobId: item.jobId,
      chapterIndex: item.chapterIndex,
      status: { $nin: ['rejected', 'error', 'pending', 'generating'] },
    }).select('title kind order').sort({ order: 1 }).lean();
    sendSuccess(res, {
      ...draftAsLesson(item),
      siblings: siblings.map(s => ({ _id: String(s._id), title: s.title, kind: s.kind })),
    });
  } catch (err) {
    sendError(res, 'Failed to build preview', 500, err.message);
  }
};

/** Grade a preview attempt exactly like a real submission, without saving it. */
const previewSubmit = async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (!item) return;
    const { questions, quiz } = draftAsLesson(item);
    const answers = Array.isArray(req.body?.answers) ? req.body.answers : [];
    const results = [];
    const open = [];
    let totalScore = 0;
    let maxScore = 0;

    for (const q of questions) {
      const a = answers.find(x => String(x.questionId) === q._id) || {};
      const points = q.points || 1;
      const selected = a.selectedOption != null && a.selectedOption !== '' ? Number(a.selectedOption) : null;
      let isCorrect = false;
      if (q.type === 'mcq' || q.type === 'true_false') {
        isCorrect = selected === q.correctAnswer;
      } else {
        const text = String(a.answerText ?? a.selectedOption ?? '').trim();
        isCorrect = q.type === 'fill_blank' && text.toLowerCase() === String(q.correctAnswer).trim().toLowerCase();
        if (!isCorrect && text) {
          open.push({ index: results.length, id: String(results.length), question: q.text, type: q.type, modelAnswer: q.correctAnswer, guidance: q.explanation, studentAnswer: text, points });
        }
      }
      const score = isCorrect ? points : 0;
      results.push({
        questionId: q._id,
        questionType: q.type,
        question: q.text,
        options: q.options,
        correctAnswer: q.correctAnswer,
        userAnswer: { selectedOption: Number.isFinite(selected) ? selected : null, answerText: a.answerText ?? '' },
        isCorrect,
        score,
        maxScore: points,
        explanation: q.explanation,
      });
      totalScore += score;
      maxScore += points;
    }

    if (open.length) {
      const graded = await gradeOpenAnswers(open);
      for (const o of open) {
        const g = graded.get(o.id);
        if (!g) continue;
        const r = results[o.index];
        totalScore += g.earnedPoints - r.score;
        Object.assign(r, { score: g.earnedPoints, isCorrect: g.isCorrect, feedback: g.feedback, gradedBy: g.gradedBy });
      }
    }

    const percentage = maxScore > 0 ? Math.round((totalScore / maxScore) * 100) : 0;
    sendSuccess(res, {
      _id: `preview-${Date.now()}`,
      examId: quiz?._id,
      totalScore,
      maxScore,
      percentage,
      passed: percentage >= (quiz?.passingScore || 70),
      needsManualGrading: false,
      results,
      submittedAt: new Date(),
      preview: true,
    }, 'Preview attempt graded (not saved)');
  } catch (err) {
    sendError(res, 'Failed to grade preview', 500, err.message);
  }
};

module.exports = {
  previewItem,
  previewSubmit,
  listJobs,
  createJob,
  getJob,
  updateOutline,
  startGeneration,
  cancelJob,
  retryAnalysis,
  deleteJob,
  approveItems,
  publishJob,
  exportQuestionBank,
  getItem,
  updateItem,
  setItemStatus,
  regenerateItem,
  regenerateQuestion,
  getSourcePages,
};
