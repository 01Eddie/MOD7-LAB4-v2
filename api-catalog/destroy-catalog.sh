#!/usr/bin/env bash
set -euo pipefail
: "${CATALOG_BUCKET_NAME:?Define CATALOG_BUCKET_NAME}"
[[ "${CONFIRM_DELETE_CATALOG:-}" == "DELETE-CATALOG" ]] || { echo 'Define CONFIRM_DELETE_CATALOG=DELETE-CATALOG' >&2; exit 1; }
# SOLO INSTRUCTOR. Elimina todo el bucket del catálogo, no ejecutar durante una clase.
aws s3 rb "s3://${CATALOG_BUCKET_NAME}" --force
