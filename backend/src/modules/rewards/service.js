import { RewardCampaign, RewardAccount, Reward, Referral } from './models.js';
import { User } from '../users/models.js';
import { Device } from '../auth/models.js';
import { Transaction } from '../payments/models.js';
import { withTransaction } from '../../lib/db.js';
import { Errors } from '../../lib/errors.js';
import { money, applyBasisPoints } from '../../lib/money.js';
import { paginate } from '../../lib/pagination.js';
import { notify } from '../notifications/service.js';
import { securityEvent } from '../audit/service.js';
import { logger } from '../../lib/logger.js';

const DAY = 86_400_000;

export async function activeCampaigns({ type, country = 'KE', at = new Date() } = {}) {
  const q = { status: 'ACTIVE', startsAt: { $lte: at }, $or: [{ endsAt: null }, { endsAt: { $gt: at } }], country };
  if (type) q.type = type;
  return RewardCampaign.find(q).lean();
}

/**
 * Credits a reward exactly once. The unique `dedupeKey` on the immutable
 * ledger makes duplicate claims impossible even under concurrent processing;
 * the balance and campaign budget move in the same ACID transaction.
 */
export async function creditReward({ userId, campaign, kind, points = 0, amountMinor = 0, currency, sourceType, sourceId, description, dedupeKey, holdDays = 0 }) {
  try {
    return await withTransaction(async (session) => {
      if (campaign?.totalBudgetMinor != null && amountMinor > 0) {
        const ok = await RewardCampaign.findOneAndUpdate(
          { _id: campaign._id, $expr: { $lte: [{ $add: ['$budgetUsedMinor', amountMinor] }, '$totalBudgetMinor'] } },
          { $inc: { budgetUsedMinor: amountMinor } }, { session, returnDocument: 'after' },
        );
        if (!ok) throw Object.assign(new Error('Campaign budget exhausted'), { code: 'BUDGET_EXHAUSTED' });
      }
      const availableAt = new Date(Date.now() + holdDays * DAY);
      const [entry] = await Reward.create([{ userId, campaignId: campaign?._id, kind, entryType: 'EARN', points, amountMinor, currency, sourceType, sourceId, description, dedupeKey, availableAt }], { session });
      const inc = kind === 'POINTS' ? { points, lifetimePoints: points } : holdDays > 0 ? { cashbackPendingMinor: amountMinor } : { cashbackAvailableMinor: amountMinor };
      await RewardAccount.updateOne({ userId }, { $inc: inc, $setOnInsert: { currency } }, { upsert: true, session });
      return entry;
    });
  } catch (err) {
    if (err?.code === 11000) return null; // already credited
    if (err?.code === 'BUDGET_EXHAUSTED') {
      logger.info({ campaign: campaign?.code }, 'Campaign budget exhausted');
      return null;
    }
    throw err;
  }
}

function matches(campaign, t) {
  const r = campaign.rules ?? {};
  if (r.transactionTypes?.length && !r.transactionTypes.includes(t.type)) return false;
  if (r.categories?.length && !r.categories.includes(t.category)) return false;
  if (t.amountMinor < (r.minAmountMinor ?? 0)) return false;
  if (campaign.currency && campaign.currency !== t.currency) return false;
  return true;
}

