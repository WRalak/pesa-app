import { createRouter, idParams, pageQuery, amountString } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as savings from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';

const r = createRouter({ prefix: '/v1/savings', tags: ['Savings goals'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];
const category = z.enum(['EMERGENCY', 'RENT', 'EDUCATION', 'BUSINESS', 'TRAVEL', 'ELECTRONICS', 'HOME', 'HEALTH', 'OTHER']);
const reminder = z.object({ frequency: z.enum(['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']), amount: amountString.optional() });

r.route({ method: 'get', path: '/goals', summary: 'List goals', query: z.object({ status: z.enum(['ACTIVE', 'COMPLETED', 'ARCHIVED']).optional() }), middleware: authed, handler: (req) => savings.listGoals(req.user.id, req.valid.query) });
r.route({ method: 'get', path: '/analytics', summary: 'Monthly savings series', query: z.object({ months: z.coerce.number().int().min(1).max(24).default(6) }), middleware: authed, handler: (req) => savings.savingsAnalytics(req.userDoc, req.valid.query.months) });
r.route({
  method: 'post', path: '/goals', summary: 'Create a savings goal', status: 201, middleware: authed,
  body: z.object({ name: z.string().trim().min(1).max(60), category: category.default('OTHER'), target: amountString, deadline: z.coerce.date().optional(), color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(), icon: z.string().max(40).optional(), reminder: reminder.optional() }),
  handler: (req) => savings.createGoal(req.userDoc, req.body),
});
r.route({ method: 'get', path: '/goals/:id', summary: 'Goal detail with analytics', params: idParams, middleware: authed, handler: (req) => savings.getGoal(req.user.id, req.valid.params.id) });
r.route({
  method: 'patch', path: '/goals/:id', summary: 'Edit a goal', params: idParams, middleware: authed,
  body: z.object({ name: z.string().trim().min(1).max(60).optional(), category: category.optional(), target: amountString.optional(), deadline: z.coerce.date().nullable().optional(), color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(), icon: z.string().max(40).optional(), reminder: reminder.optional() }),
  handler: (req) => savings.updateGoal(req.userDoc, req.valid.params.id, req.body),
});
r.route({ method: 'post', path: '/goals/:id/archive', summary: 'Archive a goal', params: idParams, middleware: authed, handler: (req) => savings.setArchived(req.user.id, req.valid.params.id, true) });
r.route({ method: 'post', path: '/goals/:id/restore', summary: 'Restore an archived goal', params: idParams, middleware: authed, handler: (req) => savings.setArchived(req.user.id, req.valid.params.id, false) });
r.route({
  method: 'post', path: '/goals/:id/contributions', summary: 'Record a contribution or withdrawal (tracking)', status: 201, params: idParams, middleware: authed,
  body: z.object({ kind: z.enum(['CONTRIBUTION', 'WITHDRAWAL']).default('CONTRIBUTION'), amount: amountString, note: z.string().trim().max(140).optional() }),
  handler: (req) => savings.addContribution(req.userDoc, req.valid.params.id, req.body),
});
r.route({ method: 'get', path: '/goals/:id/contributions', summary: 'Contribution history', params: idParams, query: pageQuery, middleware: authed, handler: (req) => savings.listContributions(req.user.id, req.valid.params.id, req.valid.query) });

export default r.router;
