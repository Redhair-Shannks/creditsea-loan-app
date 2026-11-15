import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { assessEligibility, maxEligibleAmount } from '../src/services/eligibility.service.js';
import { priceLoan } from '../src/services/pricing.js';
import { mockBureauLookup } from '../src/services/underwriting.service.js';

const applicant = (overrides = {}) => ({
  onboardingStep: 'COMPLETE',
  dob: new Date('1995-04-12T00:00:00Z'),
  employmentType: 'SALARIED',
  monthlyIncome: 40000,
  creditScore: 650,
  ...overrides,
});
const NOW = new Date('2026-11-15T00:00:00Z');

describe('priceLoan', () => {
  it('applies 1% simple interest per day and a 10% processing fee', () => {
    assert.deepEqual(priceLoan({ principal: 30000, tenureDays: 40 }), {
      principal: 30000,
      tenureDays: 40,
      interestPerDayPct: 1,
      processingFeePct: 10,
      interest: 12000,
      processingFee: 3000,
      totalPayable: 42000,
      disbursalAmount: 27000,
    });
  });
});

describe('maxEligibleAmount', () => {
  it('scales income by employment type and credit band', () => {
    assert.equal(maxEligibleAmount(applicant()), 32000); // 40k x 1 x 0.8 (Fair)
    assert.equal(maxEligibleAmount(applicant({ creditScore: 760 })), 50000); // x 1.25 (Excellent)
    assert.equal(maxEligibleAmount(applicant({ employmentType: 'SELF_EMPLOYED' })), 24000); // x 0.75
    assert.equal(maxEligibleAmount(applicant({ employmentType: 'STUDENT' })), 0);
  });

  it('is capped at the product maximum and rounded to the slider step', () => {
    assert.equal(maxEligibleAmount(applicant({ monthlyIncome: 500000 })), 100000);
    assert.equal(maxEligibleAmount(applicant({ monthlyIncome: 33333 })), 26000);
  });
});

describe('assessEligibility', () => {
  it('offers the requested amount when it is within the limit', () => {
    const result = assessEligibility(applicant(), { principal: 20000, tenureDays: 30 }, { now: NOW });
    assert.equal(result.eligible, true);
    assert.equal(result.offer.principal, 20000);
    assert.equal(result.amountAdjusted, false);
  });

  it('reduces the offer to the limit when the request is higher', () => {
    const result = assessEligibility(applicant(), { principal: 80000, tenureDays: 30 }, { now: NOW });
    assert.equal(result.eligible, true);
    assert.equal(result.offer.principal, 32000);
    assert.equal(result.amountAdjusted, true);
  });

  it('explains every failed rule', () => {
    const result = assessEligibility(
      applicant({ dob: new Date('2007-01-01T00:00:00Z'), monthlyIncome: 9000, creditScore: 590 }),
      { principal: 10000, tenureDays: 20 },
      { hasActiveLoan: true, now: NOW },
    );
    assert.equal(result.eligible, false);
    assert.equal(result.offer, null);
    const failed = result.checks.filter((c) => !c.passed).map((c) => c.key);
    assert.deepEqual(failed, ['AGE', 'INCOME', 'CREDIT_SCORE', 'NO_ACTIVE_LOAN', 'LIMIT']);
  });

  it('requires a completed profile', () => {
    const result = assessEligibility(applicant({ onboardingStep: 'PAN' }), { principal: 10000, tenureDays: 20 }, { now: NOW });
    assert.equal(result.eligible, false);
    assert.equal(result.checks[0].key, 'PROFILE');
  });
});

describe('mockBureauLookup (sandbox)', () => {
  it('returns a poor record for PANs whose number starts with 9', () => {
    assert.equal(mockBureauLookup('ABCPE9123F').score, 590);
    assert.equal(mockBureauLookup('ABCPE1234F').score, 760);
  });
});
