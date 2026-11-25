import jwt from 'jsonwebtoken';
import { User, UserProfile } from '../users/models.js';
import { Device, Session } from './models.js';
import { issueOtp, verifyOtp } from './otp.service.js';
import { config } from '../../config/env.js';
import { getCountry } from '../../config/countries/index.js';
import { hashSecret, verifySecret, hmac, randomToken } from '../../lib/crypto.js';
import { Errors } from '../../lib/errors.js';
import { normalizePhone } from '../../lib/phone.js';
import { getRedis } from '../../lib/redis.js';
import { securityEvent, audit } from '../audit/service.js';
import { notify } from '../notifications/service.js';
import { revokeSessions, markSessionRevoked } from '../../middleware/auth.js';
import { sendSms } from '../messaging/service.js';
import { emitDomainEvent } from '../../lib/events.js';

const TERMS_VERSION = '2026-11';
const COMMON_PASSWORDS = new Set(['password1', 'password123', '12345678', 'qwerty123', 'iloveyou1', 'mpesa1234', 'kenya2024', 'admin1234', 'abc12345', 'letmein1']);
const TRIVIAL_PINS = new Set(['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '1234', '4321', '1212', '0123', '9876', '123456', '654321', '000000', '111111']);
let dummyHash;

// ---------------------------------------------------------------- policies
export function assertPasswordPolicy(password) {
  if (password.length < 8 || password.length > 128) throw Errors.validation([{ path: 'password', message: 'Password must be 8-128 characters' }]);
  if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) throw Errors.validation([{ path: 'password', message: 'Password must contain letters and numbers' }]);
  if (COMMON_PASSWORDS.has(password.toLowerCase())) throw Errors.validation([{ path: 'password', message: 'This password is too common' }]);
}

export function assertPinPolicy(pin) {
  if (!/^\d{4,6}$/.test(pin)) throw Errors.validation([{ path: 'pin', message: 'PIN must be 4 to 6 digits' }]);
  if (TRIVIAL_PINS.has(pin)) throw Errors.validation([{ path: 'pin', message: 'Choose a PIN that is harder to guess' }]);
}

async function generateReferralCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  for (let i = 0; i < 10; i++) {
    const bytes = randomToken(8);
    let code = '';
    for (let j = 0; j < 7; j++) code += alphabet[bytes.charCodeAt(j) % alphabet.length];
    if (!(await User.exists({ referralCode: code }))) return code;
  }
  throw new Error('Could not allocate referral code');
}

// ---------------------------------------------------------------- tokens
function signAccessToken(user, session, device) {
  return jwt.sign(
    { sid: String(session._id), did: device.deviceId, cty: user.country },
    config.JWT_ACCESS_SECRET,
    { subject: String(user._id), issuer: config.JWT_ISSUER, audience: 'pesa-app', expiresIn: config.ACCESS_TOKEN_TTL_SECONDS, algorithm: 'HS256' },
  );
}

async function createSession(user, device, req) {
  const refreshToken = randomToken(48);
  const session = await Session.create({
    userId: user._id,
    device: device._id,
    refreshTokenHash: hmac(refreshToken),
    ip: req.ip,
    userAgent: req.get('user-agent')?.slice(0, 300),
    lastUsedAt: new Date(),
    expiresAt: new Date(Date.now() + config.REFRESH_TOKEN_TTL_DAYS * 86_400_000),
  });
  return {
    accessToken: signAccessToken(user, session, device),
    refreshToken,
    tokenType: 'Bearer',
    expiresIn: config.ACCESS_TOKEN_TTL_SECONDS,
    sessionId: String(session._id),
  };
}

async function upsertDevice(userId, info, req, { trusted }) {
  const update = {
    $set: {
      name: info.name, platform: info.platform ?? 'unknown', model: info.model, osVersion: info.osVersion,
      appVersion: info.appVersion, lastSeenAt: new Date(), lastIp: req.ip,
    },
    $setOnInsert: { userId, deviceId: info.deviceId },
  };
  if (trusted) {
    update.$set.trusted = true;
    update.$set.trustedAt = new Date();
    update.$unset = { revokedAt: 1 };
  }
  return Device.findOneAndUpdate({ userId, deviceId: info.deviceId }, update, { upsert: true, new: true });
}

