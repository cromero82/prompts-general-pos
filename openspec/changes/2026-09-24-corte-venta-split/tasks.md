## Hecho (2026-09-24) — código aplicado, compila

### BD
- [x] Migración `68_corte_venta_split.sql`: estado `'dividido'`, `origen_split_id`,
      `corte_venta_correccion` (motivo NOT NULL) + `_detalle` + índices
- [x] Reset transaccional (`prompts-general-pos/reset-tablas-financieras-transaccionales-v3.sql`):
      `corte_venta_correccion_detalle` y `corte_venta_correccion` en el arreglo de tablas

### BE — Eliminar
- [x] `validarCorteEliminable`: bloquea por movimientos posteriores en **toda** OF
      tocada (medios de pago, cajas destino, ajustes de cierre)
- [x] `delete()`: validar antes de revertir; orden distribución → ventas (crédito antes
      que débito)
- [x] Un corte `dividido` no se puede eliminar
- [x] Observación uniforme «Reverso por eliminación del cierre #N»

### BE — Dividir
- [x] Entidades `CorteVentaCorreccion` / `CorteVentaCorreccionDetalle` + repos
- [x] `CorteVenta.origenSplitId`
- [x] Enum `REVERSO_TRASLADO` y `AJUSTE_PUENTE_SPLIT`; legacy `REVERSO_TRASLADO_DISTRIBUCION` conservado
- [x] `revertirParaSplit`: reversa **todas** las entradas de venta + ambas patas de los
      traslados; puente por OF con neto positivo; orden crédito→débito
- [x] `cerrarPuenteSplit` + ampliar el watermark del último corte tras cerrarlo
- [x] `dividirCorte`: validaciones → corrección → reverso → `estado = 'dividido'` →
      re-corte por partición → cierre de puente, en una `@Transactional`
- [x] Validación de cobertura (Σ ventas == original) **antes** de tocar el ledger
- [x] Particiones: dentro del rango, sin solapes, huecos permitidos
- [x] Prorrateo: Σ por destino == original
- [x] Modo editor N=1 con `tipo = 'EDICION'` y motivo obligatorio
- [x] `POST /corte-venta/{id}/dividir` (admin) y `GET /corte-venta/{id}/distribucion-original`
- [x] `ESTADOS_NO_VIGENTES` + desempate por id en «último corte vigente»
- [x] `SPLIT_PUENTE` y `SPLIT_REVERSO` fuera del filtro de «Movimientos» del cierre
- [x] Test `CorteVentaServiceImplTest` actualizado + caso «corte dividido no se elimina»

### FE
- [x] Botón **Dividir** junto a Eliminar en «Detalles por Fecha»
- [x] Eliminar muestra el mensaje del BE (409), no un texto genérico
- [x] `dividir-corte-dialog`: arrastrable, motivo obligatorio, Fecha+Hora con segundos,
      datepickers acotados, **Consultar** por partición, prorrateo precargado y editable,
      resumen «repartido X de Y», última partición por resta
- [x] Cabecera del diálogo con segundos (`HH:mm:ss`)
- [x] Ingresos excluye `dividido`; filtro de estado **Divididos** + badge
- [x] `corte-venta.service.ts`: `dividir()` y `obtenerDistribucionOriginal()`

## Pendiente — pruebas humanas (retomar aquí)

Requisito previo: **recompilar el BE con todos los fixes** y **resetear la BD**. Las
corridas anteriores quedaron invalidadas por los hallazgos de doble conteo de QR, corte
dividido sumando en Ingresos y watermark del puente.

- [ ] **CV-E01-permitido** — día 1 ventas + corte; día 2 ventas + corte; Eliminar el del
      día 2 → permitido; saldos vuelven al estado del día 1
- [ ] **CV-E02-no-permitido** — igual pero con egreso antes de Eliminar → bloqueo con el
      mensaje del BE
- [ ] **CV-E02-no-permitido (variante medio de pago)** — el egreso sale de Bancolombia – QR
      o Caja: Efectivo, no de Caja Menor → también debe bloquear
- [ ] **CV-E02-split-por-día** — 1 corte para dos días + egreso posterior; Eliminar
      bloqueado; Dividir en 2 (23:59:59 / 00:00:00) → 2 cortes, original `dividido`,
      Σ ventas == original, egreso intacto, ningún `saldoDespues` negativo
- [ ] **CV-E04-split-en-mismo-día** — corte de un solo día dividido en 2 turnos
- [ ] **Split 3+ particiones** — reparto sin residuo de redondeo (última por resta)
- [ ] Verificar después de cada split: Ingresos sin el corte dividido, «Tickets sin corte»
      en 0, Base del siguiente cierre igual al saldo real de cada OF
- [ ] Reintento sobre un corte ya dividido → error explícito

## Pendiente — cabos sueltos detectados al documentar

- [ ] Sincronizar la **copia del BE** del reset: `pos-relational-data-service/src/main/resources/sql/reset-tablas-financieras-transaccionales-v3.sql`
      y la lista `TABLAS_TRANSACCIONALES` de `ResetTransaccionesSandboxServiceImpl`, que
      no nombran las tablas de corrección. Hoy funciona igual porque el
      `TRUNCATE … CASCADE` de `corte_venta` las arrastra, pero conviene que sea explícito
- [ ] `ResetTransaccionesSandboxServiceImpl`: la aserción post-reset cuenta
      `corte_venta WHERE estado <> 'eliminado'`; alinear con `ESTADOS_NO_VIGENTES`
      (inofensivo tras un truncate, pero es la misma trampa que ya nos costó el 4.600.000)

## Cierre

- [ ] Archivar este change (`/opsx-archive`) cuando los escenarios pasen
