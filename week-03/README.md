# Week 3 — Governance + first CI/CD lab (Domain 6, 14%; touches Domain 4 federation)

## Goal
Config detects and auto-remediates a misconfiguration. A GitHub Actions pipeline deploys IAM roles as code, with policy checks that block bad PRs, and authenticates to AWS via OIDC — no access keys anywhere.

## Part 1 — Config remediation (1 h)
- [ ] Config recorder on; 3 managed rules (`encrypted-volumes`, `s3-bucket-public-read-prohibited`, `root-account-mfa-enabled`)
- [ ] SSM Automation remediation for `encrypted-volumes`
- [ ] `notes.md`: map each rule to a SOC 2 control
- [ ] Disable the recorder in teardown (Config bills per item)

## Part 2 — Governed IaC pipeline (2 h)
Flow: PR → cfn-lint → cfn-guard → Access Analyzer validate-policy → review → merge → OIDC role → CloudFormation deploy.

- [ ] `pipeline/template.yaml` — the week-1 `AppServerRole` as CloudFormation (trust EC2, S3 on one bucket, permission boundary attached)
- [ ] `pipeline/rules.guard` — three rules: every `AWS::IAM::Role` has `PermissionsBoundary`; no `Principal: "*"`; no `iam:PassRole` with `Resource: "*"`
- [ ] `policies/github-oidc-trust.json` — deploy role trust: `token.actions.githubusercontent.com`, `sub` = `repo:timiajose/aws-scs-labs:ref:refs/heads/main`, `aud` = `sts.amazonaws.com`
- [ ] `policies/github-deploy-permissions.json` — least privilege: `cloudformation:*` on the lab stack, `iam:CreateRole/AttachRolePolicy/...` on `app-*` **with** `iam:PermissionsBoundary` condition, `iam:PassRole` on `app-*`
- [ ] `.github/workflows/deploy.yml` — `pull_request`: lint + guard + `aws accessanalyzer validate-policy`; `push` to `main`: `aws-actions/configure-aws-credentials` with `role-to-assume` → `aws cloudformation deploy`
- [ ] Green run on `main`; role appears in the account
- [ ] Break-and-fix 1: PR adds `iam:PassRole` on `Resource: "*"` → which guard rule fires? Paste the output in `notes.md`
- [ ] Break-and-fix 2: run the deploy job from a feature branch → OIDC `AssumeRoleWithWebIdentity` denied; find it in CloudTrail and explain the `sub` condition
- [ ] `teardown.sh`: delete the stack, the OIDC role, the OIDC provider; Config recorder off

## Concepts to be able to explain Sunday
- Why the pipeline has `iam:CreateRole` and the developer has none
- What Access Analyzer policy validation checks vs. what cfn-guard checks vs. what the human reviewer decides
- Why OIDC beats an access key in a GitHub secret (temporary creds, scoped trust, nothing to leak or rotate)
- `iam:PermissionsBoundary` condition on `CreateRole` — pattern 3 layered under pattern 2

## 5-line summary (Sunday)
1.
2.
3.
4.
5.
