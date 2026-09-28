# Glosario — Núcleo financiero POS

Fuente de verdad de nombres para UI, docs y auditoría.

| Término usuario | Técnico | Definición |
|-----------------|---------|------------|
| **Venta / Ticket** | `historial_recibo` (+ detalle) | Venta cerrada |
| **Nº venta (VTA-…)** | `documento_venta` | Id interno de venta (no es FE DIAN aún) |
| **Medio de pago** | `metodo_pago` | Efectivo, QR, Nequi… |
| **Forma de pago** | Contado / Crédito (DIAN) | Hoy operativo: contado |
| **Líneas de pago** | `historial_recibo_pago` | Cómo se cobró; **fuente del corte** |
| **Cierre de turno / Corte** | `corte_venta` + `corte_venta_detalle` | Arqueo por medio |
| **Ventas del turno** | `totalVentasSistema` | Σ cobros de tickets en la ventana (**sin** desfase) |
| **Esperado en caja** | `totalSistema` | `base + ventas − egresos ± mov. OF` |
| **Contado / Declarado** | `total` (físico) | Lo que el cajero declara |
| **Diferencia de caja** | `desfase` | Contado − Esperado |
| **Entrada por ventas** | `ENTRADA_VENTA` | Lleva ventas del corte al OF |
| **Ajuste de cierre** | `AJUSTE_CIERRE` | Cuadra OF al contado (**no** es venta) |
| **Origen de fondos (OF)** | `origen_fondos` + ledger | Caja / bolsillo / banco interno |
| **Dueños (raíz)** | OF raíz tipo `DUENOS` | No operativo del turno; cuentas con el dueño |
| **Cuenta del dueño** | OF hijo bajo Dueños | Due-to/due-from; retiros personales **≠** gasto P&L |
| **Clasificación operativa** | `movimiento_origen_fondos.clasificacion_operativa` | Qué es el movimiento (personal / vale / gasto / …), distinto del OF |
| **Cobranza / Abono** | `abono_cxc` (schema) | Pago de deuda; **≠** venta del día |
| **Ticket rápido** | venta simplificada (`VARIOSPROD`) | Sin ítems reales; No-IVA / adaptación |
| **Nota crédito (NC)** | `nota_ajuste` | Anulación interna; **≠** crédito cliente |
| **Legalizar** | reclasificar notif. email | Traslado desde «Sin Clasificar» → destino + tag `clasificacion_operativa` |
| **Formalizar egreso** | egreso + `SALIDA_EGRESO` desde bolsa | Dinero ya en «Sin Clasificar» (notif); crea documento egreso **sin** restar de nuevo el banco |
| **Naturaleza egreso** | `egreso.naturaleza` | COMPRA_MERCANCIA / GASTO_OPERATIVO / PERSONAL / DIVIDENDOS / TRIBUTO / OTRO (no RETIRO_DUENO) |
| **Tipo egreso (snapshot)** | `egreso.tipo_egreso_id` | Categoría del pago en el documento; default desde proveedor |

## Fórmulas del corte (por medio)

```text
Ventas     = Σ historial_recibo_pago (ventana)
Esperado   = Base + Ventas − Egresos ± Movimientos_OF
Contado    = declarado
Diferencia = Contado − Esperado
```

**Dashboard Ingresos** = **Ventas sin desfase** (`totalVentasSistema` / `corte_venta.total_ventas_sistema`) + columna **Cobranzas** (`ENTRADA_COBRANZA`). Nunca Contado, Esperado, base ni Diferencia. El KPI y la gráfica son **solo ventas**.

`consultar-rango.total` = Esperado (Σ `totalSistema`). `consultar-rango.totalVentasSistema` = tickets del turno (ej. 300.000, no 1.350.000).

**Resumen económico** = Ventas (tickets del corte, sin base ni desfase) + Cobranzas − Egresos. El `corte.total` (Contado) y `corte.total_sistema` (Esperado) no son la venta del día. Los **desfases** se guardan en el detalle; más adelante se verán como afectación a OF/caja.

