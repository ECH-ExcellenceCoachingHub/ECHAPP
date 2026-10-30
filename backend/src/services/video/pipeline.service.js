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
const { renderScenes, animFps } = require('./render/renderer');
const { layoutOf, PANEL } = require('./render/scene-html');
const assembler = require('./render/assembler');
const stockMedia = require('./media/stock-media.service');
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
/** Silent "pause and think" time after a check question (seconds). */
const THINK_SECONDS = 3.5;
const CREDITS_SECONDS = 4;

/**
 * Licensed photos/clips for the storyboard: reused from the job's saved
 * artifacts when possible (no new searches on a retry), otherwise searched.
 */
async function loadOrFindMedia(job, storyboard, work, ctx, { topic = [] } = {}) {
  const saved = job.artifacts?.media;
  if (Array.isArray(saved)) {
    const media = new Map();
    try {
      for (const a of saved) {
        if (!storyboard.scenes.some(s => s.n === a.scene)) continue;
        const file = path.join(work, `stock_s${a.scene}${path.extname(a.key) || '.bin'}`);
        await storage.download(a.key, file);
        media.set(a.scene, { ...a, file });
      }
      return { media, warnings: job.artifacts?.mediaWarnings || [] };
    } catch (_) { /* a cached file disappeared — search again */ }
  }
  const { assets, warnings } = await stockMedia.prepareStoryboardMedia(storyboard, work, { signal: ctx.signal, log: ctx.log || (() => {}), topic });
  await ctx.saveArtifacts({
    media: [...assets.entries()].map(([scene, { file, ...a }]) => ({ scene, ...a })),
    mediaWarnings: warnings,
  });
  return { media: assets, warnings };
}

/** Background layer of a scene for the assembler (null = opaque slide). */
function backgroundFor(scene, asset, layout) {
  if (!asset || layout === 'none') return null;
  return {
    kind: asset.kind,
    file: asset.file,
    durationSec: asset.durationSec,
    rect: layout === 'split' ? PANEL : null,
    motion: scene.n,
  };
}

/** Where the app should pause and ask each check question. */
function interactionsFor(scenes, segments, audio) {
  const out = [];
  let t = 0;
  scenes.forEach((s, i) => {
    if (s.type === 'check') {
      const askedAt = t + assembler.LEAD_IN + audio[i].seconds + 0.3;
      out.push({
        id: `check-${s.n}`,
        at: Math.round(askedAt * 10) / 10,
        resumeAt: Math.round((t + segments[i].seconds) * 10) / 10, // start of the answer reveal
        question: s.question,
        choices: s.choices,
        answerIndex: s.answerIndex,
        explanation: s.explanation || '',
      });
    }
    t += segments[i].seconds;
  });
  return out;
}

