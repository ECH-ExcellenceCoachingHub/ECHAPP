const fsp = require('fs/promises');
const path = require('path');
const { pathToFileURL } = require('url');
const { framesFor, renderFrame, layoutOf, W, H, ANIM_SECONDS } = require('./scene-html');

/**
 * Renders every storyboard scene with headless Chromium (Puppeteer).
 *
 * Each frame state is loaded once; its CSS entrance animations are paused and
 * stepped to fixed times (ANIM_FPS per second for ANIM_SECONDS), so motion is
 * deterministic and identical on every machine. The last screenshot of a
 * state is the "hold" frame the assembler shows for the rest of its time.
 *
 * Scenes with stock media (split/full layouts) are captured with a
 * transparent background so FFmpeg can put the photo or clip underneath.
 *
 * @returns {Promise<Array<{scene:number, layout:string, states:Array<{anim:string[], hold:string}>, frames:string[]}>>}
 */
function animFps() {
  const n = parseInt(process.env.VIDEO_ANIM_FPS || '15', 10);
  return Math.min(25, Math.max(0, Number.isFinite(n) ? n : 15));
}

async function renderScenes(storyboard, ctx, workDir, { signal } = {}) {
  const puppeteer = require('puppeteer');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--allow-file-access-from-files', '--font-render-hinting=none'],
  });
  const onAbort = () => browser.close().catch(() => {});
  signal?.addEventListener('abort', onAbort, { once: true });
  const fps = animFps();
  const steps = Math.round(ANIM_SECONDS * fps);
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
    const result = [];
    const scenes = [...storyboard.scenes, ...(ctx.extraScenes || [])];
    for (const scene of scenes) {
      if (signal?.aborted) throw signal.reason || new Error('aborted');
      const layout = layoutOf(scene, ctx.media?.get(scene.n));
      const transparent = layout !== 'none';
      const states = [];
      const frameStates = framesFor(scene);
      for (let i = 0; i < frameStates.length; i++) {
        const html = renderFrame(scene, frameStates[i], ctx);
        const stem = path.join(workDir, `s${String(scene.n).padStart(2, '0')}_f${String(i).padStart(2, '0')}`);
        await fsp.writeFile(`${stem}.html`, html, 'utf8');
        await page.goto(pathToFileURL(`${stem}.html`).href, { waitUntil: 'load', timeout: 30000 });
        await page.evaluate(() => document.fonts && document.fonts.ready);
        // Shrink anything that does not fit its area (long worked examples,
        // big tables) so nothing overlaps the heading or footer.
        await page.evaluate(() => {
          const box = document.querySelector('.content');
          const inner = box && box.firstElementChild;
          if (!inner) return;
          const s = Math.min(1, (box.clientHeight - 8) / inner.scrollHeight, (box.clientWidth - 8) / inner.scrollWidth);
          if (s < 1) { inner.style.transform = 'scale(' + s + ')'; inner.style.transformOrigin = 'center center'; }
        });
        const animated = steps > 0 && await page.evaluate(() => {
          const list = document.getAnimations();
          list.forEach(a => a.pause());
          return list.length > 0;
        });
        const anim = [];
        if (animated) {
          for (let k = 0; k < steps; k++) {
            await page.evaluate((ms) => document.getAnimations().forEach(a => { a.currentTime = ms; }), (k / fps) * 1000);
            const file = `${stem}_a${String(k).padStart(2, '0')}.png`;
            await page.screenshot({ path: file, type: 'png', omitBackground: transparent });
            anim.push(file);
          }
          await page.evaluate((ms) => document.getAnimations().forEach(a => { a.currentTime = ms; }), ANIM_SECONDS * 1000 + 1000);
        }
        const hold = `${stem}.png`;
        await page.screenshot({ path: hold, type: 'png', omitBackground: transparent });
        states.push({ anim, hold });
      }
      result.push({ scene: scene.n, layout, states, frames: states.map(s => s.hold) });
    }
    return result;
  } finally {
    signal?.removeEventListener('abort', onAbort);
    await browser.close().catch(() => {});
  }
}

module.exports = { renderScenes, animFps };
