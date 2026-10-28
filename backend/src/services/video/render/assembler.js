const fsp = require('fs/promises');
const path = require('path');
const { spawn } = require('child_process');

/**
 * FFmpeg assembly:
 *   frames + narration → one MP4 segment per scene (H.264/AAC, 25 fps)
 *   segments           → final MP4 (stream copy, +faststart for streaming)
 * CPU use is capped with VIDEO_FFMPEG_THREADS (default 2).
 */

const FFMPEG = () => process.env.FFMPEG_BIN || 'ffmpeg';
const FFPROBE = () => process.env.FFPROBE_BIN || 'ffprobe';
const LEAD_IN = 0.2;   // silence before narration in each scene
const TAIL = 0.45;     // pause after narration

function run(bin, args, { signal } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let out = '';
    let err = '';
    child.stdout.on('data', d => { out += d; });
    child.stderr.on('data', d => { err += d; });
    const onAbort = () => child.kill('SIGKILL');
    signal?.addEventListener('abort', onAbort, { once: true });
    child.on('error', (e) => reject(Object.assign(new Error(`${bin} not available: ${e.message}`), { retryable: false, code: 'FFMPEG_MISSING' })));
    child.on('close', (code) => {
      signal?.removeEventListener('abort', onAbort);
      if (code === 0) resolve(out);
      else reject(new Error(`${path.basename(bin)} failed (${code}): ${err.trim().split('\n').slice(-3).join(' | ')}`));
    });
  });
}

async function probe(file, { signal } = {}) {
  const out = await run(FFPROBE(), ['-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', file], { signal });
  return JSON.parse(out);
}

async function mediaDuration(file, opts) {
  const p = await probe(file, opts);
  return parseFloat(p.format?.duration || '0');
}

function threads() {
  return String(Math.max(1, parseInt(process.env.VIDEO_FFMPEG_THREADS || '2', 10)));
}

/** One scene: frames shown in sequence for the length of its narration. */
async function buildSegment({ frames, audioFile, audioSeconds, outFile, transition = 'fade' }, { signal } = {}) {
  const total = LEAD_IN + audioSeconds + TAIL;
  const per = total / frames.length;
  const listFile = `${outFile}.txt`;
  const esc = (p) => p.replace(/\\/g, '/').replace(/'/g, "'\\''");
  const lines = [];
  frames.forEach((f, i) => {
    lines.push(`file '${esc(f)}'`);
    lines.push(`duration ${(i === frames.length - 1 ? total - per * (frames.length - 1) : per).toFixed(3)}`);
  });
  lines.push(`file '${esc(frames[frames.length - 1])}'`); // concat demuxer needs the last file twice
  await fsp.writeFile(listFile, lines.join('\n'), 'utf8');

  const vf = ['fps=25', 'format=yuv420p'];
  if (transition === 'fade') vf.push('fade=t=in:st=0:d=0.25', `fade=t=out:st=${Math.max(0, total - 0.3).toFixed(2)}:d=0.3`);
  await run(FFMPEG(), [
    '-y', '-v', 'error',
    '-f', 'concat', '-safe', '0', '-i', listFile,
    '-i', audioFile,
    '-filter_complex', `[1:a]adelay=${Math.round(LEAD_IN * 1000)},apad,aresample=44100[a]`,
    '-map', '0:v', '-map', '[a]',
    '-vf', vf.join(','),
    '-t', total.toFixed(3),
    '-c:v', 'libx264', '-preset', process.env.VIDEO_X264_PRESET || 'veryfast', '-crf', '23', '-r', '25',
    '-c:a', 'aac', '-b:a', '128k', '-ac', '1',
    '-threads', threads(),
    outFile,
  ], { signal });
  return { file: outFile, seconds: total };
}

/** Concatenate segments without re-encoding. */
async function concatSegments(segments, outFile, { signal } = {}) {
  const listFile = `${outFile}.txt`;
  await fsp.writeFile(listFile, segments.map(s => `file '${s.replace(/\\/g, '/').replace(/'/g, "'\\''")}'`).join('\n'), 'utf8');
  await run(FFMPEG(), ['-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', listFile, '-c', 'copy', '-movflags', '+faststart', outFile], { signal });
  return outFile;
}

/** Single-frame JPEG poster from the first scene. */
async function poster(videoFile, outFile, { signal } = {}) {
  await run(FFMPEG(), ['-y', '-v', 'error', '-ss', '1', '-i', videoFile, '-frames:v', '1', '-q:v', '3', outFile], { signal });
  return outFile;
}

module.exports = { buildSegment, concatSegments, probe, mediaDuration, poster, run, LEAD_IN, TAIL };
