# Pesa — money management for Africa

Pesa is a mobile-first financial super-app for Kenya, built to expand across Africa. It combines payments (M-Pesa-oriented), verified account balances, savings goals, budgeting, financial insights, cards, rewards and notifications. A separate web console covers operations, finance, compliance and security staff.

> **Regulatory position.** Pesa is software for managing money. It is **not** a bank, an e-money issuer or a licensed payment service provider, and nothing in this repository represents it as legally authorised to provide regulated financial services. Payments are designed to run through licensed partners (e.g. Safaricom Daraja, licensed aggregators and card issuers). Pesa never holds customer funds. See [docs/COMPLIANCE.md](docs/COMPLIANCE.md).

## Repository layout

| Path | What it is |
|---|---|
| [`mobile/`](mobile) | Flutter customer app (Riverpod 3, GoRouter, Dio, Freezed, Material 3, English and Swahili) |
| [`backend/`](backend) | Node.js 22 / Express 5 API and BullMQ worker (MongoDB, Redis, Socket.IO, OpenAPI) |
| [`admin/`](admin) | Web admin console (React 19, TypeScript, Vite), deployed on an internal network only |
| [`infrastructure/`](infrastructure) | Docker Compose, Terraform (AWS af-south-1), OpenTelemetry, alert rules, k6 load tests |
| [`docs/`](docs) | Architecture, API, database, security, compliance, deployment, DR, runbook, testing |
| [`.github/`](.github) | CI, security scanning, deployment pipelines, Dependabot, CODEOWNERS |

## Quick start (local, sandbox)

Requirements: Docker, Node 22, Flutter 3.50+.

```bash
cp backend/.env.example backend/.env      # fill in the secrets (generation commands are in the file)
cd infrastructure/docker
docker compose up --build -d              # MongoDB replica set, Redis, MinIO, API, worker, admin
docker compose --profile seed run --rm seed   # roles, providers, starter campaigns
```

- API: http://localhost:4000. Swagger UI is at `/docs`, the spec at `/openapi.json`.
- Admin console: http://localhost:8081. To create the first admin, run the seed with `SEED_ADMIN_EMAIL` and `SEED_ADMIN_PASSWORD` set. MFA enrolment is required on first sign-in.
- In development, `GET /v1/auth/dev/outbox` shows OTPs that would have been sent by SMS. It is refused in staging and production.

Run the mobile app against the local API (Android emulator):

```bash
cd mobile
flutter pub get && dart run build_runner build -d && flutter gen-l10n
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

Everything outside production uses **sandbox providers**. The mock provider sends HMAC-signed webhooks and simulates outcomes from the amount's minor-unit ending (`.01` fails, `.02` never calls back, `.03` is cancelled), and the app shows a permanent "SANDBOX — NO REAL MONEY" strip.

## Tests

```bash
cd backend && npm test        # 136 tests: auth, payments, callbacks, idempotency, RBAC, security, finance, prod config gate
cd admin   && npm test        # component tests (+ npm run typecheck)
cd mobile  && flutter test    # unit + widget tests (+ flutter analyze)
```

The backend tests run against an in-memory MongoDB **replica set** (needed for transactions) and a disposable Redis. Load tests are in [`infrastructure/k6`](infrastructure/k6). See [docs/TESTING.md](docs/TESTING.md).

## Key design decisions

- **Money is never a float.** All amounts are integer minor units, plus an ISO currency and an exact decimal string. Currency precision is configured per currency (UGX and RWF have none).
- **Only providers decide outcomes.** A payment becomes `SUCCESSFUL` only after a verified provider callback, a provider status query or reconciliation. Every status change is a compare-and-set transition, written together with an append-only event in a MongoDB transaction.
- **Idempotency everywhere money moves.** `Idempotency-Key` headers, a unique index per user and key, deduplicated callbacks and dedupe-keyed reward ledgers.
- **Balances by provenance.** Each balance is labelled as verified (from a provider), manual (entered by the user) or estimated (a summary).
- **Country-agnostic core.** Kenya is configuration (`backend/src/config/countries/KE.js`): limits, providers, payment types, billers and regulators.
- **Separate admin plane.** Its own JWT audience and secret, mandatory TOTP MFA, RBAC, maker-checker reversals, a hash-chained audit log and an internal-only network path.

## Status

All eight phases are implemented and tested. Production go-live still depends on items that need partners or people: licensed partner contracts and production credentials, a production account-aggregation adapter, the card-issuer SDK, a penetration test and the legal sign-off listed in [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md#before-production).
