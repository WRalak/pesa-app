# API

- **Base URL:** `https://api.<env>.pesa.africa`. All public endpoints are versioned under `/v1`. The admin API is `/admin/v1` and is reachable only through the internal ALB.
- **Spec:** [`docs/api/openapi.json`](api/openapi.json) is generated from the route definitions (`npm run openapi`), and CI fails if it is out of date. Swagger UI runs at `/docs` outside production.

## Conventions

| Topic | Rule |
|---|---|
| Auth | `Authorization: Bearer <access token>` (15 min JWT, HS256, audience `pesa-app`). Refresh with `POST /v1/auth/refresh`; the refresh token rotates on every use, and reusing an old one revokes the session. |
| Device headers | `X-Device-Id` (per-install UUID), `X-App-Version`, `X-Platform`, `Accept-Language` (`en-KE` / `sw-KE`). |
| Money | Every amount in a response is `{ "amountMinor": 150050, "currency": "KES", "amount": "1500.50" }`. Requests send amounts as **decimal strings** (`"1500.50"`), and precision beyond the currency's minor units is rejected. |
| Idempotency | `POST /v1/payments` requires `Idempotency-Key` (8–128 chars). The same key with the same body replays the original response (`Idempotent-Replayed: true`); the same key with a different body returns `422 IDEMPOTENCY_MISMATCH`; a concurrent duplicate returns `409 IDEMPOTENCY_IN_PROGRESS`. Clients reuse the key only when the outcome is unknown (timeout or 5xx). |
| Pagination | Cursor based: `?limit=20&cursor=<opaque>`. Responses look like `{ items, nextCursor, hasMore }`. |
| Errors | `{ "error": { "code", "message", "details"?, "requestId" } }`. `422 VALIDATION_ERROR` includes `details: [{ in, path, message }]`. |
| Rate limits | `429` with a `Retry-After` header. Limits are per IP, per phone number and per user, depending on the endpoint. |
| Validation | Bodies are strict, so unknown fields are rejected (mass-assignment protection). Keys starting with `$` or containing `.` are stripped. |
| Request IDs | Every response carries `X-Request-Id`; quote it to support. |

## Payment outcomes

`POST /v1/payments` returns **202** with the transaction in `PENDING` (or `FAILED` if the provider rejects it outright). The final status arrives through:

1. the Socket.IO event `transaction.updated` on path `/realtime`, authenticated with `{ auth: { token } }`;
2. a push notification or the in-app notification `PAYMENT_SUCCESSFUL` / `PAYMENT_FAILED`;
3. polling `GET /v1/transactions/:id`, or asking the provider via `POST /v1/payments/:id/refresh-status`.

Clients must never treat a 202 as success.

## Provider webhooks

| Path | Authenticity |
|---|---|
| `POST /v1/callbacks/mock` | HMAC-SHA256 of the raw body in `X-Callback-Signature` (sandbox only) |
| `POST /v1/callbacks/daraja/:token/:kind` | Secret path token, source-IP allow-list and confirmation by STK query before success |
| `POST /v1/callbacks/card-issuer` | HMAC-SHA256 in `X-Issuer-Signature` |

Every callback is stored, deduplicated (by `provider` and `dedupeKey`) and processed exactly once. Invalid signatures get `401` or `403` and raise a `CALLBACK_REJECTED` security event.

## Real-time events (Socket.IO)

| Event | Payload |
|---|---|
| `transaction.updated` | Serialized transaction |
| `notification` | Serialized notification |

## Endpoint index

