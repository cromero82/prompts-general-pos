## Why

En sandbox el tester y la IA necesitan verificar datos reales (egresos, ventas, HRE) sin DBeaver ni acceso directo a Postgres. Ya existía reset transaccional; faltaba consulta SQL de solo lectura bajo el mismo gate de `configuracion_app`.

## What Changes

- Endpoint `POST /sandbox/consulta-bd` (admin, SELECT-only, todas las tablas).
- Flag `sistema.sandbox.habilitarEndpointConsultaBd`.
- Documentación dual (narrativo + OpenSpec capacidad `sandbox-entorno-pruebas`).

## Capabilities

### New Capabilities
- `sandbox-entorno-pruebas`: aislamiento sandbox, reset transaccional, consulta BD solo lectura, flags y UI reset.

### Modified Capabilities

## Impact

- BE: `pos-relational-data-service` (+ copia `sandbox/…`) — `SandboxAdminController`, `SandboxConsultaBdServiceImpl`
- BD: flag en `configuracion_app.sistema`
- Docs: `contextos-ia/sandbox-reset-transaccional.md`, dual docs, README, AGENTS
