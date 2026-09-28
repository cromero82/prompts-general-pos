# Contexto IA — Sandbox (entorno de pruebas)

**Última actualización:** 2026-09-03.  
**OpenSpec:** `openspec/specs/sandbox-entorno-pruebas/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` (ambientes + §4.6 / §10.9) + oleada `ACTUALIZACION-QA-2026-09-03.md`

## Objetivo

Entorno de pruebas paralelo a desarrollo: misma app, BD y puertos distintos.
El tester / la IA pueden:

1. **Resetear** solo transacciones (menú admin o API).
2. **Consultar** cualquier tabla en solo lectura (`POST /sandbox/consulta-bd`) para verificar escenarios (personas, egresos, ledger, HRE, etc.).

## Dónde vive el código

| Rol | Ruta |
|---|---|
| Desarrollo (inestable) | `/Users/carlosromero/Documents/dev/repos/{proyecto}` |
| Sandbox / tester (estable) | `/Users/carlosromero/Documents/dev/repos/sandbox/{proyecto}` |

Proyectos en sandbox: `infinito-ai-front`, `infinito-security`, `pos-relational-data-service`, `puente-tienda`, `infinito-smtp-service`.

Arranque (cheat sheet de comandos, local + puente sandbox): `ARRANQUE-LOCAL-Y-SANDBOX.md`.  
Launcher (tres ambientes, Caddy/puente): `contextos-ia/ambientes-launcher-tienda-infinito.md`.  
Stack tester: `cd .../repos/sandbox && ./up.sh` (o `./up.sh --tunnel`).
Tras pull: `./restart.sh --tunnel` (down + compilar MS + up). Los scripts reales deben vivir **en** `sandbox/infinito-ai-front/scripts/sandbox/` (si solo hay stubs “Delegando…”, el restart entra en bucle).
Docs: `sandbox/README.md` y `sandbox/infinito-ai-front/scripts/sandbox/README.md`.

Desde el front de **desarrollo**, `npm run sandbox:up` / `sandbox:restart*` solo **delegan** al árbol `repos/sandbox`.

## BD

| | Dev | Sandbox |
|---|---|---|
| Nombre | `controlneg_rmx_db` | `controlneg_rmx_db_sandbox` |
| Clonar | — | `sandbox/infinito-ai-front/scripts/sandbox/clone-db.sh` |

Tras clone, ambas deben coincidir en conteos (ventas, OF, productos, `configuracion_app`). Migraciones egreso/persona: SQL `46_`…`49_` en ambas si aplica.

## Flags en `configuracion_app` (key `sistema`)

```json
{
  "sandbox": {
    "habilitarEndpointResetTransacciones": true,
    "habilitarEndpointConsultaBd": true
  }
}
```

Sin el flag correspondiente en `true`, el endpoint responde 403.

## Endpoints (pos-relational-data-service)

API sandbox típica: `http://127.0.0.1:8188` (perfil `application-sandbox.properties`).

### Reset transaccional

- `POST /sandbox/reset-datos-transaccionales`
- Rol: `admin`
- Gate: `habilitarEndpointResetTransacciones`
- Implementación: `SandboxAdminController` + `ResetTransaccionesSandboxServiceImpl` (TRUNCATE JDBC `v3-jdbc`; no `ScriptUtils`/`DO $$`)
- Script de referencia: `sql/reset-tablas-financieras-transaccionales-v3.sql`
- Fuente canónica docs: `prompts-general-pos/reset-tablas-financieras-transaccionales-v3.sql`
- Efecto: vacía ventas/cortes/ledger/egresos/CxC/correos recibidos (HRE); **conserva** OF, medios, productos, clientes, **plantillas de correo**, personas, tipos egreso, etc.
- **Punto cero para Historial:** lista vacía, tickets sin corte = 0, movimientos OF en 0 (salvo base inicial tras login). Sembrar un set corto y validar filtros (`CONTEXTO-TESTER-POS.md` §4.6). Si el ciclo se ensucia, reset otra vez.

### Consulta BD (solo SELECT)

Para que tester/IA verifiquen datos sin DBeaver.

- `POST /sandbox/consulta-bd`
- Rol: `admin`
- Gate: `habilitarEndpointConsultaBd`
- Body: `{ "sql": "SELECT …", "maxRows": 100 }` (`maxRows` opcional; default 100, máx 500)
- Allowlist: **todas** las tablas; solo `SELECT` / `WITH … SELECT` (sin DML/DDL, sin `;` múltiples, timeout 15s)
- Respuesta: `{ ok, columns, rows, rowCount, truncated, maxRows }`
- Implementación: `SandboxConsultaBdServiceImpl`

Ejemplo:

```bash
curl -s -X POST "$API/sandbox/consulta-bd" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sql":"select * from egreso ORDER BY id DESC LIMIT 10","maxRows":10}'
```

Útiles para la oleada 2026-08-26: `persona`, `egreso`, `movimiento_origen_fondos` (`origen_tipo = 'QR_MONTO_DISTINTO'`), `historial_recibos_electronicos`, `historial_recibo`, `historial_recibo_pago`.

## Frontend (copia sandbox)

- `environment.sandbox === true` solo en `environment.sandbox.ts`
- Menú admin (después de Copias de seguridad): **Reset datos transaccionales** (`mat:warning`)
- Servicio: `CopiasSeguridadService.resetDatosTransaccionales()`
- Consulta BD: **sin UI** en esta entrega (API / IA)

## Perfil Spring sandbox

`application-sandbox.properties`: puerto `8188`, JDBC → `controlneg_rmx_db_sandbox`.
Abrir el proyecto bajo `.../repos/sandbox/pos-relational-data-service`.
