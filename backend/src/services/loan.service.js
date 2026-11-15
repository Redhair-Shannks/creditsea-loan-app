import crypto from 'node:crypto';
import { ACTIVE_LOAN_STATUSES, Loan } from '../models/Loan.js';
import { nextSequence } from '../models/Counter.js';
import { ApiError } from '../utils/ApiError.js';
import { addDays } from '../utils/dates.js';
import { formatInr, maskTail } from '../utils/format.js';
import { recordCreditEvent } from './creditScore.service.js';
import { assessEligibility } from './eligibility.service.js';
import { advanceLoan, transitionLoan } from './loanLifecycle.service.js';
import { priceLoan } from './pricing.js';

export const hasActiveLoan = (userId) => Loan.exists({ user: userId, status: { $in: ACTIVE_LOAN_STATUSES } });

/** Quote shown on the "Our Offerings" screen. */
export async function quoteLoan(user, request) {
  return assessEligibility(user, request, { hasActiveLoan: Boolean(await hasActiveLoan(user._id)) });
}

/** Submits an application for the offered amount. */
export async function applyForLoan(user, { principal, tenureDays, purpose }) {
  const assessment = await quoteLoan(user, { principal, tenureDays });
  if (!assessment.eligible) {
    throw ApiError.unprocessable(assessment.reasons[0], 'NOT_ELIGIBLE', { reasons: assessment.reasons });
  }
  if (principal > assessment.maxEligibleAmount) {
    throw ApiError.unprocessable(
      `You can borrow up to ${formatInr(assessment.maxEligibleAmount)} right now.`,
      'AMOUNT_ABOVE_LIMIT',
      { maxEligibleAmount: assessment.maxEligibleAmount },
    );
  }

  const now = new Date();
  const applicationNo = `CS${await nextSequence('loanApplication')}`;
  return Loan.create({
    user: user._id,
    applicationNo,
    purpose,
    ...priceLoan({ principal, tenureDays }),
    status: 'SUBMITTED',
    statusUpdatedAt: now,
    statusHistory: [{ status: 'SUBMITTED', note: 'We have received your loan application.', at: now }],
  });
}

/** Loads one of the user's loans (404 otherwise) and applies any due status updates. */
export async function getLoanForUser(userId, loanId) {
  const loan = await Loan.findOne({ _id: loanId, user: userId });
  if (!loan) throw ApiError.notFound('Loan application not found.', 'LOAN_NOT_FOUND');
  return advanceLoan(loan);
}

export async function listLoansForUser(userId) {
  const loans = await Loan.find({ user: userId }).sort({ createdAt: -1 }).limit(50);
  return Promise.all(loans.map((loan) => advanceLoan(loan)));
}

/**
 * Post-approval steps from the design: E-KYC -> E-NACH -> E-Sign (in that order).
 * Only masked identifiers are stored.
 */
export async function completeVerificationStep(userId, loanId, step, payload) {
  const loan = await getLoanForUser(userId, loanId);
  if (loan.status !== 'APPROVED') {
    throw ApiError.conflict('This step is only available for approved loans.', 'INVALID_LOAN_STATE');
  }

  const steps = loan.steps ?? {};
  const now = new Date();
  switch (step) {
    case 'ekyc':
      steps.ekycAt = now;
      steps.aadhaarMasked = maskTail(payload.aadhaarNumber);
      break;
    case 'enach':
      if (!steps.ekycAt) throw ApiError.conflict('Please complete E-KYC first.', 'STEP_OUT_OF_ORDER');
      steps.enachAt = now;
      steps.bankAccountMasked = maskTail(payload.accountNumber);
      steps.ifsc = payload.ifsc;
      break;
    case 'esign':
      if (!steps.enachAt) throw ApiError.conflict('Please set up E-NACH first.', 'STEP_OUT_OF_ORDER');
      steps.esignAt = now;
      break;
    default:
      throw ApiError.notFound('Unknown verification step.', 'UNKNOWN_STEP');
  }

  loan.steps = steps;
  await loan.save();
  return advanceLoan(loan);
}

/**
 * Mock UPI repayment (bonus). Mirrors payment-gateway sandboxes: any valid UPI ID
 * succeeds, except one containing "fail" (e.g. fail@upi), which is declined.
 */
export async function recordRepayment(userId, loanId, { amount, method, upiId }) {
  const loan = await getLoanForUser(userId, loanId);
  if (loan.status !== 'DISBURSED') {
    throw ApiError.conflict('Only disbursed loans can be repaid.', 'INVALID_LOAN_STATE');
  }
  if (amount > loan.outstanding) {
    throw ApiError.badRequest(`The outstanding amount is ${formatInr(loan.outstanding)}.`, 'AMOUNT_TOO_HIGH');
  }
  if (upiId.includes('fail')) {
    throw new ApiError(402, 'PAYMENT_DECLINED', 'Payment declined by your bank (sandbox). Try another UPI ID.');
  }

  const now = new Date();
  loan.repayments.push({
    amount,
    method,
    upiId,
    reference: `CSPAY${crypto.randomBytes(5).toString('hex').toUpperCase()}`,
    paidAt: now,
  });
  loan.amountPaid += amount;

  let creditEvent = 'PART_PAYMENT';
  if (loan.outstanding === 0) {
    creditEvent = !loan.dueDate || now <= loan.dueDate ? 'REPAID_ON_TIME' : 'REPAID_LATE';
    loan.status = 'CLOSED';
    loan.closedAt = now;
    loan.statusUpdatedAt = now;
    loan.statusHistory.push({ status: 'CLOSED', note: 'Loan repaid in full. Thank you!', at: now });
  }

  await loan.save();
  const user = await recordCreditEvent(userId, creditEvent, loan._id);
  return { loan, user };
}

const ADMIN_TRANSITIONS = Object.freeze({
  SUBMITTED: ['UNDER_REVIEW', 'REJECTED'],
  UNDER_REVIEW: ['APPROVED', 'REJECTED'],
  APPROVED: ['DISBURSED', 'REJECTED'],
  DISBURSED: ['CLOSED'],
});

/** Manual override used by the admin API (handy for demos). */
export async function adminSetStatus(loanId, status, note) {
  const loan = await Loan.findById(loanId);
  if (!loan) throw ApiError.notFound('Loan not found.', 'LOAN_NOT_FOUND');
  if (!(ADMIN_TRANSITIONS[loan.status] ?? []).includes(status)) {
    throw ApiError.conflict(`Cannot move a loan from ${loan.status} to ${status}.`, 'INVALID_TRANSITION');
  }

  const now = new Date();
  const set = {};
  if (status === 'REJECTED') set.decision = { reasons: [note ?? 'Rejected by the credit team.'], decidedAt: now };
  if (status === 'APPROVED') set.decision = { reasons: [], decidedAt: now };
  if (status === 'DISBURSED') {
    Object.assign(set, {
      disbursedAt: now,
      dueDate: addDays(now, loan.tenureDays),
      'steps.ekycAt': loan.steps?.ekycAt ?? now,
      'steps.enachAt': loan.steps?.enachAt ?? now,
      'steps.esignAt': loan.steps?.esignAt ?? now,
    });
  }
  if (status === 'CLOSED') Object.assign(set, { closedAt: now, amountPaid: loan.totalPayable });

  const updated = await transitionLoan(loan._id, loan.status, status, { at: now, note: note ?? undefined, set });
  if (!updated) throw ApiError.conflict('The loan changed while you were updating it. Please retry.', 'CONCURRENT_UPDATE');
  return updated;
}
