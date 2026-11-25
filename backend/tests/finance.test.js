import { describe, it, expect, beforeAll, vi } from 'vitest';
import { api, createUser, idemKey } from './helpers.js';
import { User } from '../src/modules/users/models.js';
import { Transaction } from '../src/modules/payments/models.js';
import { SavingsGoal, SavingsContribution } from '../src/modules/savings/models.js';
import { RecurringItem, Expense } from '../src/modules/budgets/models.js';
import { Notification } from '../src/modules/notifications/models.js';
import { getAdapter } from '../src/modules/payments/providers/registry.js';
import { processCallback } from '../src/modules/payments/service.js';
import { signMockPayload } from '../src/modules/payments/providers/mock.js';
import { sendDueReminders } from '../src/modules/savings/service.js';
import { runRecurring } from '../src/modules/budgets/service.js';
import { buildAggregatePayload } from '../src/modules/insights/external-ai.js';

let ctx;
beforeAll(async () => {
  ctx = await createUser();
  await User.updateOne({ _id: ctx.user.id }, { $set: { kycTier: 'TIER_1' } });
});

async function completedPayment(c, body) {
  const res = await api().post('/v1/payments').set(c.auth()).set('Idempotency-Key', idemKey()).send({ pin: c.pin, ...body }).expect(202);
  const t = await Transaction.findById(res.body.transaction.id).lean();
  const cb = await getAdapter('mock').buildCallback(t.providerRequestId);
  const raw = Buffer.from(JSON.stringify(cb));
  await processCallback('mock', { body: cb, rawBody: raw, ip: '127.0.0.1', params: {}, get: () => signMockPayload(raw) });
  return res.body.transaction.id;
}

describe('savings goals', () => {
  it('creates a tracking-only goal and records contributions atomically', async () => {
    const g = await api().post('/v1/savings/goals').set(ctx.auth()).send({ name: 'Emergency fund', category: 'EMERGENCY', target: '10000', reminder: { frequency: 'WEEKLY', amount: '500' } }).expect(201);
    expect(g.body.custody).toBe('TRACKING_ONLY');
    expect(g.body.target.amountMinor).toBe(1_000_000);
    await Promise.all(Array.from({ length: 10 }, () => api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(ctx.auth()).send({ amount: '100.10' }).expect(201)));
    const detail = await api().get(`/v1/savings/goals/${g.body.id}`).set(ctx.auth()).expect(200);
    expect(detail.body.saved.amount).toBe('1001.00');
    expect(detail.body.analytics.progressPercent).toBe(10);
    expect(await SavingsContribution.countDocuments({ goalId: g.body.id })).toBe(10);
  });

  it('prevents withdrawing more than was saved', async () => {
    const g = await api().post('/v1/savings/goals').set(ctx.auth()).send({ name: 'Rent', target: '5000' }).expect(201);
    await api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(ctx.auth()).send({ amount: '200' }).expect(201);
    const res = await api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(ctx.auth()).send({ kind: 'WITHDRAWAL', amount: '200.01' }).expect(422);
    expect(res.body.error.code).toBe('INSUFFICIENT_SAVED');
  });

  it('completes a goal at the target, notifies, and reopens if the target is raised', async () => {
    const g = await api().post('/v1/savings/goals').set(ctx.auth()).send({ name: 'Phone', category: 'ELECTRONICS', target: '300' }).expect(201);
    const c = await api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(ctx.auth()).send({ amount: '300' }).expect(201);
    expect(c.body.goal.status).toBe('COMPLETED');
    expect(await Notification.exists({ userId: ctx.user.id, type: 'GOAL_COMPLETED' })).toBeTruthy();
    const e = await api().patch(`/v1/savings/goals/${g.body.id}`).set(ctx.auth()).send({ target: '400' }).expect(200);
    expect(e.body.status).toBe('ACTIVE');
    await api().post(`/v1/savings/goals/${g.body.id}/archive`).set(ctx.auth()).expect(200);
    const archived = await api().get('/v1/savings/goals?status=ARCHIVED').set(ctx.auth()).expect(200);
    expect(archived.body.items.some((x) => x.id === g.body.id)).toBe(true);
    await api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(ctx.auth()).send({ amount: '1' }).expect(422);
  });

  it('keeps goals private to their owner', async () => {
    const g = await api().post('/v1/savings/goals').set(ctx.auth()).send({ name: 'Private', target: '100' }).expect(201);
    const other = await createUser({ pin: null });
    await api().get(`/v1/savings/goals/${g.body.id}`).set(other.auth()).expect(404);
    await api().post(`/v1/savings/goals/${g.body.id}/contributions`).set(other.auth()).send({ amount: '1' }).expect(404);
  });

  it('sends due reminders and reschedules them', async () => {
    const goal = await SavingsGoal.findOne({ userId: ctx.user.id, name: 'Emergency fund' });
    await SavingsGoal.updateOne({ _id: goal._id }, { $set: { 'reminder.nextAt': new Date(Date.now() - 1000) } });
    const r = await sendDueReminders();
    expect(r.sent).toBeGreaterThanOrEqual(1);
    const after = await SavingsGoal.findById(goal._id);
    expect(after.reminder.nextAt.getTime()).toBeGreaterThan(Date.now());
  });
});

