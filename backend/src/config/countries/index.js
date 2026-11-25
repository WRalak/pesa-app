import KE from './KE.js';
import UG from './UG.js';
import { config } from '../env.js';

const ALL = { KE, UG };

export function getCountry(code = config.DEFAULT_COUNTRY) {
  const c = ALL[code?.toUpperCase()];
  if (!c) throw new Error(`Unknown country ${code}`);
  return c;
}

export function isCountryEnabled(code) {
  return config.enabledCountries.includes(code?.toUpperCase());
}

export function enabledCountries() {
  return config.enabledCountries.filter((c) => ALL[c]).map((c) => ALL[c]);
}
