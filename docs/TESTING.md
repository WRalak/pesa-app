# Testing

**Nothing in the automated tests moves real money.** Payment tests use the sandbox `mock` provider, which has HMAC-signed webhooks and deterministic outcomes. Daraja is tested at the adapter level with a mocked `fetch`.

## Backend (`cd backend && npm test`): 118 tests

| Suite | Covers |
|---|---|
| `unit.test.js` | Money (float safety, zero-decimal currencies, banker's rounding, overflow), phone normalisation, AES-GCM tamper detection, RFC 6238 TOTP test vector, audit-hash canonicalisation, Daraja password/timestamp/callback parsing/unknown-outcome handling, categoriser, Nairobi day boundaries, fee tiers |
| `auth.test.js` | Registration, OTP hashing, attempt lockout, mass-assignment rejection, enumeration resistance, device step-up, account lockout, refresh rotation and **reuse detection**, logout revocation, forged and `alg:none` tokens, session revocation, password reset, PIN lockout and reset, email verification, NoSQL-injection stripping, secure headers, per-IP rate limiting |
| `payments.test.js` | PENDING-only initiation, Idempotency-Key replay, mismatch and **concurrency**, PIN required, duplicate guard, KYC limits, payee validation, precision, configured fees; signed callbacks, forged and tampered callbacks, duplicate callbacks processed once, late FAILED can't overturn SUCCESSFUL, amount mismatch held, orphaned callbacks; status-query sweeper; state-machine rejection; immutability; provider-confirmed reversal; filters, search, cursor pagination, regex injection; **cross-user isolation**; receipts; CSV (formula injection) and PDF statements; velocity blocking |
| `finance.test.js` | Atomic concurrent contributions, overdraw prevention, goal completion and reopening, privacy, reminders; budget alerts once per threshold; concurrent recurring jobs post exactly once; analytics exclude pending; verified vs manual balances; robust outlier detection; de-identified AI payload; no AI call without consent |
| `cards-rewards.test.js` | No PAN storage or exposure, raw-PAN rejection, controls (limit, online, frozen), signed and deduplicated issuer webhooks, isolation; cashback and points rules, caps and per-user limits, replayed events, clawback on reversal, referral qualification, same-device referral rejection, concurrent redemption, offers, held cashback |
| `admin.test.js` | MFA required, TOTP replay rejected, user tokens refused, logout; RBAC per role; PII masking and audited reveal; suspend/reactivate; KYC decisions; no edit endpoints for transactions; **maker-checker** separation of duties; reconciliation auto-resolve vs conflict; fee configuration audit; campaigns; consent-gated promotions; self-escalation blocked; audit chain verification and tamper detection; temporary-password enforcement |

`npm test` first runs `scripts/check-imports.js`, which loads every module with Node's native ESM loader. That catches import errors the test transformer tolerates, so production entry points are guaranteed to boot.

Infrastructure: `mongodb-memory-server` runs a **replica set** (transactions need one), and a disposable `redis-server` runs per test run (CI uses a Redis service container).

## Admin console (`cd admin && npm test && npm run typecheck`)

Component tests (Badge tones, reason-gated privileged actions, money formatting) plus strict TypeScript.

## Mobile (`cd mobile && flutter analyze && flutter test`)

Unit tests (Money formatting and input normalisation, API client token and header handling, error mapping, session expiry, device ID stability) and widget tests (PIN pad entry and delete, MoneyText privacy masking, status chips, phone and password validation, dark theme). The analyzer runs with strict casts and raw types.

## Manual end-to-end check

1. `docker compose up` (see README), then `node scripts/seed.js`.
2. Register in the app; read the OTP from `GET /v1/auth/dev/outbox`.
3. Pay KES 50 of airtime. It goes PENDING, then about 3 seconds later the worker delivers a signed callback and it becomes SUCCESSFUL, and a push or in-app notification arrives.
4. Pay KES 50.01. The provider declines it and it becomes FAILED, with a notification.
5. Pay KES 50.02. There is no callback; the sweeper resolves it once you change the mock ledger (or it is flagged after 24 hours).
6. In the admin console: find the transaction, request a reversal, approve it as a second finance admin, and run reconciliation.

## Load testing (`infrastructure/k6/payments.js`)

Run it against **staging** with pre-seeded TIER_1 test users (never production). Thresholds: dashboard p95 < 400 ms, transaction list p95 < 300 ms, payment initiation p95 < 800 ms, error rate < 1%, with 200 concurrent browsing users and 30 payments per second.

```bash
k6 run -e BASE_URL=https://api.staging.pesa.africa -e TOKENS_FILE=tokens.json infrastructure/k6/payments.js
```
