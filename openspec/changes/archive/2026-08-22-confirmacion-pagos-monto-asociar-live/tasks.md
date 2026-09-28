## 1. Backend puente-tienda

- [x] 1.1 409 MONTO_DISTINTO en asignar sin confirmar
- [x] 1.2 Confirmación sobrepago con origen devolución OF
- [x] 1.3 Faltante venta: reapertura ticket (`FaltanteQrCreditoService`) sin CxC auto
- [x] 1.4 DTO respuesta con `abrirCxcManual`, ticket/recibo/montos/faltante
- [x] 1.5 Pendientes CxC QR con sesionId correcto para el panel

## 2. Backend pos-relational

- [x] 2.1 `AbrirCuentaPorCobrarRequest.historialElectronicoId`
- [x] 2.2 `retargetHreConfirmadoAAbono` al crear crédito

## 3. Frontend

- [x] 3.1 Modal monto distinto (esperado/recibido)
- [x] 3.2 `onCreditoDesdeFaltanteQr` → Abrir CxC bloqueado
- [x] 3.3 Asociar: open inmediato + poll `getSinAsignar` en el dialog
- [x] 3.4 Panel polling pendientes de sesión

## 4. Documentación dual

- [x] 4.1 Spec OpenSpec `confirmacion-pagos-electronicos`
- [x] 4.2 Narrativo `contextos-ia/confirmacion-pagos-electronicos.md`
- [x] 4.3 Rule Cursor FE + puente DUAL-DOCS
