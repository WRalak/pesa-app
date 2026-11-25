import mongoose from 'mongoose';
import { Transaction, TransactionEvent, PaymentCallback, TRANSITIONS, TERMINAL } from './models.js';
import { resolveProvider, getAdapter, getProviderConfig } from './providers/registry.js';
import { ProviderUnavailableError } from './providers/base.js';
import { computeFee } from './fees.js';
import { assessRisk } from './risk.js';
import { withTransaction } from '../../lib/db.js';
import { Errors } from '../../lib/errors.js';
import { toMinor, money, add } from '../../lib/money.js';
import { normalizePhone } from '../../lib/phone.js';
import { randomToken } from '../../lib/crypto.js';
import { logger } from '../../lib/logger.js';
import { emitToUser } from '../../lib/realtime.js';
import { emitDomainEvent } from '../../lib/events.js';
import { enqueue, QUEUES, registerInlineHandler } from '../../lib/queue.js';
import { paymentCounter, callbackCounter } from '../../lib/metrics.js';
import { getCountry } from '../../config/countries/index.js';
import { UserProfile } from '../users/models.js';
import { verifyPin } from '../auth/service.js';
import { securityEvent } from '../audit/service.js';
import { categorize } from '../budgets/categorizer.js';
import { LinkedAccount } from '../accounts/models.js';

const CREDIT_TYPES = new Set(['DEPOSIT', 'RECEIVE_MONEY']);

export function newReference() {
  const d = new Date();
  const ymd = `${String(d.getUTCFullYear()).slice(2)}${String(d.getUTCMonth() + 1).padStart(2, '0')}${String(d.getUTCDate()).padStart(2, '0')}`;
  return `PSA${ymd}${randomToken(8).toUpperCase().replace(/[^A-Z0-9]/g, '7').slice(0, 8)}`;
}

export function startOfDayInTz(tz, date = new Date()) {
  const parts = Object.fromEntries(new Intl.DateTimeFormat('en-GB', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' })
    .formatToParts(date).filter((p) => p.type !== 'literal').map((p) => [p.type, Number(p.value)]));
  const asUtc = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second);
  const offset = asUtc - Math.floor(date.getTime() / 1000) * 1000;
  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day) - offset);
}

export function startOfMonthInTz(tz, date = new Date()) {
  const sod = startOfDayInTz(tz, date);
  const day = Number(new Intl.DateTimeFormat('en-GB', { timeZone: tz, day: 'numeric' }).format(date));
  return new Date(sod.getTime() - (day - 1) * 86_400_000);
}

// ------------------------------------------------------------------ serialization
export function serializeTransaction(t, { detail = false } = {}) {
  const out = {
    id: String(t._id),
    reference: t.reference,
    type: t.type,
    direction: t.direction,
    status: t.status,
    statusReason: t.statusReason ?? null,
    amount: money(t.amountMinor, t.currency),
    fee: money(t.feeMinor ?? 0, t.currency),
    total: money(t.totalMinor, t.currency),
    currency: t.currency,
    provider: t.provider,
    description: t.description ?? null,
    category: t.category,
    counterparty: {
      name: t.counterparty?.name ?? null,
      phone: t.counterparty?.phone ?? null,
      accountNumber: t.counterparty?.accountNumber ?? null,
      shortcode: t.counterparty?.shortcode ?? null,
      network: t.counterparty?.network ?? null,
      utilityCode: t.counterparty?.utilityCode ?? null,
    },
    externalRef: t.externalRef ?? null,
    createdAt: t.createdAt,
    completedAt: t.completedAt ?? null,
  };
  if (detail) {
    out.providerRequestId = t.providerRequestId ?? null;
    out.reversalRequested = Boolean(t.reversal?.requestedAt);
  }
  return out;
}

// ------------------------------------------------------------------ state machine
/**
 * The ONLY way a transaction's status changes. Atomically applies an allowed
 * transition and appends an immutable TransactionEvent in the same MongoDB
 * transaction. Idempotent: re-applying the current status is a no-op, and
 * disallowed transitions (e.g. FAILED -> SUCCESSFUL) are rejected.
 */
