# AWS Security Engineering — Hands-On Lab Portfolio

Multi-account AWS security controls, built and verified from scratch: identity and access
management, organizational guardrails, continuous compliance, and a governed CI/CD pipeline.

Every control in this repo was **deployed, deliberately broken, and diagnosed** — not just
written. The goal throughout was to prove each control actually does what it claims.

**Environment:** a three-account AWS Organization (`management`, `general`, `production`),
IAM Identity Center for all human access, zero IAM users and zero long-lived access keys.

---

## Highlights

### Governed CI/CD pipeline — [`week-03/pipeline/`](week-03/pipeline/)
GitHub Actions deploying CloudFormation to AWS with **no stored credentials**, gated by
three complementary checks.

- **OIDC federation** instead of access keys — trust scoped to one repo and one branch via
  the `sub` claim, verified by assuming from a non-`main` branch and being refused
- **Privilege tiering across pipeline stages** — pull requests get read-only or no AWS
  access; only reviewed commits on `main` reach the deploy role
- **Three gates**: `cfn-lint` (valid?), `cfn-guard` (compliant with our rules?),
  IAM Access Analyzer `validate-policy` (sound IAM?)
- **Defense in depth** — a PR introducing `iam:PassRole` on `Resource: "*"` was blocked by
  two independent gates, and would have been inert even if deployed, because the deploy
  role cannot create roles without a permissions boundary

→ Full write-up: [`week-03/pipeline/README.md`](week-03/pipeline/README.md)

### Organizational guardrails — [`week-02/policies/`](week-02/policies/), [`week-03/policies/`](week-03/policies/)
- **SCPs**: region lock with a break-glass carve-out (`Deny` + ANDed `Not` conditions);
  telemetry protection preventing anyone — including account administrators — from
  disabling CloudTrail, Config, or GuardDuty; "no IAM users, no access keys" enforced
  org-wide rather than merely intended
- **RCP data perimeter**: a resource-side ceiling that overrode a valid cross-account
  bucket-policy grant, demonstrating the SCP/RCP distinction
- Verified the **management account is exempt from both** — the structural reason it holds
  no workloads

### Continuous compliance — [`week-03/`](week-03/)
AWS Config recorder, managed rules, and **automatic remediation** via SSM Automation,
with a least-privilege remediation role limited to two actions. Mapped each rule to its
SOC 2 control. Documented which findings *cannot* be auto-remediated (immutable
creation-time properties) and why those need preventive or proactive controls instead.

### IAM deep dive — [`week-01/`](week-01/), [`week-02/`](week-02/)
Identity vs resource policies, the same-account OR rule vs the cross-account AND rule,
permissions boundaries, session policies, ABAC with principal and resource tags,
cross-account role assumption, and trust-policy semantics — each demonstrated with a
working example and a deliberately broken counterpart.

Several behaviours were **established by experiment rather than assumption**, including:
- a trust policy naming a specific principal is sufficient same-account; `:root` delegates
  to IAM instead of granting, so the caller then also needs `sts:AssumeRole`
- a session policy still caps access granted by a *resource* policy
- Identity Center sessions do **not** satisfy `aws:MultiFactorAuthPresent`, so the common
  break-glass trust-policy pattern fails closed for federated users

---

## Layout

```
week-01/          IAM fundamentals — policies, boundaries, cross-account, trust
week-02/          Organizations, SCPs, ABAC, Policy Simulator, Access Analyzer
week-03/          Config + remediation, RCPs, OIDC federation, governed pipeline
  pipeline/       CloudFormation template, cfn-guard rules, pipeline write-up
.github/workflows/ the pipeline itself
quizzes/          self-assessment against the SCS-C03 task statements
cheat-sheet.md    confusable pairs and decision rules
wrong-answers.md  every mistake, with the reason — reviewed weekly
```

## Operating conventions

- All human access through IAM Identity Center; **no IAM users, no access keys** anywhere,
  enforced by SCP
- Member-account root credentials do not exist (centralized root access management)
- Every lab has a teardown step; cost guardrails via budgets at $10 and $25
- Policies are kept as files so they can be diffed, reviewed, and linted

## Context

Built while preparing for the AWS Certified Security – Specialty (SCS-C03) exam.
The labs follow the official exam guide's task statements, including content new to
C03 — resource control policies, CloudFormation Guard, and OIDC-based CI/CD.
# second direct push attempt
