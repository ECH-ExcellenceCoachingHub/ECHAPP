/**
 * Limits on what a super admin (role 'admin') may do.
 *
 * An admin with no limits (`adminLimits.restricted` false/missing) has full
 * access — every admin that existed before limits were added keeps working.
 * A restricted admin gets one level per area:
 *   full — read and change
 *   view — read only (GET/HEAD)
 *   none — no access
 *
 * Enforcement is in role.middleware `authorize()`: every route that lets the
 * 'admin' role in is checked against the area its URL belongs to. URLs that
 * map to no area (dashboard stats, the admin's own profile) stay open.
 */

const AREAS = ['users', 'courses', 'schools', 'payments', 'communication', 'settings', 'admins'];
const LEVELS = ['full', 'view', 'none'];
const RANK = { none: 0, view: 1, full: 2 };

// Longest prefix wins, so more specific paths come first where they overlap.
// Paths are relative to /api.
const AREA_PREFIXES = [
  // Admins
  ['/admin/admins', 'admins'],
  ['/admin/create-admin', 'admins'],
  // Role changes are user management; making someone an admin is also
  // checked against 'admins' by guardAdminTarget.
  ['/admin/users', 'users'],

  // Users: students, teachers, approvals, enrolments
  ['/admin/students', 'users'],
  ['/admin/teachers', 'users'],
  ['/admin/teacher-applications', 'users'],
  ['/admin/analytics/students', 'users'],
  ['/admin/manual-sync-users', 'users'],
  ['/admin/enrollments', 'users'],
  ['/enrollments', 'users'],

  // Courses & content
  ['/admin/courses', 'courses'],
  ['/admin/course-stats', 'courses'],
  ['/admin/exam-stats', 'courses'],
  ['/admin/analytics/course', 'courses'],
  ['/admin/recordings', 'courses'],
  ['/admin/teacher-guides', 'courses'],
  ['/admin/bbb', 'courses'],
  ['/courses', 'courses'],
  ['/categories', 'courses'],
  ['/sections', 'courses'],
  ['/lessons', 'courses'],
  ['/videos', 'courses'],
  ['/quizzes', 'courses'],
  ['/books', 'courses'],
  ['/documents', 'courses'],
  ['/exam-processing', 'courses'],
  // /upload/image stays open: it is also the admin's own profile picture.
  ['/upload/presigned-url', 'courses'],
  ['/upload/video', 'courses'],
  ['/upload/document', 'courses'],
  ['/course-builder', 'courses'],
  ['/labs', 'courses'],
  ['/live', 'courses'],

  // Schools
  ['/schools-courses', 'schools'],
  ['/schools', 'schools'],
  ['/school', 'schools'],

  // Payments
  ['/admin/payment-stats', 'payments'],
  ['/payments', 'payments'],

  // Communication
  ['/admin/notifications', 'communication'],
  ['/admin/push-report', 'communication'],
  // The rest of /notifications is the admin's own inbox and push token.
  ['/notifications/send-push', 'communication'],
  ['/notifications/send-topic', 'communication'],
  ['/feedback', 'communication'],

  // Settings & maintenance
  ['/admin/backups', 'settings'],
  ['/admin/video-cleanup', 'settings'],
  ['/admin/trigger-expiration-check', 'settings'],
  ['/platform-settings', 'settings'],
].sort((a, b) => b[0].length - a[0].length);

function apiPath(req) {
  const full = (req.originalUrl || req.url || '').split('?')[0];
  return full.startsWith('/api/') ? full.slice(4) : full;
}

function areaForPath(path, method = 'GET') {
  // Creating a notification for other users is a broadcast.
  if (method === 'POST' && (path === '/notifications' || path === '/notifications/')) return 'communication';
  for (const [prefix, area] of AREA_PREFIXES) {
    if (path === prefix || path.startsWith(prefix + '/')) return area;
  }
  return null;
}

function isRestricted(user) {
  return !!(user && user.role === 'admin' && user.adminLimits && user.adminLimits.restricted);
}

function levelFor(user, area) {
  if (!isRestricted(user)) return 'full';
  const level = user.adminLimits.areas && user.adminLimits.areas[area];
  return LEVELS.includes(level) ? level : 'none';
}

function hasArea(user, area, needed = 'full') {
  return RANK[levelFor(user, area)] >= RANK[needed];
}

/** Null when allowed, otherwise the 403 body. */
function checkRequest(user, req) {
  if (!isRestricted(user)) return null;
  const area = areaForPath(apiPath(req), req.method);
  if (!area) return null;
  const readOnly = req.method === 'GET' || req.method === 'HEAD';
  if (hasArea(user, area, readOnly ? 'view' : 'full')) return null;
  return {
    code: 'ADMIN_LIMITED',
    area,
    message: readOnly || levelFor(user, area) === 'none'
      ? `Your admin account has no access to ${area}.`
      : `Your admin account can only view ${area}, not change it.`,
  };
}

/**
 * Validates a limits body from the dashboard.
 * Returns { limits } or { error }.
 */
function normalizeLimits(body) {
  if (!body || typeof body !== 'object') return { error: 'Limits are required' };
  const restricted = !!body.restricted;
  const areas = {};
  for (const area of AREAS) {
    const level = body.areas ? body.areas[area] : undefined;
    if (level === undefined) {
      areas[area] = restricted ? 'none' : 'full';
    } else if (!LEVELS.includes(level)) {
      return { error: `Invalid level "${level}" for ${area}. Use full, view or none.` };
    } else {
      areas[area] = level;
    }
  }
  return { limits: { restricted, areas } };
}

/** What the dashboard needs to show an admin's own access. */
function describe(user) {
  const areas = {};
  for (const area of AREAS) areas[area] = levelFor(user, area);
  return { restricted: isRestricted(user), areas };
}

module.exports = {
  AREAS,
  LEVELS,
  areaForPath,
  isRestricted,
  levelFor,
  hasArea,
  checkRequest,
  normalizeLimits,
  describe,
};
