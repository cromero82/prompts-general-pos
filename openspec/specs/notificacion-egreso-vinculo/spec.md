## Purpose

Cuando llega un correo bancario de **egreso** (plantilla PAGASTE / naturaleza EGRESO) y ya existe un egreso POS del mismo monto sin vincular, el sistema MUST NOT meter la plata a Sin Clasificar a ciegas. El operador decide a mano: asociar el correo al egreso o enviarlo a la bolsa. Distinto de la confirmación de **venta** QR (`confirmacion-pagos-electronicos`).

## Requirements

### Requirement: Dos ejes en la notificación

`notificacion_email_pago` SHALL distinguir ciclo de vista (`estado_vista`: PENDIENTE | MOSTRADA | ARCHIVADA) de vínculo con operación POS (`vinculo_operacion`: NO_APLICA | PENDIENTE | ASOCIADA). El vínculo ASOCIADA SHALL persistirse con FK bidireccional `notificacion_email_pago.egreso_id` y `egreso.notificacion_email_pago_id` (un egreso, un correo).

#### Scenario: Correo PAGASTE sin operación
- **WHEN** un email matchea plantilla EGRESO y aún no hay ticket ni egreso ligado
- **THEN** `vinculo_operacion` es PENDIENTE

#### Scenario: Tras asociar
- **WHEN** el operador asocia el correo al egreso
- **THEN** ambas FKs quedan llenas y `vinculo_operacion` es ASOCIADA

### Requirement: Hold inbound si hay egreso candidato

Al ingestar un correo de plantilla EGRESO, el sistema SHALL buscar egresos candidatos: mismo monto, fecha del correo ±7 días, sin `notificacion_email_pago_id`, sin `from_movimiento_origen_fondos_id`, y origen de fondos coincidente con el OF origen de la plantilla (o fila en `egreso_origen_fondos`). Si hay al menos un candidato, MUST NOT crear el par de movimientos POR IDENTIFICAR (QR → Sin Clasificar). El correo entra a la bandeja de alerta.

#### Scenario: PAGASTE con egreso ya registrado
- **WHEN** llega el correo y existe un egreso candidato
- **THEN** no sube saldo en Sin Clasificar; el badge de alerta cuenta ese correo

#### Scenario: PAGASTE sin candidato
- **WHEN** llega el correo y no hay egreso del mismo monto en la ventana
- **THEN** se crea el traslado a Sin Clasificar como hasta ahora (no es alerta de vínculo)

### Requirement: Bandeja de alerta visible

El sistema SHALL exponer `GET /api/notificaciones-email/alertas-egreso-sin-vincular` con `{ count, items }`. Cada ítem SHALL incluir la notificación, OF origen/destino de la plantilla, y candidatos con monto, fecha, y nombre de **proveedor** o **persona** según el tipo del egreso. El FE SHALL mostrar:

- icono titilante + número a la izquierda del usuario (toolbar)
- el mismo recuento en la tarjeta hija **Sin Clasificar** (slot tipo tickets-sin-corte)

Polling orientativo ~8 s. El badge MUST mostrarse si `count > 0`.

#### Scenario: Una alerta pendiente
- **WHEN** hay un correo EGRESO PENDIENTE con al menos un candidato y sin par POR IDENTIFICAR
- **THEN** el header y Sin Clasificar muestran el número 1 (o N)

### Requirement: Diálogo siempre manual

Al pulsar el badge o el icono de Sin Clasificar, el FE SHALL abrir el diálogo de selección. MUST NOT asociar ni navegar solo aunque quede un único correo y un único egreso compatible.

#### Scenario: Tras resolver el primero queda uno
- **WHEN** el badge baja de 2 a 1 y el operador vuelve a pulsar
- **THEN** se abre el mismo diálogo (no salta a Egresos)

### Requirement: Acciones del diálogo

El diálogo SHALL ofrecer, por cada correo:

- **Asociar y ver en egresos** (requiere candidato seleccionado; si hay uno, puede preseleccionarse)
- **Enviar a Sin clasificar** (siempre disponible)

MUST NOT usar copys que mezclen ambas ideas (p.ej. «Aceptar y enviar…» como si se aceptara la liga).

