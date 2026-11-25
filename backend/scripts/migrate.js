/**
 * Release-time migration, run once per deploy as a one-off ECS task:
 *   1. builds every schema index (production runs with autoIndex disabled so
 *      index builds never happen implicitly under live traffic);
 *   2. runs the idempotent seed (RBAC, provider config, starter campaigns).
 * createIndexes() is non-destructive: it never drops indexes.
 */
import mongoose from 'mongoose';
import { connectDb } from '../src/lib/db.js';
import { logger } from '../src/lib/logger.js';
import '../src/modules/subscribers.js';
import '../src/middleware/idempotency.js';
import '../src/modules/admin/models.js';
import '../src/modules/cards/models.js';
import '../src/modules/support/models.js';

await connectDb();
for (const model of Object.values(mongoose.models)) {
  await model.createCollection().catch(() => {});
  await model.createIndexes();
  logger.info({ model: model.modelName }, 'Indexes ensured');
}
await mongoose.disconnect();
await import('./seed.js');
