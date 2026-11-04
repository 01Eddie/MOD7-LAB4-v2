#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
[[ "${CONFIRM_CLEANUP:-}" == "DELETE-${SUFFIX}" ]] || { echo "Define CONFIRM_CLEANUP=DELETE-${SUFFIX}" >&2; exit 1; }
# Solamente recursos prefijados del alumno. Nunca borrar bucket compartido.
KEY_ID=$(aws apigateway get-api-keys --limit 500 --query "items[?name=='mod7-key-${SUFFIX}'].id | [0]" --output text)
PLAN_ID=$(aws apigateway get-usage-plans --limit 500 --query "items[?name=='mod7-plan-${SUFFIX}'].id | [0]" --output text)
if [[ "$PLAN_ID" != 'None' ]]; then
  if [[ "$KEY_ID" != 'None' ]]; then
    aws apigateway delete-usage-plan-key --usage-plan-id "$PLAN_ID" --key-id "$KEY_ID" >/dev/null 2>&1 || true
  fi
  aws apigateway delete-usage-plan --usage-plan-id "$PLAN_ID" >/dev/null
fi
if [[ "$KEY_ID" != 'None' ]]; then aws apigateway delete-api-key --api-key "$KEY_ID" >/dev/null; fi
for NAME in "$TEST_NAME" "$PROD_NAME"; do
  ID=$(get_api_id "$NAME")
  if [[ -n "$ID" ]]; then aws apigateway delete-rest-api --rest-api-id "$ID" >/dev/null; fi
done
if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  aws lambda delete-function --function-name "$FUNCTION_NAME" >/dev/null
fi
if [[ -n "${CATALOG_BUCKET:-}" ]]; then
  aws s3 rm "s3://${CATALOG_BUCKET}/catalog/${SUFFIX}/" --recursive >/dev/null
fi
echo "Eliminación solicitada solo para recursos ${SUFFIX}. Verificar en AWS Console."
