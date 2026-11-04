# Catálogo S3 exclusivo del instructor

No se usa CloudFront. El hosting estático de Amazon S3 requiere un bucket con permisos públicos de lectura de objetos y se expone por **HTTP**. Solo información educativa ficticia.

Preparación desde la raíz del repositorio:

```bash
export AWS_REGION=us-east-1
export CATALOG_BUCKET_NAME=mod7-catalog-NOMBRE-UNICO
export NUM_STUDENTS=35
bash api-catalog/deploy-catalog.sh
```

El script no borra los prefijos `catalog/XX/`. Comparta con alumnos `CATALOG_BUCKET`, región, URL del sitio web y sufijo individual. `destroy-catalog.sh` es **solo instructor** y exige confirmación explícita.

La página de Swagger UI carga recursos estáticos desde un CDN público (unpkg.com). Puede omitirse su uso si la institución prohíbe dependencias de terceros.
