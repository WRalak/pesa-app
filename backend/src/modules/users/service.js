import { User, UserProfile, KycRecord } from './models.js';
import { Device, Session } from '../auth/models.js';
import { Errors } from '../../lib/errors.js';
import { encryptField, hmac, verifySecret } from '../../lib/crypto.js';
import { getCountry } from '../../config/countries/index.js';
import { revokeSessions, markSessionRevoked } from '../../middleware/auth.js';
import { securityEvent, audit } from '../audit/service.js';
import { presignUpload, presignDownload } from '../../lib/storage.js';
import { money } from '../../lib/money.js';

export async function getMe(userId) {
  const [user, profile] = await Promise.all([User.findById(userId), UserProfile.findOne({ userId }).lean()]);
  if (!user) throw Errors.notFound('User');
  return { user: user.toPublic(), profile: serializeProfile(profile) };
}

export function serializeProfile(p) {
  if (!p) return null;
  return {
    firstName: p.firstName ?? null,
    lastName: p.lastName ?? null,
    dateOfBirth: p.dateOfBirth ?? null,
    occupation: p.occupation ?? null,
    address: p.address ?? {},
    hasAvatar: Boolean(p.avatarKey),
    notificationPreferences: p.notificationPreferences ?? {},
    privacy: p.privacy ?? {},
  };
}

export async function updateProfile(userId, patch) {
  const set = {};
  for (const [k, v] of Object.entries(patch)) {
    if (k === 'address') for (const [ak, av] of Object.entries(v)) set[`address.${ak}`] = av;
    else set[k] = v;
  }
  // Names are locked once KYC is verified so identity cannot drift from documents.
  const user = await User.findById(userId, { kycStatus: 1 }).lean();
  if (user.kycStatus === 'VERIFIED' && (patch.firstName || patch.lastName || patch.dateOfBirth)) {
    throw Errors.unprocessable('KYC_LOCKED', 'Name and date of birth cannot be changed after identity verification. Contact support.');
  }
  const profile = await UserProfile.findOneAndUpdate({ userId }, { $set: set }, { new: true, upsert: true }).lean();
  return serializeProfile(profile);
}

export async function updatePreferences(userId, prefs) {
  const set = Object.fromEntries(Object.entries(prefs).map(([k, v]) => [`notificationPreferences.${k}`, v]));
  const profile = await UserProfile.findOneAndUpdate({ userId }, { $set: set }, { new: true, upsert: true }).lean();
  return profile.notificationPreferences;
}

export async function updatePrivacy(userId, { hideBalances, analyticsOptIn, marketing, aiInsights, externalAiProcessing }) {
  const pset = {};
  if (hideBalances !== undefined) pset['privacy.hideBalances'] = hideBalances;
  if (analyticsOptIn !== undefined) pset['privacy.analyticsOptIn'] = analyticsOptIn;
  if (Object.keys(pset).length) await UserProfile.updateOne({ userId }, { $set: pset }, { upsert: true });
  const uset = {};
  if (marketing !== undefined) uset['consents.marketing'] = marketing;
  if (aiInsights !== undefined) uset['consents.aiInsights'] = aiInsights;
  if (externalAiProcessing !== undefined) uset['consents.externalAiProcessing'] = externalAiProcessing;
  if (Object.keys(uset).length) await User.updateOne({ _id: userId }, { $set: uset });
  return getMe(userId);
}

export async function avatarUploadUrl(userId, contentType) {
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(contentType)) throw Errors.validation([{ path: 'contentType', message: 'Unsupported image type' }]);
  const upload = await presignUpload({ prefix: `avatars/${userId}`, contentType, maxBytes: 2 * 1024 * 1024 });
  return upload;
}

export async function confirmAvatar(userId, key) {
  if (!key.startsWith(`avatars/${userId}/`)) throw Errors.forbidden();
  await UserProfile.updateOne({ userId }, { $set: { avatarKey: key } });
  return { avatarUrl: await presignDownload(key) };
}

export async function avatarUrl(userId) {
  const p = await UserProfile.findOne({ userId }, { avatarKey: 1 }).lean();
  return { avatarUrl: p?.avatarKey ? await presignDownload(p.avatarKey) : null };
}

// ---------------------------------------------------------------- devices & sessions
export async function listDevices(userId, currentDeviceId) {
  const devices = await Device.find({ userId, revokedAt: null }).sort({ lastSeenAt: -1 }).lean();
  return devices.map((d) => ({
    id: String(d._id), name: d.name ?? d.model ?? 'Unknown device', platform: d.platform, model: d.model,
    trusted: d.trusted, biometricEnabled: d.biometricEnabled, lastSeenAt: d.lastSeenAt, current: d.deviceId === currentDeviceId,
  }));
}

