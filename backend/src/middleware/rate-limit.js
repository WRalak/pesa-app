import { RateLimiterRedis, RateLimiterMemory } from 'rate-limiter-flexible';
import { getRedis } from '../lib/redis.js';
import { Errors } from '../lib/errors.js';

const limiters = new Map();

function limiter(name, points, duration, blockDuration = 0) {
  const key = `${name}:${points}:${duration}`;
  if (!limiters.has(key)) {
    const insurance = new RateLimiterMemory({ points, duration });
    limiters.set(key, new RateLimiterRedis({
      storeClient: getRedis(),
      keyPrefix: `rl:${name}`,
      points,
      duration,
      blockDuration,
      insuranceLimiter: insurance, // keep protecting if Redis is briefly unavailable
    }));
  }
  return limiters.get(key);
}

/**
 * Express middleware. `keyFn` picks the identity being limited (IP, user, phone).
 * Limits are deliberately per-identity so a single abusive client cannot
 * exhaust a shared budget.
 */
export function rateLimit({ name, points, duration, blockDuration, keyFn = (req) => req.ip }) {
  return async (req, res, next) => {
    const id = keyFn(req);
    if (!id) return next();
    try {
      const r = await limiter(name, points, duration, blockDuration).consume(String(id));
      res.setHeader('RateLimit-Remaining', String(r.remainingPoints));
      next();
    } catch (rej) {
      if (rej instanceof Error) return next(rej);
      next(Errors.tooMany('Too many requests. Please slow down.', Math.ceil(rej.msBeforeNext / 1000)));
    }
  };
}

export async function consumeOrThrow({ name, points, duration, blockDuration }, id) {
  try {
    await limiter(name, points, duration, blockDuration).consume(String(id));
  } catch (rej) {
    if (rej instanceof Error) throw rej;
    throw Errors.tooMany('Too many attempts. Please try again later.', Math.ceil(rej.msBeforeNext / 1000));
  }
}

export const globalLimiter = rateLimit({ name: 'global', points: 300, duration: 60 });
