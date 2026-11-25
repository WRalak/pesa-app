# Backup, disaster recovery and incident response

## Objectives

| Tier | Component | RPO | RTO |
|---|---|---|---|
| 1 | Payments ledger (MongoDB) | ≤ 1 minute (continuous backup, PITR) | 1 hour |
| 1 | API / worker (stateless) | n/a | 30 minutes (redeploy from immutable images) |
| 2 | Redis (rate limits, queues, cache) | 24 hours (snapshots); content is reconstructible | 30 minutes |
| 2 | S3 uploads (KYC documents, avatars) | 0 (versioned, KMS); cross-region replication recommended for prod | 1 hour |
| 3 | Admin console (static) | n/a | 30 minutes |

Redis loss is **safe by design**. Queued jobs are re-created by the schedulers. Pending payments are resolved by the status sweeper and reconciliation, which read MongoDB and the provider. Idempotency also has a MongoDB copy (`idempotencykeys`). Revocation deny-list entries only last 15 minutes, and refresh still re-checks the session in MongoDB.

## Backups

- **MongoDB Atlas:** continuous cloud backup with point-in-time restore (7-day window) plus daily snapshots kept for 35 days and monthly snapshots for 12 months. A copy policy sends snapshots to a second region. Snapshots are encrypted with the customer KMS key.
- **S3:** versioning plus an Object Lock (governance) lifecycle on `kyc/`. Prod uses cross-region replication.
- **Redis:** automatic daily snapshots (7 days in prod).
- **Configuration:** everything is in Git (Terraform, workflows); secrets are in Secrets Manager (replicated to the DR region).

**Restore drills** run quarterly: restore the Atlas PITR to a scratch cluster, run `npm run audit:verify` (audit chain integrity) and the reconciliation report against provider settlement files, and record the time taken against the RTO.

## Scenarios

### Bad deploy
The ECS circuit breaker rolls back automatically. To roll back by hand, redeploy the previous SHA ([DEPLOYMENT.md](DEPLOYMENT.md#release-pipeline-githubworkflowsdeployyml)).

### Data corruption or accidental deletion
1. Freeze writes: scale `api` and `worker` to 0, or enable maintenance mode for all providers in the admin console.
2. Restore Atlas PITR to a new cluster at the last good timestamp.
3. Diff the affected collections. Append-only collections and the audit chain identify tampering precisely (`verifyAuditChain` reports `brokenAt`).
4. Repoint `MONGODB_URI` (Secrets Manager), then redeploy.
5. Run reconciliation over the affected window. Provider settlement data is the source of truth for outcomes.

### Region outage (af-south-1)
1. Promote the Atlas cross-region copy (or a multi-region cluster's secondary) in the DR region.
2. `terraform apply` in the DR region using the same modules (`region` and `azs` variables), with replicated secrets and ECR replication.
3. Move DNS (Route 53 health-checked failover) for `api.` and update the Daraja callback registration.
4. Clients retry with the same idempotency keys. Nothing double-charges, because providers deduplicate and our unique indexes hold.

### Provider outage
Put the provider in **maintenance** in the admin console (Finance → Providers). New payments fail fast with a clear message, or route to an alternate provider by priority. Pending payments resolve when the provider recovers, through the sweeper and reconciliation. Nothing is ever marked failed or successful on assumption.

## Incident response

1. **Detect:** alerts (5xx, latency, callback rejections, payment failure rate), Sentry, security events, customer reports.
2. **Triage (15 min):** assign an incident commander, set the severity, open an incident channel and timeline.
3. **Contain:** revoke sessions (per user or all), suspend accounts, disable providers, rotate secrets, block IPs in the WAF.
4. **Eradicate and recover:** fix, deploy, reconcile, verify the audit chain.
5. **Notify:**
   - Personal data breach: **ODPC within 72 hours** (DPA s.43); affected data subjects without undue delay.
   - Payment incidents: the partner PSP or bank, and the CBK, as the partner agreement and regulations require.
   - Suspicious activity: the FRC (via the compliance officer).
6. **Post-incident review** within 5 business days: root cause, actions, and updates to this document.
