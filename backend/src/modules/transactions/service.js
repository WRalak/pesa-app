import PDFDocument from 'pdfkit';
import { Transaction, TransactionEvent } from '../payments/models.js';
import { serializeTransaction } from '../payments/service.js';
import { paginate } from '../../lib/pagination.js';
import { Errors } from '../../lib/errors.js';
import { fromMinor, toMinor } from '../../lib/money.js';
import { User, UserProfile } from '../users/models.js';
import { EXPENSE_KEYS, INCOME_KEYS } from '../budgets/categories.js';
import { config } from '../../config/env.js';

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export function buildFilter(userId, q, currency) {
  const filter = { userId };
  if (q.status) filter.status = { $in: q.status.split(',') };
  if (q.type) filter.type = { $in: q.type.split(',') };
  if (q.provider) filter.provider = q.provider;
  if (q.direction) filter.direction = q.direction;
  if (q.category) filter.category = q.category;
  if (q.from || q.to) {
    filter.createdAt = {};
    if (q.from) filter.createdAt.$gte = q.from;
    if (q.to) filter.createdAt.$lte = q.to;
  }
  if (q.minAmount || q.maxAmount) {
    filter.amountMinor = {};
    if (q.minAmount) filter.amountMinor.$gte = toMinor(q.minAmount, currency);
    if (q.maxAmount) filter.amountMinor.$lte = toMinor(q.maxAmount, currency);
  }
  if (q.q) {
    // Bounded by the userId index; user input is escaped to prevent ReDoS/injection.
    const rx = new RegExp(escapeRegex(q.q.slice(0, 50)), 'i');
    filter.$or = [{ reference: rx }, { description: rx }, { 'counterparty.name': rx }, { 'counterparty.phone': rx }, { 'counterparty.accountNumber': rx }, { externalRef: rx }];
  }
  return filter;
}

export async function listTransactions(user, q) {
  const page = await paginate(Transaction, buildFilter(user._id, q, user.currency), { cursor: q.cursor, limit: q.limit });
  return { ...page, items: page.items.map((t) => serializeTransaction(t)) };
}

export async function getTransaction(userId, id) {
  const t = await Transaction.findOne({ _id: id, userId }).lean();
  if (!t) throw Errors.notFound('Transaction');
  const events = await TransactionEvent.find({ transactionId: t._id, kind: { $in: ['STATUS_CHANGE', 'REVERSAL_REQUESTED'] } }).sort({ createdAt: 1 }).lean();
  return {
    transaction: serializeTransaction(t, { detail: true }),
    timeline: events.map((e) => ({ status: e.toStatus, kind: e.kind, at: e.createdAt, reason: e.reason ?? null })),
  };
}

export async function receipt(userId, id) {
  const t = await Transaction.findOne({ _id: id, userId }).lean();
  if (!t) throw Errors.notFound('Transaction');
  if (!['SUCCESSFUL', 'REVERSED'].includes(t.status)) throw Errors.unprocessable('RECEIPT_UNAVAILABLE', 'Receipts are available once a payment completes');
  const tx = serializeTransaction(t, { detail: true });
  return {
    receipt: {
      title: `${config.APP_NAME} payment receipt`,
      reference: tx.reference,
      providerReceipt: tx.externalRef,
      status: tx.status,
      type: tx.type,
      amount: tx.amount,
      fee: tx.fee,
      total: tx.total,
      to: tx.counterparty,
      description: tx.description,
      paidAt: tx.completedAt,
      provider: tx.provider,
      sandbox: t.provider === 'mock',
      disclaimer: 'Payment processed by a licensed payment service provider.',
    },
  };
}

export async function setCategory(userId, id, category) {
  if (![...EXPENSE_KEYS, ...INCOME_KEYS].includes(category)) throw Errors.validation([{ path: 'category', message: 'Unknown category' }]);
  const t = await Transaction.findOneAndUpdate({ _id: id, userId }, { $set: { category, categorySource: 'USER' } }, { returnDocument: 'after' }).lean();
  if (!t) throw Errors.notFound('Transaction');
  await TransactionEvent.create({ transactionId: t._id, userId, fromStatus: t.status, toStatus: t.status, kind: 'CATEGORY_CHANGED', source: 'USER', actorId: String(userId), data: { category } });
  return { transaction: serializeTransaction(t) };
}

