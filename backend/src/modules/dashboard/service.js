import { LinkedAccount } from '../accounts/models.js';
import { serializeAccount } from '../accounts/service.js';
import { Transaction } from '../payments/models.js';
import { serializeTransaction } from '../payments/service.js';
import { listGoals } from '../savings/service.js';
import { listBudgets } from '../budgets/service.js';
import { periodSummary } from '../analytics/service.js';
import { Notification } from '../notifications/models.js';
import { UserProfile } from '../users/models.js';
import { money } from '../../lib/money.js';

/**
 * Home dashboard. Balances are grouped by provenance so the client can
 * never present a manual or estimated figure as a verified balance:
 *   verified  — fetched from a provider via a linked account
 *   manual    — typed in by the user
 *   estimated — derived summaries (income/expenses), never balances
 * The platform holds no customer funds, so there is no "wallet balance".
 */
export async function getDashboard(user) {
  const [accounts, recent, savings, budgets, month, unread, profile, pending] = await Promise.all([
    LinkedAccount.find({ userId: user._id, status: { $ne: 'UNLINKED' } }).lean(),
    Transaction.find({ userId: user._id }).sort({ createdAt: -1, _id: -1 }).limit(5).lean(),
    listGoals(user._id, {}),
    listBudgets(user),
    periodSummary(user, { period: 'MONTHLY' }),
    Notification.countDocuments({ userId: user._id, readAt: null }),
    UserProfile.findOne({ userId: user._id }, { firstName: 1, privacy: 1 }).lean(),
    Transaction.countDocuments({ userId: user._id, status: { $in: ['PENDING', 'PROCESSING'] } }),
  ]);

  const sum = (list) => list.reduce((a, x) => a + (x.balanceMinor ?? 0), 0);
  const verified = accounts.filter((a) => a.balanceSource === 'PROVIDER_VERIFIED' && a.currency === user.currency && a.status === 'ACTIVE');
  const manual = accounts.filter((a) => a.balanceSource === 'MANUAL' && a.currency === user.currency);
  const oldestVerified = verified.reduce((min, a) => (!min || a.balanceAsOf < min ? a.balanceAsOf : min), null);

  return {
    greetingName: profile?.firstName ?? null,
    hideBalances: Boolean(profile?.privacy?.hideBalances),
    balances: {
      verified: { total: verified.length ? money(sum(verified), user.currency) : null, accountCount: verified.length, oldestAsOf: oldestVerified, sandbox: verified.some((a) => a.sandbox) },
      manual: { total: manual.length ? money(sum(manual), user.currency) : null, accountCount: manual.length },
      accounts: accounts.map(serializeAccount),
      note: 'Verified balances come from your linked providers. Manual balances are what you entered.',
    },
    month: {
      income: month.income, expenses: month.expenses, net: month.net,
      byCategory: month.byCategory.slice(0, 6), changeInExpensesPercent: month.changeInExpensesPercent,
      daily: month.daily, basis: 'ESTIMATED', basisNote: month.basisNote,
    },
    recentTransactions: recent.map((t) => serializeTransaction(t)),
    pendingTransactions: pending,
    savings: { summary: savings.summary, goals: savings.items.filter((g) => g.status === 'ACTIVE').slice(0, 3) },
    budget: budgets.items[0] ?? null,
    unreadNotifications: unread,
    quickActions: ['SEND_MONEY', 'RECEIVE_MONEY', 'DEPOSIT', 'AIRTIME', 'PAY_BILLS', 'SAVE'],
  };
}
