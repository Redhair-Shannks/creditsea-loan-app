import { env } from '../config/env.js';
import { ApiError } from '../utils/ApiError.js';
import { logger } from '../utils/logger.js';

/**
 * Sends an SMS through Twilio when it is configured. Otherwise the message is only
 * logged (dev/demo mode) and the OTP is returned to the app by the auth endpoint.
 */
export async function sendSms(phone, body) {
  if (!env.smsProviderConfigured) {
    logger.info(`[sms:dev] +91${phone}: ${body}`);
    return { delivered: false };
  }

  const auth = Buffer.from(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`).toString('base64');
  const response = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${env.TWILIO_ACCOUNT_SID}/Messages.json`, {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ To: `+91${phone}`, From: env.TWILIO_FROM_NUMBER, Body: body }),
  });

  if (!response.ok) {
    logger.error('Twilio SMS failed', response.status, await response.text());
    throw new ApiError(502, 'SMS_FAILED', 'We could not send the SMS. Please try again.');
  }
  return { delivered: true };
}

/** Sends an email through Resend when configured; logs it otherwise. */
export async function sendEmail(to, subject, text) {
  if (!env.emailProviderConfigured) {
    logger.info(`[email:dev] ${to} | ${subject} | ${text}`);
    return { delivered: false };
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: env.EMAIL_FROM, to, subject, text }),
  });

  if (!response.ok) {
    logger.error('Resend email failed', response.status, await response.text());
    throw new ApiError(502, 'EMAIL_FAILED', 'We could not send the email. Please try again.');
  }
  return { delivered: true };
}
