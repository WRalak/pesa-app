import jwt from 'jsonwebtoken';
import { config } from '../../config/env.js';
import { Errors } from '../../lib/errors.js';
import { AdminUser, AdminSession, Role, Permission } from './models.js';
import { cached, getRedis } from '../../lib/redis.js';

export const PERMISSIONS = {
  'dashboard.read': ['Dashboard', 'View operational dashboard'],
  'users.read': ['Users', 'View users (PII masked)'],
  'users.pii.read': ['Users', 'View unmasked personal data and ID numbers'],
  'users.suspend': ['Users', 'Suspend and reactivate accounts'],
  'users.restrict': ['Users', 'Manage account restrictions'],
  'kyc.review': ['Users', 'Approve or reject KYC'],
  'transactions.read': ['Transactions', 'Search and view transactions'],
  'transactions.flag': ['Transactions', 'Flag transactions for investigation'],
  'transactions.reverse.request': ['Transactions', 'Request a reversal (maker)'],
  'transactions.reverse.approve': ['Transactions', 'Approve a reversal (checker)'],
  'callbacks.read': ['Transactions', 'View provider callbacks'],
  'reconciliation.read': ['Finance', 'View reconciliation results'],
  'reconciliation.run': ['Finance', 'Run reconciliation'],
  'reconciliation.resolve': ['Finance', 'Resolve reconciliation exceptions'],
  'finance.read': ['Finance', 'Revenue, fees and settlement reports'],
  'providers.manage': ['Finance', 'Configure payment providers and fees'],
  'campaigns.read': ['Marketing', 'View campaigns'],
  'campaigns.manage': ['Marketing', 'Create and manage reward campaigns'],
  'notifications.campaign': ['Marketing', 'Send notification campaigns'],
  'support.read': ['Support', 'View support tickets'],
  'support.manage': ['Support', 'Reply to and manage tickets'],
  'security.read': ['Security', 'View security events and login history'],
  'security.manage': ['Security', 'Revoke sessions and acknowledge alerts'],
  'audit.read': ['Security', 'View the admin audit log'],
  'admins.manage': ['Security', 'Manage administrators and roles'],
};

export const DEFAULT_ROLES = {
  SUPER_ADMIN: { name: 'Super Administrator', permissions: Object.keys(PERMISSIONS) },
  OPERATIONS_ADMIN: { name: 'Operations Administrator', permissions: ['dashboard.read', 'users.read', 'transactions.read', 'transactions.flag', 'callbacks.read', 'reconciliation.read', 'support.read', 'support.manage', 'providers.manage'] },
  FINANCE_ADMIN: { name: 'Finance Administrator', permissions: ['dashboard.read', 'transactions.read', 'transactions.reverse.request', 'transactions.reverse.approve', 'callbacks.read', 'reconciliation.read', 'reconciliation.run', 'reconciliation.resolve', 'finance.read', 'providers.manage'] },
  CUSTOMER_SUPPORT: { name: 'Customer Support', permissions: ['users.read', 'transactions.read', 'support.read', 'support.manage'] },
  COMPLIANCE_OFFICER: { name: 'Compliance Officer', permissions: ['dashboard.read', 'users.read', 'users.pii.read', 'users.suspend', 'users.restrict', 'kyc.review', 'transactions.read', 'transactions.flag', 'callbacks.read', 'security.read', 'audit.read', 'support.read'] },
  SECURITY_ADMIN: { name: 'Security Administrator', permissions: ['dashboard.read', 'users.read', 'users.suspend', 'security.read', 'security.manage', 'audit.read', 'admins.manage'] },
  MARKETING_ADMIN: { name: 'Marketing Administrator', permissions: ['dashboard.read', 'campaigns.read', 'campaigns.manage', 'notifications.campaign'] },
};

export async function syncRbac() {
  for (const [key, [group, description]] of Object.entries(PERMISSIONS)) {
    await Permission.updateOne({ key }, { $set: { group, description } }, { upsert: true });
  }
  for (const [key, r] of Object.entries(DEFAULT_ROLES)) {
    await Role.updateOne({ key }, { $set: { name: r.name, permissions: r.permissions, system: true } }, { upsert: true });
  }
}

export async function permissionsFor(roleKeys) {
  const key = `admin-perms:${[...roleKeys].sort().join(',')}`;
  return cached(key, 60, async () => {
    const roles = await Role.find({ key: { $in: roleKeys } }, { permissions: 1 }).lean();
    return [...new Set(roles.flatMap((r) => r.permissions))];
  });
}

export function signAdminToken(admin, sessionId) {
  return jwt.sign({ sid: String(sessionId), mfa: true }, config.JWT_ADMIN_SECRET, { subject: String(admin._id), issuer: config.JWT_ISSUER, audience: 'pesa-admin', expiresIn: config.ADMIN_TOKEN_TTL_SECONDS, algorithm: 'HS256' });
}

/** Verifies an MFA-backed admin token, live session and account status. */
export async function requireAdmin(req, _res, next) {
  const [scheme, token] = (req.get('authorization') ?? '').split(' ');
  if (scheme !== 'Bearer' || !token) return next(Errors.unauthorized());
  let payload;
  try {
    payload = jwt.verify(token, config.JWT_ADMIN_SECRET, { issuer: config.JWT_ISSUER, audience: 'pesa-admin', algorithms: ['HS256'] });
  } catch {
    return next(Errors.unauthorized('Session expired. Please sign in again.', 'TOKEN_EXPIRED'));
  }
  if (!payload.mfa) return next(Errors.unauthorized('MFA required', 'MFA_REQUIRED'));
  if (await getRedis().exists(`admin-revoked:${payload.sid}`)) return next(Errors.unauthorized('Session revoked', 'SESSION_REVOKED'));
  const [admin, session] = await Promise.all([
    AdminUser.findById(payload.sub).lean(),
    AdminSession.findById(payload.sid).lean(),
  ]);
  if (!admin || admin.status !== 'ACTIVE' || !session || session.revokedAt || session.expiresAt < new Date()) return next(Errors.unauthorized('Session revoked', 'SESSION_REVOKED'));
  req.admin = { id: String(admin._id), email: admin.email, name: admin.name, roles: admin.roles, sessionId: payload.sid, permissions: await permissionsFor(admin.roles) };
  next();
}

export const can = (req, perm) => req.admin?.permissions.includes(perm);

export function requirePermission(...perms) {
  return (req, _res, next) => {
    if (!perms.every((p) => can(req, p))) return next(Errors.forbidden());
    next();
  };
}
