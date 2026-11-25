import { describe, it, expect, beforeAll } from 'vitest';
import { api, createUser, idemKey } from './helpers.js';
import { AdminUser } from '../src/modules/admin/models.js';
import { syncRbac } from '../src/modules/admin/rbac.js';
import { hashSecret, decryptField } from '../src/lib/crypto.js';
import { totpCode } from '../src/lib/totp.js';
import { User, KycRecord } from '../src/modules/users/models.js';
import { Transaction, MockProviderLedger, ReconciliationRecord } from '../src/modules/payments/models.js';
import { getAdapter } from '../src/modules/payments/providers/registry.js';
import { processCallback } from '../src/modules/payments/service.js';
import { signMockPayload } from '../src/modules/payments/providers/mock.js';
import { AuditLog } from '../src/modules/audit/models.js';
import { Notification } from '../src/modules/notifications/models.js';

const PASSWORD = 'Adm1n-Passw0rd-Long';

async function makeAdmin(email, roles) {
  await AdminUser.create({ email, name: email.split('@')[0], roles, passwordHash: await hashSecret(PASSWORD) });
}

/** Full login: password -> MFA setup/enrol (first time) -> token. */
async function adminLogin(email) {
  const step1 = await api().post('/admin/v1/auth/login').send({ email, password: PASSWORD }).expect(200);
  if (step1.body.next === 'MFA_ENROLL') {
    const setup = await api().post('/admin/v1/auth/mfa/setup').send({ mfaToken: step1.body.mfaToken }).expect(200);
    const res = await api().post('/admin/v1/auth/mfa/enroll').send({ mfaToken: step1.body.mfaToken, code: totpCode(setup.body.secret) }).expect(200);
    return { token: res.body.accessToken, secret: setup.body.secret };
  }
  const admin = await AdminUser.findOne({ email }).select('+mfaSecretEnc');
  const secret = decryptField(admin.mfaSecretEnc);
  const res = await api().post('/admin/v1/auth/mfa/verify').send({ mfaToken: step1.body.mfaToken, code: totpCode(secret, Date.now() + 30_000) }).expect(200);
  return { token: res.body.accessToken, secret };
}

const as = (t) => ({ Authorization: `Bearer ${t}` });
let superT; let financeA; let financeB; let support; let marketing; let compliance;

beforeAll(async () => {
  await syncRbac();
  await makeAdmin('root@pesa.test', ['SUPER_ADMIN']);
  await makeAdmin('fin.a@pesa.test', ['FINANCE_ADMIN']);
  await makeAdmin('fin.b@pesa.test', ['FINANCE_ADMIN']);
  await makeAdmin('support@pesa.test', ['CUSTOMER_SUPPORT']);
  await makeAdmin('mkt@pesa.test', ['MARKETING_ADMIN']);
  await makeAdmin('kyc@pesa.test', ['COMPLIANCE_OFFICER']);
  superT = (await adminLogin('root@pesa.test')).token;
  financeA = (await adminLogin('fin.a@pesa.test')).token;
  financeB = (await adminLogin('fin.b@pesa.test')).token;
  support = (await adminLogin('support@pesa.test')).token;
  marketing = (await adminLogin('mkt@pesa.test')).token;
  compliance = (await adminLogin('kyc@pesa.test')).token;
});

describe('admin authentication', () => {
  it('requires MFA — a password alone never yields a token', async () => {
    const r = await api().post('/admin/v1/auth/login').send({ email: 'root@pesa.test', password: PASSWORD }).expect(200);
    expect(r.body.accessToken).toBeUndefined();
    expect(r.body.next).toBe('MFA_VERIFY');
    await api().post('/admin/v1/auth/mfa/verify').send({ mfaToken: r.body.mfaToken, code: '000000' }).expect(401);
  });

  it('rejects a replayed TOTP code', async () => {
    const admin = await AdminUser.findOne({ email: 'support@pesa.test' }).select('+mfaSecretEnc +mfaLastStep');
    const code = totpCode(decryptField(admin.mfaSecretEnc), admin.mfaLastStep * 30_000); // the code already used at login
    const r = await api().post('/admin/v1/auth/login').send({ email: 'support@pesa.test', password: PASSWORD }).expect(200);
    await api().post('/admin/v1/auth/mfa/verify').send({ mfaToken: r.body.mfaToken, code }).expect(401);
  });

  it('does not accept user-app tokens on admin routes', async () => {
    const u = await createUser({ pin: null });
    await api().get('/admin/v1/dashboard').set(as(u.tokens.accessToken)).expect(401);
  });

  it('revokes the admin session on logout', async () => {
    const t = (await adminLogin('mkt@pesa.test')).token;
    await api().post('/admin/v1/auth/logout').set(as(t)).expect(204);
    await api().get('/admin/v1/auth/me').set(as(t)).expect(401);
  });
});

