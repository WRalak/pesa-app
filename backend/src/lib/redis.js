import Redis from 'ioredis';
import { config } from '../config/env.js';
import { logger } from './logger.js';

let client;

export function getRedis() {
  if (!client) {
    client = new Redis(config.REDIS_URL, { maxRetriesPerRequest: null, enableReadyCheck: true, lazyConnect: false });
    client.on('error', (err) => logger.error({ err: err.message }, 'Redis error'));
  }
  return client;
}

/** Dedicated connection (BullMQ workers and pub/sub need their own). */
export function createRedisConnection() {
  return new Redis(config.REDIS_URL, { maxRetriesPerRequest: null });
}

export async function closeRedis() {
  if (client) {
    await client.quit().catch(() => {});
    client = undefined;
  }
}

/** Read-through cache helper with JSON serialisation. */
export async function cached(key, ttlSeconds, loader) {
  const redis = getRedis();
  const hit = await redis.get(key);
  if (hit) return JSON.parse(hit);
  const value = await loader();
  await redis.set(key, JSON.stringify(value), 'EX', ttlSeconds);
  return value;
}

export async function invalidate(...keys) {
  if (keys.length) await getRedis().del(...keys);
}
