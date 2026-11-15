/**
 * Loan product and credit policy.
 *
 * Defaults follow the Figma design: 1% interest per day, 10% processing fee
 * and a 20-45 day tenure. The app reads these values from GET /loans/config,
 * so they can change here without shipping a new APK.
 */
export const LOAN_PRODUCT = Object.freeze({
  currency: 'INR',
  minAmount: 5000,
  maxAmount: 100000,
  amountStep: 1000,
  minTenureDays: 20,
  maxTenureDays: 45,
  interestPerDayPct: 1,
  processingFeePct: 10,
  purposes: Object.freeze([
    'Personal',
    'Medical',
    'Education',
    'Travel',
    'Home renovation',
    'Business',
    'Wedding',
    'Other',
  ]),
});

export const ELIGIBILITY_RULES = Object.freeze({
  minAge: 21,
  maxAge: 60,
  minMonthlyIncome: 15000,
  minCreditScore: 600,
  /** Bureau score below which underwriting rejects an application. */
  minBureauScore: 650,
  /** Share of monthly income that can be borrowed, by employment type. */
  incomeMultiplier: Object.freeze({
    SALARIED: 1,
    SELF_EMPLOYED: 0.75,
    STUDENT: 0,
    OTHER: 0,
  }),
  /** Credit-score bands scale the limit. Ordered from best to worst. */
  scoreBands: Object.freeze([
    Object.freeze({ minScore: 750, multiplier: 1.25, label: 'Excellent' }),
    Object.freeze({ minScore: 700, multiplier: 1, label: 'Good' }),
    Object.freeze({ minScore: 650, multiplier: 0.8, label: 'Fair' }),
    Object.freeze({ minScore: 600, multiplier: 0.6, label: 'Average' }),
  ]),
});

/** Internal credit score (bonus feature): repayments move it up. */
export const CREDIT_SCORE = Object.freeze({
  initial: 650,
  min: 300,
  max: 900,
  events: Object.freeze({
    REPAID_ON_TIME: Object.freeze({ delta: 30, reason: 'Loan repaid on time' }),
    REPAID_LATE: Object.freeze({ delta: 10, reason: 'Loan repaid after the due date' }),
    PART_PAYMENT: Object.freeze({ delta: 5, reason: 'Part payment received' }),
  }),
});
