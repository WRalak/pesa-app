import mongoose from 'mongoose';

const { Schema } = mongoose;

const deviceSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  deviceId: { type: String, required: true, maxlength: 128 },
  name: { type: String, maxlength: 80 },
  platform: { type: String, enum: ['android', 'ios', 'web', 'unknown'], default: 'unknown' },
  model: { type: String, maxlength: 80 },
  osVersion: { type: String, maxlength: 40 },
  appVersion: { type: String, maxlength: 32 },
  pushToken: { type: String, select: false },
  trusted: { type: Boolean, default: false },
  trustedAt: Date,
  biometricEnabled: { type: Boolean, default: false },
  lastSeenAt: Date,
  lastIp: String,
  revokedAt: Date,
}, { timestamps: true });
deviceSchema.index({ userId: 1, deviceId: 1 }, { unique: true });
deviceSchema.index({ userId: 1, revokedAt: 1, lastSeenAt: -1 });

/**
 * One session per login on a device. The refresh token is opaque, stored only
 * as an HMAC, and rotated on each use. Previous hashes are retained so that a
 * replayed (stolen) refresh token is detected and the session revoked.
 */
const sessionSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  device: { type: Schema.Types.ObjectId, ref: 'Device', required: true },
  refreshTokenHash: { type: String, required: true },
  previousTokenHashes: { type: [String], default: [], select: false },
  ip: String,
  userAgent: String,
  lastUsedAt: Date,
  rotationCount: { type: Number, default: 0 },
  expiresAt: { type: Date, required: true },
  revokedAt: Date,
  revokedReason: String,
}, { timestamps: true });
sessionSchema.index({ refreshTokenHash: 1 }, { unique: true });
sessionSchema.index({ previousTokenHashes: 1 });
sessionSchema.index({ userId: 1, revokedAt: 1 });
sessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const otpSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User' },
  targetHash: { type: String, required: true }, // HMAC of phone/email
  channel: { type: String, enum: ['SMS', 'EMAIL'], required: true },
  purpose: {
    type: String,
    enum: ['PHONE_VERIFY', 'EMAIL_VERIFY', 'DEVICE_VERIFY', 'PASSWORD_RESET', 'PIN_RESET', 'ACCOUNT_RECOVERY', 'SENSITIVE_ACTION'],
    required: true,
  },
  codeHash: { type: String, required: true },
  attempts: { type: Number, default: 0 },
  maxAttempts: { type: Number, default: 5 },
  consumedAt: Date,
  expiresAt: { type: Date, required: true },
}, { timestamps: { createdAt: true, updatedAt: false } });
otpSchema.index({ targetHash: 1, purpose: 1, createdAt: -1 });
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 3600 }); // keep 1h past expiry for abuse analysis

export const Device = mongoose.model('Device', deviceSchema);
export const Session = mongoose.model('Session', sessionSchema);
export const Otp = mongoose.model('Otp', otpSchema);
