import pino from 'pino';
import { config } from '../config/env.js';

/**
 * Structured JSON logger. Sensitive fields are redacted centrally so that
 * individual call sites cannot accidentally leak credentials, OTPs or PINs.
 */
export const REDACT_PATHS = [
  'password', '*.password', 'newPassword', '*.newPassword', 'currentPassword', '*.currentPassword',
  'pin', '*.pin', 'newPin', '*.newPin', 'otp', '*.otp', 'code', '*.code',
  'token', '*.token', 'accessToken', '*.accessToken', 'refreshToken', '*.refreshToken',
  'secret', '*.secret', 'totpSecret', '*.totpSecret', 'idNumber', '*.idNumber',
  'req.headers.authorization', 'req.headers.cookie', 'req.headers["x-callback-signature"]',
  'req.headers["x-api-key"]', 'res.headers["set-cookie"]',
  'cardNumber', '*.cardNumber', 'cvv', '*.cvv', 'Password', '*.Password',
];

/** Pretty logs only for interactive local runs where pino-pretty (a devDependency) is installed. */
function devTransport() {
  if (!config.isDev || !process.stdout.isTTY) return undefined;
  try {
    import.meta.resolve('pino-pretty');
    return { target: 'pino-pretty', options: { colorize: true } };
  } catch {
    return undefined;
  }
}

export const logger = pino({
  level: config.isTest ? 'silent' : config.LOG_LEVEL,
  base: { service: 'pesa-api', env: config.NODE_ENV },
  redact: { paths: REDACT_PATHS, censor: '[REDACTED]' },
  timestamp: pino.stdTimeFunctions.isoTime,
  formatters: { level: (label) => ({ level: label }) },
  transport: devTransport(),
});
