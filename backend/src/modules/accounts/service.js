import { LinkedAccount } from './models.js';
import { Errors } from '../../lib/errors.js';
import { money, toMinor } from '../../lib/money.js';
import { getAggregator } from './aggregators.js';
import { audit } from '../audit/service.js';

export function serializeAccount(a) {
  return {
    id: String(a._id),
    kind: a.kind,
    provider: a.provider,
    displayName: a.displayName,
    maskedIdentifier: a.maskedIdentifier ?? null,
    currency: a.currency,
    balance: a.balanceMinor != null ? money(a.balanceMinor, a.currency) : null,
    balanceSource: a.balanceSource,
    balanceAsOf: a.balanceAsOf ?? null,
    sandbox: a.sandbox,
    status: a.status,
    isDefault: a.isDefault,
  };
}

export async function listAccounts(userId) {
  const accounts = await LinkedAccount.find({ userId, status: { $ne: 'UNLINKED' } }).sort({ isDefault: -1, createdAt: 1 }).lean();
  return accounts.map(serializeAccount);
}

export function institutions() {
  return getAggregator()?.institutions ?? [];
}

export async function linkAccount(user, { institution }, req) {
  const agg = getAggregator();
  if (!agg) throw Errors.unprocessable('LINKING_UNAVAILABLE', 'Account linking is not available yet');
  const linked = await agg.link({ institution, currency: user.currency });
  const balance = await agg.fetchBalance({ providerAccountToken: linked.providerAccountToken, currency: user.currency });
  const count = await LinkedAccount.countDocuments({ userId: user._id, status: 'ACTIVE' });
  if (count >= 10) throw Errors.unprocessable('ACCOUNT_LIMIT', 'You can link up to 10 accounts');
  const account = await LinkedAccount.create({
    userId: user._id, provider: institution, ...linked,
    balanceMinor: balance.balanceMinor, balanceSource: 'PROVIDER_VERIFIED', balanceAsOf: balance.asOf,
    isDefault: count === 0,
  });
  await audit({ actorType: 'USER', actorId: user._id, action: 'account.linked', resourceType: 'LinkedAccount', resourceId: account._id, metadata: { institution } }, req);
  return serializeAccount(account);
}

export async function addManualAccount(user, { kind, displayName, balance }) {
  const account = await LinkedAccount.create({
    userId: user._id, kind, provider: 'manual', displayName, currency: user.currency,
    balanceMinor: balance != null ? toMinor(balance, user.currency) : undefined,
    balanceSource: balance != null ? 'MANUAL' : 'UNAVAILABLE', balanceAsOf: balance != null ? new Date() : undefined,
  });
  return serializeAccount(account);
}

export async function updateAccount(user, id, { displayName, balance, isDefault }) {
  const account = await LinkedAccount.findOne({ _id: id, userId: user._id, status: { $ne: 'UNLINKED' } });
  if (!account) throw Errors.notFound('Account');
  if (displayName) account.displayName = displayName;
  if (balance !== undefined) {
    // Verified balances come only from the provider; users cannot overwrite them.
    if (account.provider !== 'manual') throw Errors.unprocessable('BALANCE_READ_ONLY', 'Balances of linked accounts come from your provider and cannot be edited');
    account.balanceMinor = toMinor(balance, user.currency);
    account.balanceSource = 'MANUAL';
    account.balanceAsOf = new Date();
  }
  if (isDefault) {
    await LinkedAccount.updateMany({ userId: user._id }, { $set: { isDefault: false } });
    account.isDefault = true;
  }
  await account.save();
  return serializeAccount(account);
}

export async function refreshBalance(user, id) {
  const account = await LinkedAccount.findOne({ _id: id, userId: user._id, status: 'ACTIVE' }).select('+providerAccountToken');
  if (!account) throw Errors.notFound('Account');
  if (account.provider === 'manual') throw Errors.unprocessable('MANUAL_ACCOUNT', 'Manual accounts have no provider to refresh from');
  const agg = getAggregator();
  if (!agg) throw Errors.unprocessable('LINKING_UNAVAILABLE', 'Balance refresh unavailable');
  try {
    const b = await agg.fetchBalance({ providerAccountToken: account.providerAccountToken, currency: account.currency });
    account.balanceMinor = b.balanceMinor;
    account.balanceSource = 'PROVIDER_VERIFIED';
    account.balanceAsOf = b.asOf;
  } catch {
    account.status = 'REQUIRES_REAUTH';
  }
  await account.save();
  return serializeAccount(account);
}

export async function unlinkAccount(user, id, req) {
  const account = await LinkedAccount.findOneAndUpdate({ _id: id, userId: user._id, status: { $ne: 'UNLINKED' } }, { $set: { status: 'UNLINKED', isDefault: false }, $unset: { providerAccountToken: 1, balanceMinor: 1 } });
  if (!account) throw Errors.notFound('Account');
  await audit({ actorType: 'USER', actorId: user._id, action: 'account.unlinked', resourceType: 'LinkedAccount', resourceId: id }, req);
}
