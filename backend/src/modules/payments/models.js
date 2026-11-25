import mongoose from 'mongoose';
import { CURRENCY_CODES } from '../../config/currencies.js';
import { appendOnly } from '../../lib/immutable.js';

const { Schema } = mongoose;

export const TX_STATUSES = ['INITIATED', 'PENDING', 'PROCESSING', 'SUCCESSFUL', 'FAILED', 'REVERSED'];
export const TX_TYPES = ['SEND_MONEY', 'RECEIVE_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT', 'CARD_PAYMENT', 'BANK_TRANSFER'];
export const TERMINAL = ['SUCCESSFUL', 'FAILED', 'REVERSED'];

/** Allowed state machine transitions. Anything else is rejected. */
export const TRANSITIONS = {
  INITIATED: ['PENDING', 'PROCESSING', 'FAILED'],
  PENDING: ['PROCESSING', 'SUCCESSFUL', 'FAILED'],
  PROCESSING: ['SUCCESSFUL', 'FAILED'],
  SUCCESSFUL: ['REVERSED'],
  FAILED: [],
  REVERSED: [],
};

const minorInt = { type: Number, validate: { validator: Number.isSafeInteger, message: 'Amounts must be integer minor units' } };

const paymentProviderSchema = new Schema({
  code: { type: String, required: true },
  name: { type: String, required: true },
  kind: { type: String, enum: ['MOBILE_MONEY', 'BANK', 'AGGREGATOR', 'CARD_ISSUER'], required: true },
  countries: [String],
  currencies: [{ type: String, enum: CURRENCY_CODES }],
  supportedTypes: [{ type: String, enum: TX_TYPES }],
  enabled: { type: Boolean, default: true },
  maintenance: { type: Boolean, default: false },
  sandbox: { type: Boolean, default: true },
  priority: { type: Number, default: 100 },
  // Fees are configuration, never code. bps = basis points of the amount.
  fees: [{
    type: { type: String, enum: TX_TYPES },
    minAmountMinor: { ...minorInt, default: 0 },
    maxAmountMinor: { ...minorInt, default: Number.MAX_SAFE_INTEGER },
    fixedMinor: { ...minorInt, default: 0 },
    bps: { type: Number, default: 0 },
    _id: false,
  }],
}, { timestamps: true });
paymentProviderSchema.index({ code: 1 }, { unique: true });

const counterpartySchema = new Schema({
  name: { type: String, maxlength: 120 },
  phone: String, // E.164
  accountNumber: { type: String, maxlength: 64 },
  shortcode: { type: String, maxlength: 20 }, // paybill / till
  network: String,
  utilityCode: String,
  bankCode: String,
}, { _id: false });

const transactionSchema = new Schema({
  reference: { type: String, required: true, immutable: true },
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, immutable: true },
  type: { type: String, enum: TX_TYPES, required: true, immutable: true },
  direction: { type: String, enum: ['DEBIT', 'CREDIT'], required: true, immutable: true },
  amountMinor: { ...minorInt, required: true, immutable: true, min: 1 },
  feeMinor: { ...minorInt, default: 0, immutable: true, min: 0 },
  totalMinor: { ...minorInt, required: true, immutable: true },
  currency: { type: String, enum: CURRENCY_CODES, required: true, immutable: true },
  provider: { type: String, required: true, immutable: true },
  status: { type: String, enum: TX_STATUSES, default: 'INITIATED', required: true },
  statusReason: String,
  description: { type: String, maxlength: 140 },
  category: { type: String, maxlength: 40, default: 'uncategorised' },
  categorySource: { type: String, enum: ['RULE', 'USER', 'AI', 'DEFAULT'], default: 'DEFAULT' },
  counterparty: { type: counterpartySchema, default: () => ({}) },
  sourceAccountId: { type: Schema.Types.ObjectId, ref: 'LinkedAccount' },
  cardId: { type: Schema.Types.ObjectId, ref: 'Card' },
  idempotencyKey: { type: String, required: true, immutable: true },
  providerRequestId: String, // e.g. Daraja CheckoutRequestID
  externalRef: String, // provider receipt, e.g. M-Pesa receipt number
  channel: { type: String, enum: ['APP', 'USSD', 'API', 'SYSTEM'], default: 'APP' },
  deviceId: String,
  ip: String,
  risk: {
    score: { type: Number, default: 0 },
    flags: [String],
    reviewRequired: { type: Boolean, default: false },
  },
  reversal: {
    requestedAt: Date,
    requestedBy: Schema.Types.ObjectId,
    reason: String,
    providerRequestId: String,
  },
  initiatedAt: { type: Date, default: Date.now, immutable: true },
  completedAt: Date,
  lastStatusCheckAt: Date,
  statusChecks: { type: Number, default: 0 },
  version: { type: Number, default: 0 },
}, { timestamps: true, versionKey: false });

