# Security

## Threat model (summary)

| Threat | Main controls |
|---|---|
| Account takeover (credential stuffing, SIM swap, stolen phone) | Argon2id passwords; per-IP and per-phone rate limits; account lockout; device binding with OTP step-up on new devices; new-device and suspicious-login alerts; transaction PIN with lockout; biometric app lock with 2-minute auto-lock; phone-number changes go through manual recovery review |
| Session theft | 15-minute access tokens; opaque refresh tokens stored only as HMACs, rotated on every use; replaying an old token revokes the session (`REFRESH_TOKEN_REUSE`, critical); server-side revocation through a Redis deny-list; device mismatch on refresh revokes the session |
| Payment fraud and spoofed confirmations | Success only from verified provider data; HMAC-signed webhooks (or path token, IP allow-list and a confirmation query for Daraja); callback dedupe; amount-mismatch holds; velocity and new-device risk rules; KYC-tiered limits; duplicate-payment guard |
| Double charging and replays | Idempotency keys (Redis lock plus stored response plus unique DB index); a client policy to reuse keys only when the outcome is unknown |
| Insider abuse | Separate admin plane; mandatory TOTP MFA with replay protection; RBAC with least-privilege roles; PII masking unless the role holds `users.pii.read`; audited ID reveals; maker-checker reversals (a different approver is enforced); no endpoint edits successful transactions; hash-chained, append-only audit log; the admin console runs on an internal network only |
| Data breach | TLS 1.2+/1.3 everywhere; KMS encryption at rest (Atlas, S3, Redis, logs); AES-256-GCM field encryption for KYC ID numbers and TOTP secrets; HMAC lookups for OTPs and tokens; no PAN, CVV or M-Pesa PIN ever stored or collected; log redaction |
| Injection and API abuse | zod schemas on every route with strict bodies; `$` and `.` key stripping; escaped user regex; CSV formula neutralisation; Helmet headers; a CORS allow-list; body size limits; WAF managed rules and IP rate limiting |

## OWASP API Security Top 10 (2023) mapping

| Risk | Implementation |
|---|---|
| API1 Broken object-level authorization | Every query is scoped by `userId` from the token (for example `findOne({_id, userId})`); cross-user access returns 404. Tests: "isolates users…", "keeps goals private…", "isolates cards…" |
| API2 Broken authentication | See above. Tests cover forged and `alg:none` tokens, revocation, rotation and reuse, lockouts and OTP attempt limits |
| API3 Broken object-property-level authorization | Strict bodies reject unknown fields (`status`, `kycTier`…); serializers whitelist output fields; secrets use `select: false` |
| API4 Unrestricted resource consumption | Redis rate limits per IP, phone and user; capped page sizes (100); a 12-month statement cap; streamed exports; body limits; WAF rate rules |
| API5 Broken function-level authorization | Admin routes require an MFA-backed admin JWT (separate secret and audience) plus explicit permissions; RBAC tests per role |
| API6 Unrestricted access to sensitive business flows | Velocity blocking, duplicate-payment confirmation, OTP issuance caps (3 per 10 min, 10 per day), referral abuse detection (shared device, caps), campaign budgets |
| API7 SSRF | The server never fetches user-supplied URLs; provider endpoints are fixed configuration |
| API8 Security misconfiguration | A production gate (`deploymentProblems()` in `config/env.js`, unit-tested) refuses to start staging or production with dev secrets, identical user/admin JWT secrets, console SMS or email, the mock provider (prod), Daraja without IP allow-list or a strong callback token, non-https URLs, or a missing metrics token; Swagger is off in production; the edge ALB blocks `/admin`, `/metrics` and `/docs` |
| API9 Improper inventory management | Versioned `/v1`; a generated OpenAPI spec checked in CI; a single route table |
| API10 Unsafe consumption of APIs | Provider responses are parsed defensively; unknown outcomes are never assumed; amounts are cross-checked against our ledger; timeouts on every outbound call |

## Cryptography

| Use | Algorithm |
|---|---|
| Passwords, PINs | Argon2id (m=19 MiB, t=2, p=1; OWASP minimum) |
| OTPs, refresh tokens, lookup keys | HMAC-SHA256 with a server-side pepper (Secrets Manager) |
| KYC ID numbers, TOTP secrets | AES-256-GCM with versioned keys (`v1:` prefix to support rotation) |
| Access tokens | HS256 JWT with separate secrets for users and admins, issuer and audience checked, algorithm pinned |
| Webhooks | HMAC-SHA256 over the raw body, compared in constant time |
| Admin MFA | RFC 6238 TOTP (SHA-1, 6 digits, 30 s, ±1 step), with the last-used step stored to block replay |

**Key rotation:** JWT secrets rotate by deploying the new secret and letting existing tokens expire (15 min for users, 30 min for admins). Field-encryption keys are versioned: add `v2`, re-encrypt in a background job, then retire `v1`. The HMAC pepper can't be rotated in place for existing OTP and refresh hashes, so it is rotated by forcing re-login.

## Secrets management

- Nothing secret is in the repository or in Terraform state. Values live in AWS Secrets Manager (KMS) and are injected as ECS task secrets.
- The mobile app contains no secrets; build-time `--dart-define` values are public configuration only.
- CI/CD authenticates to AWS with OIDC (no long-lived keys). Secret scanning (gitleaks) runs on every push.

## Logging and monitoring

- Structured JSON logs (pino) with central redaction of passwords, PINs, OTPs, tokens, ID numbers, card data and auth headers. Phone numbers are masked in logs.
- Sentry runs with `sendDefaultPii: false` and request bodies stripped. OpenTelemetry traces pass through a collector that deletes auth and idempotency headers.
- Security events cover login failures, lockouts, new devices, token reuse, PIN locks, rejected callbacks, fraud flags and admin logins. High and critical events surface on the admin dashboard and through alerts.

## Mobile app

Tokens are stored in the Android Keystore or iOS Keychain (`first_unlock_this_device`). Biometrics unlock the local session only and never replace the server-verified PIN for payments. The PIN pad is custom, so no system keyboard, clipboard or suggestions are involved. `FLAG_SECURE` blocks screenshots and recents previews. App backups are disabled. Release builds are HTTPS-only with system CAs (no user CAs). The app auto-locks in the background, and a sandbox banner appears in every non-production build. **TLS pinning** is implemented: staging and production builds trust only the Amazon Trust Services roots that ACM chains to (`mobile/assets/certs/trusted_roots.pem`, installed via `HttpOverrides`, so Dio and the WebSocket both use it). Root-level pinning survives ACM's automatic renewals; if the API ever leaves ACM, update the bundle and ship an app release *first*. Non-dev builds refuse to start without an `https://` API URL. Recommended before launch: Play Integrity / App Attest, and root/jailbreak signals fed into the risk engine.

## Vulnerability management

CodeQL (security-extended), `npm audit` (high and above fails), dependency review on PRs, Trivy container scans (critical and high fail), Checkov IaC scans, Dependabot, and ECR scan-on-push. Before go-live: an external penetration test (API, mobile, admin) and a re-test every year and after major changes.

## Reporting

Report vulnerabilities to security@pesa.africa. Don't open public issues for security problems.
