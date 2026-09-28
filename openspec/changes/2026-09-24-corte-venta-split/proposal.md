## Why

Un corte de cierre tomó **dos días en un solo corte** y después se registraron egresos
con ese dinero. Eliminar el corte no era opción: la plata distribuida a Caja Menor ya
se había gastado, así que revertir dejaba saldos negativos. Un intento previo hizo un
`REVERSO_ENTRADA_VENTA` suelto (sin su traslado) y el saldo quedó en −350.000.

Hacía falta una corrección que **no cambie la plata** —mismos totales, mismos saldos
finales— y que solo reorganice el registro del corte en el tiempo, con traza para DIAN.

## What Changes

- Capacidad OpenSpec nueva `corte-venta-split` (contrato vigente en `openspec/specs/`).
- **Eliminar**: se bloquea si CUALQUIER OF tocada por el corte (medios de pago y cajas
  destino) tuvo movimientos posteriores, no solo las cajas destino; y los reversos
  cambian de orden para no pasar por saldo negativo.
- **Dividir (SPLIT)**: corte original a `estado = 'dividido'`, reverso + asiento puente
  + re-corte por partición, todo en una transacción, con motivo obligatorio.
- **Modo editor** (una partición): deja traza `tipo = 'EDICION'` sin tocar el ledger.
- `dividido` se trata como no vigente en Ingresos, watermarks y «último corte».
- Migración aditiva `68_corte_venta_split.sql` (sin tocar queries de saldo).

## Capabilities

### New Capabilities
- `corte-venta-split`: Eliminar bloqueado con motivo, Dividir con reverso+puente+re-corte,
  editor trazado, estado `dividido` fuera de circulación, prorrateo editable.

### Modified Capabilities
- `ingresos-dashboard`: el dashboard excluye los cortes en estado `dividido`.

## Impact

- `pos-relational-data-service`: `CorteVentaService(.Impl)`, `MovimientoOrigenFondosService(.Impl)`,
  `CorteVentaRepository`, `CorteVentaDetalleRepository`, `MovimientoOrigenFondosRepository`,
  `HistorialReciboServiceImpl`, entidades `CorteVentaCorreccion(+Detalle)`, enum
  `TipoMovimientoOrigenFondos`, `CorteVentaController`, migración `68_`.
- `infinito-ai-front`: `ingresos.component.*`, nuevo `dividir-corte-dialog`,
  `corte-venta.service.ts`, `origenes-list.component.ts`.
- Docs: `contextos-ia/corte-venta-split.md`, `CONTEXTO-TESTER-POS.md` §4.9 / §10.1,
  `ayuda-documental/corte-venta-split/`.
- Reset transaccional: incluir las dos tablas de corrección.

## Non-goals

- **Soft-supersede** (marcar filas reemplazadas y filtrarlas en las queries de saldo):
  descartado a propósito; no se cambia el sistema de consulta por un evento aislado.
- Tocar egresos ya registrados: el split no los modifica.
- Recalcular hacia atrás los `saldoAntes/saldoDespues` ya persistidos.
- Arqueo físico por partición: los cortes nuevos son `SOLO_VISIBLE`, sin Contado ni desfase.
- Cambiar el flujo normal de cierre de turno ni el asistente de conteo de billetes.
