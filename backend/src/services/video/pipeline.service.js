const crypto = require('crypto');
const fsp = require('fs/promises');
const os = require('os');
const path = require('path');
const { pathToFileURL } = require('url');

const CourseBuildItem = require('../../models/CourseBuildItem');
const CourseBuildJob = require('../../models/CourseBuildJob');
const Lesson = require('../../models/Lesson');
const FigureAsset = require('../../models/FigureAsset');
const storage = require('./storage.service');
const { generateStoryboard } = require('./storyboard.service');
const { subjectByKey } = require('./subjects');
const { assessExperiment } = require('./experiment');
const { resolveTts } = require('./providers/tts');
const { resolveVideoProvider } = require('./providers/video');
const { renderScenes } = require('./render/renderer');
const assembler = require('./render/assembler');
const { buildCaptions } = require('./captions');
const { validateVideo } = require('./validator');
const cost = require('./cost.service');
const videoJobs = require('./video-jobs.service');
const { contentText } = require('../course-builder/integrity.service');

/**
 * Worker handler for `lesson_video` jobs.
 *
 *   generating_script   storyboard from the lesson (LLM) → validated, saved
 *   generating_audio    narration per scene (TTS) → stored, durations measured
 *   generating_visuals  every frame rendered deterministically (Puppeteer)
 *   assembling          FFmpeg segments → final MP4
 *   validating          quality checks, captions, upload, attach to lesson
 *
 * Stage outputs are saved on the job (`artifacts`), so a retry resumes from
 * the failed stage, and an admin can regenerate only the script, the
 * narration or the visuals. Paid narration is never bought twice for the
 * same text.
 */

const STAGES = ['generating_script', 'generating_audio', 'generating_visuals', 'assembling', 'validating'];

function sha(s) {
  return crypto.createHash('sha1').update(String(s)).digest('hex').slice(0, 16);
}

async function loadSource(job) {
  const item = job.buildItemId ? await CourseBuildItem.findById(job.buildItemId).lean() : null;
  const lessonId = job.lessonId || item?.published?.lessonId;
  const lesson = lessonId ? await Lesson.findById(lessonId).lean() : null;
  const content = item?.content || lesson?.aiContent;
  if (!content || !(content.notes || content.summary)) {
    throw Object.assign(new Error('The lesson has no generated content to make a video from.'), { retryable: false, code: 'NO_CONTENT' });
  }
  const currentVersion = item ? (item.contentVersion || 1) : (lesson?.contentVersion || 1);
  if (currentVersion > (job.contentVersion || 1)) {
    throw Object.assign(new Error(`The lesson changed (version ${currentVersion}) after this video was queued (version ${job.contentVersion}). Regenerate the video for the new version.`), { retryable: false, code: 'SUPERSEDED' });
  }
  const buildJob = job.buildJobId ? await CourseBuildJob.findById(job.buildJobId).lean() : null;

  const wanted = (content.figures || []).filter(f => f.usage?.some(u => ['video_reference', 'animate', 'supplement'].includes(u)));
  const assets = wanted.length ? await FigureAsset.find({ _id: { $in: wanted.map(f => f.assetId) }, storageKey: { $ne: null } }).lean() : [];
  const usageById = new Map(wanted.map(f => [String(f.assetId), f.usage]));
  const figures = assets.map(a => ({
    id: String(a._id), page: a.page, caption: a.caption, labels: a.labels || [], labelBoxes: a.labelBoxes || [],
    usage: usageById.get(String(a._id)) || ['video_reference'], storageKey: a.storageKey, widthPx: a.widthPx, heightPx: a.heightPx,
  }));
  return { item, lesson, content, title: item?.title || lesson?.title || 'Lesson', buildJob, figures };
}

