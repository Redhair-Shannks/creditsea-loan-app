import { ELIGIBILITY_RULES, LOAN_PRODUCT } from '../config/loanProduct.js';
import { ageInYears } from '../utils/dates.js';
import { formatInr } from '../utils/format.js';
import { priceLoan } from './pricing.js';

/** The credit-score band for a score, or null if the score is below every band. */
export function scoreBand(score) {
  return ELIGIBILITY_RULES.scoreBands.find((band) => score >= band.minScore) ?? null;
}

/**
 * Loan limit = monthly income x employment multiplier x credit-score multiplier,
 * capped at the product maximum and rounded down to the slider step.
 */
export function maxEligibleAmount(user) {
  const band = scoreBand(user.creditScore);
  const incomeMultiplier = ELIGIBILITY_RULES.incomeMultiplier[user.employmentType] ?? 0;
  if (!band || !user.monthlyIncome || incomeMultiplier === 0) return 0;

  const limit = Math.min(LOAN_PRODUCT.maxAmount, user.monthlyIncome * incomeMultiplier * band.multiplier);
  return Math.floor(limit / LOAN_PRODUCT.amountStep) * LOAN_PRODUCT.amountStep;
}

/**
 * Checks an applicant against the credit policy and builds an offer.
 * Used both for the in-app quote ("Our Offerings") and again by underwriting,
 * so what the user is shown and what is decided always follow the same rules.
 *
 * If the requested amount is above the user's limit, the offer is reduced to the limit.
 */
export function assessEligibility(user, { principal, tenureDays }, { hasActiveLoan = false, now = new Date() } = {}) {
  const { minAge, maxAge, minMonthlyIncome, minCreditScore } = ELIGIBILITY_RULES;
  const checks = [];
  const check = (key, label, passed, failMessage) =>
    checks.push({ key, label, passed, message: passed ? null : failMessage });

  const age = user.dob ? ageInYears(user.dob, now) : null;
  const limit = maxEligibleAmount(user);

  check('PROFILE', 'Profile complete', user.onboardingStep === 'COMPLETE',
    'Complete your profile (personal details, email, PAN and income) first.');
  check('AGE', `Age ${minAge}-${maxAge} years`, age !== null && age >= minAge && age <= maxAge,
    `Applicants must be between ${minAge} and ${maxAge} years old.`);
  check('EMPLOYMENT', 'Salaried or self-employed', (ELIGIBILITY_RULES.incomeMultiplier[user.employmentType] ?? 0) > 0,
    'Loans are currently available to salaried and self-employed applicants.');
  check('INCOME', `Monthly income of ${formatInr(minMonthlyIncome)}+`, (user.monthlyIncome ?? 0) >= minMonthlyIncome,
    `A monthly income of at least ${formatInr(minMonthlyIncome)} is required.`);
  check('CREDIT_SCORE', `Credit score of ${minCreditScore}+`, user.creditScore >= minCreditScore,
    `Your credit score (${user.creditScore}) is below ${minCreditScore}.`);
  check('NO_ACTIVE_LOAN', 'No other active loan', !hasActiveLoan,
    'You already have an active loan. Repay it before applying again.');
  check('LIMIT', `Limit of at least ${formatInr(LOAN_PRODUCT.minAmount)}`, limit >= LOAN_PRODUCT.minAmount,
    `Your current loan limit is below the minimum loan amount of ${formatInr(LOAN_PRODUCT.minAmount)}.`);

  const eligible = checks.every((c) => c.passed);
  const offeredPrincipal = eligible ? Math.min(principal, limit) : 0;

  return {
    eligible,
    checks,
    reasons: checks.filter((c) => !c.passed).map((c) => c.message),
    creditScore: user.creditScore,
    creditBand: scoreBand(user.creditScore)?.label ?? 'Poor',
    maxEligibleAmount: limit,
    requested: priceLoan({ principal, tenureDays }),
    offer: eligible ? priceLoan({ principal: offeredPrincipal, tenureDays }) : null,
    amountAdjusted: eligible && offeredPrincipal < principal,
  };
}
