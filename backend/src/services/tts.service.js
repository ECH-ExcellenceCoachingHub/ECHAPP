const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const crypto = require('crypto');
const { PROVIDERS } = require('./video/providers/tts');

/**
 * Speech for the AI learning assistant. Uses the same ElevenLabs provider as
 * video narration, so the assistant has the same voice, model and delivery
 * settings (ELEVENLABS_VOICE_ID / ELEVENLABS_MODEL_ID / ELEVENLABS_* in .env).
 */

const AUDIO_DIR = path.join(__dirname, '../../uploads/voice');
const MAX_CHARS = 5000;
// After an account-level error (402, blocked), skip ElevenLabs for a while
// instead of retrying on every message; the app falls back to device TTS.
const COOLDOWN_MS = 10 * 60 * 1000;

/** Strip markdown and emoji so the voice reads the words, not the symbols. */
function toSpeakable(text) {
  return String(text || '')
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/[*_~`#>|]+/g, '')
    .replace(/^\s*[-+]\s+/gm, '')
    .replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, MAX_CHARS);
}

class TTSService {
  constructor() {
    this._disabledUntil = 0;
    this._inFlight = new Map();
  }

  available() {
    return PROVIDERS.elevenlabs.available() && Date.now() >= this._disabledUntil;
  }

  /**
   * Generate speech from text and save to file
   * @param {string} text The text to convert to speech
   * @param {string} outputFile Path to save the audio file (.mp3)
   * @returns {Promise<string|null>} Path to the generated audio file, or null on failure
   */
  async generateSpeech(text, outputFile) {
    const speakable = toSpeakable(text);
    if (!speakable || !this.available()) return null;

    try {
      const { file } = await PROVIDERS.elevenlabs.synthesize(speakable, outputFile.replace(/\.mp3$/i, ''));
      return file;
    } catch (error) {
      if (/\((401|402|403)\)|detected_unusual_activity|quota_exceeded/.test(error.message)) {
        console.warn(`TTS: ElevenLabs unavailable (${error.message.slice(0, 120)}) — pausing for 10 min; device TTS will be used.`);
        this._disabledUntil = Date.now() + COOLDOWN_MS;
      } else {
        console.error('TTS Generation error:', error.message);
      }
      return null;
    }
  }

  /**
   * Speech for `text`, cached on disk by content and voice settings so replays
   * do not spend characters again.
   * @returns {Promise<string|null>} File name inside uploads/voice, or null
   */
  async speechFileFor(text) {
    const speakable = toSpeakable(text);
    if (!speakable) return null;
    const key = crypto.createHash('sha256')
      .update(`${PROVIDERS.elevenlabs.signature()}\n${speakable}`)
      .digest('hex').slice(0, 32);
    const fileName = `tts-${key}.mp3`;
    const filePath = path.join(AUDIO_DIR, fileName);

    if (fs.existsSync(filePath)) return fileName;
    if (this._inFlight.has(key)) return this._inFlight.get(key);

    const job = (async () => {
      await fsp.mkdir(AUDIO_DIR, { recursive: true });
      const generated = await this.generateSpeech(speakable, filePath);
      return generated ? fileName : null;
    })().finally(() => this._inFlight.delete(key));
    this._inFlight.set(key, job);
    return job;
  }
}

module.exports = new TTSService();
module.exports.toSpeakable = toSpeakable;
