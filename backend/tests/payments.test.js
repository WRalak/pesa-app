import { describe, it, expect, beforeAll } from 'vitest';
import { api, createUser, idemKey } from './helpers.js';
import { Transaction, TransactionEvent, PaymentCallback, MockProviderLedger, PaymentProvider } from '../src/modules/payments/models.js';
import { signMockPayload } from '../src/modules/payments/providers/mock.js';
import { getAdapter } from '../src/modules/payments/providers/registry.js';
import { sweepPending, requestReversal, transition } from '../src/modules/payments/service.js';
import { Notification } from '../src/modules/notifications/models.js';
import { User } from '../src/modules/users/models.js';
import { invalidate } from '../src/lib/redis.js';

function sendCallback(body, { signature } = {}) {
  const raw = JSON.stringify(body);
  return api().post('/v1/callbacks/mock')
    .set('Content-Type', 'application/json')
    .set('X-Callback-Signature', signature ?? signMockPayload(Buffer.from(raw)))
    .send(raw);
}

async function providerCallbackFor(txnId) {
  const t = await Transaction.findById(txnId).lean();
  return getAdapter('mock').buildCallback(t.providerRequestId);
}

function pay(ctx, body = {}, key = idemKey()) {
  return api().post('/v1/payments').set(ctx.auth()).set('Idempotency-Key', key).send({
    type: 'SEND_MONEY', amount: '250.00', recipientPhone: '0711000222', recipientName: 'Baraka', pin: ctx.pin, ...body,
  });
}

let ctx;
beforeAll(async () => {
  ctx = await createUser();
  // Raise to TIER_1 so most tests aren't constrained by TIER_0 limits.
  await User.updateOne({ _id: ctx.user.id }, { $set: { kycTier: 'TIER_1', createdAt: new Date(Date.now() - 7 * 86_400_000) } });
});