La ficha del correo SHALL mostrar monto, fecha/hora y nombre de plantilla (PAGASTE). MUST NOT mostrar «Sin pagador». El candidato SHALL mostrar además **Proveedor: {nombre}** o **Persona: {nombre}**.

#### Scenario: Asociar y ver
- **WHEN** el operador elige un candidato y pulsa Asociar y ver en egresos
- **THEN** el correo queda ASOCIADA a ese egreso y la app abre `/apps/financiero/egresos?egresoId={id}` con ese registro filtrado y resaltado

#### Scenario: Enviar a bolsa
- **WHEN** el operador pulsa Enviar a Sin clasificar
- **THEN** se crea el traslado QR → Sin Clasificar (`POST .../enviar-a-bolsa`); el egreso candidato **no** se vincula

### Requirement: Asociar anula paso por bolsa

Al asociar (`PUT .../asociar-egreso`), si ya existía el par POR IDENTIFICAR de esa notificación, el sistema SHALL borrarlo y recalcular saldos del OF. MUST NOT insertar filas `FUSION_EGRESO_NOTIFICACION`. SHALL sellar la observación de la `SALIDA_EGRESO` del egreso con `Notif #`. Si esos movimientos ya están en un corte cerrado, MUST rechazar.

Si no había par en bolsa, SHALL solo persistir FKs + sello.

#### Scenario: Asociar desde lista de egresos (correo tardío)
- **WHEN** el operador asocia un correo PENDIENTE a un egreso ya registrado y el dinero había pasado por Sin Clasificar
- **THEN** el par POR IDENTIFICAR desaparece y no queda un ajuste extra en el ledger

### Requirement: Filtro en listado de egresos

Con query `egresoId`, el listado SHALL mostrar solo ese registro, con resaltado breve, y un botón visible **Borrar filtro notificación** (junto al título y otra vez sobre la tabla). Al pulsarlo MUST volver al listado completo habitual. MUST NOT usar solo un enlace discreto «Ver todos».

#### Scenario: Volver a todos
- **WHEN** el operador pulsa Borrar filtro notificación
- **THEN** se ven de nuevo todos los egresos con los filtros normales de la pantalla

### Requirement: Clasificación en bandeja de notificaciones

El filtro «Por identificar» MUST excluir `vinculo_operacion=ASOCIADA` y correos ya ligados a egreso o HRE. La columna de clasificación SHALL mostrar **Egreso #N** (o ticket) cuando el vínculo es ASOCIADA, no «Por identificar».

#### Scenario: Correo ya ligado
- **WHEN** el operador mira Notificaciones recibidas de un PAGASTE asociado
- **THEN** la fila no aparece como por identificar y la clasificación indica el egreso

### Requirement: Cierre no doble-cuenta PAGASTE formalizado

Si un aviso PAGASTE (plantilla EGRESO) ya se formalizó como egreso desde Sin Clasificar, el cierre de turno MUST NOT restar esa plata dos veces. La columna **Egresos** del medio electrónico de la OF origen (QR, Nequi u otro con `metodo_pago_id`) SHALL mostrar el documento. La columna **Movimientos** MUST NOT incluir el débito `MOVIMIENTO BANCO POR IDENTIFICAR` de ese par. El mismo criterio aplica a cualquier medio electrónico, no solo QR.

Mientras el PAGASTE esté en bolsa **sin** formalizar, el débito SÍ MAY sumar en Movimientos para que Esperado coincida con el saldo de la OF raíz.

#### Scenario: Cobranza + PAGASTE formalizado en QR o Nequi
- **WHEN** hay una cobranza electrónica de $100.000 y un PAGASTE de $50.000 ya formalizado como egreso
- **THEN** en Cierre de turno, Movimientos de ese medio es $100.000 y Egresos es $50.000; Esperado cuadra con el saldo de la OF raíz

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/notificacion-egreso-vinculo.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.9 / §4.15 / §10.1 / §10.10, más la oleada QA del ciclo.

#### Scenario: Cambio de labels o hold inbound
- **WHEN** cambia el diálogo de alerta, el hold de PAGASTE o el filtro de Egresos
- **THEN** spec, narrativo y perfil tester se actualizan en el mismo ciclo
