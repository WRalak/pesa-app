import mongoose from 'mongoose';
import { Transaction } from '../payments/models.js';
import { Budget } from '../budgets/models.js';
import { aggregateWindow, periodWindow } from '../analytics/service.js';
import { money } from '../../lib/money.js';
import { getCountry } from '../../config/countries/index.js';

const DAY = 86_400_000;

/**
 * Local financial-intelligence engine. Deterministic statistics over the
 * user's own data, executed inside the platform — nothing is sent to third
 * parties. This module is read-only: it has no access to payment initiation
 * and can never move money.
 */
export async function unusualTransactions(user, { lookbackDays = 90, since } = {}) {
  const userId = new mongoose.Types.ObjectId(String(user._id));
  const from = new Date(Date.now() - lookbackDays * DAY);
  // Robust statistics (median + MAD) so a single large outlier cannot hide itself.
  const stats = await Transaction.aggregate([
    { $match: { userId, status: 'SUCCESSFUL', direction: 'DEBIT', completedAt: { $gte: from } } },
    { $sort: { completedAt: -1 } },
    { $limit: 5000 },
    { $group: { _id: '$category', amounts: { $push: '$totalMinor' } } },
  ]);
  const median = (xs) => { const a = [...xs].sort((x, y) => x - y); const m = a.length >> 1; return a.length % 2 ? a[m] : (a[m - 1] + a[m]) / 2; };
  const byCat = {};
  for (const s of stats) {
    const med = median(s.amounts);
    const mad = median(s.amounts.map((x) => Math.abs(x - med))) * 1.4826;
    byCat[s._id] = { med, mad, n: s.amounts.length };
  }
  const recent = await Transaction.find({ userId, status: 'SUCCESSFUL', direction: 'DEBIT', completedAt: { $gte: since ?? new Date(Date.now() - 30 * DAY) } }).sort({ totalMinor: -1 }).limit(200).lean();
  const out = [];
  for (const t of recent) {
    const s = byCat[t.category];
    if (!s || s.n < 5 || !s.med) continue;
    if (t.totalMinor > s.med + 5 * Math.max(s.mad, s.med * 0.1) && t.totalMinor > 3 * s.med) {
      out.push({ transactionId: String(t._id), reference: t.reference, category: t.category, amount: money(t.totalMinor, t.currency), typical: money(Math.round(s.med), t.currency), timesTypical: Math.round((t.totalMinor / s.med) * 10) / 10, at: t.completedAt });
    }
  }
  return out.slice(0, 10);
}

export async function spendingPatterns(user) {
  const userId = new mongoose.Types.ObjectId(String(user._id));
  const tz = getCountry(user.country).timezone;
  const rows = await Transaction.aggregate([
    { $match: { userId, status: 'SUCCESSFUL', direction: 'DEBIT', completedAt: { $gte: new Date(Date.now() - 90 * DAY) } } },
    { $group: { _id: { $dayOfWeek: { date: '$completedAt', timezone: tz } }, total: { $sum: '$totalMinor' }, n: { $sum: 1 } } },
  ]);
  const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const byDay = names.map((name, i) => ({ day: name, spent: money(rows.find((r) => r._id === i + 1)?.total ?? 0, user.currency), count: rows.find((r) => r._id === i + 1)?.n ?? 0 }));
  const peak = [...byDay].sort((a, b) => b.spent.amountMinor - a.spent.amountMinor)[0];
  return { byDayOfWeek: byDay, peakDay: peak?.spent.amountMinor ? peak.day : null };
}

function roundUp(minor, step) {
  return Math.ceil(minor / step) * step;
}

