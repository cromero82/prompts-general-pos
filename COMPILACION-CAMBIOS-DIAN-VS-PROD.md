# Compilación de cambios: producción vs dian (FE / BE / BD)

Documento vivo para IAs y humanos. Resume la diferencia entre:

| Pieza | Producción | Destino |
|---|---|---|
| Backend | `others-versions/pos-relational-data-service` @ `feature/prod` | `pos-relational-data-service` @ **`dian-v2`** |
| Frontend | (prod sin módulo OF completo) | `infinito-ai-front` @ **`dian-version`** |
| BD referencia dian | — | `src/main/resources/backups/dump-controlneg_rmx_db-202607261840_linux_dian-v2.sql` |

Carpeta de prompts generales: **`prompts-general-pos/`** (antes `prompts/` / README en raíz del monorepo).

---

## 1. Modelo mental (ciclo de caja)

```
[Instalación] Base inicial (ENTRADA_MANUAL / BASE_INICIAL)
      ↓
[Turno] Ventas (tickets) + Egresos (SALIDA_EGRESO) + Movimientos OF
      ↓
[Cierre] consultar-rango → corte + ENTRADA_VENTA + AJUSTE_CIERRE + watermarks
      ↓
[Distribución] TRASLADOs Caja→Menor/General; base_siguiente_efectivo
      ↓
[Logout] → siguiente turno usa Base = base_siguiente_efectivo
```

Prod **no** tiene ledger ni continuidad de base entre turnos.

---

## 2. Base de datos

### 2.1 Tablas nuevas (solo dian)

| Tabla final | Origen en scripts | Rol |
|---|---|---|
| `tipo_origen_fondos` | `13` + rename `18` | Catálogo tipo OF |
| `origen_fondos` | `14`→`18` | Cuentas (Caja Efectivo, QR, Nequi, Menor, General, …) |
| `movimiento_origen_fondos` | `15`→`18` | Ledger (saldo por impacto) |
| `motivo_movimiento` | `13`, `19`, `24` | Motivos ajuste / desfase / BASE_TURNO |
| `corte_venta_detalle` | `20` | Snapshot por medio en el corte |
| `historial_recibo_pago` | `30` | Líneas de cobro multipago (fuente de verdad por medio) |

### 2.2 Columnas nuevas en tablas existentes

**`corte_venta`:** `sesion_id`, `fondo_inicial_efectivo`, `motivo_desfase`, `estado`, `observacion`, `revisado_por`, `fecha_revision`, `ultimo_movimiento_origen_fondos_id`, `distribucion_efectivo_estado`, `base_siguiente_efectivo`

**`egreso`:** `metodo_pago_id`, `origen_fondos_id`

**`ventas_tipo`:** `total_ventas_sistema`, `total_egresos_sistema`, `desfase`, `motivo_desfase_id`

**`metodo_pago`:** `descripcion_egreso`, `visible_pagos_egresos`, `visible_pago_tickets`, `monto`, `codigo_dian_payment_means` (`30`)

**`establecimiento`:** `manejo_estricto_cuentas`

### 2.3 Scripts `00`–`30` (orden)

Ver `apply-migrate-prod-to-dian-v2.sh` y `MIGRATE-PROD-TO-DIAN-V2.md`.

| Rango | Tema |
|---|---|
| `00`–`05` | Establecimiento, documentos, estados recibo |
| `06`–`09` | Permisos POS, egreso/mp, corte extend, mp extend |
| `10`–`11` | Inventario / kardex |
| `12`–`18` | Bolsillos → **origen_fondos** + ledger + rename |
| `19`–`20` | Motivo desfase + workflow `corte_venta_detalle` |
| `21`–`24` | Fix traslado, watermark movimientos, distribución, base inicial |
| `25` | **Solo repair de prueba** — no usar en prod |
| `26` | Desvincular Caja Menor/General de `metodo_pago`; inactivar mp id=4 |
| `27`–`28` | `id_referencia` ledger; `origen_fondos.estado` ARCHIVADO |
| `30` | Multipago: `historial_recibo_pago` + códigos DIAN + backfill |

### 2.4 Cómo dejar una BD destino = esquema dian

```bash
# 1) Backup
# 2) Migrar schema
bash pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh "$DB_URL"

# Opcional: vaciar transacciones de prueba (NO en prod con datos reales)
bash prompts-general-pos/apply-reset-tablas-financieras-transaccionales.sh
```

Referencia: dump adjunto en el repo backend (`backups/dump-controlneg_rmx_db-202607261840_linux_dian-v2.sql`).

---

## 3. Backend (`dian-v2`)

### 3.1 APIs nuevas

| Área | Endpoints |
|---|---|
| OF | `GET /origenes-fondos`, `/para-egreso`, `/arbol`, `/arbol-egreso` |
| Ledger | `GET/POST /movimientos-origen-fondos` (entrada, préstamo, traslado, ajuste) |
| Motivos | `GET /motivos-movimiento` |
| Corte | `GET /distribucion-pendiente`, `POST /{id}/distribucion-efectivo` |
| | `GET /base-inicial-pendiente`, `POST /base-inicial` |
| | `PUT /{id}/finalizar-revision` |

### 3.2 Comportamientos clave (esta conversación / dian)

