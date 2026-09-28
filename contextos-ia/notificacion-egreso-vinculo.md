# Contexto IA — Vínculo notificación EGRESO (PAGASTE) ↔ egreso POS

**Última actualización:** 2026-09-11.  
**OpenSpec:** `openspec/specs/notificacion-egreso-vinculo/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.15 / §10.10; oleada `ACTUALIZACION-QA-2026-09-10.md`  
**SQL:** `59_notificacion_vinculo_operacion.sql`  
**Relacionado:** `metodos-pago-notificacion.md` (plantilla EGRESO), `egresos.md`, `origenes-fondos.md`.  
**No confundir** con `confirmacion-pagos-electronicos.md` (venta/abono QR → HRE → panel flotante).

## Qué es

Un **PAGASTE** (plantilla `naturaleza=EGRESO`) avisa que **salió** plata del banco. Si el cajero **ya registró el egreso** en el POS (mismo monto, ventana ±7 días, mismo OF origen), no hay que crear el traslado a **Sin Clasificar**. El operador elige:

1. **Asociar y ver en egresos** — liga correo ↔ egreso; si había paso por bolsa, se **borra** el par POR IDENTIFICAR (no se fusiona).
2. **Enviar a Sin clasificar** — el correo no es ese egreso; entonces sí se crea el traslado.

Ticket QR de **venta** es HRE + panel Pagos electrónicos. PAGASTE no confirma ticket.

## Modelo

| Campo | Valores | Rol |
|-------|---------|-----|
| `estado_vista` | PENDIENTE / MOSTRADA / ARCHIVADA | ¿se vio en UI? |
| `vinculo_operacion` | NO_APLICA / PENDIENTE / ASOCIADA | ¿hay operación POS? |
| `notificacion_email_pago.egreso_id` | FK | correo → egreso |
| `egreso.notificacion_email_pago_id` | FK única | egreso → un correo |

Índices únicos parciales: un egreso no se liga a dos correos.

## Inbound (`puente-tienda`)

`MovimientoDesdeNotificacionService.registrarSiAplica(notif, plantilla, forzarAunqueHayaCandidato)`:

- Plantilla EGRESO + candidatos ≥ 1 + `forzar=false` → **no** crea movimiento; log «skip traslado (bandeja)».
- Sin candidatos → traslado QR → OF destino (Sin Clasificar), `origen_tipo=MOVIMIENTO BANCO POR IDENTIFICAR`.
- `enviar-a-bolsa` llama `registrarSiAplica(..., true)`.

Candidato (`listarEgresosCandidatos`):

```text
egreso.valor = notif.monto
fecha ∈ [recibidoEn ± 7 días]
notificacion_email_pago_id IS NULL
from_movimiento_origen_fondos_id IS NULL
origen_fondos_id = plantilla.origenFondosOrigenId
  OR existe egreso_origen_fondos con ese OF
```

JOIN `proveedor.nombre AS proveedor_nombre`, `persona.nombre AS persona_nombre` (alias distintos: Hibernate no tolera dos `nombre`).

## APIs (`GestionNotificacionController`)

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/api/notificaciones-email/alertas-egreso-sin-vincular` | bandeja: PENDIENTE EGRESO, sin par POR IDENTIFICAR, **con** candidatos |
| POST | `/api/notificaciones-email/{id}/enviar-a-bolsa` | forzar traslado |
| PUT | `/api/notificaciones-email/{id}/asociar-egreso` body `{ egresoId }` | FK + anular par + sello |
| GET | `/api/notificaciones-email/candidatas-egreso?egresoId=` | asociar tarde desde lista/edición de egreso |

Asociar: `anularParPorIdentificarYSellarEgreso` — DELETE par `id_referencia=notif` + `origen_tipo` POR IDENTIFICAR; recalc `saldo_antes`/`saldo_despues` por OF; stamp `Notif #` en `SALIDA_EGRESO` (`origen_tipo=EGRESO`). Si el movimiento ya está en corte cerrado (`ultimo_movimiento_origen_fondos_id`) → error. Histórico `FUSION_EGRESO_NOTIFICACION` **no** se migra.

## FE

| Pieza | Archivo |
|-------|---------|
| Poll ~8 s | `alerta-egreso-sin-vincular.service.ts` |
| Badge header | `toolbar-alerta-egreso.component.ts` (count abajo-derecha; no `matBadge` arriba) |
| Diálogo | `alerta-egreso-sin-vincular-dialog.component.ts` |
| Icono Sin Clasificar | `origenes-list` → `abrirAlertaEgresoSinVincularDialog(dialog, cuenta.id)` |
| Lista egresos + filtro | `egreso-list` query `egresoId` + `_r`; botón **Borrar filtro notificación** |
| Asociar tarde | `asociar-notificacion-egreso-dialog.component.ts` |
| Columna clasificación | `gestion-notificaciones-medios-electronicos` `labelClasificacion` |

Diálogo: **siempre** se abre (también con 1 alerta). Labels: **Asociar y ver en egresos** / **Enviar a Sin clasificar**. Beneficiario = `Persona: …` si hay `personaNombre`, si no `Proveedor: …`. No fallback «Sin pagador» (`nombrePagador` es quién te pagó en plantillas Ingreso).

Navegación post-asociar: `/apps/financiero/egresos?egresoId=&_r=` — no abre el modal de edición.

## Gestión notificaciones

Filtro `POR_IDENTIFICAR` (`searchPorIdentificar`) excluye ASOCIADA, `egresoId`, HRE. Clasificación muestra `Egreso #N` si `vinculo=ASOCIADA`.

## Piezas backend

| Pieza | Dónde |
|-------|--------|
| Hold + candidatos + DELETE par | `puente-tienda` `MovimientoDesdeNotificacionService` |
| Alertas / bolsa / asociar | `puente-tienda` `GestionNotificacionService` |
| DTO candidato | `EgresoCandidatoAlertaDto` (`proveedorNombre`, `personaNombre`) |
| Query pendientes sin movimiento | `NotificacionEmailPagoRepository.findPendientesEgresoSinMovimiento` |
| Columnas FK | `pos-relational` `Egreso.notificacionEmailPagoId` + SQL `59_` |

Reiniciar **puente-tienda :8095** si cambia el jar (hold, alertas, JOIN candidato). Relational :8088 si aplica `59_` o entidad `Egreso`.

## No romper

- Un egreso $200 y dos PAGASTE $200: el primero se asocia; el segundo sigue en badge hasta asociar otro egreso o enviarlo a bolsa.
- PAGASTE $300 sin egreso $300 → Sin Clasificar, **sin** badge.
- «Sin pagador» no aplica a este modal.
- catchError del poll FE trata 500 como `count=0` (el badge desaparece si el API falla; revisar log puente, p.ej. alias SQL duplicado).

## Cierre de turno (columna Movimientos)

`consultar-rango` suma cobranzas y otros movimientos del medio. **No** vuelve a restar el débito `MOVIMIENTO BANCO POR IDENTIFICAR` (QR, Nequi u otro electrónico) cuando ese par ya tiene `egreso.from_movimiento_origen_fondos_id`. Esa plata va en **Egresos**. Antes de formalizar, el débito sí entra en Movimientos (Esperado = saldo de la OF raíz). `SALIDA_EGRESO` del formalizar sale de Sin Clasificar (sin `metodo_pago_id`) y nunca fue columna Movimientos.
