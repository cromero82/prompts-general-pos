# Confirmación de pagos electrónicos (QR / email)

Documento narrativo para IAs y humanos. **Spec contractual:**  
`openspec/specs/confirmacion-pagos-electronicos/spec.md`  
**Puente docs triple:** `DUAL-DOCS-CURSOR-OPENSPEC.md`  
**Plan original (túnel/Cloudflare):** `interceptar-pagos-tunel.md`

**Última actualización:** 2026-09-06.

## Qué es

Cuando el cliente paga con un **medio electrónico con notificaciones** (`metodo_pago.permite_notificacion`, p.ej. QR Bancolombia o Nequi), el banco (o canal de alerta) envía un email. Ese email llega a `puente-tienda` (:8095), se parsea con **plantillas Ingreso** ligadas al medio y se relaciona con un pendiente `historial_recibos_electronicos` (HRE) creado al cobrar. El cajero ve el estado en el **panel flotante** de pagos electrónicos.

Ver también: `contextos-ia/metodos-pago-notificacion.md` (Dominios, plantillas, corregir medio).  
**No es PAGASTE:** correo de *salida* de banco → `notificacion-egreso-vinculo.md` (campanita, no este panel).

## UI panel (tema `azul-atras`)

| Pieza | Comportamiento |
|-------|----------------|
| Contenedor | Azul medio (`#4a6388`); header un tono más oscuro |
| Ítem | Tarjeta clara; borde de estado (espera / ok / ambigua) |
| Icono | `metodo_pago.file` según `metodoPagoId` del pendiente (no hardcode QR) |
| Tipografía | Montos y botones legibles (~15–17px) |
| Layout | Icono alineado al monto; fila botones **Asociar** · **Ya no esperar**; **Ver productos** abajo a la derecha; leyenda de tiempo en **fila completa** (sin ellipsis) |
| Arrastre | Header arrastrable; doble clic resetea posición |
| Minimizar | Header → dock en el footer (`Pagos electrónicos` + conteo + **Restaurar**); animación ~220 ms; `localStorage` `confirmacion-pagos-panel-minimized` |
| Ocultar (config) | `configuracion_app.notificaciones.activa=false` (SQL `55_`): **no** se monta el panel. El inbound/match sigue. **No** es el mismo gesto que minimizar |

Clase CSS: `confirmacion-pagos-panel--azul-atras` en `confirmacion-pagos-panel`.
Dock: `--vex-footer-height` / `confirmacion-pagos-dock` (footer de la app).

## Repos y piezas

| Pieza | Ubicación |
|-------|-----------|
| Panel + Asociar + monto distinto | `infinito-ai-front/.../confirmacion-pagos-panel/` |
| Dialog Asociar (poll live + multi-método) | `…/asociar-notificacion-dialog.component.ts` |
| Servicio FE | `…/service/confirmacion-pago.service.ts` → `apiUrlPuenteTienda` (+ corrección medio en relational) |
| API confirmación / asignar | `puente-tienda` — `ConfirmacionPagoService` |
| Corregir medio HRE | `pos-relational` — `HistorialReciboElectronicoController` |
| Faltante → reabrir ticket | `puente-tienda` — `FaltanteQrCreditoService` |
| Ajustes OF monto distinto | `puente-tienda` — `MovimientoDesdeNotificacionService` |
| Abrir CxC + retarget HRE | `pos-relational` — `CuentaPorCobrarServiceImpl` |
| Schema base | `…/database/28_confirmacion_pagos_electronicos.sql` |
| Schema medio/plantilla | `53_metodo_pago_permite_notificacion.sql`, `54_plantilla_naturaleza_ingreso.sql` |
| Visibilidad panel | `55_notificaciones_activa.sql` (`notificaciones.activa`) |

## Estados HRE

`CREADA` → `CONFIRMADA` | `AMBIGUA` | `HUERFANA` (ya no esperar / sin match útil).

## Flujos clave (vigentes)

### 1. Match normal

1. Cobro con medio notificable → HRE `CREADA` (venta o abono CxC).
2. Email → `notificacion_email_pago` (plantilla Ingreso del mismo medio).
3. Match por monto/sesión/medio o **Asociar** manual.
4. HRE `CONFIRMADA`; panel puede marcar vista confirmada.

### 2. Asociar (timing)

- El panel abre el modal **de inmediato** (lista inicial vacía OK).
- El modal hace **polling ~2.5 s** a `GET /api/notificaciones/sin-asignar`.
- Vacío: spinner «Esperando emails…», no mensaje definitivo de «no hay».
- Al cerrar: se corta el poll del modal.
- **Multi-método:** si hay emails de otro medio, iconos en Esperado/filas; esos emails no se eligen; **Corregir / cambiar medio** actualiza el pendiente (API relational).

### 3. Monto distinto (`MONTO_DISTINTO`)

- `PUT …/asignar` sin confirmar → **409** + esperado/recibido/diferencia.
- FE: modal de confirmación.
- **Sobrepago:** confirmar + OF devolución → dos movimientos `origen_tipo=QR_MONTO_DISTINTO` (±diff): exceso en OF QR y salida en caja. Preferible `AJUSTE_SALDO`; si quedó `SALIDA_EGRESO` legacy, el corte **igual** los incluye por `origen_tipo`.
- **Faltante (venta):** confirmar → **reabre ticket** (anula VTA / restaura productos, nombre tipo `Ticket N`); **no** crea CxC sola en puente.
- Respuesta con `abrirCxcManual`, `ticketIdReabierto`, `reciboIdReabierto`, montos, `faltante`.

### 4. Faltante → crédito manual

1. FE `tickets.onCreditoDesdeFaltanteQr`.
2. Abre `AbrirCuentaPorCobrarDialog` con `bloquearMontos: true` (abono=recibido, saldo=faltante, medio=QR, `disableClose`).
3. Cajero identifica cliente → Crear crédito con `historialElectronicoId`.
4. BE **retarget** HRE `CONFIRMADA` → `abono_cxc_id` (sin segundo HRE `CREADA`).

## APIs útiles (puente)

| Método | Ruta |
|--------|------|
| GET | `/api/notificaciones/pendientes?sesionId=` |
| GET | `/api/notificaciones/sin-asignar` |
| PUT | `/api/recibos-electronicos/{id}/asignar` body: `notificacionId`, `confirmarMontoDistinto`, `origenFondosDevolucionId?` |
| PUT | `/api/recibos-electronicos/{id}/ya-no-esperar` |
| PUT | `/api/notificaciones/confirmadas` |

## Operación

- **`puente-tienda` lo arranca el operador** (Maven/jar). Si el panel está vacío tras un QR real, revisar primero que :8095 esté vivo.
- Polling panel y modal: **2500 ms**.
- Multipago: el HRE usa solo el **tramo QR** (ver `MULTIPAGO-MEDIOS-POR-TICKET.md`).

## No confundir con

- Multipago genérico / corte por medios.
- Guía en línea CxC (`contextos-ia/guia-en-linea.md`).
- Plan B API oficial Bancolombia QR.

## Changelog corto

| Fecha | Cambio |
|-------|--------|
| 2026-08 | MVP HRE + email + panel |
| 2026-08 | CxC QR crea pendiente; fix sesionId panel |
| 2026-08-26 | Sobrepago QR: AJUSTE_SALDO (±diff) para que cierre muestre movimientos en caja y QR |
| 2026-08-22 | Asociar con polling en vivo; docs dual Cursor+OpenSpec |
| 2026-09-06 | Minimizar → dock footer; distinguir de `notificaciones.activa` |
