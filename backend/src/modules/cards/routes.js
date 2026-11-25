import { Router } from 'express';
import { createRouter, idParams, pageQuery, amountString, objectId } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as cards from './service.js';
import { getIssuer } from './issuers.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';
import { config } from '../../config/env.js';
import { randomToken } from '../../lib/crypto.js';
import { Errors } from '../../lib/errors.js';
import { Card } from './models.js';

const r = createRouter({ prefix: '/v1/cards', tags: ['Cards'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];
const pin = z.string().regex(/^\d{4,6}$/);

r.route({ method: 'get', path: '/', summary: 'My cards (tokenised; no card numbers)', middleware: authed, handler: (req) => cards.listCards(req.user.id) });
r.route({ method: 'post', path: '/virtual', summary: 'Issue a virtual card via the issuing partner', status: 201, middleware: authed, body: z.object({ nickname: z.string().trim().max(40).optional(), pin }), handler: (req) => cards.issueVirtualCard(req.userDoc, req.body, req) });
r.route({
  method: 'post', path: '/link', summary: 'Link an existing card using a PSP payment-method token', status: 201, middleware: authed,
  description: 'The client collects card data with the PSP SDK and sends only the resulting token. Raw card numbers are rejected.',
  body: z.object({ paymentMethodToken: z.string().regex(/^tok_[A-Za-z0-9_]{4,64}$/, 'Send a PSP token, never card numbers'), nickname: z.string().trim().max(40).optional() }),
  handler: (req) => cards.linkCard(req.userDoc, req.body, req),
});
r.route({ method: 'post', path: '/:id/freeze', summary: 'Freeze card', params: idParams, middleware: authed, handler: (req) => cards.setFrozen(req.userDoc, req.valid.params.id, true, req) });
r.route({ method: 'post', path: '/:id/unfreeze', summary: 'Unfreeze card', params: idParams, middleware: authed, handler: (req) => cards.setFrozen(req.userDoc, req.valid.params.id, false, req) });
r.route({
  method: 'patch', path: '/:id/controls', summary: 'Spending limits and channel controls', params: idParams, middleware: authed,
  body: z.object({ perTransaction: amountString.nullable().optional(), daily: amountString.nullable().optional(), monthly: amountString.nullable().optional(), online: z.boolean().optional(), international: z.boolean().optional(), atm: z.boolean().optional() }),
  handler: (req) => cards.updateControls(req.userDoc, req.valid.params.id, req.body),
});
r.route({ method: 'post', path: '/:id/secure-display', summary: 'Start an issuer secure-display session (PIN required)', params: idParams, middleware: authed, body: z.object({ pin }), handler: (req) => cards.secureDisplay(req.userDoc, req.valid.params.id, req.body, req) });
r.route({ method: 'delete', path: '/:id', summary: 'Close a card', params: idParams, middleware: authed, handler: (req) => cards.closeCard(req.userDoc, req.valid.params.id, req) });
r.route({ method: 'get', path: '/:id/transactions', summary: 'Card transactions', params: idParams, query: pageQuery, middleware: authed, handler: (req) => cards.cardTransactions(req.user.id, req.valid.params.id, req.valid.query) });

if (!config.isProd) {
  r.route({
    method: 'post', path: '/:id/simulate-authorization', summary: '[SANDBOX] Simulate a merchant authorization through the issuer webhook path', params: idParams, middleware: authed,
    body: z.object({ amount: amountString, merchantName: z.string().max(60).default('Sandbox Merchant'), channel: z.enum(['POS', 'ONLINE', 'ATM']).default('POS'), international: z.boolean().default(false) }),
    handler: async (req) => {
      const card = await Card.findOne({ _id: req.valid.params.id, userId: req.user.id }).lean();
      if (!card) throw Errors.notFound('Card');
      const { toMinor } = await import('../../lib/money.js');
      return cards.processIssuerEvent({ eventId: `sim_${randomToken(10)}`, cardId: card._id, authorizationId: `AUTH${randomToken(6)}`, amountMinor: toMinor(req.body.amount, card.currency), merchantName: req.body.merchantName, channel: req.body.channel, international: req.body.international, approved: true });
    },
  });
}

/** Issuer webhook (HMAC-signed). */
export const issuerWebhook = Router();
issuerWebhook.post('/card-issuer', async (req, res, next) => {
  try {
    const issuer = getIssuer();
    if (!issuer.verifyWebhook(req)) return res.status(401).json({ error: { code: 'CALLBACK_REJECTED', message: 'Invalid signature' } });
    const b = req.body ?? {};
    if (!b.eventId || !objectId.safeParse(String(b.cardId)).success || !Number.isSafeInteger(b.amountMinor) || b.amountMinor <= 0) return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Malformed event' } });
    const out = await cards.processIssuerEvent({ eventId: String(b.eventId), cardId: b.cardId, authorizationId: String(b.authorizationId ?? b.eventId), amountMinor: b.amountMinor, merchantName: String(b.merchantName ?? 'Merchant').slice(0, 60), channel: b.channel, international: Boolean(b.international), approved: b.approved !== false, declineReason: b.declineReason });
    res.json({ received: true, status: out.status });
  } catch (err) {
    next(err);
  }
});

export default r.router;
