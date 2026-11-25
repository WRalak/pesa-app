import { SavingsGoal, SavingsContribution } from './models.js';
import { Errors } from '../../lib/errors.js';
import { money, toMinor, percent, subtract } from '../../lib/money.js';
import { paginate } from '../../lib/pagination.js';
import { withTransaction } from '../../lib/db.js';
import { notify } from '../notifications/service.js';

const DAY = 86_400_000;

export function nextReminder(frequency, from = new Date()) {
  const d = new Date(from);
  if (frequency === 'DAILY') return new Date(d.getTime() + DAY);
  if (frequency === 'WEEKLY') return new Date(d.getTime() + 7 * DAY);
  if (frequency === 'MONTHLY') { d.setUTCMonth(d.getUTCMonth() + 1); return d; }
  return null;
}

/** Progress analytics: projection uses the average contribution rate so far. */
export function goalAnalytics(goal, now = new Date()) {
  const remaining = Math.max(0, goal.targetMinor - goal.savedMinor);
  const ageDays = Math.max(1, Math.ceil((now - new Date(goal.createdAt)) / DAY));
  const dailyRate = Math.floor(goal.savedMinor / ageDays);
  const projectedCompletion = remaining === 0 ? now : dailyRate > 0 ? new Date(now.getTime() + Math.ceil(remaining / dailyRate) * DAY) : null;
  let requiredMonthlyMinor = null;
  let onTrack = null;
  if (goal.deadline && remaining > 0) {
    const monthsLeft = Math.max(1, Math.ceil((new Date(goal.deadline) - now) / (30 * DAY)));
    requiredMonthlyMinor = Math.ceil(remaining / monthsLeft);
    onTrack = projectedCompletion ? projectedCompletion <= new Date(goal.deadline) : false;
  }
  return {
    progressPercent: percent(goal.savedMinor, goal.targetMinor),
    remaining: money(remaining, goal.currency),
    projectedCompletion,
    requiredMonthly: requiredMonthlyMinor != null ? money(requiredMonthlyMinor, goal.currency) : null,
    onTrack,
  };
}

export function serializeGoal(g) {
  return {
    id: String(g._id), name: g.name, category: g.category, status: g.status,
    target: money(g.targetMinor, g.currency), saved: money(g.savedMinor, g.currency),
    deadline: g.deadline ?? null, color: g.color ?? null, icon: g.icon ?? null,
    custody: g.custody,
    custodyNote: g.custody === 'TRACKING_ONLY' ? 'Tracking only — funds remain in your own accounts.' : 'Held by an authorised partner.',
    reminder: { frequency: g.reminder?.frequency ?? 'NONE', amount: g.reminder?.amountMinor ? money(g.reminder.amountMinor, g.currency) : null, nextAt: g.reminder?.nextAt ?? null },
    completedAt: g.completedAt ?? null, createdAt: g.createdAt,
    analytics: goalAnalytics(g),
  };
}

export async function listGoals(userId, { status }) {
  const filter = { userId };
  filter.status = status ?? { $in: ['ACTIVE', 'COMPLETED'] };
  const goals = await SavingsGoal.find(filter).sort({ status: 1, createdAt: -1 }).limit(100).lean();
  const items = goals.map(serializeGoal);
  const currency = goals[0]?.currency;
  const totals = goals.filter((g) => g.status !== 'ARCHIVED').reduce((a, g) => ({ saved: a.saved + g.savedMinor, target: a.target + g.targetMinor }), { saved: 0, target: 0 });
  return { items, summary: currency ? { saved: money(totals.saved, currency), target: money(totals.target, currency), progressPercent: percent(totals.saved, totals.target) } : null };
}

async function ownGoal(userId, id) {
  const g = await SavingsGoal.findOne({ _id: id, userId });
  if (!g) throw Errors.notFound('Savings goal');
  return g;
}

export async function createGoal(user, input) {
  const active = await SavingsGoal.countDocuments({ userId: user._id, status: 'ACTIVE' });
  if (active >= 20) throw Errors.unprocessable('GOAL_LIMIT', 'You can have up to 20 active goals');
  if (input.deadline && input.deadline <= new Date()) throw Errors.validation([{ path: 'deadline', message: 'Deadline must be in the future' }]);
  const frequency = input.reminder?.frequency ?? 'NONE';
  const goal = await SavingsGoal.create({
    userId: user._id, name: input.name, category: input.category, currency: user.currency,
    targetMinor: toMinor(input.target, user.currency), deadline: input.deadline, color: input.color, icon: input.icon,
    reminder: { frequency, amountMinor: input.reminder?.amount ? toMinor(input.reminder.amount, user.currency) : undefined, nextAt: nextReminder(frequency) },
  });
  return serializeGoal(goal);
}

export async function getGoal(userId, id) {
  return serializeGoal(await ownGoal(userId, id));
}

export async function updateGoal(user, id, input) {
  const g = await ownGoal(user._id, id);
  if (g.status === 'ARCHIVED') throw Errors.unprocessable('GOAL_ARCHIVED', 'Restore the goal before editing it');
  if (input.name) g.name = input.name;
  if (input.category) g.category = input.category;
  if (input.color) g.color = input.color;
  if (input.icon) g.icon = input.icon;
  if (input.deadline !== undefined) g.deadline = input.deadline ?? undefined;
  if (input.target) {
    g.targetMinor = toMinor(input.target, g.currency);
    if (g.savedMinor >= g.targetMinor && g.status === 'ACTIVE') { g.status = 'COMPLETED'; g.completedAt = new Date(); }
    else if (g.savedMinor < g.targetMinor && g.status === 'COMPLETED') { g.status = 'ACTIVE'; g.completedAt = undefined; }
  }
  if (input.reminder) {
    g.reminder = { frequency: input.reminder.frequency, amountMinor: input.reminder.amount ? toMinor(input.reminder.amount, g.currency) : undefined, nextAt: nextReminder(input.reminder.frequency) };
  }
  await g.save();
  return serializeGoal(g);
}

