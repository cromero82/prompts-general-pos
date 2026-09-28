# Contexto IA — Historial Tickets

**Última actualización:** 2026-09-26.  
**Ruta FE:** `/apps/tickets/historial` (`HistorialVentasComponent`)  
**API:** `GET /historial-recibos/search`  
**OpenSpec:** `openspec/specs/historial-tickets/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.6 / §4.11 / §10.9; oleada `doc-ayuda-inteligente/ACTUALIZACION-QA-2026-09-03.md`  
**Migrate v02:** `MIGRATE-TIENDA-INFINITO-V02.md` (lecciones ensayo) + `MIGRATE-PROD-TO-DIAN-V2.md`

## Layout

Lista + filtros a la izquierda (ancho arrastrable, default ~450px), detalle a la derecha. Divisor visible: `border-right` 1px en el panel izquierdo + handle del `split-pane-divider` (mismo criterio visual que Financiero > Ingresos).

## Filtros

Se combinan (AND). `valueChanges` de MatSelect/checkbox no dispara search en el primer paint (`skip(1)`); recargas van por `searchReload$` + `switchMap`.

| Parámetro | Uso |
|-----------|-----|
| `fecha` | Día (YYYY-MM-DD) |
| `estadoId` / `restaurados` | Pagado, anulados, restaurados, todos |
| `metodoPagoId` | Medio visible en Tickets (`GET /metodos-pago?paraTickets=true`) o línea de multipago |
| `mixto=true` | Tickets con **más de un** `historial_recibo_pago` |
| `sinCorte=true` | `historial_recibo.id` &gt; `ultimoHistorialReciboId` del último corte no eliminado |
| `clienteId` | Autocomplete Cliente; limpia con X |
| `productoId` | Autocomplete Producto (misma consulta y orden que `selector-productos`: `POST /products/busquedaPorFiltros` por nombre; `GET /products/search` por código de barras o “Coincidir toda la palabra”; botones Ab y Limpiar). EXISTS en `historial_recibo_detalle` |

Respuesta enriquece:

- `multipago` (boolean)
- `estadoNotificacionElectronica` (desde HRE; null si el medio no usa flujo electrónico)
- `sesionUserId` (UUID de `sesion.user_id`) para resolver cajero desde cache `todos-usuarios` (sin `GET /sesiones/{id}/usuario`)

## Consecutivo VTA y migrate prod → v02

La lista muestra `documentoVentaConsecutivo` o, si falta, `#` + id interno. Tras migrate, **todas** las ventas pagadas deben tener `documento_venta` con `VTA-000001` … `VTA-NNNNNN` (mismo formato que una venta nueva). `consecutivo_documento` VENTA queda en el máximo para continuar la serie.

Ensayo laptop 2026-09-12 (corregir también en **producción v02**):

1. El search **no cargaba** tickets: `GET /historial-recibos/search` 500 porque Hibernate lee `historial_recibos_electronicos.nombre_cliente` y el dump prod + wrapper no aplicaban `32_historial_recibos_electronicos_nombre_cliente.sql`. Sin esa columna la lista queda vacía (el enrich HRE no iba en try/catch).
2. El backfill `05_backfill_documento_venta.sql` emitía `VTA-LEGACY-######`. La UI y las ventas nuevas usan `VTA-######`. Corregido el backfill; `62_normalize_documento_venta_vta.sql` renombra ensayos ya aplicados.

Orden: `62_` corre tras `05_backfill`; `32_` tras `45_` (exige tabla HRE de `28_confirmacion_pagos_electronicos`).

## UI lista

- Línea 1: **monto · VTA · fecha** (misma fila, `align-items: center`). Tras migrate, VTA = `VTA-######`, no `#id` ni `VTA-LEGACY-`.
- Línea 2: cliente (icono persona; **ocultar ANONIMO**) + spacer + `atendió: Nombre a.` (tooltip = nombre completo).
- Slot fijo de iconos (~48px): visto verde (`done_all`) si electrónico confirmado; icono de medio (26px); gris si pendiente electrónico.
- Mixto: opción propia en el select (no entra al filtrar un medio suelto).

## UI detalle

- **Documentos y operaciones** (aunque no haya documento): grilla 2 columnas — izquierda Comprobante + Estado; derecha Fecha de venta + Cajero que atendió (nombre completo). NC/ND / VTA nueva a ancho completo.
- Pie: medio a la izquierda; **TOTAL** + monto a la derecha (`flex`, `nowrap`, `margin-right: 48px` para no chocar con el FAB de opciones). El monto no debe intersectar el label TOTAL en cifras de millones.

## Relación con Orígenes de fondos (OF)

