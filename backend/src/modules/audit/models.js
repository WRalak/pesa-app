import mongoose from 'mongoose';
import { appendOnly } from '../../lib/immutable.js';

const { Schema } = mongoose;

/**
 * Tamper-evident audit trail. Each entry stores the hash of the previous
 * entry; `scripts/verify-audit-chain.js` re-computes the chain to detect
 * deletion or modification. Collection is append-only.
 */
const auditLogSchema = new Schema({
  seq: { type: Number, required: true, unique: true },
  actorType: { type: String, enum: ['USER', 'ADMIN', 'SYSTEM', 'PROVIDER'], required: true },
  actorId: { type: String },
  action: { type: String, required: true },
  resourceType: { type: String },
  resourceId: { type: String },
  outcome: { type: String, enum: ['SUCCESS', 'FAILURE', 'DENIED'], default: 'SUCCESS' },
  ip: String,
  userAgent: String,
  requestId: String,
  metadata: { type: Schema.Types.Mixed },
  prevHash: { type: String },
  hash: { type: String, required: true },
  createdAt: { type: Date, required: true },
}, { versionKey: false, minimize: false });
auditLogSchema.index({ actorType: 1, actorId: 1, createdAt: -1 });
auditLogSchema.index({ resourceType: 1, resourceId: 1, createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });
auditLogSchema.plugin(appendOnly);

const chainHeadSchema = new Schema({ _id: String, seq: Number, hash: String }, { versionKey: false });

const securityEventSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User' },
  adminId: { type: Schema.Types.ObjectId, ref: 'AdminUser' },
  type: {
    type: String,
    required: true,
    enum: [
      'LOGIN_SUCCESS', 'LOGIN_FAILED', 'ACCOUNT_LOCKED', 'NEW_DEVICE_LOGIN', 'SUSPICIOUS_LOGIN',
      'REFRESH_TOKEN_REUSE', 'PASSWORD_CHANGED', 'PASSWORD_RESET', 'PIN_CHANGED', 'PIN_LOCKED',
      'DEVICE_REVOKED', 'SESSION_REVOKED', 'MFA_ENROLLED', 'MFA_FAILED', 'OTP_ABUSE',
      'CALLBACK_REJECTED', 'ADMIN_LOGIN', 'ADMIN_LOGIN_FAILED', 'ACCOUNT_SUSPENDED', 'FRAUD_FLAG',
    ],
  },
  severity: { type: String, enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], default: 'LOW' },
  ip: String,
  userAgent: String,
  deviceId: String,
  details: Schema.Types.Mixed,
  acknowledgedBy: { type: Schema.Types.ObjectId, ref: 'AdminUser' },
  acknowledgedAt: Date,
}, { timestamps: { createdAt: true, updatedAt: false }, versionKey: false });
securityEventSchema.index({ userId: 1, createdAt: -1 });
securityEventSchema.index({ severity: 1, acknowledgedAt: 1, createdAt: -1 });
securityEventSchema.index({ type: 1, createdAt: -1 });
// Retain security telemetry for 2 years, then expire automatically.
securityEventSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 730, name: 'security_event_ttl' });

export const AuditLog = mongoose.model('AuditLog', auditLogSchema);
export const AuditChainHead = mongoose.model('AuditChainHead', chainHeadSchema);
export const SecurityEvent = mongoose.model('SecurityEvent', securityEventSchema);
