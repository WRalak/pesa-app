import { describe, it, expect, vi } from 'vitest';
import { toMinor, fromMinor, applyBasisPoints, add, percent } from '../src/lib/money.js';
import { normalizePhone } from '../src/lib/phone.js';
import { generateTotpSecret, totpCode, verifyTotp } from '../src/lib/totp.js';
import { encryptField, decryptField, mask } from '../src/lib/crypto.js';
import { chainHash, canonical } from '../src/lib/audit-chain.js';
import { DarajaProvider, darajaTimestamp, stkPassword, toWholeKes } from '../src/modules/payments/providers/daraja.js';
import { categorize } from '../src/modules/budgets/categorizer.js';
import { startOfDayInTz } from '../src/modules/payments/service.js';
import { computeFee } from '../src/modules/payments/fees.js';

describe('money', () => {
  it('converts decimal strings to minor units without floating point error', () => {
    expect(toMinor('0.1', 'KES') + toMinor('0.2', 'KES')).toBe(toMinor('0.3', 'KES'));
    expect(toMinor('1500.50', 'KES')).toBe(150050);
    expect(toMinor('1500', 'UGX')).toBe(1500);
    expect(toMinor('19.99', 'ZAR')).toBe(1999);
  });

  it('respects currencies without minor units', () => {
    expect(() => toMinor('10.5', 'UGX')).toThrow(/at most 0 decimal/);
    expect(() => toMinor('10.5', 'RWF')).toThrow();
    expect(fromMinor(1500, 'UGX')).toBe('1500');
    expect(toMinor('10.00', 'UGX')).toBe(10);
  });

  it('formats minor units', () => {
    expect(fromMinor(150050, 'KES')).toBe('1500.50');
    expect(fromMinor(5, 'KES')).toBe('0.05');
    expect(fromMinor(-5, 'NGN')).toBe('-0.05');
  });

  it('rejects malformed and unsafe amounts', () => {
    for (const bad of ['-1', '1e5', 'abc', '', '1.2.3', '9999999999999999']) expect(() => toMinor(bad, 'KES')).toThrow();
    expect(() => add(Number.MAX_SAFE_INTEGER, 1)).toThrow(/range/);
    expect(() => fromMinor(1.5, 'KES')).toThrow();
  });

  it("applies basis points with banker's rounding", () => {
    expect(applyBasisPoints(10_000, 150)).toBe(150);
    expect(applyBasisPoints(50, 100)).toBe(0); // 0.5 -> 0 (even)
    expect(applyBasisPoints(150, 100)).toBe(2); // 1.5 -> 2 (even)
    expect(applyBasisPoints(250, 100)).toBe(2); // 2.5 -> 2 (even)
  });

  it('computes percentages safely', () => {
    expect(percent(50, 0)).toBe(0);
    expect(percent(150, 100)).toBe(100);
    expect(percent(33, 100)).toBe(33);
  });

  it('computes tiered fees from configuration', () => {
    const cfg = { fees: [{ type: 'PAYBILL', minAmountMinor: 0, maxAmountMinor: 100_00, fixedMinor: 0, bps: 0 }, { type: 'PAYBILL', minAmountMinor: 100_01, maxAmountMinor: 1e12, fixedMinor: 1000, bps: 0 }] };
    expect(computeFee(cfg, 'PAYBILL', 50_00)).toBe(0);
    expect(computeFee(cfg, 'PAYBILL', 500_00)).toBe(1000);
    expect(computeFee(null, 'PAYBILL', 500_00)).toBe(0);
  });
});

describe('phone numbers', () => {
  it('normalises Kenyan formats to E.164', () => {
    for (const n of ['0712345678', '712345678', '254712345678', '+254 712 345 678', '0112345678']) {
      expect(normalizePhone(n).e164).toMatch(/^\+2547\d{8}$|^\+2541\d{8}$/);
    }
    expect(normalizePhone('0712345678').e164).toBe('+254712345678');
  });

  it('rejects invalid or unsupported numbers', () => {
    expect(() => normalizePhone('12345')).toThrow();
    try {
      normalizePhone('+14155552671');
      throw new Error('should have thrown');
    } catch (e) {
      expect(e.details[0].message).toMatch(/not supported/);
    }
  });
});

