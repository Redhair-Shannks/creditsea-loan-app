import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { API, bearer, completeOnboarding, signUp, startTestServer } from './helpers.js';

let ctx;
before(async () => {
  ctx = await startTestServer();
});
after(async () => {
  await ctx.stop();
});

async function borrower(phone, profile) {
  const { token } = await signUp(ctx.api, phone);
  await completeOnboarding(ctx.api, token, profile);
  return bearer(token);
}

describe('Loan config and quotes', () => {
  it('serves the calculator config publicly', async () => {
    const res = await ctx.api.get(`${API}/loans/config`).expect(200);
    assert.equal(res.body.product.interestPerDayPct, 1);
    assert.equal(res.body.product.minTenureDays, 20);
    assert.equal(res.body.product.maxTenureDays, 45);
  });

  it('caps the offer at the income-based limit', async () => {
    const auth = await borrower('9876510001', { monthlyIncome: 40000, pan: 'BBBPA2222B' });
    const res = await ctx.api.post(`${API}/loans/quote`).set(auth).send({ principal: 80000, tenureDays: 30 }).expect(200);
    assert.equal(res.body.assessment.eligible, true);
    assert.equal(res.body.assessment.offer.principal, 32000);
    assert.equal(res.body.assessment.amountAdjusted, true);
  });

  it('refuses to quote before the profile is complete', async () => {
    const { token } = await signUp(ctx.api, '9876510002');
    const res = await ctx.api.post(`${API}/loans/quote`).set(bearer(token)).send({ principal: 10000, tenureDays: 30 }).expect(200);
    assert.equal(res.body.assessment.eligible, false);
    assert.equal(res.body.assessment.checks[0].key, 'PROFILE');
  });
});

