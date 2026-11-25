import { PaymentProviderAdapter, ProviderUnavailableError } from './base.js';
import { config } from '../../../config/env.js';
import { getRedis } from '../../../lib/redis.js';
import { fromMinor } from '../../../lib/money.js';
import { timingSafeEqualStr } from '../../../lib/crypto.js';
import { logger } from '../../../lib/logger.js';

/**
 * Safaricom Daraja (M-Pesa) adapter.
 *
 * - STK Push (Lipa na M-Pesa Online) for DEPOSIT / PAYBILL / BUY_GOODS where the
 *   receiving shortcode belongs to the licensed partner configured here.
 * - The customer authorises on their own handset. We NEVER collect or transmit
 *   the customer's M-Pesa PIN.
 * - Daraja does not sign callbacks. Defences: unguessable callback path token,
 *   source-IP allow-list, strict payload parsing, and — crucially — every
 *   success callback is confirmed via the STK Query API before the payment is
 *   marked successful (`confirmCallbacksByQuery`).
 *
 * Credentials come exclusively from the environment / secrets manager.
 */
const BASE = { sandbox: 'https://sandbox.safaricom.co.ke', production: 'https://api.safaricom.co.ke' };

export function darajaTimestamp(date = new Date()) {
  // Daraja expects YYYYMMDDHHmmss in East Africa Time (UTC+3, no DST).
  const eat = new Date(date.getTime() + 3 * 3600_000);
  const p = (n) => String(n).padStart(2, '0');
  return `${eat.getUTCFullYear()}${p(eat.getUTCMonth() + 1)}${p(eat.getUTCDate())}${p(eat.getUTCHours())}${p(eat.getUTCMinutes())}${p(eat.getUTCSeconds())}`;
}

export function stkPassword(shortcode, passkey, timestamp) {
  return Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');
}

/** Daraja requires whole-shilling amounts; reject fractional KES rather than silently rounding. */
export function toWholeKes(amountMinor) {
  if (amountMinor % 100 !== 0) throw new Error('M-Pesa amounts must be whole shillings');
  return amountMinor / 100;
}

export class DarajaProvider extends PaymentProviderAdapter {
  code = 'daraja';

  capabilities = {
    types: ['DEPOSIT', 'PAYBILL', 'BUY_GOODS'],
    currencies: ['KES'],
    countries: ['KE'],
    statusQuery: true,
    reversal: true,
    signedCallbacks: false,
    confirmCallbacksByQuery: true,
  };

  constructor({ fetchImpl = globalThis.fetch } = {}) {
    super();
    this.fetch = fetchImpl;
  }

  get baseUrl() {
    return BASE[config.DARAJA_ENV];
  }

  assertConfigured() {
    for (const k of ['DARAJA_CONSUMER_KEY', 'DARAJA_CONSUMER_SECRET', 'DARAJA_SHORTCODE', 'DARAJA_PASSKEY', 'DARAJA_CALLBACK_TOKEN']) {
      if (!config[k]) throw new ProviderUnavailableError(`Daraja is not configured (${k} missing)`);
    }
  }

  async token() {
    const redis = getRedis();
    const cached = await redis.get('daraja:token');
    if (cached) return cached;
    const basic = Buffer.from(`${config.DARAJA_CONSUMER_KEY}:${config.DARAJA_CONSUMER_SECRET}`).toString('base64');
    const res = await this.call('/oauth/v1/generate?grant_type=client_credentials', { method: 'GET', headers: { Authorization: `Basic ${basic}` } }, false);
    await redis.set('daraja:token', res.access_token, 'EX', Math.max(60, Number(res.expires_in ?? 3599) - 120));
    return res.access_token;
  }

