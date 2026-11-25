import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';

const { Schema } = mongoose;

/**
 * Cards are issued/held by licensed issuers. We store ONLY the issuer's opaque
 * token and display metadata (brand, last 4, expiry). Raw PANs and CVVs never
 * reach our servers; sensitive display uses the issuer's secure display flow.
 */
const cardSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  kind: { type: String, enum: ['VIRTUAL', 'LINKED'], required: true },
  issuer: { type: String, required: true },
  providerCardToken: { type: String, required: true, select: false },
  brand: { type: String, enum: ['VISA', 'MASTERCARD', 'OTHER'], required: true },
  last4: { type: String, required: true, match: /^\d{4}$/ },
  expiryMonth: { type: Number, min: 1, max: 12, required: true },
  expiryYear: { type: Number, min: 2024, max: 2100, required: true },
  nameOnCard: { type: String, maxlength: 60 },
  nickname: { type: String, maxlength: 40 },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  status: { type: String, enum: ['ACTIVE', 'FROZEN', 'CLOSED'], default: 'ACTIVE' },
  frozenAt: Date,
  closedAt: Date,
  sandbox: { type: Boolean, default: false },
  controls: {
    perTransactionMinor: Number,
    dailyMinor: Number,
    monthlyMinor: Number,
    online: { type: Boolean, default: true },
    international: { type: Boolean, default: false },
    atm: { type: Boolean, default: true },
  },
}, { timestamps: true });
cardSchema.index({ userId: 1, status: 1 });

export const Card = mongoose.model('Card', cardSchema);
