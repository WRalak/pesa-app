import mongoose from 'mongoose';
import { Card } from './models.js';
import { getIssuer, issuerAvailable } from './issuers.js';
import { Transaction, TransactionEvent } from '../payments/models.js';
import { newReference, serializeTransaction, transition } from '../payments/service.js';
import { paginate } from '../../lib/pagination.js';
import { Errors } from '../../lib/errors.js';
import { money, toMinor } from '../../lib/money.js';
import { withTransaction } from '../../lib/db.js';
import { verifyPin } from '../auth/service.js';
import { audit } from '../audit/service.js';
import { notify } from '../notifications/service.js';
import { categorize } from '../budgets/categorizer.js';
import { startOfDayInTz } from '../payments/service.js';
import { getCountry } from '../../config/countries/index.js';
import { User } from '../users/models.js';
import { config } from '../../config/env.js';

export function serializeCard(c) {
  return {
    id: String(c._id), kind: c.kind, issuer: c.issuer, brand: c.brand, last4: c.last4,
    expiry: `${String(c.expiryMonth).padStart(2, '0')}/${String(c.expiryYear).slice(-2)}`,
    nameOnCard: c.nameOnCard ?? null, nickname: c.nickname ?? null, currency: c.currency,
    status: c.status, sandbox: c.sandbox,
    controls: {
      perTransaction: c.controls?.perTransactionMinor != null ? money(c.controls.perTransactionMinor, c.currency) : null,
      daily: c.controls?.dailyMinor != null ? money(c.controls.dailyMinor, c.currency) : null,
      monthly: c.controls?.monthlyMinor != null ? money(c.controls.monthlyMinor, c.currency) : null,
      online: c.controls?.online ?? true, international: c.controls?.international ?? false, atm: c.controls?.atm ?? true,
    },
  };
}

async function ownCard(userId, id, { withToken = false } = {}) {
  const q = Card.findOne({ _id: id, userId, status: { $ne: 'CLOSED' } });
  if (withToken) q.select('+providerCardToken');
  const c = await q;
  if (!c) throw Errors.notFound('Card');
  return c;
}

export async function listCards(userId) {
  return { items: (await Card.find({ userId, status: { $ne: 'CLOSED' } }).sort({ createdAt: -1 }).lean()).map(serializeCard), issuingAvailable: issuerAvailable() };
}

export async function issueVirtualCard(user, { nickname, pin }, req) {
  if (!issuerAvailable()) throw Errors.unprocessable('ISSUING_UNAVAILABLE', 'Virtual cards are not available yet');
  if (user.kycStatus !== 'VERIFIED' && !config.isDev && !config.isTest) throw Errors.forbidden('Verify your identity to get a virtual card');
  await verifyPin(user._id, pin, req);
  if ((await Card.countDocuments({ userId: user._id, kind: 'VIRTUAL', status: { $ne: 'CLOSED' } })) >= 3) throw Errors.unprocessable('CARD_LIMIT', 'You can have up to 3 virtual cards');
  const issuer = getIssuer();
  const issued = await issuer.issueVirtual({ user, currency: user.currency });
  const card = await Card.create({ userId: user._id, kind: 'VIRTUAL', issuer: issuer.code, providerCardToken: issued.token, brand: issued.brand, last4: issued.last4, expiryMonth: issued.expiryMonth, expiryYear: issued.expiryYear, nickname, currency: user.currency, sandbox: !config.isProd });
  await audit({ actorType: 'USER', actorId: user._id, action: 'card.issued', resourceType: 'Card', resourceId: card._id }, req);
  await notify(user._id, { category: 'SECURITY', type: 'CARD_ISSUED', title: 'Virtual card created', body: `Your ${issued.brand} card ending ${issued.last4} is ready.`, data: { route: `/cards/${card._id}` } });
  return serializeCard(card);
}

export async function linkCard(user, { paymentMethodToken, nickname }, req) {
  const issuer = getIssuer();
  let t;
  try {
    t = await issuer.tokenizeLinked(paymentMethodToken);
  } catch {
    throw Errors.unprocessable('CARD_TOKEN_INVALID', 'We could not verify this card. Please try again.');
  }
  const card = await Card.create({ userId: user._id, kind: 'LINKED', issuer: issuer.code, providerCardToken: t.token, brand: t.brand, last4: t.last4, expiryMonth: t.expiryMonth, expiryYear: t.expiryYear, nickname, currency: user.currency, sandbox: !config.isProd });
  await audit({ actorType: 'USER', actorId: user._id, action: 'card.linked', resourceType: 'Card', resourceId: card._id }, req);
  return serializeCard(card);
}

export async function setFrozen(user, id, frozen, req) {
  const card = await ownCard(user._id, id, { withToken: true });
  await getIssuer(card.issuer).setStatus(card.providerCardToken, frozen ? 'FROZEN' : 'ACTIVE');
  card.status = frozen ? 'FROZEN' : 'ACTIVE';
  card.frozenAt = frozen ? new Date() : undefined;
  await card.save();
  await audit({ actorType: 'USER', actorId: user._id, action: frozen ? 'card.frozen' : 'card.unfrozen', resourceType: 'Card', resourceId: card._id }, req);
  await notify(user._id, { category: 'SECURITY', type: frozen ? 'CARD_FROZEN' : 'CARD_UNFROZEN', title: frozen ? 'Card frozen' : 'Card unfrozen', body: `Your card ending ${card.last4} is now ${frozen ? 'frozen. New payments will be declined.' : 'active again.'}` });
  return serializeCard(card);
}

