import { Queue } from 'bullmq';
import { createRedisConnection } from './redis.js';
import { config } from '../config/env.js';
import { logger } from './logger.js';

/**
 * Named queues. Producers call `enqueue`; consumers are registered in
 * src/worker.js which runs as a separate, independently scalable process.
 * In tests (JOBS_INLINE) jobs run synchronously in-process.
 */
export const QUEUES = {
  notifications: 'notifications',
  payments: 'payments',
  reconciliation: 'reconciliation',
  insights: 'insights',
  reminders: 'reminders',
  statements: 'statements',
};

const queues = new Map();
const inlineHandlers = new Map();
let connection;

export function getQueue(name) {
  if (!queues.has(name)) {
    connection ??= createRedisConnection();
    queues.set(name, new Queue(name, {
      connection,
      defaultJobOptions: {
        attempts: 5,
        backoff: { type: 'exponential', delay: 2000 },
        removeOnComplete: { age: 3600, count: 10_000 },
        removeOnFail: { age: 7 * 24 * 3600 },
      },
    }));
  }
  return queues.get(name);
}

export function registerInlineHandler(queue, jobName, fn) {
  inlineHandlers.set(`${queue}:${jobName}`, fn);
}

export async function enqueue(queue, jobName, data, opts = {}) {
  if (config.JOBS_INLINE) {
    const fn = inlineHandlers.get(`${queue}:${jobName}`);
    if (fn) {
      try {
        await fn({ name: jobName, data });
      } catch (err) {
        logger.warn({ err: err.message, queue, jobName }, 'Inline job failed');
      }
    }
    return null;
  }
  return getQueue(queue).add(jobName, data, opts);
}

export async function closeQueues() {
  await Promise.all([...queues.values()].map((q) => q.close().catch(() => {})));
  queues.clear();
  if (connection) await connection.quit().catch(() => {});
  connection = undefined;
}
