import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';

const { Schema } = mongoose;

const userSchema = new Schema({
  phone: { type: String, required: true, match: /^(\+[1-9]\d{7,14}|closed:[a-f\d]{24})$/ },
  phoneVerifiedAt: Date,
  email: { type: String, lowercase: true, trim: true, maxlength: 254 },
  emailVerifiedAt: Date,
  passwordHash: { type: String, required: true, select: false },
  passwordChangedAt: Date,
  pinHash: { type: String, select: false },
  pinSetAt: Date,
  pinFailedAttempts: { type: Number, default: 0 },
  pinLockedUntil: Date,
  status: { type: String, enum: ['PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'CLOSED'], default: 'PENDING_VERIFICATION', index: true },
  suspensionReason: String,
  restrictions: { type: [String], enum: ['NO_PAYMENTS', 'NO_WITHDRAWALS', 'NO_LOGIN', 'REVIEW_REQUIRED'], default: [] },
  country: { type: String, required: true, minlength: 2, maxlength: 2 },
  currency: { type: String, required: true, enum: CURRENCY_CODES },
  locale: { type: String, default: 'en-KE' },
  kycTier: { type: String, enum: ['TIER_0', 'TIER_1', 'TIER_2'], default: 'TIER_0' },
  kycStatus: { type: String, enum: ['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED'], default: 'NOT_STARTED', index: true },
  failedLoginAttempts: { type: Number, default: 0 },
  lockedUntil: Date,
  lastLoginAt: Date,
  lastLoginIp: String,
  lastLoginCountry: String,
  referralCode: { type: String, required: true },
  referredBy: { type: Schema.Types.ObjectId, ref: 'User' },
  consents: {
    termsVersion: String,
    termsAcceptedAt: Date,
    privacyAcceptedAt: Date,
    marketing: { type: Boolean, default: false },
    aiInsights: { type: Boolean, default: false },
    externalAiProcessing: { type: Boolean, default: false },
  },
  deletionRequestedAt: Date,
  closedAt: Date,
}, { timestamps: true });

userSchema.index({ phone: 1 }, { unique: true });
userSchema.index({ email: 1 }, { unique: true, partialFilterExpression: { email: { $type: 'string' } } });
userSchema.index({ referralCode: 1 }, { unique: true });
userSchema.index({ createdAt: -1 });
userSchema.index({ country: 1, status: 1, createdAt: -1 });

userSchema.methods.toPublic = function toPublic() {
  return {
    id: String(this._id),
    phone: this.phone,
    phoneVerified: Boolean(this.phoneVerifiedAt),
    email: this.email ?? null,
    emailVerified: Boolean(this.emailVerifiedAt),
    status: this.status,
    country: this.country,
    currency: this.currency,
    locale: this.locale,
    kycTier: this.kycTier,
    kycStatus: this.kycStatus,
    hasPin: Boolean(this.pinSetAt),
    referralCode: this.referralCode,
    restrictions: this.restrictions,
    consents: {
      marketing: this.consents?.marketing ?? false,
      aiInsights: this.consents?.aiInsights ?? false,
      externalAiProcessing: this.consents?.externalAiProcessing ?? false,
    },
    createdAt: this.createdAt,
  };
};

const notificationPrefsSchema = new Schema({
  push: { type: Boolean, default: true },
  email: { type: Boolean, default: true },
  sms: { type: Boolean, default: false },
  transactions: { type: Boolean, default: true },
  savings: { type: Boolean, default: true },
  budgets: { type: Boolean, default: true },
  security: { type: Boolean, default: true, immutable: true }, // security alerts cannot be disabled
  promotions: { type: Boolean, default: false },
}, { _id: false });

const userProfileSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  firstName: { type: String, trim: true, maxlength: 60 },
  lastName: { type: String, trim: true, maxlength: 60 },
  dateOfBirth: Date,
  avatarKey: String,
  address: {
    line1: { type: String, maxlength: 120 },
    city: { type: String, maxlength: 60 },
    region: { type: String, maxlength: 60 },
  },
  occupation: { type: String, maxlength: 80 },
  notificationPreferences: { type: notificationPrefsSchema, default: () => ({}) },
  privacy: {
    hideBalances: { type: Boolean, default: false },
    analyticsOptIn: { type: Boolean, default: false },
  },
  // User-chosen limits; always <= the regulatory limit for the user's KYC tier.
  transactionLimits: {
    perTransaction: Number,
    daily: Number,
  },
}, { timestamps: true });
userProfileSchema.index({ userId: 1 }, { unique: true });

const kycRecordSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  country: { type: String, required: true },
  idType: { type: String, required: true },
  idNumberEnc: { type: String, required: true, select: false }, // AES-256-GCM
  idNumberHash: { type: String, required: true }, // HMAC for duplicate detection
  idNumberLast4: String,
  fullName: { type: String, required: true },
  dateOfBirth: Date,
  status: { type: String, enum: ['PENDING', 'VERIFIED', 'REJECTED'], default: 'PENDING' },
  provider: { type: String, default: 'manual' },
  providerRef: String,
  documents: [{ type: { type: String }, storageKey: String, uploadedAt: Date }],
  reviewedBy: { type: Schema.Types.ObjectId, ref: 'AdminUser' },
  reviewedAt: Date,
  rejectionReason: String,
  tierGranted: String,
}, { timestamps: true });
kycRecordSchema.index({ userId: 1, createdAt: -1 });
kycRecordSchema.index({ status: 1, createdAt: 1 });
kycRecordSchema.index({ idNumberHash: 1, country: 1 });

export const User = mongoose.model('User', userSchema);
export const UserProfile = mongoose.model('UserProfile', userProfileSchema);
export const KycRecord = mongoose.model('KycRecord', kycRecordSchema);
