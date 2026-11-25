import { sha256 } from './crypto.js';

/** Canonical JSON (sorted keys) so hashes are reproducible during verification. */
export function canonical(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (value instanceof Date) return JSON.stringify(value.toISOString());
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (typeof value.toHexString === 'function') return JSON.stringify(value.toHexString());
  return `{${Object.keys(value).sort().filter((k) => value[k] !== undefined).map((k) => `${JSON.stringify(k)}:${canonical(value[k])}`).join(',')}}`;
}

export function chainHash(prevHash, payload) {
  return sha256(`${prevHash ?? 'GENESIS'}|${canonical(payload)}`);
}
