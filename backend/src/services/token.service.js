import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { Session } from '../models/Session.js';
import { addDays } from '../utils/dates.js';

const sign = (user, session) =>
  jwt.sign({ sid: session.id }, env.JWT_SECRET, {
    subject: user.id,
    expiresIn: `${env.JWT_EXPIRES_IN_DAYS}d`,
  });

/** Starts a new signed-in session (method: 'OTP' | 'PASSWORD') and returns its bearer token. */
export async function createSession(user, { method, userAgent } = {}) {
  const session = await Session.create({
    user: user._id,
    method,
    expiresAt: addDays(new Date(), env.JWT_EXPIRES_IN_DAYS),
    userAgent: userAgent?.slice(0, 300),
  });
  return { token: sign(user, session), session };
}

/** Slides the session expiry forward (called by the app on every launch). */
export async function refreshSession(user, session) {
  session.expiresAt = addDays(new Date(), env.JWT_EXPIRES_IN_DAYS);
  session.lastSeenAt = new Date();
  await session.save();
  return sign(user, session);
}

/** Returns the JWT payload or throws if the token is invalid or expired. */
export const verifyToken = (token) => jwt.verify(token, env.JWT_SECRET);

export const revokeSession = (sessionId) => Session.deleteOne({ _id: sessionId });
