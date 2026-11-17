const mongoose = require('mongoose');

/**
 * One-time handoff codes for "Open eexams" single sign-on.
 *
 * ECH issues a random code, stores only its SHA-256 hash here, and sends the
 * browser to eexams with the raw code. The eexams backend then exchanges the
 * code server-to-server (single use, ~60 s lifetime) for the user's identity.
 */
const eexamsSsoCodeSchema = new mongoose.Schema({
  codeHash: { type: String, required: true, unique: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  redirect: { type: String, default: '/' },
  expiresAt: { type: Date, required: true },
});

// MongoDB removes expired codes on its own.
eexamsSsoCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('EexamsSsoCode', eexamsSsoCodeSchema);
