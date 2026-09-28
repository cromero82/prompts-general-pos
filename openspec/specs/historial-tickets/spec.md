## Purpose

Listado e inspección de ventas cobradas (historial de recibos): filtros por estado, fecha, medio, multipago, tickets sin corte, cliente, producto, estado de notificación electrónica y detalle de productos / cajero.

## Requirements

### Requirement: Filtros de busqueda

El search de historial (`GET /historial-recibos/search`) SHALL aceptar, ademas de fecha/estado/sesion:
- `metodoPagoId` (medio visible en Tickets o linea de multipago)
- `mixto=true` (mas de un `historial_recibo_pago`)
- `sinCorte=true` (ids posteriores al ultimo corte no eliminado)
- `clienteId` (recibo de ese cliente)
- `productoId` (EXISTS en `historial_recibo_detalle` de ese producto)

Los filtros activos SHALL combinarse con AND. Un ticket Mixto SHALL aparecer al filtrar Mixto y SHALL NOT aparecer al filtrar un medio suelto.

#### Scenario: Filtrar Nequi sin corte
- **WHEN** el usuario elige medio Nequi y marca Tickets sin corte
- **THEN** solo aparecen ventas Pagadas de ese medio posteriores al ultimo cierre

#### Scenario: Filtrar cliente
- **WHEN** el usuario elige un cliente en el autocomplete
- **THEN** solo aparecen recibos de ese `clienteId`; el anonimo no se lista como nombre de cliente

#### Scenario: Filtrar producto
- **WHEN** el usuario elige un producto en el autocomplete
- **THEN** aparecen los recibos que incluyen esa linea, aunque tengan otros productos

#### Scenario: Autocomplete producto igual al selector de ventas
- **WHEN** el usuario escribe un nombre (no codigo de barras) y no esta activo "Coincidir toda la palabra"
- **THEN** el FE consulta `POST /products/busquedaPorFiltros?query=` con body `{ filtros: [], page: 0, size: 20, campoOrdenamiento: "totalVentas", orden: "desc" }` y reordena en cliente: primero nombres que empiezan por el termino, luego `totalVentas` desc

#### Scenario: Autocomplete producto por codigo de barras
- **WHEN** el termino es un codigo de barras (8-14 digitos)
- **THEN** el FE consulta `GET /products/search` (mismo camino que el selector) y ofrece el producto para filtrar

#### Scenario: Coincidir toda la palabra y Limpiar
- **WHEN** el usuario activa "Coincidir toda la palabra" o pulsa Limpiar
- **THEN** coincidir usa `GET /products/search` con `coincidirTodaPalabraIndividual=true`; Limpiar vacia el campo, quita `productoId` y recarga la lista

#### Scenario: Mixto no entra en medio suelto
- **WHEN** hay una venta con efectivo + QR y el usuario filtra Efectivo
- **THEN** esa venta no aparece; aparece al filtrar Mixto

### Requirement: Enriquecimiento de lista

Cada item del search SHALL poder incluir:
- `multipago` (boolean)
- `estadoNotificacionElectronica` (null | CREADA | CONFIRMADA | …) desde HRE
- `sesionUserId` (UUID) para resolver el cajero en cliente sin `GET /sesiones/{id}/usuario`

La UI SHALL mostrar el medio con icono (visto verde si electronico CONFIRMADA; gris si pendiente), cliente si no es anonimo, y `atendio` abreviado a la derecha.

#### Scenario: Chip coherente con panel
- **WHEN** el ticket tiene HRE CONFIRMADA
- **THEN** el visto / estado de notificacion coincide con el panel (no Pendiente)

### Requirement: Modal productos

Desde historial (o modal OF sin corte) el usuario SHALL poder abrir productos del ticket. El modal SHALL mostrar **Atendio: {nombre}** (via sesion del recibo) y el total del pie alineado a la columna Subtotal, sin etiqueta "Total lineas".

#### Scenario: Atendido visible
- **WHEN** el recibo tiene sesion con usuario resoluble
- **THEN** el modal productos muestra Atendio con el nombre del cajero

### Requirement: Panel de detalle

