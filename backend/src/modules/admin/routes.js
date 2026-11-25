import mongoose from 'mongoose';
import { createRouter, idParams, pageQuery, amountString, objectId } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import { requireAdmin, requirePermission, can, syncRbac, PERMISSIONS, DEFAULT_ROLES } from './rbac.js';
import { AdminUser, AdminSession, AdminApproval, Role, NotificationCampaign } from './models.js';
import { User, UserProfile, KycRecord } from '../users/models.js';
import { Device, Session } from '../auth/models.js';
import { Transaction, TransactionEvent, PaymentCallback, ReconciliationRecord, PaymentProvider, TX_STATUSES, TX_TYPES } from '../payments/models.js';
import { serializeTransaction, requestReversal, checkTransactionStatus } from '../payments/service.js';
import { runReconciliation } from '../payments/reconciliation.js';
import { RewardCampaign, Referral } from '../rewards/models.js';
import { SupportTicket } from '../support/models.js';
import { serializeTicket } from '../support/service.js';
import { AuditLog, SecurityEvent } from '../audit/models.js';
import { audit, securityEvent, verifyAuditChain } from '../audit/service.js';
import { revokeSessions } from '../../middleware/auth.js';
import { notify } from '../notifications/service.js';
import { paginate } from '../../lib/pagination.js';
import { Errors } from '../../lib/errors.js';
import { money, toMinor } from '../../lib/money.js';
import { decryptField, hashSecret, randomToken, mask } from '../../lib/crypto.js';
import { maskPhone } from '../../lib/phone.js';
import { invalidate, getRedis } from '../../lib/redis.js';
import { enqueue, QUEUES, getQueue } from '../../lib/queue.js';
import { config } from '../../config/env.js';
import { getCountry } from '../../config/countries/index.js';

const r = createRouter({ prefix: '/admin/v1', tags: ['Admin'], security: 'adminAuth' });
const P = (...perms) => [requireAdmin, requirePermission(...perms)];
const reason = z.string().trim().min(5).max(500);
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const adminAudit = (req, action, resourceType, resourceId, metadata) => audit({ actorType: 'ADMIN', actorId: req.admin.id, action, resourceType, resourceId, metadata }, req);
const DAY = 86_400_000;

