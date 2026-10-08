# Wrong-answers log

Format: `[week] [domain] Q summary — what I picked — right answer — WHY I got it wrong (misread / didn't know / confused X with Y)`.
Review every Sunday. Patterns in the WHY column are the study plan for the following week.

## Week 1 — IAM fundamentals
-

## Domain 4 quiz (Sep 26, 2026) — 16/18

- **Q13** [4.1.1 authentication] MFA condition on a trust policy with Identity Center — picked A (condition satisfied by IdP MFA), correct is B (federated sessions do NOT satisfy `aws:MultiFactorAuthPresent`).
  **WHY WRONG: recall failure — I tested this myself in week 2 Lab 5 and the assume was denied.** Enforce MFA at Identity Center / the IdP; restrict privileged roles by naming the exact permission-set role ARN.

- **Q16** [4.2.4 analyze authorization failures] Policy Simulator returns implicitDeny but production works — picked A (simulator ignores resource policies), correct is B (`MissingContextValues`: no values supplied for the tag condition keys).
  **WHY WRONG: two causes.** (1) A is a half-truth — the simulator *will* evaluate a resource policy if `--resource-policy` is passed. (2) **I invented facts not in the question** — assumed a cross-account/prod scenario the stem never described.
  **Exam habit to fix: answer only what is written. If I catch myself saying "it's probably also…", re-read the stem.**

### Pattern to watch
Both misses were about *conditions*: one about a condition key that isn't populated the way I expected (Q13), one about condition keys the simulator can't see (Q16). Conditions are where my model is thinnest — re-check condition-key behaviour before assuming it works.
