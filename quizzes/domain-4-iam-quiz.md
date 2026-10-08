# Domain 4 — Identity and Access Management — Quiz
**SCS-C03 · Domain 4 is 20% of the exam (the largest)**

18 questions. Untimed, but ~2 min each is exam pace (36 min).
Write your answers down before checking `domain-4-iam-answers.md`.
Multiple-response questions say how many to select.

---

**Q1.** A role has this identity policy:

```json
{
  "Effect": "Allow",
  "Action": ["s3:ListBucket", "s3:GetObject"],
  "Resource": "arn:aws:s3:::acme-data/*"
}
```

A user assuming the role reports they can download `reports/q3.csv` by exact key, but the bucket appears empty in the console. What is the cause?

A. `s3:ListBucket` requires the bucket ARN (`arn:aws:s3:::acme-data`), which the policy does not grant
B. Block Public Access is preventing the listing
C. The console requires `s3:ListAllMyBuckets`, which is missing
D. The object key prefix `reports/` must be added to the `Resource`

---

**Q2.** An application role in account A (111111111111) has an identity policy allowing `s3:GetObject` on `arn:aws:s3:::shared-logs/*`, a bucket in account B (222222222222). Requests fail with AccessDenied stating `no resource-based policy allows the s3:GetObject action`. What must change?

A. Add `sts:AssumeRole` to the role in account A
B. Add a bucket policy in account B naming the role in account A as a `Principal`
C. Enable cross-region replication on the bucket
D. Attach a permissions boundary to the role in account A

---

**Q3.** A role has `AdministratorAccess` attached and a permissions boundary allowing only `s3:*` and `logs:*`. Which statement is correct?

A. The role can perform any action; boundaries only apply to IAM users
B. The role can perform only S3 and CloudWatch Logs actions
C. The role can perform any action, because `AdministratorAccess` is evaluated after the boundary
D. The role can perform no actions, because the boundary conflicts with the identity policy

---

**Q4.** A developer has `ec2:RunInstances` on `*` and `iam:PassRole` on `*`. A security review flags this as a privilege-escalation risk. Why, and what is the minimal fix? (Select TWO.)

A. The developer can attach any existing role — including an administrator role — to an instance they control
B. The developer can create new roles with arbitrary permissions
C. Scope `iam:PassRole` to specific role ARNs and add the `iam:PassedToService` condition key
D. Replace `iam:PassRole` with `iam:CreateServiceLinkedRole`
E. Remove `ec2:RunInstances` and grant `ec2:*` instead

---

**Q5.** An SCP attached to the organization root denies `iam:CreateUser`. A security engineer reports that IAM users can still be created in one account. Which account is it, and why?

A. Any account with `AdministratorAccess` — SCPs do not restrict administrators
B. The management account — SCPs never apply to it
C. Any account not inside an OU — SCPs apply only to OUs
D. A delegated administrator account — delegated admins are exempt

---

**Q6.** Match each AccessDenied message fragment to the policy a security engineer should inspect first.

| Message fragment | |
|---|---|
| 1. `because no permissions boundary allows the action` | |
| 2. `with an explicit deny in a service control policy` | |
| 3. `because no resource-based policy allows the action` | |
| 4. `because no session policy allows the action` | |

Options:
W. The bucket / key / queue policy on the target resource
X. The policy passed with `--policy` at `sts:AssumeRole` time
Y. The managed policy in the role's boundary slot
Z. The Organizations policy attached to the account or an OU above it

---

**Q7.** A role's trust policy specifies `"Principal": {"AWS": "arn:aws:iam::111111111111:root"}`. Which statement is correct?

A. Only the root user of account 111111111111 may assume the role
B. Any principal in account 111111111111 may assume the role, provided their own identity policy allows `sts:AssumeRole` on it
C. Every principal in account 111111111111 may assume the role unconditionally
D. The role may be assumed only by the management account of the organization

---

**Q8.** A company onboards new project teams weekly. Each team must access only the S3 objects belonging to its project. The security team wants to avoid editing IAM policies for each new team. Which approach meets this with the LEAST operational overhead?

A. Create one IAM role and one bucket policy per team
B. Tag roles and objects with a `project` key, and write one policy matching `aws:PrincipalTag/project` against `s3:ExistingObjectTag/project`
C. Create an IAM user per team member and use `${aws:username}` prefixes
D. Use a permissions boundary per team, attached at role creation

---

**Q9.** A SaaS provider runs a single backend service that reads objects for thousands of customers from one bucket. Each request must be limited to the calling customer's prefix, and the limit must not be bypassable by the application code path that handles the request. Which design is MOST appropriate?

