# The governed pipeline — how it works

A reference for what we built in Week 3, Lab 4.

---

## 1. The problem

Infrastructure changes need to be **reviewable, testable, and attributable** before they
reach a cloud account. Without a pipeline:

- someone console-clicks a change — no review, no record of intent, no way to reproduce it
- or someone runs the CLI from a laptop using long-lived credentials
- the credentials live forever, work from anywhere, and leak

With a pipeline:

- every change is a commit, reviewed in a PR
- automated checks run before a human is asked to approve
- deployment happens from a trusted branch with short-lived credentials
- every AWS API call traces back to a workflow run, and from there to a commit

---

## 2. Architecture

```
developer pushes a branch
          │
          ▼
    opens a PULL REQUEST ───────────────────────────────┐
          │                                             │
   ┌──────┴───────┐                              ┌──────┴────────┐
   │ static-checks│  (no AWS access)             │ policy-lint   │ (read-only AWS)
   │              │                              │               │
   │ • cfn-lint   │  is it valid CloudFormation? │ • Access       │ are the IAM
   │ • cfn-guard  │  does it meet our rules?     │   Analyzer     │ policies sound?
   └──────┬───────┘                              └──────┬────────┘
          │                                             │
          └──────────────┬──────────────────────────────┘
                         │  any failure → merge blocked
                         ▼
                  human review + merge
                         │
                         ▼
                  push lands on main
                         │
                         ▼
                  ┌──────────────┐
                  │   deploy     │ (privileged AWS role)
                  │              │
                  │ • assume     │ GitHubDeployRole via OIDC
                  │ • cfn deploy │ creates/updates the stack
                  └──────────────┘
```

Privilege increases with trust: a PR gets none or read-only; only a reviewed commit on
`main` reaches the role that can change the account.

---

## 3. The files

| File | Role |
|---|---|
| `.github/workflows/aws-oidc.yml` | the pipeline definition — triggers, jobs, steps |
| `week-03/pipeline/template.yaml` | the infrastructure, as CloudFormation |
| `week-03/pipeline/rules.guard` | our org's policy-as-code rules |
| `week-03/pipeline/iam-policies/*.json` | standalone IAM policies, linted by Access Analyzer |
| `week-03/policies/github-oidc-trust.json` | trust policy for the deploy role |
| `week-03/policies/github-validate-trust.json` | trust policy for the PR validation role |
| `week-03/policies/github-deploy-permissions.json` | what the deploy role may do |

---

## 4. The three AWS identities

| Identity | Trusted for | Permissions | Why |
|---|---|---|---|
| (none) | `static-checks` job | — | Linting needs no cloud access. Don't grant what isn't needed. |
| `GitHubValidateRole` | `sub = …:pull_request` | `access-analyzer:ValidatePolicy` only | A PR may come from anywhere. Give it the minimum that makes the check work. |
| `GitHubDeployRole` | `sub = …:ref:refs/heads/main` | CloudFormation + `iam:*` scoped to `role/app-*` **with a mandatory permissions boundary** | Only reviewed, merged code may change the account. |

The `sub` claim is the boundary. It is matched with `StringEquals` — exact, no wildcards.

---

## 5. The workflow, block by block

```yaml
on:
  push:
    branches: [ main ]      # deploy path
  pull_request:             # validation path
  workflow_dispatch:        # manual trigger, for testing
```

```yaml
permissions:
  id-token: write           # REQUIRED - lets GitHub mint the OIDC JWT
  contents: read            # least privilege on the GitHub side
```
Without `id-token: write` the OIDC token is never created and the assume step fails
with a confusing credentials error. This is the single most common mistake.

```yaml
  static-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4     # get the repo onto the runner
      - run: pipx install cfn-lint
      - run: curl ... install-guard.sh | sh
      - run: cfn-lint  week-03/pipeline/template.yaml
      - run: cfn-guard validate --data ... --rules ...
```
No AWS credentials anywhere in this job. If a check exits non-zero, the job fails,
and the PR shows a red check.

```yaml
  policy-lint:
    if: github.event_name == 'pull_request'
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::...:role/GitHubValidateRole
```
The action requests the JWT from GitHub, calls `sts:AssumeRoleWithWebIdentity`,
and exports temporary credentials as environment variables for later steps.

```yaml
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: static-checks
```
`needs:` creates the dependency — deploy does not start unless static-checks passed.
`if:` restricts it to the main branch. Both are *convenience*; the real control is
the trust policy, which refuses any other branch regardless of what the YAML says.

---

## 6. The three checks and why all three

| Tool | Question | Would catch |
|---|---|---|
| `cfn-lint` | Is this valid CloudFormation? | `Principl:` typo, wrong property type, bad `!Ref` |
| `cfn-guard` | Does it meet our org's rules? | role with no permissions boundary |
| `validate-policy` | Is the IAM policy sound? | `s3:GetObjects` (no such action), `StringEquals` with `*`, `PassRole` on `*` |

They fail in different directions:
- a dangerous template can be perfectly **valid** (cfn-lint says nothing)
- a broken template makes guard rules **skip silently** (cfn-guard says PASS)

**A skipped rule looks exactly like a passing rule.** Always prove a rule fires on a
known-bad input before trusting it.

---

## 7. Defense in depth

The `iam:PassRole` on `*` we tried to merge was stopped four times over:

1. `cfn-guard` — `no_passrole_on_star` FAIL (18 seconds)
2. `validate-policy` — `PASS_ROLE_WITH_STAR_IN_RESOURCE` SECURITY_WARNING
3. the deploy role's IAM condition — cannot create `app-*` roles without a boundary
4. `DeveloperBoundary` itself — allows only `s3:*` and `logs:*`, so `iam:PassRole`
   would be inert even if deployed

Only #3 and #4 are true controls. #1 and #2 are fast feedback so the failure is
caught in the PR rather than silently neutralised in production.

---

## 8. What's missing for production

| Gap | Fix |
|---|---|
| `uses: actions/checkout@v4` is a **mutable tag** | pin to a commit SHA — a repointed tag runs arbitrary code with your AWS credentials |
| No branch protection | require status checks + 1 approval before merge; otherwise the gates are advisory |
| `.github/` is editable by anyone with write access | CODEOWNERS on the workflow directory |
| No environment separation | dev → staging → prod, with separate roles and accounts |
| No rollback | `aws cloudformation deploy` updates in place; add change sets + manual approval for prod |
| No drift detection | someone console-clicks a change and the template no longer matches reality |
| No dependency/secret scanning | Dependabot, secret scanning, SBOM |

---

## 9. Vocabulary

| Term | Meaning |
|---|---|
| **CI** | Continuous Integration — every change is automatically built, tested, scanned |
| **CD** | Continuous Delivery (ready to ship, human presses the button) / Deployment (ships itself) |
| **workflow** | a YAML file defining when to run and what to do |
| **job** | a group of steps running on one runner; jobs run in parallel unless `needs:` |
| **step** | one command or one action |
| **runner** | the machine executing the job (`ubuntu-latest` = GitHub-hosted VM) |
| **action** | a reusable step (`actions/checkout`, `aws-actions/configure-aws-credentials`) |
| **gate** | a check that must pass before the change proceeds |
| **OIDC** | the federation protocol that replaces stored credentials |
| **`sub` claim** | the JWT field identifying the repo + ref — the security boundary |
| **policy as code** | org rules expressed as machine-checkable rules (cfn-guard, OPA, Sentinel) |
