#!/usr/bin/env bash
set -euo pipefail
: "${SUFFIX:?Define SUFFIX (ej. 07)}"
: "${AWS_REGION:?Define AWS_REGION (ej. us-east-1)}"
[[ "$SUFFIX" =~ ^[0-9]{2}$ ]] || { echo 'SUFFIX debe ser de dos dígitos' >&2; exit 1; }
export AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_PAGER=''
TEST_NAME="mod7-cuentas-test-${SUFFIX}"
PROD_NAME="mod7-cuentas-prod-${SUFFIX}"
FUNCTION_NAME="mod7-cuentas-lambda-${SUFFIX}"
get_api_id() {
  local name="$1" id
  id=$(aws apigateway get-rest-apis --limit 500 --query "items[?name=='${name}'].id | [0]" --output text)
  [[ "$id" != 'None' ]] && [[ -n "$id" ]] && printf '%s' "$id" || true
}
resource_id() {
  aws apigateway get-resources --rest-api-id "$1" --limit 500 --query "items[?path=='/clientes/{cliente-id}/cuentas'].id | [0]" --output text
}
methods_in_resource() {
  aws apigateway get-resource --rest-api-id "$1" --resource-id "$2" --query 'keys(resourceMethods)' --output text
}
store_env() { if [[ -n "${GITHUB_ENV:-}" ]]; then printf '%s=%s\n' "$1" "$2" >> "$GITHUB_ENV"; fi; }
account_id() { aws sts get-caller-identity --query Account --output text; }
