import { createRouter, idParams, amountString } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as users from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { toMinor } from '../../lib/money.js';
import { rateLimit } from '../../middleware/rate-limit.js';

const r = createRouter({ prefix: '/v1/me', tags: ['Profile'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];
const contentType = z.enum(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']);

r.route({ method: 'get', path: '/', summary: 'Current user and profile', middleware: authed, handler: (req) => users.getMe(req.user.id) });

r.route({
  method: 'patch', path: '/profile', summary: 'Update profile', middleware: authed,
  body: z.object({
    firstName: z.string().trim().min(1).max(60).optional(),
    lastName: z.string().trim().min(1).max(60).optional(),
    dateOfBirth: z.coerce.date().max(new Date()).optional(),
    occupation: z.string().trim().max(80).optional(),
    address: z.object({ line1: z.string().max(120).optional(), city: z.string().max(60).optional(), region: z.string().max(60).optional() }).strict().optional(),
  }),
  handler: async (req) => ({ profile: await users.updateProfile(req.user.id, req.body) }),
});

r.route({
  method: 'patch', path: '/notification-preferences', summary: 'Update notification preferences', middleware: authed,
  body: z.object({
    push: z.boolean().optional(), email: z.boolean().optional(), sms: z.boolean().optional(),
    transactions: z.boolean().optional(), savings: z.boolean().optional(), budgets: z.boolean().optional(), promotions: z.boolean().optional(),
  }),
  handler: async (req) => ({ notificationPreferences: await users.updatePreferences(req.user.id, req.body) }),
});

r.route({
  method: 'patch', path: '/privacy', summary: 'Update privacy settings and consents', middleware: authed,
  body: z.object({
    hideBalances: z.boolean().optional(), analyticsOptIn: z.boolean().optional(), marketing: z.boolean().optional(),
    aiInsights: z.boolean().optional(), externalAiProcessing: z.boolean().optional(),
  }),
  handler: (req) => users.updatePrivacy(req.user.id, req.body),
});

r.route({
  method: 'post', path: '/avatar/upload-url', summary: 'Get presigned avatar upload URL', middleware: authed,
  body: z.object({ contentType }),
  handler: (req) => users.avatarUploadUrl(req.user.id, req.body.contentType),
});
r.route({
  method: 'put', path: '/avatar', summary: 'Confirm uploaded avatar', middleware: authed,
  body: z.object({ key: z.string().max(200) }),
  handler: (req) => users.confirmAvatar(req.user.id, req.body.key),
});
r.route({ method: 'get', path: '/avatar', summary: 'Get avatar URL', middleware: authed, handler: (req) => users.avatarUrl(req.user.id) });

r.route({ method: 'get', path: '/devices', summary: 'Trusted devices', middleware: authed, handler: async (req) => ({ items: await users.listDevices(req.user.id, req.user.deviceId) }) });
r.route({ method: 'delete', path: '/devices/:id', summary: 'Revoke a device', params: idParams, middleware: authed, handler: (req) => users.revokeDevice(req.user.id, req.valid.params.id, req) });
r.route({
  method: 'patch', path: '/devices/current', summary: 'Update current device (push token, biometrics)', middleware: authed,
  body: z.object({ pushToken: z.string().max(4096).nullable().optional(), biometricEnabled: z.boolean().optional() }),
  handler: (req) => users.updateCurrentDevice(req.user.id, req.user.deviceId, req.body),
});

r.route({ method: 'get', path: '/sessions', summary: 'Active sessions', middleware: authed, handler: async (req) => ({ items: await users.listSessions(req.user.id, req.user.sessionId) }) });
r.route({ method: 'delete', path: '/sessions/:id', summary: 'Revoke a session', params: idParams, middleware: authed, handler: (req) => users.revokeSession(req.user.id, req.valid.params.id, req) });

r.route({ method: 'get', path: '/limits', summary: 'Transaction limits', middleware: authed, handler: (req) => users.getLimits(req.user.id) });
r.route({
  method: 'put', path: '/limits', summary: 'Set personal transaction limits (cannot exceed regulatory limits)', middleware: authed,
  body: z.object({ perTransaction: amountString.nullable().optional(), daily: amountString.nullable().optional() }),
  handler: (req) => users.setLimits(req.user.id, {
    perTransactionMinor: req.body.perTransaction ? toMinor(req.body.perTransaction, req.userDoc.currency) : null,
    dailyMinor: req.body.daily ? toMinor(req.body.daily, req.userDoc.currency) : null,
  }),
});

r.route({ method: 'get', path: '/kyc', summary: 'KYC status', middleware: authed, handler: (req) => users.kycStatus(req.user.id) });
r.route({
  method: 'post', path: '/kyc/upload-url', summary: 'Presigned URL for an ID document', middleware: authed,
  body: z.object({ contentType }),
  handler: (req) => users.kycUploadUrl(req.user.id, req.body.contentType),
});
r.route({
  method: 'post', path: '/kyc', summary: 'Submit identity verification', status: 202,
  middleware: [...authed, rateLimit({ name: 'kyc-submit', points: 5, duration: 86_400, keyFn: (req) => req.user.id })],
  body: z.object({
    idType: z.string().max(20),
    idNumber: z.string().trim().regex(/^[A-Za-z0-9]{5,20}$/),
    fullName: z.string().trim().min(3).max(120),
    dateOfBirth: z.coerce.date().max(new Date()),
    documentKeys: z.array(z.string().max(200)).max(5).optional(),
  }),
  handler: (req) => users.submitKyc(req.user.id, req.body, req),
});

r.route({ method: 'get', path: '/export', summary: 'Export my personal data', middleware: [...authed, rateLimit({ name: 'export', points: 3, duration: 86_400, keyFn: (req) => req.user.id })], handler: (req) => users.exportData(req.user.id) });
r.route({
  method: 'post', path: '/close', summary: 'Close account (data minimised; financial records retained per AML law)', middleware: authed,
  body: z.object({ password: z.string().min(1).max(128), reason: z.string().max(500).optional() }),
  handler: (req) => users.closeAccount(req.user.id, req.body, req),
});

export default r.router;
