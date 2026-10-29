const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const { spawn } = require('child_process');
const axios = require('axios');

/**
 * Text-to-speech providers behind one interface:
 *
 *   provider.name
 *   provider.paid                       true when it costs money per character
 *   provider.available()                configured / installed?
 *   provider.costPer1kChars()           USD per 1000 characters, or null if unknown
 *   provider.synthesize(text, outBase, { language, signal })
 *       → { file, requestId, chars }
 *
 * VIDEO_TTS_PROVIDER = auto | elevenlabs | espeak | silent  (default auto)
 *   auto → elevenlabs if ELEVENLABS_API_KEY is set, else espeak if installed.
 *   silent produces no narration (captions only) and is refused in production
 *   unless VIDEO_ALLOW_SILENT=true — it exists for tests and local previews.
 */

const LANG_TO_ESPEAK = { english: 'en', french: 'fr', swahili: 'sw', kiswahili: 'sw', spanish: 'es', german: 'de', portuguese: 'pt' };

function run(cmd, args, { signal, input } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: [input ? 'pipe' : 'ignore', 'pipe', 'pipe'] });
    let err = '';
    child.stderr.on('data', d => { err += d; });
    child.stdout.on('data', () => {});
    const onAbort = () => child.kill('SIGKILL');
    signal?.addEventListener('abort', onAbort, { once: true });
    child.on('error', reject);
    child.on('close', (code) => {
      signal?.removeEventListener('abort', onAbort);
      if (code === 0) resolve();
      else reject(new Error(`${cmd} exited ${code}: ${err.trim().split('\n').slice(-2).join(' ')}`));
    });
    if (input) { child.stdin.write(input); child.stdin.end(); }
  });
}

function which(cmd) {
  const exts = process.platform === 'win32' ? ['.exe', '.cmd', ''] : [''];
  for (const dir of (process.env.PATH || '').split(path.delimiter)) {
    for (const e of exts) {
      if (fs.existsSync(path.join(dir, cmd + e))) return path.join(dir, cmd + e);
    }
  }
  return null;
}

// Default narrator: "Alice" (ElevenLabs default voice, clear and friendly,
// British; described for e-learning) on eleven_multilingual_v2, the model
// ElevenLabs rates most stable for long-form narration. Both chosen after
// test generations (pace ~150 words/min with natural sentence pauses).
const DEFAULT_VOICE = 'Xb7hH8MSUJpSbSDYk0k2';
const DEFAULT_MODEL = 'eleven_multilingual_v2';
// Models that do not support request stitching (ElevenLabs docs).
const NO_STITCHING = new Set(['eleven_v3']);

function num(name, def, min, max) {
  const v = parseFloat(process.env[name] || '');
  return Number.isFinite(v) ? Math.min(max, Math.max(min, v)) : def;
}

/** Teacher-style delivery: steady, expressive and slow enough for beginners in English. */
function elevenVoiceSettings() {
  return {
    stability: num('ELEVENLABS_STABILITY', 0.5, 0, 1),
    similarity_boost: num('ELEVENLABS_SIMILARITY', 0.75, 0, 1),
    style: num('ELEVENLABS_STYLE', 0.15, 0, 1),
    use_speaker_boost: String(process.env.ELEVENLABS_SPEAKER_BOOST || 'true').toLowerCase() !== 'false',
    speed: num('ELEVENLABS_SPEED', 0.85, 0.7, 1.2),
  };
}

/**
 * Request body for one scene. Request stitching (previous request ids, or the
 * neighbouring scenes' text) keeps tone and pacing continuous across scenes.
 */
function elevenRequest(text, { previousText, nextText, previousRequestIds } = {}) {
  const model = process.env.ELEVENLABS_MODEL_ID || DEFAULT_MODEL;
  const body = { text, model_id: model, voice_settings: elevenVoiceSettings() };
  if (!NO_STITCHING.has(model)) {
    const ids = (previousRequestIds || []).filter(Boolean).slice(-3);
    if (ids.length) body.previous_request_ids = ids;
    else if (previousText) body.previous_text = String(previousText).slice(-1000);
    if (nextText) body.next_text = String(nextText).slice(0, 1000);
  }
  if (process.env.ELEVENLABS_PRONUNCIATION_DICTIONARY_ID) {
    body.pronunciation_dictionary_locators = [{ pronunciation_dictionary_id: process.env.ELEVENLABS_PRONUNCIATION_DICTIONARY_ID }];
  }
  return body;
}