### Analytics

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/analytics/summary` | Income, spending and category breakdown for a week or month | user |
| `GET` | `/v1/analytics/trends` | Monthly income vs expenses | user |

### Auth

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | `/v1/auth/register` | Register with phone number | public |
| `POST` | `/v1/auth/verify-phone` | Verify phone OTP and sign in | public |
| `POST` | `/v1/auth/resend-otp` | Resend a verification code | public |
| `POST` | `/v1/auth/login` | Sign in with phone and password | public |
| `POST` | `/v1/auth/verify-device` | Complete sign-in on a new device | public |
| `POST` | `/v1/auth/refresh` | Rotate refresh token | public |
| `POST` | `/v1/auth/logout` | Sign out of the current session | user |
| `POST` | `/v1/auth/logout-all` | Sign out of all sessions | user |
| `POST` | `/v1/auth/password/forgot` | Request a password reset code | public |
| `POST` | `/v1/auth/password/reset` | Reset password with OTP | public |
| `POST` | `/v1/auth/password/change` | Change password | user |
| `POST` | `/v1/auth/pin` | Create transaction PIN | user |
| `POST` | `/v1/auth/pin/verify` | Verify transaction PIN | user |
| `POST` | `/v1/auth/pin/change` | Change transaction PIN | user |
| `POST` | `/v1/auth/pin/reset/request` | Request PIN reset code | user |
| `POST` | `/v1/auth/pin/reset` | Reset PIN with OTP and password | user |
| `POST` | `/v1/auth/email/request` | Send email verification code | user |
| `POST` | `/v1/auth/email/verify` | Verify email code | user |
| `POST` | `/v1/auth/recovery/start` | Start account recovery via verified email | public |
| `POST` | `/v1/auth/recovery/complete` | Submit a recovery case for manual review | public |

### Budgets

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/budgets/categories` | Expense and income categories | user |
| `GET` | `/v1/budgets/` | Active budgets with live progress | user |
| `POST` | `/v1/budgets/` | Create a weekly or monthly budget | user |
| `PATCH` | `/v1/budgets/{id}` | Edit a budget | user |
| `DELETE` | `/v1/budgets/{id}` | Delete a budget | user |
| `GET` | `/v1/budgets/expenses` | List manual expenses | user |
| `POST` | `/v1/budgets/expenses` | Record an expense | user |
| `PATCH` | `/v1/budgets/expenses/{id}` | Edit expenses entry | user |
| `DELETE` | `/v1/budgets/expenses/{id}` | Delete expenses entry | user |
| `GET` | `/v1/budgets/income` | List manual income | user |
| `POST` | `/v1/budgets/income` | Record income | user |
| `PATCH` | `/v1/budgets/income/{id}` | Edit income entry | user |
| `DELETE` | `/v1/budgets/income/{id}` | Delete income entry | user |
| `GET` | `/v1/budgets/recurring` | Recurring expenses and income | user |
| `POST` | `/v1/budgets/recurring` | Create a recurring expense or income | user |
| `DELETE` | `/v1/budgets/recurring/{id}` | Stop a recurring item | user |

### Cards

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/cards/` | My cards (tokenised; no card numbers) | user |
| `POST` | `/v1/cards/virtual` | Issue a virtual card via the issuing partner | user |
| `POST` | `/v1/cards/link` | Link an existing card using a PSP payment-method token | user |
| `POST` | `/v1/cards/{id}/freeze` | Freeze card | user |
| `POST` | `/v1/cards/{id}/unfreeze` | Unfreeze card | user |
| `PATCH` | `/v1/cards/{id}/controls` | Spending limits and channel controls | user |
| `POST` | `/v1/cards/{id}/secure-display` | Start an issuer secure-display session (PIN required) | user |
| `DELETE` | `/v1/cards/{id}` | Close a card | user |
| `GET` | `/v1/cards/{id}/transactions` | Card transactions | user |
| `POST` | `/v1/cards/{id}/simulate-authorization` | [SANDBOX] Simulate a merchant authorization through the issuer webhook path | user |

### Config

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/config/` | Public client configuration (countries, currencies, feature flags) | public |

### Dashboard

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/dashboard/` | Home dashboard (balances by provenance, month summary, savings, budget) | user |

### Insights

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/insights/monthly-report` | Monthly report with insights and budgeting suggestions | user |
| `GET` | `/v1/insights/unusual` | Unusually large transactions vs your typical spending | user |
| `GET` | `/v1/insights/patterns` | Spending by day of week | user |
| `POST` | `/v1/insights/recategorize` | Auto-categorise uncategorised transactions (local rules) | user |

### Linked accounts

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/accounts/` | Linked and manual accounts with balance provenance | user |
| `GET` | `/v1/accounts/institutions` | Institutions available for linking | user |
| `POST` | `/v1/accounts/link` | Link an account through an aggregator | user |
| `POST` | `/v1/accounts/manual` | Track an account manually (balance is user-entered) | user |
| `PATCH` | `/v1/accounts/{id}` | Rename, set default, or update a manual balance | user |
| `DELETE` | `/v1/accounts/{id}` | Unlink an account | user |
| `POST` | `/v1/accounts/{id}/refresh` | Refresh balance from provider | user |

### Notifications

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/notifications/` | In-app notifications | user |
| `POST` | `/v1/notifications/{id}/read` | Mark one notification read | user |
| `POST` | `/v1/notifications/read-all` | Mark all notifications read | user |