/** Evaluates cashback and points campaigns for a confirmed (SUCCESSFUL) debit. */
export async function rewardTransaction(t) {
  if (t.status !== 'SUCCESSFUL' || t.direction !== 'DEBIT') return [];
  const user = await User.findById(t.userId, { country: 1, status: 1 }).lean();
  if (!user || user.status !== 'ACTIVE') return [];
  const campaigns = (await activeCampaigns({ country: user.country })).filter((c) => ['CASHBACK', 'POINTS'].includes(c.type) && matches(c, t));
  const credited = [];
  for (const c of campaigns) {
    const r = c.rules;
    if (r.firstTransactionOnly) {
      const prior = await Transaction.countDocuments({ userId: t.userId, status: 'SUCCESSFUL', direction: 'DEBIT', completedAt: { $lt: t.completedAt } });
      if (prior > 0) continue;
    }
    if (r.perUserLimit) {
      const used = await Reward.countDocuments({ userId: t.userId, campaignId: c._id, entryType: 'EARN' });
      if (used >= r.perUserLimit) continue;
    }
    if (c.type === 'CASHBACK') {
      let amountMinor = applyBasisPoints(t.amountMinor, r.cashbackBps ?? 0);
      if (r.maxRewardMinor != null) amountMinor = Math.min(amountMinor, r.maxRewardMinor);
      if (amountMinor <= 0) continue;
      const e = await creditReward({ userId: t.userId, campaign: c, kind: 'CASHBACK', amountMinor, currency: t.currency, sourceType: 'TRANSACTION', sourceId: String(t._id), description: `${c.name} · ${t.reference}`, dedupeKey: `cashback:${c._id}:${t._id}`, holdDays: r.holdDays ?? 7 });
      if (e) credited.push(e);
    } else {
      const points = Math.floor((t.amountMinor / (r.unitMinor || 10_000)) * (r.pointsPerUnit ?? 0));
      if (points <= 0) continue;
      const e = await creditReward({ userId: t.userId, campaign: c, kind: 'POINTS', points, currency: t.currency, sourceType: 'TRANSACTION', sourceId: String(t._id), description: `${c.name} · ${t.reference}`, dedupeKey: `points:${c._id}:${t._id}` });
      if (e) credited.push(e);
    }
  }
  if (credited.length) {
    const pts = credited.reduce((a, e) => a + (e.points ?? 0), 0);
    const cash = credited.reduce((a, e) => a + (e.amountMinor ?? 0), 0);
    const parts = [pts ? `${pts} points` : null, cash ? `${t.currency} ${money(cash, t.currency).amount} cashback (pending)` : null].filter(Boolean);
    await notify(t.userId, { category: 'REWARD', type: 'REWARD_EARNED', title: 'You earned rewards', body: `You earned ${parts.join(' and ')} on ${t.reference}.`, data: { route: '/rewards' } });
  }
  return credited;
}

/** A reversed payment claws back its rewards via compensating ledger entries. */
export async function reverseTransactionRewards(t) {
  const earned = await Reward.find({ sourceType: 'TRANSACTION', sourceId: String(t._id), entryType: 'EARN' }).lean();
  for (const e of earned) {
    try {
      await withTransaction(async (session) => {
        await Reward.create([{ userId: e.userId, campaignId: e.campaignId, kind: e.kind, entryType: 'REVERSE', points: -e.points, amountMinor: -e.amountMinor, currency: e.currency, sourceType: 'TRANSACTION', sourceId: e.sourceId, description: 'Reversed payment', dedupeKey: `reverse:${e._id}` }], { session });
        const released = await Reward.exists({ dedupeKey: `release:${e._id}` }).session(session);
        const inc = e.kind === 'POINTS' ? { points: -e.points } : released ? { cashbackAvailableMinor: -e.amountMinor } : { cashbackPendingMinor: -e.amountMinor };
        await RewardAccount.updateOne({ userId: e.userId }, { $inc: inc }, { session });
      });
    } catch (err) {
      if (err?.code !== 11000) throw err;
    }
  }
}

/** Job: move held cashback to available once the hold period has passed without reversal. */
export async function releaseHeldCashback(now = new Date()) {
  const due = await Reward.find({ kind: 'CASHBACK', entryType: 'EARN', availableAt: { $lte: now } }).limit(1000).lean();
  let released = 0;
  for (const e of due) {
    if (await Reward.exists({ dedupeKey: { $in: [`release:${e._id}`, `reverse:${e._id}`] } })) continue;
    try {
      await withTransaction(async (session) => {
        await Reward.create([{ userId: e.userId, campaignId: e.campaignId, kind: 'CASHBACK', entryType: 'RELEASE', amountMinor: 0, currency: e.currency, sourceType: e.sourceType, sourceId: e.sourceId, description: 'Cashback available', dedupeKey: `release:${e._id}` }], { session });
        await RewardAccount.updateOne({ userId: e.userId }, { $inc: { cashbackPendingMinor: -e.amountMinor, cashbackAvailableMinor: e.amountMinor } }, { session });
      });
      released++;
    } catch (err) {
      if (err?.code !== 11000) throw err;
    }
  }
  return { released };
}