export async function updateControls(user, id, input) {
  const card = await ownCard(user._id, id, { withToken: true });
  const toM = (v) => (v === null ? null : v === undefined ? undefined : toMinor(v, card.currency));
  const next = { ...card.controls?.toObject?.() ?? card.controls };
  for (const [k, field] of [['perTransaction', 'perTransactionMinor'], ['daily', 'dailyMinor'], ['monthly', 'monthlyMinor']]) {
    const v = toM(input[k]);
    if (v !== undefined) next[field] = v;
  }
  for (const k of ['online', 'international', 'atm']) if (input[k] !== undefined) next[k] = input[k];
  await getIssuer(card.issuer).setControls(card.providerCardToken, next);
  card.controls = next;
  await card.save();
  return serializeCard(card);
}

export async function secureDisplay(user, id, { pin }, req) {
  await verifyPin(user._id, pin, req);
  const card = await ownCard(user._id, id, { withToken: true });
  if (card.kind !== 'VIRTUAL') throw Errors.unprocessable('NOT_PERMITTED', 'Card details can only be displayed for virtual cards issued here');
  const session = await getIssuer(card.issuer).secureDisplaySession(card.providerCardToken);
  await audit({ actorType: 'USER', actorId: user._id, action: 'card.details.viewed', resourceType: 'Card', resourceId: card._id }, req);
  return session;
}

export async function closeCard(user, id, req) {
  const card = await ownCard(user._id, id, { withToken: true });
  await getIssuer(card.issuer).setStatus(card.providerCardToken, 'CLOSED');
  card.status = 'CLOSED';
  card.closedAt = new Date();
  await card.save();
  await audit({ actorType: 'USER', actorId: user._id, action: 'card.closed', resourceType: 'Card', resourceId: card._id }, req);
}

export async function cardTransactions(userId, id, q) {
  await ownCard(userId, id);
  const page = await paginate(Transaction, { userId, cardId: new mongoose.Types.ObjectId(String(id)) }, q);
  return { ...page, items: page.items.map((t) => serializeTransaction(t)) };
}

/**
 * Processes an issuer authorization/settlement webhook. The issuer is the
 * authority on approval; we mirror controls locally as defence in depth and
 * record every event as an immutable transaction.
 */
export async function processIssuerEvent(evt) {
  const card = await Card.findOne({ _id: evt.cardId }).lean();
  if (!card) return { status: 'ORPHANED' };
  const existing = await Transaction.findOne({ userId: card.userId, idempotencyKey: `issuer:${evt.eventId}` }).lean();
  if (existing) return { status: 'DUPLICATE', transactionId: String(existing._id) };

  let decline = evt.approved ? null : (evt.declineReason ?? 'Declined by issuer');
  if (!decline && card.status !== 'ACTIVE') decline = 'Card is frozen';
  if (!decline && card.controls?.perTransactionMinor != null && evt.amountMinor > card.controls.perTransactionMinor) decline = 'Exceeds card transaction limit';
  if (!decline && evt.channel === 'ONLINE' && card.controls?.online === false) decline = 'Online payments disabled';
  if (!decline && evt.international && !card.controls?.international) decline = 'International payments disabled';
  if (!decline && card.controls?.dailyMinor != null) {
    const user = await User.findById(card.userId, { country: 1 }).lean();
    const since = startOfDayInTz(getCountry(user.country).timezone);
    const [row] = await Transaction.aggregate([{ $match: { cardId: card._id, status: 'SUCCESSFUL', createdAt: { $gte: since } } }, { $group: { _id: null, t: { $sum: '$totalMinor' } } }]);
    if ((row?.t ?? 0) + evt.amountMinor > card.controls.dailyMinor) decline = 'Exceeds card daily limit';
  }

  const cat = categorize({ type: 'CARD_PAYMENT', description: evt.merchantName, counterparty: { name: evt.merchantName } });
  const txn = await withTransaction(async (session) => {
    const [t] = await Transaction.create([{
      reference: newReference(), userId: card.userId, type: 'CARD_PAYMENT', direction: 'DEBIT',
      amountMinor: evt.amountMinor, feeMinor: 0, totalMinor: evt.amountMinor, currency: card.currency, provider: card.issuer,
      description: `${evt.merchantName} · card ${card.last4}`, category: cat.category, categorySource: cat.source,
      counterparty: { name: evt.merchantName }, cardId: card._id, idempotencyKey: `issuer:${evt.eventId}`,
      providerRequestId: evt.authorizationId, channel: 'API',
    }], { session });
    await TransactionEvent.create([{ transactionId: t._id, userId: card.userId, fromStatus: null, toStatus: 'INITIATED', source: 'PROVIDER_CALLBACK', data: { eventId: evt.eventId } }], { session });
    return t;
  });
  if (!decline) await transition(txn._id, { to: 'PENDING', source: 'PROVIDER_CALLBACK', reason: 'Authorized by issuer' });
  await transition(txn._id, decline
    ? { to: 'FAILED', source: 'PROVIDER_CALLBACK', reason: decline }
    : { to: 'SUCCESSFUL', source: 'PROVIDER_CALLBACK', externalRef: evt.authorizationId });
  if (decline) {
    await notify(card.userId, { category: 'TRANSACTION', type: 'CARD_DECLINED', title: 'Card payment declined', body: `${card.currency} ${money(evt.amountMinor, card.currency).amount} at ${evt.merchantName} was declined: ${decline}.`, data: { route: `/cards/${card._id}` } });
  }
  return { status: decline ? 'DECLINED' : 'APPROVED', transactionId: String(txn._id), reason: decline };
}
