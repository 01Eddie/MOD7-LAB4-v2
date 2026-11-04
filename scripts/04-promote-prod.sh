#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
TEST_API_ID=$(get_api_id "$TEST_NAME")
[[ -n "$TEST_API_ID" ]] || { echo 'No existe API TEST' >&2; exit 1; }
TEST_VERSION=$(aws lambda get-alias --function-name "$FUNCTION_NAME" --name test --query FunctionVersion --output text)
[[ "$TEST_VERSION" =~ ^[0-9]+$ ]] || { echo 'Alias test inválido' >&2; exit 1; }
# Se usa API Gateway INDEPENDIENTE en PROD para aislar API keys y deployments.
PROD_API_ID=$(get_api_id "$PROD_NAME")
if [[ -z "$PROD_API_ID" ]]; then
  PROD_API_ID=$(aws apigateway import-rest-api --body fileb://contract/openapi.yaml \
    --parameters endpointConfigurationTypes=REGIONAL --query id --output text)
  aws apigateway update-rest-api --rest-api-id "$PROD_API_ID" --patch-operations "op=replace,path=/name,value=${PROD_NAME}" >/dev/null
else
  aws apigateway put-rest-api --rest-api-id "$PROD_API_ID" --mode overwrite --body fileb://contract/openapi.yaml >/dev/null
fi
# put-rest-api puede reemplazar el nombre del API; restablecerlo también en reimportaciones.
aws apigateway update-rest-api --rest-api-id "$PROD_API_ID" --patch-operations "op=replace,path=/name,value=${PROD_NAME}" >/dev/null
if aws lambda get-alias --function-name "$FUNCTION_NAME" --name prod >/dev/null 2>&1; then
  aws lambda update-alias --function-name "$FUNCTION_NAME" --name prod --function-version "$TEST_VERSION" >/dev/null
else
  aws lambda create-alias --function-name "$FUNCTION_NAME" --name prod --function-version "$TEST_VERSION" >/dev/null
fi
RID=$(resource_id "$PROD_API_ID")
[[ "$RID" != 'None' ]] || { echo 'Recurso cuentas inexistente' >&2; exit 1; }
ACC=$(account_id)
URI="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_REGION}:${ACC}:function:${FUNCTION_NAME}:prod/invocations"
for METHOD in $(methods_in_resource "$PROD_API_ID" "$RID"); do
  [[ "$METHOD" == 'OPTIONS' ]] && continue
  aws apigateway put-integration --rest-api-id "$PROD_API_ID" --resource-id "$RID" --http-method "$METHOD" \
    --type AWS_PROXY --integration-http-method POST --uri "$URI" >/dev/null
  aws apigateway update-method --rest-api-id "$PROD_API_ID" --resource-id "$RID" --http-method "$METHOD" \
    --patch-operations op=replace,path=/apiKeyRequired,value=true >/dev/null
  SID="mod7-${SUFFIX}-prod-${METHOD}"
  aws lambda remove-permission --function-name "$FUNCTION_NAME" --qualifier prod --statement-id "$SID" >/dev/null 2>&1 || true
  aws lambda add-permission --function-name "$FUNCTION_NAME" --qualifier prod --statement-id "$SID" \
    --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${AWS_REGION}:${ACC}:${PROD_API_ID}/*/${METHOD}/clientes/*/cuentas" >/dev/null
done
aws apigateway create-deployment --rest-api-id "$PROD_API_ID" --stage-name prod --description "Version Lambda ${TEST_VERSION}" >/dev/null
PLAN_NAME="mod7-plan-${SUFFIX}"
KEY_NAME="mod7-key-${SUFFIX}"
PLAN_ID=$(aws apigateway get-usage-plans --limit 500 --query "items[?name=='${PLAN_NAME}'].id | [0]" --output text)
if [[ "$PLAN_ID" == 'None' ]]; then
  PLAN_ID=$(aws apigateway create-usage-plan --name "$PLAN_NAME" --api-stages "apiId=${PROD_API_ID},stage=prod" \
     --throttle burstLimit=10,rateLimit=5 --quota limit=1000,period=DAY --query id --output text)
else
  aws apigateway update-usage-plan --usage-plan-id "$PLAN_ID" \
     --patch-operations "op=add,path=/apiStages,value=${PROD_API_ID}:prod" >/dev/null 2>&1 || true
fi
KEY_ID=$(aws apigateway get-api-keys --limit 500 --query "items[?name=='${KEY_NAME}'].id | [0]" --output text)
if [[ "$KEY_ID" == 'None' ]]; then
  KEY_ID=$(aws apigateway create-api-key --name "$KEY_NAME" --enabled --query id --output text)
fi
EXISTING=$(aws apigateway get-usage-plan-keys --usage-plan-id "$PLAN_ID" --query "items[?id=='${KEY_ID}'].id | [0]" --output text)
if [[ "$EXISTING" == 'None' ]]; then
  aws apigateway create-usage-plan-key --usage-plan-id "$PLAN_ID" --key-id "$KEY_ID" --key-type API_KEY >/dev/null
fi
store_env PROD_API_ID "$PROD_API_ID"
store_env PROD_KEY_ID "$KEY_ID"
store_env PROD_VERSION "$TEST_VERSION"
echo "PROD listo: API ID ${PROD_API_ID}, version ${TEST_VERSION}; clave NO impresa"
