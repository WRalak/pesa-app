import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';
import { appendOnly } from '../../lib/immutable.js';

const { Schema } = mongoose;
const minorInt = { type: Number, validate: { validator: Number.isSafeInteger, message: 'Integer minor units required' } };

/** Admin-configurable campaign. All reward rules live here, not in code. */
const rewardCampaignSchema = new Schema({
  code: { type: String, required: true, uppercase: true, match: /^[A-Z0-9_]{3,40}$/ },
  name: { type: String, required: true, maxlength: 80 },
  description: { type: String, maxlength: 500 },
  terms: { type: String, maxlength: 4000 },
  type: { type: String, enum: ['CASHBACK', 'POINTS', 'REFERRAL', 'PARTNER_DEAL'], required: true },
  status: { type: String, enum: ['DRAFT', 'ACTIVE', 'PAUSED', 'ENDED'], default: 'DRAFT' },
  country: { type: String, default: 'KE' },
  currency: { type: String, enum: CURRENCY_CODES, default: 'KES' },
  startsAt: { type: Date, required: true },
  endsAt: Date,
  rules: {
    transactionTypes: [String],
    categories: [String],
    minAmountMinor: { ...minorInt, default: 0 },
    cashbackBps: { type: Number, min: 0, max: 10_000, default: 0 },
    maxRewardMinor: minorInt,
    pointsPerUnit: { type: Number, min: 0, default: 0 }, // points per 1 major unit (e.g. per KES 100 when unitMinor=10000)
    unitMinor: { ...minorInt, default: 100_00 },
    perUserLimit: { type: Number, min: 0 },
    firstTransactionOnly: { type: Boolean, default: false },
    referrerPoints: { type: Number, min: 0, default: 0 },
    refereePoints: { type: Number, min: 0, default: 0 },
    referralQualifyingMinAmountMinor: { ...minorInt, default: 0 },
    maxReferralsPerReferrerPerMonth: { type: Number, default: 10 },
    holdDays: { type: Number, default: 7 },
  },
  totalBudgetMinor: minorInt,
  budgetUsedMinor: { ...minorInt, default: 0 },
  partner: { name: String, logoUrl: String, dealUrl: String, promoCode: String },
  createdBy: Schema.Types.ObjectId,
}, { timestamps: true });
rewardCampaignSchema.index({ code: 1 }, { unique: true });
rewardCampaignSchema.index({ status: 1, type: 1, startsAt: 1 });

/** Per-user running balances, updated atomically alongside ledger entries. */
const rewardAccountSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  points: { type: Number, default: 0, min: 0 },
  lifetimePoints: { type: Number, default: 0 },
  cashbackPendingMinor: { ...minorInt, default: 0 },
  cashbackAvailableMinor: { ...minorInt, default: 0 },
  currency: { type: String, enum: CURRENCY_CODES, default: 'KES' },
}, { timestamps: true });
rewardAccountSchema.index({ userId: 1 }, { unique: true });

/** Immutable reward ledger ("Rewards"). `dedupeKey` blocks duplicate claims. */
const rewardSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  campaignId: { type: Schema.Types.ObjectId, ref: 'RewardCampaign' },
  kind: { type: String, enum: ['POINTS', 'CASHBACK'], required: true },
  entryType: { type: String, enum: ['EARN', 'REDEEM', 'REVERSE', 'RELEASE', 'ADJUST'], required: true },
  points: { type: Number, default: 0 },
  amountMinor: { ...minorInt, default: 0 },
  currency: { type: String, enum: CURRENCY_CODES },
  sourceType: { type: String, enum: ['TRANSACTION', 'REFERRAL', 'PROMO', 'REDEMPTION', 'ADMIN'], required: true },
  sourceId: String,
  description: { type: String, maxlength: 140 },
  dedupeKey: { type: String, required: true },
  availableAt: Date,
  createdAt: { type: Date, default: Date.now },
}, { versionKey: false });
rewardSchema.index({ dedupeKey: 1 }, { unique: true });
rewardSchema.index({ userId: 1, createdAt: -1 });
rewardSchema.index({ campaignId: 1, userId: 1 });
rewardSchema.index({ kind: 1, entryType: 1, availableAt: 1 });
rewardSchema.plugin(appendOnly);

const referralSchema = new Schema({
  referrerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  refereeId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  campaignId: { type: Schema.Types.ObjectId, ref: 'RewardCampaign' },
  status: { type: String, enum: ['PENDING', 'QUALIFIED', 'REWARDED', 'REJECTED'], default: 'PENDING' },
  rejectionReason: String,
  fraudSignals: [String],
  qualifiedAt: Date,
  rewardedAt: Date,
}, { timestamps: true });
referralSchema.index({ refereeId: 1 }, { unique: true }); // a user can only ever be referred once
referralSchema.index({ referrerId: 1, createdAt: -1 });
referralSchema.index({ status: 1, createdAt: -1 });

export const RewardCampaign = mongoose.model('RewardCampaign', rewardCampaignSchema);
export const RewardAccount = mongoose.model('RewardAccount', rewardAccountSchema);
export const Reward = mongoose.model('Reward', rewardSchema);
export const Referral = mongoose.model('Referral', referralSchema);