describe('budgets & alerts', () => {
  it('tracks spend against category limits and alerts once per threshold', async () => {
    const u = await createUser();
    await User.updateOne({ _id: u.user.id }, { $set: { kycTier: 'TIER_1' } });
    const b = await api().post('/v1/budgets').set(u.auth()).send({ name: 'November', period: 'MONTHLY', categories: [{ category: 'food', limit: '1000' }, { category: 'transport', limit: '500' }] }).expect(201);
    expect(b.body.totalLimit.amount).toBe('1500.00');
    await api().post('/v1/budgets').set(u.auth()).send({ name: 'Dup', period: 'MONTHLY', totalLimit: '10' }).expect(409);

    await completedPayment(u, { type: 'BUY_GOODS', tillNumber: '555111', recipientName: 'Naivas', amount: '850.00' });
    let alerts = await Notification.find({ userId: u.user.id, category: 'BUDGET' });
    expect(alerts.map((a) => a.type)).toEqual(['BUDGET_THRESHOLD']);

    await api().post('/v1/budgets/expenses').set(u.auth()).send({ amount: '200', category: 'food', description: 'Mama mboga' }).expect(201);
    alerts = await Notification.find({ userId: u.user.id, category: 'BUDGET' }).sort({ createdAt: 1 });
    expect(alerts.map((a) => a.type)).toEqual(['BUDGET_THRESHOLD', 'BUDGET_EXCEEDED']);

    await api().post('/v1/budgets/expenses').set(u.auth()).send({ amount: '5', category: 'food' }).expect(201);
    expect(await Notification.countDocuments({ userId: u.user.id, category: 'BUDGET' })).toBe(2);

    const list = await api().get('/v1/budgets').set(u.auth()).expect(200);
    const food = list.body.items[0].categories.find((c) => c.category === 'food');
    expect(food.spent.amount).toBe('1055.00');
    expect(food.overspent).toBe(true);
  });

  it('rejects unknown categories', async () => {
    await api().post('/v1/budgets/expenses').set(ctx.auth()).send({ amount: '10', category: 'yachts' }).expect(422);
  });

  it('materialises recurring items exactly once even with concurrent workers', async () => {
    const u = await createUser({ pin: null });
    await api().post('/v1/budgets/recurring').set(u.auth()).send({ kind: 'EXPENSE', amount: '12000', category: 'rent', description: 'Rent', frequency: 'MONTHLY', startDate: new Date(Date.now() - 1000).toISOString() }).expect(201);
    await Promise.all([runRecurring(), runRecurring(), runRecurring()]);
    expect(await Expense.countDocuments({ userId: u.user.id, category: 'rent' })).toBe(1);
    const item = await RecurringItem.findOne({ userId: u.user.id });
    expect(item.nextRunAt.getTime()).toBeGreaterThan(Date.now());
  });
});

