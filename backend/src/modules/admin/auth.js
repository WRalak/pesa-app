import { createRouter } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import { AdminUser, AdminSession } from './models.js';
import { requireAdmin, signAdminToken } from './rbac.js';
import { verifySecret, hashSecret, encryptField, decryptField, randomToken } from '../../lib/crypto.js';
import { generateTotpSecret, verifyTotp, totpUri } from '../../lib/totp.js';
import { Errors } from '../../lib/errors.js';
import { getRedis } from '../../lib/redis.js';
import { config } from '../../config/env.js';
import { audit, securityEvent } from '../audit/service.js';
import { rateLimit } from '../../middleware/rate-limit.js';
import { assertPasswordPolicy } from '../auth/service.js';

const MFA_TTL = 300;
let dummy;

async function startMfa(admin) {
  const mfaToken = randomToken(32);
  await getRedis().set(`admin-mfa:${mfaToken}`, String(admin._id), 'EX', MFA_TTL);
  return mfaToken;
}

async function consumeMfaToken(mfaToken, { peek = false } = {}) {
  const key = `admin-mfa:${mfaToken}`;
  const id = await getRedis().get(key);
  if (!id) throw Errors.unauthorized('Sign-in expired. Please start again.', 'MFA_EXPIRED');
  if (!peek) await getRedis().del(key);
  return id;
}

async function issueSession(admin, req) {
  const session = await AdminSession.create({ adminId: admin._id, ip: req.ip, userAgent: req.get('user-agent')?.slice(0, 300), expiresAt: new Date(Date.now() + config.ADMIN_TOKEN_TTL_SECONDS * 1000) });
  await AdminUser.updateOne({ _id: admin._id }, { $set: { lastLoginAt: new Date(), lastLoginIp: req.ip, failedLogins: 0 }, $unset: { lockedUntil: 1 } });
  await securityEvent({ adminId: admin._id, type: 'ADMIN_LOGIN', severity: 'LOW' }, req);
  await audit({ actorType: 'ADMIN', actorId: admin._id, action: 'admin.login', resourceType: 'AdminUser', resourceId: admin._id }, req);
  return { accessToken: signAdminToken(admin, session._id), expiresIn: config.ADMIN_TOKEN_TTL_SECONDS, mustChangePassword: admin.mustChangePassword };
}

/** Verifies a TOTP code once: the matched time step is stored so a code cannot be replayed. */
async function checkTotp(admin, code, req) {
  const secret = decryptField(admin.mfaSecretEnc);
  const step = verifyTotp(secret, code);
  if (step === null || (admin.mfaLastStep != null && step <= admin.mfaLastStep)) {
    await securityEvent({ adminId: admin._id, type: 'MFA_FAILED', severity: 'MEDIUM' }, req);
    throw Errors.unauthorized('Invalid authentication code', 'MFA_INVALID');
  }
  const r = await AdminUser.updateOne({ _id: admin._id, $or: [{ mfaLastStep: null }, { mfaLastStep: { $lt: step } }] }, { $set: { mfaLastStep: step } });
  if (!r.modifiedCount) throw Errors.unauthorized('Invalid authentication code', 'MFA_INVALID');
}

const r = createRouter({ prefix: '/admin/v1/auth', tags: ['Admin: Auth'] });
const loginLimit = rateLimit({ name: 'admin-login', points: 10, duration: 900 });

r.route({
  method: 'post', path: '/login', summary: 'Admin sign-in step 1 (password)', middleware: [loginLimit],
  body: z.object({ email: z.string().email().max(254), password: z.string().min(1).max(128) }),
  handler: async (req) => {
    const admin = await AdminUser.findOne({ email: req.body.email.toLowerCase() }).select('+passwordHash');
    if (!admin) {
      dummy ??= await hashSecret('timing-equaliser-admin-1');
      await verifySecret(dummy, req.body.password);
      throw Errors.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }
    if (admin.lockedUntil && admin.lockedUntil > new Date()) throw Errors.locked('Account locked. Try again later.');
    if (admin.status !== 'ACTIVE' || !(await verifySecret(admin.passwordHash, req.body.password))) {
      const u = await AdminUser.findOneAndUpdate({ _id: admin._id }, { $inc: { failedLogins: 1 } }, { returnDocument: 'after' });
      if (u.failedLogins >= 5) await AdminUser.updateOne({ _id: admin._id }, { $set: { lockedUntil: new Date(Date.now() + 30 * 60_000), failedLogins: 0 } });
      await securityEvent({ adminId: admin._id, type: 'ADMIN_LOGIN_FAILED', severity: u.failedLogins >= 5 ? 'HIGH' : 'MEDIUM' }, req);
      throw Errors.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }
    const mfaToken = await startMfa(admin);
    return { next: admin.mfaEnabled ? 'MFA_VERIFY' : 'MFA_ENROLL', mfaToken, expiresIn: MFA_TTL };
  },
});

