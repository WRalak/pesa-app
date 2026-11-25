import { Otp } from './models.js';
import { hmac, randomDigits, timingSafeEqualStr } from '../../lib/crypto.js';
import { config } from '../../config/env.js';
import { Errors } from '../../lib/errors.js';
import { sendSms, sendEmail } from '../messaging/service.js';
import { consumeOrThrow } from '../../middleware/rate-limit.js';

const MESSAGES = {
  PHONE_VERIFY: (c) => `Your ${config.APP_NAME} verification code is ${c}. It expires in 5 minutes. Never share this code.`,
  EMAIL_VERIFY: (c) => `Your ${config.APP_NAME} email verification code is ${c}.`,
  DEVICE_VERIFY: (c) => `${c} is your ${config.APP_NAME} code to sign in on a new device. If this wasn't you, change your password now.`,
  PASSWORD_RESET: (c) => `${c} is your ${config.APP_NAME} password reset code. We will never call to ask for it.`,
  PIN_RESET: (c) => `${c} is your ${config.APP_NAME} PIN reset code. Do not share it with anyone.`,
  ACCOUNT_RECOVERY: (c) => `${c} is your ${config.APP_NAME} account recovery code.`,
  SENSITIVE_ACTION: (c) => `${c} is your ${config.APP_NAME} confirmation code.`,
};

/**
 * Issues a 6-digit OTP. Only an HMAC of the code is stored. Issuance is rate
 * limited per target (3/10min, 10/day) to prevent SMS pumping and enumeration.
 */
export async function issueOtp({ target, channel = 'SMS', purpose, userId }) {
  const targetHash = hmac(`${channel}:${target}`);
  await consumeOrThrow({ name: 'otp-issue-short', points: 3, duration: 600 }, targetHash);
  await consumeOrThrow({ name: 'otp-issue-day', points: 10, duration: 86_400 }, targetHash);

  // Invalidate any outstanding codes for the same purpose.
  await Otp.updateMany({ targetHash, purpose, consumedAt: null }, { $set: { consumedAt: new Date() } });
  const code = randomDigits(6);
  const expiresAt = new Date(Date.now() + config.OTP_TTL_SECONDS * 1000);
  await Otp.create({
    userId, targetHash, channel, purpose,
    codeHash: hmac(`${purpose}:${code}`, config.HASH_PEPPER + targetHash),
    maxAttempts: config.OTP_MAX_ATTEMPTS,
    expiresAt,
  });
  const text = MESSAGES[purpose](code);
  if (channel === 'SMS') await sendSms(target, text, { kind: `OTP_${purpose}` });
  else await sendEmail(target, `${config.APP_NAME} verification code`, text, { kind: `OTP_${purpose}` });
  return { expiresAt, channel };
}

/** Verifies and consumes an OTP. Attempts are bounded per code. */
export async function verifyOtp({ target, channel = 'SMS', purpose, code }) {
  const targetHash = hmac(`${channel}:${target}`);
  const otp = await Otp.findOne({ targetHash, purpose, consumedAt: null }).sort({ createdAt: -1 });
  if (!otp || otp.expiresAt < new Date()) throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  if (otp.attempts >= otp.maxAttempts) {
    otp.consumedAt = new Date();
    await otp.save();
    throw Errors.unprocessable('OTP_ATTEMPTS_EXCEEDED', 'Too many incorrect attempts. Request a new code.');
  }
  const expected = hmac(`${purpose}:${code}`, config.HASH_PEPPER + targetHash);
  if (!timingSafeEqualStr(expected, otp.codeHash)) {
    // Atomic increment avoids lost updates from parallel guesses.
    await Otp.updateOne({ _id: otp._id }, { $inc: { attempts: 1 } });
    throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  }
  const consumed = await Otp.findOneAndUpdate({ _id: otp._id, consumedAt: null }, { $set: { consumedAt: new Date() } });
  if (!consumed) throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  return true;
}
