import mongoose from 'mongoose';
import { config } from '../config/env.js';
import { logger } from './logger.js';

mongoose.set('strictQuery', true);

export async function connectDb(uri = config.MONGODB_URI) {
  await mongoose.connect(uri, {
    maxPoolSize: config.MONGODB_MAX_POOL,
    minPoolSize: 2,
    serverSelectionTimeoutMS: 10_000,
    retryWrites: true,
    w: 'majority',
    autoIndex: !config.isProd, // production indexes are built by the migration step
  });
  logger.info({ host: mongoose.connection.host }, 'MongoDB connected');
  return mongoose.connection;
}

export async function disconnectDb() {
  await mongoose.disconnect();
}

/** Run `fn` inside a multi-document ACID transaction (requires a replica set). */
export async function withTransaction(fn) {
  const session = await mongoose.startSession();
  try {
    let result;
    await session.withTransaction(async () => {
      result = await fn(session);
    }, { readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } });
    return result;
  } finally {
    await session.endSession();
  }
}
