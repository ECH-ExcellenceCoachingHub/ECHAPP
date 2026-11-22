/**
 * Loaded first by server.js.
 *
 *  - Error tracking with Sentry, only when SENTRY_DSN is set. No personal data
 *    is sent (sendDefaultPii: false) and auth headers/cookies are stripped.
 *  - LOG_LEVEL=warn (or error) silences console.log/info noise in production
 *    while keeping warnings and errors. Default: everything is logged.
 */
const Sentry = require('@sentry/node');

const enabled = !!process.env.SENTRY_DSN && process.env.NODE_ENV !== 'test';

if (enabled) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.SENTRY_ENVIRONMENT || process.env.NODE_ENV || 'production',
    release: process.env.RENDER_GIT_COMMIT || undefined,
    tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE || 0.05),
    sendDefaultPii: false,
    beforeSend(event) {
      if (event.request) {
        delete event.request.cookies;
        if (event.request.headers) {
          delete event.request.headers.authorization;
          delete event.request.headers.Authorization;
          delete event.request.headers.cookie;
        }
        delete event.request.data; // request bodies may hold PINs or passwords
      }
      return event;
    },
  });
}

const level = String(process.env.LOG_LEVEL || '').toLowerCase();
if (level === 'warn' || level === 'error') {
  console.log = () => {};
  console.info = () => {};
  console.debug = () => {};
  if (level === 'error') console.warn = () => {};
}

module.exports = { Sentry, sentryEnabled: enabled };
