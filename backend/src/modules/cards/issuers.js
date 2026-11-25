import crypto from 'node:crypto';
import { config } from '../../config/env.js';
import { randomToken } from '../../lib/crypto.js';

/**
 * Card issuer adapter contract (implemented per licensed issuing partner):
 *   issueVirtual({ user, currency }) -> { token, brand, last4, expiryMonth, expiryYear }
 *   tokenizeLinked(paymentMethodToken) -> { token, brand, last4, expiryMonth, expiryYear }
 *   setStatus(token, 'ACTIVE'|'FROZEN'|'CLOSED')
 *   setControls(token, controls)
 *   secureDisplaySession(token) -> { sessionToken, expiresIn } for the issuer's PCI-scoped display SDK
 *   verifyWebhook(req) -> boolean
 * SANDBOX issuer below is for development and tests only.
 */
class SandboxIssuer {
  code = 'sandbox-issuer';

  async issueVirtual() {
    return { token: `sbxcard_${randomToken(16)}`, brand: 'VISA', last4: String(crypto.randomInt(1000, 9999)), expiryMonth: 12, expiryYear: new Date().getUTCFullYear() + 3 };
  }

  async tokenizeLinked(paymentMethodToken) {
    const brands = { tok_sandbox_visa: ['VISA', '4242'], tok_sandbox_mastercard: ['MASTERCARD', '4444'] };
    const b = brands[paymentMethodToken];
    if (!b) throw new Error('Unknown sandbox payment method token');
    return { token: `sbxlinked_${randomToken(16)}`, brand: b[0], last4: b[1], expiryMonth: 8, expiryYear: new Date().getUTCFullYear() + 2 };
  }

  async setStatus() { return true; }
  async setControls() { return true; }

  async secureDisplaySession() {
    return { sessionToken: `sbxdisplay_${randomToken(16)}`, expiresIn: 60, note: 'Sandbox: card numbers are rendered by the issuer SDK, never returned by this API.' };
  }

  signWebhook(raw) {
    return crypto.createHmac('sha256', config.MOCK_PROVIDER_WEBHOOK_SECRET).update(raw).digest('hex');
  }

  verifyWebhook(req) {
    const sig = req.get('x-issuer-signature') ?? '';
    const expected = this.signWebhook(req.rawBody ?? Buffer.from(''));
    return sig.length === expected.length && crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
  }
}

const sandbox = new SandboxIssuer();
export function getIssuer(code = 'sandbox-issuer') {
  if (code === 'sandbox-issuer' && !config.isProd) return sandbox;
  throw new Error(`Card issuer ${code} is not configured`);
}
export function issuerAvailable() {
  return !config.isProd;
}