### Payments

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | `/v1/payments/` | Initiate a payment | user |
| `POST` | `/v1/payments/quote` | Preview fees for a payment | user |
| `GET` | `/v1/payments/options` | Payment types, providers and billers for my country | user |
| `POST` | `/v1/payments/{id}/refresh-status` | Ask the provider for the latest status | user |

### Profile

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/me/` | Current user and profile | user |
| `PATCH` | `/v1/me/profile` | Update profile | user |
| `PATCH` | `/v1/me/notification-preferences` | Update notification preferences | user |
| `PATCH` | `/v1/me/privacy` | Update privacy settings and consents | user |
| `POST` | `/v1/me/avatar/upload-url` | Get presigned avatar upload URL | user |
| `PUT` | `/v1/me/avatar` | Confirm uploaded avatar | user |
| `GET` | `/v1/me/avatar` | Get avatar URL | user |
| `GET` | `/v1/me/devices` | Trusted devices | user |
| `DELETE` | `/v1/me/devices/{id}` | Revoke a device | user |
| `PATCH` | `/v1/me/devices/current` | Update current device (push token, biometrics) | user |
| `GET` | `/v1/me/sessions` | Active sessions | user |
| `DELETE` | `/v1/me/sessions/{id}` | Revoke a session | user |
| `GET` | `/v1/me/limits` | Transaction limits | user |
| `PUT` | `/v1/me/limits` | Set personal transaction limits (cannot exceed regulatory limits) | user |
| `GET` | `/v1/me/kyc` | KYC status | user |
| `POST` | `/v1/me/kyc` | Submit identity verification | user |
| `POST` | `/v1/me/kyc/upload-url` | Presigned URL for an ID document | user |
| `GET` | `/v1/me/export` | Export my personal data | user |
| `POST` | `/v1/me/close` | Close account (data minimised; financial records retained per AML law) | user |

### Rewards

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/rewards/` | Rewards dashboard: points, cashback, offers, referral code | user |
| `GET` | `/v1/rewards/history` | Reward ledger history | user |
| `POST` | `/v1/rewards/redeem` | Redeem points | user |

### Savings goals

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/savings/goals` | List goals | user |
| `POST` | `/v1/savings/goals` | Create a savings goal | user |
| `GET` | `/v1/savings/analytics` | Monthly savings series | user |
| `GET` | `/v1/savings/goals/{id}` | Goal detail with analytics | user |
| `PATCH` | `/v1/savings/goals/{id}` | Edit a goal | user |
| `POST` | `/v1/savings/goals/{id}/archive` | Archive a goal | user |
| `POST` | `/v1/savings/goals/{id}/restore` | Restore an archived goal | user |
| `POST` | `/v1/savings/goals/{id}/contributions` | Record a contribution or withdrawal (tracking) | user |
| `GET` | `/v1/savings/goals/{id}/contributions` | Contribution history | user |

### Support

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | `/v1/support/tickets` | Open a support ticket | user |
| `GET` | `/v1/support/tickets` | My tickets | user |
| `GET` | `/v1/support/tickets/{id}` | Ticket detail | user |
| `POST` | `/v1/support/tickets/{id}/messages` | Reply to a ticket | user |

### Transactions

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/v1/transactions/` | List transactions with filters (cursor-paginated) | user |
| `GET` | `/v1/transactions/statement` | Download a statement (CSV or PDF, streamed) | user |
| `GET` | `/v1/transactions/{id}` | Transaction detail with status timeline | user |
| `GET` | `/v1/transactions/{id}/receipt` | Receipt for a completed transaction | user |
| `PATCH` | `/v1/transactions/{id}/category` | Re-categorise a transaction | user |