describe('payment initiation', () => {
  it('creates a PENDING transaction — never successful from the initiation response', async () => {
    const res = await pay(ctx).expect(202);
    expect(res.body.transaction.status).toBe('PENDING');
    expect(res.body.transaction.amount).toEqual({ amountMinor: 25000, currency: 'KES', amount: '250.00' });
    expect(res.body.transaction.counterparty.phone).toBe('+254711000222');
    expect(res.body.transaction.reference).toMatch(/^PSA\d{6}[A-Z0-9]{8}$/);
    const events = await TransactionEvent.find({ transactionId: res.body.transaction.id }).sort({ createdAt: 1 });
    expect(events.map((e) => e.toStatus)).toEqual(['INITIATED', 'PENDING']);
  });

  it('requires an Idempotency-Key header', async () => {
    await api().post('/v1/payments').set(ctx.auth()).send({ type: 'AIRTIME', amount: '50', pin: ctx.pin }).expect(400);
  });

  it('requires the transaction PIN', async () => {
    const res = await pay(ctx, { pin: '9999', amount: '260.00' }).expect(422);
    expect(res.body.error.code).toBe('INVALID_PIN');
    await User.updateOne({ _id: ctx.user.id }, { $set: { pinFailedAttempts: 0 } });
  });

  it('replays the original response for a repeated Idempotency-Key', async () => {
    const key = idemKey();
    const a = await pay(ctx, { amount: '300.00' }, key).expect(202);
    const b = await pay(ctx, { amount: '300.00' }, key).expect(202);
    expect(b.headers['idempotent-replayed']).toBe('true');
    expect(b.body.transaction.id).toBe(a.body.transaction.id);
    expect(await Transaction.countDocuments({ idempotencyKey: key })).toBe(1);
  });

  it('rejects a reused key with a different payload', async () => {
    const key = idemKey();
    await pay(ctx, { amount: '310.00' }, key).expect(202);
    const res = await pay(ctx, { amount: '999.00' }, key).expect(422);
    expect(res.body.error.code).toBe('IDEMPOTENCY_MISMATCH');
  });

  it('creates exactly one transaction under concurrent duplicate submissions', async () => {
    const key = idemKey();
    const results = await Promise.all(Array.from({ length: 5 }, () => pay(ctx, { amount: '320.00' }, key)));
    const created = results.filter((r) => r.status === 202);
    expect(created.length).toBeGreaterThanOrEqual(1);
    for (const r of results) expect([202, 409]).toContain(r.status);
    expect(await Transaction.countDocuments({ idempotencyKey: key })).toBe(1);
  });

  it('warns about a possible duplicate payment to the same payee', async () => {
    await pay(ctx, { type: 'PAYBILL', paybillNumber: '888880', accountNumber: 'ACC-77', amount: '410.00' }).expect(202);
    const dup = await pay(ctx, { type: 'PAYBILL', paybillNumber: '888880', accountNumber: 'ACC-77', amount: '410.00' }).expect(409);
    expect(dup.body.error.code).toBe('POSSIBLE_DUPLICATE');
    await pay(ctx, { type: 'PAYBILL', paybillNumber: '888880', accountNumber: 'ACC-77', amount: '410.00', confirmDuplicate: true }).expect(202);
  });

  it('enforces KYC-tier limits', async () => {
    const low = await createUser();
    const res = await pay(low, { amount: '1500.00' }).expect(422);
    expect(res.body.error.code).toBe('LIMIT_EXCEEDED');
  });

  it('validates payee details per payment type', async () => {
    await pay(ctx, { type: 'PAYBILL', paybillNumber: '12', accountNumber: 'X', amount: '50.00' }).expect(422);
    await pay(ctx, { type: 'BUY_GOODS', tillNumber: 'abc', amount: '50.00' }).expect(422);
    await pay(ctx, { type: 'UTILITY', utilityCode: 'NOPE', accountNumber: '1', amount: '50.00' }).expect(422);
  });

  it('rejects amounts with more precision than the currency allows', async () => {
    await pay(ctx, { amount: '10.005' }).expect(422);
  });

  it('applies admin-configured fees using integer arithmetic', async () => {
    await PaymentProvider.updateOne({ code: 'mock' }, {
      $set: { name: 'Sandbox', kind: 'AGGREGATOR', enabled: true, fees: [{ type: 'BUY_GOODS', minAmountMinor: 0, maxAmountMinor: 100_000_00, fixedMinor: 500, bps: 55 }] },
    }, { upsert: true });
    await invalidate('provider-config:mock');
    const q = await api().post('/v1/payments/quote').set(ctx.auth()).send({ type: 'BUY_GOODS', amount: '1234.56' }).expect(200);
    // 123456 * 55 / 10000 = 679.008 -> 679 ; + 500 fixed
    expect(q.body.fee.amountMinor).toBe(1179);
    expect(q.body.total.amount).toBe('1246.35');
    await PaymentProvider.deleteOne({ code: 'mock' });
    await invalidate('provider-config:mock');
  });
});

