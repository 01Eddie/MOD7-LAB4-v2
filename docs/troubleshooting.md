# Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| Spectral falla | Errores intencionales, reglas estándar | Revisar log y `contract/openapi.yaml`; corregir las dos marcas del laboratorio |
| `ExpiredToken` o `InvalidClientTokenId` | Credenciales temporales caducadas | Renovar los GitHub Secrets del fork y reejecutar |
| `AccessDenied` en `iam:PassRole` | Alumno no autorizado para rol de Lambda | Instructor: otorgar `iam:PassRole` solo al rol designado |
| `AccessDenied` en S3 | Bucket/prefijo no permitido | Instructor: habilitar `catalog/<suffix>/*` para alumno |
| `403` en sitio web S3 | Bloqueo de acceso público organizacional | Instructor: verificar política institucional; no desactivar guardrails sin aprobación |
| `403` en PROD sin clave | Esperado | El endpoint PROD exige x-api-key |
| `403` en PROD con clave | Propagación Usage Plan o clave no asociada | Reintentar y revisar Usage Plan; no registrar valor de clave en logs |
| `502` desde API Gateway | Permiso Lambda, handler o integración | Consultar CloudWatch y verificar `Lambda:test`/`Lambda:prod` |
| Prueba MOCK responde LAMBDA | Estado anterior no reemplazado | Volver a ejecutar pipeline de contrato |
| TEST responde MOCK después de editar contrato | El pipeline de contrato importa la definición MOCK | Ejecutar de nuevo el pipeline de implementación |
| Catálogo no se actualiza | Caché o falta de publicación | Refrescar y revisar último step del workflow |
| Error en Swagger UI Try it out | CORS o clave de PROD | Para verificación usar curl/CloudShell; en navegador revisar preflight |

**Nunca pegues Access Keys, Session Tokens ni valores de API Key en incidencias o capturas.**
