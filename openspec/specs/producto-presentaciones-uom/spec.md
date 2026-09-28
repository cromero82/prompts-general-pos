## Purpose

Modelar venta por presentación/UoM (paquete vs unidad/menudeo) sin perder traza en el ticket, con stock canónico en unidad base, y UX de ticket/selector coherente para el cajero.

## Requirements

### Requirement: Presentaciones vendibles

El sistema SHALL persistir cero o más presentaciones por producto en `producto_presentacion` con codigo (`PAQUETE`, `UNIDAD`, …), `factor_a_base` > 0, `precio_venta`, opcional `codigo_barras_alt`, y una presentación default de venta.

#### Scenario: Producto con menudeo
- **WHEN** un producto tiene `precio_unidad` > 0
- **THEN** existen presentaciones activas PAQUETE y UNIDAD (tras ensure/backfill)

#### Scenario: Producto sin menudeo
- **WHEN** no hay precio_unidad
- **THEN** existe al menos PAQUETE default

### Requirement: Identidad de linea de ticket

Las lineas de `recibo_detalle` (y espejos historial/edicion) SHALL referenciar `presentacion_id` y guardar snapshots de precio/factor y `cantidad_base`.

El cliente (y el servidor al fusionar historicos) SHALL tratar `(recibo, presentacion_id)` como identidad de linea: unidad y paquete del mismo producto MAY coexistir en el mismo ticket.

#### Scenario: Unidad luego paquete
- **WHEN** el cajero agrega el producto en modo unidad y luego en modo paquete
- **THEN** quedan dos lineas (o cantidades independientes) sin sobrescribir el modo previo

#### Scenario: Agrupacion visual
- **WHEN** el ticket tiene varios productos y el mismo base aparece en paquete y unidad
- **THEN** esas dos lineas se muestran consecutivas (agrupadas por producto)

### Requirement: Etiqueta y toggle de presentacion en ticket

La linea UNIDAD SHALL mostrar el sufijo `(Por unidad)` en negrita junto al nombre.

El boton de alternar precio unidad/empaque SHALL ocultarse cuando el mismo producto ya tiene ambas presentaciones en el ticket.

Al alternar, el cliente SHALL resolver presentaciones via `ensure` y actualizar `presentacionId` y precio desde la presentacion destino (no solo el subtotal dejando el mismo presentacionId).

#### Scenario: Toggle con presentaciones cargadas
- **WHEN** el cajero pulsa el toggle y existen PAQUETE y UNIDAD
- **THEN** cambia presentacion, precio unitario y el estado del toggle/etiqueta es coherente en clics sucesivos

#### Scenario: Ambas presentaciones ya en ticket
- **WHEN** coexisten linea paquete y linea unidad del mismo producto
- **THEN** no se muestra el boton de cambio de precio por unidad/empaque

### Requirement: Selector de productos y deshabilitados

En el modal Seleccionar producto, un producto con `activate` distinto de activo SHALL verse atenuado (gris) y MUST NOT poder seleccionarse (boton, doble clic o Enter); MAY seguir permitiendo editar.

#### Scenario: Producto deshabilitado en busqueda
- **WHEN** el cajero busca un producto deshabilitado
- **THEN** aparece en gris y no se agrega al ticket al intentar seleccionar

### Requirement: Stock en unidad base

`producto.existencia` SHALL ser la cantidad en unidad base. Los movimientos de inventario por venta SHALL descontar `cantidad_base` (no la cantidad de UoM a ciegas).

La existencia “por paquete” SHALL ser una vista derivada `floor(existencia / factor)` — no una segunda columna mutable.

#### Scenario: Venta de un paquete factor 20
- **WHEN** se confirma una venta de 1 PAQUETE con factor_snapshot=20
- **THEN** existencia baja en 20 unidades base

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/producto-presentaciones.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.2 (menudeo).
