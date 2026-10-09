# Known-bad fixtures

Deliberately non-compliant templates. They exist to **prove the gates fire** —
a rule that never fires looks identical to a rule that passes.

Excluded from the pipeline's scanning (`--skip-path`) because they are supposed
to fail. They are run manually, or by the rule-test step, as negative tests.

| File | Demonstrates |
|---|---|
| `bad-template.yaml` | `Principal: "*"`, `iam:PassRole` on `*`, no permissions boundary |
| `ai-generated-template.yaml` | AI-plausible output: wildcard resources, no Block Public Access, no encryption, a plaintext secret in a Lambda env var |

Verify the rules still catch them:

```bash
cfn-guard validate --data fixtures/bad-template.yaml --rules rules.guard --show-summary fail
cfn-guard validate --data fixtures/ai-generated-template.yaml --rules rules.guard --show-summary fail
checkov -f fixtures/ai-generated-template.yaml --framework cloudformation --compact --quiet
```