export async function setArchived(userId, id, archived) {
  const g = await ownGoal(userId, id);
  if (archived) { g.status = 'ARCHIVED'; g.archivedAt = new Date(); }
  else { g.status = g.savedMinor >= g.targetMinor ? 'COMPLETED' : 'ACTIVE'; g.archivedAt = undefined; }
  await g.save();
  return serializeGoal(g);
}

/**
 * Records a contribution or withdrawal. The running balance is updated with a
 * conditional $inc inside a transaction so concurrent entries cannot corrupt
 * it, and withdrawals cannot take the tracked balance below zero.
 */
export async function addContribution(user, id, { kind, amount, note }) {
  const amountMinor = toMinor(amount, user.currency);
  if (amountMinor <= 0) throw Errors.validation([{ path: 'amount', message: 'Amount must be greater than zero' }]);
  const result = await withTransaction(async (session) => {
    const g = await SavingsGoal.findOne({ _id: id, userId: user._id }).session(session);
    if (!g) throw Errors.notFound('Savings goal');
    if (g.status === 'ARCHIVED') throw Errors.unprocessable('GOAL_ARCHIVED', 'Restore the goal before adding entries');
    const delta = kind === 'WITHDRAWAL' ? -amountMinor : amountMinor;
    const guard = kind === 'WITHDRAWAL' ? { savedMinor: { $gte: amountMinor } } : {};
    const updated = await SavingsGoal.findOneAndUpdate({ _id: g._id, ...guard }, { $inc: { savedMinor: delta } }, { new: true, session });
    if (!updated) throw Errors.unprocessable('INSUFFICIENT_SAVED', 'You cannot withdraw more than you have saved toward this goal');
    let completedNow = false;
    if (updated.status === 'ACTIVE' && updated.savedMinor >= updated.targetMinor) {
      updated.status = 'COMPLETED'; updated.completedAt = new Date(); completedNow = true;
      await updated.save({ session });
    } else if (updated.status === 'COMPLETED' && updated.savedMinor < updated.targetMinor) {
      updated.status = 'ACTIVE'; updated.completedAt = undefined;
      await updated.save({ session });
    }
    const [c] = await SavingsContribution.create([{ goalId: g._id, userId: user._id, kind, amountMinor, currency: g.currency, note, balanceAfterMinor: updated.savedMinor }], { session });
    return { goal: updated, contribution: c, completedNow };
  });
  if (result.completedNow) {
    await notify(user._id, { category: 'SAVINGS', type: 'GOAL_COMPLETED', title: 'Goal reached! 🎉', body: `You reached your "${result.goal.name}" goal of ${result.goal.currency} ${money(result.goal.targetMinor, result.goal.currency).amount}.`, data: { route: `/savings/${result.goal._id}` } });
  }
  return { goal: serializeGoal(result.goal), contribution: serializeContribution(result.contribution) };
}

export function serializeContribution(c) {
  return { id: String(c._id), kind: c.kind, amount: money(c.amountMinor, c.currency), note: c.note ?? null, balanceAfter: money(c.balanceAfterMinor, c.currency), createdAt: c.createdAt };
}

export async function listContributions(userId, id, q) {
  await ownGoal(userId, id);
  const page = await paginate(SavingsContribution, { goalId: id, userId }, q);
  return { ...page, items: page.items.map(serializeContribution) };
}

/** Monthly contribution series across goals for charts. */
export async function savingsAnalytics(user, months = 6) {
  const since = new Date(); since.setUTCMonth(since.getUTCMonth() - months + 1); since.setUTCDate(1); since.setUTCHours(0, 0, 0, 0);
  const rows = await SavingsContribution.aggregate([
    { $match: { userId: user._id, createdAt: { $gte: since } } },
    { $group: { _id: { m: { $dateToString: { format: '%Y-%m', date: '$createdAt', timezone: 'Africa/Nairobi' } }, k: '$kind' }, total: { $sum: '$amountMinor' } } },
  ]);
  const series = [];
  for (let i = 0; i < months; i++) {
    const d = new Date(since); d.setUTCMonth(since.getUTCMonth() + i);
    const key = d.toISOString().slice(0, 7);
    const c = rows.find((r) => r._id.m === key && r._id.k === 'CONTRIBUTION')?.total ?? 0;
    const w = rows.find((r) => r._id.m === key && r._id.k === 'WITHDRAWAL')?.total ?? 0;
    series.push({ month: key, contributed: money(c, user.currency), withdrawn: money(w, user.currency), net: money(subtract(c, w), user.currency) });
  }
  return { series };
}

/** Job: send due savings reminders and schedule the next one. */
export async function sendDueReminders(now = new Date()) {
  const due = await SavingsGoal.find({ status: 'ACTIVE', 'reminder.frequency': { $ne: 'NONE' }, 'reminder.nextAt': { $lte: now } }).limit(1000);
  for (const g of due) {
    const amount = g.reminder.amountMinor ? ` ${g.currency} ${money(g.reminder.amountMinor, g.currency).amount}` : '';
    await notify(g.userId, { category: 'SAVINGS', type: 'SAVINGS_REMINDER', title: `Time to save for ${g.name}`, body: `Set aside${amount} toward "${g.name}" — you're ${percent(g.savedMinor, g.targetMinor)}% there.`, data: { route: `/savings/${g._id}` } });
    await SavingsGoal.updateOne({ _id: g._id }, { $set: { 'reminder.nextAt': nextReminder(g.reminder.frequency, now) } });
  }
  return { sent: due.length };
}
