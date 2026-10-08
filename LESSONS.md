# Lessons and interview notes

Accumulated after every lab. Each entry: **what was built**, **five lessons**, and
**the line to say in an interview**.

Review cadence: skim the interview lines weekly; read the lessons for a domain before
its quiz.

---

## Week 1 — IAM fundamentals (Domain 4)

### Lab 1 · Identity policies and the S3 resource-ARN split
Built: a role whose policy let it read objects but not list the bucket, then fixed it.

1. `Resource` is **string matching against ARNs** — nothing more. `bucket` and `bucket/*`
   are different strings matching disjoint sets; neither contains the other.
2. S3 has **two resource types**. Bucket actions (`ListBucket`, `GetBucketPolicy`) →
   bucket ARN. Object actions (`GetObject`, `PutObject`) → `bucket/*`. Most policies
   need one statement of each.
3. **One API call = one authorization check, against one resource.** No traversal, no
   parent check — which is why reading a file doesn't require permission on the bucket.
4. Read AccessDenied as **four facts**: who, what action, **which resource ARN was
   checked**, and which policy type was missing.
5. **IAM is eventually consistent.** A test run immediately after a policy change can
   lie in either direction.

> "S3 policies fail most often because people forget the bucket and the objects are
> different resources. The symptom is a user who can download a file by exact key but
> sees an empty bucket — that's directory listing disabled, not a bug."

### Lab 2 · Resource policies and the same-account rule
Built: a role with zero permissions that read an object purely via a bucket policy.

1. **Same account: identity policy OR resource policy.** Either grant works alone.
2. `Principal` is the field only resource policies have — identity policies are attached
   to someone, so the subject is implicit.
3. A resource policy is the **resource owner's** lever; an identity policy is the
   principal owner's. "Who should own this grant?" is a design question.
4. **Implicit deny is the default** — requests fail because nothing allowed them, not
   because something denied them.
5. When `aws s3 cp` returns a bare `403`, re-issue with `aws s3api get-object` — HEAD
   responses have no body, so the explanation is lost.

> "Same-account, either side can grant. I decide which side based on who should own the
> decision — the resource owner or the identity owner."

### Lab 3 · Cross-account access and the AND rule
Built: the same setup across an account boundary, and watched it break.

1. **Cross-account is an AND** — both account owners must agree.
2. Part 4 of the error names **which half is missing**: `no identity-based policy` →
   caller's side; `no resource-based policy` → resource's side.
3. Spot cross-account from the error by comparing account IDs in the principal ARN and
   the resource ARN.
4. **Resource policies are the only inbound door** — there is no "invite" API.
5. Same-account "OR" is a convenience of single ownership, not a security model. Don't
   carry the intuition across a boundary.

> "Neither account can unilaterally grant access to the other's resources. That's the
> trust boundary made concrete, and it's why the error tells you which side to fix."

### Lab 4 · Permissions boundaries
Built: a role with `AdministratorAccess` that couldn't describe an EC2 instance.

1. **Effective = identity policy ∩ boundary.** The boundary never grants.
2. A boundary is an **ordinary policy in an extraordinary position** — attached as a
   permissions policy it grants; attached as a boundary it caps.
3. `because no permissions boundary allows…` sends you to a different file than
   `no identity-based policy allows…`.
4. `[]` is a successful empty result, not a denial.
5. Boundaries must be **managed** policies, and attach only to users and roles.

> "Boundaries are how you delegate IAM safely: developers can create roles, but only if
> each one carries a mandatory boundary, enforced by the `iam:PermissionsBoundary`
> condition at creation time and protected by an SCP denying its removal."

### Lab 5 · Diagnosing a break
Built: two deliberate breaks, diagnosed from errors and CloudTrail.

1. A role's **trust policy is its resource-based policy** — same role in the evaluation
   chain as a bucket policy, which is why it has a `Principal`.
2. **Implicit vs explicit matters more than the layer.** `no … policy allows` means add
   a grant; `with an explicit deny in …` means stop adding grants and find the Deny.
3. `AssumeRole` denials carry **no "because" clause** — AWS won't say which side failed,
   so check both.
4. **CloudTrail does not log data events by default.** The failing `GetObject` is
   invisible; the `PutBucketPolicy` that caused it is fully recorded.
5. When you can't see the failure, **find the change**: `cloudtrail lookup-events` on
   management events.

> "When I can't see the denial, I look for the configuration change that preceded it.
> 'What changed in the last hour' resolves more incidents than 'why is this failing'."

### Experiment · Trust policy semantics
Established by test, not assumption:
- A trust policy naming a **specific principal** is sufficient same-account — the caller
  needs no `sts:AssumeRole` of their own.
- `:root` **delegates** the decision to the account's IAM rather than granting, so the
  caller then does need it.
- The trust policy is always evaluated and must always allow — an identity policy alone
  is never enough.

