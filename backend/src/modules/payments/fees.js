import { applyBasisPoints, add } from '../../lib/money.js';

/** Computes the fee from the provider's admin-configured fee table (integer arithmetic only). */
export function computeFee(providerCfg, type, amountMinor) {
  const rule = (providerCfg?.fees ?? []).find((f) => f.type === type && amountMinor >= f.minAmountMinor && amountMinor <= f.maxAmountMinor);
  if (!rule) return 0;
  return add(rule.fixedMinor ?? 0, applyBasisPoints(amountMinor, rule.bps ?? 0));
}
