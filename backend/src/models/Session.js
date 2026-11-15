import mongoose from 'mongoose';

/**
 * A signed-in device. The JWT carries the session id, so logging out (deleting the
 * session) invalidates the token immediately, and the app can slide the expiry
 * forward on every launch to keep the user signed in until they log out.
 */
const sessionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    /** How the user proved who they are. Changing an existing password needs a recent OTP session. */
    method: { type: String, enum: ['OTP', 'PASSWORD'], required: true },
    expiresAt: { type: Date, required: true },
    lastSeenAt: { type: Date, default: Date.now },
    userAgent: { type: String, maxlength: 300 },
  },
  { timestamps: true },
);

sessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Session = mongoose.model('Session', sessionSchema);
