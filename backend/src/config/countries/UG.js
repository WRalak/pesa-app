/** Uganda — prepared for expansion; not enabled until ENABLED_COUNTRIES includes UG. */
export default Object.freeze({
  code: 'UG',
  name: 'Uganda',
  dialCode: '+256',
  currency: 'UGX',
  locales: ['en-UG'],
  defaultLocale: 'en-UG',
  timezone: 'Africa/Kampala',
  dateFormat: 'dd/MM/yyyy',
  paymentProviders: ['mock'],
  defaultPaymentProvider: 'mock',
  paymentTypes: ['SEND_MONEY', 'AIRTIME', 'UTILITY'],
  mobileNetworks: ['MTN', 'AIRTEL'],
  limits: {
    TIER_0: { perTransaction: 100_000, daily: 500_000, monthly: 2_000_000 },
    TIER_1: { perTransaction: 5_000_000, daily: 10_000_000, monthly: 50_000_000 },
    TIER_2: { perTransaction: 7_000_000, daily: 20_000_000, monthly: 100_000_000 },
  },
  minTransaction: 500,
  kyc: { idTypes: ['NATIONAL_ID', 'PASSPORT'], requiresKraPin: false },
  regulatory: {
    dataProtectionAuthority: 'Personal Data Protection Office (PDPO)',
    paymentsRegulator: 'Bank of Uganda',
    amlAuthority: 'Financial Intelligence Authority (FIA)',
  },
  utilities: [],
});
