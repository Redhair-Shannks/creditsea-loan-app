import { ELIGIBILITY_RULES, LOAN_PRODUCT } from '../config/loanProduct.js';
import {
  applyForLoan,
  completeVerificationStep,
  getLoanForUser,
  listLoansForUser,
  quoteLoan,
  recordRepayment,
} from '../services/loan.service.js';

/** GET /loans/config — slider ranges, rates and purposes for the loan calculator. */
export function getConfig(_req, res) {
  const { minAge, maxAge, minMonthlyIncome, minCreditScore } = ELIGIBILITY_RULES;
  res.json({ product: LOAN_PRODUCT, rules: { minAge, maxAge, minMonthlyIncome, minCreditScore } });
}

/** POST /loans/quote — eligibility check + offer ("Our Offerings"). */
export async function quote(req, res) {
  res.json({ assessment: await quoteLoan(req.user, req.valid.body) });
}

/** POST /loans — "Accept Offer" submits the application. */
export async function apply(req, res) {
  const loan = await applyForLoan(req.user, req.valid.body);
  res.status(201).json({ loan: loan.toPublicJSON() });
}

/** GET /loans — the user's applications, newest first. */
export async function list(req, res) {
  const loans = await listLoansForUser(req.user._id);
  res.json({ loans: loans.map((loan) => loan.toPublicJSON()) });
}

/** GET /loans/:id — one application with its status timeline. */
export async function getOne(req, res) {
  const loan = await getLoanForUser(req.user._id, req.valid.params.id);
  res.json({ loan: loan.toPublicJSON() });
}

/** POST /loans/:id/{ekyc|enach|esign} */
export const completeStep = (step) => async (req, res) => {
  const loan = await completeVerificationStep(req.user._id, req.valid.params.id, step, req.valid.body);
  res.json({ loan: loan.toPublicJSON() });
};

/** POST /loans/:id/repayments — mock UPI repayment; returns the loan and the updated credit score. */
export async function repay(req, res) {
  const { loan, user } = await recordRepayment(req.user._id, req.valid.params.id, req.valid.body);
  res.json({ loan: loan.toPublicJSON(), user: user.toPublicJSON() });
}
