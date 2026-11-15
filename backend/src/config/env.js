import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config({ quiet: true });

/** Boolean env flag ("true"/"false"/"1"/"0") with a default. */
const flag = (defaultValue) =>
  z
    .enum(['true', 'false', '1', '0'])
    .optional()
    .transform((value) => (value === undefined ? defaultValue : value === 'true' || value === '1'));

const seconds = (defaultValue) => z.coerce.number().int().min(0).default(defaultValue);

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  MONGODB_URI: z.string().trim().optional(),
  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters').optional(),
  JWT_EXPIRES_IN_DAYS: z.coerce.number().int().positive().default(30),
  CORS_ORIGINS: z.string().optional(),
  ADMIN_API_KEY: z.string().min(8, 'ADMIN_API_KEY must be at least 8 characters').optional(),

  // OTP delivery. In dev mode the code is also returned in the API response so the
  // app can be demoed without paying for SMS/email.
  OTP_DEV_MODE: flag(true),
  OTP_TTL_SECONDS: seconds(300),
  OTP_RESEND_SECONDS: seconds(30),
  OTP_MAX_ATTEMPTS: z.coerce.number().int().positive().default(5),

  // Simulated loan pipeline timings (seconds after the previous step).
  LOAN_REVIEW_DELAY_SECONDS: seconds(20),
  LOAN_DECISION_DELAY_SECONDS: seconds(40),
  LOAN_DISBURSAL_DELAY_SECONDS: seconds(20),
  LIFECYCLE_SWEEP_SECONDS: seconds(10),

  // Optional real providers.
  TWILIO_ACCOUNT_SID: z.string().optional(),
  TWILIO_AUTH_TOKEN: z.string().optional(),
  TWILIO_FROM_NUMBER: z.string().optional(),
  RESEND_API_KEY: z.string().optional(),
  EMAIL_FROM: z.string().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  const details = parsed.error.issues.map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`).join('\n');
  throw new Error(`Invalid environment configuration:\n${details}`);
}

const raw = parsed.data;

if (raw.NODE_ENV === 'production') {
  for (const key of ['MONGODB_URI', 'JWT_SECRET']) {
    if (!raw[key]) throw new Error(`${key} must be set when NODE_ENV=production`);
  }
}

export const env = Object.freeze({
  ...raw,
  JWT_SECRET: raw.JWT_SECRET ?? 'dev-only-secret-change-me-in-production',
  isProduction: raw.NODE_ENV === 'production',
  isTest: raw.NODE_ENV === 'test',
  corsOrigins: raw.CORS_ORIGINS
    ? raw.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean)
    : null,
  smsProviderConfigured: Boolean(raw.TWILIO_ACCOUNT_SID && raw.TWILIO_AUTH_TOKEN && raw.TWILIO_FROM_NUMBER),
  emailProviderConfigured: Boolean(raw.RESEND_API_KEY && raw.EMAIL_FROM),
});