export async function monthlyReport(user, date = new Date()) {
  const tz = getCountry(user.country).timezone;
  const cur = periodWindow('MONTHLY', tz, date);
  const prevWindows = [];
  let d = new Date(cur.from.getTime() - DAY);
  for (let i = 0; i < 3; i++) { const w = periodWindow('MONTHLY', tz, d); prevWindows.push(w); d = new Date(w.from.getTime() - DAY); }
  const [now, ...prev] = await Promise.all([aggregateWindow(user, cur.from, cur.to), ...prevWindows.map((w) => aggregateWindow(user, w.from, w.to))]);
  const c = user.currency;
  const step = c === 'UGX' || c === 'RWF' ? 1000 : 100_00;

  const avgByCat = {};
  for (const p of prev) for (const [k, v] of Object.entries(p.byCategory)) avgByCat[k] = (avgByCat[k] ?? 0) + v / prev.length;

  const insights = [];
  const top = Object.entries(now.byCategory).sort((a, b) => b[1] - a[1]);
  if (top.length) {
    const [cat, amt] = top[0];
    insights.push({ type: 'TOP_CATEGORY', severity: 'INFO', title: `Most of your spending went to ${cat.replace(/_/g, ' ')}`, detail: `${c} ${money(amt, c).amount} (${now.expenseMinor ? Math.round((amt * 100) / now.expenseMinor) : 0}% of spending).` });
  }
  for (const [cat, amt] of top) {
    const avg = avgByCat[cat];
    if (avg && amt > avg * 1.5 && amt - avg > step / 2) {
      insights.push({ type: 'CATEGORY_SPIKE', severity: 'WARNING', title: `${cat.replace(/_/g, ' ')} spending is up`, detail: `${c} ${money(amt, c).amount} this month vs a ${c} ${money(Math.round(avg), c).amount} average over the last 3 months.` });
    }
  }
  if (now.incomeMinor > 0) {
    const rate = Math.round(((now.incomeMinor - now.expenseMinor) * 100) / now.incomeMinor);
    insights.push(rate < 10
      ? { type: 'LOW_SAVINGS_RATE', severity: 'WARNING', title: 'Little left over this month', detail: `You kept ${Math.max(rate, 0)}% of recorded income. Many people aim for 10–20%.` }
      : { type: 'SAVINGS_RATE', severity: 'POSITIVE', title: `You kept ${rate}% of your income`, detail: 'Consider moving some of it toward a savings goal.' });
  }

  const suggestions = [];
  const hasBudget = await Budget.exists({ userId: user._id, active: true });
  const suggestedCategories = Object.entries(avgByCat).filter(([k]) => !['transfers', 'savings'].includes(k)).sort((a, b) => b[1] - a[1]).slice(0, 5)
    .map(([category, avg]) => ({ category, suggestedLimit: money(roundUp(Math.round(avg), step), c) }));
  if (!hasBudget && suggestedCategories.length) {
    suggestions.push({ type: 'CREATE_BUDGET', title: 'Set a monthly budget', detail: 'Based on your last 3 months, here are starting limits you can adjust.', categories: suggestedCategories });
  }
  const dominant = top.find(([k, v]) => !['transfers', 'savings', 'rent'].includes(k) && now.expenseMinor && v / now.expenseMinor > 0.3);
  if (dominant) suggestions.push({ type: 'CAP_CATEGORY', title: `Consider a cap on ${dominant[0].replace(/_/g, ' ')}`, detail: 'It makes up over 30% of your spending this month.' });

  const unusual = await unusualTransactions(user, { since: cur.from });
  return {
    month: cur.key.slice(1),
    income: money(now.incomeMinor, c),
    expenses: money(now.expenseMinor, c),
    topCategories: top.slice(0, 5).map(([category, v]) => ({ category, amount: money(v, c) })),
    insights,
    suggestions,
    unusualTransactions: unusual,
    patterns: await spendingPatterns(user),
    summary: localNarrative(now, top, c),
    basis: 'ESTIMATED',
    generatedBy: 'LOCAL_RULES',
    _aggregates: { incomeMinor: now.incomeMinor, expenseMinor: now.expenseMinor, byCategory: now.byCategory, avgByCategory: avgByCat },
  };
}

function localNarrative(now, top, c) {
  if (!now.expenseMinor && !now.incomeMinor) return 'No completed transactions or manual entries yet this month.';
  const parts = [`This month you spent ${c} ${money(now.expenseMinor, c).amount}`];
  if (now.incomeMinor) parts.push(`against recorded income of ${c} ${money(now.incomeMinor, c).amount}`);
  let s = `${parts.join(' ')}.`;
  if (top[0]) s += ` Your biggest category was ${top[0][0].replace(/_/g, ' ')}.`;
  return s;
}