describe('provider callbacks', () => {
  it('marks a payment SUCCESSFUL only after a verified callback, and notifies the user', async () => {
    const res = await pay(ctx, { amount: '500.00' }).expect(202);
    const body = await providerCallbackFor(res.body.transaction.id);
    await sendCallback(body).expect(200);
    const detail = await api().get(`/v1/transactions/${res.body.transaction.id}`).set(ctx.auth()).expect(200);
    expect(detail.body.transaction.status).toBe('SUCCESSFUL');
    expect(detail.body.transaction.externalRef).toMatch(/^SBX/);
    expect(detail.body.timeline.map((t) => t.status)).toEqual(['INITIATED', 'PENDING', 'SUCCESSFUL']);
    const n = await Notification.findOne({ userId: ctx.user.id, type: 'PAYMENT_SUCCESSFUL', 'data.transactionId': res.body.transaction.id });
    expect(n).toBeTruthy();
  });

  it('rejects callbacks with an invalid signature and leaves the payment untouched', async () => {
    const res = await pay(ctx, { amount: '510.00' }).expect(202);
    const body = await providerCallbackFor(res.body.transaction.id);
    await sendCallback(body, { signature: 'deadbeef' }).expect(401);
    const t = await Transaction.findById(res.body.transaction.id);
    expect(t.status).toBe('PENDING');
    expect(await PaymentCallback.countDocuments({ processingStatus: 'REJECTED' })).toBeGreaterThan(0);
  });

  it('rejects a forged success for a payment that tampers with the body after signing', async () => {
    const res = await pay(ctx, { amount: '520.01' }).expect(202); // ..01 => provider says FAILED
    const body = await providerCallbackFor(res.body.transaction.id);
    const sig = signMockPayload(Buffer.from(JSON.stringify(body)));
    await sendCallback({ ...body, status: 'SUCCESS' }, { signature: sig }).expect(401);
    await sendCallback(body).expect(200);
    expect((await Transaction.findById(res.body.transaction.id)).status).toBe('FAILED');
  });

  it('processes duplicate callbacks exactly once', async () => {
    const res = await pay(ctx, { amount: '530.00' }).expect(202);
    const body = await providerCallbackFor(res.body.transaction.id);
    await sendCallback(body).expect(200);
    await sendCallback(body).expect(200);
    await sendCallback(body).expect(200);
    const events = await TransactionEvent.countDocuments({ transactionId: res.body.transaction.id, toStatus: 'SUCCESSFUL', kind: 'STATUS_CHANGE' });
    expect(events).toBe(1);
    const notes = await Notification.countDocuments({ 'data.transactionId': res.body.transaction.id, type: 'PAYMENT_SUCCESSFUL' });
    expect(notes).toBe(1);
  });

  it('never lets a later FAILED callback overturn a SUCCESSFUL payment', async () => {
    const res = await pay(ctx, { amount: '540.00' }).expect(202);
    const body = await providerCallbackFor(res.body.transaction.id);
    await sendCallback(body).expect(200);
    await sendCallback({ ...body, eventId: 'evt_late_fail', status: 'FAILED', reason: 'late' }).expect(200);
    expect((await Transaction.findById(res.body.transaction.id)).status).toBe('SUCCESSFUL');
  });

  it('holds payments with a mismatched amount for review instead of marking success', async () => {
    const res = await pay(ctx, { amount: '550.00' }).expect(202);
    const body = await providerCallbackFor(res.body.transaction.id);
    await sendCallback({ ...body, amountMinor: 5_500 }).expect(200);
    const t = await Transaction.findById(res.body.transaction.id);
    expect(t.status).toBe('PROCESSING');
    expect(t.risk.reviewRequired).toBe(true);
    expect(t.risk.flags).toContain('AMOUNT_MISMATCH');
  });

  it('records callbacks for unknown transactions as orphaned', async () => {
    await sendCallback({ eventId: 'evt_orphan_1', providerRequestId: 'MOCK-unknown', status: 'SUCCESS', amountMinor: 100 }).expect(200);
    const cb = await PaymentCallback.findOne({ dedupeKey: 'evt_orphan_1' });
    expect(cb.processingStatus).toBe('ORPHANED');
  });
});

