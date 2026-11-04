#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
: "${CATALOG_BUCKET_NAME:?Define CATALOG_BUCKET_NAME}"
: "${AWS_REGION:?Define AWS_REGION}"
: "${NUM_STUDENTS:=35}"
# Ejemplo educativo: S3 website publica contenido por HTTP, NO HTTPS.
# Usar bucket EXCLUSIVO para material ficticio. Requiere autorización institucional
# para desbloquear acceso público a nivel bucket/cuenta.
if ! aws s3api head-bucket --bucket "$CATALOG_BUCKET_NAME" >/dev/null 2>&1; then
  if [[ "$AWS_REGION" == 'us-east-1' ]]; then
    aws s3api create-bucket --bucket "$CATALOG_BUCKET_NAME" --region "$AWS_REGION" >/dev/null
  else
    aws s3api create-bucket --bucket "$CATALOG_BUCKET_NAME" --region "$AWS_REGION" \
      --create-bucket-configuration "LocationConstraint=${AWS_REGION}" >/dev/null
  fi
fi
aws s3api put-public-access-block --bucket "$CATALOG_BUCKET_NAME" \
  --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false' >/dev/null
aws s3 website "s3://${CATALOG_BUCKET_NAME}" --index-document index.html --error-document index.html
aws s3api put-bucket-policy --bucket "$CATALOG_BUCKET_NAME" --policy "$(python3 - <<'PY'
import json,os
b=os.environ['CATALOG_BUCKET_NAME']
print(json.dumps({'Version':'2012-10-17','Statement':[{'Sid':'ReadOnlyWebsite','Effect':'Allow','Principal':'*','Action':'s3:GetObject','Resource':f'arn:aws:s3:::{b}/*'}]}))
PY
)" >/dev/null
python3 - <<'PY'
import json,os,pathlib
n=int(os.environ.get('NUM_STUDENTS','35'))
if not 1 <= n <= 99: raise SystemExit('NUM_STUDENTS debe ser 1..99')
pathlib.Path('frontend/manifest.json').write_text(json.dumps([f'{i:02}' for i in range(1,n+1)]))
PY
# No --delete: evita borrar objetos catalog/ escritos por alumnos.
aws s3 sync frontend/ "s3://${CATALOG_BUCKET_NAME}/" --exclude 'catalog/*' >/dev/null
echo "CATÁLOGO (HTTP, solo datos ficticios): http://${CATALOG_BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
