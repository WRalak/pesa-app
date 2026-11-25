import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';
import { Errors } from '../lib/errors.js';
import { Session } from '../modules/auth/models.js';
import { User } from '../modules/users/models.js';
import { getRedis } from '../lib/redis.js';

const REVOKED_PREFIX = 'revoked-sid:';

/**
 * Verifies the short-lived access token. Session revocation is enforced
 * immediately via a Redis deny-list (populated on logout/revoke) so we do
 * not have to wait for token expiry, without hitting MongoDB on every call.
 */
export async function requireAuth(req, _res, next) {
  const header = req.get('authorization') ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(Errors.unauthorized());
  let payload;
  try {
    payload = jwt.verify(token, config.JWT_ACCESS_SECRET, { issuer: config.JWT_ISSUER, audience: 'pesa-app', algorithms: ['HS256'] });
  } catch (err) {
    return next(Errors.unauthorized(err.name === 'TokenExpiredError' ? 'Access token expired' : 'Invalid access token', err.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'UNAUTHORIZED'));
  }
  if (await getRedis().exists(REVOKED_PREFIX + payload.sid)) return next(Errors.unauthorized('Session has been revoked', 'SESSION_REVOKED'));
  req.user = { id: payload.sub, sessionId: payload.sid, deviceId: payload.did, country: payload.cty };
  next();
}

/** Loads the user document and enforces account status. */
export async function loadActiveUser(req, _res, next) {
  const user = await User.findById(req.user.id);
  if (!user) return next(Errors.unauthorized());
  if (user.status === 'SUSPENDED') return next(Errors.forbidden('Your account is suspended. Please contact support.'));
  if (user.status === 'CLOSED') return next(Errors.unauthorized('Account closed'));
  req.userDoc = user;
  next();
}

/** Blocks money movement for restricted accounts. */
export function requireTransactable(req, _res, next) {
  const u = req.userDoc;
  if (!u) return next(Errors.unauthorized());
  if (u.status !== 'ACTIVE') return next(Errors.forbidden('Verify your phone number to continue'));
  if (u.restrictions?.includes('NO_PAYMENTS')) return next(Errors.forbidden('Payments are restricted on this account. Please contact support.'));
  next();
}

export async function markSessionRevoked(sessionId) {
  await getRedis().set(REVOKED_PREFIX + sessionId, '1', 'EX', config.ACCESS_TOKEN_TTL_SECONDS + 60);
}

export async function revokeSessions(filter, reason) {
  const sessions = await Session.find({ ...filter, revokedAt: null }, { _id: 1 }).lean();
  if (!sessions.length) return 0;
  await Session.updateMany({ _id: { $in: sessions.map((s) => s._id) } }, { $set: { revokedAt: new Date(), revokedReason: reason } });
  await Promise.all(sessions.map((s) => markSessionRevoked(String(s._id))));
  return sessions.length;
}
