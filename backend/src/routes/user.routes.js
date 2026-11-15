import { Router } from 'express';
import {
  getMe,
  sendEmailOtp,
  updateEmployment,
  updatePersonalDetails,
  verifyEmail,
  verifyPan,
} from '../controllers/user.controller.js';
import { requireAuth } from '../middleware/auth.js';
import { otpLimiter } from '../middleware/rateLimit.js';
import { validate } from '../middleware/validate.js';
import {
  emailOtpRequestSchema,
  emailVerifySchema,
  employmentSchema,
  panSchema,
  personalDetailsSchema,
} from '../validators/schemas.js';

const router = Router();

router.use(requireAuth);
router.get('/me', getMe);
router.put('/me/personal', validate(personalDetailsSchema), updatePersonalDetails);
router.post('/me/email/send-otp', otpLimiter, validate(emailOtpRequestSchema), sendEmailOtp);
router.post('/me/email/verify', otpLimiter, validate(emailVerifySchema), verifyEmail);
router.post('/me/pan/verify', validate(panSchema), verifyPan);
router.put('/me/employment', validate(employmentSchema), updateEmployment);

export default router;
