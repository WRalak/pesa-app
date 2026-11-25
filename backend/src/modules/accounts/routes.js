import { createRouter, idParams, amountString } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as accounts from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';

const r = createRouter({ prefix: '/v1/accounts', tags: ['Linked accounts'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

r.route({ method: 'get', path: '/', summary: 'Linked and manual accounts with balance provenance', middleware: authed, handler: async (req) => ({ items: await accounts.listAccounts(req.user.id) }) });
r.route({ method: 'get', path: '/institutions', summary: 'Institutions available for linking', middleware: authed, handler: () => ({ items: accounts.institutions() }) });
r.route({
  method: 'post', path: '/link', summary: 'Link an account through an aggregator', status: 201, middleware: authed,
  body: z.object({ institution: z.string().max(40) }),
  handler: (req) => accounts.linkAccount(req.userDoc, req.body, req),
});
r.route({
  method: 'post', path: '/manual', summary: 'Track an account manually (balance is user-entered)', status: 201, middleware: authed,
  body: z.object({ kind: z.enum(['MOBILE_MONEY', 'BANK', 'CASH', 'SACCO', 'OTHER']), displayName: z.string().trim().min(1).max(60), balance: amountString.optional() }),
  handler: (req) => accounts.addManualAccount(req.userDoc, req.body),
});
r.route({
  method: 'patch', path: '/:id', summary: 'Rename, set default, or update a manual balance', params: idParams, middleware: authed,
  body: z.object({ displayName: z.string().trim().min(1).max(60).optional(), balance: amountString.optional(), isDefault: z.literal(true).optional() }),
  handler: (req) => accounts.updateAccount(req.userDoc, req.valid.params.id, req.body),
});
r.route({
  method: 'post', path: '/:id/refresh', summary: 'Refresh balance from provider', params: idParams,
  middleware: [...authed, rateLimit({ name: 'balance-refresh', points: 20, duration: 3600, keyFn: (req) => req.user.id })],
  handler: (req) => accounts.refreshBalance(req.userDoc, req.valid.params.id),
});
r.route({ method: 'delete', path: '/:id', summary: 'Unlink an account', params: idParams, middleware: authed, handler: (req) => accounts.unlinkAccount(req.userDoc, req.valid.params.id, req) });

export default r.router;
