#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
: "${LAMBDA_ROLE_ARN:?Define LAMBDA_ROLE_ARN}"
zip -q -j /tmp/mod7-lambda-${SUFFIX}.zip implementation/src/index.mjs
if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  aws lambda update-function-code --function-name "$FUNCTION_NAME" --zip-file "fileb:///tmp/mod7-lambda-${SUFFIX}.zip" >/dev/null
  aws lambda wait function-updated-v2 --function-name "$FUNCTION_NAME"
else
  aws lambda create-function --function-name "$FUNCTION_NAME" --runtime nodejs22.x --handler index.handler \
    --role "$LAMBDA_ROLE_ARN" --zip-file "fileb:///tmp/mod7-lambda-${SUFFIX}.zip" --timeout 10 --memory-size 128 >/dev/null
  aws lambda wait function-active-v2 --function-name "$FUNCTION_NAME"
fi
VERSION=$(aws lambda publish-version --function-name "$FUNCTION_NAME" --query Version --output text)
if aws lambda get-alias --function-name "$FUNCTION_NAME" --name test >/dev/null 2>&1; then
  aws lambda update-alias --function-name "$FUNCTION_NAME" --name test --function-version "$VERSION" >/dev/null
else
  aws lambda create-alias --function-name "$FUNCTION_NAME" --name test --function-version "$VERSION" >/dev/null
fi
store_env TEST_VERSION "$VERSION"
echo "Lambda ${FUNCTION_NAME}:test -> version ${VERSION}"