> "`:root` in a trust policy isn't a grant, it's a delegation. That's why it's only as
> safe as every identity policy in that account — naming the specific principal is both
> tighter and simpler."

---

## Week 2 — Organizations, SCPs, ABAC (Domain 4 + 6)

### Lab 1 · OUs and the region-lock SCP
Built: a region lock with a break-glass carve-out, tested against an account admin.

1. An SCP blocks a **full account administrator** — the first layer that does.
2. SCPs **inherit down the OU tree**; scope follows the attachment point.
3. `Deny` + ANDed `Not…` conditions = "only these survive". The exempted thing is what's
   being *protected*, not blocked.
4. `NotAction` is evaluated **before** conditions — exempted actions never reach them.
5. SCP denials name **the exact policy ID**, the most useful breadcrumb AWS gives.

> "Region locks need the global services exempted — IAM, STS, Organizations, billing,
> support — or you lock everyone out of the account including yourself. Those are
> control-plane services, so exempting them doesn't undermine data residency."

### Lab 2 · Deny-list SCPs and the management account
Built: a guardrail SCP, then discovered the one account it doesn't protect.

1. **Deny-lists subtract from `FullAWSAccess`**; allow-lists require detaching it and
   intersect down the tree, which is how people brick accounts.
2. **Inheritance is invisible** to `list-policies-for-target` — it shows direct
   attachments only. Test, or use the console's account view.
3. Multiple SCPs **intersect** — a request must survive all of them.
4. **SCPs never apply to the management account.** Structural, not configurable.
5. Therefore: no workloads there, minimal access, and security tooling runs from a
   **delegated administrator** member account.

> "The management account is exempt from SCPs and RCPs. That single fact is why it should
> hold nothing, why almost nobody should have access, and why GuardDuty and Security Hub
> get delegated out to a member account."

### Lab 3 · ABAC with tags
Built: one policy document attached to two roles, giving them different access.

1. `${aws:PrincipalTag/key}` — role tags become principal tags; federated users get
   **session tags** from the IdP, which is why ABAC works where `${aws:username}` fails.
2. `s3:ExistingObjectTag` / `aws:ResourceTag` describe the resource side.
3. Matching one against the other **scales without policy edits**.
4. A failed condition is an **implicit** deny — the statement becomes inapplicable.
5. **`ListBucket` cannot see object tags** — names and existence leak even when content
   doesn't.

> "ABAC makes tags the security boundary, so tag-write permissions become privileged.
> You guard them with a `RequestTag` condition and an SCP preventing anyone from
> retagging themselves into another team."

### Lab 4 · Policy Simulator and Access Analyzer
Built: pre-deployment policy testing and external-access findings.

1. The simulator evaluates **policies, not reality** — conditions needing live state come
   back as `MissingContextValues` and produce a misleading `implicitDeny`.
2. It **does** evaluate SCPs, reported in `OrganizationsDecisionDetail`.
3. Garbage in, confident garbage out — a mismatched resource ARN answers a question you
   didn't ask.
4. Access Analyzer findings **include intended access**; archive rules are what keep the
   signal visible.
5. `validate-policy` catches invalid actions, escalation patterns, and wildcard/operator
   mismatches — cheap enough to run on every PR.

> "Access Analyzer is five different things. Validation lints a policy document before
> deploy; external-access findings scan deployed resources. One is a CI gate, the other
> is continuous monitoring — people conflate them."

### Lab 5 · Session policies and permission sets
Built: dynamic per-session scoping, and a second Identity Center permission set.

1. A session policy is **passed at AssumeRole time**, stored nowhere, and dies with the
   credentials. Two people can assume the same role with different effective permissions.
2. It **caps but never grants** — and it still caps access granted by a *resource* policy.
3. It's **not an enforcement mechanism against the caller** — only against code paths
   that can't construct the assume call themselves. That requires a broker.
4. A **permission set is a template**; Identity Center materialises it as an ordinary IAM
   role in each assigned account, trusted via SAML.
5. **Identity Center sessions do not satisfy `aws:MultiFactorAuthPresent`** — the flag
   belongs to the credential, not the human.

> "The MFA condition pattern fails closed with Identity Center. The flag records whether
> an MFA code reached STS, not whether a human authenticated at the IdP. So a break-glass
> role protected that way is unusable by exactly the people meant to use it — and you'd
> find out during the incident."

---

## Week 3 — Governance and CI/CD (Domain 6)

### Lab 1 · AWS Config and auto-remediation
Built: continuous evaluation plus SSM Automation remediation.

1. **Config records state; CloudTrail records actions.** What does it look like vs who
   did it.
2. **No recorder, no evaluations** — rules against a stopped recorder return nothing,
   which reads as compliant.
3. Service-principal grants need **`aws:SourceAccount`/`aws:SourceArn`** — the confused
   deputy guard.
