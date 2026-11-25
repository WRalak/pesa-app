import { Router } from 'express';
import mongoose from 'mongoose';
import { getRedis } from '../../lib/redis.js';
import { registry } from '../../lib/metrics.js';
import { config } from '../../config/env.js';
import { timingSafeEqualStr } from '../../lib/crypto.js';

const router = Router();

/** Liveness: the process is up. Never touches dependencies. */
router.get('/health/live', (_req, res) => res.json({ status: 'ok' }));

/** Readiness: dependencies reachable; load balancers stop routing on failure. */
router.get('/health/ready', async (_req, res) => {
  const checks = { mongo: mongoose.connection.readyState === 1 ? 'ok' : 'down', redis: 'down' };
  try {
    checks.redis = (await getRedis().ping()) === 'PONG' ? 'ok' : 'down';
  } catch { /* reported as down */ }
  const ok = Object.values(checks).every((v) => v === 'ok');
  res.status(ok ? 200 : 503).json({ status: ok ? 'ok' : 'degraded', checks, version: process.env.APP_VERSION ?? 'dev' });
});

router.get('/metrics', async (req, res) => {
  if (config.METRICS_TOKEN) {
    const token = (req.get('authorization') ?? '').replace(/^Bearer /, '');
    if (!timingSafeEqualStr(token, config.METRICS_TOKEN)) return res.status(401).end();
  } else if (config.isDeployed) {
    return res.status(404).end();
  }
  res.setHeader('Content-Type', registry.contentType);
  res.send(await registry.metrics());
});

export default router;
