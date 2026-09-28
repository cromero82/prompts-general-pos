## Why

El cajero necesita seguir la plata cuando un saldo pasa de OF en OF (ej. QR Bancolombia → Sin clasificar → Caja menor) sin perder el contexto del movimiento hermano.

## What Changes

- API para obtener ambas patas de un traslado por `grupoTrasladoId`.
- Botones Atrás / Adelante en filas TRASLADO/DISTRIBUCION de la lista OF.
- Al navegar: cambia el OF enfocado, resalta tarjeta y fila del movimiento par.

## Capabilities

### New Capabilities
- `navegacion-traslados-of`: navegación hop-a-hop entre patas del mismo grupo de traslado

### Modified Capabilities

## Impact

- `pos-relational-data-service`: `GET /movimientos-origen-fondos/grupo/{grupoTrasladoId}`
- `infinito-ai-front`: `origenes-list`, `movimiento-origen-fondos.service.ts`
