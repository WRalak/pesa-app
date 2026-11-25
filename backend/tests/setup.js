import { beforeAll, afterAll } from 'vitest';
import mongoose from 'mongoose';
import { getRedis, closeRedis } from '../src/lib/redis.js';
import { clearOutbox } from '../src/modules/messaging/service.js';
import '../src/modules/subscribers.js';

beforeAll(async () => {
  if (mongoose.connection.readyState !== 1) await mongoose.connect(process.env.MONGODB_URI, { autoIndex: false, autoCreate: false });
  await mongoose.connection.db.dropDatabase();
  // Collections must exist before multi-document transactions touch them.
  for (const m of Object.values(mongoose.models)) {
    await m.createCollection().catch(() => {});
    await m.createIndexes();
  }
  await getRedis().flushdb();
  clearOutbox();
});

afterAll(async () => {
  await mongoose.disconnect();
  await closeRedis();
});
