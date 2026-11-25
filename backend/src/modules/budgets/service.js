import { Budget, Expense, IncomeRecord, RecurringItem } from './models.js';
import { EXPENSE_CATEGORIES, INCOME_CATEGORIES, EXPENSE_KEYS, INCOME_KEYS } from './categories.js';
import { Errors } from '../../lib/errors.js';
import { money, toMinor, percent } from '../../lib/money.js';
import { paginate } from '../../lib/pagination.js';
import { getCountry } from '../../config/countries/index.js';
import { periodWindow, aggregateWindow } from '../analytics/service.js';
import { notify } from '../notifications/service.js';
import { User } from '../users/models.js';

export const categories = () => ({ expense: EXPENSE_CATEGORIES, income: INCOME_CATEGORIES });

function assertCategory(key, kind) {
  const keys = kind === 'INCOME' ? INCOME_KEYS : EXPENSE_KEYS;
  if (!keys.includes(key)) throw Errors.validation([{ path: 'category', message: 'Unknown category' }]);
}

async function budgetStatus(user, b, date = new Date()) {
  const w = periodWindow(b.period, getCountry(user.country).timezone, date);
  const agg = await aggregateWindow(user, w.from, w.to);
  const cats = b.categories.map((c) => {
    const spent = agg.byCategory[c.category] ?? 0;
    return { category: c.category, limit: money(c.limitMinor, b.currency), spent: money(spent, b.currency), remaining: money(Math.max(0, c.limitMinor - spent), b.currency), percentUsed: c.limitMinor ? Math.round((spent * 100) / c.limitMinor) : 0, overspent: spent > c.limitMinor };
  });
  const budgetedSpend = b.categories.length ? b.categories.reduce((a, c) => a + (agg.byCategory[c.category] ?? 0), 0) : agg.expenseMinor;
  const totalLimit = b.totalLimitMinor ?? b.categories.reduce((a, c) => a + c.limitMinor, 0);
  const spentForTotal = b.totalLimitMinor != null ? agg.expenseMinor : budgetedSpend;
  const elapsed = Math.min(1, (Date.now() - w.from) / (w.to - w.from));
  return {
    window: { from: w.from, to: w.to, key: w.key },
    totalLimit: money(totalLimit, b.currency),
    spent: money(spentForTotal, b.currency),
    remaining: money(Math.max(0, totalLimit - spentForTotal), b.currency),
    percentUsed: totalLimit ? Math.round((spentForTotal * 100) / totalLimit) : 0,
    periodElapsedPercent: Math.round(elapsed * 100),
    onPace: totalLimit ? spentForTotal <= totalLimit * elapsed * 1.05 : true,
    categories: cats,
    _raw: { spentForTotal, totalLimit, byCategory: agg.byCategory },
  };
}

export async function serializeBudget(user, b) {
  const status = await budgetStatus(user, b);
  const { _raw, ...rest } = status;
  return { id: String(b._id), name: b.name, period: b.period, active: b.active, alertThresholds: b.alertThresholds, ...rest };
}

export async function listBudgets(user) {
  const budgets = await Budget.find({ userId: user._id, active: true }).sort({ createdAt: -1 }).limit(20);
  return { items: await Promise.all(budgets.map((b) => serializeBudget(user, b))) };
}

function parseCategories(user, cats = []) {
  const seen = new Set();
  return cats.map((c) => {
    assertCategory(c.category, 'EXPENSE');
    if (seen.has(c.category)) throw Errors.validation([{ path: 'categories', message: `Duplicate category ${c.category}` }]);
    seen.add(c.category);
    return { category: c.category, limitMinor: toMinor(c.limit, user.currency) };
  });
}

