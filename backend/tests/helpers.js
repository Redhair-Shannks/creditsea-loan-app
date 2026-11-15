// Test environment. Set before the app is imported, because config is read at import time.
Object.assign(process.env, {
  NODE_ENV: 'test',
  JWT_SECRET: 'test-secret-test-secret',
  ADMIN_API_KEY: 'test-admin-key',
  OTP_DEV_MODE: 'true',
  OTP_RESEND_SECONDS: '0',
  LOAN_REVIEW_DELAY_SECONDS: '0',
  LOAN_DECISION_DELAY_SECONDS: '0',
  LOAN_DISBURSAL_DELAY_SECONDS: '0',
  LIFECYCLE_SWEEP_SECONDS: '0',
});

import { MongoMemoryServer } from 'mongodb-memory-server';
import request from 'supertest';

export const API = '/api/v1';

/** Starts an in-memory MongoDB and returns a supertest client for a fresh app. */
export async function startTestServer() {
  const mongo = await MongoMemoryServer.create();
  const { connectDatabase, disconnectDatabase } = await import('../src/db/connect.js');
  const { createApp } = await import('../src/app.js');
  await connectDatabase(mongo.getUri('creditsea-test'));

  const app = createApp();
  return {
    api: request(app),
    stop: async () => {
      await disconnectDatabase();
      await mongo.stop();
    },
  };
}

export const bearer = (token) => ({ Authorization: `Bearer ${token}` });

/** Signs up a new user through the OTP flow and returns { token, user }. */
export async function signUp(api, phone) {
  const sent = await api.post(`${API}/auth/otp/send`).send({ phone }).expect(200);
  const verified = await api.post(`${API}/auth/otp/verify`).send({ phone, otp: sent.body.devOtp }).expect(201);
  return { token: verified.body.token, user: verified.body.user };
}

/** Walks through every onboarding step and returns the final user. */
export async function completeOnboarding(api, token, {
  email = `user${Date.now()}${Math.floor(Math.random() * 1000)}@example.com`,
  pan = 'ABCPE1234F',
  dob = '1995-04-12',
  employmentType = 'SALARIED',
  monthlyIncome = 60000,
} = {}) {
  const auth = bearer(token);
  await api.post(`${API}/auth/password`).set(auth).send({ password: 'Secret@123' }).expect(200);
  await api
    .put(`${API}/users/me/personal`)
    .set(auth)
    .send({ firstName: 'Asha', lastName: 'Verma', gender: 'FEMALE', dob, maritalStatus: 'SINGLE' })
    .expect(200);
  const sent = await api.post(`${API}/users/me/email/send-otp`).set(auth).send({ email }).expect(200);
  await api.post(`${API}/users/me/email/verify`).set(auth).send({ email, otp: sent.body.devOtp }).expect(200);
  await api.post(`${API}/users/me/pan/verify`).set(auth).send({ pan }).expect(200);
  const done = await api.put(`${API}/users/me/employment`).set(auth).send({ employmentType, monthlyIncome }).expect(200);
  return done.body.user;
}