export async function transition(txnId, { to, source, reason, actorId, externalRef, set = {}, data, kind = 'STATUS_CHANGE' }) {
  const result = await withTransaction(async (session) => {
    const current = await Transaction.findById(txnId).session(session);
    if (!current) throw Errors.notFound('Transaction');
    if (current.status === to) return { txn: current, changed: false };
    if (!TRANSITIONS[current.status].includes(to)) {
      return { txn: current, changed: false, rejected: true, from: current.status };
    }
    const $set = { status: to, statusReason: reason ?? null, ...set };
    if (externalRef) $set.externalRef = externalRef;
    if (TERMINAL.includes(to)) $set.completedAt = new Date();
    const updated = await Transaction.findOneAndUpdate(
      { _id: txnId, status: current.status, version: current.version },
      { $set, $inc: { version: 1 } },
      { new: true, session },
    );
    if (!updated) throw Object.assign(new Error('Concurrent transaction update'), { errorLabels: ['TransientTransactionError'] });
    await TransactionEvent.create([{
      transactionId: current._id, userId: current.userId, fromStatus: current.status, toStatus: to,
      kind, source, actorId: actorId ? String(actorId) : undefined, reason, data,
    }], { session });
    return { txn: updated, changed: true, from: current.status };
  });

  if (result.rejected) {
    logger.warn({ txnId: String(txnId), from: result.from, to, source }, 'Rejected invalid transaction transition');
  }
  if (result.changed) await afterTransition(result.txn, result.from);
  return result;
}

async function afterTransition(txn, from) {
  paymentCounter.inc({ provider: txn.provider, type: txn.type, status: txn.status });
  emitToUser(String(txn.userId), 'transaction.updated', serializeTransaction(txn));
  if (TERMINAL.includes(txn.status)) {
    await emitDomainEvent(`transaction.${txn.status.toLowerCase()}`, { transaction: txn.toObject ? txn.toObject() : txn, from });
  }
}

async function appendEvent(txn, { kind, source, actorId, reason, data }) {
  await TransactionEvent.create({ transactionId: txn._id, userId: txn.userId, fromStatus: txn.status, toStatus: txn.status, kind, source, actorId: actorId ? String(actorId) : undefined, reason, data });
}

// ------------------------------------------------------------------ initiation
function buildCounterparty(user, input) {
  const country = getCountry(user.country);
  switch (input.type) {
    case 'SEND_MONEY': {
      if (!input.recipientPhone) throw Errors.validation([{ path: 'recipientPhone', message: 'Recipient phone number is required' }]);
      const { e164 } = normalizePhone(input.recipientPhone, user.country);
      return { phone: e164, name: input.recipientName };
    }
    case 'PAYBILL':
      if (!/^\d{5,7}$/.test(input.paybillNumber ?? '')) throw Errors.validation([{ path: 'paybillNumber', message: 'Enter a valid paybill number' }]);
      if (!input.accountNumber) throw Errors.validation([{ path: 'accountNumber', message: 'Account number is required' }]);
      return { shortcode: input.paybillNumber, accountNumber: input.accountNumber, name: input.recipientName };
    case 'BUY_GOODS':
      if (!/^\d{5,7}$/.test(input.tillNumber ?? '')) throw Errors.validation([{ path: 'tillNumber', message: 'Enter a valid till number' }]);
      return { shortcode: input.tillNumber, name: input.recipientName };
    case 'AIRTIME': {
      const { e164 } = normalizePhone(input.recipientPhone ?? user.phone, user.country);
      if (input.network && !country.mobileNetworks.includes(input.network)) throw Errors.validation([{ path: 'network', message: 'Unsupported network' }]);
      return { phone: e164, network: input.network };
    }
    case 'UTILITY': {
      const utility = country.utilities.find((u) => u.code === input.utilityCode);
      if (!utility) throw Errors.validation([{ path: 'utilityCode', message: 'Unknown biller' }]);
      if (!input.accountNumber) throw Errors.validation([{ path: 'accountNumber', message: 'Meter/account number is required' }]);
      return { utilityCode: utility.code, shortcode: utility.paybill, accountNumber: input.accountNumber, name: utility.name };
    }
    case 'DEPOSIT':
      return { phone: user.phone, name: 'Add money' };
    case 'BANK_TRANSFER':
      if (!input.bankCode || !input.accountNumber) throw Errors.validation([{ path: 'accountNumber', message: 'Bank and account number are required' }]);
      return { bankCode: input.bankCode, accountNumber: input.accountNumber, name: input.recipientName };
    default:
      throw Errors.validation([{ path: 'type', message: 'Unsupported payment type' }]);
  }
}

