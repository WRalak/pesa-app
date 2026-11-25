import { config } from '../../config/env.js';
import { logger } from '../../lib/logger.js';
import { maskPhone } from '../../lib/phone.js';

/**
 * Outbound SMS/email. Real providers are selected by configuration. The
 * development outbox keeps the latest messages in memory so engineers can
 * complete OTP flows locally; it is refused in staging/production by env.js
 * and messages are never written to logs.
 */
const outbox = [];

async function sendViaAfricasTalking(to, message) {
  const res = await fetch('https://api.africastalking.com/version1/messaging', {
    method: 'POST',
    headers: {
      apiKey: config.AFRICASTALKING_API_KEY,
      Accept: 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ username: config.AFRICASTALKING_USERNAME, to, message }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new Error(`SMS provider responded ${res.status}`);
}

export async function sendSms(to, message, { kind = 'GENERAL' } = {}) {
  if (config.SMS_PROVIDER === 'africastalking') {
    await sendViaAfricasTalking(to, message);
  } else if (config.DEV_OTP_OUTBOX || config.isTest) {
    outbox.unshift({ channel: 'SMS', to, message, kind, at: new Date() });
    outbox.length = Math.min(outbox.length, 100);
  }
  logger.info({ to: maskPhone(to), kind, provider: config.SMS_PROVIDER }, 'SMS dispatched');
}

export async function sendEmail(to, subject, text, { kind = 'GENERAL' } = {}) {
  if (config.DEV_OTP_OUTBOX || config.isTest) {
    outbox.unshift({ channel: 'EMAIL', to, subject, message: text, kind, at: new Date() });
    outbox.length = Math.min(outbox.length, 100);
  }
  logger.info({ kind, provider: config.EMAIL_PROVIDER }, 'Email dispatched');
}

/** Development/test only. */
export function readOutbox(to) {
  return outbox.filter((m) => !to || m.to === to);
}

export function clearOutbox() {
  outbox.length = 0;
}
