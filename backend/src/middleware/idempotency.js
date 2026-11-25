import mongoose from 'mongoose';
import { Errors } from '../lib/errors.js';
import { sha256, canonical } from '../lib/index.js';
import { getRedis } from '../lib/redis.js';

const idempotencySchema = new mongoose.Schema({
  scope: { type: String, required: true },
  key: { type: String, required: true },
  requestHash: { type: String, required: true },
  status: { type: Number },
  body: { type: mongoose.Schema.Types.Mixed },
  createdAt: { type: Date, default: Date.now, expires: 60 * 60 * 24 },
}, { versionKey: false });
idempotencySchema.index({ scope: 1, key: 1 }, { unique: true });
export const IdempotencyKey = mongoose.model('IdempotencyKey', idempotencySchema);

/**
 * Enforces Idempotency-Key semantics for state-changing financial endpoints:
 *  - same key + same payload  -> replay the original response
 *  - same key + other payload -> 422
 *  - concurrent duplicate     -> 409 while the first request is in flight
 */
export function idempotent({ required = true } = {}) {
  return async (req, res, next) => {
    const key = req.get('idempotency-key');
    if (!key) return required ? next(Errors.badRequest('Idempotency-Key header is required')) : next();
    if (!/^[\w-]{8,128}$/.test(key)) return next(Errors.badRequest('Invalid Idempotency-Key'));
    const scope = `${req.user?.id ?? req.admin?.id ?? 'anon'}:${req.method}:${req.baseUrl}${req.route?.path ?? req.path}`;
    const requestHash = sha256(canonical(req.body ?? {}));

    const existing = await IdempotencyKey.findOne({ scope, key }).lean();
    if (existing) {
      if (existing.requestHash !== requestHash) return next(Errors.unprocessable('IDEMPOTENCY_MISMATCH', 'Idempotency-Key was reused with a different request'));
      if (existing.status) {
        res.setHeader('Idempotent-Replayed', 'true');
        return res.status(existing.status).json(existing.body);
      }
    }
    const lockKey = `idem-lock:${scope}:${key}`;
    const locked = await getRedis().set(lockKey, '1', 'EX', 60, 'NX');
    if (!locked) return next(Errors.conflict('A request with this Idempotency-Key is already being processed', 'IDEMPOTENCY_IN_PROGRESS'));

    const originalJson = res.json.bind(res);
    res.json = (body) => {
      if (res.statusCode < 500) {
        IdempotencyKey.updateOne({ scope, key }, { $set: { requestHash, status: res.statusCode, body } }, { upsert: true })
          .catch(() => {})
          .finally(() => getRedis().del(lockKey).catch(() => {}));
      } else {
        getRedis().del(lockKey).catch(() => {});
      }
      return originalJson(body);
    };
    res.on('close', () => { if (!res.writableFinished) getRedis().del(lockKey).catch(() => {}); });
    next();
  };
}
