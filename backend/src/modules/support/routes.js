import { createRouter, idParams, pageQuery, objectId } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as support from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { rateLimit } from '../../middleware/rate-limit.js';

const r = createRouter({ prefix: '/v1/support', tags: ['Support'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

r.route({
  method: 'post', path: '/tickets', summary: 'Open a support ticket', status: 201,
  middleware: [...authed, rateLimit({ name: 'ticket-create', points: 10, duration: 86_400, keyFn: (req) => req.user.id })],
  body: z.object({
    category: z.enum(['PAYMENT', 'ACCOUNT', 'KYC', 'CARD', 'SECURITY', 'FEEDBACK', 'OTHER']),
    subject: z.string().trim().min(3).max(140),
    message: z.string().trim().min(5).max(4000),
    transactionId: objectId.optional(),
  }),
  handler: (req) => support.createTicket(req.user.id, req.body),
});
r.route({ method: 'get', path: '/tickets', summary: 'My tickets', query: pageQuery, middleware: authed, handler: (req) => support.listTickets(req.user.id, req.valid.query) });
r.route({ method: 'get', path: '/tickets/:id', summary: 'Ticket detail', params: idParams, middleware: authed, handler: (req) => support.getTicket(req.user.id, req.valid.params.id) });
r.route({
  method: 'post', path: '/tickets/:id/messages', summary: 'Reply to a ticket', params: idParams, middleware: authed,
  body: z.object({ message: z.string().trim().min(1).max(4000) }),
  handler: (req) => support.replyToTicket(req.user.id, req.valid.params.id, req.body),
});

export default r.router;