1. **Base inicial:** si no hay corte ni movimiento `BASE_INICIAL` → admin registra inversión en Caja: Efectivo (motivo `INVERSION_INICIAL_BASE`). Define Base del primer corte; watermark de movimientos.
2. **consultar-rango:** Base desde `base_siguiente_efectivo` o inversión inicial; ventas con watermark `id > ultimo_historial_recibo_id` agregadas desde **`historial_recibo_pago`** (multipago); movimientos con `id > ultimo_movimiento_origen_fondos_id`; excluye `SALIDA_EGRESO` / `ENTRADA_VENTA` de columna Movimientos.
3. **Al crear corte:** `ENTRADA_VENTA` por medio → OF (para que Distribución use saldo real = Base+Ventas−Egresos±Mov). Luego AJUSTE_CIERRE si desfase; watermarks; `distribucion_efectivo_estado=PENDIENTE`.
4. **Distribución:** Base + Caja Menor + Caja General = saldo Caja Efectivo; traslados `origen_tipo=DISTRIBUCION`; guarda `base_siguiente_efectivo`.
5. **Caja Menor/General:** sin `metodo_pago_id` (no aparecen como fila fantasma en cierre).
6. **Egreso:** exige OF; escribe `SALIDA_EGRESO` en ledger.
7. **Multipago:** `PUT /recibos` con `pagos[]`; ver `MULTIPAGO-MEDIOS-POR-TICKET.md`.

### 3.3 Enum `TipoMovimientoOrigenFondos`

`ENTRADA_MANUAL`, `ENTRADA_PRESTAMO`, `ENTRADA_VENTA`, `TRASLADO`, `SALIDA_EGRESO`, `SALIDA_DEVOLUCION_PRESTAMO`, `AJUSTE_SALDO`, `AJUSTE_CIERRE`, `REVERSO_AJUSTE_CIERRE`, `REVERSO_ENTRADA_VENTA`

### 3.4 JPA a contrastar (prod vs dian)

Si hay duda de columnas: comparar entidades en

- Prod: `others-versions/pos-relational-data-service/.../entities/`
- Dian: `pos-relational-data-service/.../entities/`

Sobre todo: `CorteVenta`, `CorteVentaDetalle`, `OrigenFondos`, `MovimientoOrigenFondos`, `MotivoMovimiento`, `Egreso`, `MetodoPago`, `VentasTipo`, `HistorialReciboPago`.

---

## 4. Frontend (`dian-version`)

### 4.1 Módulos nuevos / ampliados

| Ruta | Qué hace |
|---|---|
| `financiero/origenes-fondos/` | Lista OF, ledger, parcial (ledger + tickets sin corte), entrada/préstamo/traslado/ajuste |
| `ingresos/base-inicial-dialog/` | Modal instalación |
| `ingresos/distribucion-efectivo-dialog/` | Modal post-cierre |
| `ingresos/cierre-revision/` | Revisión admin |
| `auth/login` | Gate admin: distribución pendiente → base inicial pendiente |
| `egresos/egreso-edit` | Selector OF + saldo parcial |
| `ingresos/cierre-ventas` | Columnas Base/Movimientos; filtro `visiblePagoTickets`; abre distribución |

### 4.2 UX de continuidad de sesión

- Cajero cierra → logout (admin debe distribuir).
- Admin distribuye → logout (nuevo turno).
- Login admin bloqueado hasta completar distribución / base inicial (`disableClose`).

---

## 5. Cambios destacados de esta conversación (incremental sobre dian)

| # | Cambio | Dónde |
|---|---|---|
| 1 | Modal **Entrada manual / Base inicial** en instalación | BE `base-inicial*`, FE dialog + login |
| 2 | Motivo `INVERSION_INICIAL_BASE` | SQL `24` |
| 3 | `ENTRADA_VENTA` al confirmar corte (saldo distribución = total físico) | `MovimientoOrigenFondosService` + `CorteVentaServiceImpl` |
| 4 | Watermark ventas por **id** (fix +40k fantasma post-corte) | `HistorialReciboRepository` + `consultarRango` |
| 5 | Distribución + watermark movimientos + base siguiente | SQL `22`–`23` |
| 6 | Desvincular Caja Menor de mp id=4 | SQL `26` + filtro FE cierre |
| 7 | Reset transaccional documentado | `prompts-general-pos/RESET-*` |
| 8 | Script migración prod→dian | `apply-migrate-prod-to-dian-v2.sh` |
| 9 | **Multipago** 2–3 medios/ticket (`historial_recibo_pago`, corte por líneas, FE mixto, tirilla/historial) | SQL `30`, BE `ReciboService`/`CorteVenta`, FE `pago-efectivo-cambio` + print/historial; doc `MULTIPAGO-MEDIOS-POR-TICKET.md` |

---

## 6. Checklist para trabajar en otra máquina

1. Clonar/actualizar `dian-v2` + FE activo.
2. Tener dump o BD; si schema viejo → `apply-migrate-prod-to-dian-v2.sh` (hasta `30_`).
3. (Pruebas) reset transaccional opcional (incluye `historial_recibo_pago`).
4. Arrancar BE `:8088` + FE.
5. Login admin → Base inicial → operar ciclo de caja.
6. Smoke multipago: venta mixta → líneas en BD → cierre por medio.

## 7. Archivos de prompt relacionados

| Archivo | Uso |
|---|---|
| `prompts-general-pos/README.md` | Mapa de los 5 proyectos POS |
| `prompts-general-pos/MIGRATE-PROD-TO-DIAN-V2.md` | Pasos IA para migrar schema |
| `prompts-general-pos/MULTIPAGO-MEDIOS-POR-TICKET.md` | Multipago (diseño + estado) |
| `prompts-general-pos/RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Vaciar datos de prueba |
| `prompts-general-pos/COMPILACION-CAMBIOS-DIAN-VS-PROD.md` | Este documento |
| `…/database/apply-migrate-prod-to-dian-v2.sh` | Ejecutor SQL |
| `…/database/README-SPRINTS.md` | Índice histórico de sprints |
| `infinito-ai-front/.cursor/rules/movimientos-almacen/ONBOARDING-FINANZAS-ORIGENES-CIERRES.md` | Onboarding dominio finanzas |
