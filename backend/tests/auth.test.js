import { describe, it, expect } from 'vitest';
import { api, kenyanPhone, device, latestOtp, createUser } from './helpers.js';
import { Otp, Session } from '../src/modules/auth/models.js';
import { User } from '../src/modules/users/models.js';
import { SecurityEvent } from '../src/modules/audit/models.js';
import { readOutbox } from '../src/modules/messaging/service.js';

describe('registration & phone verification', () => {
  it('registers a Kenyan number in national format and normalises to E.164', async () => {
    const res = await api().post('/v1/auth/register').send({
      phone: '0722 000 111', password: 'Str0ngPass!', firstName: 'Wanjiku', lastName: 'Kamau', acceptTerms: true,
    }).expect(202);
    expect(res.body.phone).toBe('+254722000111');
    const user = await User.findOne({ phone: '+254722000111' }).select('+passwordHash');
    expect(user.status).toBe('PENDING_VERIFICATION');
    expect(user.currency).toBe('KES');
    expect(user.passwordHash).toMatch(/^\$argon2id\$/);
  });

  it('never stores OTPs in plaintext', async () => {
    const phone = kenyanPhone();
    await api().post('/v1/auth/register').send({ phone, password: 'Str0ngPass!', firstName: 'A', lastName: 'B', acceptTerms: true }).expect(202);
    const code = latestOtp(phone);
    const otp = await Otp.findOne({ purpose: 'PHONE_VERIFY' }).sort({ createdAt: -1 }).lean();
    expect(JSON.stringify(otp)).not.toContain(code);
  });

  it('rejects weak passwords, invalid numbers and missing consent', async () => {
    await api().post('/v1/auth/register').send({ phone: kenyanPhone(), password: 'password', firstName: 'A', lastName: 'B', acceptTerms: true }).expect(422);
    await api().post('/v1/auth/register').send({ phone: '+254100', password: 'Str0ngPass!', firstName: 'A', lastName: 'B', acceptTerms: true }).expect(422);
    await api().post('/v1/auth/register').send({ phone: kenyanPhone(), password: 'Str0ngPass!', firstName: 'A', lastName: 'B', acceptTerms: false }).expect(422);
  });

  it('rejects unknown body fields (mass-assignment protection)', async () => {
    const res = await api().post('/v1/auth/register').send({
      phone: kenyanPhone(), password: 'Str0ngPass!', firstName: 'A', lastName: 'B', acceptTerms: true, status: 'ACTIVE', kycTier: 'TIER_2',
    }).expect(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('does not reveal whether a number is already registered', async () => {
    const ctx = await createUser({ pin: null });
    const res = await api().post('/v1/auth/register').send({ phone: ctx.phone, password: 'An0therPass!', firstName: 'X', lastName: 'Y', acceptTerms: true }).expect(202);
    expect(res.body.status).toBe('OTP_SENT');
    expect(readOutbox(ctx.phone)[0].kind).toBe('DUPLICATE_REGISTRATION');
    // The original password still works.
    await api().post('/v1/auth/login').send({ phone: ctx.phone, password: ctx.password, device: ctx.device }).expect(200);
  });

  it('activates the account with the OTP and returns tokens', async () => {
    const ctx = await createUser({ pin: null });
    expect(ctx.user.status).toBe('ACTIVE');
    expect(ctx.user.phoneVerified).toBe(true);
    expect(ctx.tokens.accessToken).toBeTruthy();
    expect(ctx.tokens.refreshToken).toBeTruthy();
  });

  it('locks an OTP after too many wrong attempts', async () => {
    const phone = kenyanPhone();
    await api().post('/v1/auth/register').send({ phone, password: 'Str0ngPass!', firstName: 'A', lastName: 'B', acceptTerms: true }).expect(202);
    const code = latestOtp(phone);
    const wrong = code === '000000' ? '111111' : '000000';
    for (let i = 0; i < 5; i++) {
      await api().post('/v1/auth/verify-phone').send({ phone, code: wrong, device: device() }).expect(422);
    }
    const res = await api().post('/v1/auth/verify-phone').send({ phone, code, device: device() }).expect(422);
    expect(res.body.error.code).toBe('OTP_ATTEMPTS_EXCEEDED');
  });
});

describe('login, devices and lockout', () => {
  it('logs in directly on a trusted device', async () => {
    const ctx = await createUser({ pin: null });
    const res = await api().post('/v1/auth/login').send({ phone: ctx.phone, password: ctx.password, device: ctx.device }).expect(200);
    expect(res.body.tokens.accessToken).toBeTruthy();
  });

  it('requires OTP step-up on a new device and raises a security alert', async () => {
    const ctx = await createUser({ pin: null });
    const newDevice = device({ name: 'Unknown Tecno' });
    const step = await api().post('/v1/auth/login').send({ phone: ctx.phone, password: ctx.password, device: newDevice }).expect(200);
    expect(step.body.next).toBe('VERIFY_DEVICE');
    expect(step.body.tokens).toBeUndefined();
    const done = await api().post('/v1/auth/verify-device').send({ challengeId: step.body.challengeId, code: latestOtp(ctx.phone) }).expect(200);
    expect(done.body.tokens.accessToken).toBeTruthy();
    const evt = await SecurityEvent.findOne({ userId: ctx.user.id, type: 'NEW_DEVICE_LOGIN' });
    expect(evt).toBeTruthy();
    const notes = await api().get('/v1/notifications').set({ Authorization: `Bearer ${done.body.tokens.accessToken}` });
    if (notes.status === 200) expect(notes.body.items.some((n) => n.type === 'NEW_DEVICE_LOGIN')).toBe(true);
  });

  it('returns the same error for unknown users and wrong passwords', async () => {
    const ctx = await createUser({ pin: null });
    const a = await api().post('/v1/auth/login').send({ phone: kenyanPhone(), password: 'Whatever123', device: device() }).expect(401);
    const b = await api().post('/v1/auth/login').send({ phone: ctx.phone, password: 'Wrong12345', device: ctx.device }).expect(401);
    expect(a.body.error.code).toBe(b.body.error.code);
    expect(a.body.error.message).toBe(b.body.error.message);
  });

  it('locks the account after repeated failures', async () => {
    const ctx = await createUser({ pin: null });
    for (let i = 0; i < 4; i++) {
      await api().post('/v1/auth/login').send({ phone: ctx.phone, password: 'Wrong12345', device: ctx.device }).expect(401);
    }
    await api().post('/v1/auth/login').send({ phone: ctx.phone, password: 'Wrong12345', device: ctx.device }).expect(423);
    // Correct password is refused while locked.
    await api().post('/v1/auth/login').send({ phone: ctx.phone, password: ctx.password, device: ctx.device }).expect(423);
  });
});

describe('tokens and sessions', () => {
  it('rotates refresh tokens and detects reuse', async () => {
    const ctx = await createUser({ pin: null });
    const first = ctx.tokens.refreshToken;
    const r1 = await api().post('/v1/auth/refresh').send({ refreshToken: first, deviceId: ctx.device.deviceId }).expect(200);
    expect(r1.body.refreshToken).not.toBe(first);
    // Replaying the old token revokes the whole session.
    const replay = await api().post('/v1/auth/refresh').send({ refreshToken: first }).expect(401);
    expect(replay.body.error.code).toBe('INVALID_REFRESH_TOKEN');
    await api().post('/v1/auth/refresh').send({ refreshToken: r1.body.refreshToken }).expect(401);
    const evt = await SecurityEvent.findOne({ userId: ctx.user.id, type: 'REFRESH_TOKEN_REUSE' });
    expect(evt.severity).toBe('CRITICAL');
  });

  it('stores only hashes of refresh tokens', async () => {
    const ctx = await createUser({ pin: null });
    const s = await Session.findById(ctx.tokens.sessionId).lean();
    expect(s.refreshTokenHash).not.toBe(ctx.tokens.refreshToken);
    expect(JSON.stringify(s)).not.toContain(ctx.tokens.refreshToken);
  });

  it('revokes access immediately on logout', async () => {
    const ctx = await createUser({ pin: null });
    await api().get('/v1/me').set(ctx.auth()).expect(200);
    await api().post('/v1/auth/logout').set(ctx.auth()).expect(204);
    const res = await api().get('/v1/me').set(ctx.auth()).expect(401);
    expect(res.body.error.code).toBe('SESSION_REVOKED');
    await api().post('/v1/auth/refresh').send({ refreshToken: ctx.tokens.refreshToken }).expect(401);
  });

  it('rejects tampered or missing access tokens', async () => {
    await api().get('/v1/me').expect(401);
    const ctx = await createUser({ pin: null });
    const [h, p, s] = ctx.tokens.accessToken.split('.');
    const forged = Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(p, 'base64url')), sub: '000000000000000000000000' })).toString('base64url');
    await api().get('/v1/me').set({ Authorization: `Bearer ${h}.${forged}.${s}` }).expect(401);
    const none = `${Buffer.from('{"alg":"none","typ":"JWT"}').toString('base64url')}.${p}.`;
    await api().get('/v1/me').set({ Authorization: `Bearer ${none}` }).expect(401);
  });

  it('lists and revokes other sessions', async () => {
    const ctx = await createUser({ pin: null });
    const other = await api().post('/v1/auth/login').send({ phone: ctx.phone, password: ctx.password, device: ctx.device }).expect(200);
    const list = await api().get('/v1/me/sessions').set(ctx.auth()).expect(200);
    expect(list.body.items.length).toBe(2);
    await api().delete(`/v1/me/sessions/${other.body.tokens.sessionId}`).set(ctx.auth()).expect(204);
    await api().get('/v1/me').set({ Authorization: `Bearer ${other.body.tokens.accessToken}` }).expect(401);
  });
});

