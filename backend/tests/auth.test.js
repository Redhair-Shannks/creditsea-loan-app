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

describe('OTP authentication', () => {
  it('rejects an invalid mobile number', async () => {
    const res = await ctx.api.post(`${API}/auth/otp/send`).send({ phone: '12345' }).expect(400);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    assert.match(res.body.error.message, /10-digit/);
  });

  it('sends a 4-digit OTP and creates the account on verification', async () => {
    const sent = await ctx.api.post(`${API}/auth/otp/send`).send({ phone: '9876500001' }).expect(200);
    assert.equal(sent.body.length, 4);
    assert.match(sent.body.devOtp, /^\d{4}$/);

    const verified = await ctx.api
      .post(`${API}/auth/otp/verify`)
      .send({ phone: '9876500001', otp: sent.body.devOtp })
      .expect(201);
    assert.ok(verified.body.token);
    assert.equal(verified.body.isNewUser, true);
    assert.equal(verified.body.user.onboardingStep, 'PASSWORD');
  });

  it('counts wrong attempts and burns the code after use', async () => {
    const phone = '9876500002';
    const sent = await ctx.api.post(`${API}/auth/otp/send`).send({ phone }).expect(200);
    const wrong = sent.body.devOtp === '0000' ? '1111' : '0000';

    const bad = await ctx.api.post(`${API}/auth/otp/verify`).send({ phone, otp: wrong }).expect(400);
    assert.equal(bad.body.error.code, 'OTP_INVALID');
    assert.equal(bad.body.error.details.remainingAttempts, 4);

    await ctx.api.post(`${API}/auth/otp/verify`).send({ phone, otp: sent.body.devOtp }).expect(201);
    const reused = await ctx.api.post(`${API}/auth/otp/verify`).send({ phone, otp: sent.body.devOtp }).expect(400);
    assert.equal(reused.body.error.code, 'OTP_EXPIRED');
  });

  it('signs an existing user back in with OTP (not a new account)', async () => {
    const phone = '9876500003';
    await signUp(ctx.api, phone);
    const sent = await ctx.api.post(`${API}/auth/otp/send`).send({ phone }).expect(200);
    const again = await ctx.api.post(`${API}/auth/otp/verify`).send({ phone, otp: sent.body.devOtp }).expect(200);
    assert.equal(again.body.isNewUser, false);
  });
});

describe('Password sign-in and sessions', () => {
  it('enforces the password rule from the design (8+ chars, 1 special)', async () => {
    const { token } = await signUp(ctx.api, '9876500010');
    const res = await ctx.api.post(`${API}/auth/password`).set(bearer(token)).send({ password: 'password1' }).expect(400);
    assert.match(res.body.error.message, /special character/);
  });

  it('signs in with mobile number + password', async () => {
    const phone = '9876500011';
    const { token } = await signUp(ctx.api, phone);
    await ctx.api.post(`${API}/auth/password`).set(bearer(token)).send({ password: 'Secret@123' }).expect(200);

    const ok = await ctx.api.post(`${API}/auth/login`).send({ phone, password: 'Secret@123' }).expect(200);
    assert.ok(ok.body.token);
    assert.equal(ok.body.user.hasPassword, true);

    const bad = await ctx.api.post(`${API}/auth/login`).send({ phone, password: 'Wrong@123' }).expect(401);
    assert.equal(bad.body.error.code, 'INVALID_CREDENTIALS');
  });

  it('only lets a recent OTP session replace an existing password', async () => {
    const phone = '9876500012';
    const { token } = await signUp(ctx.api, phone);
    await ctx.api.post(`${API}/auth/password`).set(bearer(token)).send({ password: 'Secret@123' }).expect(200);

    const login = await ctx.api.post(`${API}/auth/login`).send({ phone, password: 'Secret@123' }).expect(200);
    const denied = await ctx.api
      .post(`${API}/auth/password`)
      .set(bearer(login.body.token))
      .send({ password: 'Changed@123' })
      .expect(403);
    assert.equal(denied.body.error.code, 'OTP_REQUIRED');

    // "Forgot password": verify OTP again, then reset.
    const sent = await ctx.api.post(`${API}/auth/otp/send`).send({ phone }).expect(200);
    const otpLogin = await ctx.api.post(`${API}/auth/otp/verify`).send({ phone, otp: sent.body.devOtp }).expect(200);
    await ctx.api.post(`${API}/auth/password`).set(bearer(otpLogin.body.token)).send({ password: 'Changed@123' }).expect(200);
    await ctx.api.post(`${API}/auth/login`).send({ phone, password: 'Changed@123' }).expect(200);
  });

  it('refreshes the token and revokes it on logout', async () => {
    const { token } = await signUp(ctx.api, '9876500013');
    const refreshed = await ctx.api.post(`${API}/auth/refresh`).set(bearer(token)).expect(200);
    assert.ok(refreshed.body.token);

    await ctx.api.post(`${API}/auth/logout`).set(bearer(refreshed.body.token)).expect(204);
    const after = await ctx.api.get(`${API}/users/me`).set(bearer(token)).expect(401);
    assert.equal(after.body.error.code, 'SESSION_EXPIRED');
  });

  it('rejects requests without a token', async () => {
    await ctx.api.get(`${API}/users/me`).expect(401);
  });
});

describe('Profile onboarding', () => {
  it('walks PASSWORD -> PERSONAL -> EMAIL -> PAN -> EMPLOYMENT -> COMPLETE', async () => {
    const { token } = await signUp(ctx.api, '9876500020');
    const user = await completeOnboarding(ctx.api, token, { email: 'asha@example.com', pan: 'AAAPV1111A' });
    assert.equal(user.onboardingStep, 'COMPLETE');
    assert.equal(user.fullName, 'Asha Verma');
    assert.equal(user.panMasked, 'AA******1A');
    assert.equal(user.emailVerified, true);
    assert.equal(user.creditScore, 650);
  });

  it('validates PAN format and blocks a PAN used by another account', async () => {
    const { token } = await signUp(ctx.api, '9876500021');
    const auth = bearer(token);

    const business = await ctx.api.post(`${API}/users/me/pan/verify`).set(auth).send({ pan: 'ABCDE1234F' }).expect(400);
    assert.match(business.body.error.message, /personal PAN/);

    const taken = await ctx.api.post(`${API}/users/me/pan/verify`).set(auth).send({ pan: 'AAAPV1111A' }).expect(409);
    assert.equal(taken.body.error.code, 'PAN_IN_USE');
  });

  it('rejects applicants under 18 and impossible dates', async () => {
    const { token } = await signUp(ctx.api, '9876500022');
    const auth = bearer(token);
    const base = { firstName: 'Ravi', lastName: 'Kumar', gender: 'MALE', maritalStatus: 'SINGLE' };

    const minor = await ctx.api.put(`${API}/users/me/personal`).set(auth).send({ ...base, dob: '2015-01-01' }).expect(400);
    assert.match(minor.body.error.message, /18/);
    await ctx.api.put(`${API}/users/me/personal`).set(auth).send({ ...base, dob: '1990-02-30' }).expect(400);
  });
});
