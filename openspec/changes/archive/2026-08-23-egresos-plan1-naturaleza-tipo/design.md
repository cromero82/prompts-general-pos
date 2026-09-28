## Context

Egreso hoy: fecha, valor, proveedor, OF, observación → `SALIDA_EGRESO`. Tipo solo en proveedor. OF Dueños > Cuenta del dueño clasifica/acumula; bajar saldo = egreso de pago.

## Decisions

1. Snapshot `tipo_egreso_id` en `egreso`; default desde proveedor.
2. `naturaleza` enum string (sin `RETIRO_DUENO`).
3. Inferencia de naturaleza desde nombre de tipo si falta.
4. Export CSV en FE (filtros actuales), sin endpoint Excel nuevo en Plan 1.
5. Plan 2 (Personas) fuera de alcance.

## Risks

| Riesgo | Mitigación |
|--------|------------|
| Egresos viejos sin tipo | Backfill SQL desde proveedor |
| FE cachea tipo en proveedor | Listado lee `egreso.tipoEgreso` / `naturaleza` |
