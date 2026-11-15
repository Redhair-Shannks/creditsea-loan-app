import mongoose from 'mongoose';
import { CREDIT_SCORE } from '../config/loanProduct.js';
import { toIsoDate } from '../utils/dates.js';
import { maskPan } from '../utils/format.js';

export const GENDERS = Object.freeze(['MALE', 'FEMALE', 'OTHER']);
export const MARITAL_STATUSES = Object.freeze(['SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED']);
export const EMPLOYMENT_TYPES = Object.freeze(['SALARIED', 'SELF_EMPLOYED', 'STUDENT', 'OTHER']);

/**
 * Sign-up is a short wizard. `onboardingStep` tells the app which screen comes next,
 * so the routing rules live in one place (here) instead of being duplicated in the app.
 */
export const ONBOARDING_STEPS = Object.freeze(['PASSWORD', 'PERSONAL', 'EMAIL', 'PAN', 'EMPLOYMENT', 'COMPLETE']);

const creditEventSchema = new mongoose.Schema(
  {
    delta: { type: Number, required: true },
    reason: { type: String, required: true },
    scoreAfter: { type: Number, required: true },
    loan: { type: mongoose.Schema.Types.ObjectId, ref: 'Loan' },
    at: { type: Date, default: Date.now },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    phone: { type: String, required: true, unique: true, trim: true, match: /^[6-9]\d{9}$/ },
    passwordHash: { type: String },

    firstName: { type: String, trim: true, maxlength: 50 },
    lastName: { type: String, trim: true, maxlength: 50 },
    gender: { type: String, enum: GENDERS },
    dob: { type: Date },
    maritalStatus: { type: String, enum: MARITAL_STATUSES },

    // Only stored once verified (OTP for email, format + uniqueness for PAN).
    email: { type: String, trim: true, lowercase: true },
    emailVerifiedAt: { type: Date },
    pan: { type: String, trim: true, uppercase: true },
    panVerifiedAt: { type: Date },

    employmentType: { type: String, enum: EMPLOYMENT_TYPES },
    monthlyIncome: { type: Number, min: 0 },

    creditScore: { type: Number, default: CREDIT_SCORE.initial, min: CREDIT_SCORE.min, max: CREDIT_SCORE.max },
    creditHistory: { type: [creditEventSchema], default: [] },

    lastLoginAt: { type: Date },
  },
  { timestamps: true },
);

userSchema.index({ email: 1 }, { unique: true, partialFilterExpression: { email: { $type: 'string' } } });
userSchema.index({ pan: 1 }, { unique: true, partialFilterExpression: { pan: { $type: 'string' } } });

userSchema.virtual('onboardingStep').get(function onboardingStep() {
  if (!this.passwordHash) return 'PASSWORD';
  if (!this.firstName || !this.lastName || !this.gender || !this.dob || !this.maritalStatus) return 'PERSONAL';
  if (!this.emailVerifiedAt) return 'EMAIL';
  if (!this.panVerifiedAt) return 'PAN';
  if (!this.employmentType || this.monthlyIncome == null) return 'EMPLOYMENT';
  return 'COMPLETE';
});

userSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this.id,
    phone: this.phone,
    firstName: this.firstName ?? null,
    lastName: this.lastName ?? null,
    fullName: [this.firstName, this.lastName].filter(Boolean).join(' ') || null,
    gender: this.gender ?? null,
    dob: toIsoDate(this.dob),
    maritalStatus: this.maritalStatus ?? null,
    email: this.email ?? null,
    emailVerified: Boolean(this.emailVerifiedAt),
    panMasked: maskPan(this.pan),
    panVerified: Boolean(this.panVerifiedAt),
    employmentType: this.employmentType ?? null,
    monthlyIncome: this.monthlyIncome ?? null,
    creditScore: this.creditScore,
    creditHistory: this.creditHistory.slice(-10).reverse().map((event) => ({
      delta: event.delta,
      reason: event.reason,
      scoreAfter: event.scoreAfter,
      at: event.at,
    })),
    hasPassword: Boolean(this.passwordHash),
    onboardingStep: this.onboardingStep,
    createdAt: this.createdAt,
  };
};

export const User = mongoose.model('User', userSchema);
