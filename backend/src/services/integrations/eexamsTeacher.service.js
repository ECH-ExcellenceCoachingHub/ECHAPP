/**
 * Teacher tools on top of eexams.net.
 *
 * The planner tools (Lesson Plan, Slides, Exercises, Scheme of Work) are ECH
 * features whose engine runs on eexams; exams are created from ECH but saved
 * and managed on eexams. ECH's backend calls eexams server-to-server on the
 * teacher's behalf:
 *   X-ECH-Service: ECH_EEXAMS_SSO_SECRET   X-ECH-User: <ECH user id>
 * so the teacher is never "logged in" to eexams by the app (which would end
 * their eexams browser session on paid accounts).
 *
 * Monthly planner limits are ECH's (ECH_PLANNER_LIMITS) and are enforced by the
 * eexams quota engine, which counts each teacher's saved items per month.
 */
const { isEmailVerified } = require('./eexams.service');

const DEFAULT_LIMITS = { lessonPlansPerMonth: 4, slidesPerMonth: 3, exercisesPerMonth: 3, schemesPerMonth: 1 };

const config = () => ({
  apiUrl: (process.env.EEXAMS_API_URL || 'https://eexamsbackend.onrender.com/api').replace(/\/+$/, ''),
  secret: process.env.ECH_EEXAMS_SSO_SECRET || '',
});

function plannerLimits() {
  try {
    const raw = process.env.ECH_PLANNER_LIMITS ? JSON.parse(process.env.ECH_PLANNER_LIMITS) : {};
    const out = { ...DEFAULT_LIMITS };
    for (const k of Object.keys(DEFAULT_LIMITS)) if (Number.isFinite(Number(raw[k]))) out[k] = Number(raw[k]);
    return out;
  } catch {
    return { ...DEFAULT_LIMITS };
  }
}

const serviceHeaders = (user) => ({
  'X-ECH-Service': config().secret,
  'X-ECH-User': String(user._id),
  'X-ECH-Planner-Limits': JSON.stringify(plannerLimits()),
});

class EexamsError extends Error {
  constructor(status, body) {
    super(body?.message || `eexams responded ${status}`);
    this.status = status;
    this.body = body || {};
  }
}

// Remember recent successful provisioning so every request doesn't repeat it.
const provisioned = new Map(); // userId -> expiresAt
const PROVISION_TTL = 10 * 60 * 1000;

/** Makes sure the ECH user has a linked eexams account (teacher for instructors). */
async function provision(user, { force = false } = {}) {
  const key = String(user._id);
  if (!force && (provisioned.get(key) || 0) > Date.now()) return { linked: true, cached: true };
  const { apiUrl, secret } = config();
  if (!secret) throw new EexamsError(503, { message: 'eexams integration is not configured' });

  const res = await fetch(`${apiUrl}/auth/ech/provision`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-ECH-Service': secret },
    body: JSON.stringify({
      echUserId: key,
      email: user.email || null,
      emailVerified: await isEmailVerified(user),
      fullName: user.fullName || '',
      phone: user.phone || null,
      role: user.role,
    }),
    signal: AbortSignal.timeout(30000),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new EexamsError(res.status, body);
  provisioned.set(key, Date.now() + PROVISION_TTL);
  if (provisioned.size > 5000) for (const [k, t] of provisioned) if (t < Date.now()) provisioned.delete(k);
  return body;
}

/** JSON call to eexams as the user. */
async function callJson(user, method, path, body, { timeout = 120000 } = {}) {
  await provision(user);
  const res = await fetch(`${config().apiUrl}${path}`, {
    method,
    headers: { ...serviceHeaders(user), ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}) },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(timeout),
  });
  const text = await res.text();
  let json;
  try { json = text ? JSON.parse(text) : null; } catch { json = { message: text.slice(0, 300) }; }
  if (!res.ok) {
    if (res.status === 401 && json?.code === 'ECH_NOT_LINKED') provisioned.delete(String(user._id));
    throw new EexamsError(res.status, json);
  }
  return json;
}

const PASS_HEADERS = ['content-type', 'content-disposition'];

/**
 * Streams an incoming ECH request through to eexams as the user and sends the
 * eexams response back unchanged (JSON, multipart uploads and file downloads).
 */