export async function createBudget(user, input) {
  if (!input.totalLimit && !input.categories?.length) throw Errors.validation([{ path: 'categories', message: 'Set a total limit or at least one category limit' }]);
  if (await Budget.exists({ userId: user._id, active: true, period: input.period })) {
    throw Errors.conflict(`You already have an active ${input.period.toLowerCase()} budget. Edit it instead.`, 'BUDGET_EXISTS');
  }
  const b = await Budget.create({
    userId: user._id, name: input.name, period: input.period, currency: user.currency,
    totalLimitMinor: input.totalLimit ? toMinor(input.totalLimit, user.currency) : undefined,
    categories: parseCategories(user, input.categories), alertThresholds: input.alertThresholds ?? [80, 100],
  });
  return serializeBudget(user, b);
}

export async function updateBudget(user, id, input) {
  const b = await Budget.findOne({ _id: id, userId: user._id, active: true });
  if (!b) throw Errors.notFound('Budget');
  if (input.name) b.name = input.name;
  if (input.totalLimit !== undefined) b.totalLimitMinor = input.totalLimit ? toMinor(input.totalLimit, user.currency) : undefined;
  if (input.categories) b.categories = parseCategories(user, input.categories);
  if (input.alertThresholds) b.alertThresholds = input.alertThresholds;
  await b.save();
  return serializeBudget(user, b);
}

export async function deleteBudget(userId, id) {
  const r = await Budget.updateOne({ _id: id, userId, active: true }, { $set: { active: false } });
  if (!r.matchedCount) throw Errors.notFound('Budget');
}

/**
 * Evaluates every active budget and sends threshold alerts once per period,
 * category and threshold (deduplicated atomically via `alertsSent`).
 */
export async function evaluateBudgetAlerts(userId) {
  const user = await User.findById(userId);
  if (!user) return [];
  const budgets = await Budget.find({ userId, active: true });
  const sent = [];
  for (const b of budgets) {
    const s = await budgetStatus(user, b);
    const checks = [{ scope: 'TOTAL', spent: s._raw.spentForTotal, limit: s._raw.totalLimit, label: b.name }];
    for (const c of b.categories) checks.push({ scope: c.category, spent: s._raw.byCategory[c.category] ?? 0, limit: c.limitMinor, label: c.category.replace(/_/g, ' ') });
    for (const chk of checks) {
      if (!chk.limit) continue;
      const pct = percent(chk.spent, chk.limit);
      const crossed = [...b.alertThresholds].sort((x, y) => y - x).find((t) => (t >= 100 ? chk.spent > chk.limit || pct >= 100 : pct >= t));
      if (!crossed) continue;
      const key = `${s.window.key}:${chk.scope}:${crossed}`;
      const claimed = await Budget.updateOne({ _id: b._id, alertsSent: { $ne: key } }, { $push: { alertsSent: { $each: [key], $slice: -200 } } });
      if (!claimed.modifiedCount) continue;
      const over = crossed >= 100;
      await notify(userId, {
        category: 'BUDGET',
        type: over ? 'BUDGET_EXCEEDED' : 'BUDGET_THRESHOLD',
        title: over ? `Over budget: ${chk.label}` : `${crossed}% of ${chk.label} budget used`,
        body: over
          ? `You've spent ${b.currency} ${money(chk.spent, b.currency).amount} of ${money(chk.limit, b.currency).amount} this ${b.period === 'WEEKLY' ? 'week' : 'month'}.`
          : `You've used ${pct}% of your ${chk.label} budget. ${b.currency} ${money(Math.max(0, chk.limit - chk.spent), b.currency).amount} left.`,
        data: { route: '/budgets', budgetId: String(b._id) },
      });
      sent.push(key);
    }
  }
  return sent;
}

// ---------------------------------------------------------------- manual entries
function serializeEntry(e) {
  return { id: String(e._id), amount: money(e.amountMinor, e.currency), category: e.category, description: e.description ?? null, date: e.date, paymentMethod: e.paymentMethod, recurring: Boolean(e.recurringItemId), createdAt: e.createdAt };
}

export async function addEntry(user, kind, input) {
  assertCategory(input.category, kind);
  const Model = kind === 'INCOME' ? IncomeRecord : Expense;
  const e = await Model.create({ userId: user._id, amountMinor: toMinor(input.amount, user.currency), currency: user.currency, category: input.category, description: input.description, date: input.date ?? new Date(), paymentMethod: input.paymentMethod });
  if (kind === 'EXPENSE') await evaluateBudgetAlerts(user._id);
  return serializeEntry(e);
}

