import { env } from '../config/env.js';
import { Loan } from '../models/Loan.js';
import { addDays, addSeconds } from '../utils/dates.js';
import { formatInr } from '../utils/format.js';
import { logger } from '../utils/logger.js';
import { underwrite } from './underwriting.service.js';

/**
 * Atomically moves a loan from `from` to `to` and records it in the status history.
 * Returns the updated loan, or null if the loan was no longer in `from`
 * (another request or the scheduler already moved it), which makes this race-safe.
 */
export function transitionLoan(loanId, from, to, { note, at = new Date(), set = {} } = {}) {
  return Loan.findOneAndUpdate(
    { _id: loanId, status: from },
    {
      $set: { status: to, statusUpdatedAt: at, ...set },
      $push: { statusHistory: { status: to, note, at } },
    },
    { returnDocument: 'after' },
  );
}

/**
 * Returns a function performing the next automatic transition if one is due, otherwise null.
 * Timestamps use the moment the step was due (not "now"), so a server that was asleep
 * (e.g. a free Render instance) still produces a realistic timeline when it wakes up.
 */
function dueTransition(loan, now) {
  switch (loan.status) {
    case 'SUBMITTED': {
      const at = addSeconds(loan.statusUpdatedAt, env.LOAN_REVIEW_DELAY_SECONDS);
      if (at > now) return null;
      return () => transitionLoan(loan._id, 'SUBMITTED', 'UNDER_REVIEW', {
        at,
        note: 'Our credit team has started reviewing your application.',
      });
    }
    case 'UNDER_REVIEW': {
      const at = addSeconds(loan.statusUpdatedAt, env.LOAN_DECISION_DELAY_SECONDS);
      if (at > now) return null;
      return async () => {
        const decision = await underwrite(loan);
        const to = decision.approved ? 'APPROVED' : 'REJECTED';
        const note = decision.approved
          ? 'Your loan is approved. Complete E-KYC, E-NACH and E-Sign to receive the money.'
          : decision.reasons.join(' ');
        return transitionLoan(loan._id, 'UNDER_REVIEW', to, {
          at,
          note,
          set: { decision: { reasons: decision.reasons, bureauScore: decision.bureauScore, decidedAt: at } },
        });
      };
    }
    case 'APPROVED': {
      if (!loan.steps?.esignAt) return null; // waiting for the borrower
      const at = addSeconds(loan.steps.esignAt, env.LOAN_DISBURSAL_DELAY_SECONDS);
      if (at > now) return null;
      return () => transitionLoan(loan._id, 'APPROVED', 'DISBURSED', {
        at,
        note: `${formatInr(loan.disbursalAmount)} has been sent to your bank account.`,
        set: { disbursedAt: at, dueDate: addDays(at, loan.tenureDays) },
      });
    }
    default:
      return null;
  }
}

/**
 * Applies every automatic transition that is due. Called when a loan is read and by the
 * background sweep, so status updates also work on serverless hosts without timers.
 */
export async function advanceLoan(loan, now = new Date()) {
  let current = loan;
  for (let i = 0; i < 4 && current; i += 1) {
    const step = dueTransition(current, now);
    if (!step) break;
    current = (await step()) ?? (await Loan.findById(current._id));
  }
  return current;
}

/** Periodically advances in-flight loans. Returns a function that stops the timer. */
export function startLifecycleScheduler() {
  if (!env.LIFECYCLE_SWEEP_SECONDS) return () => {};

  const timer = setInterval(async () => {
    try {
      const loans = await Loan.find({ status: { $in: ['SUBMITTED', 'UNDER_REVIEW', 'APPROVED'] } }).limit(200);
      for (const loan of loans) await advanceLoan(loan);
    } catch (error) {
      logger.error('Loan lifecycle sweep failed:', error);
    }
  }, env.LIFECYCLE_SWEEP_SECONDS * 1000);

  timer.unref();
  return () => clearInterval(timer);
}
