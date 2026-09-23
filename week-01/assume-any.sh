#!/usr/bin/env bash
# usage: eval "$(./assume-any.sh <profile> <account-id> <role-name>)"
set -euo pipefail
PROFILE="$1"; ACCT="$2"; ROLE="$3"
CREDS=$(command aws --profile "$PROFILE" --region us-east-2 sts assume-role \
  --role-arn "arn:aws:iam::${ACCT}:role/${ROLE}" --role-session-name "lab-$(date +%s)" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)
echo "export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | cut -f1)"
echo "export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | cut -f2)"
echo "export AWS_SESSION_TOKEN=$(echo "$CREDS" | cut -f3)"
echo "export AWS_DEFAULT_REGION=us-east-2"
echo "unset AWS_PROFILE"
