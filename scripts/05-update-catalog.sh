#!/usr/bin/env bash
set -euo pipefail
source scripts/_common.sh
: "${CATALOG_BUCKET:?Define CATALOG_BUCKET}"
: "${STATUS:?Define STATUS: MOCK|IMPLEMENTADO|PRODUCCION}"
case "$STATUS" in MOCK|IMPLEMENTADO|PRODUCCION) ;; *) echo 'STATUS inválido' >&2; exit 1;; esac
TEST_ID=$(get_api_id "$TEST_NAME")
PROD_ID=$(get_api_id "$PROD_NAME")
TEST_VERSION=''; PROD_VERSION=''
if aws lambda get-alias --function-name "$FUNCTION_NAME" --name test >/dev/null 2>&1; then
  TEST_VERSION=$(aws lambda get-alias --function-name "$FUNCTION_NAME" --name test --query FunctionVersion --output text)
fi
if aws lambda get-alias --function-name "$FUNCTION_NAME" --name prod >/dev/null 2>&1; then
  PROD_VERSION=$(aws lambda get-alias --function-name "$FUNCTION_NAME" --name prod --query FunctionVersion --output text)
fi
export TEST_ID PROD_ID TEST_VERSION PROD_VERSION
python3 - <<'PY'
import json,os,datetime,pathlib
r=os.environ['AWS_REGION']; s=os.environ['SUFFIX']
def endpoint(id, stage): return f'https://{id}.execute-api.{r}.amazonaws.com/{stage}' if id else None
j={'suffix':s,'apiName':f'cuentas-api-{s}','statusCode':os.environ['STATUS'],
   'version':'1.0.0','cloud':'AWS','region':r,
   'stages':{'test':endpoint(os.environ['TEST_ID'],'test'),'prod':endpoint(os.environ['PROD_ID'],'prod')},
   'lambdaVersions':{'test':os.environ['TEST_VERSION'] or None,'prod':os.environ['PROD_VERSION'] or None},
   'apiKeyRequiredInProd':bool(os.environ['PROD_ID']),
   'lastUpdated':datetime.datetime.now(datetime.timezone.utc).isoformat(),
   'repository':os.getenv('GITHUB_REPOSITORY','local')}
pathlib.Path('/tmp/mod7-metadata-'+s+'.json').write_text(json.dumps(j,indent=2))
# Publicar contrato documentado (sin extensiones AWS de integración ni endpoints ficticios).
try:
 import yaml
 spec=yaml.safe_load(pathlib.Path('contract/openapi.yaml').read_text())
except ImportError:
 raise SystemExit('PyYAML no está instalado. En pipeline se instala mediante pip.')
for path in spec.get('paths',{}).values():
 for operation in path.values():
  if isinstance(operation,dict): operation.pop('x-amazon-apigateway-integration',None)
urls=[]
for stage in ('test','prod'):
 v=j['stages'][stage]
 if v: urls.append({'url':v,'description':stage.upper()})
spec['servers']=urls
pathlib.Path('/tmp/mod7-openapi-'+s+'.json').write_text(json.dumps(spec,indent=2))
PY
aws s3 cp "/tmp/mod7-metadata-${SUFFIX}.json" "s3://${CATALOG_BUCKET}/catalog/${SUFFIX}/metadata.json" --content-type application/json >/dev/null
aws s3 cp "/tmp/mod7-openapi-${SUFFIX}.json" "s3://${CATALOG_BUCKET}/catalog/${SUFFIX}/openapi.json" --content-type application/json >/dev/null
echo "Catálogo actualizado para ${SUFFIX}, estado ${STATUS}"