En tarjetas raíz con medio de Tickets, junto a **tickets sin corte** hay un botón (icono) que abre `TicketsSinCorteDialog`:

- Misma consulta: `metodoPagoId` + `sinCorte=true`, estado Pagado.
- Ventana **arrastrable** (header).
- Total parcial de tickets alineado en la misma grilla que los montos de fila (info | total | productos).
- Meta de fila: fecha, cliente, **usuario que atendió** (vía `sesionId`).
- Sin hint “Mismos filtros que Historial…”.

## Reset para ciclos de prueba

En sandbox, admin → **Reset datos transaccionales** (o `POST /sandbox/reset-datos-transaccionales`): ventas/cortes/ledger/egresos/CxC/notifs en 0; catálogos intactos. Logout + login; base inicial si aplica.

Tras reset: Historial vacío, sin corte = 0, movimientos OF en 0 (salvo base). Sembrar un set corto (efectivo, electrónico, mixto, anónimo, anular, restaurar, cierre, venta post-cierre) y validar filtros §4.6 / §10.9.

Detalle técnico: `contextos-ia/sandbox-reset-transaccional.md`.

## No confundir

- **Ingresos / corte-venta/search** = historial de **cierres**, no de tickets.
- Tickets sin corte = mismos que alimentan el “parcial” de OF / cierre de turno abierto.
- Filtro de un medio **no** incluye Mixto; Mixto es opción aparte.

## Anular y restaurar

La sigla de pagado en catálogo es `PAG` (no `P`). El filtro Pagado, los botones Anular/Restaurar y el modal de tickets sin corte la usan así.

Solo se anula, restaura o edita si el dinero aún no se contó y no hay cartera: `id` mayor que el watermark de `sinCorte` y sin `cuenta_por_cobrar`. Si no, el BE responde 409 (`IllegalStateException`) y el FE muestra `message`. No se crea nota crédito ni se mueve el ledger. El `PUT` genérico no queda bloqueado: el guard corre al pasar de pagado a anulado, en `restaurar-ticket` y al entrar a edición (`moveToEdition`).

Anular una venta sin corte abre un modal para elegir el origen del reembolso (por defecto **Caja: Efectivo**). Si ese origen es el del medio de la venta, no hay salida en el ledger: al anular, los tickets sin corte de ese medio bajan el total. Si es otro, en OF se ve `SALIDA_DEVOLUCION_VENTA` (Devolución de venta) en el origen elegido y `ENTRADA_CRUCE_DEVOLUCION_VENTA` (Ingreso por devolución en otro origen) en el del medio. La tarjeta muestra esa línea en movimientos aunque ya no queden tickets sin corte.

Editar en ventas abre un borrador y no toca el historial ni el comprobante. **Sin cambios en productos** descarta ese borrador (`POST /recibos/{id}/descartar-edicion`): la fila y el VTA quedan iguales. Si al cobrar la edición hay cambios, o si se devuelve porque el total bajó, ahí se anula el comprobante original (nota crédito), se borra ese historial y queda la venta nueva por el total ajustado. SQL: `69_documento_venta_historial_nullable.sql`.

Al bajar el total, el cajero elige el origen de la devolución (por defecto **Caja: Efectivo**). Si ese origen es el del medio de la venta, no hay salida en el ledger: los tickets sin corte de ese medio bajan la diferencia (la venta aún no entró al corte). Si elige otro origen, sale `SALIDA_DEVOLUCION_VENTA` de ese origen y entra `ENTRADA_CRUCE_DEVOLUCION_VENTA` en el del medio, para no descontar dos veces.

El watermark es el último corte vigente por id (`findFirstByEstadoNotInOrderByIdDesc`), no el máximo watermark. Si algún corte se creara con rango anterior, el guard puede quedar corto. Es el mismo límite de `sinCorte`; no se cambia aquí.

### Pendiente (no implementado)

| Dónde está el dinero | Qué falta |
|---|---|
| Sin corte | Nada |
| Corte generado | NC + inventario + salida del mismo medio y OF. El corte de ayer no se toca; el siguiente recoge la salida. Sin elegir egreso con naturaleza propia o movimiento de ledger (no reutilizar `REVERSO_ENTRADA_VENTA`) |
| Cartera: 3×100, abono 200, se queda 1 | NC por 200, saldo a 0, 100 en efectivo |
| Cartera: se devuelve 1 y lo pagado ya cubre lo que queda | NC por esa unidad y cierre de CxC por devolución; no sale plata; no usar `valor_perdida_costo` |
| Medio mal cobrado, corte ya generado | Traslado entre OF + NC de traza. Sin corte, restaurar (reabrir) alcanza |
