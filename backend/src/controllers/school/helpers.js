const mongoose = require('mongoose');
const School = require('../../models/School');
const { canManageSchool, same } = require('../../services/school/access.service');

class HttpError extends Error {
  constructor(message, status = 400, extra = {}) {
    super(message);
    this.status = status;
    this.extra = extra;
    this.expose = true;
  }
}

const ok = (res, data, message = 'OK', status = 200) => res.status(status).json({ success: true, message, data });

/** Wraps an async handler: readable errors keep their status; others become a 500 without internals. */
const wrap = (fn) => async (req, res) => {
  try {
    await fn(req, res);
  } catch (err) {
    if (err.expose || err.status) {
      return res.status(err.status || 400).json({ success: false, message: err.message, ...(err.extra || {}) });
    }
    if (err.name === 'ValidationError') {
      const first = Object.values(err.errors || {})[0];
      return res.status(400).json({ success: false, message: first?.message || 'Invalid data' });
    }
    if (err.code === 11000) {
      return res.status(409).json({ success: false, message: 'This already exists.' });
    }
    if (err.name === 'CastError') {
      return res.status(400).json({ success: false, message: 'Invalid id' });
    }
    console.error(`[school] ${req.method} ${req.originalUrl}:`, err);
    return res.status(500).json({ success: false, message: 'Something went wrong. Please try again.' });
  }
};

const isId = (v) => mongoose.Types.ObjectId.isValid(String(v || ''));

function requireId(v, what = 'id') {
  if (!isId(v)) throw new HttpError(`Invalid ${what}`, 400);
  return v;
}

/** The school in req.params[param]; 'me' means the caller's own school. Enforces management rights. */
async function schoolFor(req, { param = 'schoolId', manage = true } = {}) {
  let id = req.params[param];
  if (id === 'me' || !id) id = req.user.schoolId;
  if (!id) throw new HttpError('Your account is not linked to a school.', 404);
  requireId(id, 'school id');
  const school = await School.findById(id);
  if (!school) throw new HttpError('School not found', 404);
  if (manage && !canManageSchool(req.user, school._id)) {
    throw new HttpError('Only the school administration can do this.', 403);
  }
  if (!manage && req.user.role !== 'admin' && !same(req.user.schoolId, school._id)) {
    throw new HttpError('You are not a member of this school.', 403);
  }
  return school;
}

function paging(query, { defLimit = 20, maxLimit = 200 } = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(maxLimit, Math.max(1, parseInt(query.limit, 10) || defLimit));
  return { page, limit, skip: (page - 1) * limit };
}

const pageResult = (items, total, { page, limit }, key = 'items') => ({
  [key]: items,
  total,
  currentPage: page,
  totalPages: Math.max(1, Math.ceil(total / limit)),
});

module.exports = { HttpError, ok, wrap, isId, requireId, schoolFor, paging, pageResult };
