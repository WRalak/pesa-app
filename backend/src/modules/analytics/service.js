import mongoose from 'mongoose';
import { Transaction } from '../payments/models.js';
import { Expense, IncomeRecord } from '../budgets/models.js';
import { money } from '../../lib/money.js';
import { getCountry } from '../../config/countries/index.js';
import { startOfDayInTz, startOfMonthInTz } from '../payments/service.js';

const DAY = 86_400_000;
/** Credits that are movements between the user's own accounts, not income. */
const NON_INCOME_CREDIT_TYPES = ['DEPOSIT'];

export function periodWindow(period, tz, date = new Date()) {
  if (period === 'WEEKLY') {
    const sod = startOfDayInTz(tz, date);
    const dow = new Intl.DateTimeFormat('en-GB', { timeZone: tz, weekday: 'short' }).format(date);
    const offset = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(dow);
    const from = new Date(sod.getTime() - offset * DAY);
    return { from, to: new Date(from.getTime() + 7 * DAY), key: `W${from.toISOString().slice(0, 10)}` };
  }
  const from = startOfMonthInTz(tz, date);
  const next = startOfMonthInTz(tz, new Date(from.getTime() + 32 * DAY));
  return { from, to: next, key: `M${new Date(from.getTime() + DAY).toISOString().slice(0, 7)}` };
}

/**
 * Aggregates income and spending for a window from (a) provider-confirmed
 * SUCCESSFUL transactions and (b) manually recorded expenses/income. Results
 * are labelled as estimates since manual entries are user-reported.
 */
export async function aggregateWindow(user, from, to) {
  const userId = new mongoose.Types.ObjectId(String(user._id));
  const [tx, exp, inc] = await Promise.all([
    Transaction.aggregate([
      { $match: { userId, status: 'SUCCESSFUL', completedAt: { $gte: from, $lt: to } } },
      { $group: { _id: { d: '$direction', c: '$category', t: '$type' }, total: { $sum: '$totalMinor' }, count: { $sum: 1 } } },
    ]),
    Expense.aggregate([{ $match: { userId, date: { $gte: from, $lt: to } } }, { $group: { _id: '$category', total: { $sum: '$amountMinor' }, count: { $sum: 1 } } }]),
    IncomeRecord.aggregate([{ $match: { userId, date: { $gte: from, $lt: to } } }, { $group: { _id: '$category', total: { $sum: '$amountMinor' } } }]),
  ]);
  const byCategory = {};
  let expenseMinor = 0;
  let incomeMinor = 0;
  let transactionCount = 0;
  for (const r of tx) {
    transactionCount += r.count;
    if (r._id.d === 'DEBIT') {
      byCategory[r._id.c] = (byCategory[r._id.c] ?? 0) + r.total;
      expenseMinor += r.total;
    } else if (!NON_INCOME_CREDIT_TYPES.includes(r._id.t)) {
      incomeMinor += r.total;
    }
  }
  for (const r of exp) {
    byCategory[r._id] = (byCategory[r._id] ?? 0) + r.total;
    expenseMinor += r.total;
  }
  for (const r of inc) incomeMinor += r.total;
  return { incomeMinor, expenseMinor, byCategory, transactionCount, manualEntries: exp.reduce((a, r) => a + r.count, 0) };
}

export async function dailySeries(user, from, to) {
  const userId = new mongoose.Types.ObjectId(String(user._id));
  const tz = getCountry(user.country).timezone;
  const [tx, exp] = await Promise.all([
    Transaction.aggregate([
      { $match: { userId, status: 'SUCCESSFUL', direction: 'DEBIT', completedAt: { $gte: from, $lt: to } } },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$completedAt', timezone: tz } }, total: { $sum: '$totalMinor' } } },
    ]),
    Expense.aggregate([
      { $match: { userId, date: { $gte: from, $lt: to } } },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$date', timezone: tz } }, total: { $sum: '$amountMinor' } } },
    ]),
  ]);
  const map = new Map();
  for (const r of [...tx, ...exp]) map.set(r._id, (map.get(r._id) ?? 0) + r.total);
  const out = [];
  for (let t = from.getTime(); t < to.getTime() && t <= Date.now(); t += DAY) {
    const key = new Intl.DateTimeFormat('en-CA', { timeZone: tz }).format(new Date(t + 3600_000));
    out.push({ date: key, spent: money(map.get(key) ?? 0, user.currency) });
  }
  return out;
}

function serializeAgg(agg, currency) {
  return {
    income: money(agg.incomeMinor, currency),
    expenses: money(agg.expenseMinor, currency),
    net: money(agg.incomeMinor - agg.expenseMinor, currency),
    byCategory: Object.entries(agg.byCategory).sort((a, b) => b[1] - a[1]).map(([category, v]) => ({ category, amount: money(v, currency), share: agg.expenseMinor ? Math.round((v * 1000) / agg.expenseMinor) / 10 : 0 })),
    transactionCount: agg.transactionCount,
    manualEntries: agg.manualEntries,
  };
}

export async function periodSummary(user, { period = 'MONTHLY', date = new Date() } = {}) {
  const tz = getCountry(user.country).timezone;
  const w = periodWindow(period, tz, date);
  const prev = periodWindow(period, tz, new Date(w.from.getTime() - DAY));
  const [cur, before, daily] = await Promise.all([aggregateWindow(user, w.from, w.to), aggregateWindow(user, prev.from, prev.to), dailySeries(user, w.from, w.to)]);
  return {
    period, from: w.from, to: w.to,
    ...serializeAgg(cur, user.currency),
    previous: { income: money(before.incomeMinor, user.currency), expenses: money(before.expenseMinor, user.currency) },
    changeInExpensesPercent: before.expenseMinor ? Math.round(((cur.expenseMinor - before.expenseMinor) * 1000) / before.expenseMinor) / 10 : null,
    daily,
    basis: 'ESTIMATED',
    basisNote: 'Based on completed transactions in this app plus entries you recorded manually. Not a bank statement.',
  };
}

export async function monthlyTrends(user, months = 6) {
  const tz = getCountry(user.country).timezone;
  const out = [];
  let cursor = new Date();
  for (let i = 0; i < months; i++) {
    const w = periodWindow('MONTHLY', tz, cursor);
    const agg = await aggregateWindow(user, w.from, w.to);
    out.unshift({ month: w.key.slice(1), income: money(agg.incomeMinor, user.currency), expenses: money(agg.expenseMinor, user.currency) });
    cursor = new Date(w.from.getTime() - DAY);
  }
  return { months: out, basis: 'ESTIMATED' };
}
