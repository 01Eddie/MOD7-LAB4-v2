# Guía del instructor — configuración previa

Este archivo **no** contiene secretos y está destinado a preparar la cuenta compartida. Se recomienda revisar políticas IAM antes de distribuir permisos.

## 1. Catálogo S3 (sin CloudFront)

Desde AWS CloudShell con permisos suficientes:

```bash
export CATALOG_BUCKET_NAME="mod7-api-catalog-UNICO-$(aws sts get-caller-identity --query Account --output text)"
export AWS_REGION=us-east-1
export NUM_STUDENTS=35
bash api-catalog/deploy-catalog.sh
```

La salida imprime una URL HTTP `s3-website`. S3 Static Website Hosting **no ofrece HTTPS por sí solo**. El bucket es de lectura pública: usar exclusivamente datos simulados y un bucket dedicado. Si la cuenta tiene controles que impiden acceso público, **no quitarlos sin aprobación**. Se puede usar el catálogo solo como almacenamiento de metadatos, sin web pública.

## 2. Rol de ejecución Lambda reutilizable

El instructor debe crear previamente un rol `mod7-lambda-execution-role` con confianza en `lambda.amazonaws.com` y política administrada `AWSLambdaBasicExecutionRole` para CloudWatch Logs. Compartir únicamente ARN, no las credenciales del rol. El código Lambda de este ejercicio no accede a servicios de datos.

## 3. Permisos de alumnos

Crear usuarios/roles con permisos estrictamente acotados a recursos `mod7-...-<suffix>` y `s3://<bucket>/catalog/<suffix>/*`. **API Gateway REST no soporta un aislamiento IAM uniforme para todas las acciones por nombre de API**: para una clase compartida, valorar rol de instructor que ejecute los despliegues o cuentas aisladas si se requiere separación fuerte. No asignar AdministratorAccess como medida por defecto.

Revisar como mínimo: `apigateway:GET/POST/PUT/PATCH/DELETE`, `lambda:CreateFunction/UpdateFunctionCode/PublishVersion/CreateAlias/UpdateAlias/Get*/AddPermission/RemovePermission/DeleteFunction`, `iam:PassRole` limitado al rol, `s3:PutObject/DeleteObject` en prefijo del alumno, `s3:HeadBucket`/acceso al bucket, `sts:GetCallerIdentity`. Las acciones y ARN exactos deben comprobarse contra la política de la organización.

Los scripts buscan APIs por nombre; dado que algunos endpoints de API Gateway requieren recursos amplios, protegerlos con supervisión o, preferiblemente, un rol de despliegue asumible condicionado.

## 4. Coordinación de alumnos

Asignar sufijos únicos, verificar expiración de credenciales y comunicar URL del catálogo, bucket, región y role ARN. Hacer prueba piloto con un fork real **antes de clase**.

## 5. Lista de aceptación

- [ ] Contrato falla antes de corregir versión y operationId
- [ ] Contrato corregido genera MOCK, `origen=MOCK`
- [ ] Merge de implementación genera Lambda, `origen=LAMBDA`
- [ ] PROD exige API Key, TEST no
- [ ] Aprobación del POST: contrato + Lambda + promoción
- [ ] Catálogo refleja endpoints correctos
- [ ] Cleanup elimina solo el sufijo probado
- [ ] Resto de APIs de estudiantes sigue funcionando

## 6. Observaciones

- La protección de API Key se aplica al **API PROD separado**, no al stage TEST.
- El POST es simulado. No hay DynamoDB ni persistencia.
- Para producción real, se requerirían IAM/OIDC, autorización fuerte, controles WAF, HTTPS, infraestructura como código y secretos gestionados.