export async function listEntries(user, kind, q) {
  const Model = kind === 'INCOME' ? IncomeRecord : Expense;
  const filter = { userId: user._id };
  if (q.category) filter.category = q.category;
  const page = await paginate(Model, filter, { ...q, sortField: 'date' });
  return { ...page, items: page.items.map(serializeEntry) };
}

export async function updateEntry(user, kind, id, input) {
  const Model = kind === 'INCOME' ? IncomeRecord : Expense;
  const set = {};
  if (input.amount) set.amountMinor = toMinor(input.amount, user.currency);
  if (input.category) { assertCategory(input.category, kind); set.category = input.category; }
  if (input.description !== undefined) set.description = input.description;
  if (input.date) set.date = input.date;
  const e = await Model.findOneAndUpdate({ _id: id, userId: user._id }, { $set: set }, { new: true }).lean();
  if (!e) throw Errors.notFound(kind === 'INCOME' ? 'Income record' : 'Expense');
  return serializeEntry(e);
}

export async function deleteEntry(user, kind, id) {
  const Model = kind === 'INCOME' ? IncomeRecord : Expense;
  const r = await Model.deleteOne({ _id: id, userId: user._id });
  if (!r.deletedCount) throw Errors.notFound('Entry');
}

// ---------------------------------------------------------------- recurring
export function nextRun(frequency, from) {
  const d = new Date(from);
  if (frequency === 'WEEKLY') return new Date(d.getTime() + 7 * 86_400_000);
  d.setUTCMonth(d.getUTCMonth() + 1);
  return d;
}

function serializeRecurring(r) {
  return { id: String(r._id), kind: r.kind, amount: money(r.amountMinor, r.currency), category: r.category, description: r.description ?? null, frequency: r.frequency, nextRunAt: r.nextRunAt, active: r.active };
}

export async function createRecurring(user, input) {
  assertCategory(input.category, input.kind);
  const r = await RecurringItem.create({ userId: user._id, kind: input.kind, amountMinor: toMinor(input.amount, user.currency), currency: user.currency, category: input.category, description: input.description, frequency: input.frequency, nextRunAt: input.startDate ?? new Date() });
  return serializeRecurring(r);
}

export async function listRecurring(user) {
  return { items: (await RecurringItem.find({ userId: user._id, active: true }).sort({ nextRunAt: 1 }).lean()).map(serializeRecurring) };
}

export async function stopRecurring(user, id) {
  const r = await RecurringItem.updateOne({ _id: id, userId: user._id, active: true }, { $set: { active: false } });
  if (!r.matchedCount) throw Errors.notFound('Recurring item');
}

/** Job: materialise due recurring entries. Claims each item atomically to avoid double-posting across workers. */
export async function runRecurring(now = new Date()) {
  let created = 0;
  for (let i = 0; i < 1000; i++) {
    // Claim + advance in one atomic update; `new: false` returns the run being executed.
    const item = await RecurringItem.findOneAndUpdate(
      { active: true, nextRunAt: { $lte: now } },
      [{ $set: { nextRunAt: { $dateAdd: { startDate: '$nextRunAt', unit: { $cond: [{ $eq: ['$frequency', 'WEEKLY'] }, 'week', 'month'] }, amount: 1 } } } }],
      { new: false, sort: { nextRunAt: 1 }, updatePipeline: true },
    );
    if (!item) break;
    const Model = item.kind === 'INCOME' ? IncomeRecord : Expense;
    await Model.create({ userId: item.userId, amountMinor: item.amountMinor, currency: item.currency, category: item.category, description: item.description, date: item.nextRunAt, recurringItemId: item._id });
    if (item.kind === 'EXPENSE') await evaluateBudgetAlerts(item.userId);
    created++;
  }
  return { created };
}
