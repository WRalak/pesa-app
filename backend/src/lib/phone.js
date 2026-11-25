import { parsePhoneNumberFromString } from 'libphonenumber-js/max';
import { Errors } from './errors.js';
import { isCountryEnabled } from '../config/countries/index.js';

/**
 * Normalise any user-entered phone number ("0712 345 678", "254712345678",
 * "+254712345678") to E.164. The default region drives parsing of national
 * formats; only numbers in enabled countries are accepted.
 */
export function normalizePhone(input, defaultCountry = 'KE') {
  const raw = String(input ?? '').replace(/[\s()-]/g, '');
  const withPlus = /^\d{11,15}$/.test(raw) && !raw.startsWith('0') ? `+${raw}` : raw;
  const parsed = parsePhoneNumberFromString(withPlus, defaultCountry);
  if (!parsed || !parsed.isValid()) throw Errors.validation([{ path: 'phone', message: 'Invalid phone number' }]);
  if (!isCountryEnabled(parsed.country)) {
    throw Errors.validation([{ path: 'phone', message: `Phone numbers from ${parsed.country ?? 'this region'} are not supported yet` }]);
  }
  const type = parsed.getType();
  if (type && !['MOBILE', 'FIXED_LINE_OR_MOBILE'].includes(type)) {
    throw Errors.validation([{ path: 'phone', message: 'A mobile number is required' }]);
  }
  return { e164: parsed.number, country: parsed.country, national: parsed.formatNational() };
}

export function maskPhone(e164) {
  if (!e164) return e164;
  return `${e164.slice(0, 4)}*****${e164.slice(-3)}`;
}
