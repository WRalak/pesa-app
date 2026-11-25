import { SupportTicket } from './models.js';
import { randomDigits } from '../../lib/crypto.js';
import { Errors } from '../../lib/errors.js';
import { paginate } from '../../lib/pagination.js';
import { audit } from '../audit/service.js';

const newReference = () => `TKT-${new Date().toISOString().slice(2, 10).replace(/-/g, '')}-${randomDigits(6)}`;

export function serializeTicket(t, { includeInternal = false } = {}) {
  return {
    id: String(t._id),
    reference: t.reference,
    category: t.category,
    subject: t.subject,
    status: t.status,
    priority: t.priority,
    transactionId: t.transactionId ? String(t.transactionId) : null,
    messages: (t.messages ?? []).filter((m) => includeInternal || !m.internal).map((m) => ({
      id: String(m._id), authorType: m.authorType, body: m.body, internal: includeInternal ? m.internal : undefined, createdAt: m.createdAt,
    })),
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  };
}

export async function createTicket(userId, { category, subject, message, transactionId }) {
  const ticket = await SupportTicket.create({
    reference: newReference(), userId, category, subject, transactionId,
    priority: category === 'SECURITY' ? 'HIGH' : 'NORMAL',
    messages: [{ authorType: 'USER', authorId: userId, body: message }],
  });
  return serializeTicket(ticket);
}

export async function listTickets(userId, { cursor, limit }) {
  const page = await paginate(SupportTicket, { userId }, { cursor, limit });
  return { ...page, items: page.items.map((t) => serializeTicket(t)) };
}

export async function getTicket(userId, id) {
  const t = await SupportTicket.findOne({ _id: id, userId }).lean();
  if (!t) throw Errors.notFound('Ticket');
  return serializeTicket(t);
}

export async function replyToTicket(userId, id, { message }) {
  const t = await SupportTicket.findOneAndUpdate(
    { _id: id, userId, status: { $nin: ['CLOSED'] } },
    { $push: { messages: { authorType: 'USER', authorId: userId, body: message } }, $set: { status: 'OPEN' } },
    { new: true },
  ).lean();
  if (!t) throw Errors.notFound('Ticket');
  return serializeTicket(t);
}

export async function createRecoveryTicket(user, { requestedPhone, details }, req) {
  const ticket = await SupportTicket.create({
    reference: newReference(),
    userId: user._id,
    category: 'ACCOUNT_RECOVERY',
    subject: 'Account recovery: phone number change request',
    priority: 'HIGH',
    metadata: { requestedPhone },
    messages: [{ authorType: 'SYSTEM', body: `Recovery requested via verified email. ${details ?? ''}`.trim() }],
  });
  await audit({ actorType: 'USER', actorId: user._id, action: 'user.recovery.requested', resourceType: 'SupportTicket', resourceId: ticket._id }, req);
  return ticket;
}
