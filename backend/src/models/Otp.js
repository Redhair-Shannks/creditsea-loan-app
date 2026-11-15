import mongoose from 'mongoose';

/**
 * One active one-time password per (purpose, target). Only an HMAC of the code is
 * stored, never the code itself. MongoDB deletes expired documents via the TTL index.
 */
const otpSchema = new mongoose.Schema({
  purpose: { type: String, required: true },
  target: { type: String, required: true },
  codeHash: { type: String, required: true },
  attempts: { type: Number, default: 0 },
  lastSentAt: { type: Date, required: true },
  expiresAt: { type: Date, required: true },
});

otpSchema.index({ purpose: 1, target: 1 }, { unique: true });
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Otp = mongoose.model('Otp', otpSchema);
