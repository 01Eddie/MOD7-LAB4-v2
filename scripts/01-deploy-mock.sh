#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
python3 - <<'PY'
from pathlib import Path
p=Path('contract/openapi.yaml').read_text()
if 'version: ""' in p or 'operationId: listarCuentasCliente' not in p.replace('# LAB: descomentar operationId: listarCuentasCliente',''):
    raise SystemExit('Corrige primero los errores intencionales de OpenAPI')
PY
# En este paso se importa el contrato completo: el stage TEST vuelve a MOCK.
# La API PROD (independiente) no se altera.
EXISTING=$(get_api_id "$TEST_NAME")
if [[ -n "$EXISTING" ]]; then
  echo "Actualizando API TEST $EXISTING (volverá a MOCK)"
  aws apigateway put-rest-api --rest-api-id "$EXISTING" --mode overwrite --body fileb://contract/openapi.yaml >/dev/null
  API_ID="$EXISTING"
else
  API_ID=$(aws apigateway import-rest-api --body fileb://contract/openapi.yaml --parameters endpointConfigurationTypes=REGIONAL --query id --output text)
fi
# Se asigna un nombre distintivo después de importar.
aws apigateway update-rest-api --rest-api-id "$API_ID" --patch-operations "op=replace,path=/name,value=${TEST_NAME}" >/dev/null
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name test --description "Contrato MOCK - ${SUFFIX}" >/dev/null
store_env API_ID "$API_ID"
store_env TEST_API_ID "$API_ID"
echo "TEST MOCK URL: https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/test"
