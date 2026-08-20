# Prompt para IA — Migrar BD producción → esquema dian-v2

Úsalo cuando el usuario pida alinear una base **prod** (rama `feature/prod` /
carpeta `others-versions/pos-relational-data-service`) con la estructura
**dian-v2** (orígenes de fondos, ledger, cierres con detalle, distribución, base
inicial, estado ARCHIVADO, `id_referencia`, …).

> **Fuente de verdad del orden de scripts:**  
> `pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh`  
> y `…/database/README-SPRINTS.md`.  
> Este markdown debe mantenerse sincronizado con ese `.sh`.

## Repositorios de referencia

| Rol | Ruta / rama |
|---|---|
| Backend prod (referencia) | `others-versions/pos-relational-data-service` → `feature/prod` |
| Backend destino | `pos-relational-data-service` → **`dian-v2`** |
| Frontend destino | `infinito-ai-front` → **`dian-version`** (o rama activa de finanzas) |
| Dump referencia dian | `pos-relational-data-service/src/main/resources/backups/dump-controlneg_rmx_db-202607261840_linux_dian-v2.sql` |
| Scripts SQL | `pos-relational-data-service/src/main/resources/doc/contextos/database/` |
| Handoff finanzas | `…/doc/contextos/AI-HANDOFF-FINANZAS-2026-08.md` |
| Prompts generales POS | `prompts-general-pos/` (esta carpeta) |

## Objetivo

Dejar el schema PostgreSQL `controlneg_rmx_db` con **datos de negocio preservados** y:

### Ya incluido en el migrate (dian-v2 / movimientos)

- Tablas: `origen_fondos`, `movimiento_origen_fondos`, `tipo_origen_fondos`, `motivo_movimiento`, `corte_venta_detalle`, …
- Columnas en `corte_venta`: watermarks (`ultimo_historial_recibo_id`, `ultimo_movimiento_origen_fondos_id`), `distribucion_efectivo_estado`, `base_siguiente_efectivo`, workflow de estados
- Columnas en `egreso`: `metodo_pago_id`, `origen_fondos_id` (egreso **prima O.F.**; MP opcional)
- Caja Menor / Caja General **sin** `metodo_pago_id` (`26_…`)
- Motivo `INVERSION_INICIAL_BASE` (`24_…`)
- `movimiento_origen_fondos.id_referencia` (`27_…`)
- `origen_fondos.estado` ACTIVO|ARCHIVADO + unicidad nombre entre hermanos (`28_origen_fondos_estado_archivar.sql`)
- Multipago (capa BD): `historial_recibo_pago` + `metodo_pago.codigo_dian_payment_means` + backfill 1:1 (`30_historial_recibo_pago.sql`)
- Ticket rápido: flag `historial_recibo.ticket_rapido` + backfill pagos (`34_`)
- Motivos desfase con `accion_esperada` + `MOVIMIENTO_NO_REGISTRADO` (`35_`)
- Legalizar notificaciones email: columnas clasificación (`36_`)
- CxC schema: `cuenta_por_cobrar` + `abono_cxc` (`37_`; UI incremental)

### Núcleo ingresos (estándar)

- **Ingresos dashboard = Ventas sistema** (`totalVentasSistema` / `historial_recibo_pago`), no Contado.
- Contado / Diferencia = control de caja (arqueo).
- Glosario: `prompts-general-pos/GLOSARIO-NUCLEO-FINANCIERO.md`

### Pendiente de código (BE/FE) — multi-pago operativo

- Schema **sí** va en el migrate (`30_`). BE/FE ya escriben `pagos[]`, agregan el corte por líneas e imprimen/historial con desglose. Detalle: `prompts-general-pos/MULTIPAGO-MEDIOS-POR-TICKET.md`.
- Ver sección **«Multi-pago»** abajo.

**No** es un truncate de datos de negocio (para eso: `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` + script **v2**).

## Pasos obligatorios para la IA

