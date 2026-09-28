# Contexto IA — Observaciones de ticket

**Última actualización:** 2026-09-06.  
**OpenSpec:** `openspec/specs/ticket-observaciones/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.5 / §10.3; oleada `ACTUALIZACION-QA-2026-09-06.md`  
**SQL:** `56_ticket_observaciones.sql`

## Qué es

Comentario libre del **ticket vivo** (no de la CxC). Sirve para anotar un pedido, una nota al fiado, o un recordatorio. Convive con el panel **Crédito** del mismo rail.

## Modelo y API

| Pieza | Dónde |
|-------|--------|
| Columna | `ticket.observaciones` TEXT |
| Request | `PUT /tickets/{id}/observaciones` body `{ "observaciones": "…" }` |
| Normalización | trim; vacío → `null` (`TicketServiceImpl.normalizarObservaciones`) |
| Lista tickets | SELECT incluye observaciones `[6]` |

## FE

- Dialog `ticket-observacion-dialog`: «Agregar comentario» / «Editar comentario»; textarea `maxlength=500`; al abrir, foco + select-all si es edición.
- Focus POS: `TicketsPosFocusService.hold('dialog:ticket-observacion')` para que el POS no robe el cursor.
- Menú tab (⋮ y clic derecho): `Registrar/Editar comentario` y `Generar crédito a: {ticket}`.
- Rail `cxc-ticket-rail`: títulos **Crédito** / **Observación** / **Crédito y observación**; cita (comilla `“`, itálica, ~4 líneas + tooltip si desborda).
- Con observación + muchos abonos: la lista de abonos scrollea.

## Limpieza

El mismo id de ticket se reusa tras liquidar CxC. Se pone `observaciones=null` en:

- `CuentaPorCobrarServiceImpl.formalizarTicketSiLiquidada`
- `TicketReciboServiceImpl.crearReciboYEnlace`

El FE, tras abono `PAGADA`, parchea `{ observaciones: null }` en el ticket local.

## No confundir

- Observación del **egreso** o del **cierre** (otros campos).
- Observación del modal **Abrir CxC** (nota de la cuenta, no `ticket.observaciones`).
