import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';
import { appendOnly } from '../../lib/immutable.js';

const { Schema } = mongoose;
const minorInt = { type: Number, validate: { validator: Number.isSafeInteger, message: 'Amounts must be integer minor units' } };

/**
 * Savings goals are TRACKING tools in the initial release: they record what the
 * user reports setting aside. Custody of funds belongs to an authorised partner
 * (e.g. a bank or licensed SACCO) once integrated; `custody` makes this explicit.
 */
const savingsGoalSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true, maxlength: 60 },
  category: { type: String, enum: ['EMERGENCY', 'RENT', 'EDUCATION', 'BUSINESS', 'TRAVEL', 'ELECTRONICS', 'HOME', 'HEALTH', 'OTHER'], default: 'OTHER' },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  targetMinor: { ...minorInt, required: true, min: 1 },
  savedMinor: { ...minorInt, default: 0, min: 0 },
  deadline: Date,
  status: { type: String, enum: ['ACTIVE', 'COMPLETED', 'ARCHIVED'], default: 'ACTIVE' },
  completedAt: Date,
  archivedAt: Date,
  color: { type: String, match: /^#[0-9A-Fa-f]{6}$/ },
  icon: { type: String, maxlength: 40 },
  custody: { type: String, enum: ['TRACKING_ONLY', 'PARTNER'], default: 'TRACKING_ONLY' },
  reminder: {
    frequency: { type: String, enum: ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY'], default: 'NONE' },
    amountMinor: minorInt,
    nextAt: Date,
  },
}, { timestamps: true });
savingsGoalSchema.index({ userId: 1, status: 1, createdAt: -1 });
savingsGoalSchema.index({ 'reminder.nextAt': 1 }, { partialFilterExpression: { status: 'ACTIVE' } });

const savingsContributionSchema = new Schema({
  goalId: { type: Schema.Types.ObjectId, ref: 'SavingsGoal', required: true },
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  kind: { type: String, enum: ['CONTRIBUTION', 'WITHDRAWAL'], required: true },
  amountMinor: { ...minorInt, required: true, min: 1 },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  note: { type: String, maxlength: 140 },
  source: { type: String, enum: ['MANUAL', 'TRANSACTION'], default: 'MANUAL' },
  transactionId: { type: Schema.Types.ObjectId, ref: 'Transaction' },
  balanceAfterMinor: minorInt,
  createdAt: { type: Date, default: Date.now },
}, { versionKey: false });
savingsContributionSchema.index({ goalId: 1, createdAt: -1 });
savingsContributionSchema.index({ userId: 1, createdAt: -1 });
savingsContributionSchema.plugin(appendOnly);

export const SavingsGoal = mongoose.model('SavingsGoal', savingsGoalSchema);
export const SavingsContribution = mongoose.model('SavingsContribution', savingsContributionSchema);
