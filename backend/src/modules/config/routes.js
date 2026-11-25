import { createRouter } from '../../lib/router.js';
import { enabledCountries } from '../../config/countries/index.js';
import { CURRENCIES } from '../../config/currencies.js';
import { config } from '../../config/env.js';

const r = createRouter({ prefix: '/v1/config', tags: ['Config'] });

r.route({
  method: 'get', path: '/', summary: 'Public client configuration (countries, currencies, feature flags)',
  handler: (_req, res) => {
    res.setHeader('Cache-Control', 'public, max-age=300');
    return {
      environment: config.NODE_ENV,
      sandbox: !config.isProd,
      defaultCountry: config.DEFAULT_COUNTRY,
      countries: enabledCountries().map((c) => ({
        code: c.code, name: c.name, dialCode: c.dialCode, currency: c.currency, locales: c.locales,
        timezone: c.timezone, paymentTypes: c.paymentTypes, mobileNetworks: c.mobileNetworks,
        utilities: c.utilities.map(({ code, name }) => ({ code, name })), kycIdTypes: c.kyc.idTypes,
      })),
      currencies: Object.values(CURRENCIES),
      features: { cards: true, rewards: true, aiInsights: true, externalAi: config.AI_EXTERNAL_PROVIDER !== 'none' },
      minSupportedAppVersion: '1.0.0',
      legal: {
        disclaimer: 'Pesa is a financial management platform. Payments are processed by licensed partners. Pesa does not hold customer funds.',
      },
    };
  },
});

export default r.router;
