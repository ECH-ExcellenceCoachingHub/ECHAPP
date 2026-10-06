const Section = require('../../models/Section');
const Lesson = require('../../models/Lesson');
const Quiz = require('../../models/Quiz');
const Question = require('../../models/Question');
const Course = require('../../models/Course');
const CourseBuildJob = require('../../models/CourseBuildJob');
const CourseBuildItem = require('../../models/CourseBuildItem');

/**
 * Publishes approved draft items into the live course structure:
 *   chapter        → Section
 *   lesson         → Lesson (+ lesson Quiz when it has questions)
 *   revision       → Lesson (notes)
 *   chapter_test   → Lesson + Quiz (type "test")
 *   mock_exam      → "Exam Preparation" Section → Lesson + Quiz (type "exam")
 * Re-publishing an item that was edited after publishing updates it in place.
 */

const SECONDS_PER_QUESTION = 90;

async function publishApproved(jobId, { chapterIndex = null, itemIds = null } = {}) {
  const job = await CourseBuildJob.findById(jobId);
  if (!job) throw new Error('Job not found');

  const filter = {
    jobId,
    $or: [{ status: 'approved' }, { status: 'published', dirtyAfterPublish: true }],
  };
  if (chapterIndex != null) filter.chapterIndex = chapterIndex;
  if (itemIds) filter._id = { $in: itemIds };

  const items = await CourseBuildItem.find(filter);
  items.sort((a, b) => (a.chapterIndex ?? 1e9) - (b.chapterIndex ?? 1e9) || a.order - b.order);

  let published = 0;
  for (const item of items) {
    const sectionId = await ensureSection(job, item);
    await publishItem(job, item, sectionId);
    published++;
  }
  await job.save();
  await fillCourseDetails(job);
  return { published };
}

async function ensureSection(job, item) {
  if (item.kind === 'mock_exam') {
    if (job.mockSectionId && await Section.exists({ _id: job.mockSectionId })) return job.mockSectionId;
    const s = await Section.create({ courseId: job.courseId, title: 'Exam Preparation', order: await nextSectionOrder(job.courseId) });
    job.mockSectionId = s._id;
    return s._id;
  }
  const chapter = job.outline.chapters.find(c => c.index === item.chapterIndex);
  if (!chapter) throw new Error(`Chapter ${item.chapterIndex} not found in outline`);
  if (chapter.publishedSectionId && await Section.exists({ _id: chapter.publishedSectionId })) {
    return chapter.publishedSectionId;
  }
  const s = await Section.create({
    courseId: job.courseId,
    title: chapter.title.slice(0, 200),
    order: await nextSectionOrder(job.courseId),
  });
  chapter.publishedSectionId = s._id;
  job.markModified('outline');
  return s._id;
}

async function nextSectionOrder(courseId) {
  const last = await Section.findOne({ courseId }).sort({ order: -1 }).select('order').lean();
  return last ? last.order + 1 : 0;
}

/** Lessons keep the draft order inside their chapter: lessons, revision, then test. */
async function lessonOrder(sectionId, item) {
  const siblings = await Lesson.find({ sectionId }).select('order buildItemId').lean();
  if (!siblings.length) return 0;
  const draftOrders = await CourseBuildItem.find({ _id: { $in: siblings.map(s => s.buildItemId).filter(Boolean) } }).select('order').lean();
  const byId = new Map(draftOrders.map(d => [String(d._id), d.order]));
  const before = siblings.filter(s => !s.buildItemId || (byId.get(String(s.buildItemId)) ?? -1) < item.order);
  const maxBefore = before.length ? Math.max(...before.map(s => s.order)) : -1;
  // Shift later lessons down to make room
  await Lesson.updateMany({ sectionId, order: { $gt: maxBefore } }, { $inc: { order: 1 } });
  return maxBefore + 1;
}

