import { createRouter, idParams, pageQuery, amountString } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as budgets from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';

const r = createRouter({ prefix: '/v1/budgets', tags: ['Budgets'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];
const catLimit = z.object({ category: z.string().max(40), limit: amountString });
const thresholds = z.array(z.number().int().min(10).max(150)).min(1).max(4);

r.route({ method: 'get', path: '/categories', summary: 'Expense and income categories', middleware: authed, handler: () => budgets.categories() });
r.route({ method: 'get', path: '/', summary: 'Active budgets with live progress', middleware: authed, handler: (req) => budgets.listBudgets(req.userDoc) });
r.route({
  method: 'post', path: '/', summary: 'Create a weekly or monthly budget', status: 201, middleware: authed,
  body: z.object({ name: z.string().trim().min(1).max(60), period: z.enum(['WEEKLY', 'MONTHLY']), totalLimit: amountString.optional(), categories: z.array(catLimit).max(15).optional(), alertThresholds: thresholds.optional() }),
  handler: (req) => budgets.createBudget(req.userDoc, req.body),
});
r.route({
  method: 'patch', path: '/:id', summary: 'Edit a budget', params: idParams, middleware: authed,
  body: z.object({ name: z.string().trim().min(1).max(60).optional(), totalLimit: amountString.nullable().optional(), categories: z.array(catLimit).max(15).optional(), alertThresholds: thresholds.optional() }),
  handler: (req) => budgets.updateBudget(req.userDoc, req.valid.params.id, req.body),
});
r.route({ method: 'delete', path: '/:id', summary: 'Delete a budget', params: idParams, middleware: authed, handler: (req) => budgets.deleteBudget(req.user.id, req.valid.params.id) });

const entryBody = z.object({ amount: amountString, category: z.string().max(40), description: z.string().trim().max(140).optional(), date: z.coerce.date().max(new Date(Date.now() + 86_400_000)).optional() });
for (const [path, kind] of [['expenses', 'EXPENSE'], ['income', 'INCOME']]) {
  const body = kind === 'EXPENSE' ? entryBody.extend({ paymentMethod: z.enum(['CASH', 'MOBILE_MONEY', 'CARD', 'BANK', 'OTHER']).optional() }) : entryBody;
  r.route({ method: 'get', path: `/${path}`, summary: `List manual ${path}`, query: pageQuery.extend({ category: z.string().max(40).optional() }), middleware: authed, handler: (req) => budgets.listEntries(req.userDoc, kind, req.valid.query) });
  r.route({ method: 'post', path: `/${path}`, summary: `Record ${kind === 'EXPENSE' ? 'an expense' : 'income'}`, status: 201, middleware: authed, body, handler: (req) => budgets.addEntry(req.userDoc, kind, req.body) });
  r.route({ method: 'patch', path: `/${path}/:id`, summary: `Edit ${path} entry`, params: idParams, middleware: authed, body: body.partial(), handler: (req) => budgets.updateEntry(req.userDoc, kind, req.valid.params.id, req.body) });
  r.route({ method: 'delete', path: `/${path}/:id`, summary: `Delete ${path} entry`, params: idParams, middleware: authed, handler: (req) => budgets.deleteEntry(req.userDoc, kind, req.valid.params.id) });
}

r.route({ method: 'get', path: '/recurring', summary: 'Recurring expenses and income', middleware: authed, handler: (req) => budgets.listRecurring(req.userDoc) });
r.route({
  method: 'post', path: '/recurring', summary: 'Create a recurring expense or income', status: 201, middleware: authed,
  body: z.object({ kind: z.enum(['EXPENSE', 'INCOME']), amount: amountString, category: z.string().max(40), description: z.string().trim().max(140).optional(), frequency: z.enum(['WEEKLY', 'MONTHLY']), startDate: z.coerce.date().optional() }),
  handler: (req) => budgets.createRecurring(req.userDoc, req.body),
});
r.route({ method: 'delete', path: '/recurring/:id', summary: 'Stop a recurring item', params: idParams, middleware: authed, handler: (req) => budgets.stopRecurring(req.userDoc, req.valid.params.id) });

export default r.router;