  async call(path, init, auth = true) {
    const headers = { 'Content-Type': 'application/json', ...(init.headers ?? {}) };
    if (auth) headers.Authorization = `Bearer ${await this.token()}`;
    let res;
    try {
      res = await this.fetch(`${this.baseUrl}${path}`, { ...init, headers, signal: AbortSignal.timeout(15_000) });
    } catch (err) {
      // Network failure / timeout: we cannot know whether Safaricom acted on it.
      throw new ProviderUnavailableError(`Daraja request failed: ${err.message}`, { outcomeUnknown: init.method === 'POST' });
    }
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      logger.warn({ status: res.status, path, errorCode: body.errorCode }, 'Daraja error response');
      const err = new ProviderUnavailableError(body.errorMessage ?? `Daraja responded ${res.status}`, { outcomeUnknown: res.status >= 500 });
      err.providerRejected = res.status < 500;
      throw err;
    }
    return body;
  }

  callbackUrl(kind) {
    return `${config.PUBLIC_BASE_URL}/v1/callbacks/daraja/${config.DARAJA_CALLBACK_TOKEN}/${kind}`;
  }

  async initiate(txn, { payerPhone }) {
    this.assertConfigured();
    const timestamp = darajaTimestamp();
    const isTill = txn.type === 'BUY_GOODS';
    const body = {
      BusinessShortCode: config.DARAJA_SHORTCODE,
      Password: stkPassword(config.DARAJA_SHORTCODE, config.DARAJA_PASSKEY, timestamp),
      Timestamp: timestamp,
      TransactionType: isTill ? 'CustomerBuyGoodsOnline' : 'CustomerPayBillOnline',
      Amount: toWholeKes(txn.amountMinor),
      PartyA: payerPhone.replace('+', ''),
      PartyB: config.DARAJA_SHORTCODE,
      PhoneNumber: payerPhone.replace('+', ''),
      CallBackURL: this.callbackUrl('stk'),
      AccountReference: (txn.counterparty?.accountNumber ?? txn.reference).slice(0, 12),
      TransactionDesc: (txn.description ?? txn.type).slice(0, 13),
    };
    try {
      const res = await this.call('/mpesa/stkpush/v1/processrequest', { method: 'POST', body: JSON.stringify(body) });
      if (String(res.ResponseCode) !== '0') return { accepted: false, status: 'FAILED', reason: res.ResponseDescription };
      return { accepted: true, providerRequestId: res.CheckoutRequestID, status: 'PENDING', customerMessage: 'Check your phone and enter your M-Pesa PIN to approve.' };
    } catch (err) {
      if (err.providerRejected) return { accepted: false, status: 'FAILED', reason: err.message };
      throw err;
    }
  }

  async parseCallback(req) {
    const tokenOk = config.DARAJA_CALLBACK_TOKEN && timingSafeEqualStr(req.params.token ?? '', config.DARAJA_CALLBACK_TOKEN);
    const ipOk = config.darajaAllowedIps.length === 0 ? !config.isProd : config.darajaAllowedIps.includes(req.ip);
    const ack = { ResultCode: 0, ResultDesc: 'Accepted' };
    const cb = req.body?.Body?.stkCallback;
    if (req.params.kind === 'stk' && cb) {
      const items = Object.fromEntries((cb.CallbackMetadata?.Item ?? []).map((i) => [i.Name, i.Value]));
      const success = Number(cb.ResultCode) === 0;
      return {
        verified: Boolean(tokenOk && ipOk),
        dedupeKey: `${cb.CheckoutRequestID}:${cb.ResultCode}`,
        providerRequestId: cb.CheckoutRequestID,
        externalRef: items.MpesaReceiptNumber,
        outcome: success ? 'SUCCESS' : 'FAILED',
        amountMinor: items.Amount != null ? Math.round(Number(items.Amount)) * 100 : undefined,
        reason: success ? undefined : cb.ResultDesc,
        // Phone numbers are not stored from callbacks (data minimisation).
        sanitizedPayload: { MerchantRequestID: cb.MerchantRequestID, CheckoutRequestID: cb.CheckoutRequestID, ResultCode: cb.ResultCode, ResultDesc: cb.ResultDesc, Amount: items.Amount, MpesaReceiptNumber: items.MpesaReceiptNumber },
        ack,
      };
    }
    const result = req.body?.Result;
    if (req.params.kind === 'reversal' && result) {
      const params = Object.fromEntries((result.ResultParameters?.ResultParameter ?? []).map((p) => [p.Key, p.Value]));
      return {
        verified: Boolean(tokenOk && ipOk),
        dedupeKey: `rev:${result.ConversationID}:${result.ResultCode}`,
        providerRequestId: result.OriginatorConversationID,
        reversalRequestId: result.ConversationID,
        externalRef: result.TransactionID,
        outcome: Number(result.ResultCode) === 0 ? 'REVERSED' : 'UNKNOWN',
        amountMinor: params.Amount != null ? Math.round(Number(params.Amount)) * 100 : undefined,
        reason: result.ResultDesc,
        sanitizedPayload: { ConversationID: result.ConversationID, ResultCode: result.ResultCode, ResultDesc: result.ResultDesc, TransactionID: result.TransactionID },
        ack,
      };
    }
    return { verified: false, dedupeKey: '', outcome: 'UNKNOWN', sanitizedPayload: {}, ack };
  }

  async queryStatus(txn) {
    this.assertConfigured();
    const timestamp = darajaTimestamp();
    try {
      const res = await this.call('/mpesa/stkpushquery/v1/query', {
        method: 'POST',
        body: JSON.stringify({
          BusinessShortCode: config.DARAJA_SHORTCODE,
          Password: stkPassword(config.DARAJA_SHORTCODE, config.DARAJA_PASSKEY, timestamp),
          Timestamp: timestamp,
          CheckoutRequestID: txn.providerRequestId,
        }),
      });
      if (res.ResultCode === undefined) return { outcome: 'PENDING' };
      // ResultCode 0 = paid; 1032 = cancelled; 1037 = timeout; 1 = insufficient funds; others = failed.
      if (String(res.ResultCode) === '0') return { outcome: 'SUCCESS' };
      return { outcome: 'FAILED', reason: res.ResultDesc };
    } catch (err) {
      // Daraja returns 500 "transaction is being processed" while the prompt is open.
      if (/being processed/i.test(err.message)) return { outcome: 'PENDING' };
      throw err;
    }
  }

  async reverse(txn, reason) {
    this.assertConfigured();
    if (!process.env.DARAJA_INITIATOR_NAME || !process.env.DARAJA_SECURITY_CREDENTIAL) {
      return { accepted: false, reason: 'Reversal initiator credentials are not configured' };
    }
    const res = await this.call('/mpesa/reversal/v1/request', {
      method: 'POST',
      body: JSON.stringify({
        Initiator: process.env.DARAJA_INITIATOR_NAME,
        SecurityCredential: process.env.DARAJA_SECURITY_CREDENTIAL,
        CommandID: 'TransactionReversal',
        TransactionID: txn.externalRef,
        Amount: fromMinor(txn.amountMinor, 'KES').split('.')[0],
        ReceiverParty: config.DARAJA_SHORTCODE,
        RecieverIdentifierType: '11',
        ResultURL: this.callbackUrl('reversal'),
        QueueTimeOutURL: this.callbackUrl('timeout'),
        Remarks: (reason ?? 'Reversal').slice(0, 100),
        Occasion: txn.reference,
      }),
    });
    return { accepted: String(res.ResponseCode) === '0', providerRequestId: res.ConversationID, reason: res.ResponseDescription };
  }
}
