const fsp = require('fs/promises');
const path = require('path');
const { pathToFileURL } = require('url');
const { framesFor, renderFrame, W, H } = require('./scene-html');

/**
 * Renders every storyboard frame to PNG with headless Chromium (Puppeteer,
 * already a backend dependency). One browser per job; pages are reused.
 *
 * @returns {Promise<Array<{scene:number, frames:string[]}>>}
 */
async function renderScenes(storyboard, ctx, workDir, { signal } = {}) {
  const puppeteer = require('puppeteer');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--allow-file-access-from-files', '--font-render-hinting=none'],
  });
  const onAbort = () => browser.close().catch(() => {});
  signal?.addEventListener('abort', onAbort, { once: true });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: W, height: H, deviceScaleFactor: 1 });
    const result = [];
    for (const scene of storyboard.scenes) {
      if (signal?.aborted) throw signal.reason || new Error('aborted');
      const frames = [];
      const states = framesFor(scene);
      for (let i = 0; i < states.length; i++) {
        const html = renderFrame(scene, states[i], ctx);
        const htmlPath = path.join(workDir, `s${String(scene.n).padStart(2, '0')}_f${String(i).padStart(2, '0')}.html`);
        const pngPath = htmlPath.replace(/\.html$/, '.png');
        await fsp.writeFile(htmlPath, html, 'utf8');
        await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'load', timeout: 30000 });
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
        await page.screenshot({ path: pngPath, type: 'png' });
        frames.push(pngPath);
      }
      result.push({ scene: scene.n, frames });
    }
    return result;
  } finally {
    signal?.removeEventListener('abort', onAbort);
    await browser.close().catch(() => {});
  }
}

module.exports = { renderScenes };