describe('Loan lifecycle', () => {
  it('Submitted -> Under review -> Approved -> E-KYC/E-NACH/E-Sign -> Disbursed -> repaid (score goes up)', async () => {
    const auth = await borrower('9876520001', { monthlyIncome: 60000, pan: 'CCCPB3333C' });

    const applied = await ctx.api
      .post(`${API}/loans`)
      .set(auth)
      .send({ principal: 30000, tenureDays: 40, purpose: 'Medical' })
      .expect(201);
    const { loan } = applied.body;
    assert.equal(loan.status, 'SUBMITTED');
    assert.match(loan.applicationNo, /^CS\d+$/);
    assert.equal(loan.totalPayable, 42000);

    // Review delays are 0 in tests, so reading the loan applies the due transitions.
    const reviewed = await ctx.api.get(`${API}/loans/${loan.id}`).set(auth).expect(200);
    assert.equal(reviewed.body.loan.status, 'APPROVED');
    assert.deepEqual(reviewed.body.loan.statusHistory.map((e) => e.status), ['SUBMITTED', 'UNDER_REVIEW', 'APPROVED']);

    // Steps must be done in order.
    await ctx.api.post(`${API}/loans/${loan.id}/esign`).set(auth).send({ agreed: true }).expect(409);
    await ctx.api.post(`${API}/loans/${loan.id}/ekyc`).set(auth).send({ aadhaarNumber: '234567890123', consent: true }).expect(200);
    await ctx.api.post(`${API}/loans/${loan.id}/enach`).set(auth).send({ accountNumber: '123456789012', ifsc: 'HDFC0001234' }).expect(200);
    const signed = await ctx.api.post(`${API}/loans/${loan.id}/esign`).set(auth).send({ agreed: true }).expect(200);
    assert.equal(signed.body.loan.status, 'DISBURSED');
    assert.equal(signed.body.loan.steps.aadhaarMasked, 'XXXX0123');
    assert.ok(signed.body.loan.dueDate);

    const declined = await ctx.api
      .post(`${API}/loans/${loan.id}/repayments`)
      .set(auth)
      .send({ amount: 1000, upiId: 'fail@upi' })
      .expect(402);
    assert.equal(declined.body.error.code, 'PAYMENT_DECLINED');

    const part = await ctx.api.post(`${API}/loans/${loan.id}/repayments`).set(auth).send({ amount: 2000, upiId: 'asha@okaxis' }).expect(200);
    assert.equal(part.body.loan.outstanding, 40000);
    assert.equal(part.body.user.creditScore, 655);

    const full = await ctx.api.post(`${API}/loans/${loan.id}/repayments`).set(auth).send({ amount: 40000, upiId: 'asha@okaxis' }).expect(200);
    assert.equal(full.body.loan.status, 'CLOSED');
    assert.equal(full.body.user.creditScore, 685);
  });

  it('rejects an applicant with a poor (sandbox) bureau record', async () => {
    const auth = await borrower('9876520002', { pan: 'DDDPC9444D' });
    const applied = await ctx.api.post(`${API}/loans`).set(auth).send({ principal: 10000, tenureDays: 20, purpose: 'Travel' }).expect(201);
    const res = await ctx.api.get(`${API}/loans/${applied.body.loan.id}`).set(auth).expect(200);
    assert.equal(res.body.loan.status, 'REJECTED');
    assert.match(res.body.loan.rejectionReasons[0], /bureau/);
  });

  it('allows only one active loan at a time and validates the amount', async () => {
    const auth = await borrower('9876520003', { pan: 'EEEPD5555E' });
    await ctx.api.post(`${API}/loans`).set(auth).send({ principal: 10000, tenureDays: 20, purpose: 'Travel' }).expect(201);

    const second = await ctx.api.post(`${API}/loans`).set(auth).send({ principal: 10000, tenureDays: 20, purpose: 'Travel' }).expect(422);
    assert.equal(second.body.error.code, 'NOT_ELIGIBLE');

    const tooBig = await ctx.api.post(`${API}/loans`).set(auth).send({ principal: 500000, tenureDays: 20, purpose: 'Travel' }).expect(400);
    assert.equal(tooBig.body.error.code, 'VALIDATION_ERROR');
  });

  it('does not expose other users\' loans', async () => {
    const owner = await borrower('9876520004', { pan: 'FFFPE6666F' });
    const applied = await ctx.api.post(`${API}/loans`).set(owner).send({ principal: 10000, tenureDays: 20, purpose: 'Travel' }).expect(201);
    const { token } = await signUp(ctx.api, '9876520005');
    await ctx.api.get(`${API}/loans/${applied.body.loan.id}`).set(bearer(token)).expect(404);
  });
});

describe('Admin API', () => {
  it('requires the admin key and enforces valid transitions', async () => {
    const auth = await borrower('9876530001', { pan: 'GGGPF7777G' });
    const applied = await ctx.api.post(`${API}/loans`).set(auth).send({ principal: 10000, tenureDays: 20, purpose: 'Travel' }).expect(201);
    const id = applied.body.loan.id;

    await ctx.api.get(`${API}/admin/loans`).expect(401);
    const list = await ctx.api.get(`${API}/admin/loans`).set('x-admin-key', 'test-admin-key').expect(200);
    assert.ok(list.body.loans.some((l) => l.id === id));

    const invalid = await ctx.api
      .patch(`${API}/admin/loans/${id}/status`)
      .set('x-admin-key', 'test-admin-key')
      .send({ status: 'CLOSED' })
      .expect(409);
    assert.equal(invalid.body.error.code, 'INVALID_TRANSITION');

    const rejected = await ctx.api
      .patch(`${API}/admin/loans/${id}/status`)
      .set('x-admin-key', 'test-admin-key')
      .send({ status: 'REJECTED', note: 'Documents could not be verified.' })
      .expect(200);
    assert.equal(rejected.body.loan.status, 'REJECTED');
    assert.deepEqual(rejected.body.loan.rejectionReasons, ['Documents could not be verified.']);
  });
});