async function publishItem(job, item, sectionId) {
  const content = item.content || null;
  const questions = item.questions || [];
  const hasQuestions = questions.length > 0;
  const isUpdate = !!item.published?.lessonId && await Lesson.exists({ _id: item.published.lessonId });

  const lessonTypeByKind = {
    lesson: content && hasQuestions ? 'Notes + Quiz' : content ? 'Notes' : 'Quiz',
    revision: 'Notes',
    chapter_test: 'Quiz',
    mock_exam: 'Quiz',
  };

  const lessonFields = {
    title: item.title.slice(0, 200),
    description: (content?.summary || describeQuiz(item)).slice(0, 1000),
    notes: content ? contentToMarkdown(item.title, content) : null,
    duration: content?.estimatedMinutes || Math.max(5, Math.round((questions.length * SECONDS_PER_QUESTION) / 60)),
    lessonType: lessonTypeByKind[item.kind],
    aiContent: content ? { ...content, kind: item.kind } : null,
    aiGenerated: true,
    buildItemId: item._id,
    isPublished: true,
    status: 'completed',
  };

  let lesson;
  if (isUpdate) {
    lesson = await Lesson.findByIdAndUpdate(item.published.lessonId, { $set: lessonFields }, { new: true });
  } else {
    lesson = await Lesson.create({
      ...lessonFields,
      sectionId,
      courseId: job.courseId,
      order: await lessonOrder(sectionId, item),
    });
  }

  let quizId = item.published?.quizId || null;
  if (hasQuestions) {
    const quizType = item.kind === 'mock_exam' ? 'exam' : item.kind === 'chapter_test' ? 'test' : 'quiz';
    const quizFields = {
      title: item.kind === 'lesson' ? `${item.title} — Quiz`.slice(0, 200) : item.title.slice(0, 200),
      description: describeQuiz(item),
      courseId: job.courseId,
      sectionId,
      type: quizType,
      passingScore: item.kind === 'mock_exam' ? 60 : 70,
      timeLimit: questions.length * SECONDS_PER_QUESTION,
      questionsCount: questions.length,
      isPublished: true,
      shuffleOptions: false,
      showCorrectAnswers: true,
      allowReview: true,
      maxAttempts: item.kind === 'lesson' ? 5 : 3,
      instructions: item.kind === 'mock_exam'
        ? 'Answer all questions under exam conditions. Explanations and book references are shown after you submit.'
        : 'Answer every question. Explanations and book references are shown after you submit.',
    };
    if (quizId && await Quiz.exists({ _id: quizId })) {
      await Quiz.updateOne({ _id: quizId }, { $set: quizFields });
      await Question.deleteMany({ quizId });
    } else {
      quizId = (await Quiz.create(quizFields))._id;
    }
    await Question.insertMany(questions.map(q => toAppQuestion(q, quizId)));
    await Lesson.updateOne({ _id: lesson._id }, { $set: { quizId } });
  } else if (quizId) {
    await Question.deleteMany({ quizId });
    await Quiz.deleteOne({ _id: quizId });
    await Lesson.updateOne({ _id: lesson._id }, { $set: { quizId: null } });
    quizId = null;
  }

  item.status = 'published';
  item.dirtyAfterPublish = false;
  item.published = { sectionId, lessonId: lesson._id, quizId, at: new Date() };
  await item.save();
}

function describeQuiz(item) {
  const n = item.questions?.length || 0;
  if (item.kind === 'mock_exam') return `Full mock exam — ${n} questions across the course.`;
  if (item.kind === 'chapter_test') return `Chapter test — ${n} questions.`;
  return n ? `${n} practice questions.` : '';
}