async function effectiveLimits(user) {
  const reg = getCountry(user.country).limits[user.kycTier];
  const profile = await UserProfile.findOne({ userId: user._id }, { transactionLimits: 1 }).lean();
  const custom = profile?.transactionLimits ?? {};
  return {
    perTransaction: Math.min(reg.perTransaction, custom.perTransaction ?? reg.perTransaction),
    daily: Math.min(reg.daily, custom.daily ?? reg.daily),
    monthly: reg.monthly,
  };
}

async function usedSince(userId, since) {
  const [row] = await Transaction.aggregate([
    { $match: { userId: new mongoose.Types.ObjectId(String(userId)), createdAt: { $gte: since }, direction: 'DEBIT', status: { $in: ['INITIATED', 'PENDING', 'PROCESSING', 'SUCCESSFUL'] } } },
    { $group: { _id: null, total: { $sum: '$totalMinor' } } },
  ]);
  return row?.total ?? 0;
}

export async function initiatePayment(user, input, req) {
  const country = getCountry(user.country);
  if (!country.paymentTypes.includes(input.type)) throw Errors.unprocessable('UNSUPPORTED_TYPE', 'This payment type is not available in your country');
  const currency = input.currency ?? user.currency;
  if (currency !== country.currency) throw Errors.unprocessable('UNSUPPORTED_CURRENCY', `Payments must be in ${country.currency}`);

  // 1. Strong customer authentication with the app's own transaction PIN.
  await verifyPin(user._id, input.pin, req);

  // 2. Amount, fees and limits — integer minor units throughout.
  const amountMinor = toMinor(input.amount, currency);
  if (amountMinor < country.minTransaction) throw Errors.unprocessable('AMOUNT_TOO_LOW', `Minimum amount is ${money(country.minTransaction, currency).amount} ${currency}`);
  const counterparty = buildCounterparty(user, input);
  const { adapter, cfg } = await resolveProvider({ requested: input.provider, type: input.type, currency, country: user.country });
  const feeMinor = computeFee(cfg, input.type, amountMinor);
  const totalMinor = add(amountMinor, feeMinor);
  const direction = CREDIT_TYPES.has(input.type) ? 'CREDIT' : 'DEBIT';

  const limits = await effectiveLimits(user);
  if (direction === 'DEBIT') {
    if (totalMinor > limits.perTransaction) throw Errors.unprocessable('LIMIT_EXCEEDED', `This exceeds your per-transaction limit of ${money(limits.perTransaction, currency).amount} ${currency}`, { limit: 'perTransaction' });
    const [daily, monthly] = await Promise.all([
      usedSince(user._id, startOfDayInTz(country.timezone)),
      usedSince(user._id, startOfMonthInTz(country.timezone)),
    ]);
    if (daily + totalMinor > limits.daily) throw Errors.unprocessable('LIMIT_EXCEEDED', 'This exceeds your daily limit', { limit: 'daily', remaining: money(Math.max(0, limits.daily - daily), currency) });
    if (monthly + totalMinor > limits.monthly) throw Errors.unprocessable('LIMIT_EXCEEDED', 'This exceeds your monthly limit', { limit: 'monthly' });
  }

  // 3. Duplicate-payment guard (same payee + amount within 2 minutes).
  if (!input.confirmDuplicate) {
    const dup = await Transaction.findOne({
      userId: user._id, type: input.type, amountMinor, status: { $in: ['INITIATED', 'PENDING', 'PROCESSING', 'SUCCESSFUL'] },
      createdAt: { $gte: new Date(Date.now() - 120_000) },
      ...(counterparty.phone ? { 'counterparty.phone': counterparty.phone } : {}),
      ...(counterparty.shortcode ? { 'counterparty.shortcode': counterparty.shortcode } : {}),
      ...(counterparty.accountNumber ? { 'counterparty.accountNumber': counterparty.accountNumber } : {}),
    }, { reference: 1 }).lean();
    if (dup) throw Errors.conflict('You made an identical payment moments ago. Confirm to send it again.', 'POSSIBLE_DUPLICATE');
  }

  // 4. Risk rules.
  const risk = await assessRisk({ user, amountMinor, counterparty, deviceId: req.user?.deviceId, limits });
  if (risk.block) {
    await securityEvent({ userId: user._id, type: 'FRAUD_FLAG', severity: 'HIGH', details: { flags: risk.flags, amountMinor } }, req);
    throw Errors.unprocessable('PAYMENT_BLOCKED', 'This payment could not be processed for your security. Please contact support.');
  }

  let sourceAccountId;
  if (input.sourceAccountId) {
    const acct = await LinkedAccount.findOne({ _id: input.sourceAccountId, userId: user._id, status: 'ACTIVE' }, { _id: 1 }).lean();
    if (!acct) throw Errors.notFound('Account');
    sourceAccountId = acct._id;
  }

  const description = input.description ?? defaultDescription(input.type, counterparty);
  const cat = categorize({ type: input.type, description, counterparty });

  // 5. Persist INITIATED + first event atomically. The unique (userId, idempotencyKey)
  //    index is the last line of defence against duplicate submission.
  let txn;
  try {
    txn = await withTransaction(async (session) => {
      const [created] = await Transaction.create([{
        reference: newReference(), userId: user._id, type: input.type, direction,
        amountMinor, feeMinor, totalMinor, currency, provider: adapter.code,
        description, category: cat.category, categorySource: cat.source, counterparty, sourceAccountId,
        idempotencyKey: input.idempotencyKey, deviceId: req.user?.deviceId, ip: req.ip,
        risk: { score: risk.score, flags: risk.flags, reviewRequired: risk.reviewRequired },
      }], { session });
      await TransactionEvent.create([{ transactionId: created._id, userId: user._id, fromStatus: null, toStatus: 'INITIATED', source: 'USER', actorId: String(user._id), data: { riskFlags: risk.flags } }], { session });
      return created;
    });
  } catch (err) {
    if (err?.code === 11000 && String(err.message).includes('idempotencyKey')) {
      const existing = await Transaction.findOne({ userId: user._id, idempotencyKey: input.idempotencyKey });
      return { transaction: serializeTransaction(existing, { detail: true }), replayed: true };
    }
    throw err;
  }
  if (risk.reviewRequired) {
    await securityEvent({ userId: user._id, type: 'FRAUD_FLAG', severity: 'MEDIUM', details: { transactionId: String(txn._id), flags: risk.flags } }, req);
  }

  // 6. Submit to the provider. Its response only tells us the request was
  //    accepted — success is established exclusively by a verified callback,
  //    a provider status query, or reconciliation.
  let customerMessage;
  try {
    const res = await adapter.initiate(txn, { payerPhone: user.phone, user });
    customerMessage = res.customerMessage;
    if (res.accepted) {
      ({ txn } = await transition(txn._id, { to: 'PENDING', source: 'SYSTEM', set: { providerRequestId: res.providerRequestId }, data: { providerRequestId: res.providerRequestId } }));
    } else {
      ({ txn } = await transition(txn._id, { to: 'FAILED', source: 'SYSTEM', reason: res.reason ?? 'Rejected by provider' }));
    }
  } catch (err) {
    if (err instanceof ProviderUnavailableError && err.outcomeUnknown) {
      // We cannot know if the provider acted. Never assume failure or success.
      ({ txn } = await transition(txn._id, { to: 'PENDING', source: 'SYSTEM', reason: 'PROVIDER_OUTCOME_UNKNOWN', set: { 'risk.reviewRequired': true } }));
    } else {
      logger.error({ err: err.message, reference: txn.reference }, 'Provider initiation failed');
      ({ txn } = await transition(txn._id, { to: 'FAILED', source: 'SYSTEM', reason: 'Payment provider unavailable' }));
    }
  }
  return { transaction: serializeTransaction(txn, { detail: true }), customerMessage: customerMessage ?? null };
}

