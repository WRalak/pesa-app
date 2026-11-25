import { createRouter } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as insights from './service.js';
import { unusualTransactions, spendingPatterns } from './engine.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';

const r = createRouter({ prefix: '/v1/insights', tags: ['Insights'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

r.route({
  method: 'get', path: '/monthly-report', summary: 'Monthly report with insights and budgeting suggestions',
  description: 'Computed locally. If `narrative=true` and the user has consented to external AI processing, a narrative is generated from aggregated, de-identified totals only.',
  middleware: [...authed, rateLimit({ name: 'insights', points: 30, duration: 3600, keyFn: (req) => req.user.id })],
  query: z.object({ date: z.coerce.date().optional(), narrative: z.coerce.boolean().default(false) }),
  handler: (req) => insights.getMonthlyReport(req.userDoc, req.valid.query),
});
r.route({ method: 'get', path: '/unusual', summary: 'Unusually large transactions vs your typical spending', middleware: authed, handler: async (req) => ({ items: await unusualTransactions(req.userDoc) }) });
r.route({ method: 'get', path: '/patterns', summary: 'Spending by day of week', middleware: authed, handler: (req) => spendingPatterns(req.userDoc) });
r.route({ method: 'post', path: '/recategorize', summary: 'Auto-categorise uncategorised transactions (local rules)', middleware: authed, handler: (req) => insights.recategorize(req.userDoc) });

export default r.router;
