# Week 3 notes — Domain 6: Security Foundations and Governance (14%)

Surprises only. Don't transcribe the video.

## Organizations: the policy types
| Type | Caps what | Notes |
|---|---|---|
| SCP | what *my principals* can do | built in week 2 |
| RCP (new in C03) | what can be done *to my resources* | |
| Declarative policy (new in C03) | | |
| AI services opt-out | | |
| Tag policy / Backup policy | | |

## Control Tower — three control types
| Type | Implemented as | Acts when |
|---|---|---|
| Preventive | SCP | before the API call succeeds |
| Detective | Config rule | after the fact |
| Proactive | CloudFormation Hooks | at deploy time, before the resource exists |

Other terms: landing zone, Account Factory, drift detection, enrollment.

## Config
- recorder → rules → evaluations → remediation
- managed vs custom rules; conformance packs
- remediation = SSM Automation document + a role
- **Cannot auto-remediate immutable properties** (EBS/RDS encryption, bucket region) → prevent at creation instead

### Config rule → SOC 2 mapping
| Config rule | SOC 2 control | Why |
|---|---|---|
| | | |

## Delegated administrator
Which services support it, and why security tooling runs from a member account not the management account:

## IaC and the pipeline
- cfn-lint =
- cfn-guard =
- Access Analyzer validate-policy =
- GitHub OIDC vs access keys =

## Other services (awareness level)
| Service | One-line purpose | Exam tell |
|---|---|---|
| Audit Manager | | |
| Artifact | | |
| Service Catalog | | |
| RAM | | |
| Trusted Advisor | | |
| Well-Architected Tool | | |

## Surprises
-

## 5-line summary (Sunday)
1.
2.
3.
4.
5.