describe('crypto', () => {
  it('round-trips AES-GCM field encryption and detects tampering', () => {
    const enc = encryptField('12345678');
    expect(enc).not.toContain('12345678');
    expect(decryptField(enc)).toBe('12345678');
    const parts = enc.split(':');
    parts[3] = Buffer.from('tampered').toString('base64');
    expect(() => decryptField(parts.join(':'))).toThrow();
  });

  it('masks values', () => expect(mask('0712345678')).toBe('******5678'));

  it('generates and verifies RFC 6238 TOTP codes', () => {
    const secret = generateTotpSecret();
    const now = Date.now();
    const code = totpCode(secret, now);
    expect(verifyTotp(secret, code, now)).not.toBeNull();
    expect(verifyTotp(secret, code, now + 31_000)).not.toBeNull(); // drift tolerance
    expect(verifyTotp(secret, code, now + 120_000)).toBeNull();
    expect(verifyTotp(secret, '12345a', now)).toBeNull();
  });

  it('matches the RFC 6238 SHA-1 test vector', () => {
    // Secret "12345678901234567890" in base32
    expect(totpCode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', 59_000)).toBe('287082');
  });

  it('produces order-independent canonical hashes for the audit chain', () => {
    expect(canonical({ b: 1, a: { d: 2, c: 3 } })).toBe(canonical({ a: { c: 3, d: 2 }, b: 1 }));
    expect(chainHash('x', { a: 1 })).not.toBe(chainHash('y', { a: 1 }));
  });
});

describe('Daraja adapter', () => {
  it('builds the STK password and EAT timestamp', () => {
    expect(darajaTimestamp(new Date('2026-01-31T21:30:05Z'))).toBe('20260201003005');
    expect(stkPassword('174379', 'pk', '20260101000000')).toBe(Buffer.from('174379pk20260101000000').toString('base64'));
  });

  it('refuses fractional shillings instead of rounding', () => {
    expect(toWholeKes(150_00)).toBe(150);
    expect(() => toWholeKes(150_50)).toThrow(/whole shillings/);
  });

  it('parses STK callbacks, but marks them unverified without the secret path token', async () => {
    const p = new DarajaProvider();
    const body = { Body: { stkCallback: { MerchantRequestID: 'm1', CheckoutRequestID: 'ws_CO_1', ResultCode: 0, ResultDesc: 'OK', CallbackMetadata: { Item: [{ Name: 'Amount', Value: 100 }, { Name: 'MpesaReceiptNumber', Value: 'TJK3XYZ' }, { Name: 'PhoneNumber', Value: 254712345678 }] } } } };
    const parsed = await p.parseCallback({ body, params: { token: 'wrong', kind: 'stk' }, ip: '1.2.3.4' });
    expect(parsed.verified).toBe(false);
    expect(parsed.outcome).toBe('SUCCESS');
    expect(parsed.amountMinor).toBe(10000);
    expect(parsed.externalRef).toBe('TJK3XYZ');
    expect(JSON.stringify(parsed.sanitizedPayload)).not.toContain('254712345678');
    expect(p.capabilities.confirmCallbacksByQuery).toBe(true);
  });

  it('maps failed STK callbacks', async () => {
    const p = new DarajaProvider();
    const parsed = await p.parseCallback({ body: { Body: { stkCallback: { CheckoutRequestID: 'ws_CO_2', ResultCode: 1032, ResultDesc: 'Request cancelled by user' } } }, params: { kind: 'stk' } });
    expect(parsed.outcome).toBe('FAILED');
    expect(parsed.reason).toMatch(/cancelled/);
  });

  it('reports an unknown outcome on network failure (never assumes failure)', async () => {
    const fetchImpl = vi.fn().mockRejectedValue(new Error('ETIMEDOUT'));
    const p = new DarajaProvider({ fetchImpl });
    await expect(p.call('/mpesa/stkpush/v1/processrequest', { method: 'POST', body: '{}' }, false)).rejects.toMatchObject({ outcomeUnknown: true });
  });
});

describe('categoriser & timezones', () => {
  it('categorises common Kenyan merchants', () => {
    expect(categorize({ type: 'BUY_GOODS', description: 'Till 1 · Naivas Westlands' }).category).toBe('food');
    expect(categorize({ type: 'PAYBILL', description: 'Paybill · HELB loan' }).category).toBe('education');
    expect(categorize({ type: 'AIRTIME' }).category).toBe('airtime_data');
    expect(categorize({ type: 'UTILITY', counterparty: { utilityCode: 'KPLC_PREPAID' } }).category).toBe('utilities');
    expect(categorize({ type: 'PAYBILL', description: 'unknown' }).category).toBe('uncategorised');
  });

  it('computes start of day in Africa/Nairobi', () => {
    const sod = startOfDayInTz('Africa/Nairobi', new Date('2026-03-10T22:30:00Z')); // 01:30 EAT on the 11th
    expect(sod.toISOString()).toBe('2026-03-10T21:00:00.000Z');
  });
});
