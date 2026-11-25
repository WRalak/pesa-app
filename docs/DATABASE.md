# Database (MongoDB 7, replica set)

The database runs as a **replica set** in every environment, because multi-document ACID transactions are used for payment state changes, savings contributions and the reward ledger. Production runs on MongoDB Atlas (dedicated, `af-south-1`, PrivateLink, customer-managed KMS, continuous backup).

## Money representation

Every amount is stored as an **integer number of minor units** (`*Minor` fields), with a validator that requires `Number.isSafeInteger`, alongside an ISO 4217 `currency`. Minor units per currency come from `config/currencies.js` (KES 2, UGX 0, TZS 2, RWF 0, NGN 2, GHS 2, ZAR 2). Conversions use string and `BigInt` arithmetic (`lib/money.js`). Percentages and fees use basis points with banker's rounding. The largest safe value (9.0e15 minor units) is about KES 90 trillion, far above any single amount.

## Collections

| Collection (model) | Purpose | Key indexes / constraints |
|---|---|---|
| `users` (User) | Identity, status, KYC tier, lockouts, consents, referral code | `phone` unique, `email` unique (partial), `referralCode` unique, `{country,status,createdAt}` |
| `userprofiles` (UserProfile) | Names, DOB, address, notification and privacy preferences, personal limits | `userId` unique |
| `devices` (Device) | Device binding, trust, biometrics flag, push token | `{userId,deviceId}` unique |
| `sessions` (Session) | One per login; refresh token **HMAC** plus the previous hashes (reuse detection) | `refreshTokenHash` unique, `previousTokenHashes`, **TTL** on `expiresAt` |
| `otps` (Otp) | HMAC of the code, purpose, attempts | `{targetHash,purpose,createdAt}`, **TTL** 1h after expiry |
| `kycrecords` (KycRecord) | ID type, **AES-256-GCM encrypted** ID number, HMAC for duplicate detection, review | `{status,createdAt}`, `{idNumberHash,country}` |
| `linkedaccounts` (LinkedAccount) | Aggregator token (hidden), balance with `balanceSource` provenance | `{userId,provider,maskedIdentifier}` unique (partial) |
| `paymentproviders` (PaymentProvider) | Admin-managed fees, enablement, maintenance | `code` unique |
| `transactions` (Transaction) | The ledger of payment instructions. Financial fields are `immutable`; deletes are blocked | `reference` unique, `{userId,idempotencyKey}` unique, `{provider,providerRequestId}` unique (partial), `{provider,externalRef}` unique (partial), `{userId,createdAt,_id}`, `{status,updatedAt}` |
| `transactionevents` (TransactionEvent) | **Append-only** status history | `{transactionId,createdAt}` |
| `paymentcallbacks` (PaymentCallback) | Every webhook received (sanitised), with its processing outcome | `{provider,dedupeKey}` unique |
| `reconciliationrecords` | Per-run comparison results and their resolution | `{runId}`, `{resolution,createdAt}` |
| `savingsgoals` / `savingscontributions` | Goals; **append-only** contributions with the running balance | `{userId,status,createdAt}`, `{goalId,createdAt}` |
| `budgets`, `expenses`, `incomerecords`, `recurringitems` | Budgets with deduplicated alert keys; manual entries; recurring schedules | `{userId,date}`, `{active,nextRunAt}` |
| `cards` | Issuer token (hidden), brand, last 4, expiry, controls. **No PAN or CVV** | `{userId,status}` |
| `rewardcampaigns` | Admin-configurable rules and budget | `code` unique |
| `rewardaccounts` | Running points and cashback balances | `userId` unique |
| `rewards` (Reward) | **Append-only** ledger | `dedupeKey` unique (blocks double claims) |
| `referrals` | Referrer and referee, status, fraud signals | `refereeId` unique |
| `notifications` | In-app inbox | `{userId,createdAt}`, **TTL** 180 days |
| `supporttickets` | Support conversations | `reference` unique, `{status,priority,createdAt}` |
| `adminusers`, `roles`, `permissions`, `adminsessions`, `adminapprovals` | Admin identity, RBAC, sessions (TTL), maker-checker | `email` unique, `key` unique |
| `notificationcampaigns` | Marketing fan-outs (consented users only) | — |
| `auditlogs` (AuditLog) | **Append-only, hash-chained** audit trail | `seq` unique, `{actorType,actorId,createdAt}`, `{resourceType,resourceId,createdAt}` |
| `auditchainheads` | Current head of the audit chain | — |
| `securityevents` | Logins, lockouts, token reuse, fraud flags, rejected callbacks | `{severity,acknowledgedAt,createdAt}`, **TTL** 2 years |
| `idempotencykeys` | Stored responses for idempotent requests | `{scope,key}` unique, **TTL** 24h |
| `mockproviderledgers` | Sandbox provider state (non-production only) | `providerRequestId` unique |

## Immutability

- `appendOnly` plugin (`lib/immutable.js`): `TransactionEvent`, `SavingsContribution`, `Reward` and `AuditLog` refuse every update and delete operation at the ODM layer.
- `Transaction`: amount, fee, total, currency, user, type, provider, reference and idempotency key are `immutable: true`, and deletes throw. Status changes only through `transition()`.
- **Production hardening:** the application's database user is granted only `find`, `insert` and `createIndex` on the append-only collections (no `update` or `remove`), using an Atlas custom role. Then even compromised application code cannot rewrite history.
- The audit chain is verifiable with `npm run audit:verify` or the admin console's "Verify integrity". Editing or deleting any entry breaks every hash after it.

## Retention

| Data | Retention | Basis |
|---|---|---|
| Transactions, events, callbacks, reconciliation, KYC | 7 years after the relationship ends | AML/CFT record keeping (POCAMLA s.46) |
| Audit logs | 7 years | Same |
| Security events | 2 years (TTL) | Fraud investigation |
| Notifications | 180 days (TTL) | Data minimisation |
| OTPs | 1 hour after expiry (TTL) | Abuse analysis |
| Profile PII | Removed when the account is closed | DPA 2019 s.40 (erasure, subject to legal holds) |

## Transactions and concurrency

- Payment creation (transaction plus first event) and every status transition run in a session with snapshot read concern and `w: majority`.
- Savings contributions use a guarded `$inc` (withdrawals require `savedMinor >= amount`) inside a transaction.
- Reward redemption is a guarded `$inc` on `points`; campaign budgets are a `$expr` guard on `budgetUsedMinor + amount <= totalBudgetMinor`.
- Recurring items are claimed and advanced in one atomic pipeline update (`$dateAdd`), so parallel workers never double-post.
