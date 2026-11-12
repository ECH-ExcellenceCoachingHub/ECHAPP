const mongoose = require('mongoose');

/**
 * Pairs a VR headset (which has no ECH login) with a signed-in student:
 * the headset shows a 6-digit code, the student types it in the ECH app,
 * and the headset then receives a lab token. Documents expire after 10 minutes.
 */
const labPairingSchema = new mongoose.Schema({
  code: { type: String, required: true, index: true },
  // Secret the headset uses to poll; never shown to the user.
  deviceSecret: { type: String, required: true, unique: true },
  deviceName: { type: String, default: 'VR headset' },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  scenarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'LabScenario', default: null },
  lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', default: null },
  confirmedAt: { type: Date, default: null },
  claimedAt: { type: Date, default: null },
  expiresAt: { type: Date, required: true },
}, { timestamps: true });

labPairingSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('LabPairing', labPairingSchema);
