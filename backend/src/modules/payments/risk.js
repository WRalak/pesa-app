import { Transaction } from './models.js';
import { Device } from '../auth/models.js';
import { config } from '../../config/env.js';

/**
 * Rule-based transaction risk scoring. Rules are deliberately transparent so
 * compliance can review them; scores feed the admin fraud queue. A model-based
 * scorer can be added behind the same interface.
 */
export async function assessRisk({ user, amountMinor, counterparty, deviceId, limits }, thresholds = { warn: config.RISK_VELOCITY_WARN, block: config.RISK_VELOCITY_BLOCK }) {
  const flags = [];
  let score = 0;
  const tenMinAgo = new Date(Date.now() - 10 * 60_000);
  const recent = await Transaction.countDocuments({ userId: user._id, createdAt: { $gte: tenMinAgo }, direction: 'DEBIT' });
  if (recent >= thresholds.block) { flags.push('VELOCITY_BLOCK'); score += 100; }
  else if (recent >= thresholds.warn) { flags.push('HIGH_VELOCITY'); score += 30; }

  if (deviceId) {
    const device = await Device.findOne({ userId: user._id, deviceId }, { trustedAt: 1 }).lean();
    if (device?.trustedAt && Date.now() - device.trustedAt.getTime() < 24 * 3600_000 && amountMinor > limits.perTransaction / 2) {
      flags.push('NEW_DEVICE_LARGE_AMOUNT');
      score += 40;
    }
  }
  if (Date.now() - user.createdAt.getTime() < 24 * 3600_000 && amountMinor > limits.perTransaction / 4) {
    flags.push('NEW_ACCOUNT_LARGE_AMOUNT');
    score += 25;
  }
  if (counterparty?.phone && counterparty.phone === user.phone) { flags.push('SELF_TRANSFER'); score += 5; }
  if (user.restrictions?.includes('REVIEW_REQUIRED')) { flags.push('ACCOUNT_UNDER_REVIEW'); score += 50; }

  return { score: Math.min(score, 100), flags, block: score >= 100, reviewRequired: score >= 50 };
}
