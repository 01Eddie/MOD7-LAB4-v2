# Prerrequisitos del alumno

1. Cuenta personal GitHub con Actions habilitado.
2. Acceso AWS en la cuenta compartida con permisos preparados por el instructor.
3. Sufijo único de 2 dígitos (01..99). No reutilizar entre alumnos.
4. Región, ARN de rol Lambda y bucket central proporcionados por el instructor.
5. Permisos AWS API Gateway REST, Lambda, CloudWatch, S3 en `catalog/<suffix>/` e IAM `PassRole` restringido al rol Lambda.
6. Navegador y opción de usar AWS CloudShell para pruebas con `curl`.

En **Settings → Secrets and variables → Actions** del fork configurar:

### Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` **solo si se usan credenciales temporales**.

### Variables
- `SUFFIX` (por ejemplo `07`)
- `AWS_REGION` (por ejemplo `us-east-1`)
- `CATALOG_BUCKET` (bucket del instructor)
- `LAMBDA_ROLE_ARN` (rol de ejecución precreado)

> Si el instructor habilita OIDC por repositorio, debe adaptar `configure-aws-credentials` a `role-to-assume` y otorgar `id-token: write`. Esta distribución utiliza credenciales AWS por simplicidad docente. Nunca incluirlas en commits.

Los Actions pueden requerir habilitación en el fork. Si el fork no tiene Actions habilitado, abrir pestaña Actions y confirmarlo.
