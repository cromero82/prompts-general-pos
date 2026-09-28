## Context

Sandbox ya tenía `POST /sandbox/reset-datos-transaccionales` gated por `habilitarEndpointResetTransacciones`. Se añade consulta paralela gated por `habilitarEndpointConsultaBd`.

## Decisions

1. **Allowlist = todas las tablas**; seguridad vía validación SELECT-only + timeout + `maxRows`, no lista blanca de nombres.
2. **Misma auth** que reset: rol `admin` + flag en `configuracion_app`.
3. **Sin UI FE** para consulta en esta entrega (API/curl / IA); el menú sandbox sigue solo para reset.
4. Capacidad OpenSpec unifica reset + consulta + aislamiento (`sandbox-entorno-pruebas`).

## Risks / Mitigations

| Riesgo | Mitigación |
|--------|------------|
| SQL injection / escritura | Rechazo DML/DDL, sin `;` múltiples, `readOnly` TX, `setMaxRows` |
| Flag en prod por error | Endpoint pensado para sandbox; sin flag → 403 |
| Queries pesadas | Timeout 15s, max 500 filas |
