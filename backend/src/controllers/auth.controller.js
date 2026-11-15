import bcrypt from 'bcryptjs';
import { User } from '../models/User.js';
import { sendSms } from '../services/notification.service.js';
import { OTP_PURPOSE, consumeOtp, issueOtp, otpResponse } from '../services/otp.service.js';
import { createSession, refreshSession, revokeSession } from '../services/token.service.js';
import { ApiError } from '../utils/ApiError.js';

const BCRYPT_ROUNDS = 10;
/** Recent-OTP window in which an existing password may be reset. */
const PASSWORD_RESET_WINDOW_MS = 15 * 60 * 1000;
// Compared against when the phone is unknown, so response time doesn't reveal registered numbers.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password!', BCRYPT_ROUNDS);

/** POST /auth/otp/send — step 1 of sign-up / OTP sign-in. */
export async function sendPhoneOtp(req, res) {
  const { phone } = req.valid.body;
  const otp = await issueOtp(OTP_PURPOSE.PHONE_LOGIN, phone);
  const minutes = Math.round(otp.expiresInSec / 60);
  await sendSms(phone, `${otp.code} is your CreditSea verification code. Valid for ${minutes} minutes. Do not share it.`);
  res.json(otpResponse(otp, `OTP sent to +91 ${phone}`));
}

/** POST /auth/otp/verify — creates the account on first sign-in and returns a session token. */
export async function verifyPhoneOtp(req, res) {
  const { phone, otp } = req.valid.body;
  await consumeOtp(OTP_PURPOSE.PHONE_LOGIN, phone, otp);

  const existing = await User.findOne({ phone });
  const user = existing ?? new User({ phone });
  user.lastLoginAt = new Date();
  await user.save();

  const { token } = await createSession(user, { method: 'OTP', userAgent: req.get('user-agent') });
  res.status(existing ? 200 : 201).json({ token, user: user.toPublicJSON(), isNewUser: !existing });
}

/** POST /auth/login — mobile number + password ("Please enter your credentials" screen). */
export async function login(req, res) {
  const { phone, password } = req.valid.body;
  const user = await User.findOne({ phone });
  const matches = await bcrypt.compare(password, user?.passwordHash ?? DUMMY_HASH);
  if (!user?.passwordHash || !matches) {
    throw ApiError.unauthorized('Incorrect mobile number or password.', 'INVALID_CREDENTIALS');
  }

  user.lastLoginAt = new Date();
  await user.save();
  const { token } = await createSession(user, { method: 'PASSWORD', userAgent: req.get('user-agent') });
  res.json({ token, user: user.toPublicJSON(), isNewUser: false });
}

/**
 * POST /auth/password — "Create a password" screen. Also used for "Forgot password":
 * an existing password can only be replaced from a session verified by OTP in the last 15 minutes.
 */
export async function setPassword(req, res) {
  const { user, authSession } = req;
  const recentOtp = authSession.method === 'OTP' && Date.now() - authSession.createdAt.getTime() < PASSWORD_RESET_WINDOW_MS;
  if (user.passwordHash && !recentOtp) {
    throw ApiError.forbidden('Verify your mobile number with an OTP to change your password.', 'OTP_REQUIRED');
  }

  user.passwordHash = await bcrypt.hash(req.valid.body.password, BCRYPT_ROUNDS);
  await user.save();
  res.json({ user: user.toPublicJSON() });
}

/** POST /auth/refresh — called on app start to slide the session forward (keeps users signed in). */
export async function refresh(req, res) {
  const token = await refreshSession(req.user, req.authSession);
  res.json({ token, user: req.user.toPublicJSON() });
}

/** POST /auth/logout — revokes this device's session. */
export async function logout(req, res) {
  await revokeSession(req.authSession._id);
  res.status(204).end();
}
