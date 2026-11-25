import { AuditLog, AuditChainHead, SecurityEvent } from './models.js';
import { chainHash } from '../../lib/audit-chain.js';
import { logger } from '../../lib/logger.js';
import { getRedis } from '../../lib/redis.js';

const SENSITIVE_KEYS = /pass|pin|otp|token|secret|cvv|card|idnumber|code/i;

function scrub(meta, depth = 0) {
  if (!meta || typeof meta !== 'object' || depth > 5) return meta;
  if (Array.isArray(meta)) return meta.map((m) => scrub(m, depth + 1));
  const out = {};
  for (const [k, v] of Object.entries(meta)) out[k] = SENSITIVE_KEYS.test(k) ? '[REDACTED]' : scrub(v, depth + 1);
  return out;
}

/**
 * Appends an entry to the hash-chained audit log. Serialised through a Redis
 * lock so the chain stays linear across horizontally-scaled API instances.
 */
export async function audit(entry, req) {
  const redis = getRedis();
  const lockKey = 'lock:audit-chain';
  for (let attempt = 0; attempt < 50; attempt++) {
    const token = `${process.pid}-${Date.now()}-${Math.random()}`;
    if (await redis.set(lockKey, token, 'PX', 5000, 'NX')) {
      try {
        const head = (await AuditChainHead.findById('audit').lean()) ?? { seq: 0, hash: null };
        const doc = {
          seq: head.seq + 1,
          actorType: entry.actorType,
          actorId: entry.actorId ? String(entry.actorId) : undefined,
          action: entry.action,
          resourceType: entry.resourceType,
          resourceId: entry.resourceId ? String(entry.resourceId) : undefined,
          outcome: entry.outcome ?? 'SUCCESS',
          ip: req?.ip,
          userAgent: req?.get?.('user-agent')?.slice(0, 300),
          requestId: req?.id,
          metadata: scrub(entry.metadata),
          prevHash: head.hash,
          createdAt: new Date(),
        };
        doc.hash = chainHash(head.hash, doc);
        await AuditLog.create(doc);
        await AuditChainHead.updateOne({ _id: 'audit' }, { $set: { seq: doc.seq, hash: doc.hash } }, { upsert: true });
        return doc;
      } finally {
        if ((await redis.get(lockKey)) === token) await redis.del(lockKey);
      }
    }
    await new Promise((r) => setTimeout(r, 20 + attempt * 5));
  }
  logger.error({ action: entry.action }, 'Could not acquire audit chain lock');
  throw new Error('Audit log unavailable');
}

export async function verifyAuditChain() {
  let prev = null;
  let count = 0;
  for await (const doc of AuditLog.find().sort({ seq: 1 }).lean().cursor()) {
    const { _id, hash, ...rest } = doc;
    const expected = chainHash(prev, { ...rest });
    if (doc.prevHash !== prev || expected !== hash) return { valid: false, brokenAt: doc.seq, checked: count };
    prev = hash;
    count++;
  }
  return { valid: true, checked: count };
}

export async function securityEvent(evt, req) {
  try {
    return await SecurityEvent.create({
      ...evt,
      details: scrub(evt.details),
      ip: evt.ip ?? req?.ip,
      userAgent: evt.userAgent ?? req?.get?.('user-agent')?.slice(0, 300),
      deviceId: evt.deviceId ?? req?.get?.('x-device-id'),
    });
  } catch (err) {
    logger.error({ err: err.message, type: evt.type }, 'Failed to record security event');
    return null;
  }
}