describe('RBAC', () => {
  it('enforces permissions per role', async () => {
    await api().get('/admin/v1/dashboard').set(as(superT)).expect(200);
    await api().get('/admin/v1/dashboard').set(as(support)).expect(403);
    await api().get('/admin/v1/campaigns').set(as(marketing)).expect(200);
    await api().get('/admin/v1/transactions').set(as(marketing)).expect(403);
    await api().get('/admin/v1/admins').set(as(financeA)).expect(403);
    await api().get('/admin/v1/audit-logs').set(as(support)).expect(403);
  });

  it('masks PII for roles without users.pii.read', async () => {
    const u = await createUser({ pin: null });
    const masked = await api().get(`/admin/v1/users/${u.user.id}`).set(as(support)).expect(200);
    expect(masked.body.user.phone).not.toBe(u.phone);
    expect(masked.body.user.phone).toContain('*');
    expect(masked.body.user.piiMasked).toBe(true);
    const full = await api().get(`/admin/v1/users/${u.user.id}`).set(as(compliance)).expect(200);
    expect(full.body.user.phone).toBe(u.phone);
    expect(await AuditLog.exists({ action: 'admin.user.pii.viewed', resourceId: u.user.id })).toBeTruthy();
  });
});

describe('user management & KYC', () => {
  it('suspends (revoking sessions) and reactivates a user with an audit trail', async () => {
    const u = await createUser({ pin: null });
    await api().post(`/admin/v1/users/${u.user.id}/suspend`).set(as(compliance)).send({ reason: 'Suspected account takeover' }).expect(200);
    await api().get('/v1/me').set(u.auth()).expect(401);
    const login = await api().post('/v1/auth/login').send({ phone: u.phone, password: u.password, device: u.device }).expect(403);
    expect(login.body.error.code).toBe('FORBIDDEN');
    await api().post(`/admin/v1/users/${u.user.id}/reactivate`).set(as(compliance)).send({ reason: 'Verified with customer' }).expect(200);
    await api().post('/v1/auth/login').send({ phone: u.phone, password: u.password, device: u.device }).expect(200);
    const logs = await AuditLog.find({ resourceId: u.user.id, actorType: 'ADMIN' }).sort({ seq: 1 });
    expect(logs.map((l) => l.action)).toEqual(['admin.user.suspended', 'admin.user.reactivated']);
  });

  it('approves KYC, raising the user tier, and reveals ID numbers only to permitted roles', async () => {
    const u = await createUser({ pin: null });
    await api().post('/v1/me/kyc').set(u.auth()).send({ idType: 'NATIONAL_ID', idNumber: '23456789', fullName: 'Amani Otieno', dateOfBirth: '1995-04-02' }).expect(202);
    const rec = await KycRecord.findOne({ userId: u.user.id });
    await api().get(`/admin/v1/kyc/${rec._id}/id-number`).set(as(support)).expect(403);
    const id = await api().get(`/admin/v1/kyc/${rec._id}/id-number`).set(as(compliance)).expect(200);
    expect(id.body.idNumber).toBe('23456789');
    await api().post(`/admin/v1/kyc/${rec._id}/decision`).set(as(compliance)).send({ decision: 'APPROVE', tier: 'TIER_1' }).expect(200);
    await api().post(`/admin/v1/kyc/${rec._id}/decision`).set(as(compliance)).send({ decision: 'REJECT', reason: 'x' }).expect(409);
    const user = await User.findById(u.user.id);
    expect(user.kycTier).toBe('TIER_1');
    expect(await Notification.exists({ userId: u.user.id, type: 'KYC_APPROVED' })).toBeTruthy();
  });
});