describe('password recovery', () => {
  it('resets password with OTP, revokes sessions and untrusts devices', async () => {
    const ctx = await createUser({ pin: null });
    await api().post('/v1/auth/password/forgot').send({ phone: ctx.phone }).expect(202);
    await api().post('/v1/auth/password/reset').send({ phone: ctx.phone, code: latestOtp(ctx.phone), newPassword: 'N3wSecurePass' }).expect(200);
    await api().get('/v1/me').set(ctx.auth()).expect(401);
    const res = await api().post('/v1/auth/login').send({ phone: ctx.phone, password: 'N3wSecurePass', device: ctx.device }).expect(200);
    expect(res.body.next).toBe('VERIFY_DEVICE');
  });

  it('forgot-password responds identically for unknown numbers', async () => {
    const res = await api().post('/v1/auth/password/forgot').send({ phone: kenyanPhone() }).expect(202);
    expect(res.body.status).toBe('OTP_SENT');
  });
});

describe('transaction PIN', () => {
  it('rejects trivial PINs', async () => {
    const ctx = await createUser({ pin: null });
    await api().post('/v1/auth/pin').set(ctx.auth()).send({ pin: '1234' }).expect(422);
  });

  it('verifies and locks after repeated failures', async () => {
    const ctx = await createUser();
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: ctx.pin }).expect(200);
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: '9753' }).expect(422);
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: '9753' }).expect(422);
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: '9753' }).expect(423);
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: ctx.pin }).expect(423);
    // Reset with OTP + password unlocks.
    await api().post('/v1/auth/pin/reset/request').set(ctx.auth()).expect(202);
    await api().post('/v1/auth/pin/reset').set(ctx.auth()).send({ code: latestOtp(ctx.phone), password: ctx.password, newPin: '8642' }).expect(200);
    await api().post('/v1/auth/pin/verify').set(ctx.auth()).send({ pin: '8642' }).expect(200);
  });
});

