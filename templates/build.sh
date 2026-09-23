#!/usr/bin/env bash
# Lab build script template. Copy to week-NN/build.sh.
# Every resource created here MUST have a matching delete in teardown.sh.
set -euo pipefail
PROFILE="${PROFILE:-scs-general}"
REGION="${REGION:-us-east-1}"
TAG_KEY="scs-lab"; TAG_VAL="week-NN"   # tag everything so teardown can find strays
aws() { command aws --profile "$PROFILE" --region "$REGION" "$@"; }

echo "==> building week-NN lab in $PROFILE/$REGION"
# ...