// ======================================================================= dashboard
r.route({
  method: 'get', path: '/dashboard', summary: 'Operational KPIs', middleware: P('dashboard.read'),
  handler: async () => {
    const now = Date.now();
    const d1 = new Date(now - DAY);
    const d7 = new Date(now - 7 * DAY);
    const d30 = new Date(now - 30 * DAY);
    const [totalUsers, newUsers7d, activeUsers30d, kyc, tx24, tx30, providers, fraudAlerts, pendingStale, reconOpen, approvals] = await Promise.all([
      User.countDocuments({ status: { $ne: 'CLOSED' } }),
      User.countDocuments({ createdAt: { $gte: d7 } }),
      User.countDocuments({ lastLoginAt: { $gte: d30 } }),
      User.aggregate([{ $group: { _id: '$kycStatus', n: { $sum: 1 } } }]),
      Transaction.aggregate([{ $match: { createdAt: { $gte: d1 } } }, { $group: { _id: '$status', n: { $sum: 1 }, value: { $sum: '$amountMinor' } } }]),
      Transaction.aggregate([{ $match: { createdAt: { $gte: d30 }, status: 'SUCCESSFUL' } }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt', timezone: 'Africa/Nairobi' } }, n: { $sum: 1 }, value: { $sum: '$amountMinor' } } }, { $sort: { _id: 1 } }]),
      Transaction.aggregate([{ $match: { createdAt: { $gte: d7 }, status: { $in: ['SUCCESSFUL', 'FAILED'] } } }, { $group: { _id: '$provider', ok: { $sum: { $cond: [{ $eq: ['$status', 'SUCCESSFUL'] }, 1, 0] } }, n: { $sum: 1 }, avgMs: { $avg: { $subtract: ['$completedAt', '$createdAt'] } } } }]),
      SecurityEvent.countDocuments({ severity: { $in: ['HIGH', 'CRITICAL'] }, acknowledgedAt: null }),
      Transaction.countDocuments({ status: { $in: ['PENDING', 'PROCESSING'] }, createdAt: { $lt: new Date(now - 15 * 60_000) } }),
      ReconciliationRecord.countDocuments({ resolution: 'OPEN' }),
      AdminApproval.countDocuments({ status: 'PENDING' }),
    ]);
    const byStatus = Object.fromEntries(TX_STATUSES.map((s) => [s, { count: 0, valueMinor: 0 }]));
    for (const t of tx24) byStatus[t._id] = { count: t.n, valueMinor: t.value };
    let health = { mongo: mongoose.connection.readyState === 1 ? 'ok' : 'down', redis: 'down', queues: {} };
    try { health.redis = (await getRedis().ping()) === 'PONG' ? 'ok' : 'down'; } catch { /* down */ }
    if (!config.JOBS_INLINE) {
      for (const q of Object.values(QUEUES)) {
        try { health.queues[q] = await getQueue(q).getJobCounts('waiting', 'active', 'failed', 'delayed'); } catch { health.queues[q] = null; }
      }
    }
    return {
      users: { total: totalUsers, new7d: newUsers7d, active30d: activeUsers30d, kyc: Object.fromEntries(kyc.map((k) => [k._id, k.n])) },
      transactions24h: { byStatus, total: tx24.reduce((a, t) => a + t.n, 0), successfulValue: money(byStatus.SUCCESSFUL.valueMinor, 'KES') },
      volume30d: tx30.map((d) => ({ date: d._id, count: d.n, value: money(d.value, 'KES') })),
      providers: providers.map((p) => ({ provider: p._id, successRate: p.n ? Math.round((p.ok * 1000) / p.n) / 10 : null, completed: p.n, avgCompletionSeconds: p.avgMs ? Math.round(p.avgMs / 1000) : null })),
      alerts: { fraudAndSecurity: fraudAlerts, stalePending: pendingStale, reconciliationExceptions: reconOpen, pendingApprovals: approvals },
      health,
      currencyNote: 'Values shown in KES (default market).',
    };
  },
});

// ======================================================================= users
function adminUserView(u, profile, { pii }) {
  return {
    id: String(u._id), phone: pii ? u.phone : maskPhone(u.phone), email: u.email ? (pii ? u.email : `${u.email[0]}***@${u.email.split('@')[1]}`) : null,
    name: profile ? `${profile.firstName ?? ''} ${pii ? (profile.lastName ?? '') : `${(profile.lastName ?? '')[0] ?? ''}.`}`.trim() : null,
    status: u.status, suspensionReason: u.suspensionReason ?? null, restrictions: u.restrictions, country: u.country, kycTier: u.kycTier, kycStatus: u.kycStatus,
    lastLoginAt: u.lastLoginAt ?? null, createdAt: u.createdAt, piiMasked: !pii,
  };
}

r.route({
  method: 'get', path: '/users', summary: 'Search users', middleware: P('users.read'),
  query: pageQuery.extend({ q: z.string().trim().max(60).optional(), status: z.enum(['PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'CLOSED']).optional(), kycStatus: z.enum(['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED']).optional() }),
  handler: async (req) => {
    const q = req.valid.query;
    const filter = {};
    if (q.status) filter.status = q.status;
    if (q.kycStatus) filter.kycStatus = q.kycStatus;
    if (q.q) {
      if (mongoose.isValidObjectId(q.q)) filter._id = q.q;
      else if (/^[+\d\s]{6,}$/.test(q.q)) filter.phone = { $regex: `${escapeRegex(q.q.replace(/\s/g, '').replace(/^0/, ''))}$` };
      else if (q.q.includes('@')) filter.email = q.q.toLowerCase();
      else if (/^[A-Z0-9]{7}$/i.test(q.q)) filter.referralCode = q.q.toUpperCase();
      else {
        const ids = await UserProfile.find({ $or: [{ firstName: new RegExp(`^${escapeRegex(q.q)}`, 'i') }, { lastName: new RegExp(`^${escapeRegex(q.q)}`, 'i') }] }, { userId: 1 }).limit(200).lean();
        filter._id = { $in: ids.map((p) => p.userId) };
      }
    }
    const page = await paginate(User, filter, q);
    const profiles = await UserProfile.find({ userId: { $in: page.items.map((u) => u._id) } }).lean();
    const pmap = new Map(profiles.map((p) => [String(p.userId), p]));
    return { ...page, items: page.items.map((u) => adminUserView(u, pmap.get(String(u._id)), { pii: can(req, 'users.pii.read') })) };
  },
});

r.route({
  method: 'get', path: '/users/:id', summary: 'User 360° view', params: idParams, middleware: P('users.read'),
  handler: async (req) => {
    const id = req.valid.params.id;
    const [u, profile, kyc, devices, sessions, txs, events, tickets] = await Promise.all([
      User.findById(id).lean(), UserProfile.findOne({ userId: id }).lean(), KycRecord.find({ userId: id }).sort({ createdAt: -1 }).limit(5).lean(),
      Device.find({ userId: id }).sort({ lastSeenAt: -1 }).lean(), Session.countDocuments({ userId: id, revokedAt: null, expiresAt: { $gt: new Date() } }),
      Transaction.find({ userId: id }).sort({ createdAt: -1 }).limit(20).lean(), SecurityEvent.find({ userId: id }).sort({ createdAt: -1 }).limit(20).lean(),
      SupportTicket.find({ userId: id }).sort({ createdAt: -1 }).limit(10).lean(),
    ]);
    if (!u) throw Errors.notFound('User');
    const pii = can(req, 'users.pii.read');
    if (pii) await adminAudit(req, 'admin.user.pii.viewed', 'User', id);
    return {
      user: adminUserView(u, profile, { pii }),
      kyc: kyc.map((k) => ({ id: String(k._id), idType: k.idType, idNumberLast4: k.idNumberLast4, fullName: pii ? k.fullName : mask(k.fullName, 3), status: k.status, rejectionReason: k.rejectionReason ?? null, submittedAt: k.createdAt, reviewedAt: k.reviewedAt ?? null })),
      devices: devices.map((d) => ({ id: String(d._id), name: d.name, platform: d.platform, trusted: d.trusted, revoked: Boolean(d.revokedAt), lastSeenAt: d.lastSeenAt, lastIp: pii ? d.lastIp : undefined })),
      activeSessions: sessions,
      recentTransactions: txs.map((t) => ({ ...serializeTransaction(t), counterparty: pii ? serializeTransaction(t).counterparty : { name: t.counterparty?.name ?? null } , risk: t.risk })),
      securityEvents: events.map((e) => ({ id: String(e._id), type: e.type, severity: e.severity, at: e.createdAt, ip: pii ? e.ip : undefined })),
      tickets: tickets.map((t) => ({ id: String(t._id), reference: t.reference, subject: t.subject, status: t.status })),
    };
  },
});

r.route({
  method: 'post', path: '/users/:id/suspend', summary: 'Suspend an account (revokes sessions)', params: idParams, middleware: P('users.suspend'),
  body: z.object({ reason }),
  handler: async (req) => {
    const u = await User.findOneAndUpdate({ _id: req.valid.params.id, status: { $in: ['ACTIVE', 'PENDING_VERIFICATION'] } }, { $set: { status: 'SUSPENDED', suspensionReason: req.body.reason } }, { returnDocument: 'after' });
    if (!u) throw Errors.conflict('User is not active', 'INVALID_STATE');
    await revokeSessions({ userId: u._id }, 'ACCOUNT_SUSPENDED');
    await securityEvent({ userId: u._id, adminId: req.admin.id, type: 'ACCOUNT_SUSPENDED', severity: 'HIGH', details: { reason: req.body.reason } }, req);
    await adminAudit(req, 'admin.user.suspended', 'User', u._id, { reason: req.body.reason });
    return { status: u.status };
  },
});

r.route({
  method: 'post', path: '/users/:id/reactivate', summary: 'Reactivate a suspended account', params: idParams, middleware: P('users.suspend'),
  body: z.object({ reason }),
  handler: async (req) => {
    const u = await User.findOneAndUpdate({ _id: req.valid.params.id, status: 'SUSPENDED' }, { $set: { status: 'ACTIVE' }, $unset: { suspensionReason: 1 } }, { returnDocument: 'after' });
    if (!u) throw Errors.conflict('User is not suspended', 'INVALID_STATE');
    await adminAudit(req, 'admin.user.reactivated', 'User', u._id, { reason: req.body.reason });
    await notify(u._id, { category: 'SECURITY', type: 'ACCOUNT_REACTIVATED', title: 'Account reactivated', body: 'Your account has been reactivated.' });
    return { status: u.status };
  },
});

r.route({
  method: 'put', path: '/users/:id/restrictions', summary: 'Set account restrictions', params: idParams, middleware: P('users.restrict'),
  body: z.object({ restrictions: z.array(z.enum(['NO_PAYMENTS', 'NO_WITHDRAWALS', 'NO_LOGIN', 'REVIEW_REQUIRED'])).max(4), reason }),
  handler: async (req) => {
    const before = await User.findById(req.valid.params.id, { restrictions: 1 }).lean();
    if (!before) throw Errors.notFound('User');
    await User.updateOne({ _id: before._id }, { $set: { restrictions: req.body.restrictions } });
    if (req.body.restrictions.includes('NO_LOGIN')) await revokeSessions({ userId: before._id }, 'RESTRICTED');
    await adminAudit(req, 'admin.user.restrictions.updated', 'User', before._id, { before: before.restrictions, after: req.body.restrictions, reason: req.body.reason });
    return { restrictions: req.body.restrictions };
  },
});

r.route({
  method: 'post', path: '/users/:id/revoke-sessions', summary: 'Sign a user out everywhere', params: idParams, middleware: P('security.manage'),
  body: z.object({ reason }),
  handler: async (req) => {
    const n = await revokeSessions({ userId: req.valid.params.id }, 'ADMIN_REVOKED');
    await adminAudit(req, 'admin.user.sessions.revoked', 'User', req.valid.params.id, { count: n, reason: req.body.reason });
    return { revoked: n };
  },
});

// ======================================================================= KYC
r.route({
  method: 'get', path: '/kyc', summary: 'KYC review queue', middleware: P('kyc.review'),
  query: pageQuery.extend({ status: z.enum(['PENDING', 'VERIFIED', 'REJECTED']).default('PENDING') }),
  handler: async (req) => {
    const page = await paginate(KycRecord, { status: req.valid.query.status }, req.valid.query);
    return { ...page, items: page.items.map((k) => ({ id: String(k._id), userId: String(k.userId), country: k.country, idType: k.idType, idNumberLast4: k.idNumberLast4, fullName: k.fullName, dateOfBirth: k.dateOfBirth, documents: k.documents?.length ?? 0, status: k.status, submittedAt: k.createdAt })) };
  },
});

r.route({
  method: 'get', path: '/kyc/:id/id-number', summary: 'Reveal full ID number (audited)', params: idParams, middleware: P('kyc.review', 'users.pii.read'),
  handler: async (req) => {
    const k = await KycRecord.findById(req.valid.params.id).select('+idNumberEnc').lean();
    if (!k) throw Errors.notFound('KYC record');
    await adminAudit(req, 'admin.kyc.id_number.revealed', 'KycRecord', k._id);
    return { idNumber: decryptField(k.idNumberEnc) };
  },
});

r.route({
  method: 'post', path: '/kyc/:id/decision', summary: 'Approve or reject a KYC submission', params: idParams, middleware: P('kyc.review'),
  body: z.object({ decision: z.enum(['APPROVE', 'REJECT']), tier: z.enum(['TIER_1', 'TIER_2']).optional(), reason: z.string().trim().max(500).optional() }),
  handler: async (req) => {
    const { decision, tier = 'TIER_1' } = req.body;
    if (decision === 'REJECT' && !req.body.reason) throw Errors.validation([{ path: 'reason', message: 'A rejection reason is required' }]);
    const k = await KycRecord.findOneAndUpdate({ _id: req.valid.params.id, status: 'PENDING' }, { $set: { status: decision === 'APPROVE' ? 'VERIFIED' : 'REJECTED', reviewedBy: req.admin.id, reviewedAt: new Date(), rejectionReason: req.body.reason, tierGranted: decision === 'APPROVE' ? tier : undefined } }, { returnDocument: 'after' });
    if (!k) throw Errors.conflict('This submission was already reviewed', 'ALREADY_REVIEWED');
    await User.updateOne({ _id: k.userId }, decision === 'APPROVE' ? { $set: { kycStatus: 'VERIFIED', kycTier: tier } } : { $set: { kycStatus: 'REJECTED' } });
    await adminAudit(req, `admin.kyc.${decision.toLowerCase()}d`, 'KycRecord', k._id, { userId: String(k.userId), tier, reason: req.body.reason });
    await notify(k.userId, decision === 'APPROVE'
      ? { category: 'SYSTEM', type: 'KYC_APPROVED', title: 'Identity verified', body: 'Your identity is verified and your limits have been increased.', data: { route: '/profile/kyc' } }
      : { category: 'SYSTEM', type: 'KYC_REJECTED', title: 'Verification unsuccessful', body: `We couldn't verify your identity: ${req.body.reason}. You can submit again.`, data: { route: '/profile/kyc' } });
    return { status: k.status };
  },
});

// ======================================================================= transactions
r.route({
  method: 'get', path: '/transactions', summary: 'Search transactions', middleware: P('transactions.read'),
  query: pageQuery.extend({
    q: z.string().trim().max(60).optional(), status: z.enum(TX_STATUSES).optional(), type: z.enum(TX_TYPES).optional(), provider: z.string().max(30).optional(),
    userId: objectId.optional(), reviewRequired: z.coerce.boolean().optional(), from: z.coerce.date().optional(), to: z.coerce.date().optional(),
    minAmount: amountString.optional(), maxAmount: amountString.optional(),
  }),
  handler: async (req) => {
    const q = req.valid.query;
    const filter = {};
    for (const k of ['status', 'type', 'provider', 'userId']) if (q[k]) filter[k] = q[k];
    if (q.reviewRequired) filter['risk.reviewRequired'] = true;
    if (q.from || q.to) filter.createdAt = { ...(q.from && { $gte: q.from }), ...(q.to && { $lte: q.to }) };
    if (q.minAmount || q.maxAmount) filter.amountMinor = { ...(q.minAmount && { $gte: toMinor(q.minAmount, 'KES') }), ...(q.maxAmount && { $lte: toMinor(q.maxAmount, 'KES') }) };
    if (q.q) filter.$or = [{ reference: q.q.toUpperCase() }, { externalRef: q.q.toUpperCase() }, { providerRequestId: q.q }];
    const page = await paginate(Transaction, filter, q);
    return { ...page, items: page.items.map((t) => ({ ...serializeTransaction(t, { detail: true }), userId: String(t.userId), risk: t.risk })) };
  },
});

r.route({
  method: 'get', path: '/transactions/:id', summary: 'Transaction detail, events, callbacks, approvals', params: idParams, middleware: P('transactions.read'),
  handler: async (req) => {
    const t = await Transaction.findById(req.valid.params.id).lean();
    if (!t) throw Errors.notFound('Transaction');
    const [events, callbacks, approvals] = await Promise.all([
      TransactionEvent.find({ transactionId: t._id }).sort({ createdAt: 1 }).lean(),
      can(req, 'callbacks.read') ? PaymentCallback.find({ transactionId: t._id }).sort({ receivedAt: 1 }).lean() : [],
      AdminApproval.find({ resourceId: String(t._id) }).sort({ createdAt: -1 }).lean(),
    ]);
    return {
      transaction: { ...serializeTransaction(t, { detail: true }), userId: String(t.userId), risk: t.risk, reversal: t.reversal ?? null, ip: t.ip, deviceId: t.deviceId },
      events: events.map((e) => ({ kind: e.kind, from: e.fromStatus, to: e.toStatus, source: e.source, actorId: e.actorId ?? null, reason: e.reason ?? null, data: e.data ?? null, at: e.createdAt })),
      callbacks: callbacks.map((c) => ({ id: String(c._id), outcome: c.outcome, processingStatus: c.processingStatus, note: c.processingNote ?? null, signatureValid: c.signatureValid, receivedAt: c.receivedAt, payload: c.payload })),
      approvals: approvals.map((a) => ({ id: String(a._id), type: a.type, status: a.status, reason: a.reason, requestedBy: String(a.requestedBy), decidedBy: a.decidedBy ? String(a.decidedBy) : null, createdAt: a.createdAt })),
      note: 'Financial fields are immutable. Status changes only via provider confirmation, reconciliation, or approved reversal.',
    };
  },
});

r.route({
  method: 'post', path: '/transactions/:id/flag', summary: 'Flag or clear a transaction for investigation', params: idParams, middleware: P('transactions.flag'),
  body: z.object({ flagged: z.boolean(), reason }),
  handler: async (req) => {
    const t = await Transaction.findByIdAndUpdate(req.valid.params.id, req.body.flagged ? { $set: { 'risk.reviewRequired': true }, $addToSet: { 'risk.flags': 'ADMIN_FLAGGED' } } : { $set: { 'risk.reviewRequired': false } }, { returnDocument: 'after' }).lean();
    if (!t) throw Errors.notFound('Transaction');
    await TransactionEvent.create({ transactionId: t._id, userId: t.userId, fromStatus: t.status, toStatus: t.status, kind: 'FLAGGED', source: 'ADMIN', actorId: req.admin.id, reason: req.body.reason, data: { flagged: req.body.flagged } });
    await adminAudit(req, req.body.flagged ? 'admin.transaction.flagged' : 'admin.transaction.cleared', 'Transaction', t._id, { reason: req.body.reason });
    return { reviewRequired: t.risk.reviewRequired };
  },
});

r.route({
  method: 'post', path: '/transactions/:id/check-status', summary: 'Query the provider for the authoritative status', params: idParams, middleware: P('transactions.read'),
  handler: async (req) => {
    const t = await checkTransactionStatus(req.valid.params.id);
    if (!t) throw Errors.notFound('Transaction');
    await adminAudit(req, 'admin.transaction.status_checked', 'Transaction', t._id);
    return { status: t.status };
  },
});

r.route({
  method: 'post', path: '/transactions/:id/reversal-requests', summary: 'Request a reversal (requires approval by a different admin)', status: 201, params: idParams, middleware: P('transactions.reverse.request'),
  body: z.object({ reason }),
  handler: async (req) => {
    const t = await Transaction.findById(req.valid.params.id).lean();
    if (!t) throw Errors.notFound('Transaction');
    if (t.status !== 'SUCCESSFUL') throw Errors.unprocessable('NOT_REVERSIBLE', 'Only successful transactions can be reversed');
    if (await AdminApproval.exists({ type: 'TRANSACTION_REVERSAL', resourceId: String(t._id), status: 'PENDING' })) throw Errors.conflict('A reversal request is already pending', 'APPROVAL_PENDING');
    const a = await AdminApproval.create({ type: 'TRANSACTION_REVERSAL', resourceId: String(t._id), reason: req.body.reason, requestedBy: req.admin.id, payload: { reference: t.reference, amountMinor: t.amountMinor, currency: t.currency } });
    await adminAudit(req, 'admin.reversal.requested', 'Transaction', t._id, { approvalId: String(a._id), reason: req.body.reason });
    return { approvalId: String(a._id), status: a.status };
  },
});

r.route({
  method: 'get', path: '/approvals', summary: 'Maker-checker approvals', middleware: P('transactions.reverse.approve'),
  query: pageQuery.extend({ status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'FAILED']).default('PENDING') }),
  handler: async (req) => {
    const page = await paginate(AdminApproval, { status: req.valid.query.status }, req.valid.query);
    return { ...page, items: page.items.map((a) => ({ id: String(a._id), type: a.type, resourceId: a.resourceId, payload: a.payload, reason: a.reason, status: a.status, requestedBy: String(a.requestedBy), decidedBy: a.decidedBy ? String(a.decidedBy) : null, createdAt: a.createdAt, mine: String(a.requestedBy) === req.admin.id })) };
  },
});

r.route({
  method: 'post', path: '/approvals/:id/decision', summary: 'Approve or reject (cannot approve your own request)', params: idParams, middleware: P('transactions.reverse.approve'),
  body: z.object({ decision: z.enum(['APPROVE', 'REJECT']), note: z.string().trim().max(500).optional() }),
  handler: async (req) => {
    const pending = await AdminApproval.findOne({ _id: req.valid.params.id, status: 'PENDING' });
    if (!pending) throw Errors.conflict('Approval is no longer pending', 'INVALID_STATE');
    if (String(pending.requestedBy) === req.admin.id) throw Errors.forbidden('Separation of duties: you cannot approve your own request');
    const claimed = await AdminApproval.findOneAndUpdate({ _id: pending._id, status: 'PENDING' }, { $set: { status: req.body.decision === 'APPROVE' ? 'APPROVED' : 'REJECTED', decidedBy: req.admin.id, decidedAt: new Date(), decisionNote: req.body.note } }, { returnDocument: 'after' });
    if (!claimed) throw Errors.conflict('Approval is no longer pending', 'INVALID_STATE');
    if (req.body.decision === 'APPROVE') {
      try {
        await requestReversal(claimed.resourceId, { reason: claimed.reason, adminId: req.admin.id });
      } catch (err) {
        await AdminApproval.updateOne({ _id: claimed._id }, { $set: { status: 'FAILED', decisionNote: err.message } });
        await adminAudit(req, 'admin.reversal.failed', 'Transaction', claimed.resourceId, { error: err.message });
        throw err;
      }
    }
    await adminAudit(req, `admin.reversal.${req.body.decision === 'APPROVE' ? 'approved' : 'rejected'}`, 'Transaction', claimed.resourceId, { approvalId: String(claimed._id), note: req.body.note });
    return { status: claimed.status, note: req.body.decision === 'APPROVE' ? 'Reversal submitted to provider. Status changes to REVERSED only after provider confirmation.' : undefined };
  },
});

// ======================================================================= callbacks & reconciliation
r.route({
  method: 'get', path: '/callbacks', summary: 'Provider callback monitor', middleware: P('callbacks.read'),
  query: pageQuery.extend({ provider: z.string().max(30).optional(), processingStatus: z.enum(['RECEIVED', 'APPLIED', 'DUPLICATE', 'ORPHANED', 'REJECTED', 'IGNORED', 'ERROR']).optional() }),
  handler: async (req) => {
    const q = req.valid.query;
    const filter = {};
    if (q.provider) filter.provider = q.provider;
    if (q.processingStatus) filter.processingStatus = q.processingStatus;
    const page = await paginate(PaymentCallback, filter, { ...q, sortField: 'receivedAt' });
    return { ...page, items: page.items.map((c) => ({ id: String(c._id), provider: c.provider, outcome: c.outcome ?? null, processingStatus: c.processingStatus, note: c.processingNote ?? null, signatureValid: c.signatureValid, sourceIp: c.sourceIp, transactionId: c.transactionId ? String(c.transactionId) : null, providerRequestId: c.providerRequestId ?? null, receivedAt: c.receivedAt })) };
  },
});

r.route({
  method: 'post', path: '/reconciliation/runs', summary: 'Run reconciliation for a provider and window', status: 201, middleware: P('reconciliation.run'),
  body: z.object({ provider: z.string().max(30), from: z.coerce.date(), to: z.coerce.date() }),
  handler: async (req) => {
    if (req.body.to <= req.body.from || req.body.to - req.body.from > 7 * DAY) throw Errors.validation([{ path: 'to', message: 'Window must be positive and at most 7 days' }]);
    const summary = await runReconciliation(req.body);
    await adminAudit(req, 'admin.reconciliation.run', 'Reconciliation', summary.runId, summary);
    return summary;
  },
});

r.route({
  method: 'get', path: '/reconciliation/records', summary: 'Reconciliation results', middleware: P('reconciliation.read'),
  query: pageQuery.extend({ runId: z.string().max(80).optional(), result: z.enum(['MATCHED', 'AUTO_RESOLVED', 'STATUS_MISMATCH', 'AMOUNT_MISMATCH', 'MISSING_INTERNAL', 'MISSING_AT_PROVIDER']).optional(), resolution: z.enum(['OPEN', 'RESOLVED', 'ESCALATED', 'NOT_REQUIRED']).optional() }),
  handler: async (req) => {
    const q = req.valid.query;
    const filter = {};
    for (const k of ['runId', 'result', 'resolution']) if (q[k]) filter[k] = q[k];
    const page = await paginate(ReconciliationRecord, filter, q);
    return { ...page, items: page.items.map((x) => ({ ...x, id: String(x._id), _id: undefined, internalAmount: x.internalAmountMinor != null ? money(x.internalAmountMinor, x.currency ?? 'KES') : null, providerAmount: x.providerAmountMinor != null ? money(x.providerAmountMinor, x.currency ?? 'KES') : null })) };
  },
});

r.route({
  method: 'post', path: '/reconciliation/records/:id/resolve', summary: 'Record the resolution of an exception (does not alter transactions)', params: idParams, middleware: P('reconciliation.resolve'),
  body: z.object({ resolution: z.enum(['RESOLVED', 'ESCALATED']), note: reason }),
  handler: async (req) => {
    const rec = await ReconciliationRecord.findOneAndUpdate({ _id: req.valid.params.id, resolution: { $in: ['OPEN', 'ESCALATED'] } }, { $set: { resolution: req.body.resolution, resolutionNote: req.body.note, resolvedBy: req.admin.id, resolvedAt: new Date() } }, { returnDocument: 'after' });
    if (!rec) throw Errors.conflict('Record is not open', 'INVALID_STATE');
    await adminAudit(req, 'admin.reconciliation.resolved', 'ReconciliationRecord', rec._id, req.body);
    return { resolution: rec.resolution };
  },
});

// ======================================================================= finance
r.route({
  method: 'get', path: '/finance/summary', summary: 'Fee revenue, volumes, reversals and settlement view', middleware: P('finance.read'),
  query: z.object({ from: z.coerce.date().default(() => new Date(Date.now() - 30 * DAY)), to: z.coerce.date().default(() => new Date()) }),
  handler: async (req) => {
    const { from, to } = req.valid.query;
    const [byProvider, reversals, recon] = await Promise.all([
      Transaction.aggregate([
        { $match: { createdAt: { $gte: from, $lt: to } } },
        { $group: { _id: { provider: '$provider', status: '$status', currency: '$currency' }, n: { $sum: 1 }, amount: { $sum: '$amountMinor' }, fees: { $sum: '$feeMinor' } } },
      ]),
      Transaction.find({ $or: [{ status: 'REVERSED', completedAt: { $gte: from, $lt: to } }, { 'reversal.requestedAt': { $gte: from, $lt: to } }] }).limit(200).lean(),
      ReconciliationRecord.aggregate([{ $match: { createdAt: { $gte: from, $lt: to } } }, { $group: { _id: '$result', n: { $sum: 1 } } }]),
    ]);
    const providers = {};
    for (const row of byProvider) {
      const p = (providers[row._id.provider] ??= { provider: row._id.provider, currency: row._id.currency, byStatus: {}, feeRevenueMinor: 0, settledVolumeMinor: 0 });
      p.byStatus[row._id.status] = { count: row.n, amount: money(row.amount, row._id.currency) };
      if (row._id.status === 'SUCCESSFUL') { p.feeRevenueMinor += row.fees; p.settledVolumeMinor += row.amount; }
    }
    return {
      window: { from, to },
      providers: Object.values(providers).map((p) => ({ ...p, feeRevenue: money(p.feeRevenueMinor, p.currency), settledVolume: money(p.settledVolumeMinor, p.currency) })),
      reversals: reversals.map((t) => ({ id: String(t._id), reference: t.reference, status: t.status, amount: money(t.amountMinor, t.currency), requestedAt: t.reversal?.requestedAt ?? null, completedAt: t.status === 'REVERSED' ? t.completedAt : null })),
      reconciliation: Object.fromEntries(recon.map((x) => [x._id, x.n])),
      note: 'The platform does not hold customer funds; settlement is between customers and licensed providers. Fee revenue reflects configured platform fees on successful transactions.',
    };
  },
});

r.route({
  method: 'get', path: '/providers', summary: 'Payment provider configuration', middleware: P('finance.read'),
  handler: async () => {
    const docs = await PaymentProvider.find().lean();
    const known = new Map(docs.map((d) => [d.code, d]));
    for (const code of config.paymentProviders) if (!known.has(code)) known.set(code, { code, name: code, enabled: true, fees: [], unconfigured: true });
    return { items: [...known.values()].map((p) => ({ ...p, _id: undefined, id: p._id ? String(p._id) : null, active: config.paymentProviders.includes(p.code) })) };
  },
});

r.route({
  method: 'put', path: '/providers/:code', summary: 'Update provider config (fees, enabled, maintenance)', middleware: P('providers.manage'),
  params: z.object({ code: z.string().regex(/^[a-z0-9-]{2,30}$/) }),
  body: z.object({
    name: z.string().max(60), kind: z.enum(['MOBILE_MONEY', 'BANK', 'AGGREGATOR', 'CARD_ISSUER']), enabled: z.boolean(), maintenance: z.boolean(), priority: z.number().int().min(1).max(1000),
    countries: z.array(z.string().length(2)).max(20), currencies: z.array(z.string().length(3)).max(10), sandbox: z.boolean(),
    fees: z.array(z.object({ type: z.enum(TX_TYPES), minAmount: amountString, maxAmount: amountString, fixed: amountString, bps: z.number().int().min(0).max(2000) })).max(50),
    reason,
  }),
  handler: async (req) => {
    const { reason: why, fees, ...rest } = req.body;
    const cur = rest.currencies[0] ?? 'KES';
    const before = await PaymentProvider.findOne({ code: req.valid.params.code }).lean();
    const doc = await PaymentProvider.findOneAndUpdate({ code: req.valid.params.code }, { $set: { ...rest, fees: fees.map((f) => ({ type: f.type, minAmountMinor: toMinor(f.minAmount, cur), maxAmountMinor: toMinor(f.maxAmount, cur), fixedMinor: toMinor(f.fixed, cur), bps: f.bps })) } }, { returnDocument: 'after', upsert: true }).lean();
    await invalidate(`provider-config:${doc.code}`);
    await adminAudit(req, 'admin.provider.updated', 'PaymentProvider', doc.code, { reason: why, before: before ? { enabled: before.enabled, maintenance: before.maintenance, fees: before.fees } : null, after: { enabled: doc.enabled, maintenance: doc.maintenance, fees: doc.fees } });
    return { ...doc, _id: undefined };
  },
});

// ======================================================================= campaigns
const campaignBody = z.object({
  code: z.string().regex(/^[A-Z0-9_]{3,40}$/), name: z.string().max(80), description: z.string().max(500).optional(), terms: z.string().max(4000).optional(),
  type: z.enum(['CASHBACK', 'POINTS', 'REFERRAL', 'PARTNER_DEAL']), country: z.string().length(2).default('KE'), startsAt: z.coerce.date(), endsAt: z.coerce.date().optional(),
  rules: z.object({
    transactionTypes: z.array(z.enum(TX_TYPES)).optional(), categories: z.array(z.string().max(40)).optional(), minAmount: amountString.optional(),
    cashbackBps: z.number().int().min(0).max(10_000).optional(), maxReward: amountString.optional(), pointsPerUnit: z.number().min(0).max(1000).optional(), unitAmount: amountString.optional(),
    perUserLimit: z.number().int().min(0).optional(), firstTransactionOnly: z.boolean().optional(), referrerPoints: z.number().int().min(0).optional(), refereePoints: z.number().int().min(0).optional(),
    referralQualifyingMinAmount: amountString.optional(), maxReferralsPerReferrerPerMonth: z.number().int().min(1).max(1000).optional(), holdDays: z.number().int().min(0).max(90).optional(),
  }).default({}),
  totalBudget: amountString.optional(),
  partner: z.object({ name: z.string().max(60), logoUrl: z.string().url().max(300).optional(), dealUrl: z.string().url().max(300).optional(), promoCode: z.string().max(40).optional() }).optional(),
});

function toCampaignDoc(b) {
  const cur = getCountry(b.country).currency;
  const r2 = b.rules ?? {};
  const m = (v) => (v ? toMinor(v, cur) : undefined);
  return {
    code: b.code, name: b.name, description: b.description, terms: b.terms, type: b.type, country: b.country, currency: cur, startsAt: b.startsAt, endsAt: b.endsAt, partner: b.partner,
    totalBudgetMinor: m(b.totalBudget),
    rules: {
      transactionTypes: r2.transactionTypes, categories: r2.categories, minAmountMinor: m(r2.minAmount) ?? 0, cashbackBps: r2.cashbackBps, maxRewardMinor: m(r2.maxReward),
      pointsPerUnit: r2.pointsPerUnit, unitMinor: m(r2.unitAmount) ?? 100_00, perUserLimit: r2.perUserLimit, firstTransactionOnly: r2.firstTransactionOnly,
      referrerPoints: r2.referrerPoints, refereePoints: r2.refereePoints, referralQualifyingMinAmountMinor: m(r2.referralQualifyingMinAmount) ?? 0,
      maxReferralsPerReferrerPerMonth: r2.maxReferralsPerReferrerPerMonth, holdDays: r2.holdDays,
    },
  };
}

r.route({ method: 'get', path: '/campaigns', summary: 'Reward campaigns', query: pageQuery.extend({ status: z.enum(['DRAFT', 'ACTIVE', 'PAUSED', 'ENDED']).optional() }), middleware: P('campaigns.read'), handler: async (req) => {
  const page = await paginate(RewardCampaign, req.valid.query.status ? { status: req.valid.query.status } : {}, req.valid.query);
  return { ...page, items: page.items.map((c) => ({ ...c, id: String(c._id), _id: undefined, budgetUsed: money(c.budgetUsedMinor ?? 0, c.currency), totalBudget: c.totalBudgetMinor != null ? money(c.totalBudgetMinor, c.currency) : null })) };
} });
r.route({ method: 'post', path: '/campaigns', summary: 'Create a reward campaign (as DRAFT)', status: 201, body: campaignBody, middleware: P('campaigns.manage'), handler: async (req) => {
  const c = await RewardCampaign.create({ ...toCampaignDoc(req.body), status: 'DRAFT', createdBy: req.admin.id });
  await adminAudit(req, 'admin.campaign.created', 'RewardCampaign', c._id, { code: c.code });
  return { id: String(c._id), status: c.status };
} });
r.route({ method: 'put', path: '/campaigns/:id', summary: 'Edit a campaign (DRAFT or PAUSED only)', params: idParams, body: campaignBody, middleware: P('campaigns.manage'), handler: async (req) => {
  const c = await RewardCampaign.findOneAndUpdate({ _id: req.valid.params.id, status: { $in: ['DRAFT', 'PAUSED'] } }, { $set: toCampaignDoc(req.body) }, { returnDocument: 'after' });
  if (!c) throw Errors.conflict('Only draft or paused campaigns can be edited', 'INVALID_STATE');
  await adminAudit(req, 'admin.campaign.updated', 'RewardCampaign', c._id, { code: c.code });
  return { id: String(c._id), status: c.status };
} });
r.route({ method: 'post', path: '/campaigns/:id/status', summary: 'Activate, pause or end a campaign', params: idParams, body: z.object({ status: z.enum(['ACTIVE', 'PAUSED', 'ENDED']) }), middleware: P('campaigns.manage'), handler: async (req) => {
  const allowed = { ACTIVE: ['DRAFT', 'PAUSED'], PAUSED: ['ACTIVE'], ENDED: ['ACTIVE', 'PAUSED', 'DRAFT'] }[req.body.status];
  const c = await RewardCampaign.findOneAndUpdate({ _id: req.valid.params.id, status: { $in: allowed } }, { $set: { status: req.body.status } }, { returnDocument: 'after' });
  if (!c) throw Errors.conflict('Invalid status change', 'INVALID_STATE');
  await adminAudit(req, `admin.campaign.${req.body.status.toLowerCase()}`, 'RewardCampaign', c._id);
  return { status: c.status };
} });
r.route({ method: 'get', path: '/referrals', summary: 'Referral tracking', query: pageQuery.extend({ status: z.enum(['PENDING', 'QUALIFIED', 'REWARDED', 'REJECTED']).optional() }), middleware: P('campaigns.read'), handler: async (req) => {
  const page = await paginate(Referral, req.valid.query.status ? { status: req.valid.query.status } : {}, req.valid.query);
  return { ...page, items: page.items.map((x) => ({ id: String(x._id), referrerId: String(x.referrerId), refereeId: String(x.refereeId), status: x.status, fraudSignals: x.fraudSignals, createdAt: x.createdAt, rewardedAt: x.rewardedAt ?? null })) };
} });

r.route({ method: 'get', path: '/notification-campaigns', summary: 'Notification campaigns', query: pageQuery, middleware: P('campaigns.read'), handler: async (req) => {
  const page = await paginate(NotificationCampaign, {}, req.valid.query);
  return { ...page, items: page.items.map((c) => ({ ...c, id: String(c._id), _id: undefined })) };
} });
r.route({
  method: 'post', path: '/notification-campaigns', summary: 'Create and send/schedule a promotional notification (marketing-consent users only)', status: 201, middleware: P('notifications.campaign'),
  body: z.object({ title: z.string().trim().min(3).max(120), body: z.string().trim().min(3).max(500), countries: z.array(z.string().length(2)).max(10).optional(), kycTiers: z.array(z.enum(['TIER_0', 'TIER_1', 'TIER_2'])).optional(), sendAt: z.coerce.date().optional() }),
  handler: async (req) => {
    const c = await NotificationCampaign.create({ title: req.body.title, body: req.body.body, segment: { countries: req.body.countries, kycTiers: req.body.kycTiers }, status: 'SCHEDULED', scheduledAt: req.body.sendAt ?? new Date(), createdBy: req.admin.id });
    await enqueue(QUEUES.notifications, 'campaign', { campaignId: String(c._id) }, { delay: Math.max(0, (req.body.sendAt?.getTime() ?? Date.now()) - Date.now()), jobId: `campaign-${c._id}` });
    await adminAudit(req, 'admin.notification_campaign.scheduled', 'NotificationCampaign', c._id, { title: c.title });
    return { id: String(c._id), status: c.status };
  },
});

// ======================================================================= support
r.route({ method: 'get', path: '/support/tickets', summary: 'Support queue', query: pageQuery.extend({ status: z.enum(['OPEN', 'IN_PROGRESS', 'AWAITING_USER', 'RESOLVED', 'CLOSED']).optional(), category: z.string().max(30).optional() }), middleware: P('support.read'), handler: async (req) => {
  const q = req.valid.query;
  const page = await paginate(SupportTicket, { ...(q.status && { status: q.status }), ...(q.category && { category: q.category }) }, q);
  return { ...page, items: page.items.map((t) => ({ ...serializeTicket(t, { includeInternal: true }), userId: String(t.userId), assignedTo: t.assignedTo ? String(t.assignedTo) : null, metadata: t.category === 'ACCOUNT_RECOVERY' ? { requestedPhone: can(req, 'users.pii.read') ? t.metadata?.requestedPhone : maskPhone(t.metadata?.requestedPhone) } : undefined })) };
} });
r.route({
  method: 'post', path: '/support/tickets/:id/messages', summary: 'Reply to a ticket or add an internal note', params: idParams, middleware: P('support.manage'),
  body: z.object({ message: z.string().trim().min(1).max(4000), internal: z.boolean().default(false), status: z.enum(['OPEN', 'IN_PROGRESS', 'AWAITING_USER', 'RESOLVED', 'CLOSED']).optional() }),
  handler: async (req) => {
    const set = { assignedTo: req.admin.id };
    if (req.body.status) { set.status = req.body.status; if (['RESOLVED', 'CLOSED'].includes(req.body.status)) set.resolvedAt = new Date(); }
    const t = await SupportTicket.findByIdAndUpdate(req.valid.params.id, { $push: { messages: { authorType: 'ADMIN', authorId: req.admin.id, body: req.body.message, internal: req.body.internal } }, $set: set }, { returnDocument: 'after' }).lean();
    if (!t) throw Errors.notFound('Ticket');
    if (!req.body.internal) await notify(t.userId, { category: 'SYSTEM', type: 'SUPPORT_REPLY', title: `Update on ${t.reference}`, body: req.body.message.slice(0, 200), data: { route: `/support/${t._id}` } });
    await adminAudit(req, 'admin.support.replied', 'SupportTicket', t._id, { internal: req.body.internal, status: req.body.status });
    return serializeTicket(t, { includeInternal: true });
  },
});

// ======================================================================= security
r.route({ method: 'get', path: '/security/events', summary: 'Security events and suspicious activity', query: pageQuery.extend({ severity: z.enum(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).optional(), type: z.string().max(40).optional(), unacknowledged: z.coerce.boolean().optional(), admin: z.coerce.boolean().optional() }), middleware: P('security.read'), handler: async (req) => {
  const q = req.valid.query;
  const filter = {};
  if (q.severity) filter.severity = q.severity;
  if (q.type) filter.type = q.type;
  if (q.unacknowledged) filter.acknowledgedAt = null;
  if (q.admin) filter.adminId = { $ne: null };
  const page = await paginate(SecurityEvent, filter, q);
  return { ...page, items: page.items.map((e) => ({ id: String(e._id), type: e.type, severity: e.severity, userId: e.userId ? String(e.userId) : null, adminId: e.adminId ? String(e.adminId) : null, ip: e.ip, deviceId: e.deviceId ?? null, details: e.details ?? null, acknowledged: Boolean(e.acknowledgedAt), at: e.createdAt })) };
} });
r.route({ method: 'post', path: '/security/events/:id/acknowledge', summary: 'Acknowledge a security alert', params: idParams, body: z.object({ note: z.string().max(500).optional() }), middleware: P('security.manage'), handler: async (req) => {
  const e = await SecurityEvent.findOneAndUpdate({ _id: req.valid.params.id, acknowledgedAt: null }, { $set: { acknowledgedAt: new Date(), acknowledgedBy: req.admin.id } }, { returnDocument: 'after' });
  if (!e) throw Errors.conflict('Already acknowledged', 'INVALID_STATE');
  await adminAudit(req, 'admin.security_event.acknowledged', 'SecurityEvent', e._id, { note: req.body.note });
  return { acknowledged: true };
} });
r.route({ method: 'get', path: '/audit-logs', summary: 'Tamper-evident audit log', query: pageQuery.extend({ actorType: z.enum(['USER', 'ADMIN', 'SYSTEM', 'PROVIDER']).optional(), actorId: z.string().max(40).optional(), action: z.string().max(80).optional(), resourceId: z.string().max(80).optional() }), middleware: P('audit.read'), handler: async (req) => {
  const q = req.valid.query;
  const filter = {};
  for (const k of ['actorType', 'actorId', 'resourceId']) if (q[k]) filter[k] = q[k];
  if (q.action) filter.action = { $regex: `^${escapeRegex(q.action)}` };
  const page = await paginate(AuditLog, filter, q);
  return { ...page, items: page.items.map((a) => ({ seq: a.seq, actorType: a.actorType, actorId: a.actorId, action: a.action, resourceType: a.resourceType, resourceId: a.resourceId, outcome: a.outcome, ip: a.ip, metadata: a.metadata, at: a.createdAt, hash: a.hash })) };
} });
r.route({ method: 'get', path: '/audit-logs/verify', summary: 'Verify audit hash chain integrity', middleware: P('audit.read'), handler: async (req) => {
  const result = await verifyAuditChain();
  await adminAudit(req, 'admin.audit.verified', 'AuditLog', null, result);
  return result;
} });

// ======================================================================= administrators
r.route({ method: 'get', path: '/admins', summary: 'Administrators', middleware: P('admins.manage'), handler: async () => {
  const admins = await AdminUser.find().sort({ createdAt: 1 }).lean();
  return { items: admins.map((a) => ({ id: String(a._id), email: a.email, name: a.name, roles: a.roles, status: a.status, mfaEnabled: a.mfaEnabled, lastLoginAt: a.lastLoginAt ?? null, createdAt: a.createdAt })) };
} });
r.route({ method: 'get', path: '/roles', summary: 'Roles and permissions', middleware: P('admins.manage'), handler: async () => {
  await syncRbac();
  return { roles: await Role.find().sort({ key: 1 }).lean().then((rs) => rs.map((x) => ({ key: x.key, name: x.name, permissions: x.permissions, system: x.system }))), permissions: Object.entries(PERMISSIONS).map(([key, [group, description]]) => ({ key, group, description })) };
} });
r.route({
  method: 'post', path: '/admins', summary: 'Invite an administrator (temporary password, MFA enrollment forced)', status: 201, middleware: P('admins.manage'),
  body: z.object({ email: z.string().email().max(254), name: z.string().trim().min(2).max(80), roles: z.array(z.enum(Object.keys(DEFAULT_ROLES))).min(1).max(3) }),
  handler: async (req) => {
    if (req.body.roles.includes('SUPER_ADMIN') && !req.admin.roles.includes('SUPER_ADMIN')) throw Errors.forbidden('Only a Super Administrator can grant Super Administrator');
    const tempPassword = `${randomToken(12)}9a`;
    const a = await AdminUser.create({ email: req.body.email, name: req.body.name, roles: req.body.roles, passwordHash: await hashSecret(tempPassword), mustChangePassword: true, createdBy: req.admin.id });
    await adminAudit(req, 'admin.admin.created', 'AdminUser', a._id, { email: a.email, roles: a.roles });
    return { id: String(a._id), temporaryPassword: tempPassword, note: 'Share via a secure channel. The administrator must enrol MFA and change this password on first sign-in.' };
  },
});
r.route({
  method: 'patch', path: '/admins/:id', summary: 'Change roles, disable, or reset MFA', params: idParams, middleware: P('admins.manage'),
  body: z.object({ roles: z.array(z.enum(Object.keys(DEFAULT_ROLES))).min(1).max(3).optional(), status: z.enum(['ACTIVE', 'DISABLED']).optional(), resetMfa: z.boolean().optional(), reason }),
  handler: async (req) => {
    if (req.valid.params.id === req.admin.id) throw Errors.forbidden('You cannot change your own access');
    if (req.body.roles?.includes('SUPER_ADMIN') && !req.admin.roles.includes('SUPER_ADMIN')) throw Errors.forbidden('Only a Super Administrator can grant Super Administrator');
    const set = {};
    const unset = {};
    if (req.body.roles) set.roles = req.body.roles;
    if (req.body.status) set.status = req.body.status;
    if (req.body.resetMfa) { set.mfaEnabled = false; unset.mfaSecretEnc = 1; unset.mfaLastStep = 1; }
    const a = await AdminUser.findByIdAndUpdate(req.valid.params.id, { $set: set, $unset: unset }, { returnDocument: 'after' });
    if (!a) throw Errors.notFound('Administrator');
    if (req.body.status === 'DISABLED' || req.body.resetMfa || req.body.roles) {
      const sessions = await AdminSession.find({ adminId: a._id, revokedAt: null }, { _id: 1 }).lean();
      await AdminSession.updateMany({ adminId: a._id, revokedAt: null }, { $set: { revokedAt: new Date() } });
      await Promise.all(sessions.map((s) => getRedis().set(`admin-revoked:${s._id}`, '1', 'EX', config.ADMIN_TOKEN_TTL_SECONDS)));
    }
    await adminAudit(req, 'admin.admin.updated', 'AdminUser', a._id, { ...req.body });
    return { id: String(a._id), roles: a.roles, status: a.status, mfaEnabled: a.mfaEnabled };
  },
});

export default r.router;
