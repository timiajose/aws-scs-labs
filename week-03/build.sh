#!/usr/bin/env bash
# Lab build script template. Copy to week-03/build.sh.
# Every resource created here MUST have a matching delete in teardown.sh.
set -euo pipefail
PROFILE="${PROFILE:-scs-general}"
REGION="${REGION:-us-east-1}"
TAG_KEY="scs-lab"; TAG_VAL="week-03"   # tag everything so teardown can find strays
aws() { command aws --profile "$PROFILE" --region "$REGION" "$@"; }

echo "==> building week-03 lab in $PROFILE/$REGION"
# ...
