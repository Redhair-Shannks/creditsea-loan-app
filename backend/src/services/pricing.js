import { LOAN_PRODUCT } from '../config/loanProduct.js';

/**
 * Prices a short-term loan with simple daily interest.
 *  - interest       = principal x daily rate x days
 *  - processing fee = principal x fee %, deducted from the amount disbursed
 *  - total payable  = principal + interest (one bullet repayment on the due date)
 */
export function priceLoan({
  principal,
  tenureDays,
  interestPerDayPct = LOAN_PRODUCT.interestPerDayPct,
  processingFeePct = LOAN_PRODUCT.processingFeePct,
}) {
  const interest = Math.round(principal * (interestPerDayPct / 100) * tenureDays);
  const processingFee = Math.round(principal * (processingFeePct / 100));
  return {
    principal,
    tenureDays,
    interestPerDayPct,
    processingFeePct,
    interest,
    processingFee,
    totalPayable: principal + interest,
    disbursalAmount: principal - processingFee,
  };
}
