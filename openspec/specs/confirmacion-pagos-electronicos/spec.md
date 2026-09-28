## Purpose

Confirmar automáticamente (o con asistencia del cajero) los pagos QR / transferencia detectados por email bancario, manteniendo coherencia entre venta o abono CxC, orígenes de fondos y el panel flotante de pagos electrónicos.

## Requirements

### Requirement: Pendiente electrónico al cobrar con medio que permite notificación

El sistema SHALL crear un registro en `historial_recibos_electronicos` (HRE) en estado `CREADA` cuando una venta o un abono CxC se liquida con un medio que tiene `permite_notificacion=true` (tramo electrónico en multipago), asociado a la sesión de caja vigente. El sistema MUST NOT basar esta decisión solo en heurísticas de sigla/descripción «QR» / «Bancolombia».

#### Scenario: Venta contado con tramo electrónico notificable
- **WHEN** el cajero formaliza un ticket con al menos un tramo de un medio con `permiteNotificacion`
- **THEN** existe un HRE `CREADA` con `monto_esperado` igual a ese tramo y `historial_recibo_id` de la venta

#### Scenario: Abono CxC con medio notificable
- **WHEN** el cajero registra un abono a cuenta por cobrar con ese medio
- **THEN** existe un HRE `CREADA` con `abono_cxc_id` (no solo venta) y el panel puede listarlo en la sesión

### Requirement: Ingesta de email y cola sin asignar

El servicio `puente-tienda` SHALL recibir el email inbound, parsear monto / pagador / referencia de cuenta, persistir `notificacion_email_pago` y exponer las no asociadas vía `GET /api/notificaciones/sin-asignar`.

#### Scenario: Email válido llega tras el cobro
- **WHEN** llega un email de alerta bancaria parseable con monto coincidente a un HRE `CREADA`
- **THEN** el sistema puede emparejar automáticamente o dejar la notificación disponible para asociación manual

### Requirement: Panel flotante con polling de pendientes

El frontend SHALL mostrar un panel de confirmación de pagos electrónicos que consulta periódicamente `GET /api/notificaciones/pendientes?sesionId=…` (intervalo orientativo 2500 ms) y permite acciones de cajero (confirmar vista, asociar, ya no esperar).

#### Scenario: Polling de sesión
- **WHEN** hay sesión de caja activa y el panel está montado
- **THEN** la lista de pendientes se refresca en background sin recargar toda la app de ventas

### Requirement: UX legible del panel (tema azul-atras)

El panel SHALL usar tipografía legible en montos, estados y botones; layout con icono alineado al monto; acciones **Asociar** y **Ya no esperar** en la fila superior; **Ver productos** debajo a la derecha; y la leyenda de tiempo (p.ej. «Hoy, … · Hace N minutos») MUST mostrarse completa sin truncar con ellipsis por falta de ancho.

#### Scenario: Leyenda de espera visible
- **WHEN** hay un pendiente CREADA con fecha de creación
- **THEN** el texto relativo de tiempo se lee completo en el ítem

### Requirement: Modal Asociar con escucha en vivo

Al abrir «Asociar pago bancario», el diálogo SHALL hacer polling de `GET /api/notificaciones/sin-asignar` (mismo intervalo orientativo que el panel) mientras esté abierto, y MUST abrir de inmediato sin bloquearse esperando la primera respuesta vacía.

#### Scenario: Cajero abre Asociar antes de que llegue el email
- **WHEN** el cajero pulsa Asociar y aún no hay notificaciones sin asignar
- **THEN** el modal muestra estado de espera (no un callejón «no hay emails» definitivo) y, cuando llega una notificación, la lista se actualiza para poder seleccionarla

#### Scenario: Cierre del modal
- **WHEN** el usuario cierra el modal Asociar
- **THEN** el polling interno del modal se detiene

### Requirement: Asociar con claridad de método de pago

Si hay notificaciones sin asignar cuyo `metodoPagoId` difiere del pendiente (o entre sí), el modal SHALL mostrar iconos de medio en la fila «Esperado» y en cada candidato. Las de otro medio MUST mostrarse atenuadas y no seleccionables. El modal SHALL ofrecer corregir el medio del HRE pendiente vía API de corrección cuando aplique.

#### Scenario: Email de otro medio
- **WHEN** el pendiente es medio A y hay un email parseado como medio B
- **THEN** el cajero ve iconos, no puede elegir B hasta corregir el medio del pendiente a B (u otro coincidente)

### Requirement: Monto distinto requiere confirmación explícita

Si el monto del email difiere del `monto_esperado` del HRE, la asignación sin flag de confirmación SHALL responder `409` con código `MONTO_DISTINTO` e información de esperado / recibido / diferencia. Solo con `confirmarMontoDistinto=true` (y origen de devolución si aplica sobrepago) se completa la asignación.