async function completeLogin(user, deviceInfo, req, { newDevice }) {
  const device = await upsertDevice(user._id, deviceInfo, req, { trusted: true });
  const viewerCountry = req.get('cloudfront-viewer-country') ?? req.get('cf-ipcountry');
  const suspicious = Boolean(viewerCountry && user.lastLoginCountry && viewerCountry !== user.lastLoginCountry);
  await User.updateOne({ _id: user._id }, {
    $set: { failedLoginAttempts: 0, lastLoginAt: new Date(), lastLoginIp: req.ip, ...(viewerCountry ? { lastLoginCountry: viewerCountry } : {}) },
    $unset: { lockedUntil: 1 },
  });
  const tokens = await createSession(user, device, req);
  await securityEvent({ userId: user._id, type: 'LOGIN_SUCCESS', deviceId: deviceInfo.deviceId }, req);
  if (newDevice || suspicious) {
    await securityEvent({
      userId: user._id,
      type: suspicious ? 'SUSPICIOUS_LOGIN' : 'NEW_DEVICE_LOGIN',
      severity: suspicious ? 'HIGH' : 'MEDIUM',
      deviceId: deviceInfo.deviceId,
      details: { device: deviceInfo.name ?? deviceInfo.model, country: viewerCountry },
    }, req);
    await notify(user._id, {
      category: 'SECURITY',
      type: 'NEW_DEVICE_LOGIN',
      title: 'New sign-in to your account',
      body: `Your account was accessed from ${deviceInfo.name ?? deviceInfo.model ?? 'a new device'}. If this wasn't you, reset your password immediately.`,
      data: { route: '/profile/security/devices' },
    });
  }
  return { user: user.toPublic(), tokens, device: { id: String(device._id), trusted: device.trusted, biometricEnabled: device.biometricEnabled } };
}

// ---------------------------------------------------------------- registration
export async function register(input, req) {
  const country = getCountry(input.country ?? config.DEFAULT_COUNTRY);
  const { e164, country: phoneCountry } = normalizePhone(input.phone, country.code);
  assertPasswordPolicy(input.password);
  if (!input.acceptTerms) throw Errors.validation([{ path: 'acceptTerms', message: 'You must accept the terms and privacy policy' }]);

  const existing = await User.findOne({ phone: e164 });
  if (existing && existing.status !== 'PENDING_VERIFICATION') {
    // Do not reveal registration status to the caller; inform the real owner by SMS.
    await sendSms(e164, `Someone tried to create a ${config.APP_NAME} account with your number. If this was you, sign in or reset your password instead.`, { kind: 'DUPLICATE_REGISTRATION' });
    return { status: 'OTP_SENT', phone: e164 };
  }

  const passwordHash = await hashSecret(input.password);
  let referredBy;
  if (input.referralCode) {
    const referrer = await User.findOne({ referralCode: input.referralCode.toUpperCase(), status: 'ACTIVE' }, { _id: 1 }).lean();
    referredBy = referrer?._id;
  }
  const email = input.email?.toLowerCase();
  if (email && (await User.exists({ email, _id: { $ne: existing?._id } }))) {
    throw Errors.conflict('This email address is already in use', 'EMAIL_TAKEN');
  }

  let user = existing;
  if (user) {
    user.passwordHash = passwordHash;
    if (email) user.email = email;
    if (referredBy && !user.referredBy) user.referredBy = referredBy;
    await user.save();
  } else {
    const now = new Date();
    user = await User.create({
      phone: e164,
      email,
      passwordHash,
      country: phoneCountry,
      currency: getCountry(phoneCountry).currency,
      locale: input.locale ?? getCountry(phoneCountry).defaultLocale,
      referralCode: await generateReferralCode(),
      referredBy,
      consents: {
        termsVersion: TERMS_VERSION, termsAcceptedAt: now, privacyAcceptedAt: now,
        marketing: Boolean(input.marketingConsent),
      },
    });
  }
  await UserProfile.updateOne(
    { userId: user._id },
    { $set: { firstName: input.firstName, lastName: input.lastName }, $setOnInsert: { userId: user._id } },
    { upsert: true },
  );
  const otp = await issueOtp({ target: e164, purpose: 'PHONE_VERIFY', userId: user._id });
  await audit({ actorType: 'USER', actorId: user._id, action: 'user.register', resourceType: 'User', resourceId: user._id }, req);
  return { status: 'OTP_SENT', phone: e164, otpExpiresAt: otp.expiresAt };
}

