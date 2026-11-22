/** In-app notification + push for school events. Never throws (notifications are best effort). */
const Notification = require('../../models/Notification');

async function notifyUsers(userIds, { title, message, type = 'school', data = {}, push = true }) {
  const ids = [...new Set((userIds || []).filter(Boolean).map(String))];
  if (!ids.length) return 0;
  try {
    await Notification.insertMany(ids.map((userId) => ({ userId, title, message, type, data })), { ordered: false });
  } catch (err) {
    console.error('[school notify] in-app failed:', err.message);
  }
  if (push) {
    // Lazy require: the notification controller pulls in Firebase messaging.
    const notificationController = require('../../controllers/notification.controller');
    await Promise.allSettled(ids.map((id) => notificationController.sendPushNotification(id, title, message, stringData(data), false)));
  }
  return ids.length;
}

// FCM data payloads must be strings.
function stringData(data) {
  const out = {};
  for (const [k, v] of Object.entries(data || {})) if (v != null) out[k] = String(v);
  return out;
}

module.exports = { notifyUsers };
