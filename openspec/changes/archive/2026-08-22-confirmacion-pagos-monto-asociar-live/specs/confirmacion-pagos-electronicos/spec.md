## ADDED Requirements

### Requirement: Modal Asociar con escucha en vivo

Al abrir «Asociar pago bancario», el diálogo SHALL hacer polling de notificaciones sin asignar mientras esté abierto y MUST abrirse de inmediato.

#### Scenario: Email llega con el modal abierto
- **WHEN** no había emails al abrir Asociar y luego llega uno parseado
- **THEN** aparece en la lista del modal sin cerrar/reabrir

### Requirement: Faltante QR → crédito manual del cajero

Tras confirmar faltante en venta, el sistema SHALL reabrir ticket y el FE SHALL abrir Abrir CxC con montos bloqueados; al crear crédito con `historialElectronicoId` el BE SHALL retargetear el HRE al abono.

#### Scenario: Sin CxC automática en puente
- **WHEN** se confirma faltante de una venta QR
- **THEN** no se crea la cuenta por cobrar completa dentro de puente-tienda; queda el ticket reabierto para flujo manual
