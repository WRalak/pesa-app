import { describe, it, expect, beforeAll } from 'vitest';
import { api, createUser, idemKey, kenyanPhone, device, latestOtp } from './helpers.js';
import { User } from '../src/modules/users/models.js';
import { Card } from '../src/modules/cards/models.js';
import { getIssuer } from '../src/modules/cards/issuers.js';
import { Transaction } from '../src/modules/payments/models.js';
import { RewardCampaign, RewardAccount, Reward, Referral } from '../src/modules/rewards/models.js';
import { getAdapter } from '../src/modules/payments/providers/registry.js';
import { processCallback, transition } from '../src/modules/payments/service.js';
import { signMockPayload } from '../src/modules/payments/providers/mock.js';
import { releaseHeldCashback } from '../src/modules/rewards/service.js';
import { emitDomainEvent } from '../src/lib/events.js';

async function completedPayment(c, body) {
  const res = await api().post('/v1/payments').set(c.auth()).set('Idempotency-Key', idemKey()).send({ pin: c.pin, ...body }).expect(202);
  const t = await Transaction.findById(res.body.transaction.id).lean();
  const cb = await getAdapter('mock').buildCallback(t.providerRequestId);
  const raw = Buffer.from(JSON.stringify(cb));
  await processCallback('mock', { body: cb, rawBody: raw, ip: '127.0.0.1', params: {}, get: () => signMockPayload(raw) });
  return res.body.transaction.id;
}

let ctx;
beforeAll(async () => {
  ctx = await createUser();
  await User.updateOne({ _id: ctx.user.id }, { $set: { kycTier: 'TIER_1' } });
});

describe('cards', () => {
  it('issues a virtual card without ever storing or returning a card number', async () => {
    const res = await api().post('/v1/cards/virtual').set(ctx.auth()).send({ nickname: 'Online', pin: ctx.pin }).expect(201);
    expect(res.body.last4).toMatch(/^\d{4}$/);
    expect(JSON.stringify(res.body)).not.toMatch(/\d{12,19}/);
    const stored = await Card.findById(res.body.id).select('+providerCardToken').lean();
    expect(JSON.stringify(stored)).not.toMatch(/\b\d{13,19}\b/);
    const display = await api().post(`/v1/cards/${res.body.id}/secure-display`).set(ctx.auth()).send({ pin: ctx.pin }).expect(200);
    expect(display.body.sessionToken).toMatch(/^sbxdisplay_/);
    expect(JSON.stringify(display.body)).not.toMatch(/\d{13,19}/);
  });

  it('rejects raw card numbers on link and accepts PSP tokens', async () => {
    await api().post('/v1/cards/link').set(ctx.auth()).send({ paymentMethodToken: '4242424242424242' }).expect(422);
    const ok = await api().post('/v1/cards/link').set(ctx.auth()).send({ paymentMethodToken: 'tok_sandbox_mastercard' }).expect(201);
    expect(ok.body.brand).toBe('MASTERCARD');
  });

  it('declines authorizations on frozen cards and over limits', async () => {
    const card = (await api().post('/v1/cards/virtual').set(ctx.auth()).send({ pin: ctx.pin }).expect(201)).body;
    const ok = await api().post(`/v1/cards/${card.id}/simulate-authorization`).set(ctx.auth()).send({ amount: '120.00', merchantName: 'Carrefour' }).expect(200);
    expect(ok.body.status).toBe('APPROVED');
    await api().patch(`/v1/cards/${card.id}/controls`).set(ctx.auth()).send({ perTransaction: '100.00', online: false }).expect(200);
    const over = await api().post(`/v1/cards/${card.id}/simulate-authorization`).set(ctx.auth()).send({ amount: '150.00' }).expect(200);
    expect(over.body.reason).toMatch(/limit/);
    const online = await api().post(`/v1/cards/${card.id}/simulate-authorization`).set(ctx.auth()).send({ amount: '50.00', channel: 'ONLINE' }).expect(200);
    expect(online.body.reason).toMatch(/Online/);
    await api().post(`/v1/cards/${card.id}/freeze`).set(ctx.auth()).expect(200);
    const frozen = await api().post(`/v1/cards/${card.id}/simulate-authorization`).set(ctx.auth()).send({ amount: '10.00' }).expect(200);
    expect(frozen.body.reason).toBe('Card is frozen');
    const txs = await api().get(`/v1/cards/${card.id}/transactions`).set(ctx.auth()).expect(200);
    expect(txs.body.items.map((t) => t.status).sort()).toEqual(['FAILED', 'FAILED', 'FAILED', 'SUCCESSFUL']);
    expect(txs.body.items.find((t) => t.status === 'SUCCESSFUL').category).toBe('food');
  });

  it('verifies issuer webhook signatures and deduplicates events', async () => {
    const card = (await api().post('/v1/cards/virtual').set(ctx.auth()).send({ pin: ctx.pin }).expect(201)).body;
    const body = JSON.stringify({ eventId: 'iss_evt_1', cardId: card.id, authorizationId: 'A1', amountMinor: 5000, merchantName: 'Uber' });
    await api().post('/v1/callbacks/card-issuer').set('Content-Type', 'application/json').set('X-Issuer-Signature', 'bad').send(body).expect(401);
    const sig = getIssuer().signWebhook(Buffer.from(body));
    await api().post('/v1/callbacks/card-issuer').set('Content-Type', 'application/json').set('X-Issuer-Signature', sig).send(body).expect(200);
    const dup = await api().post('/v1/callbacks/card-issuer').set('Content-Type', 'application/json').set('X-Issuer-Signature', sig).send(body).expect(200);
    expect(dup.body.status).toBe('DUPLICATE');
    expect(await Transaction.countDocuments({ cardId: card.id })).toBe(1);
  });

  it('isolates cards between users', async () => {
    const owner = await createUser();
    const card = (await api().post('/v1/cards/virtual').set(owner.auth()).send({ pin: owner.pin }).expect(201)).body;
    const other = await createUser();
    await api().post(`/v1/cards/${card.id}/freeze`).set(other.auth()).expect(404);
    await api().post(`/v1/cards/${card.id}/secure-display`).set(other.auth()).send({ pin: other.pin }).expect(404);
  });
});

