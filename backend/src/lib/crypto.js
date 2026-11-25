import crypto from 'node:crypto';
import argon2 from 'argon2';
import { config } from '../config/env.js';

/**
 * Argon2id parameters follow OWASP Password Storage Cheat Sheet guidance
 * (m=19 MiB, t=2, p=1 minimum). Tests use cheaper parameters for speed.
 */
const ARGON_OPTS = config.isTest
  ? { type: argon2.argon2id, memoryCost: 1024, timeCost: 1, parallelism: 1 }
  : { type: argon2.argon2id, memoryCost: 19_456, timeCost: 2, parallelism: 1 };

export const hashSecret = (plain) => argon2.hash(plain, ARGON_OPTS);
export const verifySecret = async (hash, plain) => {
  if (!hash || typeof plain !== 'string') return false;
  try {
    return await argon2.verify(hash, plain);
  } catch {
    return false;
  }
};

/** Keyed hash for values we must look up but never store in plaintext (OTPs, refresh tokens). */
export function hmac(value, key = config.HASH_PEPPER) {
  return crypto.createHmac('sha256', key).update(String(value)).digest('hex');
}

export function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

export function randomToken(bytes = 32) {
  return crypto.randomBytes(bytes).toString('base64url');
}

/** Uniformly distributed numeric code (no modulo bias). */
export function randomDigits(length = 6) {
  let out = '';
  for (let i = 0; i < length; i++) out += crypto.randomInt(0, 10).toString();
  return out;
}

export function timingSafeEqualStr(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  if (ab.length !== bb.length) return false;
  return crypto.timingSafeEqual(ab, bb);
}

// ---- AES-256-GCM field-level encryption for sensitive values at rest ----
const KEY = Buffer.from(config.FIELD_ENCRYPTION_KEY, 'base64');
if (KEY.length !== 32) throw new Error('FIELD_ENCRYPTION_KEY must decode to 32 bytes');
const KEY_VERSION = 'v1';

export function encryptField(plain) {
  if (plain == null) return plain;
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', KEY, iv);
  const enc = Buffer.concat([cipher.update(String(plain), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${KEY_VERSION}:${iv.toString('base64')}:${tag.toString('base64')}:${enc.toString('base64')}`;
}

export function decryptField(payload) {
  if (payload == null) return payload;
  const [ver, iv, tag, data] = String(payload).split(':');
  if (ver !== KEY_VERSION) throw new Error('Unknown encryption key version');
  const decipher = crypto.createDecipheriv('aes-256-gcm', KEY, Buffer.from(iv, 'base64'));
  decipher.setAuthTag(Buffer.from(tag, 'base64'));
  return Buffer.concat([decipher.update(Buffer.from(data, 'base64')), decipher.final()]).toString('utf8');
}

/** Mask all but the last `visible` characters: "0712345678" -> "******5678". */
export function mask(value, visible = 4) {
  if (!value) return value;
  const s = String(value);
  return s.length <= visible ? '*'.repeat(s.length) : '*'.repeat(s.length - visible) + s.slice(-visible);
}
