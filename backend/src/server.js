import { initTelemetry } from './lib/telemetry.js';
await initTelemetry('pesa-api');

const http = await import('node:http');
const { Server } = await import('socket.io');
const { createAdapter } = await import('@socket.io/redis-adapter');
const jwt = (await import('jsonwebtoken')).default;
const { config } = await import('./config/env.js');
const { logger } = await import('./lib/logger.js');
const { connectDb, disconnectDb } = await import('./lib/db.js');
const { getRedis, createRedisConnection, closeRedis } = await import('./lib/redis.js');
const { setIo } = await import('./lib/realtime.js');
const { createApp } = await import('./app.js');
const { closeQueues } = await import('./lib/queue.js');
await import('./modules/subscribers.js');

await connectDb();
getRedis();

const app = createApp();
const server = http.createServer(app);
server.keepAliveTimeout = 65_000; // > ALB idle timeout
server.headersTimeout = 66_000;
server.requestTimeout = 60_000; // slow-request (slowloris) protection; statements stream within this
server.maxRequestsPerSocket = 1000;

const io = new Server(server, {
  path: '/realtime',
  cors: { origin: config.corsOrigins },
  adapter: createAdapter(createRedisConnection(), createRedisConnection()),
  serveClient: false,
});
io.use((socket, next) => {
  try {
    const token = socket.handshake.auth?.token;
    const payload = jwt.verify(token, config.JWT_ACCESS_SECRET, { issuer: config.JWT_ISSUER, audience: 'pesa-app', algorithms: ['HS256'] });
    socket.data.userId = payload.sub;
    next();
  } catch {
    next(new Error('unauthorized'));
  }
});
io.on('connection', (socket) => socket.join(`user:${socket.data.userId}`));
setIo(io);

server.listen(config.PORT, () => logger.info({ port: config.PORT, env: config.NODE_ENV }, 'Pesa API listening'));

let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info({ signal }, 'Graceful shutdown started');
  const force = setTimeout(() => process.exit(1), 25_000);
  force.unref();
  io.close();
  server.close(async () => {
    await closeQueues();
    await disconnectDb();
    await closeRedis();
    logger.info('Shutdown complete');
    process.exit(0);
  });
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (err) => logger.error({ err }, 'Unhandled rejection'));
