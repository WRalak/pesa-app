/**
 * Payment provider contract. Every adapter (mock, Safaricom Daraja, bank or
 * aggregator) implements this interface so the payment service never depends
 * on a specific provider. Adding a provider = one new adapter + registry entry.
 *
 * Outcomes reported by adapters:
 *   initiate()     -> { accepted, providerRequestId?, status: 'PENDING'|'PROCESSING'|'FAILED', reason?, customerMessage? }
 *   parseCallback()-> { verified, dedupeKey, providerRequestId?, externalRef?, outcome: 'SUCCESS'|'FAILED'|'REVERSED'|'UNKNOWN', amountMinor?, reason?, ack, sanitizedPayload }
 *   queryStatus()  -> { outcome: 'SUCCESS'|'FAILED'|'PENDING'|'NOT_FOUND', externalRef?, amountMinor?, reason? }
 *   reverse()      -> { accepted, providerRequestId?, reason? }
 *   settlementReport({from,to}) -> [{ providerRequestId, externalRef, amountMinor, currency, status }]
 */
export class PaymentProviderAdapter {
  /** @type {string} */
  code = 'base';

  capabilities = {
    types: [],
    currencies: [],
    countries: [],
    statusQuery: false,
    reversal: false,
    signedCallbacks: false,
    /** If callbacks are unsigned, a success callback must be confirmed via queryStatus. */
    confirmCallbacksByQuery: true,
  };

  supports({ type, currency, country }) {
    const c = this.capabilities;
    return c.types.includes(type) && c.currencies.includes(currency) && c.countries.includes(country);
  }

  /* eslint-disable no-unused-vars */
  async initiate(txn, context) { throw new Error('not implemented'); }
  async parseCallback(req) { throw new Error('not implemented'); }
  async queryStatus(txn) { return { outcome: 'PENDING' }; }
  async reverse(txn, reason) { return { accepted: false, reason: 'Reversals not supported by provider' }; }
  async settlementReport(window) { return []; }
  /* eslint-enable no-unused-vars */
}

/** Thrown when the provider's response is unknown (timeout) — outcome must be queried later, never assumed. */
export class ProviderUnavailableError extends Error {
  constructor(message, { outcomeUnknown = false } = {}) {
    super(message);
    this.outcomeUnknown = outcomeUnknown;
  }
}