A. One IAM role per customer, assumed by the backend
B. The backend assumes its own role with a session policy scoped to the customer's prefix, generated per request by a component the request handler cannot modify
C. A permissions boundary on the backend role naming every customer prefix
D. A bucket policy with a `Deny` for every customer prefix except the caller's

---

**Q10.** A security engineer with `guardduty:*` but no IAM permissions cannot enable GuardDuty in a new account. The error references a missing permission. Which TWO options resolve this? (Select TWO.)

A. Grant `iam:CreateServiceLinkedRole` scoped to `guardduty.amazonaws.com`
B. Grant `iam:PassRole` on the GuardDuty service-linked role
C. Have an administrator run `aws iam create-service-linked-role --aws-service-name guardduty.amazonaws.com` in advance
D. Grant `iam:CreateRole` on `*`
E. Attach `AdministratorAccess` to the engineer

---

**Q11.** A bucket policy contains:

```json
"Condition": { "StringEquals": { "aws:PrincipalArn": "arn:aws:iam::111111111111:role/app-*" } }
```

Users report that no principal can access the bucket. What is wrong?

A. `aws:PrincipalArn` is not a valid condition key
B. `StringEquals` treats `*` as a literal character; the operator should be `ArnLike` or `StringLike`
C. Role ARNs cannot be used in conditions, only in `Principal`
D. The condition requires `aws:PrincipalOrgID` instead

---

**Q12.** A healthcare company needs two things: (1) staff sign in to AWS accounts using the corporate Microsoft Entra ID directory, and (2) patients sign up and sign in to the company's mobile app, which uploads documents directly to S3. Which combination is correct?

A. IAM Identity Center for staff; Amazon Cognito user pool + identity pool for patients
B. Amazon Cognito for staff; IAM Identity Center for patients
C. IAM Identity Center for both, using separate permission sets
D. IAM users with MFA for staff; Cognito user pool only for patients

---

**Q13.** A trust policy on a privileged role includes `"Bool": {"aws:MultiFactorAuthPresent": "true"}`. All workforce access is through IAM Identity Center federated to an external IdP where MFA is enforced. What is the MOST likely outcome?

A. The condition is satisfied because users completed MFA at the IdP
B. No federated user can assume the role, because the condition is not satisfied by SAML-federated sessions
C. The condition is ignored for trust policies
D. The condition is satisfied only for the first hour after sign-in

---

**Q14.** A security team wants to (1) block pull requests that introduce IAM policies granting `iam:PassRole` on `*`, and (2) continuously identify S3 buckets in their accounts that are shared with external AWS accounts. Which pair of IAM Access Analyzer capabilities meets these?

A. Policy validation for (1); external access findings for (2)
B. External access findings for (1); unused access findings for (2)
C. Policy generation for (1); policy validation for (2)
D. Unused access findings for (1); policy generation for (2)

---

**Q15.** Place the following IAM evaluation steps in the order AWS applies them when a principal in an account makes a request to a resource in the same account.

1. Evaluate service control policies
2. Check for an explicit Deny in any applicable policy
3. Evaluate the identity-based policy
4. Evaluate the permissions boundary

---

**Q16.** An engineer runs IAM Policy Simulator against a role whose policy grants `s3:GetObject` only when `s3:ExistingObjectTag/team` matches the principal's `team` tag. The simulator returns `implicitDeny`, but the same call succeeds in production. What explains the discrepancy?

A. The simulator does not evaluate resource-based policies
B. The simulator did not have values for the condition keys, which appear in `MissingContextValues`
C. The simulator evaluates SCPs, which blocked the request
D. The simulator caches results for one hour

---

**Q17.** An SCP denies all actions when `aws:RequestedRegion` is not `eu-west-1`, using `NotAction` to exempt `iam:*`, `sts:*`, and `organizations:*`. An administrator in a member account reports they can still create IAM roles while the console is set to `us-east-1`. Is this expected?

A. No — the SCP should block it; the policy is misconfigured
B. Yes — `iam:*` is exempted by `NotAction`, so the condition is never evaluated for that action
C. No — `NotAction` applies only to `Allow` statements
D. Yes — IAM roles are created in `us-east-1` regardless of the SCP, which only affects data-plane actions

---

**Q18.** Developers must be able to create IAM roles for their applications, but must not be able to grant those roles more permissions than they themselves have. Which solution meets the requirement with the LEAST operational overhead?

A. Require all role creation to go through a ticket to the security team
B. Grant `iam:CreateRole` with a condition requiring `iam:PermissionsBoundary` to equal a specific boundary policy ARN, and deny `iam:DeleteRolePermissionsBoundary` via SCP
C. Grant `iam:CreateRole` and audit created roles daily with IAM Access Analyzer
D. Grant `iam:CreateRole` only within a session policy scoped to a role-name prefix
