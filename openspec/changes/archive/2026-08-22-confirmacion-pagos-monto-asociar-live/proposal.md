## Why

Tras el MVP de confirmación por email, el cajero necesitaba manejar montos distintos al QR esperado, convertir faltantes en crédito con control humano, y no perder emails si abría «Asociar» antes de que llegara la notificación.

## What Changes

- Asignación con monto distinto: 409 `MONTO_DISTINTO` + confirmación (sobrepago con OF devolución; faltante con reapertura de ticket).
- Faltante venta: ya no crea CxC automática en puente; reabre ticket y FE abre modal Abrir CxC bloqueado + retarget HRE al abono.
- Modal Asociar: polling en vivo de emails sin asignar; apertura inmediata del diálogo.
- CxC QR / sesionId del panel: pendientes de abonos CxC visibles en la sesión correcta.

## Capabilities

### New Capabilities
- `confirmacion-pagos-electronicos`: comportamiento vigente del flujo email → HRE → panel → asociar / monto distinto / faltante→crédito

### Modified Capabilities
- (bootstrap brownfield: la capacidad se materializa como spec principal al archivar)

## Impact

- `puente-tienda`: ConfirmacionPagoService, FaltanteQrCreditoService, MovimientoDesdeNotificacionService, DTOs
- `pos-relational-data-service`: CuentaPorCobrarServiceImpl.retargetHreConfirmadoAAbono, AbrirCuentaPorCobrarRequest.historialElectronicoId
- `infinito-ai-front`: confirmacion-pagos-panel, asociar-notificacion-dialog, tickets.onCreditoDesdeFaltanteQr, abrir-cuenta-por-cobrar-dialog