/** Map a draft question onto the app's Question model (auto-gradable where possible). */
function toAppQuestion(q, quizId) {
  const sourceLine = formatSource(q.source);
  const explanation = [q.explanation, sourceLine].filter(Boolean).join('\n\n');
  const base = {
    quizId,
    text: q.question,
    explanation,
    difficulty: q.difficulty || 'medium',
    points: q.difficulty === 'hard' ? 2 : 1,
    source: { chapter: q.source?.chapter, section: q.source?.section, page: q.source?.page },
    aiGenerated: true,
    aiConfidence: q.confidence,
  };

  if (q.type === 'true_false') {
    return {
      ...base,
      type: 'true_false',
      options: [{ text: 'True', isCorrect: q.correctIndex === 0 }, { text: 'False', isCorrect: q.correctIndex === 1 }],
      correctAnswer: q.correctIndex,
    };
  }
  if (q.options && q.options.length >= 2 && q.correctIndex != null) {
    return {
      ...base,
      type: 'mcq',
      options: q.options.map((text, i) => ({ text, isCorrect: i === q.correctIndex })),
      correctAnswer: q.correctIndex,
    };
  }
  // Short answers: a few words can be auto-marked as fill-in-the-blank; longer ones need marking
  const answer = String(q.answer || '').trim();
  const shortAnswer = answer.split(/\s+/).length <= 4;
  return {
    ...base,
    type: shortAnswer ? 'fill_blank' : 'essay',
    options: [],
    correctAnswer: answer,
  };
}

function formatSource(source) {
  if (!source) return '';
  const parts = [source.chapter, source.section].filter(Boolean);
  if (source.page) parts.push(`page ${source.page}`);
  return parts.length ? `📖 Source: ${parts.join(' › ')}` : '';
}

/** Markdown version of the structured content (older app versions, AI tutor context, downloads). */
function contentToMarkdown(title, c) {
  const out = [`# ${title}`];
  if (c.summary) out.push(`> ${c.summary}`);
  if (c.learningObjectives?.length) out.push('## Learning objectives', c.learningObjectives.map(o => `- ${o}`).join('\n'));
  if (c.notes) out.push(c.notes);
  if (c.keyPoints?.length) out.push('## Key points', c.keyPoints.map(p => `- ${p}`).join('\n'));
  if (c.keyTerms?.length) out.push('## Key terms', c.keyTerms.map(t => `- **${t.term}** — ${t.definition}`).join('\n'));
  if (c.formulas?.length) {
    out.push('## Formulas', c.formulas.map(f => {
      const vars = (f.variables || []).map(v => `  - \`${v.symbol}\` = ${v.meaning}`).join('\n');
      return `- **${f.name || 'Formula'}:** \`${f.expression}\`${f.explanation ? ` — ${f.explanation}` : ''}${vars ? `\n${vars}` : ''}`;
    }).join('\n'));
  }
  if (c.examples?.length) out.push('## Worked examples', c.examples.map(e => `### ${e.title || 'Example'}\n${e.body}`).join('\n\n'));
  if (c.examTips?.length) out.push('## Exam tips', c.examTips.map(t => `- ${t}`).join('\n'));
  if (c.commonMistakes?.length) out.push('## Common mistakes', c.commonMistakes.map(t => `- ${t}`).join('\n'));
  if (c.sources?.length) out.push(`---\n*Source pages: ${[...new Set(c.sources.map(s => s.page))].join(', ')}*`);
  return out.join('\n\n');
}

/** Fill empty course fields from the book analysis — never overwrite the teacher's own text. */
async function fillCourseDetails(job) {
  const course = await Course.findById(job.courseId);
  if (!course) return;
  let changed = false;
  if (!course.learningObjectives?.length) {
    const items = await CourseBuildItem.find({ jobId: job._id, kind: 'lesson', status: 'published' }).select('content.learningObjectives').limit(8).lean();
    const objectives = [...new Set(items.flatMap(i => i.content?.learningObjectives || []))].slice(0, 8);
    if (objectives.length) { course.learningObjectives = objectives; changed = true; }
  }
  if (changed) await course.save();
}

module.exports = { publishApproved, contentToMarkdown, toAppQuestion };
