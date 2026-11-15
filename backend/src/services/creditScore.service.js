import { CREDIT_SCORE } from '../config/loanProduct.js';
import { User } from '../models/User.js';

const clamp = (value) => Math.min(CREDIT_SCORE.max, Math.max(CREDIT_SCORE.min, value));

/**
 * Applies a credit event (e.g. REPAID_ON_TIME) to the user's internal score and
 * keeps a short history the app can show. Returns the updated user.
 */
export async function recordCreditEvent(userId, eventKey, loanId) {
  const event = CREDIT_SCORE.events[eventKey];
  if (!event) throw new Error(`Unknown credit event: ${eventKey}`);

  const user = await User.findById(userId);
  const scoreAfter = clamp(user.creditScore + event.delta);
  user.creditHistory.push({
    delta: scoreAfter - user.creditScore,
    reason: event.reason,
    scoreAfter,
    loan: loanId,
    at: new Date(),
  });
  user.creditScore = scoreAfter;
  await user.save();
  return user;
}
