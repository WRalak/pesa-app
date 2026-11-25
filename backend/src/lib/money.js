import { getCurrency } from '../config/currencies.js';

/**
 * Money helpers. All amounts are integers in minor units (e.g. KES cents).
 * Parsing and formatting use string/BigInt arithmetic — never floating point.
 */

const DECIMAL_RE = /^(\d{1,15})(?:\.(\d+))?$/;

/** Parse a decimal string like "1500.50" into minor units for `currency`. */
export function toMinor(value, currency) {
  const { minorUnits } = getCurrency(currency);
  const str = typeof value === 'number' ? numberToPlainString(value) : String(value).trim();
  const m = DECIMAL_RE.exec(str);
  if (!m) throw new RangeError(`Invalid amount "${value}"`);
  const [, whole, frac = ''] = m;
  if (frac.length > minorUnits && /[1-9]/.test(frac.slice(minorUnits))) {
    throw new RangeError(`${currency} supports at most ${minorUnits} decimal places`);
  }
  const padded = (frac + '0'.repeat(minorUnits)).slice(0, minorUnits);
  const minor = BigInt(whole) * 10n ** BigInt(minorUnits) + BigInt(padded || '0');
  return assertSafe(minor);
}

/** Format minor units as a plain decimal string, e.g. 150050 KES -> "1500.50". */
export function fromMinor(minor, currency) {
  const { minorUnits } = getCurrency(currency);
  assertInteger(minor);
  const neg = minor < 0;
  const abs = BigInt(Math.abs(minor));
  if (minorUnits === 0) return `${neg ? '-' : ''}${abs}`;
  const base = 10n ** BigInt(minorUnits);
  const whole = abs / base;
  const frac = (abs % base).toString().padStart(minorUnits, '0');
  return `${neg ? '-' : ''}${whole}.${frac}`;
}

/** Serialisable money object returned by the API. */
export function money(minor, currency) {
  return { amountMinor: minor, currency, amount: fromMinor(minor, currency) };
}

export function add(...values) {
  return assertSafe(values.reduce((acc, v) => acc + BigInt(assertInteger(v)), 0n));
}

export function subtract(a, b) {
  return assertSafe(BigInt(assertInteger(a)) - BigInt(assertInteger(b)));
}

/**
 * Multiply by a rate expressed in basis points (1 bp = 0.01%) using banker's
 * rounding (half-to-even) so that rounding bias does not accumulate.
 */
export function applyBasisPoints(minor, bps) {
  assertInteger(minor);
  assertInteger(bps);
  const num = BigInt(minor) * BigInt(bps);
  const den = 10_000n;
  let q = num / den;
  const r = num % den;
  const twice = (r < 0n ? -r : r) * 2n;
  if (twice > den || (twice === den && q % 2n !== 0n)) q += num < 0n ? -1n : 1n;
  return assertSafe(q);
}

/** Percentage (0-100, integer) of `part` over `total`, never NaN. */
export function percent(part, total) {
  if (!total) return 0;
  return Math.min(100, Math.max(0, Math.floor((part * 100) / total)));
}

function assertInteger(v) {
  if (!Number.isSafeInteger(v)) throw new RangeError(`Amount must be a safe integer of minor units, got ${v}`);
  return v;
}

function assertSafe(big) {
  if (big > BigInt(Number.MAX_SAFE_INTEGER) || big < BigInt(Number.MIN_SAFE_INTEGER)) {
    throw new RangeError('Amount out of range');
  }
  return Number(big);
}

function numberToPlainString(n) {
  if (!Number.isFinite(n) || n < 0) throw new RangeError(`Invalid amount ${n}`);
  // Numbers are accepted only for convenience; they are converted via their
  // shortest round-trip decimal representation, then parsed as a string.
  return n.toLocaleString('en-US', { useGrouping: false, maximumFractionDigits: 20 });
}
