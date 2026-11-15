import crypto from 'node:crypto';
import { env } from '../config/env.js';
import { Otp } from '../models/Otp.js';
import { ApiError } from '../utils/ApiError.js';
import { addSeconds } from '../utils/dates.js';

/** Code lengths follow the Figma screens: 4 boxes for the phone OTP, 6 for email. */
export const OTP_PURPOSE = Object.freeze({
  PHONE_LOGIN: Object.freeze({ key: 'PHONE_LOGIN', length: 4 }),
  EMAIL_VERIFY: Object.freeze({ key: 'EMAIL_VERIFY', length: 6 }),
});

const hashCode = (purpose, target, code) =>
  crypto.createHmac('sha256', `otp:${env.JWT_SECRET}`).update(`${purpose}|${target}|${code}`).digest('hex');

export const generateCode = (length) => crypto.randomInt(0, 10 ** length).toString().padStart(length, '0');

/**
 * Creates (or replaces) the OTP for a target, enforcing the resend cool-down.
 * Returns the plain code so the caller can deliver it.
 */
export async function issueOtp(purpose, target, now = new Date()) {
  const existing = await Otp.findOne({ purpose: purpose.key, target });
  if (existing && existing.expiresAt > now) {
    const retryAt = addSeconds(existing.lastSentAt, env.OTP_RESEND_SECONDS);
    if (retryAt > now) {
      const retryAfterSec = Math.ceil((retryAt.getTime() - now.getTime()) / 1000);
      throw ApiError.tooMany(`Please wait ${retryAfterSec}s before requesting a new code.`, 'OTP_RESEND_TOO_SOON', {
        retryAfterSec,
      });
    }
  }

  const code = generateCode(purpose.length);
  await Otp.findOneAndUpdate(
    { purpose: purpose.key, target },
    {
      codeHash: hashCode(purpose.key, target, code),
      attempts: 0,
      lastSentAt: now,
      expiresAt: addSeconds(now, env.OTP_TTL_SECONDS),
    },
    { upsert: true },
  );

  return { code, length: purpose.length, expiresInSec: env.OTP_TTL_SECONDS, resendAfterSec: env.OTP_RESEND_SECONDS };
}

/** API response for a freshly issued OTP. In dev mode the code is included so the app can be demoed. */
export const otpResponse = (otp, message) => ({
  message,
  length: otp.length,
  expiresInSec: otp.expiresInSec,
  resendAfterSec: otp.resendAfterSec,
  ...(env.OTP_DEV_MODE ? { devOtp: otp.code } : {}),
});

/** Verifies and burns an OTP. Throws a user-friendly ApiError when it doesn't match. */
export async function consumeOtp(purpose, target, code) {
  const otp = await Otp.findOne({ purpose: purpose.key, target });
  if (!otp || otp.expiresAt <= new Date()) {
    throw ApiError.badRequest('This code has expired. Please request a new one.', 'OTP_EXPIRED');
  }
  if (otp.attempts >= env.OTP_MAX_ATTEMPTS) {
    throw ApiError.tooMany('Too many incorrect attempts. Please request a new code.', 'OTP_ATTEMPTS_EXCEEDED');
  }

  const expected = Buffer.from(otp.codeHash, 'hex');
  const actual = Buffer.from(hashCode(purpose.key, target, code), 'hex');
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
    otp.attempts += 1;
    await otp.save();
    const remainingAttempts = Math.max(0, env.OTP_MAX_ATTEMPTS - otp.attempts);
    const message = remainingAttempts > 0
      ? `Incorrect code. ${remainingAttempts} attempt${remainingAttempts === 1 ? '' : 's'} left.`
      : 'Incorrect code. Please request a new one.';
    throw ApiError.badRequest(message, 'OTP_INVALID', { remainingAttempts });
  }

  await otp.deleteOne();
}
