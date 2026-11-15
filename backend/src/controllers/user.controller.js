import { User } from '../models/User.js';
import { sendEmail } from '../services/notification.service.js';
import { OTP_PURPOSE, consumeOtp, issueOtp, otpResponse } from '../services/otp.service.js';
import { ApiError } from '../utils/ApiError.js';

const emailOtpTarget = (user, email) => `${user.id}:${email}`;

async function assertEmailAvailable(user, email) {
  if (await User.exists({ email, _id: { $ne: user._id } })) {
    throw ApiError.conflict('This email ID is already linked to another account.', 'EMAIL_IN_USE');
  }
}

/** GET /users/me */
export function getMe(req, res) {
  res.json({ user: req.user.toPublicJSON() });
}

/** PUT /users/me/personal — "Personal Details" screen. */
export async function updatePersonalDetails(req, res) {
  Object.assign(req.user, req.valid.body);
  await req.user.save();
  res.json({ user: req.user.toPublicJSON() });
}

/** POST /users/me/email/send-otp — "Personal Email ID" screen, sends a 6-digit code. */
export async function sendEmailOtp(req, res) {
  const { email } = req.valid.body;
  await assertEmailAvailable(req.user, email);
  const otp = await issueOtp(OTP_PURPOSE.EMAIL_VERIFY, emailOtpTarget(req.user, email));
  await sendEmail(
    email,
    'Your CreditSea verification code',
    `${otp.code} is your CreditSea email verification code. It is valid for ${Math.round(otp.expiresInSec / 60)} minutes.`,
  );
  res.json(otpResponse(otp, `Code sent to ${email}`));
}

/** POST /users/me/email/verify */
export async function verifyEmail(req, res) {
  const { email, otp } = req.valid.body;
  await assertEmailAvailable(req.user, email);
  await consumeOtp(OTP_PURPOSE.EMAIL_VERIFY, emailOtpTarget(req.user, email), otp);

  req.user.email = email;
  req.user.emailVerifiedAt = new Date();
  await req.user.save();
  res.json({ user: req.user.toPublicJSON() });
}

/**
 * POST /users/me/pan/verify — "Verify PAN Number" screen.
 * Sandbox verification: strict format, personal PAN, one account per PAN.
 * A production build would call a PAN verification API (e.g. Protean/NSDL) here.
 */
export async function verifyPan(req, res) {
  const { pan } = req.valid.body;
  if (await User.exists({ pan, _id: { $ne: req.user._id } })) {
    throw ApiError.conflict('This PAN is already linked to another account.', 'PAN_IN_USE');
  }

  req.user.pan = pan;
  req.user.panVerifiedAt = new Date();
  await req.user.save();
  res.json({ user: req.user.toPublicJSON() });
}

/** PUT /users/me/employment — employment type and monthly income, used by the eligibility rules. */
export async function updateEmployment(req, res) {
  Object.assign(req.user, req.valid.body);
  await req.user.save();
  res.json({ user: req.user.toPublicJSON() });
}
