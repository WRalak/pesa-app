import { createRouter, } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as auth from './service.js';
import { requireAuth } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';
import { config } from '../../config/env.js';
import { readOutbox } from '../messaging/service.js';
import { Errors } from '../../lib/errors.js';

const phone = z.string().min(9).max(20).openapi({ example: '0712345678' });
const otpCode = z.string().regex(/^\d{6}$/, 'Code must be 6 digits');
const password = z.string().min(8).max(128);
const pin = z.string().regex(/^\d{4,6}$/);
const device = z.object({
  deviceId: z.string().min(8).max(128),
  name: z.string().max(80).optional(),
  platform: z.enum(['android', 'ios', 'web', 'unknown']).default('unknown'),
  model: z.string().max(80).optional(),
  osVersion: z.string().max(40).optional(),
  appVersion: z.string().max(32).optional(),
});

const ipLimit = (name, points, duration) => rateLimit({ name, points, duration });
const phoneLimit = (name, points, duration) => rateLimit({ name, points, duration, keyFn: (req) => String(req.body?.phone ?? '').replace(/\D/g, '').slice(-9) });

const r = createRouter({ prefix: '/v1/auth', tags: ['Auth'] });

r.route({
  method: 'post', path: '/register', summary: 'Register with phone number', status: 202,
  middleware: [ipLimit('register-ip', 10, 3600)],
  body: z.object({
    phone, password,
    email: z.string().email().max(254).optional(),
    firstName: z.string().trim().min(1).max(60),
    lastName: z.string().trim().min(1).max(60),
    referralCode: z.string().trim().max(16).optional(),
    country: z.string().length(2).optional(),
    locale: z.enum(['en-KE', 'sw-KE']).optional(),
    acceptTerms: z.literal(true),
    marketingConsent: z.boolean().optional(),
  }),
  handler: (req) => auth.register(req.body, req),
});

r.route({
  method: 'post', path: '/verify-phone', summary: 'Verify phone OTP and sign in',
  middleware: [ipLimit('verify-ip', 30, 600), phoneLimit('verify-phone', 10, 600)],
  body: z.object({ phone, code: otpCode, device }),
  handler: (req) => auth.verifyPhone(req.body, req),
});

r.route({
  method: 'post', path: '/resend-otp', summary: 'Resend a verification code', status: 202,
  middleware: [ipLimit('resend-ip', 20, 3600)],
  body: z.object({ phone, purpose: z.enum(['PHONE_VERIFY', 'DEVICE_VERIFY']) }),
  handler: (req) => auth.resendOtp(req.body),
});

r.route({
  method: 'post', path: '/login', summary: 'Sign in with phone and password',
  description: 'Returns tokens for trusted devices, or a `next` step (VERIFY_DEVICE / VERIFY_PHONE) requiring an OTP.',
  middleware: [ipLimit('login-ip', 30, 900), phoneLimit('login-phone', 10, 900)],
  body: z.object({ phone, password: z.string().min(1).max(128), device }),
  handler: (req) => auth.login(req.body, req),
});

r.route({
  method: 'post', path: '/verify-device', summary: 'Complete sign-in on a new device',
  middleware: [ipLimit('verify-device-ip', 30, 600)],
  body: z.object({ challengeId: z.string().min(10).max(100), code: otpCode }),
  handler: (req) => auth.verifyDevice(req.body, req),
});

r.route({
  method: 'post', path: '/refresh', summary: 'Rotate refresh token',
  middleware: [ipLimit('refresh-ip', 60, 60)],
  body: z.object({ refreshToken: z.string().min(20).max(200), deviceId: z.string().max(128).optional() }),
  handler: (req) => auth.refresh(req.body, req),
});

r.route({
  method: 'post', path: '/logout', summary: 'Sign out of the current session', auth: 'bearerAuth',
  middleware: [requireAuth],
  handler: async (req) => { await auth.logout(req.user.sessionId); },
});

r.route({
  method: 'post', path: '/logout-all', summary: 'Sign out of all sessions', auth: 'bearerAuth',
  middleware: [requireAuth],
  handler: (req) => auth.logoutAll(req.user.id, req),
});