const elevenlabs = {
  name: 'elevenlabs',
  paid: true,
  available: () => !!process.env.ELEVENLABS_API_KEY,
  costPer1kChars() {
    const v = parseFloat(process.env.VIDEO_TTS_COST_PER_1K_CHARS || '');
    return Number.isFinite(v) ? v : null;
  },
  /** Changes when the voice, model or delivery settings change (narration is then re-recorded). */
  signature() {
    return `elevenlabs:${process.env.ELEVENLABS_VOICE_ID || DEFAULT_VOICE}:${process.env.ELEVENLABS_MODEL_ID || DEFAULT_MODEL}:${JSON.stringify(elevenVoiceSettings())}`;
  },
  supportsStitching: () => !NO_STITCHING.has(process.env.ELEVENLABS_MODEL_ID || DEFAULT_MODEL),
  async synthesize(text, outBase, { signal, previousText, nextText, previousRequestIds } = {}) {
    const voice = process.env.ELEVENLABS_VOICE_ID || DEFAULT_VOICE;
    const file = `${outBase}.mp3`;
    let res;
    try {
      res = await axios({
        method: 'post',
        url: `https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_128`,
        data: elevenRequest(text, { previousText, nextText, previousRequestIds }),
        headers: { Accept: 'audio/mpeg', 'xi-api-key': process.env.ELEVENLABS_API_KEY, 'Content-Type': 'application/json' },
        responseType: 'arraybuffer',
        timeout: 120000,
        signal,
      });
    } catch (e) {
      const status = e.response?.status;
      let detail = '';
      try { detail = Buffer.from(e.response?.data || '').toString('utf8').slice(0, 300); } catch (_) { /* ignore */ }
      // 401/402/403/422 will not fix themselves on retry.
      const retryable = !status || status === 429 || status >= 500;
      throw Object.assign(new Error(`ElevenLabs TTS failed${status ? ` (${status})` : ''}: ${detail || e.message}`), { retryable, code: 'TTS_FAILED' });
    }
    await fsp.writeFile(file, Buffer.from(res.data));
    const requestId = res.headers?.['request-id'] || res.headers?.['history-item-id'] || null;
    return { file, requestId, chars: text.length };
  },
};

const espeak = {
  name: 'espeak',
  paid: false,
  available: () => !!(which('espeak-ng') || which('espeak')),
  costPer1kChars: () => 0,
  async synthesize(text, outBase, { language, signal } = {}) {
    const bin = which('espeak-ng') || which('espeak');
    if (!bin) throw Object.assign(new Error('espeak-ng is not installed'), { retryable: false, code: 'TTS_MISSING' });
    const file = `${outBase}.wav`;
    const voice = LANG_TO_ESPEAK[String(language || 'english').toLowerCase()] || 'en';
    await run(bin, ['-v', voice, '-s', process.env.ESPEAK_SPEED || '135', '-w', file, '--stdin'], { signal, input: text });
    return { file, requestId: null, chars: text.length };
  },
};

const silent = {
  name: 'silent',
  paid: false,
  available: () => true,
  costPer1kChars: () => 0,
  async synthesize(text, outBase, { signal } = {}) {
    const { WORDS_PER_SECOND } = require('../storyboard.service');
    const seconds = Math.max(2, text.split(/\s+/).filter(Boolean).length / WORDS_PER_SECOND);
    const file = `${outBase}.wav`;
    await run(process.env.FFMPEG_BIN || 'ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono', '-t', seconds.toFixed(2), file], { signal });
    return { file, requestId: null, chars: text.length, silent: true };
  },
};

const PROVIDERS = { elevenlabs, espeak, silent };

/** Resolve the configured provider, or throw a clear configuration error. */
function resolveTts(preferred = process.env.VIDEO_TTS_PROVIDER || 'auto') {
  const name = String(preferred).toLowerCase();
  if (name === 'auto') {
    if (elevenlabs.available()) return elevenlabs;
    if (espeak.available()) return espeak;
    throw Object.assign(new Error('No text-to-speech provider is available. Set ELEVENLABS_API_KEY, or install espeak-ng on the worker (the worker Docker image includes it).'), { retryable: false, code: 'TTS_NOT_CONFIGURED' });
  }
  const p = PROVIDERS[name];
  if (!p) throw Object.assign(new Error(`Unknown VIDEO_TTS_PROVIDER "${preferred}"`), { retryable: false, code: 'TTS_NOT_CONFIGURED' });
  if (!p.available()) throw Object.assign(new Error(`TTS provider "${name}" is not configured or installed`), { retryable: false, code: 'TTS_NOT_CONFIGURED' });
  if (p === silent && process.env.NODE_ENV === 'production' && String(process.env.VIDEO_ALLOW_SILENT).toLowerCase() !== 'true') {
    throw Object.assign(new Error('Silent narration is disabled in production (set VIDEO_ALLOW_SILENT=true to allow caption-only videos)'), { retryable: false, code: 'TTS_NOT_CONFIGURED' });
  }
  return p;
}

module.exports = { resolveTts, PROVIDERS, run, which, elevenRequest, elevenVoiceSettings, DEFAULT_VOICE, DEFAULT_MODEL };
