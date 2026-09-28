## Purpose

Permitir un comentario libre por ticket vivo (panel derecho y menú de pestaña), independiente o junto al crédito CxC, y limpiarlo al reciclar el ticket.

## Requirements

### Requirement: Persistencia en ticket

El sistema SHALL guardar el comentario en `ticket.observaciones` (TEXT). `PUT /tickets/{id}/observaciones` SHALL aceptar `{ "observaciones": "…" }` y persistir el texto recortado; vacío o solo espacios MUST quedar `null`.

#### Scenario: Guardar comentario
- **WHEN** el cajero confirma un texto no vacío
- **THEN** el ticket lista y el rail muestran ese texto

#### Scenario: Vacío no deja basura
- **WHEN** el cajero guarda un comentario en blanco o cancela el diálogo
- **THEN** no se persiste texto vacío (cancelar no cambia lo anterior)

### Requirement: Titulo del rail

El panel derecho SHALL titularse según estado:
- solo crédito → **Crédito**
- solo observación → **Observación**
- ambos → **Crédito y observación**

#### Scenario: Comentario sin CxC
- **WHEN** hay observación y no hay cuenta por cobrar
- **THEN** el título es Observación y el texto se ve en el rail

#### Scenario: Credito y comentario
- **WHEN** hay CxC abierta y observación
- **THEN** el título es Crédito y observación; la lista de abonos scrollea si hay muchos pagadores

### Requirement: UI del comentario en el rail

El texto SHALL mostrarse como cita (comilla grande, itálica), máximo ~4 líneas. Si desborda, SHALL ofrecer tooltip con el texto completo. MUST NOT usar una etiqueta «Observación» encima del texto.

#### Scenario: Texto largo
- **WHEN** el comentario supera ~4 líneas
- **THEN** se recorta en el rail y el tooltip muestra el resto

### Requirement: Acceso desde pestaña

El menú de la pestaña (⋮ y clic derecho) SHALL ofrecer **Registrar comentario** / **Editar comentario** (y **Generar crédito a: {ticket}**). El diálogo MUST enfocar el textarea y, en edición, seleccionar el texto.

#### Scenario: Editar
- **WHEN** ya hay comentario y el cajero abre Editar comentario
- **THEN** el textarea tiene foco y el texto queda seleccionado

### Requirement: Limpieza al reciclar ticket

Al liquidar una CxC (`PAGADA`) o al crear un recibo nuevo en el mismo ticket (`crearReciboYEnlace`), el sistema SHALL poner `observaciones` en `null`. El FE MUST parchear el ticket local tras liquidar.

#### Scenario: Ticket reciclado sin comentario viejo
- **WHEN** se liquida el crédito y el mismo tab se reusa para una venta nueva
- **THEN** no aparece el comentario del crédito anterior

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/ticket-observaciones.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.5 / §10.3.