describe('transactions, maker-checker reversals and reconciliation', () => {
  let txnId;
  beforeAll(async () => {
    const u = await createUser();
    const res = await api().post('/v1/payments').set(u.auth()).set('Idempotency-Key', idemKey()).send({ type: 'AIRTIME', amount: '150.00', pin: u.pin }).expect(202);
    txnId = res.body.transaction.id;
    const t = await Transaction.findById(txnId).lean();
    const cb = await getAdapter('mock').buildCallback(t.providerRequestId);
    const raw = Buffer.from(JSON.stringify(cb));
    await processCallback('mock', { body: cb, rawBody: raw, ip: '127.0.0.1', params: {}, get: () => signMockPayload(raw) });
  });

  it('shows transaction detail with immutable event history and callbacks', async () => {
    const d = await api().get(`/admin/v1/transactions/${txnId}`).set(as(financeA)).expect(200);
    expect(d.body.transaction.status).toBe('SUCCESSFUL');
    expect(d.body.events.map((e) => e.to)).toEqual(['INITIATED', 'PENDING', 'SUCCESSFUL']);
    expect(d.body.callbacks).toHaveLength(1);
  });

  it('exposes no endpoint for editing a successful transaction', async () => {
    for (const m of ['put', 'patch', 'delete']) {
      const res = await api()[m](`/admin/v1/transactions/${txnId}`).set(as(superT)).send({ amount: '1.00', status: 'FAILED' });
      expect(res.status).toBe(404);
    }
    expect((await Transaction.findById(txnId)).status).toBe('SUCCESSFUL');
  });

  it('requires a different admin to approve a reversal', async () => {
    const req1 = await api().post(`/admin/v1/transactions/${txnId}/reversal-requests`).set(as(financeA)).send({ reason: 'Customer double-charged by biller' }).expect(201);
    await api().post(`/admin/v1/transactions/${txnId}/reversal-requests`).set(as(financeA)).send({ reason: 'Duplicate request attempt' }).expect(409);
    const self = await api().post(`/admin/v1/approvals/${req1.body.approvalId}/decision`).set(as(financeA)).send({ decision: 'APPROVE' }).expect(403);
    expect(self.body.error.message).toMatch(/Separation of duties/);
    const ok = await api().post(`/admin/v1/approvals/${req1.body.approvalId}/decision`).set(as(financeB)).send({ decision: 'APPROVE' }).expect(200);
    expect(ok.body.note).toMatch(/provider confirmation/);
    const t = await Transaction.findById(txnId);
    expect(t.status).toBe('SUCCESSFUL'); // not reversed until the provider confirms
    expect(t.reversal.providerRequestId).toBeTruthy();
  });

  it('reconciles against the provider report, auto-resolving pending and flagging conflicts', async () => {
    const u = await createUser();
    const pending = await api().post('/v1/payments').set(u.auth()).set('Idempotency-Key', idemKey()).send({ type: 'AIRTIME', amount: '80.02', pin: u.pin }).expect(202);
    const p = await Transaction.findById(pending.body.transaction.id);
    await MockProviderLedger.updateOne({ providerRequestId: p.providerRequestId }, { $set: { status: 'SUCCESS', externalRef: 'SBXRECON1' } });
    const conflict = await api().post('/v1/payments').set(u.auth()).set('Idempotency-Key', idemKey()).send({ type: 'AIRTIME', amount: '81.00', pin: u.pin }).expect(202);
    const c = await Transaction.findById(conflict.body.transaction.id);
    const cb = await getAdapter('mock').buildCallback(c.providerRequestId);
    const raw = Buffer.from(JSON.stringify(cb));
    await processCallback('mock', { body: cb, rawBody: raw, ip: '127.0.0.1', params: {}, get: () => signMockPayload(raw) });
    await MockProviderLedger.updateOne({ providerRequestId: c.providerRequestId }, { $set: { status: 'FAILED' } }); // provider later disagrees

    const run = await api().post('/admin/v1/reconciliation/runs').set(as(financeA)).send({ provider: 'mock', from: new Date(Date.now() - 3600_000).toISOString(), to: new Date(Date.now() + 60_000).toISOString() }).expect(201);
    expect(run.body.autoResolved).toBeGreaterThanOrEqual(1);
    expect((await Transaction.findById(p._id)).status).toBe('SUCCESSFUL');
    expect((await Transaction.findById(c._id)).status).toBe('SUCCESSFUL'); // never auto-flipped from terminal
    const rec = await ReconciliationRecord.findOne({ runId: run.body.runId, transactionId: c._id });
    expect(rec.result).toBe('STATUS_MISMATCH');
    expect(rec.resolution).toBe('OPEN');
    await api().post(`/admin/v1/reconciliation/records/${rec._id}/resolve`).set(as(financeB)).send({ resolution: 'ESCALATED', note: 'Raised with provider ops' }).expect(200);
  });

  it('updates provider fee configuration with an audit trail', async () => {
    await api().put('/admin/v1/providers/mock').set(as(financeA)).send({
      name: 'Sandbox', kind: 'AGGREGATOR', enabled: true, maintenance: false, priority: 100, countries: ['KE'], currencies: ['KES'], sandbox: true,
      fees: [{ type: 'PAYBILL', minAmount: '0', maxAmount: '1000000', fixed: '0', bps: 50 }], reason: 'Q4 pricing review',
    }).expect(200);
    expect(await AuditLog.exists({ action: 'admin.provider.updated' })).toBeTruthy();
  });
});

