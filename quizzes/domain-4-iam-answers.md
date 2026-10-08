# Domain 4 Quiz — Answers and Explanations

Score yourself: 14/18 (78%) is passing pace. Under 12, re-lab the weak area.

---

**Q1 — A.** `ListBucket` is a *bucket* action, checked against `arn:aws:s3:::acme-data` (no slash). The policy grants only `acme-data/*`, which matches object ARNs. Classic symptom: reads by exact key work, listing fails. Fix = two statements.
- B wrong: BPA blocks public access, not an authorised principal's listing.
- C wrong: `ListAllMyBuckets` only populates the bucket *list* page, not the contents.
- D wrong: `/*` already covers `reports/q3.csv`.
*(Week 1, Lab 1 — your first bug.)*

**Q2 — B.** Cross-account access is an **AND**: identity policy in A *and* resource policy in B. The error names the missing half.
- A wrong: `sts:AssumeRole` is irrelevant; this is a direct S3 call, not role assumption.
*(Week 1, Lab 3.)*

**Q3 — B.** Effective permissions = identity policy ∩ boundary. `AdministratorAccess` is inert outside the ceiling.
- A wrong: boundaries apply to users *and* roles (not groups).
- C wrong: there's no ordering that lets an identity policy override a boundary; both must allow.
- D wrong: they don't conflict — they intersect.
*(Week 1, Lab 4.)*

**Q4 — A and C.** `iam:PassRole` on `*` lets the developer hand *any* role, including an admin role, to an instance they control, then use the instance credentials. Fix: scope `Resource` to specific role ARNs and add `iam:PassedToService`.
- B wrong: creating roles needs `iam:CreateRole`, not granted here.
- D wrong: SLRs are a different mechanism entirely.
- E wrong: `ec2:*` is broader, not narrower.

**Q5 — B.** The management account is never subject to SCPs. This is why it holds no workloads and few identities.
- A wrong: SCPs absolutely restrict administrators — that's their purpose.
- C wrong: SCPs attached to the root apply to all member accounts, OU or not.
- D wrong: delegated administrators are ordinary member accounts.
*(Week 2, Lab 2.)*

**Q6 — 1→Y, 2→Z, 3→W, 4→X.**
The "because…" clause names the layer. Note the distinction between `no … allows` (implicit — something is missing) and `explicit deny in …` (something is actively blocking; adding Allows won't help).

**Q7 — B.** `:root` means *the account*, and it **delegates** the decision to that account's IAM rather than granting. So the caller also needs `sts:AssumeRole` in their identity policy.
- A wrong: it's not the root user.
- C wrong: that would be true only if the trust policy named the principal explicitly (then the same-account OR rule applies and no identity policy is needed).
*(Week 1, Lab 5 experiment — you tested both branches.)*

**Q8 — B.** ABAC. One policy, one tagging convention, no edits when a team is added.
- A: N policies, the thing to avoid.
- C: `${aws:username}` is empty for roles and federated identities.
- D: boundaries cap, they don't segregate by team.
*(Week 2, Lab 3.)*

**Q9 — B.** Session policies are computed per request and cap the role. The "not bypassable by the request handler" wording is the key — the scoping component must sit outside the code path that could skip it (a broker). A session policy the caller supplies to itself is blast-radius reduction, not enforcement.
- A: doesn't scale to thousands and is operationally heavy.
- C: boundaries are static; naming every customer is unmanageable.
- D: a bucket policy can't know which customer a request is "for."
*(Week 2, Lab 5.)*

**Q10 — A and C.** Either grant the scoped `iam:CreateServiceLinkedRole`, or have an admin pre-create the SLR so the permission is never needed.
- B wrong: `PassRole` applies where an API takes a role ARN as a parameter; GuardDuty finds its own SLR.
- D and E: work, but violate least privilege — the question implies the engineer should stay without IAM rights.

**Q11 — B.** `StringEquals` treats `*` as a literal asterisk, so the condition can never match and everything is denied. Use `ArnLike` (or `StringLike`).
- A wrong: `aws:PrincipalArn` is valid.
*(The wildcard/operator trap — and `validate-policy` flags it as `WILDCARD_WITHOUT_LIKE_OPERATOR`.)*

**Q12 — A.** Identity Center = workforce → AWS accounts. Cognito = application end users; user pool for sign-in, identity pool to exchange the token for temporary AWS credentials so the app can write to S3 directly.
- D wrong: IAM users for staff is the anti-pattern federation exists to remove.

**Q13 — B.** `aws:MultiFactorAuthPresent` reflects MFA presented to **STS at credential issuance**, not MFA performed at an IdP. SAML/Identity Center sessions don't satisfy it, so the role becomes unassumable. Enforce MFA in Identity Center settings or the IdP instead, and restrict the role by naming the specific permission-set role ARN.
*(Week 2, Lab 5 — you tested this directly.)*

**Q14 — A.** Policy **validation** lints a policy document (CI/PR gate). **External access findings** scan deployed resources for access from outside the zone of trust.
- Remember the five distinct Access Analyzer capabilities: validation, external access, unused access (billed), custom policy checks (billed), policy generation.

**Q15 — 2, 1, 4, 3.**
Explicit Deny anywhere → SCP → permissions boundary → identity policy. (Session policies and resource policies also participate; the exam usually tests the relative order of Deny, SCP, boundary, identity.)
Key points: an explicit Deny short-circuits everything, and SCPs are evaluated before anything in the account.

**Q16 — B.** The simulator evaluates policies, not live resource state. Conditions needing real values return `MissingContextValues` and produce a misleading `implicitDeny`. Supply `--context-entries`.
- A wrong: it *can* evaluate resource policies if you pass `--resource-policy`.
- C wrong: it does evaluate SCPs (`OrganizationsDecisionDetail`), but that isn't the cause here.
*(Week 2, Lab 4.)*

**Q17 — B.** `NotAction` removes those actions from the statement's scope entirely — the `Condition` is never reached for them. That exemption is deliberate: IAM and STS are global services served from `us-east-1`, and denying them would lock everyone out.
- D wrong: the reason is the `NotAction` exemption, not a data-plane/control-plane distinction.
*(Week 2, Lab 1 — and the drill question you missed.)*

**Q18 — B.** The `iam:PermissionsBoundary` condition makes the boundary mandatory at creation time; the SCP stops it being removed afterwards. Self-service with no escalation path.
- A: works but is maximum overhead — the thing the question rules out.
- C: detective, not preventive; the escalation happens before you audit.
- D: session policies cap the session, they can't force an attribute onto a created resource.

---

## Scoring by task statement

| Questions | Task statement | If you missed these |
|---|---|---|
| 1, 2, 11 | 4.2.3 least-privilege policies | Re-read week 1 Labs 1–3 notes; redo the ARN matching table |
| 3, 18 | 4.2.3 boundaries | Re-run week 1 Lab 4 |
| 4, 10 | 4.2.1 roles for services | Re-read the PassRole vs SLR table |
| 5, 17 | 6.1.3 org policies | Re-run week 2 Labs 1–2 |
| 6, 16 | 4.2.4 analyze authorization failures | Reproduce the part-4 table from memory |
| 7, 9 | 4.2.1 / 4.1.2 trust + temporary credentials | Re-run week 1 Lab 5 experiment |
| 8 | 4.2.2 ABAC | Re-run week 2 Lab 3 |
| 12, 13 | 4.1.1 identity solutions | Cognito vs Identity Center; MFA with federation |
| 14 | 4.2.5 unintended permissions | Access Analyzer's five capabilities |
| 15 | 4.2.3 evaluation logic | Redraw the chain from memory |
