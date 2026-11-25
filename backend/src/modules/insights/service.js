import { monthlyReport } from './engine.js';
import { externalAiAvailable, buildAggregatePayload, generateNarrative } from './external-ai.js';
import { Transaction } from '../payments/models.js';
import { categorize } from '../budgets/categorizer.js';
import { getCurrency } from '../../config/currencies.js';
import { getRedis } from '../../lib/redis.js';
import { logger } from '../../lib/logger.js';
import { sha256, canonical } from '../../lib/crypto.js';

export async function getMonthlyReport(user, { date, narrative }) {
  const report = await monthlyReport(user, date);
  const { _aggregates, ...publicReport } = report;
  publicReport.externalAi = { available: externalAiAvailable(), consented: Boolean(user.consents?.externalAiProcessing), used: false };

  if (narrative && externalAiAvailable() && user.consents?.externalAiProcessing) {
    const payload = buildAggregatePayload({ currency: user.currency, month: report.month, ..._aggregates }, getCurrency(user.currency).minorUnits);
    const key = `ai-narrative:${user._id}:${sha256(canonical(payload)).slice(0, 16)}:${user.locale}`;
    try {
      const cached = await getRedis().get(key);
      const result = cached ? JSON.parse(cached) : await generateNarrative(payload, user.locale);
      if (result) {
        if (!cached) await getRedis().set(key, JSON.stringify(result), 'EX', 86_400);
        publicReport.summary = result.summary;
        publicReport.aiTips = result.tips;
        publicReport.generatedBy = 'EXTERNAL_AI';
        publicReport.externalAi.used = true;
      }
    } catch (err) {
      logger.warn({ err: err.message }, 'External AI narrative failed; using local summary');
    }
  }
  return publicReport;
}

/** Re-runs the local categoriser over the user's uncategorised transactions. */
export async function recategorize(user) {
  const items = await Transaction.find({ userId: user._id, categorySource: { $in: ['DEFAULT'] } }, { type: 1, description: 1, counterparty: 1 }).limit(500).lean();
  let updated = 0;
  for (const t of items) {
    const c = categorize(t);
    if (c.category !== 'uncategorised') {
      await Transaction.updateOne({ _id: t._id, categorySource: 'DEFAULT' }, { $set: { category: c.category, categorySource: 'RULE' } });
      updated++;
    }
  }
  return { scanned: items.length, updated };
}
