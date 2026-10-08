# Week 1 — Setup + IAM fundamentals (Domain 4, 20%)

## Goal
Three accounts set up safely. Can write and explain identity policy, resource policy, and permission boundary, and assume a cross-account role via CLI.

## Checklist
### Setup (Saturday, hour 1)
- [x] Accounts (Sep 22): org-management `333344445555`, general `111122223333`, production `222233334444`. Org `o-exampleorgid`. Home region `us-east-2`.
- [x] Management root: MFA on, no keys, no IAM users. Member roots: **centralized root access enabled** (RootCredentialsManagement + RootSessions) — no root creds exist in member accounts. Stale 2025 `AKIA…` key retired from laptop.
- [x] Identity Center (multi-Region, us-east-2), user `dolly`, `AdministratorAccess` permission set on all three accounts. Profiles `scs-org` / `scs-general` / `scs-prod` via `sso-session scs-lab`.
- [x] Budgets in management account: $10 (alert 80% actual + forecast), $25 (alert 100% actual + forecast) → gmail.

### Lab (Saturday, hours 2–3)
- [ ] `policies/identity-list-only.json` — user can list one bucket, not read objects. Tested.
- [ ] `policies/bucket-policy-grant.json` — resource policy grants a second user with NO identity policy. Proves same-account "either is enough".
- [ ] `policies/boundary-deny-ec2.json` — boundary on an AdministratorAccess user. Proves boundary caps.
- [ ] `policies/xacct-trust.json` + `policies/xacct-permissions.json` — role in production trusted by general; assumed via `aws sts assume-role`.
- [ ] Break-and-fix: broken trust policy diagnosed from the CloudTrail `AssumeRole` event.
- [ ] `teardown.sh` run; Billing checked.

### Review (Sunday)
- [ ] Teach-back: policy evaluation order from memory
- [ ] Cantrill IAM quiz → misses into `../wrong-answers.md`
- [ ] 5 C03-style questions (one matching)
- [ ] 5-line summary below

## 5-line summary (Sunday)
1.
2.
3.
4.
5.
