/**
 * Kenya market configuration. Business rules that vary by country (limits,
 * providers, payment types, regulatory flags) live here, never inline in code.
 * Amounts are in minor units of the country currency.
 */
export default Object.freeze({
  code: 'KE',
  name: 'Kenya',
  dialCode: '+254',
  currency: 'KES',
  locales: ['en-KE', 'sw-KE'],
  defaultLocale: 'en-KE',
  timezone: 'Africa/Nairobi',
  dateFormat: 'dd/MM/yyyy',
  paymentProviders: ['mock', 'daraja'],
  defaultPaymentProvider: 'mock',
  paymentTypes: ['SEND_MONEY', 'PAYBILL', 'BUY_GOODS', 'AIRTIME', 'UTILITY', 'DEPOSIT'],
  mobileNetworks: ['SAFARICOM', 'AIRTEL', 'TELKOM'],
  limits: {
    // Tiered by KYC level. Values in KES cents.
    TIER_0: { perTransaction: 1_000_00, daily: 5_000_00, monthly: 20_000_00 },
    TIER_1: { perTransaction: 150_000_00, daily: 500_000_00, monthly: 3_000_000_00 },
    TIER_2: { perTransaction: 250_000_00, daily: 500_000_00, monthly: 5_000_000_00 },
  },
  minTransaction: 1_00,
  kyc: {
    idTypes: ['NATIONAL_ID', 'PASSPORT', 'ALIEN_ID'],
    requiresKraPin: false,
  },
  regulatory: {
    dataProtectionAuthority: 'Office of the Data Protection Commissioner (ODPC)',
    paymentsRegulator: 'Central Bank of Kenya (CBK)',
    amlAuthority: 'Financial Reporting Centre (FRC)',
    dataResidencyNote: 'Assess cross-border transfer requirements under the Data Protection Act, 2019 s.48-50.',
  },
  utilities: [
    { code: 'KPLC_PREPAID', name: 'KPLC Prepaid Tokens', paybill: '888880' },
    { code: 'KPLC_POSTPAID', name: 'KPLC Postpaid', paybill: '888888' },
    { code: 'NAIROBI_WATER', name: 'Nairobi Water', paybill: '444400' },
    { code: 'DSTV', name: 'DStv', paybill: '444900' },
    { code: 'ZUKU', name: 'Zuku', paybill: '320320' },
  ],
});
