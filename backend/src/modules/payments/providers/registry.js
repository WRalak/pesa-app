import { config } from '../../../config/env.js';
import { MockProvider } from './mock.js';
import { DarajaProvider } from './daraja.js';
import { PaymentProvider } from '../models.js';
import { Errors } from '../../../lib/errors.js';
import { cached } from '../../../lib/redis.js';

const FACTORIES = {
  mock: () => new MockProvider(),
  daraja: () => new DarajaProvider(),
};

const instances = new Map();

/** Returns the adapter for `code` if it is enabled in this environment. */
export function getAdapter(code) {
  if (!config.paymentProviders.includes(code) || !FACTORIES[code]) throw Errors.badRequest(`Payment provider ${code} is not available`);
  if (!instances.has(code)) instances.set(code, FACTORIES[code]());
  return instances.get(code);
}

export function setAdapterForTests(code, adapter) {
  instances.set(code, adapter);
}

export function enabledAdapters() {
  return config.paymentProviders.filter((c) => FACTORIES[c]).map(getAdapter);
}

/** Provider configuration (fees, maintenance flags) maintained by admins in MongoDB. */
export async function getProviderConfig(code) {
  return cached(`provider-config:${code}`, 60, async () => PaymentProvider.findOne({ code }).lean());
}

/**
 * Picks the provider for a payment: the explicitly requested one, else the
 * enabled provider with the best priority that supports type+currency+country.
 */
export async function resolveProvider({ requested, type, currency, country }) {
  const candidates = requested ? [requested] : config.paymentProviders;
  const options = [];
  for (const code of candidates) {
    const adapter = getAdapter(code);
    if (!adapter.supports({ type, currency, country })) continue;
    const cfg = await getProviderConfig(code);
    if (cfg && (!cfg.enabled || cfg.maintenance)) continue;
    options.push({ adapter, cfg, priority: cfg?.priority ?? 100 });
  }
  if (!options.length) throw Errors.unprocessable('PROVIDER_UNAVAILABLE', 'This payment type is temporarily unavailable. Please try again later.');
  options.sort((a, b) => a.priority - b.priority);
  return options[0];
}