4. Remediation is a **separate configuration**, runs on SSM Automation, and needs its own
   narrowly-scoped role.
5. **Not everything is remediable.** Toggles yes; immutable creation-time properties
   (EBS/RDS encryption) no — those need preventive or proactive controls.

> "Detective controls can't fix immutable properties. Encryption at rest is set at
> creation, so the control has to be preventive — an SCP — or proactive — a
> CloudFormation Hook or a guard rule in the pipeline. Config will only ever tell you
> it's already wrong."

### Lab 2 · Resource Control Policies
Built: an org-level ceiling that overrode a valid cross-account bucket-policy grant.

1. **SCP caps principals; RCP caps resources.** An RCP has a `Principal` element because
   it's a ceiling on resource policies.
2. RCPs stop **external** principals; SCPs cannot, because outsiders aren't in your org.
3. An RCP attached to an account protects **resources in** that account, whoever calls.
4. Org-level policies need **org-level conditions** — `aws:PrincipalOrgID`, not a
   hardcoded account ID, or the policy means different things in different accounts.
5. The data-perimeter idiom: `StringNotEqualsIfExists` on `PrincipalOrgID` +
   `BoolIfExists` on `aws:PrincipalIsAWSService` false.

> "SCPs can't protect you from a bucket policy mistake, because the person reading your
> data isn't in your org. RCPs are the backstop — they cap what any resource policy can
> grant, and no account admin can override them."

### Lab 3 · GitHub OIDC federation
Built: CI deploying to AWS with no stored credentials.

1. OIDC is the third form of one pattern: external IdP → signed token →
   `AssumeRoleWith*` → temporary credentials.
2. `permissions: id-token: write` is **mandatory** — without it no token is minted.
3. **The `sub` claim is the security boundary.** Omit it and any GitHub repo on the
   internet can assume your role.
4. GitHub pins **immutable owner and repo IDs** in `sub` so a renamed or recreated repo
   can't be impersonated.
5. When a string comparison fails and both sides look identical, **print both sides** —
   decode the token rather than re-reading the policy.

> "I scope the OIDC trust to the repo *and* the ref, with `StringEquals`. A wildcard on
> `sub` is the common finding — it means any branch, or sometimes any repo, can assume a
> production deploy role."

### Lab 4 · Pipeline gates
Built: cfn-lint, cfn-guard, and validate-policy gating every PR.

1. Three tools, three questions: **valid / compliant / sound** — they fail in different
   directions and none substitutes for another.
2. A dangerous template can be perfectly **valid**; cfn-lint will say nothing.
3. **A skipped rule looks exactly like a passing rule.** Always prove a rule fires on a
   known-bad input.
4. **Privilege tiers by stage**: PRs get none or read-only AWS access; only merged code
   reaches the deploy role.
5. **Defense in depth**: the gates are fast feedback; the IAM condition and the
   permissions boundary are the actual controls.

> "Policy-as-code has its own bug class — a rule that's too naive fails good templates,
> people add exceptions, and the gate stops meaning anything. A false positive is worse
> than no rule, so I test rules against known-bad and known-good fixtures."

### Lab 5 · Making the gates enforce
Built: branch protection, CODEOWNERS, and proof that admins are bound by it.

1. The first question about a pipeline isn't "what does it check" but **"what happens if
   someone ignores it?"**
2. **`enforce_admins` is the setting that matters** — off by default, and the people most
   able to cause damage are the exemption.
3. A control enforced by **a file inside the repo is not a control against repo writers**.
   Branch protection and the OIDC trust policy are enforcement; `if:` conditions are
   convenience.
4. **CODEOWNERS routes attention by risk** — security reviews IAM and pipeline files, not
   every README change. That's what keeps review from becoming a rubber stamp.
5. **Hardcoded account IDs are a finding** — unportable, leaks topology, breaks on the
   second environment.

> "I don't assess a pipeline by its checks, I assess it by its bypasses: can you push
> directly to the protected branch, can an admin merge past a red check, can a PR edit
> the workflow that gates it, and is the cloud role's trust scoped to the branch rather
> than just the repo."

---

## Quick-review soundbites

- Allows follow the OR/AND rules. **Denies are absolute.**
- Trust policy = compulsory resource-side grant. Bucket policy = optional, so
  same-account admins get in anyway.
- Only **SCPs and RCPs** genuinely bind an account administrator.
- **Preventive** (SCP) / **detective** (Config) / **proactive** (Hooks, cfn-guard) — three
  control types for three different moments.
- The error's "because" clause names the layer: identity / resource / boundary / session /
  explicit deny in SCP or RCP. `AssumeRole` gives you nothing, so check both sides.
- A guardrail that blocks an attacker also blocks you. Plan the exception before you need
  it — a named break-glass principal, not an emergency policy edit.
- A control people bypass provides **negative** security: it also removes the visibility
  you'd have had.
