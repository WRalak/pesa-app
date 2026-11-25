# Operations runbook

## Payment failures

**Alert:** `PaymentFailureRateHigh` (more than 20% failing for 10 minutes).

1. Admin → Dashboard → *Provider performance*: is one provider degraded?
2. Admin → Provider callbacks, filter `ERROR` or `REJECTED`. A spike in `REJECTED` means a signature or IP problem (see below).
3. Check `statusReason` on recent failed transactions (Admin → Transactions → status FAILED). Common causes: user cancelled, insufficient funds (normal), provider timeouts (incident).
4. If the provider is down, set it to **maintenance** (Finance → Providers → Configure). Users get a clear "temporarily unavailable" message.

## Rejected callbacks

**Alert:** `CallbacksRejected`. Callbacks are failing verification.

- **Mock or card issuer:** the webhook secret doesn't match the partner's configuration. Verify `MOCK_PROVIDER_WEBHOOK_SECRET` or the issuer secret.
- **Daraja:** either the source IP isn't in `DARAJA_ALLOWED_IPS` (Safaricom changed ranges), or the path token is wrong. **Never** relax verification to "make it work". Pending payments are still resolved safely by the status sweeper while you fix it.
- A sudden burst from unknown IPs suggests spoofing: add a WAF block rule and inform security.

## Stuck pending payments

Admin → Dashboard → *Stuck pending (>15 min)*. The sweeper queries providers every minute (up to 30 checks), then flags `STUCK_PENDING` after 24 hours.

1. Open the transaction and click **Check with provider**.
2. If the provider has no record and the outcome is still unknown, leave it for **reconciliation**. Don't change the status by hand; the platform doesn't allow it.

## Reconciliation exceptions

Admin → Reconciliation → OPEN.

| Result | Meaning | Action |
|---|---|---|
| `STATUS_MISMATCH` | We have a terminal status the provider disagrees with | Investigate with the provider; if money moved wrongly, raise a reversal (maker-checker) |
| `AMOUNT_MISMATCH` | Provider amount ≠ our amount | Hold for review; involve the provider; consider an STR if it's suspicious |
| `MISSING_AT_PROVIDER` | We show success, the provider has no record | Escalate to the provider urgently |
| `MISSING_INTERNAL` | Provider shows a payment we have no record of | Check orphaned callbacks; escalate |

Record the outcome with **Resolve** or **Escalate**, which writes to the audit log.

## Reversal (refund) requests

1. Finance admin A: Transaction → **Request reversal** (a reason is required).
2. Finance admin B: Approvals → **Approve reversal**. The system enforces a different approver.
3. The provider processes it. The status becomes `REVERSED` only on provider confirmation, and rewards are clawed back automatically.

## Account takeover report

1. Admin → Users → the user → **Sign out everywhere**, then **Suspend** (reason: "Reported ATO").
2. Review security events (new devices, IPs) and recent transactions; flag any suspicious ones.
3. Verify the customer's identity against KYC via support, then reactivate and ask them to reset their password and PIN.

## Account recovery (lost SIM or number)

Support → tickets with category `ACCOUNT_RECOVERY`. Verify identity against the KYC record (compliance can reveal the ID number, which is audited), and confirm with the mobile network that the SIM swap or registration is genuine **before** any number change. Treat urgency and pressure as fraud signals.

## Secret rotation

| Secret | Procedure |
|---|---|
| `JWT_ACCESS_SECRET` / `JWT_ADMIN_SECRET` | Update in Secrets Manager, then redeploy. Users re-authenticate silently through refresh; admins sign in again |
| `DARAJA_*` | Rotate in the Safaricom portal, update the secret, redeploy |
| `FIELD_ENCRYPTION_KEY` | Add a new versioned key, run the re-encryption job, then retire the old key (see SECURITY.md) |
| Redis AUTH | Terraform `random_password` taint, apply, redeploy |

## Useful commands

```bash
npm run audit:verify        # verify the audit hash chain
node scripts/migrate.js     # ensure indexes + seed (idempotent)
curl -H "Authorization: Bearer $METRICS_TOKEN" https://<internal>/metrics
```
