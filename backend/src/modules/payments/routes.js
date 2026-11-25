import { createRouter, idParams, amountString, objectId } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import * as payments from './service.js';
import { requireAuth, loadActiveUser, requireTransactable } from '../../middleware/auth.js';
import { idempotent } from '../../middleware/idempotency.js';
import { rateLimit } from '../../middleware/rate-limit.js';
import { Transaction } from './models.js';
import { Errors } from '../../lib/errors.js';
import { getCountry } from '../../config/countries/index.js';
import { enabledAdapters, getProviderConfig } from './providers/registry.js';
import { computeFee } from './fees.js';
import { toMinor, money } from '../../lib/money.js';
import { TX_TYPES } from './models.js';
import { config } from '../../config/env.js';

const r = createRouter({ prefix: '/v1/payments', tags: ['Payments'], security: 'bearerAuth' });
const authed = [requireAuth, loadActiveUser];

const paymentBody = z.object({
  type: z.enum(['SEND_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT', 'BANK_TRANSFER']),
  amount: amountString,
  currency: z.string().length(3).optional(),
  provider: z.string().max(30).optional(),
  recipientPhone: z.string().max(20).optional(),
  recipientName: z.string().trim().max(80).optional(),
  paybillNumber: z.string().max(10).optional(),
  tillNumber: z.string().max(10).optional(),
  accountNumber: z.string().trim().max(40).optional(),
  utilityCode: z.string().max(30).optional(),
  network: z.string().max(20).optional(),
  bankCode: z.string().max(20).optional(),
  description: z.string().trim().max(140).optional(),
  sourceAccountId: objectId.optional(),
  confirmDuplicate: z.boolean().optional(),
  pin: z.string().regex(/^\d{4,6}$/).openapi({ description: 'The app transaction PIN. Never an M-Pesa PIN.' }),
});

r.route({
  method: 'post', path: '/', summary: 'Initiate a payment', status: 202, idempotent: true,
  description: 'Creates a transaction and submits it to the provider. The response status is PENDING; the final outcome arrives via provider callback (pushed over Socket.IO and notifications). Requires an `Idempotency-Key` header.',
  middleware: [...authed, requireTransactable, rateLimit({ name: 'payments', points: config.PAYMENT_RATE_LIMIT_PER_MIN, duration: 60, keyFn: (req) => req.user.id }), idempotent()],
  body: paymentBody,
  handler: (req) => payments.initiatePayment(req.userDoc, { ...req.body, idempotencyKey: req.get('idempotency-key') }, req),
});

r.route({
  method: 'post', path: '/quote', summary: 'Preview fees for a payment', middleware: authed,
  body: z.object({ type: z.enum(TX_TYPES), amount: amountString, provider: z.string().max(30).optional() }),
  handler: async (req) => {
    const user = req.userDoc;
    const amountMinor = toMinor(req.body.amount, user.currency);
    const { resolveProvider } = await import('./providers/registry.js');
    const { adapter, cfg } = await resolveProvider({ requested: req.body.provider, type: req.body.type, currency: user.currency, country: user.country });
    const feeMinor = computeFee(cfg, req.body.type, amountMinor);
    return { provider: adapter.code, amount: money(amountMinor, user.currency), fee: money(feeMinor, user.currency), total: money(amountMinor + feeMinor, user.currency) };
  },
});

r.route({
  method: 'get', path: '/options', summary: 'Payment types, providers and billers for my country', middleware: authed,
  handler: async (req) => {
    const country = getCountry(req.userDoc.country);
    const providers = [];
    for (const a of enabledAdapters()) {
      const cfg = await getProviderConfig(a.code);
      if (cfg && !cfg.enabled) continue;
      providers.push({
        code: a.code, name: cfg?.name ?? a.code, sandbox: cfg?.sandbox ?? a.code === 'mock', maintenance: Boolean(cfg?.maintenance),
        types: a.capabilities.types.filter((t) => country.paymentTypes.includes(t)),
      });
    }
    return { currency: country.currency, paymentTypes: country.paymentTypes, providers, utilities: country.utilities.map(({ code, name }) => ({ code, name })), networks: country.mobileNetworks };
  },
});

r.route({
  method: 'post', path: '/:id/refresh-status', summary: 'Ask the provider for the latest status', params: idParams,
  middleware: [...authed, rateLimit({ name: 'status-refresh', points: 10, duration: 60, keyFn: (req) => req.user.id })],
  handler: async (req) => {
    const owned = await Transaction.exists({ _id: req.valid.params.id, userId: req.user.id });
    if (!owned) throw Errors.notFound('Transaction');
    const t = await payments.checkTransactionStatus(req.valid.params.id);
    return { transaction: payments.serializeTransaction(t, { detail: true }) };
  },
});

export default r.router;