describe('status queries and sweeper', () => {
  it('resolves a payment with no callback through the provider status query', async () => {
    const res = await pay(ctx, { amount: '560.02' }).expect(202); // ..02 => no callback
    await Transaction.updateOne({ _id: res.body.transaction.id }, { $set: { updatedAt: new Date(Date.now() - 5 * 60_000) } }, { timestamps: false });
    await sweepPending();
    expect((await Transaction.findById(res.body.transaction.id)).status).toBe('PENDING');
    const t = await Transaction.findById(res.body.transaction.id);
    await MockProviderLedger.updateOne({ providerRequestId: t.providerRequestId }, { $set: { status: 'SUCCESS', externalRef: 'SBXLATE01' } });
    await Transaction.updateOne({ _id: t._id }, { $set: { updatedAt: new Date(Date.now() - 5 * 60_000) } }, { timestamps: false });
    await sweepPending();
    const done = await Transaction.findById(t._id);
    expect(done.status).toBe('SUCCESSFUL');
    const ev = await TransactionEvent.findOne({ transactionId: t._id, toStatus: 'SUCCESSFUL' });
    expect(ev.source).toBe('STATUS_QUERY');
  });

  it('lets the user ask for a status refresh only on their own payments', async () => {
    const res = await pay(ctx, { amount: '570.02' }).expect(202);
    const other = await createUser();
    await api().post(`/v1/payments/${res.body.transaction.id}/refresh-status`).set(other.auth()).expect(404);
    const mine = await api().post(`/v1/payments/${res.body.transaction.id}/refresh-status`).set(ctx.auth()).expect(200);
    expect(mine.body.transaction.status).toBe('PENDING');
  });
});

describe('risk rules', () => {
  it('blocks high-velocity bursts and flags them for review', async () => {
    const { assessRisk } = await import('../src/modules/payments/risk.js');
    const u = await User.findById(ctx.user.id);
    const limits = { perTransaction: 150_000_00 };
    const r = await assessRisk({ user: u, amountMinor: 100_00, counterparty: {}, limits }, { warn: 2, block: 3 });
    expect(r.block).toBe(true);
    expect(r.flags).toContain('VELOCITY_BLOCK');
  });
});

describe('state machine & immutability', () => {
  it('rejects invalid transitions', async () => {
    const res = await pay(ctx, { amount: '580.00' }).expect(202);
    await transition(res.body.transaction.id, { to: 'FAILED', source: 'SYSTEM', reason: 'test' });
    const r = await transition(res.body.transaction.id, { to: 'SUCCESSFUL', source: 'SYSTEM' });
    expect(r.rejected).toBe(true);
    expect((await Transaction.findById(res.body.transaction.id)).status).toBe('FAILED');
  });

  it('blocks modification of financial fields and deletion', async () => {
    const res = await pay(ctx, { amount: '590.00' }).expect(202);
    const t = await Transaction.findById(res.body.transaction.id);
    t.amountMinor = 1;
    await t.save();
    expect((await Transaction.findById(t._id)).amountMinor).toBe(59000);
    await expect(Transaction.deleteOne({ _id: t._id })).rejects.toThrow(/cannot be deleted/);
    await expect(TransactionEvent.updateOne({ transactionId: t._id }, { $set: { reason: 'x' } })).rejects.toThrow(/append-only/);
    await expect(TransactionEvent.deleteMany({ transactionId: t._id })).rejects.toThrow(/append-only/);
  });

  it('reverses only after provider confirmation', async () => {
    const res = await pay(ctx, { amount: '600.00' }).expect(202);
    await sendCallback(await providerCallbackFor(res.body.transaction.id)).expect(200);
    const t = await requestReversal(res.body.transaction.id, { reason: 'Customer dispute', adminId: undefined });
    expect(t.status).toBe('SUCCESSFUL');
    expect(t.reversal.providerRequestId).toMatch(/^MOCKREV-/);
    await sendCallback({ eventId: 'evt_rev_1', providerRequestId: t.providerRequestId, reversalRequestId: t.reversal.providerRequestId, status: 'REVERSED', amountMinor: 60000 }).expect(200);
    expect((await Transaction.findById(t._id)).status).toBe('REVERSED');
  });
});