async function runLessonVideo(job, ctx) {
  const stage = async (name, message) => {
    await ctx.stage(name, message);
    await videoJobs.applyJobStatus(job._id);
  };
  resolveVideoProvider(); // fails clearly if VIDEO_RENDER_PROVIDER is unknown

  // Partial regeneration requested by an admin.
  if (job.restartFrom === 'script') await ctx.unsetArtifacts(['storyboard', 'audio']);
  if (job.restartFrom === 'audio') await ctx.unsetArtifacts(['audio']);
  if (job.restartFrom) await ctx.update({ restartFrom: null });

  const src = await loadSource(job);
  const cfg = job.config || {};
  const variant = job.variant || 'explainer';
  const subject = subjectByKey(cfg.subject);
  const lessonText = contentText(src.content);
  const assessment = assessExperiment(subject.key, src.content);
  const tts = resolveTts(cfg.tts);
  const work = await fsp.mkdtemp(path.join(os.tmpdir(), 'ech-video-'));

  try {
    // ── 1. Teaching script + storyboard ──────────────────────────────────
    let storyboard = job.artifacts?.storyboard;
    if (!storyboard) {
      await stage('generating_script', 'Writing the teaching script and storyboard');
      const ai = require('../course-builder/ai.service');
      let tokens = 0;
      let requestId = null;
      const result = await generateStoryboard({
        lesson: { title: src.title, content: src.content },
        subject: subject.key,
        level: cfg.level,
        language: cfg.language,
        durationSec: cfg.durationSec || subject.durationSec,
        figures: src.figures,
        variant,
        experimentInfo: assessment,
        lessonText,
      }, {
        completeJson: ai.completeJson,
        onUsage: (u) => { tokens += u.total_tokens || 0; requestId = u.requestId || requestId; },
      });
      storyboard = result.storyboard;
      await ctx.addCost({ stage: 'generating_script', provider: 'llm', units: tokens, unit: 'tokens', usd: cost.llmCost(tokens), requestId, llmTokens: tokens });
      await ctx.addProviderRequest({ stage: 'generating_script', provider: 'llm', requestId });
      const reviewReasons = [...(variant === 'experiment' ? assessment.reasons : []), ...(result.inventedFigureIds.length ? [`Planner referenced unknown figures: ${result.inventedFigureIds.join(', ')}`] : [])];
      const reviewAll = String(process.env.VIDEO_REQUIRE_REVIEW || 'false').toLowerCase() === 'true';
      const reviewRequired = reviewAll || (variant === 'experiment' && assessment.reviewRequired);
      await ctx.saveArtifacts({ storyboard, storyboardWarnings: result.warnings });
      await ctx.update({ review: { required: reviewRequired, status: reviewRequired ? 'pending' : 'not_required', reasons: reviewReasons } });
      job.review = { required: reviewRequired, status: reviewRequired ? 'pending' : 'not_required', reasons: reviewReasons };
    }
    ctx.checkpoint();

    // ── 2. Narration ────────────────────────────────────────────────────
    await stage('generating_audio', `Recording narration (${tts.name})`);
    const chars = storyboard.scenes.reduce((a, s) => a + s.narration.length, 0);
    const existingAudio = new Map((job.artifacts?.audio || []).map(a => [a.scene, a]));
    const charsToBuy = storyboard.scenes.filter(s => existingAudio.get(s.n)?.hash !== sha(`${tts.name}|${s.narration}`)).reduce((a, s) => a + s.narration.length, 0);
    const estimate = cost.ttsCost(tts, charsToBuy);
    await cost.assertWithinBudget({ job: await refreshCost(job), buildJob: src.buildJob, estimateUsd: estimate });
    await ctx.update({ 'cost.estimatedUsd': (job.cost?.actualUsd || 0) + estimate });

    const audio = [];
    let narrated = true;
    for (const scene of storyboard.scenes) {
      ctx.checkpoint();
      const hash = sha(`${tts.name}|${scene.narration}`);
      const prior = existingAudio.get(scene.n);
      const local = path.join(work, `audio_${String(scene.n).padStart(2, '0')}`);
      if (prior && prior.hash === hash && await storage.exists(prior.key)) {
        const file = `${local}${path.extname(prior.key)}`;
        await storage.download(prior.key, file);
        audio.push({ ...prior, file });
        if (prior.silent) narrated = false;
        continue;
      }
      const res = await tts.synthesize(scene.narration, local, { language: cfg.language, signal: ctx.signal });
      const seconds = await assembler.mediaDuration(res.file, { signal: ctx.signal });
      if (!(seconds > 0.3)) throw Object.assign(new Error(`Narration for scene ${scene.n} is empty`), { retryable: true, code: 'AUDIO_EMPTY' });
      const key = `${videoJobs.AI_VIDEO_PREFIX}work/${job._id}/scene_${String(scene.n).padStart(2, '0')}${path.extname(res.file)}`;
      await storage.put(key, res.file, res.file.endsWith('.mp3') ? 'audio/mpeg' : 'audio/wav');
      const usd = cost.ttsCost(tts, res.chars);
      await ctx.addCost({ stage: 'generating_audio', provider: tts.name, units: res.chars, unit: 'chars', usd, requestId: res.requestId, ttsChars: res.chars });
      await ctx.addProviderRequest({ stage: 'generating_audio', provider: tts.name, requestId: res.requestId });
      if (res.silent) narrated = false;
      const entry = { scene: scene.n, key, hash, seconds, provider: tts.name, silent: !!res.silent };
      audio.push({ ...entry, file: res.file });
      await ctx.saveArtifacts({ audio: audio.map(({ file, ...a }) => a) });
    }
    if (audio.length !== storyboard.scenes.length) throw Object.assign(new Error('Missing narration for some scenes'), { retryable: true, code: 'AUDIO_MISSING' });

    // ── 3. Visuals ──────────────────────────────────────────────────────
    await stage('generating_visuals', 'Rendering diagrams, formulas and figures');
    const figures = new Map();
    for (const f of src.figures) {
      if (!storyboard.scenes.some(s => s.figureId === f.id)) continue;
      const file = path.join(work, `figure_${f.id}.png`);
      try {
        await storage.download(f.storageKey, file);
        figures.set(f.id, { ...f, localUrl: pathToFileURL(file).href });
      } catch (e) {
        throw Object.assign(new Error(`Textbook figure ${f.id} could not be downloaded: ${e.message}`), { retryable: true, code: 'ASSET_MISSING' });
      }
    }
    const rendered = await renderScenes(storyboard, {
      lessonTitle: src.title,
      subjectLabel: subject.key === 'general' ? 'Lesson' : subject.key.replace('_', ' '),
      totalScenes: storyboard.scenes.length,
      figures,
    }, work, { signal: ctx.signal });
    const missing = rendered.filter(r => !r.frames.length);
    if (missing.length) throw Object.assign(new Error(`No frames rendered for scene(s) ${missing.map(m => m.scene).join(', ')}`), { retryable: true, code: 'VISUALS_MISSING' });

    // ── 4. Assembly ─────────────────────────────────────────────────────
    await stage('assembling', 'Assembling the video');
    const segments = [];
    for (const [i, scene] of storyboard.scenes.entries()) {
      ctx.checkpoint();
      const seg = await assembler.buildSegment({
        frames: rendered[i].frames,
        audioFile: audio[i].file,
        audioSeconds: audio[i].seconds,
        outFile: path.join(work, `segment_${String(scene.n).padStart(2, '0')}.mp4`),
        transition: scene.transition,
      }, { signal: ctx.signal });
      segments.push(seg);
    }
    const finalFile = await assembler.concatSegments(segments.map(s => s.file), path.join(work, 'lesson.mp4'), { signal: ctx.signal });

    // ── 5. Validation + upload ──────────────────────────────────────────
    await stage('validating', 'Checking the video');
    const captions = buildCaptions(storyboard.scenes, segments.map(s => s.seconds), assembler.LEAD_IN);
    const expectedSeconds = segments.reduce((a, s) => a + s.seconds, 0);
    const result = await validateVideo({
      file: finalFile,
      expectedSeconds,
      sceneCount: storyboard.scenes.length,
      captions,
      narrated,
      storyboardWarnings: job.artifacts?.storyboardWarnings || [],
    }, { signal: ctx.signal });
    await ctx.update({ checks: result.checks.map(({ blocking, ...c }) => c) });
    if (!result.ok) {
      const failed = result.checks.filter(c => !c.passed && c.blocking).map(c => `${c.name}: ${c.detail}`).join('; ');
      throw Object.assign(new Error(`Video failed quality checks — ${failed}`), { retryable: true, code: 'VALIDATION_FAILED' });
    }

    const targetId = job.buildItemId || job.lessonId;
    const base = `${videoJobs.AI_VIDEO_PREFIX}${job.courseId}/${targetId}/${variant}-v${job.contentVersion}-${job._id}`;
    const vttFile = path.join(work, 'lesson.vtt');
    await fsp.writeFile(vttFile, captions.vtt, 'utf8');
    const posterFile = await assembler.poster(finalFile, path.join(work, 'poster.jpg'), { signal: ctx.signal }).catch(() => null);
    const uploaded = await storage.put(`${base}.mp4`, finalFile, 'video/mp4');
    const vtt = await storage.put(`${base}.vtt`, vttFile, 'text/vtt');
    const poster = posterFile ? await storage.put(`${base}.jpg`, posterFile, 'image/jpeg') : null;

    return {
      provider: `${resolveVideoProvider().name}+${tts.name}`,
      s3Key: uploaded.key,
      url: uploaded.url,
      captionsKey: vtt.key,
      captionsUrl: vtt.url,
      posterKey: poster?.key || null,
      durationSeconds: Math.round(result.durationSeconds * 10) / 10,
      sizeBytes: result.sizeBytes,
      sceneCount: storyboard.scenes.length,
      narrated,
      transcript: captions.transcript,
    };
  } finally {
    await fsp.rm(work, { recursive: true, force: true }).catch(() => {});
  }
}

async function refreshCost(job) {
  const GenerationJob = require('../../models/GenerationJob');
  return GenerationJob.findById(job._id).select('cost courseId').lean();
}

runLessonVideo.onComplete = async (jobId) => {
  await videoJobs.applyJobResult(jobId);
  await videoJobs.notify(jobId, 'completed');
};
runLessonVideo.onFinalFailure = async (jobId) => {
  await videoJobs.applyJobStatus(jobId);
  await videoJobs.notify(jobId, 'failed');
};
runLessonVideo.onRetryScheduled = async (jobId) => {
  await videoJobs.applyJobStatus(jobId);
};

module.exports = { runLessonVideo, loadSource, STAGES };
