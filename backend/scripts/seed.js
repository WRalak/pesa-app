/**
 * Idempotent seed: RBAC roles/permissions, provider configuration and
 * starter reward campaigns. Creates the first Super Administrator only when
 * SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD are provided (never hardcoded).
 *
 *   SEED_ADMIN_EMAIL=ops@example.com SEED_ADMIN_PASSWORD='...' npm run seed
 */
import { config } from '../src/config/env.js';
import { connectDb, disconnectDb } from '../src/lib/db.js';
import { closeRedis } from '../src/lib/redis.js';
import { syncRbac } from '../src/modules/admin/rbac.js';
import { AdminUser } from '../src/modules/admin/models.js';
import { PaymentProvider } from '../src/modules/payments/models.js';
import { RewardCampaign } from '../src/modules/rewards/models.js';
import { hashSecret } from '../src/lib/crypto.js';
import { assertPasswordPolicy } from '../src/modules/auth/service.js';

await connectDb();
await syncRbac();

const providers = [
  { code: 'mock', name: 'Sandbox Provider', kind: 'AGGREGATOR', sandbox: true, priority: 100, countries: ['KE', 'UG'], currencies: ['KES', 'UGX'],
    fees: [{ type: 'PAYBILL', minAmountMinor: 0, maxAmountMinor: 100_00, fixedMinor: 0, bps: 0 }, { type: 'PAYBILL', minAmountMinor: 100_01, maxAmountMinor: 1_000_000_00, fixedMinor: 0, bps: 50 }] },
  { code: 'daraja', name: 'Safaricom M-Pesa (Daraja)', kind: 'MOBILE_MONEY', sandbox: config.DARAJA_ENV === 'sandbox', priority: 10, countries: ['KE'], currencies: ['KES'], fees: [] },
];
for (const p of providers) await PaymentProvider.updateOne({ code: p.code }, { $setOnInsert: p }, { upsert: true });

const now = new Date();
const campaigns = [
  { code: 'PESA_POINTS', name: 'Pesa Points', type: 'POINTS', status: 'ACTIVE', startsAt: now, description: 'Earn 1 point for every KES 100 you pay.', rules: { pointsPerUnit: 1, unitMinor: 100_00 } },
  { code: 'REFER_A_FRIEND', name: 'Refer a friend', type: 'REFERRAL', status: 'ACTIVE', startsAt: now, description: 'Earn 200 points when a friend makes their first payment.', rules: { referrerPoints: 200, refereePoints: 100, referralQualifyingMinAmountMinor: 100_00, maxReferralsPerReferrerPerMonth: 20 } },
  { code: 'AIRTIME_5', name: '5% airtime cashback', type: 'CASHBACK', status: 'DRAFT', startsAt: now, description: 'Get 5% back on airtime (max KES 20 per purchase).', rules: { transactionTypes: ['AIRTIME'], cashbackBps: 500, maxRewardMinor: 20_00, holdDays: 7, perUserLimit: 10 }, totalBudgetMinor: 100_000_00 },
];
for (const c of campaigns) await RewardCampaign.updateOne({ code: c.code }, { $setOnInsert: c }, { upsert: true });

if (config.SEED_ADMIN_EMAIL && config.SEED_ADMIN_PASSWORD) {
  assertPasswordPolicy(config.SEED_ADMIN_PASSWORD);
  if (config.SEED_ADMIN_PASSWORD.length < 12) throw new Error('Admin password must be at least 12 characters');
  const exists = await AdminUser.exists({ email: config.SEED_ADMIN_EMAIL.toLowerCase() });
  if (!exists) {
    await AdminUser.create({ email: config.SEED_ADMIN_EMAIL, name: 'Super Administrator', roles: ['SUPER_ADMIN'], passwordHash: await hashSecret(config.SEED_ADMIN_PASSWORD), mustChangePassword: true });
    console.log(`Created Super Administrator ${config.SEED_ADMIN_EMAIL} (MFA enrolment required on first sign-in).`);
  }
}
console.log('Seed complete.');
await disconnectDb();
await closeRedis();