r.route({
  method: 'post', path: '/mfa/setup', summary: 'Get a TOTP secret for first-time MFA enrollment', middleware: [loginLimit],
  body: z.object({ mfaToken: z.string().min(20).max(100) }),
  handler: async (req) => {
    const id = await consumeMfaToken(req.body.mfaToken, { peek: true });
    const admin = await AdminUser.findById(id);
    if (admin.mfaEnabled) throw Errors.conflict('MFA already enabled', 'MFA_ENABLED');
    const secret = generateTotpSecret();
    await AdminUser.updateOne({ _id: id }, { $set: { mfaSecretEnc: encryptField(secret) } });
    return { secret, otpauthUri: totpUri({ secret, account: admin.email, issuer: `${config.APP_NAME} Admin` }) };
  },
});

r.route({
  method: 'post', path: '/mfa/enroll', summary: 'Confirm MFA enrollment and sign in', middleware: [loginLimit],
  body: z.object({ mfaToken: z.string().min(20).max(100), code: z.string().regex(/^\d{6}$/) }),
  handler: async (req) => {
    const id = await consumeMfaToken(req.body.mfaToken, { peek: true });
    const admin = await AdminUser.findById(id).select('+mfaSecretEnc +mfaLastStep');
    if (admin.mfaEnabled || !admin.mfaSecretEnc) throw Errors.badRequest('Start MFA setup first');
    await checkTotp(admin, req.body.code, req);
    await consumeMfaToken(req.body.mfaToken);
    await AdminUser.updateOne({ _id: id }, { $set: { mfaEnabled: true } });
    await securityEvent({ adminId: admin._id, type: 'MFA_ENROLLED', severity: 'LOW' }, req);
    return issueSession(admin, req);
  },
});

r.route({
  method: 'post', path: '/mfa/verify', summary: 'Admin sign-in step 2 (TOTP)', middleware: [loginLimit],
  body: z.object({ mfaToken: z.string().min(20).max(100), code: z.string().regex(/^\d{6}$/) }),
  handler: async (req) => {
    const id = await consumeMfaToken(req.body.mfaToken, { peek: true });
    const admin = await AdminUser.findById(id).select('+mfaSecretEnc +mfaLastStep');
    if (!admin?.mfaEnabled) throw Errors.badRequest('MFA is not enrolled');
    await checkTotp(admin, req.body.code, req);
    await consumeMfaToken(req.body.mfaToken);
    return issueSession(admin, req);
  },
});

r.route({
  method: 'get', path: '/me', summary: 'Current admin and permissions', auth: 'adminAuth', middleware: [requireAdmin],
  handler: (req) => ({ id: req.admin.id, email: req.admin.email, name: req.admin.name, roles: req.admin.roles, permissions: req.admin.permissions, mustChangePassword: req.admin.mustChangePassword }),
});

r.route({
  method: 'post', path: '/logout', summary: 'Sign out', auth: 'adminAuth', middleware: [requireAdmin],
  handler: async (req) => {
    await AdminSession.updateOne({ _id: req.admin.sessionId }, { $set: { revokedAt: new Date() } });
    await getRedis().set(`admin-revoked:${req.admin.sessionId}`, '1', 'EX', config.ADMIN_TOKEN_TTL_SECONDS);
  },
});

r.route({
  method: 'post', path: '/password', summary: 'Change own password', auth: 'adminAuth', middleware: [requireAdmin],
  body: z.object({ currentPassword: z.string().min(1).max(128), newPassword: z.string().min(12).max(128) }),
  handler: async (req) => {
    const admin = await AdminUser.findById(req.admin.id).select('+passwordHash');
    if (!(await verifySecret(admin.passwordHash, req.body.currentPassword))) throw Errors.unprocessable('INVALID_PASSWORD', 'Current password is incorrect');
    assertPasswordPolicy(req.body.newPassword);
    await AdminUser.updateOne({ _id: admin._id }, { $set: { passwordHash: await hashSecret(req.body.newPassword), passwordChangedAt: new Date(), mustChangePassword: false } });
    await audit({ actorType: 'ADMIN', actorId: admin._id, action: 'admin.password.changed', resourceType: 'AdminUser', resourceId: admin._id }, req);
    return { status: 'PASSWORD_CHANGED' };
  },
});

export default r.router;
