## Why

El tipo de gasto vivía solo en el proveedor: filtrar/reclasificar era frágil y no había naturaleza contable mínima. Plan 1 fija snapshot de tipo + naturaleza en el egreso y export CSV, sin Personas (Plan 2).

## What Changes

- Columnas `egreso.tipo_egreso_id`, `egreso.naturaleza` + backfill
- Create/update/search usan tipo/naturaleza del egreso
- FE: selects en formulario, columna/filtro naturaleza, export CSV
- Docs: OpenSpec + narrativo egresos (Cuenta del dueño = clasificación)

## Capabilities

### New Capabilities
- `egresos-naturaleza-tipo`: tipo snapshot, naturaleza, filtros, export; regla dueño vs pago

### Modified Capabilities

## Impact

- BE: `Egreso`, `EgresoServiceImpl`, `EgresoRepository`, SQL `46_…`
- FE: `egreso-edit`, `egreso-list`, `egresos.service`, util entrada inventario
- Docs: `contextos-ia/egresos.md`, dual docs, CONTEXTO-TESTER breve
