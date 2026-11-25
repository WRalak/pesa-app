import crypto from 'node:crypto';
import { PaymentProviderAdapter } from './base.js';
import { MockProviderLedger } from '../models.js';
import { config } from '../../../config/env.js';
import { randomToken, timingSafeEqualStr } from '../../../lib/crypto.js';
import { enqueue, QUEUES } from '../../../lib/queue.js';

/**
 * SANDBOX ONLY. Simulates an asynchronous mobile-money provider with signed
 * webhooks so the full payment lifecycle can be exercised without moving
 * real money. Refused in production by env.js.
 *
 * Deterministic test amounts (by the minor-unit remainder modulo 100):
 *   ..01 -> FAILED (insufficient funds)
 *   ..02 -> no callback (exercise status query / reconciliation path)
 *   ..03 -> FAILED (cancelled by user)
 *   otherwise -> SUCCESS
 */
export function signMockPayload(rawBody) {
  return crypto.createHmac('sha256', config.MOCK_PROVIDER_WEBHOOK_SECRET).update(rawBody).digest('hex');
}

function scenario(amountMinor) {
  const tail = amountMinor % 100;
  if (tail === 1) return { status: 'FAILED', reason: 'Insufficient funds in M-Pesa account' };
  if (tail === 2) return { status: 'PENDING', reason: 'Awaiting customer' };
  if (tail === 3) return { status: 'FAILED', reason: 'Request cancelled by user' };
  return { status: 'SUCCESS' };
}

export class MockProvider extends PaymentProviderAdapter {
  code = 'mock';

  capabilities = {
    types: ['SEND_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT', 'BANK_TRANSFER'],
    currencies: ['KES', 'UGX', 'TZS', 'RWF', 'NGN', 'GHS', 'ZAR'],
    countries: ['KE', 'UG', 'TZ', 'RW', 'NG', 'GH', 'ZA'],
    statusQuery: true,
    reversal: true,
    signedCallbacks: true,
    confirmCallbacksByQuery: false,
  };

  async initiate(txn) {
    const providerRequestId = `MOCK-${randomToken(12)}`;
    const s = scenario(txn.amountMinor);
    const outcome = s.status === 'SUCCESS' ? 'SUCCESS' : s.status;
    await MockProviderLedger.create({
      providerRequestId,
      externalRef: outcome === 'SUCCESS' ? `SBX${randomToken(6).toUpperCase().replace(/[^A-Z0-9]/g, 'X').slice(0, 7)}` : undefined,
      amountMinor: txn.amountMinor,
      currency: txn.currency,
      status: outcome,
      reason: s.reason,
    });
    if (s.status !== 'PENDING' && !config.isTest) {
      // Simulate the provider calling our webhook a few seconds later.
      await enqueue(QUEUES.payments, 'mock-callback', { providerRequestId }, { delay: 3000 });
    }
    return {
      accepted: true,
      providerRequestId,
      status: 'PENDING',
      customerMessage: txn.type === 'DEPOSIT' ? 'Sandbox: approve the simulated prompt — no real M-Pesa request is sent.' : 'Sandbox payment submitted.',
    };
  }

  /** Builds the webhook body the sandbox provider would send. */
  async buildCallback(providerRequestId) {
    const entry = await MockProviderLedger.findOne({ providerRequestId }).lean();
    if (!entry) return null;
    return {
      eventId: `evt_${randomToken(10)}`,
      providerRequestId,
      status: entry.status,
      receipt: entry.externalRef ?? null,
      amountMinor: entry.amountMinor,
      currency: entry.currency,
      reason: entry.reason ?? null,
    };
  }

  async parseCallback(req) {
    const signature = req.get('x-callback-signature') ?? '';
    const raw = req.rawBody ?? Buffer.from(JSON.stringify(req.body ?? {}));
    const verified = timingSafeEqualStr(signature, signMockPayload(raw));
    const b = req.body ?? {};
    const outcomeMap = { SUCCESS: 'SUCCESS', FAILED: 'FAILED', REVERSED: 'REVERSED' };
    return {
      verified,
      dedupeKey: String(b.eventId ?? ''),
      providerRequestId: b.providerRequestId,
      externalRef: b.receipt ?? undefined,
      outcome: outcomeMap[b.status] ?? 'UNKNOWN',
      amountMinor: Number.isSafeInteger(b.amountMinor) ? b.amountMinor : undefined,
      reason: b.reason ?? undefined,
      sanitizedPayload: { eventId: b.eventId, providerRequestId: b.providerRequestId, status: b.status, receipt: b.receipt, amountMinor: b.amountMinor },
      ack: { received: true },
    };
  }

  async queryStatus(txn) {
    const entry = await MockProviderLedger.findOne({ providerRequestId: txn.providerRequestId }).lean();
    if (!entry) return { outcome: 'NOT_FOUND' };
    const map = { SUCCESS: 'SUCCESS', FAILED: 'FAILED', PENDING: 'PENDING', REVERSED: 'REVERSED' };
    return { outcome: map[entry.status], externalRef: entry.externalRef, amountMinor: entry.amountMinor, reason: entry.reason };
  }

  async reverse(txn) {
    const providerRequestId = `MOCKREV-${randomToken(10)}`;
    await MockProviderLedger.updateOne({ providerRequestId: txn.providerRequestId }, { $set: { status: 'REVERSED' } });
    return { accepted: true, providerRequestId };
  }

  async settlementReport({ from, to }) {
    const rows = await MockProviderLedger.find({ createdAt: { $gte: from, $lt: to }, status: { $ne: 'PENDING' } }).lean();
    return rows.map((r) => ({ providerRequestId: r.providerRequestId, externalRef: r.externalRef, amountMinor: r.amountMinor, currency: r.currency, status: r.status }));
  }
}