function defaultDescription(type, cp) {
  switch (type) {
    case 'SEND_MONEY': return `Sent to ${cp.name ?? cp.phone}`;
    case 'PAYBILL': return `Paybill ${cp.shortcode} · ${cp.accountNumber}`;
    case 'BUY_GOODS': return `Till ${cp.shortcode}${cp.name ? ` · ${cp.name}` : ''}`;
    case 'AIRTIME': return `Airtime for ${cp.phone}`;
    case 'UTILITY': return `${cp.name} · ${cp.accountNumber}`;
    case 'DEPOSIT': return 'Add money';
    case 'BANK_TRANSFER': return `Bank transfer · ${cp.accountNumber}`;
    default: return type;
  }
}

// ------------------------------------------------------------------ callbacks
export async function processCallback(providerCode, req) {
  const adapter = getAdapter(providerCode);
  const parsed = await adapter.parseCallback(req);

  if (!parsed.verified || !parsed.dedupeKey) {
    callbackCounter.inc({ provider: providerCode, outcome: 'rejected' });
    await PaymentCallback.create({
      provider: providerCode, dedupeKey: `rejected:${randomToken(12)}`, signatureValid: false, sourceIp: req.ip,
      payload: parsed.sanitizedPayload, processingStatus: 'REJECTED', processingNote: 'Signature/source verification failed',
    });
    await securityEvent({ type: 'CALLBACK_REJECTED', severity: 'HIGH', details: { provider: providerCode, ip: req.ip } }, req);
    throw Errors.unauthorized('Callback verification failed', 'CALLBACK_REJECTED');
  }

  let record;
  try {
    record = await PaymentCallback.create({
      provider: providerCode, dedupeKey: parsed.dedupeKey, signatureValid: true, sourceIp: req.ip,
      providerRequestId: parsed.providerRequestId, externalRef: parsed.externalRef, outcome: parsed.outcome, payload: parsed.sanitizedPayload,
    });
  } catch (err) {
    if (err?.code === 11000) {
      callbackCounter.inc({ provider: providerCode, outcome: 'duplicate' });
      return { ack: parsed.ack, status: 'DUPLICATE' };
    }
    throw err;
  }

  try {
    const status = await applyCallback(adapter, parsed, record);
    await PaymentCallback.updateOne({ _id: record._id }, { $set: { processingStatus: status.processingStatus, processingNote: status.note, transactionId: status.transactionId } });
    callbackCounter.inc({ provider: providerCode, outcome: status.processingStatus.toLowerCase() });
    return { ack: parsed.ack, status: status.processingStatus };
  } catch (err) {
    await PaymentCallback.updateOne({ _id: record._id }, { $set: { processingStatus: 'ERROR', processingNote: err.message.slice(0, 200) } });
    throw err;
  }
}

