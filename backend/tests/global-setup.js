import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { spawn } from 'node:child_process';
import net from 'node:net';

/**
 * Starts an in-memory MongoDB replica set (transactions need one) and, unless
 * REDIS_URL is provided (CI service container), a throwaway redis-server.
 * Set MONGOMS_SYSTEM_BINARY to use a locally installed mongod.
 */
let replSet;
let redisProc;

const freePort = () => new Promise((resolve) => {
  const srv = net.createServer();
  srv.listen(0, () => { const { port } = srv.address(); srv.close(() => resolve(port)); });
});

export async function setup() {
  replSet = await MongoMemoryReplSet.create({ replSet: { count: 1, storageEngine: 'wiredTiger' } });
  process.env.MONGODB_URI = replSet.getUri('pesa-test');

  if (!process.env.REDIS_URL) {
    const port = await freePort();
    redisProc = spawn('redis-server', ['--port', String(port), '--save', '', '--appendonly', 'no'], { stdio: 'ignore' });
    await new Promise((r) => setTimeout(r, 300));
    process.env.REDIS_URL = `redis://127.0.0.1:${port}/0`;
  }
}

export async function teardown() {
  await replSet?.stop();
  redisProc?.kill();
}
