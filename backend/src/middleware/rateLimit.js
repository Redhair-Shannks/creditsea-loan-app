import { rateLimit } from 'express-rate-limit';
import { env } from '../config/env.js';
import { ApiError } from '../utils/ApiError.js';

const limiter = (limit, windowMinutes) =>
  rateLimit({
    windowMs: windowMinutes * 60 * 1000,
    limit: env.isTest ? 10_000 : limit,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    handler: (_req, _res, next) => next(ApiError.tooMany('Too many attempts. Please try again in a few minutes.', 'RATE_LIMITED')),
  });

/** OTP and login endpoints are the ones worth brute-forcing, so they get tight limits. */
export const otpLimiter = limiter(20, 15);
export const loginLimiter = limiter(15, 15);
