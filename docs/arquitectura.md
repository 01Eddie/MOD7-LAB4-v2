# Arquitectura del laboratorio

El entorno PROD es **simulado con fines docentes**.

```mermaid
flowchart TB
  G[GitHub Actions] --> S[Spectral]
  S --> T[Pipeline contrato: API TEST MOCK]
  S --> L[Pipeline implementación]
  L --> F[Lambda publicada: versiones inmutables]
  F --> A[Test alias]
  F --> B[Prod alias]
  A --> X[API Gateway REST TEST / stage test]
  B --> Y[API Gateway REST PROD / stage prod]
  Y --> K[API Key + Usage Plan]
  T --> X
  X --> C[S3 catálogo del instructor]
  Y --> C
```

## Decisión importante

Se usan **dos REST APIs** independientes para impedir que `apiKeyRequired` afecte TEST. La integración de TEST usa `Lambda:test` y PROD `Lambda:prod`. Es una decisión de simplicidad y aislamiento didáctico, no la única topología empresarial posible.

## Flujo de gobernanza

```mermaid
sequenceDiagram
  actor Alumno
  participant GitHub
  participant API as API Gateway
  participant Lambda
  participant S3 as Catálogo S3
  Alumno->>GitHub: Corregir contrato y hacer commit
  GitHub->>GitHub: Spectral
  GitHub->>API: Importar MOCK a TEST
  GitHub->>S3: Publicar MOCK
  Alumno->>GitHub: PR implementación, merge
  GitHub->>Lambda: Publicar versión y alias test
  GitHub->>API: Integrar API TEST con Lambda:test
  GitHub->>S3: Publicar IMPLEMENTADO
  Alumno->>GitHub: Ejecutar promoción manual
  GitHub->>Lambda: alias prod = versión de test
  GitHub->>API: Crear/actualizar API PROD separada
  GitHub->>API: API Key y Usage Plan en PROD
  GitHub->>S3: Publicar PRODUCCION
```

## Alcance de seguridad

API Key **no autentica personas ni sustituye IAM/JWT**. Solo identifica consumidores para controles como cuotas. El catálogo S3 website se sirve por HTTP y puede ser público: no almacenar datos reales, secretos ni documentos internos.
