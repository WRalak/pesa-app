import { randomToken } from '../../lib/crypto.js';
import { config } from '../../config/env.js';

/**
 * Account-aggregation adapters (open-banking style). A production adapter
 * wraps a licensed aggregator: the user grants consent on the aggregator's
 * hosted page; we store only an opaque account token and fetch balances with
 * it. The SANDBOX adapter returns clearly-labelled simulated data and is
 * disabled in production.
 */
class SandboxAggregator {
  code = 'sandbox';
  institutions = [
    { code: 'sandbox-mpesa', name: 'M-Pesa (Sandbox)', kind: 'MOBILE_MONEY' },
    { code: 'sandbox-bank', name: 'Demo Bank (Sandbox)', kind: 'BANK' },
  ];

  async link({ institution, currency }) {
    const inst = this.institutions.find((i) => i.code === institution);
    if (!inst) throw new Error('Unknown institution');
    const suffix = String(Math.floor(1000 + Math.random() * 8999));
    return {
      kind: inst.kind,
      displayName: inst.name,
      maskedIdentifier: inst.kind === 'MOBILE_MONEY' ? `****${suffix}` : `ACC ****${suffix}`,
      providerAccountToken: `sbx_${randomToken(16)}`,
      currency,
      sandbox: true,
    };
  }

  /** Deterministic pseudo-balance derived from the token so refreshes are stable. */
  async fetchBalance({ providerAccountToken, currency }) {
    let h = 0;
    for (const ch of providerAccountToken) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
    const minorUnits = currency === 'UGX' || currency === 'RWF' ? 0 : 2;
    const whole = 5_000 + (h % 95_000);
    return { balanceMinor: whole * 10 ** minorUnits, asOf: new Date() };
  }
}

const sandbox = new SandboxAggregator();

export function getAggregator() {
  if (config.isProd) return null; // production aggregator adapter is configured per partner agreement
  return sandbox;
}