export async function revokeDevice(userId, id, req) {
  const device = await Device.findOneAndUpdate({ _id: id, userId, revokedAt: null }, { $set: { revokedAt: new Date(), trusted: false, biometricEnabled: false }, $unset: { pushToken: 1 } });
  if (!device) throw Errors.notFound('Device');
  await revokeSessions({ userId, device: device._id }, 'DEVICE_REVOKED');
  await securityEvent({ userId, type: 'DEVICE_REVOKED', severity: 'MEDIUM', details: { device: device.name } }, req);
}

export async function updateCurrentDevice(userId, deviceId, { pushToken, biometricEnabled }) {
  const set = {};
  if (pushToken !== undefined) set.pushToken = pushToken;
  if (biometricEnabled !== undefined) set.biometricEnabled = biometricEnabled;
  const d = await Device.findOneAndUpdate({ userId, deviceId, revokedAt: null }, { $set: set }, { new: true });
  if (!d) throw Errors.notFound('Device');
  return { id: String(d._id), biometricEnabled: d.biometricEnabled, pushRegistered: Boolean(pushToken ?? d.pushToken) };
}

export async function listSessions(userId, currentSessionId) {
  const sessions = await Session.find({ userId, revokedAt: null, expiresAt: { $gt: new Date() } }).populate('device', 'name model platform').sort({ lastUsedAt: -1 }).lean();
  return sessions.map((s) => ({
    id: String(s._id), device: s.device?.name ?? s.device?.model ?? 'Unknown', platform: s.device?.platform,
    ip: s.ip, lastUsedAt: s.lastUsedAt, createdAt: s.createdAt, current: String(s._id) === currentSessionId,
  }));
}

export async function revokeSession(userId, id, req) {
  const s = await Session.findOneAndUpdate({ _id: id, userId, revokedAt: null }, { $set: { revokedAt: new Date(), revokedReason: 'USER_REVOKED' } });
  if (!s) throw Errors.notFound('Session');
  await markSessionRevoked(String(s._id));
  await securityEvent({ userId, type: 'SESSION_REVOKED', severity: 'LOW', details: { sessionId: id } }, req);
}

// ---------------------------------------------------------------- limits
export async function getLimits(userId) {
  const [user, profile] = await Promise.all([User.findById(userId).lean(), UserProfile.findOne({ userId }, { transactionLimits: 1 }).lean()]);
  const reg = getCountry(user.country).limits[user.kycTier];
  const custom = profile?.transactionLimits ?? {};
  const eff = (k) => Math.min(reg[k], custom[k] ?? reg[k]);
  return {
    kycTier: user.kycTier,
    regulatory: { perTransaction: money(reg.perTransaction, user.currency), daily: money(reg.daily, user.currency), monthly: money(reg.monthly, user.currency) },
    custom: { perTransaction: custom.perTransaction ? money(custom.perTransaction, user.currency) : null, daily: custom.daily ? money(custom.daily, user.currency) : null },
    effective: { perTransaction: money(eff('perTransaction'), user.currency), daily: money(eff('daily'), user.currency), monthly: money(reg.monthly, user.currency) },
  };
}

export async function setLimits(userId, { perTransactionMinor, dailyMinor }) {
  const user = await User.findById(userId).lean();
  const reg = getCountry(user.country).limits[user.kycTier];
  if (perTransactionMinor != null && perTransactionMinor > reg.perTransaction) throw Errors.validation([{ path: 'perTransaction', message: 'Cannot exceed your regulatory limit' }]);
  if (dailyMinor != null && dailyMinor > reg.daily) throw Errors.validation([{ path: 'daily', message: 'Cannot exceed your regulatory limit' }]);
  await UserProfile.updateOne({ userId }, { $set: { 'transactionLimits.perTransaction': perTransactionMinor ?? null, 'transactionLimits.daily': dailyMinor ?? null } }, { upsert: true });
  return getLimits(userId);
}

