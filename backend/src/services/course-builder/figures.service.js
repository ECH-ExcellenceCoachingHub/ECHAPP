const crypto = require('crypto');
const fs = require('fs');
const fsp = require('fs/promises');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const FigureAsset = require('../../models/FigureAsset');
const FigureExtraction = require('../../models/FigureExtraction');
const CourseBuildJob = require('../../models/CourseBuildJob');
const queue = require('../jobs/queue.service');
const storage = require('../video/storage.service');

/**
 * Textbook figure extraction (PDF → FigureAsset library).
 *
 * The API only *requests* extraction (hash + queue entry). The CPU-heavy part
 * runs in the worker: it calls python/figure_extractor.py (PyMuPDF), uploads
 * every rendered figure to object storage and records one FigureAsset per
 * figure. Extraction is keyed by the book's sha256 + extractor version, so a
 * book uploaded again (or used by another course) reuses the same assets.
 */

const EXTRACTOR_VERSION = process.env.FIGURE_EXTRACTOR_VERSION || '1.0.0';
const SCRIPT = process.env.FIGURE_EXTRACTOR_SCRIPT || path.join(__dirname, '..', '..', '..', 'python', 'figure_extractor.py');
const PYTHON = process.env.PYTHON_BIN || (process.platform === 'win32' ? 'python' : 'python3');

function isPdf(source) {
  return /pdf/i.test(source?.mimeType || '') || /\.pdf$/i.test(source?.fileName || '');
}