async function forward(req, res, eexamsPath, { timeout = 150000 } = {}) {
  await provision(req.user);
  const url = `${config().apiUrl}${eexamsPath}`;
  const method = req.method.toUpperCase();
  const headers = { ...serviceHeaders(req.user) };
  let body;

  if (!['GET', 'HEAD', 'DELETE'].includes(method)) {
    const ctype = req.headers['content-type'] || '';
    if (ctype.startsWith('multipart/form-data')) {
      // Not parsed by express.json — pass the raw upload straight through.
      headers['content-type'] = ctype;
      body = req;
    } else {
      headers['content-type'] = 'application/json';
      body = JSON.stringify(req.body || {});
    }
  }

  const upstream = await fetch(url, { method, headers, body, duplex: body === req ? 'half' : undefined, signal: AbortSignal.timeout(timeout) });
  if (upstream.status === 401) provisioned.delete(String(req.user._id));
  res.status(upstream.status);
  for (const h of PASS_HEADERS) {
    const v = upstream.headers.get(h);
    if (v) res.setHeader(h, v);
  }
  return res.send(Buffer.from(await upstream.arrayBuffer()));
}

// ── Exams (created from ECH, saved + managed on eexams) ─────────────────────

/** Mirrors the eexams client's draft payload (TeacherDashboard handleSaveDraft). */
function toDraft(generated, { level, subLevel }) {
  const questions = (generated.questions || []).map((q) => ({
    text: q.text,
    type: q.type || 'multiple-choice',
    marks: q.marks || q.points || 1,
    difficulty: q.difficulty || 'medium',
    correctAnswer: q.correctAnswer || '',
    options: q.options || [],
    allowMultipleAnswers: q.allowMultipleAnswers === true,
    multipleAnswerScoring: q.multipleAnswerScoring || 'partial',
    explanation: q.explanation || q.answerKey || '',
    answerKey: q.answerKey || q.explanation || '',
    gradingCriteria: q.gradingCriteria || q.keyPoints || [],
    keyPoints: q.keyPoints || q.gradingCriteria || [],
    acceptableAnswers: q.acceptableAnswers || [],
    section: q.section || 'A',
    leftItems: q.leftItems,
    rightItems: q.rightItems,
    items: q.items,
    matchingPairs: q.matchingPairs,
    itemsToOrder: q.itemsToOrder,
    passage: q.passage,
    instructions: q.instructions,
    wordBank: q.wordBank,
    subQuestions: q.subQuestions || [],
    subQuestionConfig: q.subQuestionConfig || { mode: 'all', requiredCount: 1, scoringType: 'partial' },
    imageUrl: q.imageUrl || '',
    imageUrls: q.imageUrls || [],
    spreadsheetTemplate: q.spreadsheetTemplate,
    spreadsheetModelAnswer: q.spreadsheetModelAnswer,
  }));
  return {
    title: generated.title,
    description: generated.description || generated.title,
    timeLimit: generated.timeLimit || 60,
    passingScore: generated.passingScore || 70,
    totalMarks: generated.totalMarks || questions.reduce((s, q) => s + (q.marks || 1), 0),
    level: level || undefined,
    subLevel: subLevel || undefined,
    accessType: 'subscription',
    sections: generated.sections || [],
    questions,
  };
}

/** AI-describe an exam on eexams and save it there as a draft. */
async function createExamWithAi(user, { prompt, level, subLevel }) {
  const generated = await callJson(user, 'POST', '/exam/ai-generate', { prompt }, { timeout: 180000 });
  if (!generated?.questions?.length) throw new EexamsError(422, { message: 'The AI did not return any questions. Try describing the exam in more detail.' });
  const saved = await callJson(user, 'POST', '/exam/save-draft', toDraft(generated, { level, subLevel }), { timeout: 180000 });
  return {
    examId: String(saved.examId || saved.exam?._id),
    title: generated.title,
    questionCount: generated.questions.length,
    totalMarks: generated.totalMarks || null,
  };
}

/** The teacher's exams on eexams (title + status), newest first. */
async function listExams(user) {
  const exams = await callJson(user, 'GET', '/admin/exams');
  return (Array.isArray(exams) ? exams : []).map((e) => ({
    id: String(e._id),
    title: e.title,
    status: e.status || (e.isLocked ? 'locked' : 'draft'),
    timeLimit: e.timeLimit,
    createdAt: e.createdAt,
    students: e.studentsCount ?? e.totalStudents ?? null,
    completions: e.completedCount ?? e.completions ?? null,
  })).sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
}

module.exports = { provision, callJson, forward, createExamWithAi, listExams, plannerLimits, EexamsError };