Al seleccionar un recibo, el panel derecho SHALL mostrar Documentos y operaciones en dos columnas: Comprobante + Estado a la izquierda; Fecha de venta + Cajero que atendio a la derecha. El pie SHALL mostrar TOTAL y el monto sin solaparse (incluido montos en millones) y con holgura respecto al FAB de opciones.

#### Scenario: Campos frente a frente
- **WHEN** hay venta seleccionada
- **THEN** Fecha de venta y Cajero quedan frente a Comprobante venta y Estado documento

#### Scenario: TOTAL no se cruza
- **WHEN** el total es de siete cifras o mas (ej. `$ 1.402.100`)
- **THEN** el label TOTAL y el monto no se intersectan

### Requirement: Modal tickets sin corte desde OF

En Orígenes de fondos, tarjetas raiz con medio de Tickets y parcial sin corte SHALL ofrecer accion que abre un dialog con la misma consulta (`metodoPagoId` + `sinCorte`). El dialog SHALL ser arrastrable, mostrar total parcial alineado con montos de fila, usuario que atendio y acceso a productos.

#### Scenario: Parcial OF = lista modal
- **WHEN** el parcial sin corte de Nequi es X y se abre el modal
- **THEN** la suma / total parcial mostrado es coherente con esas ventas y el filtro historial equivalente

### Requirement: Ciclo de prueba con reset

En sandbox, el reset transaccional SHALL dejar historial y movimientos de prueba en 0 (catalogos intactos) para sembrar escenarios de filtros. Tras reset + login (+ base inicial si aplica), Historial SHALL estar vacio y tickets sin corte SHALL ser 0.

#### Scenario: Punto cero
- **WHEN** admin ejecuta Reset datos transaccionales y vuelve a entrar
- **THEN** no hay ventas en Historial y OF no muestra tickets sin corte (salvo base inicial en movimientos)

### Requirement: Consecutivo VTA en lista y migracion

Cada venta pagada (`historial_recibo.estado_id = 2`) SHALL tener un `documento_venta` con consecutivo `VTA-` + 6 digitos (mismo formato que `ConsecutivoDocumentoService.nextConsecutivo(VENTA)`, ej. `VTA-000001`). El search SHALL devolver `documentoVentaConsecutivo` y la lista SHALL mostrarlo; MUST NOT caer a `#id` si el documento existe.

La BD v02 (schema con los `NN_…` en orden) SHALL:
- crear esos documentos en `05_backfill_documento_venta.sql` (prefijo `VTA-`, no `VTA-LEGACY-`)
- dejar `consecutivo_documento` VENTA en el maximo usado para que la siguiente venta sea el siguiente numero
- aplicar `32_historial_recibos_electronicos_nombre_cliente.sql` antes de usar Historial (sin esa columna el search 500 y la lista queda vacia)
- aplicar `62_normalize_documento_venta_vta.sql` si un ensayo previo dejo `VTA-LEGACY-*`

Un fallo al enriquecer HRE (notificacion electronica) MUST NOT tumbar el search: la lista de tickets sigue visible.

#### Scenario: Lista tras migrate v02
- **WHEN** el operador abre Historial Tickets sobre una BD migrada desde prod
- **THEN** aparecen las ventas pagadas y cada fila muestra `VTA-######` (no `#id` ni `VTA-LEGACY-`)

#### Scenario: HRE incompleto no vacia la lista
- **WHEN** falta una columna de `historial_recibos_electronicos` usada solo para el chip electronico
- **THEN** el search sigue devolviendo tickets (el chip puede quedar vacio)

### Requirement: Anular y restaurar segun donde esta el dinero

Anular (`PUT` que pasa una venta pagada a anulado) y Restaurar (`POST /{id}/restaurar-ticket`) SHALL ejecutarse solo si el dinero aun no se conto en un corte y la venta no tiene cartera.

