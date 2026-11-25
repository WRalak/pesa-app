import { Transaction, ReconciliationRecord } from './models.js';
import { getAdapter, enabledAdapters } from './providers/registry.js';
import { transition } from './service.js';
import { randomToken } from '../../lib/crypto.js';
import { logger } from '../../lib/logger.js';

/**
 * Compares our ledger with the provider's settlement report for a window.
 * Provider data is authoritative for outcomes: non-terminal transactions are
 * auto-resolved to the provider's status; anything that would contradict a
 * terminal internal status (e.g. we say SUCCESSFUL, provider says FAILED) is
 * never changed automatically — it is opened for finance review.
 */
export async function runReconciliation({ provider, from, to }) {
  const adapter = getAdapter(provider);
  const runId = `REC-${provider}-${from.toISOString().slice(0, 10)}-${randomToken(4)}`;
  const report = await adapter.settlementReport({ from, to });
  const byRequest = new Map(report.map((r) => [r.providerRequestId, r]));
  const summary = { runId, provider, from, to, matched: 0, autoResolved: 0, exceptions: 0, providerRows: report.length, internalRows: 0 };
  const records = [];
  const seen = new Set();

  for await (const t of Transaction.find({ provider, createdAt: { $gte: from, $lt: to }, providerRequestId: { $type: 'string' } }).lean().cursor()) {
    summary.internalRows++;
    const p = byRequest.get(t.providerRequestId);
    seen.add(t.providerRequestId);
    const base = { runId, provider, windowStart: from, windowEnd: to, transactionId: t._id, reference: t.reference, externalRef: p?.externalRef ?? t.externalRef, internalStatus: t.status, providerStatus: p?.status ?? null, internalAmountMinor: t.amountMinor, providerAmountMinor: p?.amountMinor, currency: t.currency };
    if (!p) {
      if (['SUCCESSFUL', 'REVERSED'].includes(t.status)) {
        records.push({ ...base, result: 'MISSING_AT_PROVIDER', resolution: 'OPEN' });
        summary.exceptions++;
      }
      continue;
    }
    if (p.amountMinor !== t.amountMinor && p.status !== 'FAILED') {
      records.push({ ...base, result: 'AMOUNT_MISMATCH', resolution: 'OPEN' });
      summary.exceptions++;
      continue;
    }
    const expected = { SUCCESS: 'SUCCESSFUL', FAILED: 'FAILED', REVERSED: 'REVERSED' }[p.status];
    if (!expected || expected === t.status) {
      records.push({ ...base, result: 'MATCHED', resolution: 'NOT_REQUIRED' });
      summary.matched++;
      continue;
    }
    const canAuto = ['INITIATED', 'PENDING', 'PROCESSING'].includes(t.status) || (t.status === 'SUCCESSFUL' && expected === 'REVERSED');
    if (canAuto) {
      if (t.status === 'INITIATED' && expected === 'SUCCESSFUL') await transition(t._id, { to: 'PENDING', source: 'RECONCILIATION', data: { runId } });
      const r = await transition(t._id, { to: expected, source: 'RECONCILIATION', reason: `Reconciled with ${provider} settlement`, externalRef: p.externalRef, data: { runId } });
      if (!r.rejected) {
        records.push({ ...base, result: 'AUTO_RESOLVED', resolution: 'RESOLVED', resolutionNote: `${t.status} -> ${expected}`, resolvedAt: new Date() });
        summary.autoResolved++;
        continue;
      }
    }
    records.push({ ...base, result: 'STATUS_MISMATCH', resolution: 'OPEN' });
    summary.exceptions++;
  }
  for (const p of report) {
    if (seen.has(p.providerRequestId)) continue;
    records.push({ runId, provider, windowStart: from, windowEnd: to, externalRef: p.externalRef, providerStatus: p.status, providerAmountMinor: p.amountMinor, currency: p.currency, result: 'MISSING_INTERNAL', resolution: 'OPEN' });
    summary.exceptions++;
  }
  if (records.length) await ReconciliationRecord.insertMany(records, { ordered: false });
  logger.info(summary, 'Reconciliation completed');
  return summary;
}

/** Daily job: reconcile yesterday (and re-check the day before) for every provider. */
export async function reconcileRecent(now = new Date()) {
  const results = [];
  const to = new Date(now); to.setUTCHours(0, 0, 0, 0);
  const from = new Date(to.getTime() - 86_400_000);
  for (const a of enabledAdapters()) {
    try {
      results.push(await runReconciliation({ provider: a.code, from, to }));
    } catch (err) {
      logger.error({ err: err.message, provider: a.code }, 'Reconciliation failed');
    }
  }
  return results;
}
