# AWS SCS-C03 Labs

Hands-on lab log for the AWS Certified Security – Specialty (SCS-C03) exam.
Roadmap: `~/Downloads/AWS_Security_Specialty_Roadmap_v2.md`. Exam week: Dec 14–18, 2026.

## Layout
```
week-NN/
  README.md        what this week proves, 5-line summary (written Sunday)
  notes.md         surprises only — never transcribe video
  build.sh         creates the lab (or template.yaml for CloudFormation)
  teardown.sh      deletes everything build.sh created — run before closing the laptop
  policies/        every policy JSON, one-line header comment saying what it proves
wrong-answers.md   every missed quiz/practice question, with the *why*
cheat-sheet.md     confusable pairs — the exam lives here
templates/         build.sh / teardown.sh starting points
```

## Accounts
| Profile | Account | Purpose |
|---|---|---|
| `scs-general` | general | Daily lab account |
| `scs-prod` | production | Cross-account target |
| `scs-org` | org-management | Organizations, Identity Center, org trail |

All access via `aws sso login --profile <name>`. No IAM user access keys, ever. Root: MFA on, no keys.

## Rules
1. Lab before quiz.
2. Every lab ends with `teardown.sh` and a look at the Billing console.
3. Never commit credentials, account IDs in public repos, or `.env` files (see `.gitignore`).

## Session start (every lab)
```bash
aws sso login --sso-session scs-lab     # once per ~8 h; opens browser
aws sts get-caller-identity --profile scs-general
```
# direct push attempt on main
