import crypto from 'node:crypto';
import { env } from '../config/env.js';
import { Session } from '../models/Session.js';
import { User } from '../models/User.js';
import { verifyToken } from '../services/token.service.js';
import { ApiError } from '../utils/ApiError.js';

const sessionExpired = () => ApiError.unauthorized('Your session has ended. Please sign in again.', 'SESSION_EXPIRED');

/** Requires `Authorization: Bearer <token>` for a live session; sets req.user and req.authSession. */
export async function requireAuth(req, _res, next) {
  const [scheme, token] = (req.get('authorization') ?? '').split(' ');
  if (scheme !== 'Bearer' || !token) throw ApiError.unauthorized();

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    throw sessionExpired();
  }

  const session = await Session.findById(payload.sid);
  if (!session || session.expiresAt <= new Date() || String(session.user) !== payload.sub) throw sessionExpired();

  const user = await User.findById(payload.sub);
  if (!user) throw sessionExpired();

  req.user = user;
  req.authSession = session;
  next();
}

/** Protects the admin API with a shared key. The admin API is disabled when no key is configured. */
export function requireAdmin(req, _res, next) {
  if (!env.ADMIN_API_KEY) throw ApiError.notFound();
  const given = Buffer.from(req.get('x-admin-key') ?? '');
  const expected = Buffer.from(env.ADMIN_API_KEY);
  if (given.length !== expected.length || !crypto.timingSafeEqual(given, expected)) {
    throw ApiError.unauthorized('Invalid admin key.', 'INVALID_ADMIN_KEY');
  }
  next();
}
