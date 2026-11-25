# Implementation plan and status

| Phase | Scope | Status |
|---|---|---|
| 1 | Architecture, project structure, design system, authentication | ✅ Done: Express API foundation, validated config, security middleware, full auth (OTP, device step-up, rotating refresh, lockouts, PIN, recovery); Flutter theme, tokens and auth flows |
| 2 | Home dashboard, profile, navigation, activity | ✅ Done: dashboard with balance provenance, profile/KYC/devices/sessions/limits/privacy, 5-tab shell, activity with search, filters, receipts and statements |
| 3 | Payments architecture and sandbox integrations | ✅ Done: provider abstraction, mock (signed) and Daraja adapters, state machine, callbacks, sweeper, reversals, reconciliation, fees, risk rules |
| 4 | Savings, budgeting, financial analytics | ✅ Done: goals and contributions, budgets and alerts, manual and recurring entries, analytics, local insights, consent-gated AI narrative |
| 5 | Cards, rewards, notifications | ✅ Done: tokenised cards with controls and issuer webhooks, campaigns, points, cashback, referrals; FCM, in-app and Socket.IO notifications |
| 6 | Administrative backend | ✅ Done: MFA admin auth, RBAC (7 roles), operations, finance, compliance and security APIs, maker-checker; React console |
| 7 | Security hardening, testing, DevSecOps | ✅ Done: 118 backend + admin + mobile tests, CI, CodeQL, audit, gitleaks, Trivy, Checkov, Dependabot; hardened containers |
| 8 | Production deployment preparation | ✅ Done: Terraform (AWS af-south-1), deploy pipeline with OIDC and circuit-breaker rollback, migrations, observability, DR and runbooks, compliance mapping |

## How it was verified

- The backend suite runs against a real MongoDB replica set and Redis, including concurrency tests for idempotency, contributions, recurring jobs and redemptions.
- The API and worker were booted against live MongoDB and Redis. A payment went API → BullMQ → signed callback → `SUCCESSFUL` → notification.
- The admin console was driven in a browser against the live API, including first-time MFA enrolment.
- The Flutter app was compiled (a web build used only for automated UI checks) and driven through: login → device OTP → dashboard → airtime payment approved with the PIN pad → live "Payment successful". These checks caught and fixed an inaccessible OTP field and a duplicated navigation push.
- The API container image was built and run read-only as non-root with all capabilities dropped.

## Before production

These depend on partners, legal work or people, not code:

1. **Licensing and contracts.** Confirm the CBK pathway (see [COMPLIANCE.md](COMPLIANCE.md)); sign agreements with Safaricom (Daraja production shortcode), an aggregator for B2C and bank payouts, a card issuer, and an account-aggregation partner.
2. **Adapters needing partner SDKs or credentials:** a production account aggregator (the interface is in `accounts/aggregators.js`), the card issuer (`cards/issuers.js`, including its secure-display SDK in the app), Daraja B2C for send-money (the STK, query and reversal adapter is implemented), and the Africa's Talking SMS sender (implemented; needs credentials).
3. **KYC:** IPRS verification, sanctions and PEP screening, document capture UI with liveness, and a goAML STR export.
4. **Mobile:** add Firebase configs per environment; certificate pinning; Play Integrity / App Attest; run `tool/fetch_fonts.sh`; migrate FCM to the `register()`/`onRegistered` API together with the server sender.
5. **Security:** external penetration test; DPIA; ODPC registration; an Atlas custom role that removes update and delete rights on append-only collections.
6. **Load test** on staging at the target scale and tune pool sizes and autoscaling.