export async function verifyPhone({ phone, code, device }, req) {
  const { e164 } = normalizePhone(phone);
  const user = await User.findOne({ phone: e164 });
  if (!user) throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  await verifyOtp({ target: e164, purpose: 'PHONE_VERIFY', code });
  const wasPending = user.status === 'PENDING_VERIFICATION';
  user.phoneVerifiedAt = new Date();
  if (wasPending) user.status = 'ACTIVE';
  await user.save();
  const session = await completeLogin(user, device, req, { newDevice: false });
  // Emitted after the device is registered so referral abuse checks can see it.
  if (wasPending) await emitDomainEvent('user.activated', { userId: String(user._id), referredBy: user.referredBy ? String(user.referredBy) : null });
  return session;
}

export async function resendOtp({ phone, purpose }) {
  const { e164 } = normalizePhone(phone);
  const user = await User.findOne({ phone: e164 }, { _id: 1, status: 1 }).lean();
  // Same response regardless of existence to avoid account enumeration.
  if (user && (purpose !== 'PHONE_VERIFY' || user.status === 'PENDING_VERIFICATION')) {
    await issueOtp({ target: e164, purpose, userId: user._id });
  }
  return { status: 'OTP_SENT' };
}

// ---------------------------------------------------------------- login
export async function login({ phone, password, device }, req) {
  const { e164 } = normalizePhone(phone);
  const user = await User.findOne({ phone: e164 }).select('+passwordHash');
  if (!user) {
    dummyHash ??= await hashSecret('timing-equaliser-not-a-password-1');
    await verifySecret(dummyHash, password);
    throw Errors.unauthorized('Incorrect phone number or password', 'INVALID_CREDENTIALS');
  }
  if (user.status === 'CLOSED') throw Errors.unauthorized('Incorrect phone number or password', 'INVALID_CREDENTIALS');
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    throw Errors.locked('Account temporarily locked after too many failed attempts', { lockedUntil: user.lockedUntil });
  }
  const ok = await verifySecret(user.passwordHash, password);
  if (!ok) {
    const updated = await User.findOneAndUpdate({ _id: user._id }, { $inc: { failedLoginAttempts: 1 } }, { new: true });
    await securityEvent({ userId: user._id, type: 'LOGIN_FAILED', severity: 'LOW', details: { attempts: updated.failedLoginAttempts } }, req);
    if (updated.failedLoginAttempts >= config.LOGIN_MAX_FAILURES) {
      const lockedUntil = new Date(Date.now() + config.LOGIN_LOCK_MINUTES * 60_000);
      await User.updateOne({ _id: user._id }, { $set: { lockedUntil, failedLoginAttempts: 0 } });
      await securityEvent({ userId: user._id, type: 'ACCOUNT_LOCKED', severity: 'HIGH' }, req);
      await notify(user._id, { category: 'SECURITY', type: 'ACCOUNT_LOCKED', title: 'Account temporarily locked', body: 'We locked your account after several failed sign-in attempts. If this wasn\'t you, reset your password.' });
      throw Errors.locked('Account temporarily locked after too many failed attempts', { lockedUntil });
    }
    throw Errors.unauthorized('Incorrect phone number or password', 'INVALID_CREDENTIALS');
  }
  if (user.status === 'SUSPENDED' || user.restrictions.includes('NO_LOGIN')) {
    throw Errors.forbidden('Your account is suspended. Please contact support.');
  }
  if (user.status === 'PENDING_VERIFICATION') {
    await issueOtp({ target: e164, purpose: 'PHONE_VERIFY', userId: user._id });
    return { next: 'VERIFY_PHONE', phone: e164 };
  }

  const known = await Device.findOne({ userId: user._id, deviceId: device.deviceId });
  if (known?.trusted && !known.revokedAt) return completeLogin(user, device, req, { newDevice: false });

  // Unknown or revoked device: step-up verification by SMS OTP.
  const challengeId = randomToken(24);
  await getRedis().set(`login-challenge:${challengeId}`, JSON.stringify({ userId: String(user._id), device }), 'EX', 600);
  await issueOtp({ target: e164, purpose: 'DEVICE_VERIFY', userId: user._id });
  return { next: 'VERIFY_DEVICE', challengeId, phone: e164 };
}

