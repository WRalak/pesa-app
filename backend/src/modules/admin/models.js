import mongoose from 'mongoose';

const { Schema } = mongoose;

const permissionSchema = new Schema({
  key: { type: String, required: true },
  group: { type: String, required: true },
  description: { type: String, required: true },
}, { timestamps: true });
permissionSchema.index({ key: 1 }, { unique: true });

const roleSchema = new Schema({
  key: { type: String, required: true, uppercase: true },
  name: { type: String, required: true },
  description: String,
  permissions: { type: [String], default: [] },
  system: { type: Boolean, default: false },
}, { timestamps: true });
roleSchema.index({ key: 1 }, { unique: true });

const adminUserSchema = new Schema({
  email: { type: String, required: true, lowercase: true, trim: true },
  name: { type: String, required: true, maxlength: 80 },
  passwordHash: { type: String, required: true, select: false },
  roles: { type: [String], default: [] }, // role keys
  status: { type: String, enum: ['ACTIVE', 'DISABLED'], default: 'ACTIVE' },
  mfaEnabled: { type: Boolean, default: false },
  mfaSecretEnc: { type: String, select: false },
  mfaLastStep: { type: Number, select: false }, // TOTP replay protection
  failedLogins: { type: Number, default: 0 },
  lockedUntil: Date,
  lastLoginAt: Date,
  lastLoginIp: String,
  passwordChangedAt: Date,
  mustChangePassword: { type: Boolean, default: false },
  createdBy: Schema.Types.ObjectId,
}, { timestamps: true });
adminUserSchema.index({ email: 1 }, { unique: true });

const adminSessionSchema = new Schema({
  adminId: { type: Schema.Types.ObjectId, ref: 'AdminUser', required: true },
  ip: String,
  userAgent: String,
  expiresAt: { type: Date, required: true },
  revokedAt: Date,
}, { timestamps: true });
adminSessionSchema.index({ adminId: 1, revokedAt: 1 });
adminSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 86_400 });

/** Maker-checker approvals for high-risk operations. */
const adminApprovalSchema = new Schema({
  type: { type: String, enum: ['TRANSACTION_REVERSAL'], required: true },
  resourceId: { type: String, required: true },
  payload: Schema.Types.Mixed,
  reason: { type: String, required: true, maxlength: 500 },
  status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED', 'FAILED'], default: 'PENDING' },
  requestedBy: { type: Schema.Types.ObjectId, ref: 'AdminUser', required: true },
  decidedBy: { type: Schema.Types.ObjectId, ref: 'AdminUser' },
  decidedAt: Date,
  decisionNote: String,
}, { timestamps: true });
adminApprovalSchema.index({ status: 1, createdAt: -1 });
adminApprovalSchema.index({ type: 1, resourceId: 1, status: 1 });

/** Marketing notification campaigns (fan-out handled by the worker). */
const notificationCampaignSchema = new Schema({
  title: { type: String, required: true, maxlength: 120 },
  body: { type: String, required: true, maxlength: 500 },
  segment: {
    countries: [String],
    kycTiers: [String],
    marketingConsentOnly: { type: Boolean, default: true, immutable: true },
  },
  status: { type: String, enum: ['DRAFT', 'SCHEDULED', 'SENDING', 'SENT', 'CANCELLED'], default: 'DRAFT' },
  scheduledAt: Date,
  sentCount: { type: Number, default: 0 },
  createdBy: Schema.Types.ObjectId,
  sentAt: Date,
}, { timestamps: true });

export const Permission = mongoose.model('Permission', permissionSchema);
export const Role = mongoose.model('Role', roleSchema);
export const AdminUser = mongoose.model('AdminUser', adminUserSchema);
export const AdminSession = mongoose.model('AdminSession', adminSessionSchema);
export const AdminApproval = mongoose.model('AdminApproval', adminApprovalSchema);
export const NotificationCampaign = mongoose.model('NotificationCampaign', notificationCampaignSchema);
