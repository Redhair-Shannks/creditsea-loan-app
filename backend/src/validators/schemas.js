import { z } from 'zod';
import { LOAN_PRODUCT } from '../config/loanProduct.js';
import { LOAN_STATUSES } from '../models/Loan.js';
import { EMPLOYMENT_TYPES, GENDERS, MARITAL_STATUSES } from '../models/User.js';
import { ageInYears, parseIsoDate } from '../utils/dates.js';
import { formatInr } from '../utils/format.js';

const phone = z
  .string({ message: 'Mobile number is required' })
  .trim()
  .regex(/^[6-9]\d{9}$/, 'Enter a valid 10-digit mobile number');

const otp = (length) =>
  z.string({ message: 'Code is required' }).trim().regex(new RegExp(`^\\d{${length}}$`), `Enter the ${length}-digit code`);

export const passwordRule = z
  .string({ message: 'Password is required' })
  .min(8, 'Password must be at least 8 characters')
  .max(64, 'Password must be at most 64 characters')
  .regex(/[^A-Za-z0-9\s]/, 'Password must include at least 1 special character');

const personName = (label) =>
  z
    .string({ message: `${label} is required` })
    .trim()
    .min(1, `${label} is required`)
    .max(50, `${label} is too long`)
    .regex(/^[A-Za-z][A-Za-z .'-]*$/, `${label} can only contain letters`);

const email = z.string({ message: 'Email is required' }).trim().toLowerCase().max(254).email('Enter a valid email ID');

// ---- auth
export const phoneOtpRequestSchema = z.object({ phone });
export const phoneOtpVerifySchema = z.object({ phone, otp: otp(4) });
export const loginSchema = z.object({ phone, password: z.string({ message: 'Password is required' }).min(1, 'Password is required') });
export const setPasswordSchema = z.object({ password: passwordRule });

// ---- profile
export const personalDetailsSchema = z.object({
  firstName: personName('First name'),
  lastName: personName('Last name'),
  gender: z.enum(GENDERS, { message: 'Select your gender' }),
  maritalStatus: z.enum(MARITAL_STATUSES, { message: 'Select your marital status' }),
  dob: z
    .string({ message: 'Date of birth is required' })
    .transform((value, ctx) => {
      const date = parseIsoDate(value);
      if (!date) {
        ctx.addIssue({ code: 'custom', message: 'Enter a valid date of birth (YYYY-MM-DD)' });
        return z.NEVER;
      }
      return date;
    })
    .refine((date) => ageInYears(date) >= 18, 'You must be at least 18 years old')
    .refine((date) => ageInYears(date) <= 100, 'Enter a valid date of birth'),
});

export const emailOtpRequestSchema = z.object({ email });
export const emailVerifySchema = z.object({ email, otp: otp(6) });

export const panSchema = z.object({
  pan: z
    .string({ message: 'PAN is required' })
    .trim()
    .toUpperCase()
    .regex(/^[A-Z]{5}\d{4}[A-Z]$/, 'Enter a valid PAN, e.g. ABCPE1234F')
    .refine((pan) => pan[3] === 'P', 'Enter your personal PAN (the 4th character is "P")'),
});

export const employmentSchema = z.object({
  employmentType: z.enum(EMPLOYMENT_TYPES, { message: 'Select your employment type' }),
  monthlyIncome: z.coerce
    .number({ message: 'Enter your monthly income' })
    .int('Enter a whole number')
    .min(0, 'Income cannot be negative')
    .max(10_000_000, 'Enter a realistic monthly income'),
});

// ---- loans
export const loanQuoteSchema = z.object({
  principal: z.coerce
    .number({ message: 'Enter a loan amount' })
    .int()
    .min(LOAN_PRODUCT.minAmount, `Minimum loan amount is ${formatInr(LOAN_PRODUCT.minAmount)}`)
    .max(LOAN_PRODUCT.maxAmount, `Maximum loan amount is ${formatInr(LOAN_PRODUCT.maxAmount)}`),
  tenureDays: z.coerce
    .number({ message: 'Select a tenure' })
    .int()
    .min(LOAN_PRODUCT.minTenureDays, `Minimum tenure is ${LOAN_PRODUCT.minTenureDays} days`)
    .max(LOAN_PRODUCT.maxTenureDays, `Maximum tenure is ${LOAN_PRODUCT.maxTenureDays} days`),
});

export const loanApplySchema = loanQuoteSchema.extend({
  purpose: z.enum(LOAN_PRODUCT.purposes, { message: 'Select the purpose of the loan' }),
});

export const ekycSchema = z.object({
  aadhaarNumber: z.string({ message: 'Aadhaar number is required' }).trim().regex(/^[2-9]\d{11}$/, 'Enter a valid 12-digit Aadhaar number'),
  consent: z.literal(true, { message: 'Please give your consent to continue' }),
});

export const enachSchema = z.object({
  accountNumber: z.string({ message: 'Account number is required' }).trim().regex(/^\d{9,18}$/, 'Enter a valid bank account number'),
  ifsc: z.string({ message: 'IFSC is required' }).trim().toUpperCase().regex(/^[A-Z]{4}0[A-Z0-9]{6}$/, 'Enter a valid IFSC, e.g. HDFC0001234'),
});

export const esignSchema = z.object({
  agreed: z.literal(true, { message: 'Please accept the loan agreement' }),
});

export const repaymentSchema = z.object({
  amount: z.coerce.number({ message: 'Enter an amount' }).int('Enter a whole amount').positive('Enter an amount'),
  method: z.enum(['UPI']).default('UPI'),
  upiId: z
    .string({ message: 'UPI ID is required' })
    .trim()
    .toLowerCase()
    .regex(/^[a-z0-9._-]{2,256}@[a-z]{2,64}$/, 'Enter a valid UPI ID, e.g. name@okaxis'),
});

// ---- admin
export const adminStatusSchema = z.object({
  status: z.enum(LOAN_STATUSES),
  note: z.string().trim().max(300).optional(),
});

export const objectIdParam = z.object({
  id: z.string().regex(/^[a-f\d]{24}$/i, 'Invalid id'),
});
