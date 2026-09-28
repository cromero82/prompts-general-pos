## Hecho — código en el repo

### FE
- [x] `idAcceso`: tooltip sin espacios y en minúsculas; id del botón en `metodos-pago`
- [x] `AccesoTecladoService` lee `teclas-acceso-rapido` y escucha en captura mientras Tickets está vivo
- [x] `[Shift] + dígito` por `event.code` (`Digit1`, `Digit2`)
- [x] Foco en `#productSearchInput` no bloquea; `preventDefault` no escribe el carácter
- [x] Otro input o un diálogo abierto sí bloquean
- [x] Click en el primer botón con ese `id` que no esté `metodo-pago-disabled`

### BD
- [x] Archivo `73_teclas_acceso_rapido.sql` (idempotente). `70_` no se tocó
- [ ] SQL aplicado en `controlneg_rmx_db_v02` (manual; no corrido en la sesión)

## Pendiente

- [ ] Probar en Tickets, con el caret en Buscar producto: `Shift+1` selecciona efectivo y no inserta carácter; `Shift+2` selecciona el QR si su tooltip normaliza a `bancolombia-qr`
