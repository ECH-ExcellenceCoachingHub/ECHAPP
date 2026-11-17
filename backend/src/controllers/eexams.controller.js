const eexams = require('../services/integrations/eexams.service');
const { sendSuccess, sendError, sendUnauthorized } = require('../utils/response.utils');

/** POST /api/integrations/eexams/sso/start  (logged-in ECH user) → { url } */
exports.startSso = async (req, res) => {
  try {
    if (!process.env.ECH_EEXAMS_SSO_SECRET) return sendError(res, 'eexams integration is not configured', 503);
    const data = await eexams.startSso(req.user, req.body?.redirect);
    return sendSuccess(res, data, 'eexams sign-in link created');
  } catch (e) {
    console.error('[eexams] startSso failed:', e);
    return sendError(res, 'Could not create eexams sign-in link');
  }
};

/** POST /api/integrations/eexams/sso/exchange  (eexams backend only) */
exports.exchange = async (req, res) => {
  if (!eexams.checkServiceAuth(req)) return sendUnauthorized(res, 'Invalid service credentials');
  try {
    const identity = await eexams.exchangeCode(req.body?.code);
    if (!identity) return sendUnauthorized(res, 'Invalid or expired code');
    return sendSuccess(res, identity, 'Code exchanged');
  } catch (e) {
    console.error('[eexams] exchange failed:', e);
    return sendError(res, 'Exchange failed');
  }
};

/** POST /api/integrations/eexams/events  (signed webhook from eexams) */
exports.events = async (req, res) => {
  if (!eexams.verifyWebhook(req)) return sendUnauthorized(res, 'Invalid signature');
  try {
    const events = Array.isArray(req.body?.events) ? req.body.events : [req.body];
    if (events.length > 100) return sendError(res, 'Too many events in one request', 413);
    const results = [];
    for (const ev of events) results.push({ id: ev?.id, ...(await eexams.handleEvent(ev)) });
    return sendSuccess(res, { results }, 'Events processed');
  } catch (e) {
    console.error('[eexams] event handling failed:', e);
    return sendError(res, 'Event handling failed');
  }
};

/** GET /api/integrations/eexams/me  (logged-in ECH user) */
exports.me = async (req, res) => {
  try {
    const data = await eexams.getStudentOverview(req.user, { limit: req.query.limit });
    return sendSuccess(res, data);
  } catch (e) {
    console.error('[eexams] overview failed:', e);
    return sendError(res, 'Could not load eexams results');
  }
};
