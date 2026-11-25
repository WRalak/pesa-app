import { createRouter, idParams, amountString } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as txs from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';
import { TX_STATUSES, TX_TYPES } from '../payments/models.js';

const r = createRouter({ prefix: '/v1/transactions', tags: ['Transactions'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

const csvEnum = (values) => z.string().max(200).refine((s) => s.split(',').every((v) => values.includes(v)), `Allowed: ${values.join(', ')}`);

r.route({
  method: 'get', path: '/', summary: 'List transactions with filters (cursor-paginated)', middleware: authed,
  query: z.object({
    cursor: z.string().max(200).optional(),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    status: csvEnum(TX_STATUSES).optional(),
    type: csvEnum(TX_TYPES).optional(),
    provider: z.string().max(30).optional(),
    direction: z.enum(['DEBIT', 'CREDIT']).optional(),
    category: z.string().max(40).optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional(),
    minAmount: amountString.optional(),
    maxAmount: amountString.optional(),
    q: z.string().trim().max(50).optional(),
  }),
  handler: (req) => txs.listTransactions(req.userDoc, req.valid.query),
});

r.route({
  method: 'get', path: '/statement', summary: 'Download a statement (CSV or PDF, streamed)',
  middleware: [...authed, rateLimit({ name: 'statement', points: 10, duration: 3600, keyFn: (req) => req.user.id })],
  query: z.object({ from: z.coerce.date(), to: z.coerce.date(), format: z.enum(['csv', 'pdf']).default('pdf') }),
  handler: (req, res) => txs.streamStatement(req.userDoc, req.valid.query, res),
});

r.route({ method: 'get', path: '/:id', summary: 'Transaction detail with status timeline', params: idParams, middleware: authed, handler: (req) => txs.getTransaction(req.user.id, req.valid.params.id) });
r.route({ method: 'get', path: '/:id/receipt', summary: 'Receipt for a completed transaction', params: idParams, middleware: authed, handler: (req) => txs.receipt(req.user.id, req.valid.params.id) });
r.route({
  method: 'patch', path: '/:id/category', summary: 'Re-categorise a transaction', params: idParams, middleware: authed,
  body: z.object({ category: z.string().max(40) }),
  handler: (req) => txs.setCategory(req.user.id, req.valid.params.id, req.body.category),
});

export default r.router;
