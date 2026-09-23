#!/usr/bin/env bash
# usage: eval "$(./assume.sh <role-name> [session-policy-file])"
# prints export lines for temporary creds of the named role in scs-general
set -euo pipefail
ROLE="$1"; ACCT=797273591655
if [ $# -ge 2 ]; then
  CREDS=$(command aws --profile scs-general --region us-east-2 sts assume-role \
    --role-arn "arn:aws:iam::${ACCT}:role/${ROLE}" --role-session-name "lab-$(date +%s)" \
    --policy "file://$2" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)
else
  CREDS=$(command aws --profile scs-general --region us-east-2 sts assume-role \
    --role-arn "arn:aws:iam::${ACCT}:role/${ROLE}" --role-session-name "lab-$(date +%s)" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)
fi
echo "export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | cut -f1)"
echo "export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | cut -f2)"
echo "export AWS_SESSION_TOKEN=$(echo "$CREDS" | cut -f3)"
echo "export AWS_DEFAULT_REGION=us-east-2"
echo "unset AWS_PROFILE"
