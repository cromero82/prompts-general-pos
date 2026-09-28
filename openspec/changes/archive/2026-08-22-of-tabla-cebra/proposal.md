## Why

La tabla de movimientos en Financiero → Orígenes de fondos debía seguir el estilo cebra estándar del POS (clientes, productos, egresos). El fondo solo en `tr` no bastaba con Material MDC.

## What Changes

- Cebra odd/even en historial OF con fondo también en `td`.
- Hover / selección / flash de navegación mantienen prioridad sobre la cebra.

## Capabilities

### New Capabilities
- `origenes-fondos-lista`: presentación de la lista OF (tabla movimientos / densidad)

### Modified Capabilities

## Impact

- FE: `origenes-list.component.scss`
- Docs: `contextos-ia/origenes-fondos.md`