describe('analytics, insights and dashboard', () => {
  it('summarises the month from confirmed transactions plus manual entries', async () => {
    const u = await createUser();
    await User.updateOne({ _id: u.user.id }, { $set: { kycTier: 'TIER_1' } });
    await completedPayment(u, { type: 'AIRTIME', amount: '100.00' });
    await api().post('/v1/payments').set(u.auth()).set('Idempotency-Key', idemKey()).send({ type: 'AIRTIME', amount: '999.02', pin: u.pin }).expect(202); // stays pending
    await api().post('/v1/budgets/expenses').set(u.auth()).send({ amount: '50.50', category: 'transport' }).expect(201);
    await api().post('/v1/budgets/income').set(u.auth()).send({ amount: '30000', category: 'salary' }).expect(201);
    const s = await api().get('/v1/analytics/summary').set(u.auth()).expect(200);
    expect(s.body.expenses.amount).toBe('150.50'); // pending payment excluded
    expect(s.body.income.amount).toBe('30000.00');
    expect(s.body.basis).toBe('ESTIMATED');
    expect(s.body.byCategory.map((c) => c.category).sort()).toEqual(['airtime_data', 'transport']);

    const d = await api().get('/v1/dashboard').set(u.auth()).expect(200);
    expect(d.body.balances.verified.total).toBeNull(); // nothing linked: no fabricated balance
    expect(d.body.month.basis).toBe('ESTIMATED');
    expect(d.body.pendingTransactions).toBe(1);
    expect(d.body.recentTransactions).toHaveLength(2);
  });

  it('separates verified and manual balances on the dashboard', async () => {
    const u = await createUser({ pin: null });
    await api().post('/v1/accounts/link').set(u.auth()).send({ institution: 'sandbox-mpesa' }).expect(201);
    const manual = await api().post('/v1/accounts/manual').set(u.auth()).send({ kind: 'CASH', displayName: 'Cash', balance: '2500' }).expect(201);
    expect(manual.body.balanceSource).toBe('MANUAL');
    const accounts = await api().get('/v1/accounts').set(u.auth()).expect(200);
    const linked = accounts.body.items.find((a) => a.provider === 'sandbox-mpesa');
    expect(linked.balanceSource).toBe('PROVIDER_VERIFIED');
    expect(linked.sandbox).toBe(true);
    // Users cannot overwrite a provider-verified balance.
    await api().patch(`/v1/accounts/${linked.id}`).set(u.auth()).send({ balance: '999999' }).expect(422);
    const d = await api().get('/v1/dashboard').set(u.auth()).expect(200);
    expect(d.body.balances.manual.total.amount).toBe('2500.00');
    expect(d.body.balances.verified.total.amountMinor).toBe(linked.balance.amountMinor);
    expect(d.body.balances.verified.sandbox).toBe(true);
  });

  it('flags unusual spending and suggests budgets locally', async () => {
    const u = await createUser();
    await User.updateOne({ _id: u.user.id }, { $set: { kycTier: 'TIER_1' } });
    for (const amt of ['100.00', '120.00', '90.00', '110.00', '105.00', '95.00']) {
      await completedPayment(u, { type: 'BUY_GOODS', tillNumber: '777000', recipientName: 'Java House', amount: amt, confirmDuplicate: true });
    }
    await completedPayment(u, { type: 'BUY_GOODS', tillNumber: '777000', recipientName: 'Java House', amount: '2400.00' });
    const r = await api().get('/v1/insights/monthly-report').set(u.auth()).expect(200);
    expect(r.body.generatedBy).toBe('LOCAL_RULES');
    expect(r.body.unusualTransactions).toHaveLength(1);
    expect(r.body.unusualTransactions[0].amount.amount).toBe('2400.00');
    expect(r.body.insights.find((i) => i.type === 'TOP_CATEGORY').title).toMatch(/food/);
    expect(r.body.externalAi).toEqual({ available: false, consented: false, used: false });
    expect(r.body._aggregates).toBeUndefined();
  });

  it('sends only de-identified aggregates to the external AI payload', () => {
    const payload = buildAggregatePayload({ currency: 'KES', month: '2026-11', incomeMinor: 3_000_000, expenseMinor: 1_234_56, byCategory: { food: 1_000_00 }, avgByCategory: { food: 900_00 } }, 2);
    expect(payload).toEqual({ currency: 'KES', month: '2026-11', income: 30000, spending: 1235, categories: { food: 1000 }, threeMonthAverages: { food: 900 } });
    expect(JSON.stringify(payload)).not.toMatch(/\+254|PSA|Naivas/);
  });

  it('never calls the external AI without consent', async () => {
    const mod = await import('../src/modules/insights/external-ai.js');
    const spy = vi.spyOn(mod, 'generateNarrative');
    await api().get('/v1/insights/monthly-report?narrative=true').set(ctx.auth()).expect(200);
    expect(spy).not.toHaveBeenCalled();
  });
});