function sha256(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function enabled() {
  return String(process.env.FIGURE_EXTRACTION_ENABLED || 'true').toLowerCase() !== 'false';
}

/**
 * Called by the course builder once the book is uploaded (non-blocking).
 * Links the build job to an existing extraction, or queues a new one.
 */
async function requestExtraction(buildJob, buffer = null) {
  if (!enabled()) {
    await setBuildStatus([buildJob._id], { status: 'skipped', error: 'Figure extraction disabled (FIGURE_EXTRACTION_ENABLED=false)' });
    return null;
  }
  if (!isPdf(buildJob.source)) {
    await setBuildStatus([buildJob._id], { status: 'not_applicable' });
    return null;
  }
  if (!buildJob.source?.s3Key) {
    await setBuildStatus([buildJob._id], { status: 'skipped', error: 'The uploaded PDF is not in storage, so the figure worker cannot read it.' });
    return null;
  }
  if (!buffer) buffer = await storage.get(buildJob.source.s3Key);
  const bookHash = sha256(buffer);

  const extraction = await FigureExtraction.findOneAndUpdate(
    { bookHash, extractorVersion: EXTRACTOR_VERSION },
    {
      $setOnInsert: { status: 'queued', sourceKey: buildJob.source.s3Key, fileName: buildJob.source.fileName },
      $addToSet: { buildJobIds: buildJob._id },
    },
    { upsert: true, new: true },
  );

  if (extraction.status === 'completed') {
    await setBuildStatus([buildJob._id], { status: 'completed', bookHash, extractionId: extraction._id, summary: extraction.summary });
    return extraction;
  }

  // A failed extraction is retried when the book is uploaded again.
  const { job } = await queue.enqueue({
    type: 'figure_extraction',
    key: `figures:${bookHash}:${EXTRACTOR_VERSION}`,
    courseId: buildJob.courseId,
    buildJobId: buildJob._id,
    config: { bookHash, sourceKey: extraction.sourceKey || buildJob.source.s3Key, fileName: buildJob.source.fileName, extractorVersion: EXTRACTOR_VERSION },
    maxAttempts: 3,
  });
  if (extraction.status === 'failed' && ['failed', 'cancelled'].includes(job.state)) {
    await queue.requeue(job._id);
    await FigureExtraction.updateOne({ _id: extraction._id }, { $set: { status: 'queued', error: null } });
  }
  await FigureExtraction.updateOne({ _id: extraction._id }, { $set: { generationJobId: job._id } });
  await setBuildStatus([buildJob._id], { status: extraction.status === 'running' ? 'running' : 'queued', bookHash, extractionId: extraction._id });
  return extraction;
}

async function setBuildStatus(jobIds, { status, bookHash, extractionId, summary, error = null }) {
  const set = { 'figureExtraction.status': status, 'figureExtraction.error': error };
  if (bookHash) set['figureExtraction.bookHash'] = bookHash;
  if (extractionId) set['figureExtraction.extractionId'] = extractionId;
  if (summary !== undefined) set['figureExtraction.summary'] = summary;
  await CourseBuildJob.updateMany({ _id: { $in: jobIds } }, { $set: set });
}

/** Run the Python extractor; resolves with the parsed figures.json. */
function runPython(pdfPath, outDir, { signal, dpi, config } = {}) {
  return new Promise((resolve, reject) => {
    const args = [SCRIPT, '--pdf', pdfPath, '--out', outDir];
    if (dpi) args.push('--dpi', String(dpi));
    if (config) args.push('--config', JSON.stringify(config));
    const child = spawn(PYTHON, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let out = '';
    let err = '';
    child.stdout.on('data', (d) => { out += d; });
    child.stderr.on('data', (d) => { err += d; });
    const onAbort = () => child.kill('SIGKILL');
    if (signal) signal.addEventListener('abort', onAbort, { once: true });
    child.on('error', (e) => {
      reject(Object.assign(new Error(`Could not start Python (${PYTHON}): ${e.message}. Set PYTHON_BIN and install PyMuPDF (pip install -r python/requirements.txt).`), { retryable: false, code: 'PYTHON_MISSING' }));
    });
    child.on('close', async (code) => {
      if (signal) signal.removeEventListener('abort', onAbort);
      const lastLine = out.trim().split(/\r?\n/).pop() || '';
      let summary = null;
      try { summary = JSON.parse(lastLine); } catch (_) { /* ignore */ }
      if (code !== 0 || !summary?.ok) {
        const msg = summary?.error || err.trim().split('\n').slice(-3).join(' ') || `exit code ${code}`;
        const missingModule = /No module named 'fitz'|ModuleNotFoundError/.test(err + msg);
        return reject(Object.assign(new Error(`Figure extractor failed: ${msg}`), { retryable: !missingModule, code: missingModule ? 'PYMUPDF_MISSING' : 'EXTRACTOR_FAILED' }));
      }
      try {
        resolve(JSON.parse(await fsp.readFile(path.join(outDir, 'figures.json'), 'utf8')));
      } catch (e) {
        reject(new Error(`Figure extractor output unreadable: ${e.message}`));
      }
    });
  });
}

function chapterForPage(outline, page) {
  const chapters = outline?.chapters || [];
  const ch = chapters.find(c => page >= c.pageStart && page <= c.pageEnd);
  if (!ch) return { chapterIndex: null, chapterTitle: null, sectionTitle: null };
  const lessons = (ch.lessons || []).filter(l => l.pageStart <= page).sort((a, b) => b.pageStart - a.pageStart);
  return { chapterIndex: ch.index, chapterTitle: ch.title, sectionTitle: lessons[0]?.title || null };
}

/** Worker handler for `figure_extraction` jobs. */
async function runExtraction(job, ctx) {
  const { bookHash, sourceKey, fileName } = job.config || {};
  const extraction = await FigureExtraction.findOneAndUpdate(
    { bookHash, extractorVersion: EXTRACTOR_VERSION },
    { $set: { status: 'running', startedAt: new Date(), error: null } },
    { new: true },
  );
  if (!extraction) throw Object.assign(new Error('Extraction record missing'), { retryable: false });
  await setBuildStatus(extraction.buildJobIds, { status: 'running', bookHash, extractionId: extraction._id });

  const tmp = await fsp.mkdtemp(path.join(os.tmpdir(), 'ech-figs-'));
  try {
    await ctx.stage('downloading', 'Downloading the textbook');
    const pdfPath = path.join(tmp, 'book.pdf');
    await storage.download(sourceKey, pdfPath);

    await ctx.stage('extracting', 'Detecting figures with PyMuPDF');
    let config = null;
    try { config = process.env.FIGURE_EXTRACTOR_CONFIG ? JSON.parse(process.env.FIGURE_EXTRACTOR_CONFIG) : null; } catch (_) { config = null; }
    const result = await runPython(pdfPath, path.join(tmp, 'out'), {
      signal: ctx.signal,
      dpi: parseInt(process.env.FIGURE_EXTRACTOR_DPI || '140', 10),
      config,
    });

    await ctx.stage('uploading', `Uploading ${result.summary.figures} figures`);
    const buildJob = extraction.buildJobIds.length
      ? await CourseBuildJob.findById(extraction.buildJobIds[0]).select('outline').lean()
      : null;
    const printed = new Map(result.pages.map(p => [p.n, p.printedPage]));
    const prefix = `textbook-figures/${bookHash}/${EXTRACTOR_VERSION}`;

    const ocrBudget = { left: parseInt(process.env.FIGURE_OCR_MAX || '40', 10) };
    for (const f of result.figures) {
      ctx.checkpoint();
      let storageKey = null;
      let url = null;
      let ocrText = f.ocrText || null;
      let needsOcr = !!f.needsOcr;
      if (f.file) {
        const filePath = path.join(tmp, 'out', f.file);
        const stored = await storage.put(`${prefix}/${f.file}`, filePath, 'image/png');
        storageKey = stored.key;
        url = stored.url;
        if (needsOcr && ocrBudget.left > 0) {
          ocrBudget.left--;
          const text = await ocrWithGemini(filePath, ctx).catch(() => null);
          if (text) { ocrText = text; needsOcr = false; }
        }
      }
      const where = chapterForPage(buildJob?.outline, f.page);
      await FigureAsset.updateOne(
        { bookHash, extractorVersion: EXTRACTOR_VERSION, figureId: f.id },
        {
          $set: {
            extractionId: extraction._id,
            sourceJobId: extraction.buildJobIds[0] || null,
            sourceFileName: fileName,
            ...where,
            page: f.page,
            printedPage: printed.get(f.page) || null,
            caption: f.caption,
            captionLabel: f.captionLabel,
            kind: f.kind,
            storageKey,
            url,
            widthPx: f.widthPx,
            heightPx: f.heightPx,
            dpi: f.dpi,
            bbox: f.bbox,
            pageSize: f.pageSize,
            labels: f.labels || [],
            labelBoxes: f.labelBoxes || [],
            ocrText,
            surroundingText: f.surroundingText || '',
            extractionMethod: f.method,
            hasRaster: f.hasRaster,
            hasVector: f.hasVector,
            needsOcr,
            quality: f.quality,
            warnings: f.warnings || [],
            hash: f.hash,
            duplicateOf: f.duplicateOf,
            continuationOf: f.continuationOf,
            provenance: { source: 'textbook', pdfSha256: result.pdf.sha256, pymupdfVersion: result.pymupdfVersion },
          },
        },
        { upsert: true },
      );
    }

    // Reading order, tables and equation candidates for later use / review.
    const manifest = await storage.put(`${prefix}/figures.json`, path.join(tmp, 'out', 'figures.json'), 'application/json');
    const summary = { ...result.summary, pageCount: result.pdf.pageCount, extractorVersion: result.extractorVersion };
    await FigureExtraction.updateOne({ _id: extraction._id }, {
      $set: { status: 'completed', manifestKey: manifest.key, summary, finishedAt: new Date(), error: null },
    });
    await setBuildStatus(extraction.buildJobIds, { status: 'completed', bookHash, extractionId: extraction._id, summary });
    return { summary, manifestKey: manifest.key };
  } finally {
    await fsp.rm(tmp, { recursive: true, force: true }).catch(() => {});
  }
}

runExtraction.onFinalFailure = async (jobId, err) => {
  const GenerationJob = require('../../models/GenerationJob');
  const job = await GenerationJob.findById(jobId).lean();
  if (!job?.config?.bookHash) return;
  const extraction = await FigureExtraction.findOneAndUpdate(
    { bookHash: job.config.bookHash, extractorVersion: EXTRACTOR_VERSION },
    { $set: { status: 'failed', error: err.message, finishedAt: new Date() } },
    { new: true },
  );
  if (extraction) await setBuildStatus(extraction.buildJobIds, { status: 'failed', error: err.message });
};

/**
 * OCR for figures whose labels are baked into a raster image. Uses Gemini
 * vision when GEMINI_API_KEY is configured; otherwise the figure keeps
 * needsOcr=true and is flagged for review.
 */
async function ocrWithGemini(filePath, ctx) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  const model = new GoogleGenerativeAI(apiKey).getGenerativeModel({ model: process.env.GEMINI_OCR_MODEL || 'gemini-2.5-flash' });
  const data = (await fsp.readFile(filePath)).toString('base64');
  const result = await model.generateContent([
    { inlineData: { mimeType: 'image/png', data } },
    { text: 'List every text label, number and symbol visible in this textbook figure, one per line, exactly as written. If there is no text, answer NONE.' },
  ]);
  const text = result.response.text().trim();
  await ctx?.addCost?.({ stage: 'ocr', provider: 'gemini', units: 1, unit: 'image', usd: 0 });
  return text && text !== 'NONE' ? text.slice(0, 2000) : null;
}

/** Usable figures (rendered, not duplicates) in a page range of a book. */
async function figuresForRange(bookHash, pageStart, pageEnd, { limit = 12 } = {}) {
  if (!bookHash) return [];
  return FigureAsset.find({
    bookHash,
    extractorVersion: EXTRACTOR_VERSION,
    page: { $gte: pageStart, $lte: pageEnd },
    storageKey: { $ne: null },
    duplicateOf: null,
  }).sort({ page: 1, 'bbox.1': 1 }).limit(limit).lean();
}

/** Wait (bounded) for a build's extraction to finish so lessons can use figures. */
async function waitForExtraction(buildJobId, maxMs = 180000, pollMs = 5000, unclaimedMs = 30000) {
  const start = Date.now();
  const deadline = start + maxMs;
  for (;;) {
    const job = await CourseBuildJob.findById(buildJobId).select('figureExtraction').lean();
    const status = job?.figureExtraction?.status;
    if (!['queued', 'running'].includes(status)) return status;
    if (Date.now() >= deadline) return status;
    // Still unclaimed after a while: no media worker is running — don't hold up the build.
    if (status === 'queued' && Date.now() - start >= Math.min(unclaimedMs, maxMs)) return 'no_worker';
    await new Promise(r => setTimeout(r, pollMs));
  }
}

module.exports = {
  EXTRACTOR_VERSION,
  requestExtraction,
  runExtraction,
  runPython,
  figuresForRange,
  waitForExtraction,
  chapterForPage,
  sha256,
  isPdf,
};