/** Part spans scaled to the measured length of the joined narration (absorbs rounding). */
function scaledSpans(a) {
  if (!a?.spans?.length) return null;
  const sum = a.spans.reduce((x, y) => x + y, 0);
  return sum > 0 ? a.spans.map(s => (s * a.seconds) / sum) : null;
}

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
  if (job.restartFrom === 'script') await ctx.unsetArtifacts(['storyboard', 'audio', 'media', 'mediaWarnings']);
  if (job.restartFrom === 'audio') await ctx.unsetArtifacts(['audio']);
  if (job.restartFrom === 'visuals') await ctx.unsetArtifacts(['media', 'mediaWarnings']);  if (job.restartFrom) await ctx.update({ restartFrom: null });

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
    const existingAudio = new Map((job.artifacts?.audio || []).map(a => [a.scene, a]));
    // Voice/model/settings are part of the hash: changing the narrator re-records.
    const voiceSig = typeof tts.signature === 'function' ? tts.signature() : tts.name;
    // Scenes narrated step by step are recorded in parts (with pauses), so the hash covers the parts.
    const audioHash = (s) => sha(`${voiceSig}|${s.parts?.length > 1 ? `parts:${assembler.stepPause()}:${s.parts.join('\u241e')}` : s.narration}`);
    const charsToBuy = storyboard.scenes.filter(s => existingAudio.get(s.n)?.hash !== audioHash(s)).reduce((a, s) => a + s.narration.length, 0);
    const estimate = cost.ttsCost(tts, charsToBuy);
    // Also reserves the estimate on the job (videos made in parallel share the course budget).
    await cost.assertWithinBudget({ job: await refreshCost(job), buildJob: src.buildJob, estimateUsd: estimate });

    const audio = [];
    let narrated = true;
    const STITCH_MAX_AGE_MS = 2 * 3600 * 1000 - 5 * 60 * 1000; // ElevenLabs: request ids ≤ 2 h old
    for (const [si, scene] of storyboard.scenes.entries()) {
      ctx.checkpoint();
      const hash = audioHash(scene);
      const prior = existingAudio.get(scene.n);
      const local = path.join(work, `audio_${String(scene.n).padStart(2, '0')}`);
      if (prior && prior.hash === hash && await storage.exists(prior.key)) {
        const file = `${local}${path.extname(prior.key)}`;
        await storage.download(prior.key, file);
        audio.push({ ...prior, file });
        if (prior.silent) narrated = false;
        continue;
      }
      // Request stitching: the narrator "hears" the previous scenes and knows what comes next.
      const recentIds = audio.filter(a => a.requestId && a.at && Date.now() - a.at < STITCH_MAX_AGE_MS && a.provider === tts.name).map(a => a.requestId).slice(-3);
      let res;
      let spans = null;
      const parts = scene.parts?.length > 1 ? scene.parts : null;
      if (parts) {
        // One recording per step, joined with a pause: each line then stays on
        // screen exactly while the teacher explains it.
        const files = [];
        const partSeconds = [];
        const ids = [];
        let chars = 0;
        let silentPart = false;
        for (const [pi, text] of parts.entries()) {
          ctx.checkpoint();
          const r = await tts.synthesize(text, `${local}_p${pi}`, {
            language: cfg.language,
            signal: ctx.signal,
            previousRequestIds: [...recentIds, ...ids].slice(-3),
            previousText: pi ? parts[pi - 1] : storyboard.scenes[si - 1]?.narration,
            nextText: parts[pi + 1] || storyboard.scenes[si + 1]?.narration,
          });
          files.push(r.file);
          partSeconds.push(await assembler.mediaDuration(r.file, { signal: ctx.signal }));
          if (r.requestId) ids.push(r.requestId);
          chars += r.chars;
          silentPart = silentPart || !!r.silent;
        }
        const pause = assembler.stepPause();
        const file = await assembler.joinAudio(files, pause, `${local}.wav`, { signal: ctx.signal });
        spans = partSeconds.map((p, i) => p + (i < parts.length - 1 ? pause : 0));
        res = { file, requestId: ids[ids.length - 1] || null, chars, silent: silentPart };
      } else {
        res = await tts.synthesize(scene.narration, local, {
          language: cfg.language,
          signal: ctx.signal,
          previousRequestIds: recentIds,
          previousText: storyboard.scenes[si - 1]?.narration,
          nextText: storyboard.scenes[si + 1]?.narration,
        });
      }
      const seconds = await assembler.mediaDuration(res.file, { signal: ctx.signal });
      if (!(seconds > 0.3)) throw Object.assign(new Error(`Narration for scene ${scene.n} is empty`), { retryable: true, code: 'AUDIO_EMPTY' });
      const key = `${videoJobs.AI_VIDEO_PREFIX}work/${job._id}/scene_${String(scene.n).padStart(2, '0')}${path.extname(res.file)}`;
      await storage.put(key, res.file, res.file.endsWith('.mp3') ? 'audio/mpeg' : 'audio/wav');
      const usd = cost.ttsCost(tts, res.chars);
      await ctx.addCost({ stage: 'generating_audio', provider: tts.name, units: res.chars, unit: 'chars', usd, requestId: res.requestId, ttsChars: res.chars });
      await ctx.addProviderRequest({ stage: 'generating_audio', provider: tts.name, requestId: res.requestId });
      if (res.silent) narrated = false;
      const entry = { scene: scene.n, key, hash, seconds, spans, provider: tts.name, silent: !!res.silent, requestId: res.requestId || null, at: Date.now() };
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
    // Licensed real-world photos and clips for scenes that asked for them.
    let media = new Map();
    if (storyboard.scenes.some(s => s.media?.query)) {
      await ctx.stage('generating_visuals', 'Finding photos and video clips');
      // Lesson vocabulary: a picture for "hand holding quadrat frame" must show a quadrat.
      const topic = stockMedia.topicTerms(src.title, storyboard.title || '', (src.content.keyTerms || []).map(t => t?.term || ''));
      ({ media } = await loadOrFindMedia(job, storyboard, work, ctx, { topic }));
      ctx.checkpoint();
    }
    const credits = [...new Map([...media.values()].map(a => [`${a.provider}:${a.id}`, a])).values()]
      .map(a => stockMedia.creditOf(a));
    const extraScenes = credits.length
      ? [{ type: 'credits', n: storyboard.scenes.length + 1, heading: 'Photo and video credits', items: credits, narration: '', sourcePages: [], onScreenLabels: [], transition: 'fade' }]
      : [];
    await ctx.stage('generating_visuals', 'Rendering animated scenes');
    const rendered = await renderScenes(storyboard, {
      lessonTitle: src.title,
      subjectLabel: subject.key === 'general' ? 'Lesson' : subject.key.replace('_', ' '),
      totalScenes: storyboard.scenes.length,
      figures,
      media,
      extraScenes,
    }, work, { signal: ctx.signal });
    const missing = rendered.filter(r => !r.frames.length);
    if (missing.length) throw Object.assign(new Error(`No frames rendered for scene(s) ${missing.map(m => m.scene).join(', ')}`), { retryable: true, code: 'VISUALS_MISSING' });

    // ── 4. Assembly ─────────────────────────────────────────────────────
    await stage('assembling', 'Assembling the video');
    const segments = [];
    for (const [i, scene] of storyboard.scenes.entries()) {
      ctx.checkpoint();
      const asset = media.get(scene.n);
      const seg = await assembler.buildSegment({
        states: rendered[i].states,
        audioFile: audio[i].file,
        audioSeconds: audio[i].seconds,
        outFile: path.join(work, `segment_${String(scene.n).padStart(2, '0')}.mp4`),
        transition: scene.type === 'check' ? 'cut' : scene.transition,
        background: backgroundFor(scene, asset, layoutOf(scene, asset)),
        tail: scene.type === 'check' ? THINK_SECONDS : assembler.TAIL,
        holdLastForTail: scene.type === 'check', // all choices stay on screen during the thinking pause
        animFps: animFps(),
        stateSeconds: scaledSpans(audio[i]),
      }, { signal: ctx.signal });
      segments.push(seg);
    }
    const sceneSegments = segments.slice();
    if (extraScenes.length) {
      const r = rendered[rendered.length - 1];
      segments.push(await assembler.buildSegment({
        states: r.states,
        audioFile: null,
        audioSeconds: CREDITS_SECONDS,
        outFile: path.join(work, 'segment_credits.mp4'),
        transition: 'fade',
        animFps: animFps(),
      }, { signal: ctx.signal }));
    }
    const finalFile = await assembler.concatSegments(segments.map(s => s.file), path.join(work, 'lesson.mp4'), { signal: ctx.signal });
    const interactions = interactionsFor(storyboard.scenes, sceneSegments, audio);

    // ── 5. Validation + upload ──────────────────────────────────────────
    await stage('validating', 'Checking the video');
    const captions = buildCaptions(storyboard.scenes, sceneSegments.map(s => s.seconds), assembler.LEAD_IN, audio.map(scaledSpans));
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
      interactions,
      credits,
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

module.exports = { runLessonVideo, loadSource, loadOrFindMedia, backgroundFor, interactionsFor, STAGES, THINK_SECONDS };
