/**
 * Super admins managing other super admins: details, password, limits,
 * active status. Mounted under /api/admin/admins, which the 'admins' area of
 * adminLimits guards (view = list only, full = change).
 *
 * An admin never changes their own limits or status here, so the admin doing
 * the change always keeps full access to admins — there is always at least
 * one admin who can undo a mistake.
 */
const User = require('../../models/User');
const firebase = require('../../config/firebase');
const { sendSuccess, sendError } = require('../../utils/response.utils');
const limitsService = require('../../services/adminLimits.service');

const OBJECT_ID = /^[0-9a-fA-F]{24}$/;
const EMAIL = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/;

async function findUser(id, select) {
  let user = null;
  if (OBJECT_ID.test(id)) user = await User.findById(id).select(select || '');
  if (!user) user = await User.findOne({ firebaseUid: id }).select(select || '');
  return user;
}

function isSelf(req, user) {
  return String(req.user._id) === String(user._id);
}

function adminView(user) {
  return {
    id: user._id,
    firebaseUid: user.firebaseUid || null,
    fullName: user.fullName,
    email: user.email,
    phone: user.phone || null,
    role: user.role,
    disabled: user.isActive === false,
    lastActive: user.lastActive,
    createdAt: user.createdAt,
    adminLimits: limitsService.describe(user),
  };
}

/** Loads :id as an admin other than the caller into req.targetAdmin. */
async function loadOtherAdmin(req, res) {
  const user = await findUser(req.params.id);
  if (!user || user.role !== 'admin') {
    sendError(res, 'Admin not found', 404);
    return null;
  }
  if (isSelf(req, user)) {
    sendError(res, 'Use your own profile page to change your account. You cannot change your own limits or status.', 400);
    return null;
  }
  return user;
}

function firebaseMissing(err) {
  return err && err.code === 'auth/user-not-found';
}

// GET /api/admin/my-access — the signed-in admin's own limits (for the dashboard menu).
const getMyAccess = async (req, res) => {
  sendSuccess(res, limitsService.describe(req.user), 'Admin access');
};

// GET /api/admin/admins/:id
const getAdmin = async (req, res) => {
  try {
    const user = await findUser(req.params.id);
    if (!user || user.role !== 'admin') return sendError(res, 'Admin not found', 404);
    sendSuccess(res, adminView(user), 'Admin retrieved');
  } catch (error) {
    sendError(res, 'Failed to load admin', 500, error.message);
  }
};

// PUT /api/admin/admins/:id — { fullName?, email?, phone? }
const updateAdminDetails = async (req, res) => {
  try {
    const user = await loadOtherAdmin(req, res);
    if (!user) return;

    const { fullName, email, phone } = req.body || {};
    const name = typeof fullName === 'string' ? fullName.trim() : undefined;
    const mail = typeof email === 'string' ? email.trim().toLowerCase() : undefined;
    const tel = typeof phone === 'string' ? phone.trim() : undefined;

    if (name !== undefined && !name) return sendError(res, 'Name cannot be empty', 400);
    if (name && name.length > 100) return sendError(res, 'Name cannot exceed 100 characters', 400);
    if (mail !== undefined && !EMAIL.test(mail)) return sendError(res, 'Enter a valid email address', 400);

    const emailChanged = mail !== undefined && mail !== (user.email || '');
    const phoneChanged = tel !== undefined && tel !== (user.phone || '');

    if (emailChanged && await User.exists({ email: mail, _id: { $ne: user._id } })) {
      return sendError(res, 'This email address is already used by another account', 409);
    }
    if (phoneChanged && tel && await User.exists({ phone: tel, _id: { $ne: user._id } })) {
      return sendError(res, 'This phone number is already used by another account', 409);
    }

    // Firebase first: the admin signs in with this email there, so a change
    // that only reaches MongoDB would lock them out.
    if (user.firebaseUid && (emailChanged || name)) {
      const update = {};
      if (emailChanged) update.email = mail;
      if (name) update.displayName = name;
      try {
        await firebase.auth().updateUser(user.firebaseUid, update);
      } catch (err) {
        if (err.code === 'auth/email-already-exists') {
          return sendError(res, 'This email address is already used by another sign-in account', 409);
        }
        if (!firebaseMissing(err)) {
          return sendError(res, 'Could not update the sign-in account', 502, err.message);
        }
      }
    }

    if (name) user.fullName = name;
    if (emailChanged) user.email = mail;
    if (phoneChanged) user.phone = tel || undefined;
    await user.save();

    sendSuccess(res, adminView(user), 'Admin details updated');
  } catch (error) {
    if (error.code === 11000) {
      const field = error.keyValue ? Object.keys(error.keyValue)[0] : 'field';
      return sendError(res, `This ${field} is already in use by another account`, 409);
    }
    sendError(res, 'Failed to update admin', 500, error.message);
  }
};

