import { createRouter } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as analytics from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';

const r = createRouter({ prefix: '/v1/analytics', tags: ['Analytics'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

r.route({
  method: 'get', path: '/summary', summary: 'Income, spending and category breakdown for a week or month', middleware: authed,
  query: z.object({ period: z.enum(['WEEKLY', 'MONTHLY']).default('MONTHLY'), date: z.coerce.date().optional() }),
  handler: (req) => analytics.periodSummary(req.userDoc, req.valid.query),
});
r.route({
  method: 'get', path: '/trends', summary: 'Monthly income vs expenses', middleware: authed,
  query: z.object({ months: z.coerce.number().int().min(1).max(12).default(6) }),
  handler: (req) => analytics.monthlyTrends(req.userDoc, req.valid.query.months),
});

export default r.router;