/**
 * Streams a statement without loading the full history into memory: a Mongo
 * cursor feeds CSV rows / PDF lines directly into the HTTP response.
 */
export async function streamStatement(user, { from, to, format }, res) {
  if (to - from > 366 * 86_400_000) throw Errors.validation([{ path: 'to', message: 'Statements can cover at most 12 months' }]);
  const profile = await UserProfile.findOne({ userId: user._id }, { firstName: 1, lastName: 1 }).lean();
  const cursor = Transaction.find({ userId: user._id, createdAt: { $gte: from, $lte: to } }).sort({ createdAt: 1 }).lean().cursor({ batchSize: 500 });
  const name = `statement-${from.toISOString().slice(0, 10)}-to-${to.toISOString().slice(0, 10)}`;
  const date = (d) => new Intl.DateTimeFormat('en-KE', { dateStyle: 'short', timeStyle: 'short', timeZone: 'Africa/Nairobi' }).format(d);

  if (format === 'csv') {
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${name}.csv"`);
    res.write('date,reference,type,direction,description,status,amount,fee,currency,provider_ref\n');
    const csv = (v) => {
      const s = String(v ?? '');
      // Neutralise spreadsheet formula injection.
      const safe = /^[=+\-@\t\r]/.test(s) ? `'${s}` : s;
      return /[",\n]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
    };
    for await (const t of cursor) {
      res.write([date(t.createdAt), t.reference, t.type, t.direction, t.description, t.status, fromMinor(t.amountMinor, t.currency), fromMinor(t.feeMinor ?? 0, t.currency), t.currency, t.externalRef].map(csv).join(',') + '\n');
    }
    return res.end();
  }

  const doc = new PDFDocument({ size: 'A4', margin: 40, info: { Title: `${config.APP_NAME} statement` } });
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename="${name}.pdf"`);
  doc.pipe(res);
  doc.fontSize(18).fillColor('#0B1B2B').text(`${config.APP_NAME} account statement`);
  doc.moveDown(0.3).fontSize(10).fillColor('#475569')
    .text(`${profile?.firstName ?? ''} ${profile?.lastName ?? ''} · ${user.phone}`)
    .text(`Period: ${from.toDateString()} – ${to.toDateString()}`)
    .text(`Generated: ${new Date().toUTCString()}`);
  if (!config.isProd) doc.fillColor('#B45309').text('SANDBOX / NON-PRODUCTION STATEMENT — NOT A RECORD OF REAL FUNDS');
  doc.moveDown();
  const cols = [40, 140, 250, 400, 480];
  const header = ['Date', 'Reference', 'Description', 'Status', 'Amount'];
  doc.fontSize(9).fillColor('#0F766E');
  header.forEach((h, i) => doc.text(h, cols[i], doc.y, { continued: false, lineBreak: false }));
  doc.moveDown();
  let credits = 0;
  let debits = 0;
  for await (const t of cursor) {
    if (doc.y > 770) doc.addPage();
    const y = doc.y;
    const signed = `${t.direction === 'DEBIT' ? '-' : '+'}${fromMinor(t.totalMinor, t.currency)}`;
    if (t.status === 'SUCCESSFUL') t.direction === 'DEBIT' ? (debits += t.totalMinor) : (credits += t.totalMinor);
    doc.fillColor('#0B1B2B');
    [date(t.createdAt), t.reference, (t.description ?? '').slice(0, 32), t.status, signed].forEach((v, i) => doc.text(v, cols[i], y, { width: (cols[i + 1] ?? 560) - cols[i] - 6, lineBreak: false }));
    doc.moveDown(0.8);
  }
  doc.moveDown().fontSize(10).fillColor('#0B1B2B')
    .text(`Total successful debits: ${fromMinor(debits, user.currency)} ${user.currency}`, 40)
    .text(`Total successful credits: ${fromMinor(credits, user.currency)} ${user.currency}`, 40);
  doc.moveDown().fontSize(8).fillColor('#64748B').text(`${config.APP_NAME} is a financial management platform. Payments are processed by licensed partners; ${config.APP_NAME} does not hold customer funds.`, 40);
  const finished = new Promise((resolve) => res.on('finish', resolve));
  doc.end();
  await finished;
}

export async function loadUser(userId) {
  return User.findById(userId);
}
