# Deployment

## Environments

| | dev | staging | prod |
|---|---|---|---|
| Purpose | Engineers, local and shared dev | Release candidates, partner sandbox testing, load tests | Customers |
| Payment providers | `mock` | `mock,daraja` (Daraja **sandbox**) | `daraja` (production credentials) — `mock` refused |
| OTP outbox | allowed | refused | refused |
| Data | Synthetic | Synthetic only — never copies of production data | Real |
| Deploy trigger | Local / Compose | Every merge to `main` | Manual dispatch + required reviewers (GitHub Environment `prod`) |

The API refuses to start in staging or production with development secrets, the mock provider (prod) or the OTP outbox enabled (`src/config/env.js`).

## One-time setup (per AWS account)

1. Create the Terraform state bucket and lock table (`pesa-terraform-state-<acct>`, `pesa-terraform-locks`).
2. Create a GitHub OIDC deploy role with permissions scoped to ECR push, ECS, Terraform-managed resources, and `iam:PassRole` for the task roles. Set the repository variable `AWS_DEPLOY_ROLE_ARN`.
3. Provision **MongoDB Atlas** (M30+, `af-south-1`, PrivateLink to the VPC, customer KMS, continuous backup / PITR). Create two database users:
   - `pesa-app`: readWrite on `pesa`, **minus** `update`/`remove` on `transactionevents`, `auditlogs`, `rewards`, `savingscontributions` (custom role);
   - `pesa-migrate`: adds `createIndex`.
   Store the SRV URI in Secrets Manager (`pesa-<env>/mongodb-uri`).
4. Request ACM certificates for the API and admin domains.
5. `terraform apply` (see `infrastructure/terraform/README.md`).
6. Populate the application secret:

```bash
aws secretsmanager put-secret-value --secret-id pesa-prod/app --secret-string "$(jq -n \
  --arg a "$(openssl rand -base64 48)" --arg b "$(openssl rand -base64 48)" \
  --arg p "$(openssl rand -base64 48)" --arg k "$(openssl rand -base64 32)" \
  --arg c "$(openssl rand -hex 24)" --arg m "$(openssl rand -hex 32)" \
  '{JWT_ACCESS_SECRET:$a, JWT_ADMIN_SECRET:$b, HASH_PEPPER:$p, FIELD_ENCRYPTION_KEY:$k,
    DARAJA_CALLBACK_TOKEN:$c, METRICS_TOKEN:$m, MOCK_PROVIDER_WEBHOOK_SECRET:"unused-in-prod",
    DARAJA_CONSUMER_KEY:"…", DARAJA_CONSUMER_SECRET:"…", DARAJA_SHORTCODE:"…", DARAJA_PASSKEY:"…", SENTRY_DSN:"…"}')"
```

7. Register the Daraja callback URL `https://<api-domain>/v1/callbacks/daraja/<DARAJA_CALLBACK_TOKEN>/stk` and set `DARAJA_ALLOWED_IPS` to Safaricom's published callback IP ranges.
8. Create the first administrator with a one-off task: `SEED_ADMIN_EMAIL=… SEED_ADMIN_PASSWORD=… node scripts/seed.js`. They are forced to enrol MFA and change the password at first sign-in.

## Release pipeline (`.github/workflows/deploy.yml`)

1. CI (lint, tests, typecheck, Flutter analyze/test, Terraform validate) and the security workflow (CodeQL, audit, gitleaks, Trivy, Checkov) must pass on the PR.
2. On merge: build ARM64 images with SBOM and provenance and push to ECR. Tags are immutable (the git SHA).
3. Run `scripts/migrate.js` as a one-off ECS task: non-destructive index build and idempotent seed.
4. `terraform apply` with the new `image_tag`. ECS rolls tasks over; the **deployment circuit breaker** rolls back automatically if new tasks fail their health checks.
5. Wait for services to stabilise, then run the smoke test (`/health/ready`).

**Rollback:** re-run the deploy workflow with the previous SHA (`workflow_dispatch`), or `aws ecs update-service --task-definition <previous revision>`. Schema changes are additive (expand, then contract) so older images keep working.

## Mobile release

- Flavours come from `--dart-define`: `ENV`, `API_BASE_URL`, `APP_VERSION`.
- Firebase: add `google-services.json` and `GoogleService-Info.plist` per environment at build time from CI secrets. They are not committed. Without them the app runs with in-app notifications only.
- Signing: keep the upload keystore and iOS certificates in CI secrets (never in the repo). Use Play App Signing.
- Build: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.pesa.africa`. Upload the symbols to Sentry or Crashlytics.
- Roll out through staged Play rollouts (5%, 20%, 50%, 100%) and TestFlight, then phased release. Enforce `minSupportedAppVersion` from `GET /v1/config`.
- Fonts: run `mobile/tool/fetch_fonts.sh` (Satoshi, ITF Free Font License) and uncomment the `fonts:` block in `pubspec.yaml`.

## Admin console access

The console and `/admin/v1` sit behind the **internal** ALB only. The public ALB returns 404 for `/admin/*`. Staff reach it through the corporate VPN or a ZTNA provider whose egress ranges are in `admin_allowed_cidrs`. Every admin needs TOTP MFA. Disabled admins and MFA resets revoke sessions immediately.

## Observability

- Logs: CloudWatch (`/pesa/<env>/{api,worker,admin}`), KMS-encrypted, retained for 1 year in prod.
- Metrics: `/metrics` (Prometheus format, needs a `METRICS_TOKEN` bearer, and is blocked at the public edge), plus ALB, ECS and ElastiCache metrics. Alert rules are in `infrastructure/monitoring/alerts.yml`, and CloudWatch alarms are in Terraform.
- Traces: OpenTelemetry (`OTEL_ENABLED=true`) to the collector, then your APM or X-Ray.
- Errors: Sentry (`SENTRY_DSN`), with PII stripped.
