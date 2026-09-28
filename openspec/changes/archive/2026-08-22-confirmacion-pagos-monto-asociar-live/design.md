## Context

Flujo QR ya existía (HRE + email + panel). Esta entrega cierra gaps operativos del cajero: timing del email, montos distintos y política de crédito en faltantes.

## Goals / Non-Goals

**Goals**
- Confirmación asistida cuando monto email ≠ esperado.
- Faltante: ticket reabierto + CxC manual + retarget HRE.
- Asociar con lista viva (polling).

**Non-Goals**
- API oficial Bancolombia QR (sigue plan B; ver interceptar-pagos-tunel.md).
- Cambiar multipago genérico fuera del tramo QR.
- Auto-reinicio de puente-tienda.

## Decisions

| Decisión | Motivo |
|----------|--------|
| Faltante no crea CxC sola en puente | El cajero debe identificar cliente y montos en el modal estándar |
| Retarget HRE CONFIRMADA → abono | Evita segundo pendiente CREADA duplicado |
| Polling 2500 ms en panel y modal Asociar | Misma cadencia; UX predecible |
| Modal Asociar abre vacío + spinner | Evita race «No hay emails» si el cajero es más rápido que el email |
| `bloquearMontos` + `disableClose` | Evita cancelar a medias el flujo faltante→crédito |

## Risks / Trade-offs

- Doble polling (panel + modal) mientras Asociar está abierto: aceptable a volumen de tienda.
- Si puente está caído, panel y modal vacíos aunque HRE exista: operador debe levantar :8095.

## Migration

Ninguna SQL nueva en este cierre; usa schema `28_confirmacion_pagos_electronicos` (+ tablas CxC/OF existentes).
