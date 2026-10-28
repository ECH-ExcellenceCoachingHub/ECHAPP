const fsp = require('fs/promises');
const { probe } = require('./render/assembler');

/**
 * Quality gate run before a video is uploaded and attached to a lesson.
 * A video that fails any "blocking" check is never published.
 */
async function validateVideo({ file, expectedSeconds, sceneCount, captions, narrated, storyboardWarnings = [] }, opts = {}) {
  const checks = [];
  const add = (name, passed, detail = '', blocking = true) => checks.push({ name, passed: !!passed, detail, blocking });

  let info = null;
  try {
    info = await probe(file, opts);
  } catch (e) {
    add('readable', false, e.message);
    return { ok: false, checks };
  }
  const stat = await fsp.stat(file);
  const v = (info.streams || []).find(s => s.codec_type === 'video');
  const a = (info.streams || []).find(s => s.codec_type === 'audio');
  const duration = parseFloat(info.format?.duration || '0');

  add('readable', true, info.format?.format_name || '');
  add('video_stream', v && v.codec_name === 'h264', v ? `${v.codec_name} ${v.width}x${v.height}` : 'missing');
  add('resolution', v && v.width >= 1280 && v.height >= 720, v ? `${v.width}x${v.height}` : '');
  add('audio_stream', a && a.codec_name === 'aac', a ? a.codec_name : 'missing');
  add('file_size', stat.size > 20 * 1024, `${stat.size} bytes`);
  const tol = Math.max(2, expectedSeconds * 0.06);
  add('duration', Math.abs(duration - expectedSeconds) <= tol, `${duration.toFixed(1)}s (expected ${expectedSeconds.toFixed(1)}s ±${tol.toFixed(1)})`);
  add('captions', captions && captions.cues.length >= sceneCount, `${captions?.cues.length || 0} cues for ${sceneCount} scenes`);
  add('narration', narrated, narrated ? 'spoken narration present' : 'no narration (caption-only)', String(process.env.VIDEO_ALLOW_SILENT).toLowerCase() !== 'true');
  add('storyboard', true, storyboardWarnings.length ? `${storyboardWarnings.length} warning(s): ${storyboardWarnings.slice(0, 3).join(' | ')}` : 'no warnings', false);

  return { ok: checks.every(c => c.passed || !c.blocking), checks, durationSeconds: duration, sizeBytes: stat.size };
}

module.exports = { validateVideo };