- Sin corte: `historial_recibo.id` mayor que `resolveUltimoHistorialReciboWatermark()`. Anular deja nota credito y reintegra inventario. Antes de anular, el usuario SHALL elegir el origen del reembolso (por defecto Caja: Efectivo). Si ese origen es el del medio, MUST NOT escribir ledger. Si es otro, SHALL registrar `SALIDA_DEVOLUCION_VENTA` y `ENTRADA_CRUCE_DEVOLUCION_VENTA` igual que la devolucion de una edicion. Restaurar reabre el ticket y retira el historial original. Editar en ventas abre un borrador sin nota credito ni borrado. **Sin cambios en productos** SHALL descartar el borrador y dejar el mismo historial y el mismo comprobante. Un cobro de esa edicion con cambios, o una devolucion porque el total bajo, SHALL anular el comprobante original, borrar ese historial y emitir el comprobante del total nuevo (`69_documento_venta_historial_nullable.sql`). La devolucion SHALL pedir origen de fondos, por defecto Caja: Efectivo. Si ese origen es el del medio de la venta, MUST NOT escribir ledger: los tickets sin corte de ese medio bajan la diferencia. Si es otro, SHALL registrar `SALIDA_DEVOLUCION_VENTA` en el elegido y `ENTRADA_CRUCE_DEVOLUCION_VENTA` en el del medio. Editar una venta ya contada o en cartera SHALL rechazarse igual que anular, con 409.
- Ya contada (`id` menor o igual al watermark, y watermark mayor que 0) o con `cuenta_por_cobrar`: el backend SHALL rechazar con `IllegalStateException` (HTTP 409, cuerpo `{message}`) y MUST NOT crear nota credito, MUST NOT mover inventario y MUST NOT tocar origenes de fondos. El mensaje SHALL decir que la devolucion o la correccion del medio queda pendiente. MUST NOT pedir eliminar o dividir el corte.
- El guard de anular SHALL aplicar solo en la transicion pagado a anulado, no a cualquier `PUT`.
- El watermark SHALL ser el mismo de `sinCorte` (ultimo corte vigente por id). Limitacion conocida: no es el maximo watermark historico. No se corrige en este cambio.

El filtro Pagado y el modal de tickets sin corte SHALL resolver el estado pagado por sigla `PAG` (id 2), no por `P`.

#### Scenario: Venta aun sin corte
- **WHEN** el cajero anula o restaura una venta pagada cuyo id es posterior al ultimo corte y que no tiene cartera
- **THEN** la operacion sigue el flujo actual (nota credito e inventario, o reapertura del ticket)

#### Scenario: Venta ya contada
- **WHEN** el cajero anula o restaura una venta cuyo id ya quedo dentro del ultimo corte
- **THEN** responde 409, la venta sigue pagada y no hay movimiento de origen de fondos

#### Scenario: Venta en cartera
- **WHEN** el cajero anula o restaura una venta con cuenta por cobrar
- **THEN** responde 409, la cartera no cambia y no sale dinero

### Requirement: Pendiente reembolso y medio mal cobrado

La salida de dinero y el traslado de medio NO forman parte de este cambio. La spec SHALL dejar nombrado el pendiente:

| Donde esta el dinero | Que falta |
|---|---|
| Sin corte | Nada: anular y restaurar actuales |
| Corte generado | Nota credito + inventario + salida del mismo medio y OF, recogida por el corte siguiente. Sin elegir aun si esa salida es egreso con naturaleza propia o un movimiento de ledger que no sea `REVERSO_ENTRADA_VENTA` |
| Cartera, devolver parte y quedar debiendo 0 con plata de mas | Nota credito por lo devuelto; primero apaga el saldo y el resto sale en efectivo |
| Cartera, lo pagado ya cubre lo que se queda | Nota credito y cierre de la CxC con motivo de devolucion; no sale plata; no usar `valor_perdida_costo` |
| Medio mal cobrado y corte ya generado | Traslado entre origenes de fondos mas nota credito de traza. No una salida y una venta nueva |

#### Scenario: Corte de ayer intacto
- **WHEN** el tendero quiere devolver una venta que ya entro en un corte
- **THEN** el corte anterior no se reabre ni se divide; la devolucion queda pendiente de la salida descrita arriba

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/historial-tickets.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.6 / §4.11 / §10.9. La correccion de migrate (VTA + `32_`) SHALL quedar tambien en `MIGRATE-TIENDA-INFINITO-V02.md` y `MIGRATE-PROD-TO-DIAN-V2.md` para la aplicacion en produccion v02.
