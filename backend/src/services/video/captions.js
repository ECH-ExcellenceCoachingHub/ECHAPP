const { splitSentences } = require('./storyboard.service');

/**
 * WebVTT captions + plain transcript from the storyboard narration and the
 * real (measured) duration of every scene's audio.
 */

function ts(sec) {
  const ms = Math.max(0, Math.round(sec * 1000));
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const r = ms % 1000;
  const p = (n, w = 2) => String(n).padStart(w, '0');
  return `${p(h)}:${p(m)}:${p(s)}.${p(r, 3)}`;
}

/** Split long sentences so a cue never exceeds ~84 characters (two lines). */
function chunk(sentence, max = 84) {
  if (sentence.length <= max) return [sentence];
  const words = sentence.split(/\s+/);
  const out = [];
  let cur = '';
  for (const w of words) {
    if ((cur + ' ' + w).trim().length > max && cur) { out.push(cur); cur = w; } else cur = `${cur} ${w}`.trim();
  }
  if (cur) out.push(cur);
  return out;
}

/**
 * @param {Array<{narration:string}>} scenes
 * @param {number[]} durations  seconds per scene (segment length in the video)
 * @param {number} leadIn       seconds of silence before narration starts in each segment
 * @param {Array<number[]|null>} [spans]  per scene: seconds of each narration part (scenes told step by step)
 */
function buildCaptions(scenes, durations, leadIn = 0.2, spans = []) {
  const cues = [];
  let offset = 0;
  scenes.forEach((scene, i) => {
    const dur = durations[i] || 0;
    const sp = spans?.[i];
    if (scene.parts?.length && sp?.length === scene.parts.length) {
      // Each part is captioned inside its own time window.
      let t0 = offset + leadIn;
      scene.parts.forEach((part, pi) => {
        const pieces = splitSentences(part).flatMap(s => chunk(s));
        const chars = pieces.reduce((a, p) => a + p.length, 0) || 1;
        const speak = Math.max(0.3, sp[pi] - (pi < scene.parts.length - 1 ? 0.6 : 0));
        let t = t0;
        for (const p of pieces) {
          const len = (p.length / chars) * speak;
          cues.push({ start: t, end: Math.min(offset + dur, t + len), text: p });
          t += len;
        }
        t0 += sp[pi];
      });
      offset += dur;
      return;
    }
    const parts = splitSentences(scene.narration).flatMap(s => chunk(s));
    const speakable = Math.max(0.5, dur - leadIn - 0.2);
    const totalChars = parts.reduce((a, p) => a + p.length, 0) || 1;
    let t = offset + leadIn;
    for (const p of parts) {
      const len = (p.length / totalChars) * speakable;
      cues.push({ start: t, end: Math.min(offset + dur, t + len), text: p });
      t += len;
    }
    offset += dur;
  });
  const vtt = ['WEBVTT', ''].concat(cues.flatMap((c, i) => [String(i + 1), `${ts(c.start)} --> ${ts(c.end)}`, c.text, ''])).join('\n');
  const transcript = scenes.map(s => s.narration).join('\n\n');
  return { vtt, cues, transcript };
}

module.exports = { buildCaptions, ts };