// ---------------------------------------------------------------- referrals
/**
 * Called when a referred user activates. Abuse checks: no self-referral, no
 * shared devices between referrer and referee, per-referrer monthly cap, and a
 * referee can only be referred once (unique index).
 */
export async function registerReferral({ userId, referredBy }) {
  if (!referredBy || String(referredBy) === String(userId)) return null;
  const [campaign] = await activeCampaigns({ type: 'REFERRAL' });
  const signals = [];
  const [refereeDevices, referrerDevices] = await Promise.all([
    Device.find({ userId }, { deviceId: 1 }).lean(),
    Device.find({ userId: referredBy }, { deviceId: 1 }).lean(),
  ]);
  const shared = refereeDevices.some((d) => referrerDevices.some((r) => r.deviceId === d.deviceId));
  if (shared) signals.push('SHARED_DEVICE');
  const monthStart = new Date(Date.now() - 30 * DAY);
  const recent = await Referral.countDocuments({ referrerId: referredBy, createdAt: { $gte: monthStart } });
  if (campaign && recent >= (campaign.rules.maxReferralsPerReferrerPerMonth ?? 10)) signals.push('REFERRER_CAP_REACHED');
  try {
    const ref = await Referral.create({
      referrerId: referredBy, refereeId: userId, campaignId: campaign?._id,
      status: signals.length ? 'REJECTED' : 'PENDING', rejectionReason: signals.join(',') || undefined, fraudSignals: signals,
    });
    if (signals.includes('SHARED_DEVICE')) await securityEvent({ userId: referredBy, type: 'FRAUD_FLAG', severity: 'MEDIUM', details: { reason: 'REFERRAL_SHARED_DEVICE', refereeId: String(userId) } });
    return ref;
  } catch (err) {
    if (err?.code === 11000) return null;
    throw err;
  }
}

/** Qualifies a pending referral on the referee's first qualifying confirmed transaction. */
export async function qualifyReferral(t) {
  if (t.status !== 'SUCCESSFUL' || t.direction !== 'DEBIT') return null;
  const ref = await Referral.findOne({ refereeId: t.userId, status: 'PENDING' });
  if (!ref) return null;
  const campaign = ref.campaignId ? await RewardCampaign.findById(ref.campaignId).lean() : null;
  if (!campaign || campaign.status !== 'ACTIVE') return null;
  if (t.amountMinor < (campaign.rules.referralQualifyingMinAmountMinor ?? 0)) return null;
  const claimed = await Referral.findOneAndUpdate({ _id: ref._id, status: 'PENDING' }, { $set: { status: 'QUALIFIED', qualifiedAt: new Date() } }, { returnDocument: 'after' });
  if (!claimed) return null;
  const rules = campaign.rules;
  if (rules.referrerPoints) await creditReward({ userId: ref.referrerId, campaign, kind: 'POINTS', points: rules.referrerPoints, currency: t.currency, sourceType: 'REFERRAL', sourceId: String(ref._id), description: 'Referral bonus', dedupeKey: `referral:referrer:${ref._id}` });
  if (rules.refereePoints) await creditReward({ userId: ref.refereeId, campaign, kind: 'POINTS', points: rules.refereePoints, currency: t.currency, sourceType: 'REFERRAL', sourceId: String(ref._id), description: 'Welcome bonus', dedupeKey: `referral:referee:${ref._id}` });
  await Referral.updateOne({ _id: ref._id }, { $set: { status: 'REWARDED', rewardedAt: new Date() } });
  await notify(ref.referrerId, { category: 'REWARD', type: 'REFERRAL_REWARDED', title: 'Referral reward earned', body: `A friend you invited made their first payment. You earned ${rules.referrerPoints} points!`, data: { route: '/rewards' } });
  return ref;
}