// PUT /api/admin/admins/:id/password — { newPassword }
const setAdminPassword = async (req, res) => {
  try {
    const user = await loadOtherAdmin(req, res);
    if (!user) return;

    const { newPassword } = req.body || {};
    if (typeof newPassword !== 'string' || newPassword.length < 8) {
      return sendError(res, 'The new password must be at least 8 characters', 400);
    }
    if (newPassword.length > 128) return sendError(res, 'The new password is too long', 400);

    if (user.firebaseUid) {
      try {
        await firebase.auth().updateUser(user.firebaseUid, { password: newPassword });
      } catch (err) {
        if (!firebaseMissing(err)) {
          return sendError(res, 'Could not change the sign-in password', 502, err.message);
        }
      }
    }

    user.password = newPassword; // hashed by the User pre-save hook
    await user.save();

    // Sign the admin out of their other devices.
    if (user.firebaseUid) {
      try { await firebase.auth().revokeRefreshTokens(user.firebaseUid); } catch (_) { /* best effort */ }
    }

    console.log(`[admins] ${req.user._id} changed the password of admin ${user._id}`);
    sendSuccess(res, { id: user._id }, 'Password changed. The admin has been signed out and must use the new password.');
  } catch (error) {
    sendError(res, 'Failed to change password', 500, error.message);
  }
};

// PUT /api/admin/admins/:id/limits — { restricted, areas: { users: 'full'|'view'|'none', ... } }
const setAdminLimits = async (req, res) => {
  try {
    const user = await loadOtherAdmin(req, res);
    if (!user) return;

    const { limits, error } = limitsService.normalizeLimits(req.body);
    if (error) return sendError(res, error, 400);

    user.adminLimits = {
      restricted: limits.restricted,
      areas: limits.areas,
      updatedBy: req.user._id,
      updatedAt: new Date(),
    };
    await user.save();

    console.log(`[admins] ${req.user._id} set limits on admin ${user._id}: ${JSON.stringify(limits)}`);
    sendSuccess(res, adminView(user), limits.restricted ? 'Limits saved' : 'Limits removed — full access');
  } catch (error) {
    sendError(res, 'Failed to save limits', 500, error.message);
  }
};

// PUT /api/admin/admins/:id/status — { active: boolean }
const setAdminStatus = async (req, res) => {
  try {
    const user = await loadOtherAdmin(req, res);
    if (!user) return;

    const { active } = req.body || {};
    if (typeof active !== 'boolean') return sendError(res, '"active" must be true or false', 400);

    if (user.firebaseUid) {
      try {
        await firebase.auth().updateUser(user.firebaseUid, { disabled: !active });
        if (!active) await firebase.auth().revokeRefreshTokens(user.firebaseUid);
      } catch (err) {
        if (!firebaseMissing(err)) console.warn(`[admins] Firebase status update failed for ${user._id}:`, err.message);
      }
    }

    user.isActive = active;
    await user.save();

    sendSuccess(res, adminView(user), active ? 'Admin activated' : 'Admin deactivated');
  } catch (error) {
    sendError(res, 'Failed to change status', 500, error.message);
  }
};

// DELETE /api/admin/admins/:id — reuses the student delete, which also removes the Firebase account.
const deleteAdmin = (deleteUser) => async (req, res) => {
  try {
    const user = await loadOtherAdmin(req, res);
    if (!user) return;
    req.params.id = user.firebaseUid || String(user._id);
    return deleteUser(req, res);
  } catch (error) {
    sendError(res, 'Failed to delete admin', 500, error.message);
  }
};

/**
 * Guard for the general user endpoints (/admin/students/:id..., role changes):
 * touching an admin account, or making someone an admin, needs full access to
 * the 'admins' area. Otherwise an admin limited to 'users' could reset a full
 * admin's password and sign in as them.
 */
const guardAdminTarget = async (req, res, next) => {
  try {
    const makesAdmin = req.body && req.body.role === 'admin';
    const id = req.params.id || req.params.studentId;
    const target = id ? await findUser(id, 'role') : null;
    const touchesAdmin = target && target.role === 'admin';

    if ((makesAdmin || touchesAdmin) && !limitsService.hasArea(req.user, 'admins', 'full')) {
      return res.status(403).json({
        success: false,
        code: 'ADMIN_LIMITED',
        area: 'admins',
        message: 'Your admin account cannot change other admins.',
      });
    }
    return next();
  } catch (error) {
    return sendError(res, 'Failed to check permissions', 500, error.message);
  }
};

module.exports = {
  getMyAccess,
  getAdmin,
  updateAdminDetails,
  setAdminPassword,
  setAdminLimits,
  setAdminStatus,
  deleteAdmin,
  guardAdminTarget,
};
