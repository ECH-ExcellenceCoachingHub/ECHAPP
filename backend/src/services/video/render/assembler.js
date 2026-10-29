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
const LEAD_IN = 0.5;   // silence before narration in each scene
const TAIL = 1.0;      // pause after narration (time to look at the result)

/** Pause between the explanations of two steps (seconds, VIDEO_STEP_PAUSE_SEC). */
function stepPause() {
  const v = parseFloat(process.env.VIDEO_STEP_PAUSE_SEC || '');
  return Number.isFinite(v) ? Math.min(3, Math.max(0, v)) : 1.0;
}

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

const OUT_W = 1280;
const OUT_H = 720;
const even = (n) => Math.max(2, Math.round(n / 2) * 2);

/**
 * Concat-demuxer list for one scene. Each state = its animation frames (each
 * 1/animFps s; squeezed when a state is very short) followed by its hold
 * frame for the rest of the state's share of the scene.
 */
function frameList(states, total, animFps, { lastExtra = 0, durations = null } = {}) {
  const esc = (p) => p.replace(/\\/g, '/').replace(/'/g, "'\\''");
  // `lastExtra` seconds belong to the final state only (e.g. the "pause and
  // think" time after a question, when every choice must be on screen).
  const extra = Math.min(Math.max(0, lastExtra), total * 0.8);
  const per = (total - extra) / states.length;
  const lines = [];
  let used = 0;
  let last = null;
  states.forEach((st, si) => {
    // With `durations` each state lasts exactly as long as its own explanation.
    const timed = durations && durations.length === states.length;
    const budget = si === states.length - 1 ? total - used : (timed ? durations[si] : per);
    const anim = st.anim || [];
    const animDur = anim.length ? Math.min(1 / animFps, (budget * 0.6) / anim.length) : 0;
    for (const f of anim) {
      lines.push(`file '${esc(f)}'`, `duration ${animDur.toFixed(4)}`);
      used += animDur;
    }
    const hold = Math.max(0.04, budget - animDur * anim.length);
    lines.push(`file '${esc(st.hold)}'`, `duration ${hold.toFixed(4)}`);
    used += hold;
    last = st.hold;
  });
  lines.push(`file '${esc(last)}'`); // concat demuxer needs the last file twice
  return lines.join('\n');
}

/** Ken Burns motions for photos, chosen per scene for variety. */
function kenBurns(n, frames) {
  const c = { x: 'iw/2-(iw/zoom/2)', y: 'ih/2-(ih/zoom/2)' };
  const v = [
    { z: `1+0.10*on/${frames}`, ...c },                                            // slow push in
    { z: `1.10-0.10*on/${frames}`, ...c },                                         // pull out
    { z: '1.10', x: `(iw-iw/zoom)*on/${frames}`, y: c.y },                         // pan left → right
    { z: '1.10', x: `(iw-iw/zoom)*(1-on/${frames})`, y: c.y },                     // pan right → left
  ];
  return v[Math.abs(n) % v.length];
}

/**
 * One scene: animated frame states for the length of its narration, optionally
 * over a licensed photo (Ken Burns) or clip.
 *
 * @param {object} p
 * @param {string[]} [p.frames]   legacy: still frames shown in equal parts
 * @param {Array<{anim:string[], hold:string}>} [p.states]
 * @param {string|null} p.audioFile   null → silent segment of audioSeconds
 * @param {{kind:'image'|'video', file:string, durationSec?:number, rect?:{x,y,w,h}, motion?:number}|null} [p.background]
 * @param {number} [p.tail]  pause after the narration (longer for "pause and think" questions)
 * @param {number[]} [p.stateSeconds]  seconds of narration (incl. the pause after it) for each state, so a step
 *                                     stays on screen exactly while the teacher explains it
 */
async function buildSegment({ frames, states, audioFile, audioSeconds, outFile, transition = 'fade', background = null, tail = TAIL, holdLastForTail = false, animFps = 15, stateSeconds = null }, { signal } = {}) {
  const st = states?.length ? states : frames.map(f => ({ anim: [], hold: f }));
  const total = LEAD_IN + audioSeconds + tail;
  const listFile = `${outFile}.txt`;
  const durations = stateSeconds && stateSeconds.length === st.length
    ? stateSeconds.map((s, i) => s + (i === 0 ? LEAD_IN : 0))
    : null;
  await fsp.writeFile(listFile, frameList(st, total, Math.max(1, animFps), { lastExtra: holdLastForTail ? tail : 0, durations }), 'utf8');

  const fades = transition === 'fade' ? [`fade=t=in:st=0:d=0.25`, `fade=t=out:st=${Math.max(0, total - 0.3).toFixed(2)}:d=0.3`] : [];
  const audioIn = audioFile ? ['-i', audioFile] : ['-f', 'lavfi', '-t', total.toFixed(3), '-i', 'anullsrc=r=44100:cl=mono'];
  const audioChain = `[1:a]adelay=${Math.round(LEAD_IN * 1000)},apad,aresample=44100[a]`;
  const encode = [
    '-t', total.toFixed(3),
    '-c:v', 'libx264', '-preset', process.env.VIDEO_X264_PRESET || 'veryfast', '-crf', '23', '-r', '25', '-pix_fmt', 'yuv420p',
    '-c:a', 'aac', '-b:a', '128k', '-ac', '1',
    '-threads', threads(),
    outFile,
  ];

  if (!background) {
    await run(FFMPEG(), [
      '-y', '-v', 'error',
      '-f', 'concat', '-safe', '0', '-i', listFile,
      ...audioIn,
      '-filter_complex', `[0:v]fps=25,format=yuv420p${fades.length ? `,${fades.join(',')}` : ''}[v];${audioChain}`,
      '-map', '[v]', '-map', '[a]',
      ...encode,
    ], { signal });
    return { file: outFile, seconds: total };
  }

  const rect = background.rect || { x: 0, y: 0, w: OUT_W, h: OUT_H };
  const w = even(rect.w);
  const h = even(rect.h);
  let bgIn;
  let bgChain;
  if (background.kind === 'image') {
    const nFrames = Math.ceil(total * 25) + 2;
    const kb = kenBurns(background.motion || 0, nFrames);
    bgIn = ['-i', background.file];
    bgChain = `[2:v]scale=${w * 2}:${h * 2}:force_original_aspect_ratio=increase,crop=${w * 2}:${h * 2},setsar=1,`
      + `zoompan=z='${kb.z}':x='${kb.x}':y='${kb.y}':d=${nFrames}:s=${w}x${h}:fps=25[bgm]`;
  } else {
    const clip = background.durationSec || 0;
    // Slightly short clips are slowed down; much shorter ones loop.
    const stretch = clip > 0 && clip < total && clip >= total * 0.6 ? total / clip : 1;
    bgIn = clip > 0 && clip < total * 0.6 ? ['-stream_loop', '-1', '-i', background.file] : ['-i', background.file];
    bgChain = `[2:v]${stretch > 1 ? `setpts=${stretch.toFixed(4)}*PTS,` : ''}scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},setsar=1,fps=25[bgm]`;
  }
  const place = rect.w >= OUT_W && rect.h >= OUT_H
    ? '[bgm]null[bg]'
    : `color=c=0x0F172A:s=${OUT_W}x${OUT_H}:r=25[base];[base][bgm]overlay=${Math.round(rect.x)}:${Math.round(rect.y)}:shortest=1[bg]`;
  const graph = [
    bgChain,
    place,
    '[0:v]fps=25,format=rgba[ov]',
    `[bg][ov]overlay=0:0:format=auto,format=yuv420p${fades.length ? `,${fades.join(',')}` : ''}[v]`,
    audioChain,
  ].join(';');
  await run(FFMPEG(), [
    '-y', '-v', 'error',
    '-f', 'concat', '-safe', '0', '-i', listFile,
    ...audioIn,
    ...bgIn,
    '-filter_complex', graph,
    '-map', '[v]', '-map', '[a]',
    ...encode,
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

/**
 * Join narration parts (one per step) into one mono WAV with a pause after
 * every part but the last.
 */
async function joinAudio(files, pauseSec, outFile, { signal } = {}) {
  const inputs = files.flatMap(f => ['-i', f]);
  const chains = files.map((_, i) => `[${i}:a]aresample=44100,aformat=sample_fmts=s16:channel_layouts=mono${i < files.length - 1 && pauseSec > 0 ? `,apad=pad_dur=${pauseSec.toFixed(2)}` : ''}[a${i}]`);
  const graph = `${chains.join(';')};${files.map((_, i) => `[a${i}]`).join('')}concat=n=${files.length}:v=0:a=1[out]`;
  await run(FFMPEG(), ['-y', '-v', 'error', ...inputs, '-filter_complex', graph, '-map', '[out]', '-c:a', 'pcm_s16le', outFile], { signal });
  return outFile;
}

module.exports = { buildSegment, concatSegments, joinAudio, probe, mediaDuration, poster, run, frameList, kenBurns, stepPause, LEAD_IN, TAIL };