// ---------------------------------------------------------------- user API
export async function rewardsDashboard(user) {
  const [acct, campaigns, referrals] = await Promise.all([
    RewardAccount.findOne({ userId: user._id }).lean(),
    activeCampaigns({ country: user.country }),
    Referral.aggregate([{ $match: { referrerId: user._id } }, { $group: { _id: '$status', n: { $sum: 1 } } }]),
  ]);
  const refStats = Object.fromEntries(referrals.map((r) => [r._id, r.n]));
  const referralCampaign = campaigns.find((c) => c.type === 'REFERRAL');
  return {
    points: acct?.points ?? 0,
    lifetimePoints: acct?.lifetimePoints ?? 0,
    cashback: { pending: money(acct?.cashbackPendingMinor ?? 0, user.currency), available: money(acct?.cashbackAvailableMinor ?? 0, user.currency), note: 'Cashback is paid out by our licensed payment partner.' },
    referral: {
      code: user.referralCode,
      shareMessage: `Join me on Pesa — track your money and pay bills easily. Use my code ${user.referralCode} when you sign up.`,
      invited: Object.values(refStats).reduce((a, n) => a + n, 0),
      rewarded: refStats.REWARDED ?? 0,
      pending: refStats.PENDING ?? 0,
      rewardPoints: referralCampaign?.rules?.referrerPoints ?? null,
    },
    offers: campaigns.filter((c) => c.type !== 'REFERRAL').map((c) => ({
      id: String(c._id), code: c.code, name: c.name, description: c.description ?? null, type: c.type, endsAt: c.endsAt ?? null, terms: c.terms ?? null,
      cashbackPercent: c.type === 'CASHBACK' ? (c.rules.cashbackBps ?? 0) / 100 : null,
      partner: c.type === 'PARTNER_DEAL' ? c.partner : null,
    })),
  };
}

export async function rewardHistory(userId, q) {
  const page = await paginate(Reward, { userId }, q);
  return {
    ...page,
    items: page.items.map((r) => ({ id: String(r._id), kind: r.kind, entryType: r.entryType, points: r.points, amount: r.currency ? money(r.amountMinor ?? 0, r.currency) : null, description: r.description ?? null, sourceType: r.sourceType, availableAt: r.availableAt ?? null, createdAt: r.createdAt })),
  };
}

/** Redeems points atomically; the conditional $inc prevents overspending under concurrency. */
export async function redeemPoints(user, { points, reward }) {
  const POINTS_CATALOG = { AIRTIME_50: 500, AIRTIME_100: 1000, DATA_1GB: 1500 };
  const cost = POINTS_CATALOG[reward];
  if (!cost || points !== cost) throw Errors.validation([{ path: 'reward', message: 'Unknown reward or wrong points amount' }]);
  const entry = await withTransaction(async (session) => {
    const ok = await RewardAccount.findOneAndUpdate({ userId: user._id, points: { $gte: cost } }, { $inc: { points: -cost } }, { returnDocument: 'after', session });
    if (!ok) throw Errors.unprocessable('INSUFFICIENT_POINTS', 'You do not have enough points');
    const [e] = await Reward.create([{ userId: user._id, kind: 'POINTS', entryType: 'REDEEM', points: -cost, currency: user.currency, sourceType: 'REDEMPTION', description: `Redeemed for ${reward.replace('_', ' ')}`, dedupeKey: `redeem:${user._id}:${Date.now()}:${Math.random()}` }], { session });
    return e;
  });
  return { status: 'REDEMPTION_REQUESTED', redemptionId: String(entry._id), note: 'Your reward will be delivered by our partner shortly.' };
}
