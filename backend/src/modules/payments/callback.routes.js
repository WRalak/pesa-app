import { Router } from 'express';
import { processCallback } from './service.js';
import { rateLimit } from '../../middleware/rate-limit.js';
import { logger } from '../../lib/logger.js';
import { config } from '../../config/env.js';

/**
 * Provider webhooks. Unauthenticated by bearer token — authenticity is
 * established per provider (HMAC signature, secret path token, IP allow-list,
 * confirmation query). Responses are minimal and never echo internal data.
 */
const router = Router();
const limiter = rateLimit({ name: 'callbacks', points: 600, duration: 60 });

router.post('/mock', limiter, async (req, res, next) => {
  if (!config.paymentProviders.includes('mock')) return res.status(404).end();
  try {
    const out = await processCallback('mock', req);
    res.json(out.ack);
  } catch (err) {
    next(err);
  }
});

router.post('/daraja/:token/:kind', limiter, async (req, res) => {
  try {
    const out = await processCallback('daraja', req);
    res.json(out.ack);
  } catch (err) {
    // Safaricom retries on non-2xx. Rejected callbacks get 403; transient errors 500 to trigger retry.
    if (err.code === 'CALLBACK_REJECTED') return res.status(403).json({ ResultCode: 1, ResultDesc: 'Rejected' });
    logger.error({ err: err.message }, 'Daraja callback processing error');
    res.status(500).json({ ResultCode: 1, ResultDesc: 'Retry' });
  }
});

export default router;