async function applyCallback(adapter, parsed, record) {
  const lookup = parsed.outcome === 'REVERSED'
    ? { provider: adapter.code, $or: [{ 'reversal.providerRequestId': parsed.reversalRequestId ?? parsed.providerRequestId }, { providerRequestId: parsed.providerRequestId }] }
    : { provider: adapter.code, providerRequestId: parsed.providerRequestId };
  const txn = await Transaction.findOne(lookup);
  if (!txn) return { processingStatus: 'ORPHANED', note: 'No matching transaction; flagged for reconciliation' };
  const base = { transactionId: txn._id };
  const data = { callbackId: String(record._id) };

  if (parsed.amountMinor !== undefined && parsed.amountMinor !== txn.amountMinor && parsed.outcome !== 'FAILED') {
    await Transaction.updateOne({ _id: txn._id }, { $set: { 'risk.reviewRequired': true }, $addToSet: { 'risk.flags': 'AMOUNT_MISMATCH' } });
    await appendEvent(txn, { kind: 'FLAGGED', source: 'PROVIDER_CALLBACK', reason: 'AMOUNT_MISMATCH', data: { ...data, providerAmountMinor: parsed.amountMinor } });
    await securityEvent({ userId: txn.userId, type: 'FRAUD_FLAG', severity: 'CRITICAL', details: { reason: 'AMOUNT_MISMATCH', reference: txn.reference } });
    if (txn.status === 'PENDING') await transition(txn._id, { to: 'PROCESSING', source: 'PROVIDER_CALLBACK', reason: 'Under review: amount mismatch', data });
    return { ...base, processingStatus: 'APPLIED', note: 'Amount mismatch — held for review' };
  }

  switch (parsed.outcome) {
    case 'SUCCESS':
      if (adapter.capabilities.confirmCallbacksByQuery) {
        const r = await transition(txn._id, { to: 'PROCESSING', source: 'PROVIDER_CALLBACK', externalRef: parsed.externalRef, reason: 'Awaiting provider confirmation', data });
        await enqueue(QUEUES.payments, 'confirm-status', { transactionId: String(txn._id) }, { jobId: `confirm-${txn._id}`, delay: 2000 });
        return { ...base, processingStatus: r.rejected ? 'IGNORED' : 'APPLIED', note: 'Pending confirmation by status query' };
      } else {
        const r = await transition(txn._id, { to: 'SUCCESSFUL', source: 'PROVIDER_CALLBACK', externalRef: parsed.externalRef, data });
        return { ...base, processingStatus: r.rejected ? 'IGNORED' : 'APPLIED', note: r.rejected ? `Cannot move ${r.from} to SUCCESSFUL` : undefined };
      }
    case 'FAILED': {
      const r = await transition(txn._id, { to: 'FAILED', source: 'PROVIDER_CALLBACK', reason: parsed.reason ?? 'Payment failed', data });
      return { ...base, processingStatus: r.rejected ? 'IGNORED' : 'APPLIED', note: r.rejected ? `Cannot move ${r.from} to FAILED` : undefined };
    }
    case 'REVERSED': {
      const r = await transition(txn._id, { to: 'REVERSED', source: 'PROVIDER_CALLBACK', reason: parsed.reason ?? 'Reversed by provider', data });
      return { ...base, processingStatus: r.rejected ? 'IGNORED' : 'APPLIED' };
    }
    default:
      return { ...base, processingStatus: 'IGNORED', note: 'Unrecognised outcome' };
  }
}