describe('campaigns, security and audit', () => {
  it('creates a campaign as a draft and activates it', async () => {
    const c = await api().post('/admin/v1/campaigns').set(as(marketing)).send({ code: 'BILLS_2PCT', name: '2% on bills', type: 'CASHBACK', startsAt: new Date().toISOString(), rules: { transactionTypes: ['UTILITY'], cashbackBps: 200, maxReward: '50' }, totalBudget: '10000' }).expect(201);
    expect(c.body.status).toBe('DRAFT');
    await api().post(`/admin/v1/campaigns/${c.body.id}/status`).set(as(marketing)).send({ status: 'ACTIVE' }).expect(200);
    await api().put(`/admin/v1/campaigns/${c.body.id}`).set(as(marketing)).send({ code: 'BILLS_2PCT', name: 'x', type: 'CASHBACK', startsAt: new Date().toISOString() }).expect(409);
  });

  it('sends promotional notifications only to users who consented to marketing', async () => {
    const yes = await createUser({ pin: null, body: { marketingConsent: true } });
    const no = await createUser({ pin: null });
    await api().post('/admin/v1/notification-campaigns').set(as(marketing)).send({ title: 'Weekend offer', body: 'Double points this weekend!' }).expect(201);
    expect(await Notification.exists({ userId: yes.user.id, type: 'CAMPAIGN' })).toBeTruthy();
    expect(await Notification.exists({ userId: no.user.id, type: 'CAMPAIGN' })).toBeFalsy();
  });

  it('stops admins from escalating their own access', async () => {
    const me = await api().get('/admin/v1/auth/me').set(as(superT)).expect(200);
    await api().patch(`/admin/v1/admins/${me.body.id}`).set(as(superT)).send({ roles: ['MARKETING_ADMIN'], reason: 'self change' }).expect(403);
  });

  it('keeps an intact, verifiable audit hash chain', async () => {
    const v = await api().get('/admin/v1/audit-logs/verify').set(as(superT)).expect(200);
    expect(v.body.valid).toBe(true);
    expect(v.body.checked).toBeGreaterThan(5);
    await expect(AuditLog.updateOne({}, { $set: { action: 'tampered' } })).rejects.toThrow(/append-only/);
    // Tampering directly in the database is detected by verification.
    await AuditLog.collection.updateOne({ seq: 2 }, { $set: { action: 'tampered' } });
    const bad = await api().get('/admin/v1/audit-logs/verify').set(as(superT)).expect(200);
    expect(bad.body.valid).toBe(false);
    expect(bad.body.brokenAt).toBe(2);
  });
});

describe('temporary passwords', () => {
  it('blocks privileged actions until an invited admin changes their password', async () => {
    const inv = await api().post('/admin/v1/admins').set(as(superT)).send({ email: 'new.ops@pesa.test', name: 'New Ops', roles: ['OPERATIONS_ADMIN'] }).expect(201);
    const s1 = await api().post('/admin/v1/auth/login').send({ email: 'new.ops@pesa.test', password: inv.body.temporaryPassword }).expect(200);
    const setup = await api().post('/admin/v1/auth/mfa/setup').send({ mfaToken: s1.body.mfaToken }).expect(200);
    const tok = (await api().post('/admin/v1/auth/mfa/enroll').send({ mfaToken: s1.body.mfaToken, code: totpCode(setup.body.secret) }).expect(200)).body.accessToken;
    const blocked = await api().get('/admin/v1/dashboard').set(as(tok)).expect(403);
    expect(blocked.body.error.code).toBe('PASSWORD_CHANGE_REQUIRED');
    expect((await api().get('/admin/v1/auth/me').set(as(tok)).expect(200)).body.mustChangePassword).toBe(true);
    await api().post('/admin/v1/auth/password').set(as(tok)).send({ currentPassword: inv.body.temporaryPassword, newPassword: 'My-0wn-Strong-Passphrase' }).expect(200);
    await api().get('/admin/v1/dashboard').set(as(tok)).expect(200);
  });
});