describe('transactions API', () => {
  it('filters, searches and paginates with cursors', async () => {
    const u = await createUser();
    await User.updateOne({ _id: u.user.id }, { $set: { kycTier: 'TIER_1' } });
    for (let i = 0; i < 5; i++) await pay(u, { type: 'AIRTIME', amount: `${10 + i}.00`, recipientPhone: undefined, recipientName: undefined });
    await pay(u, { type: 'BUY_GOODS', tillNumber: '123456', recipientName: 'Naivas Westlands', amount: '75.00' });
    const p1 = await api().get('/v1/transactions?limit=4').set(u.auth()).expect(200);
    expect(p1.body.items).toHaveLength(4);
    expect(p1.body.hasMore).toBe(true);
    const p2 = await api().get(`/v1/transactions?limit=4&cursor=${p1.body.nextCursor}`).set(u.auth()).expect(200);
    expect(p2.body.items).toHaveLength(2);
    const ids = new Set([...p1.body.items, ...p2.body.items].map((t) => t.id));
    expect(ids.size).toBe(6);
    const airtime = await api().get('/v1/transactions?type=AIRTIME').set(u.auth()).expect(200);
    expect(airtime.body.items).toHaveLength(5);
    const search = await api().get('/v1/transactions?q=naivas').set(u.auth()).expect(200);
    expect(search.body.items).toHaveLength(1);
    expect(search.body.items[0].category).toBe('food');
    const amt = await api().get('/v1/transactions?minAmount=12&maxAmount=13.50').set(u.auth()).expect(200);
    expect(amt.body.items).toHaveLength(2);
    const rx = await api().get('/v1/transactions?q=(a+)%2B$').set(u.auth()).expect(200);
    expect(rx.body.items).toHaveLength(0);
  });

  it('isolates users from each other’s transactions', async () => {
    const res = await pay(ctx, { amount: '610.00' }).expect(202);
    const other = await createUser();
    await api().get(`/v1/transactions/${res.body.transaction.id}`).set(other.auth()).expect(404);
    const list = await api().get('/v1/transactions').set(other.auth()).expect(200);
    expect(list.body.items.find((t) => t.id === res.body.transaction.id)).toBeUndefined();
  });

  it('returns a receipt only for completed payments', async () => {
    const res = await pay(ctx, { amount: '620.00' }).expect(202);
    await api().get(`/v1/transactions/${res.body.transaction.id}/receipt`).set(ctx.auth()).expect(422);
    await sendCallback(await providerCallbackFor(res.body.transaction.id)).expect(200);
    const r = await api().get(`/v1/transactions/${res.body.transaction.id}/receipt`).set(ctx.auth()).expect(200);
    expect(r.body.receipt.total.amount).toBe('620.00');
    expect(r.body.receipt.sandbox).toBe(true);
  });

  it('streams a CSV statement and neutralises formula injection', async () => {
    await pay(ctx, { amount: '630.00', description: '=HYPERLINK("http://evil")' }).expect(202);
    const from = new Date(Date.now() - 86_400_000).toISOString();
    const to = new Date(Date.now() + 60_000).toISOString();
    const res = await api().get(`/v1/transactions/statement?from=${from}&to=${to}&format=csv`).set(ctx.auth()).expect(200);
    expect(res.headers['content-type']).toContain('text/csv');
    expect(res.text.split('\n')[0]).toContain('reference');
    expect(res.text).toContain(`"'=HYPERLINK(""http://evil"")"`);
  });

  it('produces a PDF statement', async () => {
    const from = new Date(Date.now() - 86_400_000).toISOString();
    const to = new Date(Date.now() + 60_000).toISOString();
    const res = await api().get(`/v1/transactions/statement?from=${from}&to=${to}&format=pdf`).set(ctx.auth()).buffer(true).parse((r, cb) => {
      const chunks = []; r.on('data', (c) => chunks.push(c)); r.on('end', () => cb(null, Buffer.concat(chunks)));
    }).expect(200);
    expect(res.body.subarray(0, 4).toString()).toBe('%PDF');
  });
});
