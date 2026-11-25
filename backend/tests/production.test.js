import { describe, it, expect } from 'vitest';
import { api, createUser, idemKey } from './helpers.js';
import { deploymentProblems } from '../src/config/env.js';
import { DarajaProvider } from '../src/modules/payments/providers/daraja.js';
import { Transaction, PaymentCallback } from '../src/modules/payments/models.js';
import { signMockPayload } from '../src/modules/payments/providers/mock.js';
import { retryOrphanedCallback } from '../src/modules/payments/service.js';
import { User } from '../src/modules/users/models.js';

const prodEnv = (over = {}) => ({
  NODE_ENV: 'production',
  JWT_ACCESS_SECRET: 'a'.repeat(64), JWT_ADMIN_SECRET: 'b'.repeat(64), HASH_PEPPER: 'c'.repeat(64),
  FIELD_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64'), MOCK_PROVIDER_WEBHOOK_SECRET: 'unused-in-prod-0123456789',
  DEV_OTP_OUTBOX: false, SMS_PROVIDER: 'africastalking', AFRICASTALKING_USERNAME: 'pesa', AFRICASTALKING_API_KEY: 'k',
  EMAIL_PROVIDER: 'ses', EMAIL_FROM: 'no-reply@pesa.africa', PUBLIC_BASE_URL: 'https://api.pesa.africa',
  CORS_ORIGINS: 'https://admin.pesa.internal', METRICS_TOKEN: 'm'.repeat(40), PAYMENT_PROVIDERS: 'daraja', DARAJA_ENV: 'production',
  DARAJA_CONSUMER_KEY: 'x', DARAJA_CONSUMER_SECRET: 'x', DARAJA_SHORTCODE: '123456', DARAJA_PASSKEY: 'x',
  DARAJA_CALLBACK_TOKEN: 't'.repeat(48), DARAJA_ALLOWED_IPS: '196.201.214.200', FCM_ENABLED: false, AI_EXTERNAL_PROVIDER: 'none',
  ...over,
});

describe('production configuration gate', () => {
  it('accepts a complete production configuration', () => {
    expect(deploymentProblems(prodEnv())).toEqual([]);
  });

  it.each([
    [{ SMS_PROVIDER: 'console' }, /SMS_PROVIDER/],
    [{ EMAIL_PROVIDER: 'console' }, /EMAIL_PROVIDER/],
    [{ EMAIL_FROM: undefined }, /EMAIL_FROM/],
    [{ DEV_OTP_OUTBOX: true }, /DEV_OTP_OUTBOX/],
    [{ PAYMENT_PROVIDERS: 'daraja,mock' }, /mock payment provider/],
    [{ DARAJA_ENV: 'sandbox' }, /DARAJA_ENV/],
    [{ DARAJA_ALLOWED_IPS: '' }, /DARAJA_ALLOWED_IPS/],
    [{ DARAJA_CALLBACK_TOKEN: 'short' }, /DARAJA_CALLBACK_TOKEN/],
    [{ PUBLIC_BASE_URL: 'http://api.pesa.africa' }, /https/],
    [{ CORS_ORIGINS: 'http://admin.local' }, /CORS_ORIGINS/],
    [{ METRICS_TOKEN: undefined }, /METRICS_TOKEN/],
    [{ JWT_ADMIN_SECRET: 'a'.repeat(64) }, /must differ/],
    [{ HASH_PEPPER: 'dev-pepper-change-me-0123456789abcdefghij' }, /HASH_PEPPER/],
    [{ FCM_ENABLED: true }, /FCM_SERVICE_ACCOUNT_JSON/],
  ])('refuses to boot with %o', (over, msg) => {
    expect(deploymentProblems(prodEnv(over)).join('\n')).toMatch(msg);
  });

  it('does not apply to development or test', () => {
    expect(deploymentProblems(prodEnv({ NODE_ENV: 'development', SMS_PROVIDER: 'console' }))).toEqual([]);
  });
});

describe('Daraja routing safety', () => {
  it('only collects into the partner shortcode (DEPOSIT); never third-party bills', async () => {
    const p = new DarajaProvider();
    expect(p.supports({ type: 'DEPOSIT', currency: 'KES', country: 'KE' })).toBe(true);
    for (const type of ['PAYBILL', 'BUY_GOODS', 'SEND_MONEY', 'AIRTIME', 'UTILITY']) {
      expect(p.supports({ type, currency: 'KES', country: 'KE' })).toBe(false);
    }
    await expect(p.initiate({ type: 'PAYBILL', amountMinor: 10000 }, { payerPhone: '+254712345678' })).rejects.toThrow(/cannot process PAYBILL/);
  });
});

describe('orphaned callbacks', () => {
  it('re-applies a callback that arrived before the transaction was linked', async () => {
    const u = await createUser();
    await User.updateOne({ _id: u.user.id }, { $set: { kycTier: 'TIER_1' } });
    const res = await api().post('/v1/payments').set(u.auth()).set('Idempotency-Key', idemKey()).send({ type: 'AIRTIME', amount: '75.00', pin: u.pin }).expect(202);
    const txn = await Transaction.findById(res.body.transaction.id);
    // Simulate the race: the provider's callback lands while our providerRequestId write is not yet visible.
    const realId = txn.providerRequestId;
    await Transaction.collection.updateOne({ _id: txn._id }, { $unset: { providerRequestId: 1 } });
    const body = { eventId: 'evt_race_1', providerRequestId: realId, status: 'SUCCESS', receipt: 'SBXRACE01', amountMinor: 7500 };
    const raw = JSON.stringify(body);
    await api().post('/v1/callbacks/mock').set('Content-Type', 'application/json').set('X-Callback-Signature', signMockPayload(Buffer.from(raw))).send(raw).expect(200);
    const cb = await PaymentCallback.findOne({ dedupeKey: 'evt_race_1' });
    expect(cb.processingStatus).toBe('ORPHANED');
    expect(cb.parsed.amountMinor).toBe(7500);

    await Transaction.collection.updateOne({ _id: txn._id }, { $set: { providerRequestId: realId } });
    const r = await retryOrphanedCallback({ callbackId: String(cb._id) });
    expect(r.status).toBe('APPLIED');
    const after = await Transaction.findById(txn._id);
    expect(after.status).toBe('SUCCESSFUL');
    expect(after.externalRef).toBe('SBXRACE01');
    // Idempotent: a second retry does nothing.
    expect((await retryOrphanedCallback({ callbackId: String(cb._id) })).status).toBe('SKIPPED');
  });
});