transactionSchema.index({ reference: 1 }, { unique: true });
transactionSchema.index({ userId: 1, idempotencyKey: 1 }, { unique: true });
transactionSchema.index({ userId: 1, createdAt: -1, _id: -1 });
transactionSchema.index({ userId: 1, status: 1, createdAt: -1 });
transactionSchema.index({ userId: 1, type: 1, createdAt: -1 });
transactionSchema.index({ userId: 1, category: 1, createdAt: -1 });
transactionSchema.index({ provider: 1, providerRequestId: 1 }, { unique: true, partialFilterExpression: { providerRequestId: { $type: 'string' } } });
transactionSchema.index({ provider: 1, externalRef: 1 }, { unique: true, partialFilterExpression: { externalRef: { $type: 'string' } } });
transactionSchema.index({ status: 1, updatedAt: 1 }); // pending sweeper
transactionSchema.index({ cardId: 1, createdAt: -1 }, { partialFilterExpression: { cardId: { $exists: true } } });
transactionSchema.index({ createdAt: -1, status: 1 }); // admin dashboards
transactionSchema.index({ 'risk.reviewRequired': 1, createdAt: -1 }, { partialFilterExpression: { 'risk.reviewRequired': true } });

// Transactions are never deleted.
for (const op of ['deleteOne', 'deleteMany', 'findOneAndDelete']) {
  transactionSchema.pre(op, { document: false, query: true }, () => { throw new Error('Transactions cannot be deleted'); });
}

const transactionEventSchema = new Schema({
  transactionId: { type: Schema.Types.ObjectId, ref: 'Transaction', required: true },
  userId: { type: Schema.Types.ObjectId, required: true },
  fromStatus: { type: String, enum: [...TX_STATUSES, null] },
  toStatus: { type: String, enum: TX_STATUSES },
  kind: { type: String, enum: ['STATUS_CHANGE', 'REVERSAL_REQUESTED', 'FLAGGED', 'NOTE', 'CATEGORY_CHANGED'], default: 'STATUS_CHANGE' },
  source: { type: String, enum: ['USER', 'PROVIDER_CALLBACK', 'STATUS_QUERY', 'RECONCILIATION', 'ADMIN', 'SYSTEM'], required: true },
  actorId: String,
  reason: String,
  data: Schema.Types.Mixed,
  createdAt: { type: Date, default: Date.now },
}, { versionKey: false });
transactionEventSchema.index({ transactionId: 1, createdAt: 1 });
transactionEventSchema.plugin(appendOnly);

const paymentCallbackSchema = new Schema({
  provider: { type: String, required: true },
  dedupeKey: { type: String, required: true },
  signatureValid: { type: Boolean, required: true },
  sourceIp: String,
  providerRequestId: String,
  externalRef: String,
  outcome: String,
  payload: Schema.Types.Mixed, // sanitised; never contains customer secrets
  processingStatus: { type: String, enum: ['RECEIVED', 'APPLIED', 'DUPLICATE', 'ORPHANED', 'REJECTED', 'IGNORED', 'ERROR'], default: 'RECEIVED' },
  processingNote: String,
  transactionId: { type: Schema.Types.ObjectId, ref: 'Transaction' },
}, { timestamps: { createdAt: 'receivedAt', updatedAt: true } });
paymentCallbackSchema.index({ provider: 1, dedupeKey: 1 }, { unique: true });
paymentCallbackSchema.index({ processingStatus: 1, receivedAt: -1 });
paymentCallbackSchema.index({ transactionId: 1 });
paymentCallbackSchema.index({ receivedAt: -1 });

const reconciliationRecordSchema = new Schema({
  runId: { type: String, required: true },
  provider: { type: String, required: true },
  windowStart: Date,
  windowEnd: Date,
  transactionId: { type: Schema.Types.ObjectId, ref: 'Transaction' },
  reference: String,
  externalRef: String,
  internalStatus: String,
  providerStatus: String,
  internalAmountMinor: Number,
  providerAmountMinor: Number,
  currency: String,
  result: { type: String, enum: ['MATCHED', 'AUTO_RESOLVED', 'STATUS_MISMATCH', 'AMOUNT_MISMATCH', 'MISSING_INTERNAL', 'MISSING_AT_PROVIDER'], required: true },
  resolution: { type: String, enum: ['OPEN', 'RESOLVED', 'ESCALATED', 'NOT_REQUIRED'], default: 'OPEN' },
  resolutionNote: String,
  resolvedBy: Schema.Types.ObjectId,
  resolvedAt: Date,
}, { timestamps: true });
reconciliationRecordSchema.index({ runId: 1 });
reconciliationRecordSchema.index({ provider: 1, result: 1, createdAt: -1 });
reconciliationRecordSchema.index({ resolution: 1, createdAt: -1 });

/** Sandbox-only ledger representing what the mock provider "processed". */
const mockLedgerSchema = new Schema({
  providerRequestId: { type: String, required: true, unique: true },
  externalRef: String,
  amountMinor: Number,
  currency: String,
  status: { type: String, enum: ['PENDING', 'SUCCESS', 'FAILED', 'REVERSED'] },
  reason: String,
}, { timestamps: true });

export const PaymentProvider = mongoose.model('PaymentProvider', paymentProviderSchema);
export const Transaction = mongoose.model('Transaction', transactionSchema);
export const TransactionEvent = mongoose.model('TransactionEvent', transactionEventSchema);
export const PaymentCallback = mongoose.model('PaymentCallback', paymentCallbackSchema);
export const ReconciliationRecord = mongoose.model('ReconciliationRecord', reconciliationRecordSchema);
export const MockProviderLedger = mongoose.model('MockProviderLedger', mockLedgerSchema);
