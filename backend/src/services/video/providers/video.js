/**
 * Video-generation provider abstraction.
 *
 * Every provider implements the same internal interface so the pipeline is
 * not tied to one vendor:
 *
 *   name
 *   async submit(request)            → { requestId }
 *   async getStatus(requestId)       → { state: 'queued'|'running'|'succeeded'|'failed', progress?, error? }
 *   async getResult(requestId)       → { file, durationSeconds }
 *   async cancel(requestId)          → boolean   (only if the provider supports it)
 *   estimateCost(request)            → USD or null
 *   capabilities                     → { webhooks, polling, cancellation, idempotency }
 *
 * Built in:
 *   programmatic — renders scenes locally (Puppeteer + KaTeX + deterministic
 *                  SVG plots) and assembles them with FFmpeg. Exact formulas,
 *                  numbers and labels; no per-video API cost. This is the
 *                  default and the only provider the pipeline uses today.
 *
 * Third-party text-to-video clip providers are intentionally NOT implemented:
 * none has been verified against its current API with credentials in this
 * project. To add one, implement this interface in a new file, register it
 * below, and only use it for short illustrative clips (never for formulas,
 * labels or numbers), behind VIDEO_CLIP_PROVIDER and the spending limits.
 */

const programmatic = {
  name: 'programmatic',
  capabilities: { webhooks: false, polling: false, cancellation: true, idempotency: true },
  estimateCost: () => 0,
  // The programmatic renderer runs synchronously inside the worker; the
  // pipeline calls the renderer/assembler modules directly. These methods
  // exist so the provider satisfies the same contract as remote providers.
  async submit() { return { requestId: null }; },
  async getStatus() { return { state: 'succeeded' }; },
  async getResult() { throw new Error('programmatic provider returns results synchronously'); },
  async cancel() { return true; },
};

const REGISTRY = { programmatic };

function resolveVideoProvider(name = process.env.VIDEO_RENDER_PROVIDER || 'programmatic') {
  const p = REGISTRY[String(name).toLowerCase()];
  if (!p) throw Object.assign(new Error(`Video provider "${name}" is not available. Implemented providers: ${Object.keys(REGISTRY).join(', ')}`), { retryable: false, code: 'VIDEO_PROVIDER_NOT_CONFIGURED' });
  return p;
}

/** Optional AI clip provider for illustrative scenes (none implemented yet). */
function resolveClipProvider() {
  const name = (process.env.VIDEO_CLIP_PROVIDER || 'none').toLowerCase();
  if (name === 'none') return null;
  throw Object.assign(new Error(`VIDEO_CLIP_PROVIDER "${name}" is not implemented — see providers/video.js`), { retryable: false, code: 'CLIP_PROVIDER_NOT_IMPLEMENTED' });
}

module.exports = { resolveVideoProvider, resolveClipProvider, REGISTRY };