describe('email verification', () => {
  it('verifies an email with an OTP', async () => {
    const ctx = await createUser({ pin: null });
    const email = `user${Date.now()}@example.com`;
    await api().post('/v1/auth/email/request').set(ctx.auth()).send({ email }).expect(202);
    const code = readOutbox(email)[0].message.match(/\d{6}/)[0];
    const res = await api().post('/v1/auth/email/verify').set(ctx.auth()).send({ code }).expect(200);
    expect(res.body.user.emailVerified).toBe(true);
  });
});

describe('security hardening', () => {
  it('strips NoSQL operators from input', async () => {
    const res = await api().post('/v1/auth/login').send({ phone: { $gt: '' }, password: { $ne: null }, device: device() });
    expect(res.status).toBe(422);
  });

  it('rate limits login attempts per IP', async () => {
    const ip = '203.0.113.9';
    let limited;
    for (let i = 0; i < 35; i++) {
      const res = await api(ip).post('/v1/auth/login').send({ phone: kenyanPhone(), password: 'Wrong12345', device: device() });
      if (res.status === 429) { limited = res; break; }
    }
    expect(limited).toBeTruthy();
    expect(Number(limited.headers['retry-after'])).toBeGreaterThan(0);
  });

  it('sets secure headers and a request id', async () => {
    const res = await api().get('/health/live').expect(200);
    expect(res.headers['x-request-id']).toBeTruthy();
    expect(res.headers['strict-transport-security']).toContain('max-age');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});