#### Scenario: Sobrepago
- **WHEN** el monto recibido es mayor al esperado y el cajero confirma el monto distinto eligiendo origen de fondos de devolución
- **THEN** el HRE queda confirmado; se registran dos movimientos con `origen_tipo=QR_MONTO_DISTINTO`: +diff en OF del medio QR y −diff en el OF de devolución (caja). Preferible tipo `AJUSTE_SALDO` (no egreso documento)

#### Scenario: Sobrepago visible en cierre
- **WHEN** tras el sobrepago se consulta el rango del turno
- **THEN** `totalMovimientosSistema` del medio efectivo incluye el −diff y el del medio QR incluye el +diff (incluido si el tipo legacy fue `SALIDA_EGRESO`, porque el corte filtra por `origen_tipo=QR_MONTO_DISTINTO`); `totalSistema` refleja caja−devolución y banco+exceso

#### Scenario: Faltante en venta formalizada
- **WHEN** el monto recibido es menor al esperado en una venta (no abono CxC) y el cajero confirma el faltante
- **THEN** el sistema NO crea automáticamente la CxC completa; reabre un ticket vivo con productos, anula la VTA asociada según reglas de reapertura, y señala al FE que debe abrir el modal de crédito manual

### Requirement: Faltante QR → crédito manual del cajero

Tras confirmar faltante en venta, la respuesta SHALL incluir `abrirCxcManual=true` más `ticketIdReabierto`, `reciboIdReabierto`, `totalTicketReabierto` y `faltante`. El FE SHALL abrir el diálogo existente «Abrir cuenta por cobrar» con montos/medio bloqueados (abono = recibido, saldo = faltante, medio = QR) y sin cancelar por dismiss accidental (`disableClose` cuando `bloquearMontos`).

#### Scenario: Crear crédito tras faltante
- **WHEN** el cajero identifica el cliente y confirma «Crear crédito» enviando `historialElectronicoId` del HRE ya `CONFIRMADA`
- **THEN** el backend retargetea ese HRE al nuevo `abono_cxc_id` (sin crear un segundo pendiente `CREADA` duplicado)

### Requirement: Retarget HRE confirmado a abono CxC

Al abrir CxC desde ticket con `historialElectronicoId` de un HRE `CONFIRMADA`, `pos-relational-data-service` SHALL reasignar el HRE al abono creado (retarget) en lugar de generar otro HRE pendiente.

#### Scenario: Un solo pendiente electrónico para el faltante liquidado
- **WHEN** se completa el flujo faltante → ticket reabierto → Crear crédito con el id HRE
- **THEN** el panel no muestra un segundo ítem CREADA huérfano por el mismo pago email

### Requirement: Minimizar el panel (dock)

El panel SHALL ofrecer Minimizar en el header. Minimizado, SHALL mostrar un dock en el footer de la app (etiqueta **Pagos electrónicos**, conteo de pendientes, **Restaurar**) y MUST seguir el polling de pendientes. El estado minimizado SHALL persistir en `localStorage` (`confirmacion-pagos-panel-minimized`). Minimizar MUST NOT ser lo mismo que `configuracion_app.notificaciones.activa=false` (ese flag oculta el panel por configuración; el inbound y el match siguen).

#### Scenario: Minimizar con pendientes
- **WHEN** hay pendientes y el cajero pulsa Minimizar
- **THEN** el panel se recoge al footer con el número de pendientes y Restaurar lo vuelve a mostrar

#### Scenario: Minimizado no apaga el canal
- **WHEN** el panel está minimizado y llega un match o un nuevo pendiente
- **THEN** el conteo del dock se actualiza; no se detiene el inbound

#### Scenario: Recargar Tickets
- **WHEN** el cajero recarga Tickets con el panel minimizado
- **THEN** el dock sigue minimizado (recuerda `localStorage`)

#### Scenario: Panel oculto por config
- **WHEN** `notificaciones.activa` es false
- **THEN** no se muestra el panel ni el dock (distinto de minimizar)

### Requirement: Puente-tienda controlado por el operador

El reinicio o despliegue de `puente-tienda` (:8095) MUST NOT asumirse automático por la IA; el operador lo levanta/baja de forma manual salvo instrucción explícita.

#### Scenario: Panel vacío por servicio caído
- **WHEN** `puente-tienda` no responde (p. ej. status 0)
- **THEN** el FE puede quedar sin pendientes aunque el HRE exista en BD; el diagnóstico prioritario es el servicio :8095, no «borrar» la lógica de HRE

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/confirmacion-pagos-electronicos.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.12 / §10.5. Minimizar vs ocultar: SQL `55_notificaciones_activa.sql`.