// ------------------------------------------------------------------ status queries
/** Asks the provider for the authoritative status of a non-terminal transaction. */
export async function checkTransactionStatus(transactionId, { source = 'STATUS_QUERY' } = {}) {
  const txn = await Transaction.findById(transactionId);
  if (!txn || TERMINAL.includes(txn.status) || !txn.providerRequestId) return txn;
  const adapter = getAdapter(txn.provider);
  if (!adapter.capabilities.statusQuery) return txn;
  await Transaction.updateOne({ _id: txn._id }, { $set: { lastStatusCheckAt: new Date() }, $inc: { statusChecks: 1 } });
  const res = await adapter.queryStatus(txn);
  if (res.amountMinor !== undefined && res.amountMinor !== txn.amountMinor) {
    await Transaction.updateOne({ _id: txn._id }, { $set: { 'risk.reviewRequired': true }, $addToSet: { 'risk.flags': 'AMOUNT_MISMATCH' } });
    return txn;
  }
  if (res.outcome === 'SUCCESS') return (await transition(txn._id, { to: 'SUCCESSFUL', source, externalRef: res.externalRef ?? txn.externalRef })).txn;
  if (res.outcome === 'FAILED') return (await transition(txn._id, { to: 'FAILED', source, reason: res.reason ?? 'Payment failed' })).txn;
  return txn;
}

