/**
 * ECH media worker — runs outside the API process.
 *
 *   node src/workers/media.worker.js
 *
 * Processes GenerationJob documents:
 *   figure_extraction  (Python + PyMuPDF)
 *   lesson_video       (LLM storyboard → TTS → Puppeteer frames → FFmpeg)
 *
 * Deploy as a Render "Background Worker" from backend/Dockerfile.worker (it
 * contains Python/PyMuPDF, FFmpeg, Chromium and espeak-ng). CPU-heavy work
 * never touches the API service.
 *
 * Env: MEDIA_WORKER_CONCURRENCY (default 1), VIDEO_JOB_TIMEOUT_MS (default 30 min),
 *      FIGURE_JOB_TIMEOUT_MS (default 20 min), WORKER_JOB_TYPES (comma list).
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/database');
const { JobWorker } = require('../services/jobs/worker.service');

async function main() {
  await connectDB();
  const worker = new JobWorker({
    concurrency: parseInt(process.env.MEDIA_WORKER_CONCURRENCY || '1', 10),
    pollMs: parseInt(process.env.MEDIA_WORKER_POLL_MS || '5000', 10),
  });
  const types = (process.env.WORKER_JOB_TYPES || 'figure_extraction,lesson_video').split(',').map(s => s.trim());
  if (types.includes('figure_extraction')) {
    worker.register('figure_extraction', require('../services/course-builder/figures.service').runExtraction, {
      timeoutMs: parseInt(process.env.FIGURE_JOB_TIMEOUT_MS || String(20 * 60 * 1000), 10),
    });
  }
  if (types.includes('lesson_video')) {
    worker.register('lesson_video', require('../services/video/pipeline.service').runLessonVideo, {
      timeoutMs: parseInt(process.env.VIDEO_JOB_TIMEOUT_MS || String(30 * 60 * 1000), 10),
    });
  }
  await worker.start();

  let stopping = false;
  const shutdown = async (signal) => {
    if (stopping) return;
    stopping = true;
    console.log(`[media-worker] ${signal} received — finishing current work`);
    await worker.stop(parseInt(process.env.WORKER_SHUTDOWN_GRACE_MS || '25000', 10));
    await mongoose.connection.close().catch(() => {});
    process.exit(0);
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  console.error('[media-worker] fatal:', err);
  process.exit(1);
});
