import { ELIGIBILITY_RULES } from '../config/loanProduct.js';
import { ACTIVE_LOAN_STATUSES, Loan } from '../models/Loan.js';
import { User } from '../models/User.js';
import { assessEligibility } from './eligibility.service.js';

/**
 * Sandbox credit bureau. A real lender would call CIBIL/Experian here.
 * To make both outcomes easy to demo, the result is derived from the PAN:
 * a PAN whose number part starts with 9 (e.g. ABCPE9123F) returns a poor record.
 */
export function mockBureauLookup(pan) {
  const poor = typeof pan === 'string' && pan.charAt(5) === '9';
  return { score: poor ? 590 : 760, provider: 'sandbox' };
}

/**
 * Final credit decision, run when an application leaves "Under review".
 * Re-applies the eligibility policy (things may have changed since the quote)
 * and adds the bureau check.
 */
export async function underwrite(loan) {
  const user = await User.findById(loan.user);
  if (!user) return { approved: false, reasons: ['Applicant account no longer exists.'], bureauScore: null };

  const otherActiveLoan = await Loan.exists({
    user: loan.user,
    _id: { $ne: loan._id },
    status: { $in: ACTIVE_LOAN_STATUSES },
  });

  const assessment = assessEligibility(
    user,
    { principal: loan.principal, tenureDays: loan.tenureDays },
    { hasActiveLoan: Boolean(otherActiveLoan) },
  );

  const reasons = [...assessment.reasons];
  if (assessment.eligible && loan.principal > assessment.maxEligibleAmount) {
    reasons.push('The loan amount is above your current limit.');
  }

  const bureau = mockBureauLookup(user.pan);
  if (bureau.score < ELIGIBILITY_RULES.minBureauScore) {
    reasons.push('Your credit bureau report does not meet our lending criteria right now.');
  }

  return { approved: reasons.length === 0, reasons, bureauScore: bureau.score };
}
