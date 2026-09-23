#!/usr/bin/env bash
# Lab teardown template. Copy to week-03/teardown.sh.
# Deletes in reverse order of build.sh, then lists anything still carrying the lab tag.
set -uo pipefail
PROFILE="${PROFILE:-scs-general}"
REGION="${REGION:-us-east-1}"
TAG_KEY="scs-lab"; TAG_VAL="week-03"
aws() { command aws --profile "$PROFILE" --region "$REGION" "$@"; }

echo "==> tearing down week-03 lab in $PROFILE/$REGION"
# ...

echo "==> anything still tagged $TAG_KEY=$TAG_VAL (should be empty):"
aws resourcegroupstaggingapi get-resources --tag-filters "Key=$TAG_KEY,Values=$TAG_VAL" \
  --query 'ResourceTagMappingList[].ResourceARN' --output text
echo "==> now open the Billing console and check today's spend."