// ---------------------------------------------------------------- KYC
export async function submitKyc(userId, { idType, idNumber, fullName, dateOfBirth, documentKeys = [] }, req) {
  const user = await User.findById(userId);
  const country = getCountry(user.country);
  if (!country.kyc.idTypes.includes(idType)) throw Errors.validation([{ path: 'idType', message: 'Unsupported ID type' }]);
  if (user.kycStatus === 'VERIFIED') throw Errors.conflict('Identity already verified', 'KYC_VERIFIED');
  if (user.kycStatus === 'PENDING') throw Errors.conflict('Verification already in progress', 'KYC_PENDING');
  for (const k of documentKeys) if (!k.startsWith(`kyc/${userId}/`)) throw Errors.forbidden();
  const idNumberHash = hmac(`${user.country}:${idType}:${idNumber.toUpperCase()}`);
  const duplicate = await KycRecord.exists({ idNumberHash, country: user.country, status: 'VERIFIED', userId: { $ne: userId } });
  const record = await KycRecord.create({
    userId, country: user.country, idType, fullName, dateOfBirth,
    idNumberEnc: encryptField(idNumber.toUpperCase()), idNumberHash, idNumberLast4: idNumber.slice(-4),
    documents: documentKeys.map((k) => ({ type: 'ID_DOCUMENT', storageKey: k, uploadedAt: new Date() })),
  });
  user.kycStatus = 'PENDING';
  if (duplicate) user.restrictions = [...new Set([...user.restrictions, 'REVIEW_REQUIRED'])];
  await user.save();
  if (duplicate) await securityEvent({ userId, type: 'FRAUD_FLAG', severity: 'HIGH', details: { reason: 'KYC_ID_REUSED' } }, req);
  await audit({ actorType: 'USER', actorId: userId, action: 'kyc.submitted', resourceType: 'KycRecord', resourceId: record._id }, req);
  return { status: 'PENDING', submittedAt: record.createdAt };
}

export async function kycStatus(userId) {
  const [user, latest] = await Promise.all([
    User.findById(userId, { kycStatus: 1, kycTier: 1, country: 1 }).lean(),
    KycRecord.findOne({ userId }).sort({ createdAt: -1 }).lean(),
  ]);
  return {
    status: user.kycStatus,
    tier: user.kycTier,
    acceptedIdTypes: getCountry(user.country).kyc.idTypes,
    latest: latest ? { idType: latest.idType, idNumberLast4: latest.idNumberLast4, status: latest.status, rejectionReason: latest.rejectionReason ?? null, submittedAt: latest.createdAt } : null,
  };
}

export async function kycUploadUrl(userId, contentType) {
  return presignUpload({ prefix: `kyc/${userId}`, contentType, maxBytes: 8 * 1024 * 1024 });
}

// ---------------------------------------------------------------- data rights
/** Data portability export (Kenya DPA s.38). Large exports run as a job. */
export async function exportData(userId) {
  const { Transaction } = await import('../payments/models.js');
  const me = await getMe(userId);
  const txCount = await Transaction.countDocuments({ userId });
  return {
    generatedAt: new Date(),
    account: me.user,
    profile: me.profile,
    devices: await listDevices(userId),
    transactionCount: txCount,
    note: 'Full transaction history is available as a statement from Activity > Statements.',
  };
}

/**
 * Account closure. Personal data is minimised immediately; financial records
 * are retained for the statutory AML retention period (7 years) in
 * pseudonymised form, as required by POCAMLA and permitted by DPA s.39.
 */
export async function closeAccount(userId, { password, reason }, req) {
  const user = await User.findById(userId).select('+passwordHash');
  if (!(await verifySecret(user.passwordHash, password))) throw Errors.unprocessable('INVALID_PASSWORD', 'Password is incorrect');
  const { Transaction } = await import('../payments/models.js');
  const pending = await Transaction.exists({ userId, status: { $in: ['INITIATED', 'PENDING', 'PROCESSING'] } });
  if (pending) throw Errors.conflict('You have payments in progress. Try again once they complete.', 'PENDING_TRANSACTIONS');
  await revokeSessions({ userId }, 'ACCOUNT_CLOSED');
  await Device.updateMany({ userId }, { $set: { revokedAt: new Date() }, $unset: { pushToken: 1 } });
  await UserProfile.updateOne({ userId }, { $unset: { firstName: 1, lastName: 1, dateOfBirth: 1, address: 1, occupation: 1, avatarKey: 1 } });
  await User.updateOne({ _id: userId }, {
    $set: { status: 'CLOSED', closedAt: new Date(), deletionRequestedAt: new Date(), phone: `closed:${String(userId)}`, 'consents.marketing': false },
    $unset: { email: 1, pinHash: 1 },
  });
  await audit({ actorType: 'USER', actorId: userId, action: 'user.account.closed', resourceType: 'User', resourceId: userId, metadata: { reason } }, req);
  return { status: 'CLOSED' };
}
