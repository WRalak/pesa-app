import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';

const { Schema } = mongoose;

/**
 * A financial account the user connected (M-Pesa wallet, bank account) or
 * tracks manually. `balanceSource` makes provenance explicit so the UI never
 * presents a manual or estimated figure as a verified balance.
 */
const linkedAccountSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  kind: { type: String, enum: ['MOBILE_MONEY', 'BANK', 'CASH', 'SACCO', 'OTHER'], required: true },
  provider: { type: String, required: true }, // e.g. mpesa, equity, manual
  displayName: { type: String, required: true, maxlength: 60 },
  maskedIdentifier: { type: String, maxlength: 32 },
  providerAccountToken: { type: String, select: false }, // opaque token from aggregator
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  balanceMinor: { type: Number, validate: Number.isSafeInteger },
  balanceSource: { type: String, enum: ['PROVIDER_VERIFIED', 'MANUAL', 'UNAVAILABLE'], required: true },
  balanceAsOf: Date,
  sandbox: { type: Boolean, default: false },
  status: { type: String, enum: ['ACTIVE', 'REQUIRES_REAUTH', 'UNLINKED'], default: 'ACTIVE' },
  isDefault: { type: Boolean, default: false },
  consentExpiresAt: Date,
}, { timestamps: true });
linkedAccountSchema.index({ userId: 1, status: 1 });
linkedAccountSchema.index({ userId: 1, provider: 1, maskedIdentifier: 1 }, { unique: true, partialFilterExpression: { status: { $in: ['ACTIVE', 'REQUIRES_REAUTH'] } } });

export const LinkedAccount = mongoose.model('LinkedAccount', linkedAccountSchema);