export async function verifyDevice({ challengeId, code }, req) {
  const key = `login-challenge:${challengeId}`;
  const raw = await getRedis().get(key);
  if (!raw) throw Errors.unprocessable('CHALLENGE_EXPIRED', 'Sign-in session expired. Please sign in again.');
  const { userId, device } = JSON.parse(raw);
  const user = await User.findById(userId);
  if (!user) throw Errors.unauthorized();
  await verifyOtp({ target: user.phone, purpose: 'DEVICE_VERIFY', code });
  await getRedis().del(key);
  return completeLogin(user, device, req, { newDevice: true });
}

// ---------------------------------------------------------------- refresh / logout
export async function refresh({ refreshToken, deviceId }, req) {
  const tokenHash = hmac(refreshToken);
  const session = await Session.findOne({ refreshTokenHash: tokenHash });
  if (!session) {
    const reused = await Session.findOne({ previousTokenHashes: tokenHash });
    if (reused) {
      // A rotated token was replayed: assume theft and kill the session.
      await revokeSessions({ _id: reused._id }, 'REFRESH_TOKEN_REUSE');
      await securityEvent({ userId: reused.userId, type: 'REFRESH_TOKEN_REUSE', severity: 'CRITICAL', details: { sessionId: String(reused._id) } }, req);
      await notify(reused.userId, { category: 'SECURITY', type: 'SESSION_COMPROMISED', title: 'We signed you out for your safety', body: 'We detected unusual activity on one of your sessions and signed it out. Please sign in again.' });
    }
    throw Errors.unauthorized('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
  }
  if (session.revokedAt || session.expiresAt < new Date()) throw Errors.unauthorized('Session expired. Please sign in again.', 'SESSION_EXPIRED');
  const device = await Device.findById(session.device);
  if (!device || device.revokedAt || (deviceId && device.deviceId !== deviceId)) {
    await revokeSessions({ _id: session._id }, 'DEVICE_MISMATCH');
    throw Errors.unauthorized('Session is not valid on this device', 'SESSION_EXPIRED');
  }
  const user = await User.findById(session.userId);
  if (!user || user.status === 'SUSPENDED' || user.status === 'CLOSED') {
    await revokeSessions({ _id: session._id }, 'ACCOUNT_INACTIVE');
    throw Errors.unauthorized('Account unavailable', 'ACCOUNT_INACTIVE');
  }

  const newToken = randomToken(48);
  // Compare-and-swap on the old hash so two concurrent refreshes cannot both win.
  const rotated = await Session.findOneAndUpdate(
    { _id: session._id, refreshTokenHash: tokenHash, revokedAt: null },
    {
      $set: { refreshTokenHash: hmac(newToken), lastUsedAt: new Date(), ip: req.ip },
      $push: { previousTokenHashes: { $each: [tokenHash], $slice: -20 } },
      $inc: { rotationCount: 1 },
    },
    { new: true },
  );
  if (!rotated) throw Errors.unauthorized('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
  await Device.updateOne({ _id: device._id }, { $set: { lastSeenAt: new Date(), lastIp: req.ip } });
  return {
    accessToken: signAccessToken(user, rotated, device),
    refreshToken: newToken,
    tokenType: 'Bearer',
    expiresIn: config.ACCESS_TOKEN_TTL_SECONDS,
    sessionId: String(rotated._id),
  };
}

export async function logout(sessionId) {
  await Session.updateOne({ _id: sessionId, revokedAt: null }, { $set: { revokedAt: new Date(), revokedReason: 'LOGOUT' } });
  await markSessionRevoked(sessionId);
}

export async function logoutAll(userId, req) {
  const count = await revokeSessions({ userId }, 'LOGOUT_ALL');
  await securityEvent({ userId, type: 'SESSION_REVOKED', severity: 'MEDIUM', details: { count, scope: 'ALL' } }, req);
  return { revoked: count };
}

// ---------------------------------------------------------------- password
export async function forgotPassword({ phone }) {
  const { e164 } = normalizePhone(phone);
  const user = await User.findOne({ phone: e164, status: { $in: ['ACTIVE', 'SUSPENDED'] } }, { _id: 1 }).lean();
  if (user) await issueOtp({ target: e164, purpose: 'PASSWORD_RESET', userId: user._id });
  return { status: 'OTP_SENT' };
}

export async function resetPassword({ phone, code, newPassword }, req) {
  const { e164 } = normalizePhone(phone);
  assertPasswordPolicy(newPassword);
  const user = await User.findOne({ phone: e164 });
  if (!user) throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  await verifyOtp({ target: e164, purpose: 'PASSWORD_RESET', code });
  await User.updateOne({ _id: user._id }, {
    $set: { passwordHash: await hashSecret(newPassword), passwordChangedAt: new Date(), failedLoginAttempts: 0 },
    $unset: { lockedUntil: 1 },
  });
  await revokeSessions({ userId: user._id }, 'PASSWORD_RESET');
  // Require fresh device verification everywhere after a reset.
  await Device.updateMany({ userId: user._id }, { $set: { trusted: false } });
  await securityEvent({ userId: user._id, type: 'PASSWORD_RESET', severity: 'MEDIUM' }, req);
  await notify(user._id, { category: 'SECURITY', type: 'PASSWORD_RESET', title: 'Your password was reset', body: 'Your password was changed and all devices were signed out. If this wasn\'t you, contact support immediately.' });
  return { status: 'PASSWORD_RESET' };
}

export async function changePassword(userId, sessionId, { currentPassword, newPassword }, req) {
  const user = await User.findById(userId).select('+passwordHash');
  if (!(await verifySecret(user.passwordHash, currentPassword))) throw Errors.unprocessable('INVALID_PASSWORD', 'Current password is incorrect');
  assertPasswordPolicy(newPassword);
  if (await verifySecret(user.passwordHash, newPassword)) throw Errors.validation([{ path: 'newPassword', message: 'New password must be different' }]);
  await User.updateOne({ _id: userId }, { $set: { passwordHash: await hashSecret(newPassword), passwordChangedAt: new Date() } });
  await revokeSessions({ userId, _id: { $ne: sessionId } }, 'PASSWORD_CHANGED');
  await securityEvent({ userId, type: 'PASSWORD_CHANGED', severity: 'MEDIUM' }, req);
  await notify(userId, { category: 'SECURITY', type: 'PASSWORD_CHANGED', title: 'Password changed', body: 'Your password was changed. Other devices have been signed out.' });
  return { status: 'PASSWORD_CHANGED' };
}

// ---------------------------------------------------------------- PIN
export async function setPin(userId, { pin }, req) {
  assertPinPolicy(pin);
  const user = await User.findById(userId);
  if (user.pinSetAt) throw Errors.conflict('A PIN is already set. Use change PIN instead.', 'PIN_EXISTS');
  await User.updateOne({ _id: userId }, { $set: { pinHash: await hashSecret(pin), pinSetAt: new Date(), pinFailedAttempts: 0 } });
  await audit({ actorType: 'USER', actorId: userId, action: 'user.pin.set', resourceType: 'User', resourceId: userId }, req);
  return { status: 'PIN_SET' };
}

/** Verifies the app transaction PIN (never an M-Pesa PIN) with lockout. */
export async function verifyPin(userId, pin, req) {
  const user = await User.findById(userId).select('+pinHash');
  if (!user?.pinHash) throw Errors.unprocessable('PIN_NOT_SET', 'Create a transaction PIN first');
  if (user.pinLockedUntil && user.pinLockedUntil > new Date()) {
    throw Errors.locked('PIN locked after too many attempts. Reset your PIN to continue.', { lockedUntil: user.pinLockedUntil });
  }
  if (await verifySecret(user.pinHash, String(pin ?? ''))) {
    if (user.pinFailedAttempts) await User.updateOne({ _id: userId }, { $set: { pinFailedAttempts: 0 } });
    return true;
  }
  const updated = await User.findOneAndUpdate({ _id: userId }, { $inc: { pinFailedAttempts: 1 } }, { new: true });
  if (updated.pinFailedAttempts >= config.PIN_MAX_FAILURES) {
    const lockedUntil = new Date(Date.now() + config.PIN_LOCK_MINUTES * 60_000);
    await User.updateOne({ _id: userId }, { $set: { pinLockedUntil: lockedUntil, pinFailedAttempts: 0 } });
    await securityEvent({ userId, type: 'PIN_LOCKED', severity: 'HIGH' }, req);
    await notify(userId, { category: 'SECURITY', type: 'PIN_LOCKED', title: 'Transaction PIN locked', body: 'Your PIN was locked after several incorrect attempts.' });
    throw Errors.locked('PIN locked after too many attempts. Reset your PIN to continue.', { lockedUntil });
  }
  throw Errors.unprocessable('INVALID_PIN', 'Incorrect PIN', { attemptsRemaining: config.PIN_MAX_FAILURES - updated.pinFailedAttempts });
}

export async function changePin(userId, { currentPin, newPin }, req) {
  await verifyPin(userId, currentPin, req);
  assertPinPolicy(newPin);
  await User.updateOne({ _id: userId }, { $set: { pinHash: await hashSecret(newPin), pinSetAt: new Date() } });
  await securityEvent({ userId, type: 'PIN_CHANGED', severity: 'MEDIUM' }, req);
  await notify(userId, { category: 'SECURITY', type: 'PIN_CHANGED', title: 'Transaction PIN changed', body: 'Your transaction PIN was changed.' });
  return { status: 'PIN_CHANGED' };
}

export async function requestPinReset(userId) {
  const user = await User.findById(userId, { phone: 1 }).lean();
  await issueOtp({ target: user.phone, purpose: 'PIN_RESET', userId });
  return { status: 'OTP_SENT' };
}

export async function resetPin(userId, { code, password, newPin }, req) {
  const user = await User.findById(userId).select('+passwordHash');
  if (!(await verifySecret(user.passwordHash, password))) throw Errors.unprocessable('INVALID_PASSWORD', 'Password is incorrect');
  await verifyOtp({ target: user.phone, purpose: 'PIN_RESET', code });
  assertPinPolicy(newPin);
  await User.updateOne({ _id: userId }, { $set: { pinHash: await hashSecret(newPin), pinSetAt: new Date(), pinFailedAttempts: 0 }, $unset: { pinLockedUntil: 1 } });
  await securityEvent({ userId, type: 'PIN_CHANGED', severity: 'MEDIUM', details: { via: 'reset' } }, req);
  await notify(userId, { category: 'SECURITY', type: 'PIN_RESET', title: 'Transaction PIN reset', body: 'Your transaction PIN was reset.' });
  return { status: 'PIN_RESET' };
}

// ---------------------------------------------------------------- email
export async function requestEmailVerification(userId, { email }) {
  const normalized = email.toLowerCase();
  if (await User.exists({ email: normalized, _id: { $ne: userId } })) throw Errors.conflict('This email address is already in use', 'EMAIL_TAKEN');
  await User.updateOne({ _id: userId }, { $set: { email: normalized }, $unset: { emailVerifiedAt: 1 } });
  await issueOtp({ target: normalized, channel: 'EMAIL', purpose: 'EMAIL_VERIFY', userId });
  return { status: 'OTP_SENT' };
}

export async function verifyEmail(userId, { code }) {
  const user = await User.findById(userId);
  if (!user.email) throw Errors.badRequest('No email address on file');
  await verifyOtp({ target: user.email, channel: 'EMAIL', purpose: 'EMAIL_VERIFY', code });
  user.emailVerifiedAt = new Date();
  await user.save();
  return { user: user.toPublic() };
}

// ---------------------------------------------------------------- account recovery
/**
 * Recovery for users who lost access to their phone number. Because a phone
 * number change is a high-risk operation (SIM-swap fraud), the verified email
 * only opens a recovery case that support reviews with KYC evidence.
 */
export async function startRecovery({ email }) {
  const user = await User.findOne({ email: email.toLowerCase(), emailVerifiedAt: { $ne: null } }, { _id: 1, email: 1 }).lean();
  if (user) await issueOtp({ target: user.email, channel: 'EMAIL', purpose: 'ACCOUNT_RECOVERY', userId: user._id });
  return { status: 'OTP_SENT' };
}

export async function completeRecovery({ email, code, newPhone, details }, req) {
  const user = await User.findOne({ email: email.toLowerCase(), emailVerifiedAt: { $ne: null } });
  if (!user) throw Errors.unprocessable('OTP_INVALID', 'The code is invalid or has expired');
  await verifyOtp({ target: user.email, channel: 'EMAIL', purpose: 'ACCOUNT_RECOVERY', code });
  const { e164 } = normalizePhone(newPhone);
  const { createRecoveryTicket } = await import('../support/service.js');
  const ticket = await createRecoveryTicket(user, { requestedPhone: e164, details }, req);
  await revokeSessions({ userId: user._id }, 'ACCOUNT_RECOVERY');
  return { status: 'RECOVERY_UNDER_REVIEW', ticketReference: ticket.reference };
}