1. **Backup** de la BD destino antes de migrar (`pg_dump`). No continuar sin confirmación si no hay backup.
2. Confirmar URL: `DB_URL` o default local `postgresql://…@localhost:5432/controlneg_rmx_db`.
3. Ejecutar el script maestro (idempotente en lo posible):

```bash
chmod +x pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh
bash pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh "$DB_URL"
```

4. Verificar salida (mínimo):
   - Tablas OF / `corte_venta_detalle` / `motivo_movimiento` presentes
   - `INVERSION_INICIAL_BASE` = 1
   - Caja Menor sin `metodo_pago_id`
   - Columna `movimiento_origen_fondos.id_referencia`
   - Columna `origen_fondos.estado`
   - Tabla `historial_recibo_pago` + backfill (conteo ≈ historiales con MP)
   - `metodo_pago.codigo_dian_payment_means` (10/45 en ids 1–3)
5. Desplegar **backend `dian-v2`** y **frontend** alineado (código + BD juntos).
6. Smoke test:
   - Login admin → modal Base inicial (si no hay cortes ni `BASE_INICIAL`)
   - OF list carga; egreso desde Caja Menor (sin MP)
   - Cierre muestra Base / ventas / egresos (−) / movimientos
   - Crear Fondo Hijo / Archivar (si aplica)

## Orden de scripts (detalle — sincronizado con el `.sh`)

El wrapper aplica (omitir `25_repair_*`):

| # | Script | Efecto |
|---|--------|--------|
| 00–05 | establecimiento, consecutivos, motivos op., tipos mov. inv., estado recibos, documento_venta (+ backfill) | Capa documental / DIAN base |
| 07–09 | egreso MP, corte extend, funcionalidad_pos, metodo_pago extend | Finanzas base |
| 10–11 | movimiento_inventario, inventario_kardex | Inventario |
| 12–18 | manejo cuentas, catálogos bolsillo, cuenta/movimiento, egreso↔cuenta, parent, **rename → origen_fondos** | Orígenes de fondos |
| 19–20 | motivo desfase, workflow corte + `corte_venta_detalle` | Cierre B5/B8 |
| 21–24 | fix traslado, watermark MOF, distribución efectivo, base inicial | Post-B8 |
| 26 | unlink Caja Menor MP | Contabilidad OF |
| 27 | `id_referencia` en ledger | Trazabilidad egreso/corte |
| 28 | `estado` ARCHIVADO + unique hermanos | Gestión OF |
| 30 | `historial_recibo_pago` + `codigo_dian_payment_means` + backfill | Multipago (BD) |
| 34 | `ticket_rapido` + backfill pagos quick | Ticket rápido entra al corte |
| 35 | `accion_esperada` + `MOVIMIENTO_NO_REGISTRADO` | Diferencia → acción |
| 36 | clasificar notif. email + motivos LEGALIZAR_* | Legalizar retiros |
| 37 | `cuenta_por_cobrar` + `abono_cxc` | CxC schema (UI luego) |

Cadena resumida:

```text
00→05(+backfill) → 07→08→06→09 → 10→11 → 12→18 → 19→20 → 21→24 → 26→27 → 28 → 30 → 34→37
```

> `28_confirmacion_pagos_electronicos` / `29_notificacion_email_*` existen en la carpeta pero **no** van en este wrapper (flujo QR/email aparte).

Ver también `COMPILACION-CAMBIOS-DIAN-VS-PROD.md` y `AI-HANDOFF-FINANZAS-2026-08.md`.

## Datos históricos tras migrar (sin pérdida)

| Tema | Comportamiento |
|---|---|
| Tickets / recibos / historial | **Se conservan**; no se truncan |
| Egresos viejos | Backfill `origen_fondos_id` / `metodo_pago_id` en `07`/`16` |
| Cortes viejos | `20` crea `corte_venta_detalle` desde `ventas_tipo`; estado `revisada` |
| Ledger OF | Vacío hasta movimientos nuevos / cortes con `ENTRADA_VENTA` |
| Distribución | Solo el último corte vigente puede quedar `PENDIENTE` (`23`) |
| Base siguiente | Null hasta primera distribución confirmada |
| Orígenes | Seed/árbol desde scripts; no borra ventas |
| Saldos físicos reales | Paso de negocio aparte: Base inicial o entradas manuales post-migrate |

