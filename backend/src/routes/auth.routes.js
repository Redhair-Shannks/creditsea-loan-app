import { Router } from 'express';
import { login, logout, refresh, sendPhoneOtp, setPassword, verifyPhoneOtp } from '../controllers/auth.controller.js';
import { requireAuth } from '../middleware/auth.js';
import { loginLimiter, otpLimiter } from '../middleware/rateLimit.js';
import { validate } from '../middleware/validate.js';
import { loginSchema, phoneOtpRequestSchema, phoneOtpVerifySchema, setPasswordSchema } from '../validators/schemas.js';

const router = Router();

router.post('/otp/send', otpLimiter, validate(phoneOtpRequestSchema), sendPhoneOtp);
router.post('/otp/verify', otpLimiter, validate(phoneOtpVerifySchema), verifyPhoneOtp);
router.post('/login', loginLimiter, validate(loginSchema), login);
router.post('/password', requireAuth, validate(setPasswordSchema), setPassword);
router.post('/refresh', requireAuth, refresh);
router.post('/logout', requireAuth, logout);

export default router;
