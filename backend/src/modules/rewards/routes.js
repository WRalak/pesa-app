import { createRouter, pageQuery } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as rewards from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';

const r = createRouter({ prefix: '/v1/rewards', tags: ['Rewards'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

r.route({ method: 'get', path: '/', summary: 'Rewards dashboard: points, cashback, offers, referral code', middleware: authed, handler: (req) => rewards.rewardsDashboard(req.userDoc) });
r.route({ method: 'get', path: '/history', summary: 'Reward ledger history', query: pageQuery, middleware: authed, handler: (req) => rewards.rewardHistory(req.user.id, req.valid.query) });
r.route({
  method: 'post', path: '/redeem', summary: 'Redeem points', middleware: [...authed, rateLimit({ name: 'redeem', points: 10, duration: 3600, keyFn: (req) => req.user.id })],
  body: z.object({ reward: z.enum(['AIRTIME_50', 'AIRTIME_100', 'DATA_1GB']), points: z.number().int().positive() }),
  handler: (req) => rewards.redeemPoints(req.userDoc, req.body),
});

export default r.router;