Migración de **saldos físicos reales** de prod al ledger (apertura) es un paso de negocio aparte: usar Base inicial o entradas manuales; no inventar saldos en el script.

## Si falla a mitad

- Revisar el último `>>> archivo.sql` en el log.
- Scripts mayormente idempotentes; se puede re-ejecutar el wrapper.
- Si quedó en nombres intermedios (`cuenta_bolsillo` sin rename `18`), aplicar desde `18` en adelante.
- Comparar con dump dian o entidades JPA en `dian-v2` vs prod.

## Qué no hacer

- No truncar ventas/egresos de prod salvo petición explícita.
- No aplicar `25_repair_entrada_venta_corte1.sql` en prod.
- No desplegar solo FE o solo BE.
- No re-vincular Caja Menor a `metodo_pago` id 4.
- No desplegar FE mixto sin BE que escriba `historial_recibo_pago` y corte por líneas.

---

## Multi-pago (2–3 medios por ticket)

### Schema (ya en migrate — `30_historial_recibo_pago.sql`)

```text
metodo_pago.codigo_dian_payment_means   → PaymentMeansCode al emitir XML
historial_recibo                        → cabecera (total + metodo_pago_id primario)
historial_recibo_pago                  → N líneas (metodo_pago_id, monto, orden)
documento_venta                         → sin tabla de pagos; JOIN al historial
```

Backfill: 1 línea por historial existente (`monto = total`). Sin `recibo_pago`.

### Estado implementación

| Pieza | Estado |
|-------|--------|
| Tabla + códigos DIAN + backfill | Hecho (`30_`) |
| Entidad JPA `HistorialReciboPago` | Hecho |
| `ReciboService`: aceptar `pagos[]`, persistir líneas, validar SUM=total | Hecho |
| Corte: `SUM(pago.monto) GROUP BY metodo_pago_id` | Hecho |
| FE mixto: envía `pagos[]` (cambio solo en efectivo tendered) | Hecho |
| Tirilla + historial ventas (desglose) | Hecho |
| `GET /historial-recibos/{id}/pagos` | Hecho |
| Generador XML `PaymentMeans` 1..N | Futuro (no existe emisor hoy) |

Doc ampliado: **`prompts-general-pos/MULTIPAGO-MEDIOS-POR-TICKET.md`**.

### Reglas de producto acordadas

- Solo mixto **contado** (no crédito/CxC en v1).
- Sin borrador `recibo_pago`.
- MP primario en cabecera = mayor monto (empate → efectivo id=1).
- Cambio / sobrante: solo del efectivo tendered; líneas liquidan exactamente el `total`.
- Tope 3 medios; mismo MP no se repite.
- Confirmación QR: solo el tramo QR del mixto.

### Pendiente operativo

1. Emisión XML DIAN (N `PaymentMeans`) + validar códigos QR/Nequi con PT.
2. Anulación ticket ↔ líneas de pago + ledger (tema más amplio).

---

## Checklist rápido para la IA al abrir un chat de migrate

- [ ] Backup confirmado
- [ ] Ejecutar **solo** el `.sh` (no un subset inventado)
- [ ] Verificar OF + `estado` + `id_referencia` + `historial_recibo_pago`
- [ ] Verificar `ticket_rapido` / motivos `accion_esperada` / CxC tables / notif. clasificación
- [ ] Deploy BE+FE que lean `pagos[]` / corte por líneas en el mismo release
- [ ] Smoke: venta mixta → BD líneas → cierre por medio → tirilla/historial
- [ ] Smoke: ticket rápido → `historial_recibo_pago` + `VTA-` → aparece en Ingresos (Ventas)
- [ ] Smoke: Ingresos usa Ventas sistema (no Contado)
