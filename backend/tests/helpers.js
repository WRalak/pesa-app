import request from 'supertest';
import crypto from 'node:crypto';
import { createApp } from '../src/app.js';
import { readOutbox } from '../src/modules/messaging/service.js';

export const app = createApp();
let ipCounter = 0;
/** Each call simulates a distinct client IP so per-IP limits don't interfere across tests. */
export const randomIp = () => { ipCounter += 1; return `10.${(ipCounter >> 16) & 255}.${(ipCounter >> 8) & 255}.${ipCounter & 255}`; };
export function api(ip = randomIp()) {
  const agent = request(app);
  const wrap = (method) => (url) => agent[method](url).set('X-Forwarded-For', ip);
  return { get: wrap('get'), post: wrap('post'), put: wrap('put'), patch: wrap('patch'), delete: wrap('delete') };
}

let counter = 0;
/** Generates a unique valid Safaricom-range Kenyan mobile number. */
export function kenyanPhone() {
  counter += 1;
  const n = (Date.now() % 1_000_000 + counter * 7919) % 10_000_000;
  return `+2547${String(10 + (n % 90)).padStart(2, '0')}${String(n).padStart(7, '0').slice(-6)}`;
}

export function device(overrides = {}) {
  return { deviceId: crypto.randomUUID(), name: 'Test Phone', platform: 'android', model: 'Pixel', osVersion: '15', appVersion: '1.0.0', ...overrides };
}

export function latestOtp(to) {
  const msg = readOutbox(to).find((m) => /\d{6}/.test(m.message));
  return msg?.message.match(/\d{6}/)[0];
}

/** Registers, verifies and returns an authenticated user context. */
export async function createUser({ pin = '2580', password = 'Str0ngPass!', ...rest } = {}) {
  const phone = rest.phone ?? kenyanPhone();
  const dev = device();
  await api().post('/v1/auth/register').send({ phone, password, firstName: 'Amani', lastName: 'Otieno', acceptTerms: true, ...rest.body }).expect(202);
  const res = await api().post('/v1/auth/verify-phone').send({ phone, code: latestOtp(phone), device: dev }).expect(200);
  const ctx = { phone, password, device: dev, user: res.body.user, tokens: res.body.tokens };
  ctx.auth = () => ({ Authorization: `Bearer ${ctx.tokens.accessToken}`, 'X-Device-Id': dev.deviceId });
  if (pin) {
    await api().post('/v1/auth/pin').set(ctx.auth()).send({ pin }).expect(201);
    ctx.pin = pin;
  }
  return ctx;
}

export const idemKey = () => `test-${crypto.randomUUID()}`;
