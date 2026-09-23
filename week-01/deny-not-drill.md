# Drill: Deny + Not-conditions, one step at a time

Rules we'll use for every example:
1. A condition never allows or denies. It only answers: **does this statement apply to this request?**
2. `Effect` says what happens *when it applies*.
3. Multiple conditions in one block are **AND** — the statement applies only if every test is true.
4. `aws:PrincipalArn` = **who is calling**, never what is being created.

For each policy: read the sentence, then fill in the table before we discuss.

---

## Step 1 — Allow with a plain Equals

```json
{ "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::reports/*",
  "Condition": { "StringEquals": { "aws:RequestedRegion": "ca-central-1" } } }
```
Sentence: "Allow reading reports **when** the region is ca-central-1."

| Request | Condition true? | Statement applies? | Outcome |
|---|---|---|---|
| GetObject, ca-central-1 | | | |
| GetObject, us-east-1 | | | |

---

## Step 2 — Same thing written as a Deny with NotEquals

```json
{ "Effect": "Deny", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::reports/*",
  "Condition": { "StringNotEquals": { "aws:RequestedRegion": "ca-central-1" } } }
```
Sentence: "Deny reading reports **when** the region is NOT ca-central-1."

| Request | Condition true? | Deny applies? | Outcome (assume an Allow exists elsewhere) |
|---|---|---|---|
| GetObject, ca-central-1 | | | |
| GetObject, us-east-1 | | | |

Question: what's different between Step 1 and Step 2 in practice?
(Hint: in Step 1, a *second* Allow policy could add us-east-1. In Step 2, nothing can.)

---

## Step 3 — Deny with a Not-condition on the *caller*

```json
{ "Effect": "Deny", "Action": "s3:DeleteObject", "Resource": "arn:aws:s3:::reports/*",
  "Condition": { "ArnNotLike": { "aws:PrincipalArn": "arn:aws:iam::*:role/Archivist" } } }
```
Sentence: "Deny deleting reports **when the caller is NOT** the Archivist role."

| Caller | Condition true? | Deny applies? | Outcome |
|---|---|---|---|
| role/Archivist | | | |
| role/Developer | | | |
| user/dolly (admin) | | | |

Who is the only one who can delete? ______

---

## Step 4 — Two conditions, ANDed (this is the break-glass shape)

```json
{ "Effect": "Deny", "Action": "ec2:RunInstances", "Resource": "*",
  "Condition": {
    "StringNotEquals": { "aws:RequestedRegion": "ca-central-1" },
    "ArnNotLike":      { "aws:PrincipalArn": "arn:aws:iam::*:role/BreakGlass-DR" }
  } }
```
Sentence: "Deny launching instances **when** the region is NOT ca-central-1 **AND** the caller is NOT BreakGlass-DR."

| Caller | Region | Test 1: region ≠ ca-central-1? | Test 2: caller ≠ BreakGlass? | Both true? | Deny applies? | Outcome |
|---|---|---|---|---|---|---|
| Developer | ca-central-1 | | | | | |
| Developer | us-east-1 | | | | | |
| BreakGlass-DR | ca-central-1 | | | | | |
| BreakGlass-DR | us-east-1 | | | | | |

Which row is "the emergency"? ______  Is it denied? ______

---

## Step 5 — Now add NotAction (the full SCP)

```json
{ "Effect": "Deny",
  "NotAction": ["iam:*", "sts:*", "organizations:*", "route53:*", "cloudfront:*", "support:*"],
  "Resource": "*",
  "Condition": {
    "StringNotEquals": { "aws:RequestedRegion": "ca-central-1" },
    "ArnNotLike":      { "aws:PrincipalArn": "arn:aws:iam::*:role/BreakGlass-DR" }
  } }
```
Only one thing changed from Step 4: `Action: ec2:RunInstances` became `NotAction: [list]` = "every action **except** these".
The global services are exempt because their APIs live in us-east-1 and would otherwise break.

| Caller | Action | Region | Exempt via NotAction? | Test 1 | Test 2 | Deny applies? | Outcome |
|---|---|---|---|---|---|---|---|
| Developer | iam:CreateRole | us-east-1 | | | | | |
| Developer | s3:CreateBucket | us-east-1 | | | | | |
| Developer | s3:CreateBucket | ca-central-1 | | | | | |
| BreakGlass-DR | s3:CreateBucket | us-east-1 | | | | | |
| BreakGlass-DR | kms:CreateKey | eu-west-1 | | | | | |

---

## The one-line rule to take away

**`Deny` + a `Not…` test = "only X survives."**
- `Deny` + `StringNotEquals region ca-central-1` → only ca-central-1 survives.
- `Deny` + `ArnNotLike BreakGlass-DR` → only BreakGlass-DR survives.
- Both together (AND) → survive if you're in ca-central-1 **or** you're BreakGlass-DR. Blocked only if neither.
