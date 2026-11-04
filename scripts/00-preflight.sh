#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
for command in aws python3 zip curl; do command -v "$command" >/dev/null || { echo "Falta $command"; exit 1; }; done
aws sts get-caller-identity --output json
[[ -n "${CATALOG_BUCKET:-}" ]] || { echo 'Falta CATALOG_BUCKET' >&2; exit 1; }
aws s3api head-bucket --bucket "$CATALOG_BUCKET" >/dev/null
[[ -n "${LAMBDA_ROLE_ARN:-}" ]] || { echo 'Falta LAMBDA_ROLE_ARN' >&2; exit 1; }
echo "PRE-FLIGHT OK: sufijo $SUFFIX, región $AWS_REGION, bucket $CATALOG_BUCKET"