/** Periodic job: resolve stale PENDING/PROCESSING transactions via status queries. */
export async function sweepPending({ olderThanMs = 60_000, batch = 200 } = {}) {
  const cutoff = new Date(Date.now() - olderThanMs);
  const stale = await Transaction.find({
    status: { $in: ['PENDING', 'PROCESSING'] }, updatedAt: { $lt: cutoff }, providerRequestId: { $type: 'string' },
    statusChecks: { $lt: 30 },
  }, { _id: 1 }).sort({ updatedAt: 1 }).limit(batch).lean();
  let resolved = 0;
  for (const { _id } of stale) {
    try {
      const t = await checkTransactionStatus(_id);
      if (t && TERMINAL.includes(t.status)) resolved++;
    } catch (err) {
      logger.warn({ err: err.message, txn: String(_id) }, 'Status check failed');
    }
  }
  // Escalate anything stuck for over 24h to manual review instead of guessing.
  await Transaction.updateMany(
    { status: { $in: ['PENDING', 'PROCESSING', 'INITIATED'] }, createdAt: { $lt: new Date(Date.now() - 24 * 3600_000) }, 'risk.reviewRequired': { $ne: true } },
    { $set: { 'risk.reviewRequired': true }, $addToSet: { 'risk.flags': 'STUCK_PENDING' } },
  );
  return { checked: stale.length, resolved };
}

// ------------------------------------------------------------------ reversals
export async function requestReversal(transactionId, { reason, adminId }) {
  const txn = await Transaction.findById(transactionId);
  if (!txn) throw Errors.notFound('Transaction');
  if (txn.status !== 'SUCCESSFUL') throw Errors.unprocessable('NOT_REVERSIBLE', 'Only successful transactions can be reversed');
  if (txn.reversal?.requestedAt) throw Errors.conflict('A reversal has already been requested', 'REVERSAL_EXISTS');
  const adapter = getAdapter(txn.provider);
  if (!adapter.capabilities.reversal) throw Errors.unprocessable('NOT_REVERSIBLE', 'Provider does not support reversals');
  const res = await adapter.reverse(txn, reason);
  if (!res.accepted) throw Errors.unprocessable('REVERSAL_REJECTED', res.reason ?? 'Provider rejected the reversal');
  await Transaction.updateOne({ _id: txn._id }, { $set: { reversal: { requestedAt: new Date(), requestedBy: adminId, reason, providerRequestId: res.providerRequestId } } });
  await appendEvent(txn, { kind: 'REVERSAL_REQUESTED', source: 'ADMIN', actorId: adminId, reason, data: { providerRequestId: res.providerRequestId } });
  // Status changes to REVERSED only when the provider confirms via callback/reconciliation.
  return Transaction.findById(txn._id).lean();
}

// ------------------------------------------------------------------ queue handlers
registerInlineHandler(QUEUES.payments, 'confirm-status', (job) => checkTransactionStatus(job.data.transactionId));

export async function deliverMockCallback({ providerRequestId }) {
  const { signMockPayload } = await import('./providers/mock.js');
  const adapter = getAdapter('mock');
  const body = await adapter.buildCallback(providerRequestId);
  if (!body) return;
  const raw = Buffer.from(JSON.stringify(body));
  const fakeReq = { body, rawBody: raw, ip: '127.0.0.1', params: {}, get: (h) => (h.toLowerCase() === 'x-callback-signature' ? signMockPayload(raw) : undefined) };
  await processCallback('mock', fakeReq);
}

export { getProviderConfig };
