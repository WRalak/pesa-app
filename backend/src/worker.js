import { initTelemetry } from './lib/telemetry.js';
await initTelemetry('pesa-worker');

const { Worker } = await import('bullmq');
const { config } = await import('./config/env.js');
const { logger } = await import('./lib/logger.js');
const { connectDb, disconnectDb } = await import('./lib/db.js');
const { createRedisConnection, closeRedis } = await import('./lib/redis.js');
const { QUEUES, getQueue, closeQueues } = await import('./lib/queue.js');
await import('./modules/subscribers.js');
const { deliverPush } = await import('./modules/notifications/service.js');
const { checkTransactionStatus, sweepPending, deliverMockCallback, retryOrphanedCallback } = await import('./modules/payments/service.js');
const { reconcileRecent } = await import('./modules/payments/reconciliation.js');
const { sendDueReminders } = await import('./modules/savings/service.js');
const { runRecurring } = await import('./modules/budgets/service.js');
const { releaseHeldCashback } = await import('./modules/rewards/service.js');
const { sendNotificationCampaign } = await import('./modules/admin/campaign-jobs.js');

/**
 * Background worker — a separate, horizontally scalable process. All jobs are
 * idempotent so BullMQ retries and duplicate schedules are safe.
 */
const handlers = {
  [QUEUES.notifications]: {
    push: (job) => deliverPush(job.data),
    campaign: (job) => sendNotificationCampaign(job.data),
  },
  [QUEUES.payments]: {
    'confirm-status': (job) => checkTransactionStatus(job.data.transactionId),
    'sweep-pending': () => sweepPending(),
    'mock-callback': (job) => deliverMockCallback(job.data),
    'retry-orphaned-callback': (job) => retryOrphanedCallback(job.data),
  },
  [QUEUES.reconciliation]: { 'daily-reconciliation': () => reconcileRecent() },
  [QUEUES.reminders]: {
    'savings-reminders': () => sendDueReminders(),
    'recurring-entries': () => runRecurring(),
    'release-cashback': () => releaseHeldCashback(),
  },
};

const SCHEDULES = [
  [QUEUES.payments, 'sweep-pending', { every: 60_000 }],
  [QUEUES.reminders, 'savings-reminders', { every: 15 * 60_000 }],
  [QUEUES.reminders, 'recurring-entries', { every: 15 * 60_000 }],
  [QUEUES.reminders, 'release-cashback', { every: 60 * 60_000 }],
  [QUEUES.reconciliation, 'daily-reconciliation', { pattern: '30 1 * * *', tz: 'Africa/Nairobi' }],
];

await connectDb();
const workers = Object.entries(handlers).map(([queue, jobs]) => {
  const w = new Worker(queue, async (job) => {
    const fn = jobs[job.name];
    if (!fn) throw new Error(`No handler for ${queue}:${job.name}`);
    return fn(job);
  }, { connection: createRedisConnection(), concurrency: queue === QUEUES.notifications ? 20 : 5 });
  w.on('failed', (job, err) => logger.error({ queue, job: job?.name, attempts: job?.attemptsMade, err: err.message }, 'Job failed'));
  return w;
});

for (const [queue, name, repeat] of SCHEDULES) {
  await getQueue(queue).upsertJobScheduler(`sched:${name}`, repeat, { name });
}
logger.info({ queues: Object.keys(handlers), env: config.NODE_ENV }, 'Pesa worker started');

async function shutdown() {
  logger.info('Worker shutting down');
  await Promise.all(workers.map((w) => w.close()));
  await closeQueues();
  await disconnectDb();
  await closeRedis();
  process.exit(0);
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
