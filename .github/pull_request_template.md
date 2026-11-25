## What & why

## How it was tested
- [ ] Unit/integration tests added or updated
- [ ] Ran locally against the Docker Compose stack

## Financial & security checklist
- [ ] Amounts use integer minor units (no floats)
- [ ] No payment status set from client input — only provider confirmation/reconciliation
- [ ] New endpoints validate input (zod), enforce auth/permissions, and are rate limited where abusable
- [ ] No secrets, OTPs, PINs or PII in logs
- [ ] Privileged admin actions are audited