r.route({
  method: 'post', path: '/password/forgot', summary: 'Request a password reset code', status: 202,
  middleware: [ipLimit('forgot-ip', 10, 3600)],
  body: z.object({ phone }),
  handler: (req) => auth.forgotPassword(req.body),
});

r.route({
  method: 'post', path: '/password/reset', summary: 'Reset password with OTP',
  middleware: [ipLimit('reset-ip', 20, 3600), phoneLimit('reset-phone', 10, 3600)],
  body: z.object({ phone, code: otpCode, newPassword: password }),
  handler: (req) => auth.resetPassword(req.body, req),
});

r.route({
  method: 'post', path: '/password/change', summary: 'Change password', auth: 'bearerAuth',
  middleware: [requireAuth],
  body: z.object({ currentPassword: z.string().min(1).max(128), newPassword: password }),
  handler: (req) => auth.changePassword(req.user.id, req.user.sessionId, req.body, req),
});

r.route({
  method: 'post', path: '/pin', summary: 'Create transaction PIN', auth: 'bearerAuth', status: 201,
  middleware: [requireAuth],
  body: z.object({ pin }),
  handler: (req) => auth.setPin(req.user.id, req.body, req),
});

r.route({
  method: 'post', path: '/pin/verify', summary: 'Verify transaction PIN', auth: 'bearerAuth',
  middleware: [requireAuth, rateLimit({ name: 'pin-verify', points: 10, duration: 300, keyFn: (req) => req.user.id })],
  body: z.object({ pin }),
  handler: async (req) => ({ valid: await auth.verifyPin(req.user.id, req.body.pin, req) }),
});

r.route({
  method: 'post', path: '/pin/change', summary: 'Change transaction PIN', auth: 'bearerAuth',
  middleware: [requireAuth],
  body: z.object({ currentPin: pin, newPin: pin }),
  handler: (req) => auth.changePin(req.user.id, req.body, req),
});

r.route({
  method: 'post', path: '/pin/reset/request', summary: 'Request PIN reset code', auth: 'bearerAuth', status: 202,
  middleware: [requireAuth],
  handler: (req) => auth.requestPinReset(req.user.id),
});

r.route({
  method: 'post', path: '/pin/reset', summary: 'Reset PIN with OTP and password', auth: 'bearerAuth',
  middleware: [requireAuth],
  body: z.object({ code: otpCode, password: z.string().min(1).max(128), newPin: pin }),
  handler: (req) => auth.resetPin(req.user.id, req.body, req),
});

r.route({
  method: 'post', path: '/email/request', summary: 'Send email verification code', auth: 'bearerAuth', status: 202,
  middleware: [requireAuth],
  body: z.object({ email: z.string().email().max(254) }),
  handler: (req) => auth.requestEmailVerification(req.user.id, req.body),
});

r.route({
  method: 'post', path: '/email/verify', summary: 'Verify email code', auth: 'bearerAuth',
  middleware: [requireAuth],
  body: z.object({ code: otpCode }),
  handler: (req) => auth.verifyEmail(req.user.id, req.body),
});

r.route({
  method: 'post', path: '/recovery/start', summary: 'Start account recovery via verified email', status: 202,
  middleware: [ipLimit('recovery-ip', 5, 3600)],
  body: z.object({ email: z.string().email().max(254) }),
  handler: (req) => auth.startRecovery(req.body),
});

r.route({
  method: 'post', path: '/recovery/complete', summary: 'Submit a recovery case for manual review', status: 202,
  middleware: [ipLimit('recovery-complete-ip', 10, 3600)],
  body: z.object({ email: z.string().email().max(254), code: otpCode, newPhone: phone, details: z.string().max(1000).optional() }),
  handler: (req) => auth.completeRecovery(req.body, req),
});

if (config.DEV_OTP_OUTBOX && !config.isDeployed) {
  r.route({
    method: 'get', path: '/dev/outbox', summary: '[DEVELOPMENT ONLY] Read messages sent by the console SMS/email provider',
    query: z.object({ to: z.string().optional() }),
    handler: (req) => {
      if (config.isDeployed) throw Errors.notFound();
      return { environment: config.NODE_ENV, warning: 'Development outbox — never enabled in staging/production', messages: readOutbox(req.valid.query.to) };
    },
  });
}

export default r.router;
