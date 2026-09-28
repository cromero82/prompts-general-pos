# Corte de ventas: Dividir (Split) y Eliminar bloqueado

Documentación del fix para corregir un **corte de ventas mal generado** (que agrupó
varios días en un solo corte) cuando **ya hubo egresos** con ese dinero.

## Origen

Incidente real en producción: un corte de cierre tomó 2 días (23/09 y 24/09/2026) en
**un solo corte**; después se registraron egresos desde Caja Menor. Al intentar
Eliminar el corte, el sistema bloquea porque el dinero ya se gastó.

## Cómo leer esta carpeta

| Documento | Para quién | Contenido |
|---|---|---|
| [`explicacion-detallada.md`](explicacion-detallada.md) | Equipo técnico / IA | Algoritmo del split, modelo de datos, validaciones, alcance y plan de pruebas |
| [`explicacion-simple.md`](explicacion-simple.md) | Cualquier persona | Qué pasó, qué hace "Dividir" y por qué es seguro, sin tecnicismos |

## Resumen en una línea

"Dividir" **anula** el corte malo (no lo borra), genera un corte por partición con los
mismos totales y reacomoda el ledger con asientos de ajuste temporales (puente),
dejando los egresos intactos y todo con traza y motivo obligatorio.

> **Contrato vigente:** `openspec/specs/corte-venta-split/spec.md`.
> Narrativo: `contextos-ia/corte-venta-split.md`. QA: `CONTEXTO-TESTER-POS.md` §4.9 / §10.1.
> **Pendiente de pruebas humanas** — ver `openspec/changes/2026-09-24-corte-venta-split/tasks.md`.

## Conceptos clave

- **Corte de ventas (cierre de turno):** agrupa las ventas de un rango y genera, por
  cada método de pago, un `ENTRADA_VENTA` (+ventas). Solo **Caja: Efectivo** se
  distribuye: genera además un `TRASLADO` (−) con contraparte en Caja Menor / Caja
  General. QR y Nequi reciben ventas sin traslado.
- **Eliminar:** solo se permite si **ninguna** OF que el corte tocó (medios de pago
  con ventas **y** cajas destino) tuvo movimientos posteriores.
- **Dividir:** permite corregir incluso cuando sí hubo egresos posteriores, porque
  **no cambia el total de dinero** — solo lo reparte mejor en el tiempo. No exige que
  el corte abarque más de un día: también sirve para separar turnos del mismo día.
- **`dividido`:** estado del corte original tras el split. Se conserva y se consulta,
  pero **no cuenta en Ingresos** (sus ventas ya están en los cortes nuevos).