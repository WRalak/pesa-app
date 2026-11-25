/**
 * ISO 4217 currency metadata. `minorUnits` is the number of decimal places used
 * for storage: every amount in the system is an integer count of minor units.
 * Do NOT assume two decimal places — UGX and RWF have none.
 */
export const CURRENCIES = Object.freeze({
  KES: { code: 'KES', name: 'Kenyan Shilling', minorUnits: 2, symbol: 'KSh' },
  UGX: { code: 'UGX', name: 'Ugandan Shilling', minorUnits: 0, symbol: 'USh' },
  TZS: { code: 'TZS', name: 'Tanzanian Shilling', minorUnits: 2, symbol: 'TSh' },
  RWF: { code: 'RWF', name: 'Rwandan Franc', minorUnits: 0, symbol: 'FRw' },
  NGN: { code: 'NGN', name: 'Nigerian Naira', minorUnits: 2, symbol: '₦' },
  GHS: { code: 'GHS', name: 'Ghanaian Cedi', minorUnits: 2, symbol: 'GH₵' },
  ZAR: { code: 'ZAR', name: 'South African Rand', minorUnits: 2, symbol: 'R' },
});

export const CURRENCY_CODES = Object.freeze(Object.keys(CURRENCIES));

export function getCurrency(code) {
  const c = CURRENCIES[code];
  if (!c) throw new Error(`Unsupported currency ${code}`);
  return c;
}
