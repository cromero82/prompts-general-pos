# Multipago (2–3 medios por ticket) — POS Infinito

Documento vivo para IAs y humanos. Complementa `MIGRATE-PROD-TO-DIAN-V2.md`
(script `30_`) y el handoff de finanzas.

## Objetivo

Una venta liquidada en el momento puede repartirse en **hasta 3 medios**
(ej. $60.000 efectivo + $40.000 QR). El **corte**, **orígenes (parcial)** y
`ENTRADA_VENTA` deben ver montos **por medio**, no el total en un solo MP.

No es venta a crédito / CxC (eso sería forma de pago DIAN = 2). Solo **contado**.

## Glosario breve (DIAN)

| Término | Significado |
|---|---|
| **UBL** | Estándar XML de facturación; la DIAN usa un subconjunto UBL 2.1 |
| **`cac:PaymentMeans`** | Bloque XML “cómo se paga”; cardinalidad **1..N** |
| **Forma** (`PaymentMeans/ID`) | `1` Contado / `2` Crédito |
| **Medio** (`PaymentMeansCode`) | Código oficial (ej. `10` efectivo, `45` transferencia) |

Los **montos por medio** viven en nuestra BD (`historial_recibo_pago`) para caja.
En el XML futuro suelen informarse N códigos de medio; el total fiscal va en
`LegalMonetaryTotal`.

## Modelo de datos

```text
recibo                         → borrador (sin recibo_pago)
historial_recibo               → cabecera: total + metodo_pago_id (primario)
historial_recibo_pago          → N líneas: metodo_pago_id, monto, orden  ★ fuente de verdad
documento_venta                → 1:1 historial; sin tabla de pagos (JOIN al emitir)
metodo_pago.codigo_dian_payment_means → mapeo a PaymentMeansCode
```

Constraint de negocio: `SUM(historial_recibo_pago.monto) = historial_recibo.total`.

SQL: `pos-relational-data-service/.../database/30_historial_recibo_pago.sql`  
Incluido en `apply-migrate-prod-to-dian-v2.sh`.

Backfill prod: 1 línea por historial existente (`monto = total`).

## Flujo al pagar

1. FE envía `PUT /recibos/{id}` con `pagos: [{ metodoPagoId, monto }, …]` (o sin `pagos` → 1 línea = total).
2. BE valida 1–3 medios, montos > 0, MP distintos, SUM = total.
3. Primario en cabecera = **mayor monto** (empate → efectivo id=1).
4. Persiste `historial_recibo_pago`; QR electrónico usa solo el **tramo QR**.
5. Corte / consultar-rango: `SUM(pago.monto) GROUP BY metodo_pago_id`.

Modal efectivo “Mixto”: línea de efectivo aplicada = `total − otros`; el cambio sale del efectivo tendered (`montoRecibido` puede ser > total).

## APIs / UI

| Pieza | Detalle |
|---|---|
| Pago | `ReciboDto.pagos[]` → `ReciboServiceImpl` |
| Consulta | `GET /historial-recibos/{id}/pagos` |
| Corte | `HistorialReciboPagoRepository.findResumenVentasPorMetodoPago*` |
| Tirilla | Varias filas `PAGO:` si hay desglose |
| Historial ventas | Footer “Pago mixto” con montos por medio |

## IVA futuro (Responsable de IVA)

Los impuestos van en **líneas de venta** (`producto` / detalle + `TaxTotal` XML),
**no** en `historial_recibo_pago`. El multipago no bloquea esa versión.

## Pendiente

- Generador XML UBL con N `PaymentMeans` (aún no existe emisor en BE).
- Validar con proveedor tecnológico códigos `45` para QR/Nequi.
- Anulación ticket ↔ borrar/revertir todas las líneas + ledger (tema más amplio).

## Archivos clave

| Repo | Ruta |
|---|---|
| SQL | `…/database/30_historial_recibo_pago.sql` |
| BE | `ReciboServiceImpl`, `HistorialReciboPago*`, `CorteVentaServiceImpl` |
| FE | `pago-efectivo-cambio`, `detalle-ticket`, `recibo-print.service`, `historial-ventas` |
| Migrate | `prompts-general-pos/MIGRATE-PROD-TO-DIAN-V2.md` § Multi-pago |