## Motivos de diferencia (`DESFASE_CIERRE`) → acción

| Código | Acción esperada | Enforcement |
|--------|-----------------|-------------|
| `ERROR_MEDIO_PAGO` | `TRASLADO_OF` | CTA «Abrir traslado OF» en cierre / revisión |
| `MOVIMIENTO_NO_REGISTRADO` | `REGISTRAR_DOCUMENTO` | **Bloquea** registrar cierre y finalizar revisión (BE + FE) |
| `ERROR_CONTEO` / `FALTA_CAMBIO` | `AJUSTE_CIERRE` | Ajuste over/short con auditoría |
| `AJUSTE_PERSONAL_CIERRE` | `REGISTRAR_DOCUMENTO` | Igual: documentar antes; no cierra con este motivo |
| `DESCONOCIDO` / `OTRO_DESFASE` | `REVISAR` | Hint; preferir reclasificar |

Contrato `motivo_movimiento.accion_esperada`: `TRASLADO_OF` \| `REGISTRAR_DOCUMENTO` \| `AJUSTE_CIERRE` \| `REVISAR`.

## Legalizar notificación (túnel email → OF)

1. Plantilla con OF (ej. EGRESO LULO: Bancolombia QR → **Sin Clasificar**) crea `MOVIMIENTO BANCO POR IDENTIFICAR` (`id_referencia` = notif).
2. Cola UI **Por identificar** (`clasificacion IS NULL`).
3. `PUT /api/notificaciones-email/{id}/legalizar` `{ clasificacion, observacion?, origenFondosDestinoId? }`:
   - Destinos por defecto: **Cuenta del dueño** (bajo raíz Dueños) / Bolsillo Nómina; gasto exige destino.
   - Inserta TRASLADO `LEGALIZACION_NOTIFICACION` (bolsa → destino) + motivo `LEGALIZAR_*` + `clasificacion_operativa`.
4. Archivar **no** revierte el ledger.

## Formalizar egreso (gasto con proveedor, dinero ya en bolsa)

Cuando el email/plantilla ya movió plata **banco → Sin Clasificar** (`MOVIMIENTO BANCO POR IDENTIFICAR`):

1. **No** registrar un egreso normal desde Bancolombia (doble resta).
2. En Orígenes → movimientos de la bolsa: acción **Formalizar egreso**.
3. `POST /api/egresos` con `fromMovimientoOrigenFondosId` (+ proveedor, valor, OF bloqueado a la bolsa).
4. BE: fuerza `origenFondosId` = OF del movimiento; crea egreso + `SALIDA_EGRESO` solo desde esa bolsa; `clasificacion_operativa=GASTO_NEGOCIO` en la salida; idempotente (un egreso por movimiento). En Cierre de turno, ese gasto va a **Egresos** del medio electrónico (QR/Nequi/…); el débito PAGASTE deja de sumar en **Movimientos**.
5. Distinto de **Legalizar** (dueño/nómina sin doc de proveedor).
6. **Cuenta del dueño** acumula por clasificación; **bajar** ese saldo = egreso de pago (PERSONAL / DIVIDENDOS / etc.) desde ese OF.

## Árbol OF — operativo vs Dueños

```text
Operativo del día     → Efectivo, QR, Nequi, Sin Clasificar, Nómina, Arriendo…
Dueños (no operativo) → Cuenta del dueño   ← retiros personales / due-to
Caja General / reserva → proveedores, etc.
```

- **OF** = dónde está la plata.  
- **`clasificacion_operativa`** = qué es para el negocio (personal ≠ gasto).  
- Corte de turno solo mira medios operativos; Dueños no es arqueo.  
- `periodo_cierre_id` reservado para cierre mensual (después de CxC).  
- **DnD:** fila de movimiento (impacto +) → OF destino abre traslado con `clasificacionOperativa` sugerida.  
- **Reporte:** Orígenes → «Por clasificación» → `GET /movimientos-origen-fondos/por-clasificacion`.
