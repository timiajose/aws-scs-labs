# Cheat sheet — confusable pairs

One page. Add pairs the moment you confuse them; prune anything you no longer confuse.

## IAM (week 1–2)
| Pair | The distinction |
|---|---|
| Identity policy vs resource policy | Attached to a principal vs attached to the resource. Same account: either is enough. Cross-account: need both. |
| Permission boundary vs identity policy | Boundary caps the max; grants nothing by itself. Effective = identity ∩ boundary. |
| Explicit deny vs no allow | Explicit deny always wins. Absence of allow is an implicit deny — overridable by another allow. |
| User vs role | Long-lived creds vs temporary STS creds. Prefer role for anything that isn't a human on the console. |
| `Principal` vs `NotPrincipal` | |
| Trust policy vs permission policy (on a role) | Who can assume it vs what it can do once assumed. |
| Service-linked role vs service role | SLR: AWS creates and owns it (`AWSServiceRoleFor…`), trust = service principal, you can't edit it, delete fails while in use; needs `iam:CreateServiceLinkedRole` to enable the service. Service role: you write trust + permissions and you hand it to the service. |
| `iam:PassRole` | Not an API and not a role — a permission checked on the *caller* when they attach a role to a service (RunInstances, CreateFunction, RunTask). The instance/function needs nothing extra. Also checked when an API takes a role-ARN parameter and you supply an SLR's ARN (Spot Fleet `IamFleetRole`, Config `roleARN`, ASG `ServiceLinkedRoleARN`). Scope by `Resource` = role ARN + `iam:PassedToService`; `Resource: "*"` = privilege escalation. No standalone CloudTrail event — denial shows inside the parent call. |
