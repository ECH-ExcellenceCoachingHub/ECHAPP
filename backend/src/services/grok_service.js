const Groq = require("groq-sdk");

// Models that can't be used for chat completions (speech, TTS, moderation)
const NON_CHAT_MODEL_PATTERN = /whisper|orpheus|guard|tts/i;
const REASONING_MODEL_PATTERN = /gpt-oss|qwen3/i;

class GrokService {
  static PREFERRED_MODELS = [
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
    "qwen/qwen3.8-27b",
  ];

  constructor() {
    this.apiKey = process.env.GROQ_API_KEY;
    if (!this.apiKey) {
      console.warn("GROQ_API_KEY not found. AI features will be disabled.");
    }

    this.groq = this.apiKey ? new Groq({ apiKey: this.apiKey }) : null;

    this.currentModel = "openai/gpt-oss-120b";
    this.modelCache = new Map();
    this.lastModelCheck = null;
    this.modelCheckInterval = 24 * 60 * 60 * 1000; // 24 hours

    // Resolved once per extraction run — avoids mid-run model switches
    this._activeModel = null;

    console.log("GrokService initialized:", this.isConfigured() ? "Ready" : "Not configured");
    console.log("Current AI model:", this.currentModel);
  }

  // ─── Configuration ───────────────────────────────────────────────────────────

  isConfigured() {
    return !!this.apiKey && !!this.groq;
  }

  getCurrentModel() {
    return this.currentModel;
  }

  setCurrentModel(modelName) {
    console.log(`Updating model: ${this.currentModel} → ${modelName}`);
    this.currentModel = modelName;
  }

  /**
   * Wrapper around chat.completions.create. Reasoning models (gpt-oss, qwen3) spend
   * max_tokens on hidden reasoning, so keep effort low or short outputs come back empty.
   */
  _createCompletion(params) {
    if (REASONING_MODEL_PATTERN.test(params.model) && params.reasoning_effort === undefined) {
      params = { ...params, reasoning_effort: "low" };
    }
    return this.groq.chat.completions.create(params);
  }

  // ─── Model Management ────────────────────────────────────────────────────────

  shouldCheckModel() {
    if (!this.lastModelCheck) return true;
    return Date.now() - this.lastModelCheck > this.modelCheckInterval;
  }

  async testModelAvailability(modelName) {
    const cached = this.modelCache.get(modelName);
    if (cached && Date.now() - cached.timestamp < this.modelCheckInterval) {
      return cached.available;
    }

    try {
      await this._createCompletion({
        messages: [{ role: "user", content: "ping" }],
        model: modelName,
        max_tokens: 1,
        temperature: 0,
      });
      this.modelCache.set(modelName, { available: true, timestamp: Date.now() });
      return true;
    } catch (error) {
      this.modelCache.set(modelName, {
        available: false,
        timestamp: Date.now(),
        error: error.message,
      });
      if (error.message.includes("decommissioned") || error.message.includes("not found")) {
        console.warn(`Model ${modelName} is no longer available: ${error.message}`);
      }
      return false;
    }
  }

  async autoUpdateModel() {
    if (!this.shouldCheckModel()) return this.currentModel;

    console.log("Checking model availability...");
    this.lastModelCheck = Date.now();

    const currentWorks = await this.testModelAvailability(this.currentModel);
    if (currentWorks) return this.currentModel;

    console.log(`${this.currentModel} unavailable — searching for fallback...`);

    const candidates = [...GrokService.PREFERRED_MODELS];
    // Groq retires models regularly — also consider whatever the API key can currently see
    try {
      const { data } = await this.groq.models.list();
      for (const m of data || []) {
        if (m.active !== false && !NON_CHAT_MODEL_PATTERN.test(m.id) && !candidates.includes(m.id)) {
          candidates.push(m.id);
        }
      }
    } catch (error) {
      console.warn("Could not list Groq models:", error.message);
    }

    for (const model of candidates) {
      if (model === this.currentModel) continue;
      if (await this.testModelAvailability(model)) {
        this.setCurrentModel(model);
        console.log(`✅ Auto-updated to: ${model}`);
        return model;
      }
    }

    console.error("No available fallback models found.");
    return this.currentModel;
  }

  /** Resolve model once and cache for the duration of an extraction run */
  async resolveModel() {
    if (!this._activeModel) {
      this._activeModel = await this.autoUpdateModel();
    }
    return this._activeModel;
  }

