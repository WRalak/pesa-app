# Compliance preparation (Kenya)

> **Important.** This document maps product and engineering controls to Kenyan requirements to help prepare for legal review. It is **not legal advice**, and Pesa is **not** represented as authorised to provide regulated financial services. Before launch, qualified Kenyan counsel must confirm the licensing pathway and each obligation below.

## Licensing position

Pesa is designed as a **technology and financial-management platform** that:

- does **not** hold, pool or move customer funds on its own balance sheet (no wallet, no stored value);
- routes payment instructions to **licensed** payment service providers, and only for flows the provider actually performs (Daraja STK Push is used solely to collect into the partner's own account) (for example Safaricom M-Pesa through Daraja under a merchant or aggregator agreement, licensed PSP aggregators, and licensed card issuers);
- treats savings goals as **tracking tools**, with custody (when offered) provided by an authorised partner such as a bank or a SACCO licensed by SASRA.

Points to confirm with counsel and the CBK:

1. Whether payment initiation through partners, and cashback paid by partners, require Pesa to hold a PSP authorisation under the **National Payment System Act, 2011** and the **National Payment System Regulations, 2014**, or whether operating as an agent or technical service provider of a licensed PSP is enough.
2. Whether any product (for example virtual cards or rewards with monetary value) triggers e-money issuance.
3. Partner contracts allocating responsibility for KYC, AML monitoring, complaints, chargebacks and reversals.
4. Registration with the **Office of the Data Protection Commissioner (ODPC)** as a data controller and processor.

## Data Protection Act, 2019 (and the 2021 Regulations)

| Requirement | Implementation |
|---|---|
| Lawful basis and consent (s.30, s.32) | Terms and privacy acceptance recorded with version and timestamp (`users.consents`); separate, revocable consents for marketing, smart insights and external AI processing; marketing is off by default |
| Data minimisation (s.25) | Only the needed PII is collected; callbacks store sanitised payloads (no payer phone); notification and OTP TTLs; masked admin views |
| Privacy by design (s.41) | Field-level encryption, PII masking, role-based reveal with an audit trail, local-only insights by default |
| Data subject rights (s.26, s.38, s.40) | Access and portability (`GET /v1/me/export`); correction (profile edit, or via support once KYC is locked); erasure (`POST /v1/me/close` minimises PII and keeps legally required records pseudonymised); objection to marketing (consent toggle) |
| Automated decision-making (s.35) | Risk rules can block or flag a payment. The user is told to contact support, and a human reviews flags. Rules are documented in `payments/risk.js`. Insights are advisory only |
| Security (s.41, s.42) | See [SECURITY.md](SECURITY.md) |
| Breach notification (s.43) | ODPC within **72 hours**, and affected users without undue delay. See the incident procedure in [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md#incident-response) |
| Cross-border transfers (s.48–50) | Hosting is in AWS `af-south-1` (South Africa) and Atlas in the same region. This needs documented safeguards or ODPC approval, so confirm with counsel. If transfers aren't approved, an option is a Kenyan-hosted region or provider. External AI receives only aggregated, de-identified figures, and only with explicit consent |
| DPIA (s.31) | Required: high-risk processing (financial data, profiling for risk and insights). Template: purpose, data flows, risks, mitigations, residual risk, DPO sign-off |
| DPO and register | Appoint a Data Protection Officer; keep a processing register |

## AML/CFT — Proceeds of Crime and Anti-Money Laundering Act (POCAMLA) and regulations

| Obligation | Implementation / preparation |
|---|---|
| Customer due diligence | Tiered KYC (`TIER_0` → `TIER_2`) with country-configured limits; ID capture with encrypted storage; duplicate-ID detection (`idNumberHash`) raises a `FRAUD_FLAG` and puts the account under review. **To integrate:** IPRS (Integrated Population Registration System) verification through the partner or a KYC provider, and sanctions and PEP screening |
| Ongoing monitoring | Velocity rules, new-device/large-amount rules, amount-mismatch holds, admin review queue (`risk.reviewRequired`), security events |
| Record keeping (7 years) | Immutable transactions and events, callbacks, reconciliation records and audit logs; retention documented in [DATABASE.md](DATABASE.md#retention) |
| Suspicious transaction reporting (to the FRC) | The compliance officer role can investigate and flag. **To add:** an STR case workflow and export in the FRC goAML format |
| Restrictions | Admins can apply `NO_PAYMENTS`, `NO_LOGIN` and `REVIEW_REQUIRED`, or suspend accounts (all audited) |

## Consumer protection

The relevant law includes the **Consumer Protection Act, 2012**, the **CBK Prudential Guidelines** and its consumer-protection guidance for PSPs, and the **Kenya Information and Communications (Consumer Protection) Regulations**.

- Fees are disclosed **before** confirmation (the quote screen and confirm sheet). Fees are configuration and changes to them are audited.
- Receipts carry the reference, the provider receipt, amount, fee and time. Statements can be downloaded as PDF or CSV.
- Every transaction screen links to complaint handling ("Report a problem" creates a ticket), with ticket references and status tracking.
- Marketing goes only to consenting users; security alerts can't be turned off.
- Clear language: the app states that Pesa does not hold funds, that payments are processed by licensed partners, and that insights are not financial advice.
- Sandbox environments are permanently labelled, so test data can't be mistaken for real money.

## Card data — PCI DSS scope reduction

No PAN or CVV ever reaches Pesa systems. Linking uses PSP tokens (raw card numbers are rejected by validation), and viewing details uses the issuer's PCI-scoped secure display. That limits Pesa to roughly SAQ A scope. Confirm with the issuer and a QSA.

## Open items before launch

- Legal opinion on the licensing pathway and partner agreements.
- ODPC registration, a DPIA, a privacy notice, and the cross-border transfer assessment.
- KYC and IPRS integration, sanctions and PEP screening, and the STR workflow.
- Complaint-handling SLA and escalation to the CBK or the partner.
- External penetration test and remediation.