### Admin

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | `/admin/v1/dashboard` | Operational KPIs | admin |
| `GET` | `/admin/v1/users` | Search users | admin |
| `GET` | `/admin/v1/users/{id}` | User 360° view | admin |
| `POST` | `/admin/v1/users/{id}/suspend` | Suspend an account (revokes sessions) | admin |
| `POST` | `/admin/v1/users/{id}/reactivate` | Reactivate a suspended account | admin |
| `PUT` | `/admin/v1/users/{id}/restrictions` | Set account restrictions | admin |
| `POST` | `/admin/v1/users/{id}/revoke-sessions` | Sign a user out everywhere | admin |
| `GET` | `/admin/v1/kyc` | KYC review queue | admin |
| `GET` | `/admin/v1/kyc/{id}/id-number` | Reveal full ID number (audited) | admin |
| `POST` | `/admin/v1/kyc/{id}/decision` | Approve or reject a KYC submission | admin |
| `GET` | `/admin/v1/transactions` | Search transactions | admin |
| `GET` | `/admin/v1/transactions/{id}` | Transaction detail, events, callbacks, approvals | admin |
| `POST` | `/admin/v1/transactions/{id}/flag` | Flag or clear a transaction for investigation | admin |
| `POST` | `/admin/v1/transactions/{id}/check-status` | Query the provider for the authoritative status | admin |
| `POST` | `/admin/v1/transactions/{id}/reversal-requests` | Request a reversal (requires approval by a different admin) | admin |
| `GET` | `/admin/v1/approvals` | Maker-checker approvals | admin |
| `POST` | `/admin/v1/approvals/{id}/decision` | Approve or reject (cannot approve your own request) | admin |
| `GET` | `/admin/v1/callbacks` | Provider callback monitor | admin |
| `POST` | `/admin/v1/reconciliation/runs` | Run reconciliation for a provider and window | admin |
| `GET` | `/admin/v1/reconciliation/records` | Reconciliation results | admin |
| `POST` | `/admin/v1/reconciliation/records/{id}/resolve` | Record the resolution of an exception (does not alter transactions) | admin |
| `GET` | `/admin/v1/finance/summary` | Fee revenue, volumes, reversals and settlement view | admin |
| `GET` | `/admin/v1/providers` | Payment provider configuration | admin |
| `PUT` | `/admin/v1/providers/{code}` | Update provider config (fees, enabled, maintenance) | admin |
| `GET` | `/admin/v1/campaigns` | Reward campaigns | admin |
| `POST` | `/admin/v1/campaigns` | Create a reward campaign (as DRAFT) | admin |
| `PUT` | `/admin/v1/campaigns/{id}` | Edit a campaign (DRAFT or PAUSED only) | admin |
| `POST` | `/admin/v1/campaigns/{id}/status` | Activate, pause or end a campaign | admin |
| `GET` | `/admin/v1/referrals` | Referral tracking | admin |
| `GET` | `/admin/v1/notification-campaigns` | Notification campaigns | admin |
| `POST` | `/admin/v1/notification-campaigns` | Create and send/schedule a promotional notification (marketing-consent users only) | admin |
| `GET` | `/admin/v1/support/tickets` | Support queue | admin |
| `POST` | `/admin/v1/support/tickets/{id}/messages` | Reply to a ticket or add an internal note | admin |
| `GET` | `/admin/v1/security/events` | Security events and suspicious activity | admin |
| `POST` | `/admin/v1/security/events/{id}/acknowledge` | Acknowledge a security alert | admin |
| `GET` | `/admin/v1/audit-logs` | Tamper-evident audit log | admin |
| `GET` | `/admin/v1/audit-logs/verify` | Verify audit hash chain integrity | admin |
| `GET` | `/admin/v1/admins` | Administrators | admin |
| `POST` | `/admin/v1/admins` | Invite an administrator (temporary password, MFA enrollment forced) | admin |
| `GET` | `/admin/v1/roles` | Roles and permissions | admin |
| `PATCH` | `/admin/v1/admins/{id}` | Change roles, disable, or reset MFA | admin |

### Admin: Auth

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | `/admin/v1/auth/login` | Admin sign-in step 1 (password) | public |
| `POST` | `/admin/v1/auth/mfa/setup` | Get a TOTP secret for first-time MFA enrollment | public |
| `POST` | `/admin/v1/auth/mfa/enroll` | Confirm MFA enrollment and sign in | public |
| `POST` | `/admin/v1/auth/mfa/verify` | Admin sign-in step 2 (TOTP) | public |
| `GET` | `/admin/v1/auth/me` | Current admin and permissions | admin |
| `POST` | `/admin/v1/auth/logout` | Sign out | admin |
| `POST` | `/admin/v1/auth/password` | Change own password | admin |