  async forceModelUpdate() {
    this.lastModelCheck = 0;
    this._activeModel = null;
    return this.autoUpdateModel();
  }

  getModelStatus() {
    return {
      currentModel: this.currentModel,
      lastCheck: this.lastModelCheck ? new Date(this.lastModelCheck).toISOString() : null,
      nextCheck: this.lastModelCheck
        ? new Date(this.lastModelCheck + this.modelCheckInterval).toISOString()
        : null,
      cachedModels: Array.from(this.modelCache.entries()).map(([model, data]) => ({
        model,
        available: data.available,
        lastChecked: new Date(data.timestamp).toISOString(),
        error: data.error,
      })),
    };
  }

  // ─── Question Extraction ─────────────────────────────────────────────────────

  /**
   * Extract and organize questions from a document using Groq AI.
   * @param {string|Object} documentInput - Text string, buffer object, or file-path object
   * @param {string} examType - "quiz" | "pastpaper" | "final"
   * @returns {Promise<Array>} Validated question objects
   */
  async extractQuestionsFromDocument(documentInput, examType) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured — set GROQ_API_KEY.");
    }

    // Reset per-run model cache so we use one model throughout
    this._activeModel = null;

    let documentText;
    let fileName = "document";

    if (typeof documentInput === "string") {
      documentText = documentInput;
      fileName = "text document";
    } else if (documentInput.buffer) {
      documentText = await this.extractTextFromBuffer(
        documentInput.buffer,
        documentInput.mimetype
      );
      fileName = documentInput.originalName || "uploaded document";
    } else if (documentInput.path) {
      const fs = require("fs");
      if (!fs.existsSync(documentInput.path)) {
        throw new Error(`File not found: ${documentInput.path}`);
      }
      const fileBuffer = fs.readFileSync(documentInput.path);
      documentText = await this.extractTextFromBuffer(fileBuffer, documentInput.mimetype);
      fileName = documentInput.originalName || "document file";
    } else {
      throw new Error("Invalid documentInput — must be string, buffer object, or file object.");
    }

    if (!documentText || documentText.trim().length === 0) {
      throw new Error("Could not extract any text from the provided document.");
    }

    console.log(`Document preview: ${documentText.substring(0, 200)}...`);

    // 6 000 chars/chunk keeps prompt + response safely within the 8 192-token limit
    const CHUNK_SIZE = 6000;
    const chunks = this.splitTextIntoChunks(documentText, CHUNK_SIZE);
    console.log(`Processing ${chunks.length} chunk(s) with model: ${await this.resolveModel()}`);

    const allQuestions = [];

    for (let i = 0; i < chunks.length; i++) {
      console.log(`→ Chunk ${i + 1}/${chunks.length}`);
      try {
        const questions = await this.processChunkWithRetry(
          chunks[i],
          examType,
          fileName,
          i + 1,
          chunks.length
        );
        console.log(`  ✓ ${questions.length} question(s) extracted`);
        allQuestions.push(...questions);
      } catch (err) {
        console.error(`  ✗ Chunk ${i + 1} failed: ${err.message}`);
      }
    }

    const unique = this.deduplicateQuestions(allQuestions);
    const valid = this.validateAndNormalizeQuestions(unique);
    console.log(`Extraction complete: ${valid.length} valid question(s) from ${allQuestions.length} raw`);
    return valid;
  }

  /**
   * Process a chunk with up to 2 retries on parse failure.
   */
  async processChunkWithRetry(chunk, examType, fileName, chunkNum, totalChunks, maxRetries = 2) {
    let lastError;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.processChunk(chunk, examType, fileName, chunkNum, totalChunks);
      } catch (err) {
        lastError = err;
        console.warn(`  Attempt ${attempt}/${maxRetries} failed: ${err.message}`);
        if (attempt < maxRetries) await this.sleep(500 * attempt);
      }
    }
    throw lastError;
  }

  /**
   * Send one chunk to the Groq API and return parsed questions.
   */
  async processChunk(chunk, examType, fileName, chunkNum, totalChunks) {
    // Deliberately compact prompt — less ambiguity, fewer hallucinations
    const prompt = `You are an expert examiner extracting and organizing exam questions from an educational document.

EXAM TYPE: ${examType}
FILE: ${fileName}
CHUNK: ${chunkNum} of ${totalChunks}

RULES:
1. Extract ONLY questions that literally appear in the text below.
2. Do NOT invent or paraphrase questions.
3. For MCQ: "correctAnswer" must be a zero-based integer index into "options".
4. For true_false: set options to ["True","False"] and correctAnswer to 0 or 1.
5. For fill_blank and open: omit "options"; set correctAnswer to the answer string.
6. Identify the "section" or topic for each question based on headings in the text.
7. If no questions are found, return {"questions":[]}.
8. Respond with ONLY valid JSON — no markdown fences, no explanation.

QUESTION SCHEMA:
{
  "questions": [
    {
      "question": "<exact question text>",
      "type": "mcq | true_false | fill_blank | open",
      "options": ["A","B","C","D"],   // MCQ and true_false only
      "correctAnswer": 0,             // integer index for MCQ/true_false; string for others
      "points": 1,
      "section": "<topic or section heading>"
    }
  ]
}

DOCUMENT TEXT:
---
${chunk}
---`;

    const model = await this.resolveModel();
    const completion = await this._createCompletion({
      model,
      messages: [{ role: "user", content: prompt }],
      temperature: 0.1,   // near-deterministic for extraction
      max_tokens: 4096,
    });

    const raw = completion.choices[0]?.message?.content ?? "";
    if (!raw.trim()) throw new Error("Empty response from Groq API");

    return this.parseQuestionsFromResponse(raw);
  }

  /**
   * Robustly parse a JSON response that may be wrapped in markdown fences
   * or contain leading/trailing prose.
   */
  parseQuestionsFromResponse(raw) {
    // 1. Try direct parse
    try {
      const parsed = JSON.parse(raw);
      return parsed.questions ?? [];
    } catch (_) { /* fall through */ }

    // 2. Strip markdown code fences and retry
    const stripped = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();
    try {
      const parsed = JSON.parse(stripped);
      return parsed.questions ?? [];
    } catch (_) { /* fall through */ }

    // 3. Extract the first {...} block
    const match = stripped.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        const parsed = JSON.parse(match[0]);
        return parsed.questions ?? [];
      } catch (_) { /* fall through */ }
    }

    // 4. Last resort — extract individual question objects from the text
    const questionBlocks = [];
    const objRegex = /\{[^{}]*"question"\s*:[^{}]*\}/g;
    let m;
    while ((m = objRegex.exec(stripped)) !== null) {
      try {
        questionBlocks.push(JSON.parse(m[0]));
      } catch (_) { /* skip malformed block */ }
    }

    if (questionBlocks.length > 0) {
      console.warn(`Partial parse: recovered ${questionBlocks.length} question object(s)`);
      return questionBlocks;
    }

    throw new Error("Could not parse any questions from Groq response");
  }

  // ─── Validation & Normalisation ──────────────────────────────────────────────

  /**
   * Validate structure and normalise correctAnswer so downstream code
   * always receives consistent types.
   */
  validateAndNormalizeQuestions(questions) {
    const validTypes = new Set(["mcq", "true_false", "fill_blank", "open"]);

    return questions.reduce((acc, q) => {
      if (!q.question || typeof q.question !== "string" || !q.question.trim()) {
        console.log("Skipped: missing question text");
        return acc;
      }

      const type = (q.type || "").toLowerCase();
      if (!validTypes.has(type)) {
        console.log(`Skipped: unknown type "${q.type}"`);
        return acc;
      }

      // ── MCQ ──────────────────────────────────────────────────────────────────
      if (type === "mcq") {
        if (!Array.isArray(q.options) || q.options.length < 2) {
          console.log(`Skipped MCQ (too few options): ${q.question.substring(0, 60)}`);
          return acc;
        }
        // Normalise correctAnswer to an integer index
        let idx = parseInt(q.correctAnswer, 10);
        if (isNaN(idx)) {
          // Model may have returned the option text instead of the index
          idx = q.options.findIndex(
            (o) => o.toLowerCase().trim() === String(q.correctAnswer).toLowerCase().trim()
          );
        }
        if (idx < 0 || idx >= q.options.length) idx = 0; // safe fallback

        acc.push({ ...q, type, correctAnswer: idx, points: q.points ?? 1, section: q.section || "" });
        return acc;
      }

      // ── True / False ─────────────────────────────────────────────────────────
      if (type === "true_false") {
        const options = Array.isArray(q.options) && q.options.length >= 2
          ? q.options
          : ["True", "False"];

        let idx = parseInt(q.correctAnswer, 10);
        if (isNaN(idx)) {
          const ans = String(q.correctAnswer).toLowerCase().trim();
          idx = ans === "true" || ans === "0" ? 0 : 1;
        }
        if (idx < 0 || idx > 1) idx = 0;

        acc.push({ ...q, type, options, correctAnswer: idx, points: q.points ?? 1, section: q.section || "" });
        return acc;
      }

      // ── Fill-blank / Open ────────────────────────────────────────────────────
      acc.push({
        ...q,
        type,
        correctAnswer: String(q.correctAnswer ?? ""),
        points: q.points ?? 1,
        section: q.section || "",
      });
      return acc;
    }, []);
  }

  // ─── Deduplication ───────────────────────────────────────────────────────────

  deduplicateQuestions(questions) {
    const seen = new Set();
    const result = [];

    for (const q of questions) {
      const text = (q.question || "").toLowerCase().trim();
      if (!text) continue;

      // Key = first 200 chars of question + first option (if any)
      const key =
        text.substring(0, 200) +
        "|" +
        (Array.isArray(q.options) ? q.options[0]?.toLowerCase().trim() ?? "" : "");

      if (seen.has(key)) {
        console.log(`Duplicate skipped: ${text.substring(0, 50)}…`);
        continue;
      }
      seen.add(key);
      result.push(q);
    }

    console.log(`Deduplication: ${questions.length} → ${result.length}`);
    return result;
  }

  // ─── Notes & Utilities ───────────────────────────────────────────────────────

  async organizeNotes(file, mimeType) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured — set GROQ_API_KEY.");
    }

    const documentText = await this.extractTextFromBuffer(file.buffer, mimeType);
    if (!documentText?.trim()) throw new Error("No text content found in document");

    // Hard-limit to avoid token overflow — no inline comment leaking into prompt
    const contentPreview = documentText.substring(0, 8000);

    const prompt = `You are an expert educational content organizer. Your goal is to transform messy or raw lesson notes into a high-quality, structured study guide.

STRUCTURE:
1. TITLE: A clear, descriptive title for the notes.
2. OVERVIEW: A brief (2-3 sentence) summary of what these notes cover.
3. STRUCTURED CONTENT: Organize into logical modules or sections:
   - Use Markdown headers (# for title, ## for sections, ### for sub-sections).
   - Use bold text for key terms and definitions.
   - Use bullet points for lists and concepts.
   - Use code blocks for any technical formulas or snippets.
4. SUMMARY: A "Key Takeaways" section at the end.

INSTRUCTIONS:
- Identify main topics and subtopics with clear headings.
- Preserve all factual information while removing redundancies.
- Include all examples, case studies, or formulas present in the source.
- If the source text is disorganized, reorder it into a logical learning sequence.
- Keep the language professional, clear, and accessible.

SOURCE NOTES:
---
${contentPreview}
---`;

    const completion = await this._createCompletion({
      model: await this.resolveModel(),
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
      max_tokens: 4096,
    });

    const result = completion.choices[0]?.message?.content;
    if (!result) throw new Error("Empty response from Groq AI");
    return result;
  }

  async generateExamTitle(documentText) {
    if (!this.isConfigured()) {
      return this.generateFallbackExamTitle();
    }

    try {
      const preview = documentText.substring(0, 1500);
      const prompt = `Generate a concise, professional exam title (maximum 50 characters) based on this content. Return ONLY the title — no quotes, no explanation.\n\nCONTENT:\n${preview}`;

      const completion = await this._createCompletion({
        model: await this.resolveModel(),
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
        max_tokens: 60,
      });

      const title = (completion.choices[0]?.message?.content || "")
        .replace(/["'\n\r]/g, "")
        .trim()
        .substring(0, 50);

      return title || this.generateFallbackExamTitle();
    } catch (error) {
      console.error("generateExamTitle error:", error.message);
      return this.generateFallbackExamTitle();
    }
  }

  async generateChatResponse(messages, _context) {
    if (!this.isConfigured()) {
      return "I apologize, but I'm currently unable to assist. Please try again later or contact our support team for help.";
    }

    // Use the fastest Groq model for real-time chat; fall back to the main model if unavailable
    const CHAT_MODEL = 'openai/gpt-oss-20b';

    try {
      const completion = await this._createCompletion({
        model: CHAT_MODEL,
        messages,
        temperature: 0.7,
        max_tokens: 800,
      });
      const response = completion.choices[0]?.message?.content;
      if (!response || response.trim().length === 0) {
        return "I'd be happy to help you! Could you please provide more details about what you'd like to know or what you're working on?";
      }
      return response;
    } catch (fastModelErr) {
      console.warn(`Fast chat model (${CHAT_MODEL}) failed: ${fastModelErr.message} — falling back to ${this.currentModel}`);
      try {
        const completion = await this._createCompletion({
          model: await this.resolveModel(),
          messages,
          temperature: 0.7,
          max_tokens: 800,
        });
        const response = completion.choices[0]?.message?.content;
        if (!response || response.trim().length === 0) {
          return "I'd be happy to help you! Could you please provide more details about what you'd like to know or what you're working on?";
        }
        return response;
      } catch (error) {
        console.error("generateChatResponse fallback error:", error.message);
        return "I apologize, but I'm having trouble processing your request right now. Please try rephrasing your question or contact support if the issue persists.";
      }
    }
  }

  // ─── Grading & Evaluation ────────────────────────────────────────────────────

  /**
   * Grade a batch of exam answers using Groq AI.
   * Handles MCQ, true_false, fill_blank, and open-ended questions.
   * @param {Array} questions - Original question objects from database
   * @param {Array} userAnswers - Student's submitted answers
   * @returns {Promise<Array>} Graded answers with earnedPoints and feedback
   */
  async gradeAnswers(questions, userAnswers) {
    if (!this.isConfigured()) {
      throw new Error("GrokService not configured for grading.");
    }

    // Format data for the prompt to minimize tokens
    const gradingData = userAnswers.map((ua) => {
      const q = questions.find((quest) => quest._id.toString() === ua.questionId.toString());
      if (!q) return null;

      const isPlaceholder = q.correctAnswer === "Sample answer" || !q.correctAnswer;

      const correctAnswerText = isPlaceholder
        ? "[MISSING - USE YOUR EXPERT KNOWLEDGE TO DETERMINE CORRECT ANSWER]"
        : (q.type === "mcq" || q.type === "true_false"
          ? (q.options && q.options[q.correctAnswer] ? q.options[q.correctAnswer] : q.correctAnswer)
          : q.correctAnswer);

      const studentAnswerText = q.type === "mcq" || q.type === "true_false"
        ? (q.options && q.options[ua.selectedOption] ? q.options[ua.selectedOption] : ua.selectedOption)
        : (ua.answerText || ua.selectedOption || "");

      return {
        id: ua.questionId.toString(),
        type: q.type,
        question: q.question,
        options: q.options,
        correctAnswer: correctAnswerText,
        studentAnswer: studentAnswerText,
        points: q.points || 1,
        isPlaceholder: isPlaceholder, // Explicitly tell the AI it's a placeholder
      };
    }).filter(Boolean);

    if (gradingData.length === 0) return [];

    const prompt = `You are an expert examiner grading a student's exam.
For each question, first determine the correct answer independently based on the question text, then compare it with the student's answer and the provided correct answer to ensure fair and accurate grading.

RULES:
1. For MCQ and true_false: The answer must match the correct answer exactly.
2. For fill_blank: Allow minor spelling errors or case differences if the meaning is identical.
3. For essay/open questions: Grade based on conceptual correctness, completeness, and understanding. 
   - Give full points if the answer demonstrates clear understanding of the core concept.
   - Give partial points (50-75%) if the answer is partially correct or lacks detail but shows basic understanding.
   - Give minimal points (25%) if the answer is relevant but incorrect or very incomplete.
   - Give 0 points only if the answer is completely irrelevant, empty, or shows no understanding.
   - Be generous - if the student's answer captures the essence of the topic, award full points even if minor details are missing.
4. IMPORTANT: If 'correctAnswer' is "[MISSING - USE YOUR EXPERT KNOWLEDGE TO DETERMINE CORRECT ANSWER]" or isPlaceholder is true, you MUST ignore it and use your own expert knowledge to determine the ACTUAL correct answer and grade the student accordingly. Do NOT grade based on the placeholder text "Sample answer".
5. Provide a brief "feedback" string for each answer (max 15 words) explaining the grade.
6. Respond ONLY with a JSON array of objects.

SCHEMA:
[
  {
    "id": "question_id",
    "earnedPoints": number,
    "feedback": "string",
    "isCorrect": boolean
  }
]

DATA TO GRADE:
${JSON.stringify(gradingData, null, 2)}`;

    try {
      const model = await this.resolveModel();
      const completion = await this._createCompletion({
        model,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1,
        max_tokens: 4096,
      });

      const raw = completion.choices[0]?.message?.content ?? "";
      const gradedResults = this.parseGradingResponse(raw);

      // Map results back to the original userAnswers format
      return await Promise.all(userAnswers.map(async (ua) => {
        const graded = gradedResults.find((g) => g.id && g.id.toString() === ua.questionId.toString());
        const q = questions.find((quest) => quest._id.toString() === ua.questionId.toString());
        
        if (graded) {
          return {
            ...ua,
            earnedPoints: graded.earnedPoints,
            feedback: graded.feedback,
            isCorrect: graded.isCorrect,
          };
        }

        // Fallback grading if AI missed a question
        return await this.fallbackGrade(q, ua);
      }));
    } catch (error) {
      console.error("AI Grading failed, using individual fallback:", error.message);
      return await Promise.all(userAnswers.map(async (ua) => {
        const q = questions.find((quest) => quest._id.toString() === ua.questionId);
        return await this.fallbackGrade(q, ua);
      }));
    }
  }

  /**
   * Grade a single answer using AI for accuracy.
   */
  async gradeSingleAnswerAI(question, userAnswer) {
    if (!this.isConfigured()) return null;

    const isPlaceholder = question.correctAnswer === "Sample answer" || !question.correctAnswer;
    const correctAnswerText = isPlaceholder
      ? "[MISSING - USE YOUR EXPERT KNOWLEDGE]"
      : (question.type === "mcq" || question.type === "true_false"
        ? (question.options?.[question.correctAnswer] ?? question.correctAnswer)
        : question.correctAnswer);

    const studentAnswerText = question.type === "mcq" || question.type === "true_false"
      ? (question.options?.[userAnswer.selectedOption] ?? userAnswer.selectedOption)
      : (userAnswer.answerText || userAnswer.selectedOption || "");

    const prompt = `Grade this student's exam answer.
Question: ${question.question}
Type: ${question.type}
Correct Answer (provided): ${correctAnswerText}
Student Answer: ${studentAnswerText}

RULES:
1. If the provided correct answer is a placeholder, use your expert knowledge to determine the actual correct answer.
2. For MCQ and true_false: The answer must match the correct answer exactly.
3. For open and fill_blank: Grade based on conceptual correctness. Allow minor spelling/case differences.
4. Respond ONLY with a JSON object: {"earnedPoints": number, "isCorrect": boolean, "feedback": "string (max 15 words)"}`;

    try {
      const completion = await this._createCompletion({
        model: await this.resolveModel(),
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1,
        max_tokens: 200,
      });

      const raw = completion.choices[0]?.message?.content ?? "";
      const cleaned = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();
      const match = cleaned.match(/\{[\s\S]*\}/);
      const graded = JSON.parse(match ? match[0] : cleaned);

      return {
        ...userAnswer,
        earnedPoints: Math.min(graded.earnedPoints ?? 0, question.points || 1),
        isCorrect: !!graded.isCorrect,
        feedback: graded.feedback || (graded.isCorrect ? "Correct." : "Incorrect."),
      };
    } catch (e) {
      console.error("Single answer AI grading failed:", e.message);
      return null;
    }
  }

  /**
   * Deterministic fallback grading for simple question types.
   * If AI is available, it tries to use it for accuracy.
   */
  async fallbackGrade(question, userAnswer) {
    if (!question) return { ...userAnswer, earnedPoints: 0, isCorrect: false };

    // Try AI grading first if configured for better accuracy
    if (this.isConfigured()) {
      const aiResult = await this.gradeSingleAnswerAI(question, userAnswer);
      if (aiResult) return aiResult;
    }

    const isPlaceholder = question.correctAnswer === "Sample answer" || !question.correctAnswer;
    
    if (isPlaceholder) {
      return {
        ...userAnswer,
        earnedPoints: 0,
        isCorrect: false,
        feedback: "Correct answer missing and AI unavailable for verification.",
      };
    }

    let isCorrect = false;
    if (question.type === "mcq" || question.type === "true_false") {
      isCorrect = question.correctAnswer === userAnswer.selectedOption;
    } else if (question.type === "fill_blank") {
      const studentAnswer = String(userAnswer.answerText || userAnswer.selectedOption || "").toLowerCase().trim();
      const correctAnswer = String(question.correctAnswer || "").toLowerCase().trim();
      isCorrect = studentAnswer === correctAnswer;
    } else if (question.type === "open") {
      const similarity = this.calculateBasicSimilarity(
        String(question.correctAnswer || ""),
        String(userAnswer.answerText || userAnswer.selectedOption || "")
      );
      return {
        ...userAnswer,
        earnedPoints: Math.round(similarity * (question.points || 1)),
        isCorrect: similarity > 0.7,
        feedback: similarity > 0.7 ? "Good answer." : "Partially correct or needs review.",
      };
    }

    return {
      ...userAnswer,
      earnedPoints: isCorrect ? (question.points || 1) : 0,
      isCorrect,
      feedback: isCorrect ? "Correct." : "Incorrect.",
    };
  }

  calculateBasicSimilarity(str1, str2) {
    if (!str1 || !str2) return 0;
    str1 = str1.toLowerCase().trim();
    str2 = str2.toLowerCase().trim();
    if (str1 === str2) return 1.0;
    
    const words1 = new Set(str1.split(/\s+/));
    const words2 = new Set(str2.split(/\s+/));
    const intersection = new Set([...words1].filter(x => words2.has(x)));
    const union = new Set([...words1, ...words2]);
    return union.size > 0 ? intersection.size / union.size : 0;
  }

  /**
   * Parse grading response from Groq AI.
   * Handles markdown code fences and extracts the JSON array.
   */
  parseGradingResponse(raw) {
    // 1. Try direct parse
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) { /* fall through */ }

    // 2. Strip markdown code fences and retry
    const stripped = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();
    try {
      const parsed = JSON.parse(stripped);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) { /* fall through */ }

    // 3. Extract the first [...] array block
    const match = stripped.match(/\[[\s\S]*\]/);
    if (match) {
      try {
        const parsed = JSON.parse(match[0]);
        return Array.isArray(parsed) ? parsed : [];
      } catch (_) { /* fall through */ }
    }

    console.error("Could not parse grading response from Groq AI");
    return [];
  }

  // ─── Internal Helpers ────────────────────────────────────────────────────────

  async extractTextFromBuffer(buffer, mimeType) {
    if (mimeType && mimeType.includes("text")) {
      return buffer.toString("utf8");
    }
    try {
      const DocumentProcessingService = require("./document_processing_service");
      const text = await DocumentProcessingService.extractTextFromDocument(buffer, mimeType);
      if (!text || text.trim().length < 5) {
        console.warn(`Extracted text too short for ${mimeType}`);
        return "";
      }
      return text;
    } catch (error) {
      console.warn("extractTextFromBuffer failed:", error.message);
      return "";
    }
  }

  /**
   * Split text into chunks that respect paragraph boundaries.
   * Avoids cutting a question in half.
   */
  splitTextIntoChunks(text, chunkSize) {
    if (!text) return [];
    if (text.length <= chunkSize) return [text];

    // Prefer splitting on double-newlines (paragraph breaks)
    const paragraphs = text.split(/\n{2,}/);
    const chunks = [];
    let current = "";

    for (const para of paragraphs) {
      const addition = current ? "\n\n" + para : para;

      if (current.length + addition.length <= chunkSize) {
        current += addition;
      } else {
        if (current) chunks.push(current.trim());

        // Paragraph itself exceeds chunk size — split by sentences
        if (para.length > chunkSize) {
          const sentences = para.split(/(?<=[.!?])\s+/);
          current = "";
          for (const sentence of sentences) {
            if (current.length + sentence.length + 1 <= chunkSize) {
              current += (current ? " " : "") + sentence;
            } else {
              if (current) chunks.push(current.trim());
              // Single sentence too long — hard split
              if (sentence.length > chunkSize) {
                for (let i = 0; i < sentence.length; i += chunkSize) {
                  chunks.push(sentence.substring(i, i + chunkSize));
                }
                current = "";
              } else {
                current = sentence;
              }
            }
          }
        } else {
          current = para;
        }
      }
    }

    if (current.trim()) chunks.push(current.trim());
    return chunks;
  }

  generateFallbackExamTitle() {
    const topics = ["Mathematics", "Science", "History", "Literature", "Programming", "Business"];
    const types = ["Quiz", "Test", "Assessment", "Review", "Practice"];
    return `${topics[Math.floor(Math.random() * topics.length)]} ${types[Math.floor(Math.random() * types.length)]}`;
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

module.exports = new GrokService();