describe('rewards & referrals', () => {
  beforeAll(async () => {
    await RewardCampaign.create([
      { code: 'AIRTIME_CASHBACK', name: 'Airtime cashback', type: 'CASHBACK', status: 'ACTIVE', startsAt: new Date(Date.now() - 1000), rules: { transactionTypes: ['AIRTIME'], cashbackBps: 500, maxRewardMinor: 2000, holdDays: 0, perUserLimit: 2 }, totalBudgetMinor: 100_000 },
      { code: 'BASE_POINTS', name: 'Pesa points', type: 'POINTS', status: 'ACTIVE', startsAt: new Date(Date.now() - 1000), rules: { pointsPerUnit: 1, unitMinor: 100_00 } },
      { code: 'REFER_FRIEND', name: 'Refer a friend', type: 'REFERRAL', status: 'ACTIVE', startsAt: new Date(Date.now() - 1000), rules: { referrerPoints: 200, refereePoints: 100, referralQualifyingMinAmountMinor: 50_00 } },
      { code: 'OLD_PROMO', name: 'Ended', type: 'CASHBACK', status: 'ENDED', startsAt: new Date(0), rules: { cashbackBps: 10_000 } },
    ]);
  });

  it('awards configurable cashback and points exactly once per transaction', async () => {
    const id = await completedPayment(ctx, { type: 'AIRTIME', amount: '300.00' });
    const acct = await RewardAccount.findOne({ userId: ctx.user.id });
    expect(acct.cashbackAvailableMinor).toBe(1500); // 5% of 300.00
    expect(acct.points).toBe(3); // 1 point per KES 100
    const t = await Transaction.findById(id).lean();
    await emitDomainEvent('transaction.successful', { transaction: t }); // replayed event
    expect((await RewardAccount.findOne({ userId: ctx.user.id })).cashbackAvailableMinor).toBe(1500);
    expect(await Reward.countDocuments({ sourceId: id, entryType: 'EARN' })).toBe(2);
  });

  it('caps cashback per transaction and per user', async () => {
    await completedPayment(ctx, { type: 'AIRTIME', amount: '1000.00' }); // 5% = 50, capped to 20
    await completedPayment(ctx, { type: 'AIRTIME', amount: '100.00', confirmDuplicate: true }); // perUserLimit reached
    const acct = await RewardAccount.findOne({ userId: ctx.user.id });
    expect(acct.cashbackAvailableMinor).toBe(1500 + 2000);
  });

  it('claws back rewards when a payment is reversed', async () => {
    const u = await createUser();
    const id = await completedPayment(u, { type: 'PAYBILL', paybillNumber: '400200', accountNumber: 'X1', amount: '500.00' });
    expect((await RewardAccount.findOne({ userId: u.user.id })).points).toBe(5);
    await transition(id, { to: 'REVERSED', source: 'PROVIDER_CALLBACK' });
    expect((await RewardAccount.findOne({ userId: u.user.id })).points).toBe(0);
  });

  it('rewards a referral once, after the referee’s first qualifying payment', async () => {
    const referrer = await createUser();
    const phone = kenyanPhone();
    await api().post('/v1/auth/register').send({ phone, password: 'Str0ngPass!', firstName: 'Ref', lastName: 'Eree', acceptTerms: true, referralCode: referrer.user.referralCode }).expect(202);
    const dev = device();
    const v = await api().post('/v1/auth/verify-phone').send({ phone, code: latestOtp(phone), device: dev }).expect(200);
    const referee = { pin: '2580', auth: () => ({ Authorization: `Bearer ${v.body.tokens.accessToken}` }) };
    await api().post('/v1/auth/pin').set(referee.auth()).send({ pin: '2580' }).expect(201);
    const ref = await Referral.findOne({ refereeId: v.body.user.id });
    expect(ref.status).toBe('PENDING');
    await completedPayment(referee, { type: 'AIRTIME', amount: '20.00' }); // below qualifying min
    expect((await Referral.findById(ref._id)).status).toBe('PENDING');
    await completedPayment(referee, { type: 'AIRTIME', amount: '60.00' });
    expect((await Referral.findById(ref._id)).status).toBe('REWARDED');
    expect((await RewardAccount.findOne({ userId: referrer.user.id })).points).toBe(200);
    await completedPayment(referee, { type: 'AIRTIME', amount: '70.00' });
    expect((await RewardAccount.findOne({ userId: referrer.user.id })).points).toBe(200);
  });

  it('rejects referrals from the same device (self-referral abuse)', async () => {
    const referrer = await createUser();
    const phone = kenyanPhone();
    await api().post('/v1/auth/register').send({ phone, password: 'Str0ngPass!', firstName: 'Same', lastName: 'Phone', acceptTerms: true, referralCode: referrer.user.referralCode }).expect(202);
    const v = await api().post('/v1/auth/verify-phone').send({ phone, code: latestOtp(phone), device: referrer.device }).expect(200);
    const ref = await Referral.findOne({ refereeId: v.body.user.id });
    expect(ref.status).toBe('REJECTED');
    expect(ref.fraudSignals).toContain('SHARED_DEVICE');
  });

  it('redeems points atomically without overspending', async () => {
    await RewardAccount.updateOne({ userId: ctx.user.id }, { $set: { points: 1200 } });
    const results = await Promise.all(Array.from({ length: 4 }, () => api().post('/v1/rewards/redeem').set(ctx.auth()).send({ reward: 'AIRTIME_50', points: 500 })));
    expect(results.filter((r) => r.status === 200)).toHaveLength(2);
    expect((await RewardAccount.findOne({ userId: ctx.user.id })).points).toBe(200);
  });

  it('shows the rewards dashboard with active offers only', async () => {
    const d = await api().get('/v1/rewards').set(ctx.auth()).expect(200);
    expect(d.body.referral.code).toBe(ctx.user.referralCode);
    expect(d.body.offers.map((o) => o.code).sort()).toEqual(['AIRTIME_CASHBACK', 'BASE_POINTS']);
    const h = await api().get('/v1/rewards/history').set(ctx.auth()).expect(200);
    expect(h.body.items.length).toBeGreaterThan(0);
  });

  it('holds cashback until the hold period passes', async () => {
    await RewardCampaign.updateOne({ code: 'AIRTIME_CASHBACK' }, { $set: { 'rules.holdDays': 7, 'rules.perUserLimit': 100 } });
    const u = await createUser();
    await completedPayment(u, { type: 'AIRTIME', amount: '100.00' });
    let a = await RewardAccount.findOne({ userId: u.user.id });
    expect(a.cashbackPendingMinor).toBe(500);
    await releaseHeldCashback(new Date(Date.now() + 8 * 86_400_000));
    a = await RewardAccount.findOne({ userId: u.user.id });
    expect(a.cashbackPendingMinor).toBe(0);
    expect(a.cashbackAvailableMinor).toBe(500);
  });
});
