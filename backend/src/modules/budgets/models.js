import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';

const { Schema } = mongoose;
const minorInt = { type: Number, validate: { validator: Number.isSafeInteger, message: 'Amounts must be integer minor units' } };

const budgetSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true, maxlength: 60 },
  period: { type: String, enum: ['WEEKLY', 'MONTHLY'], required: true },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  totalLimitMinor: { ...minorInt, min: 0 },
  categories: [{ category: { type: String, required: true }, limitMinor: { ...minorInt, required: true, min: 0 }, _id: false }],
  alertThresholds: { type: [Number], default: [80, 100] },
  alertsSent: { type: [String], default: [], select: false },
  active: { type: Boolean, default: true },
}, { timestamps: true });
budgetSchema.index({ userId: 1, active: 1, period: 1 });

const entrySchema = (extra = {}) => new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  amountMinor: { ...minorInt, required: true, min: 1 },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  category: { type: String, required: true, maxlength: 40 },
  description: { type: String, trim: true, maxlength: 140 },
  date: { type: Date, required: true },
  recurringItemId: { type: Schema.Types.ObjectId, ref: 'RecurringItem' },
  ...extra,
}, { timestamps: true });

const expenseSchema = entrySchema({ paymentMethod: { type: String, enum: ['CASH', 'MOBILE_MONEY', 'CARD', 'BANK', 'OTHER'], default: 'CASH' } });
expenseSchema.index({ userId: 1, date: -1 });
expenseSchema.index({ userId: 1, category: 1, date: -1 });

const incomeSchema = entrySchema();
incomeSchema.index({ userId: 1, date: -1 });

const recurringItemSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  kind: { type: String, enum: ['EXPENSE', 'INCOME'], required: true },
  amountMinor: { ...minorInt, required: true, min: 1 },
  currency: { type: String, enum: CURRENCY_CODES, required: true },
  category: { type: String, required: true },
  description: { type: String, maxlength: 140 },
  frequency: { type: String, enum: ['WEEKLY', 'MONTHLY'], required: true },
  nextRunAt: { type: Date, required: true },
  active: { type: Boolean, default: true },
}, { timestamps: true });
recurringItemSchema.index({ active: 1, nextRunAt: 1 });
recurringItemSchema.index({ userId: 1, active: 1 });

export const Budget = mongoose.model('Budget', budgetSchema);
export const Expense = mongoose.model('Expense', expenseSchema);
export const IncomeRecord = mongoose.model('IncomeRecord', incomeSchema);
export const RecurringItem = mongoose.model('RecurringItem', recurringItemSchema);
