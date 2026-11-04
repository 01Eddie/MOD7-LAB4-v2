#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
API_ID=$(get_api_id "$TEST_NAME")
[[ -n "$API_ID" ]] || { echo 'Primero ejecutar pipeline de contrato' >&2; exit 1; }
RID=$(resource_id "$API_ID")
[[ "$RID" != 'None' ]] || { echo 'No existe recurso cuentas' >&2; exit 1; }
ACC=$(account_id)
URI="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_REGION}:${ACC}:function:${FUNCTION_NAME}:test/invocations"
for METHOD in $(methods_in_resource "$API_ID" "$RID"); do
  [[ "$METHOD" == 'OPTIONS' ]] && continue
  aws apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RID" --http-method "$METHOD" \
    --type AWS_PROXY --integration-http-method POST --uri "$URI" >/dev/null
  SID="mod7-${SUFFIX}-test-${METHOD}"
  aws lambda remove-permission --function-name "$FUNCTION_NAME" --qualifier test --statement-id "$SID" >/dev/null 2>&1 || true
  aws lambda add-permission --function-name "$FUNCTION_NAME" --qualifier test --statement-id "$SID" \
    --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${AWS_REGION}:${ACC}:${API_ID}/*/${METHOD}/clientes/*/cuentas" >/dev/null
done
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name test --description 'Integración Lambda test' >/dev/null
store_env TEST_API_ID "$API_ID"
echo "TEST Lambda URL: https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/test"
