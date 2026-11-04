# Laboratorio propuesto (25–30 min): nueva operación POST

## Caso narrativo

El banco ya permite consultar cuentas bancarias ficticias mediante GET. El equipo de canales digitales solicita crear cuentas de demostración, manteniendo el proceso de gobierno basado en contratos, integración continua, pruebas y catálogo compartido. La creación será **simulada**: la respuesta 201 no implica persistencia, por lo que no aparece al consultar con GET.

## Tareas

1. En `contract/openapi.yaml`, bajo `/clientes/{cliente-id}/cuentas`, agregar la operación `post` mostrada abajo.
2. Hacer commit a `main` y verificar Spectral + MOCK. Recuerda que este pipeline reinstala MOCK en TEST temporalmente.
3. En `implementation/src/index.mjs`, cambiar `export const ENABLE_POST = false;` a `true`.
4. Crear rama `feature/post-cuentas`, abrir PR, esperar test y fusionar a main; verificar pipeline TEST.
5. Promover a PROD, probar POST (201 y 400), verificar operación en Swagger UI.

## Fragmento de contrato (insertar con indentación de 4 espacios bajo la ruta)

```yaml
    post:
      tags: [Cuentas]
      summary: Crear una cuenta simulada
      operationId: crearCuentaCliente
      parameters:
        - name: cliente-id
          in: path
          required: true
          description: Identificador de cliente
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [tipo, moneda, titular]
              properties:
                tipo: {type: string, enum: [AHORROS, CORRIENTE]}
                moneda: {type: string, enum: [PEN, USD]}
                titular: {type: string, minLength: 1}
      responses:
        '201':
          description: Creación simulada exitosa (sin persistencia)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Cuenta'
        '400':
          description: Datos inválidos
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Problema'
        '404':
          description: Cliente no encontrado
      x-amazon-apigateway-integration:
        type: mock
        requestTemplates:
          application/json: '{"statusCode": 201}'
        passthroughBehavior: never
        responses:
          default:
            statusCode: '201'
            responseTemplates:
              application/json: |
                {"numeroCuenta":"SIMULADO-0001","tipo":"AHORROS","moneda":"PEN","titular":"Cliente (Mock)","saldo":0}
```

**Nota:** El contrato de Cuenta admite atributos adicionales, por ello el resultado POST puede incluir `nota` sin incumplir esquema. En un contrato estricto, declarar explícitamente sus campos o usar un schema de respuesta específico.

## Ejemplo de prueba desde CloudShell o terminal

Sustituir el endpoint por el de la API TEST o PROD obtenido en el catálogo.

```bash
export BASE_URL="https://API_ID.execute-api.us-east-1.amazonaws.com/test"
curl -i -X POST "$BASE_URL/clientes/CLI001/cuentas" \
  -H 'Content-Type: application/json' \
  -d '{"tipo":"AHORROS","moneda":"PEN","titular":"Alumno de prueba"}'
# Esperado: HTTP 201 (después de desplegar Lambda con ENABLE_POST=true)

curl -i -X POST "$BASE_URL/clientes/CLI001/cuentas" \
  -H 'Content-Type: application/json' \
  -d '{"tipo":"INVALIDO","moneda":"PEN","titular":"Alumno"}'
# Esperado: HTTP 400
```

Para PROD añadir `-H 'x-api-key: ...'` usando la clave obtenida de API Gateway en la consola con permisos autorizados. Nunca publicar la clave en capturas, repositorios o registros.

## Evidencias

Captura del contrato POST en Swagger UI, URL de Actions con todos los jobs exitosos, salida HTTP 201 y 400, y versiones Lambda `test`/`prod` visibles en consola.
