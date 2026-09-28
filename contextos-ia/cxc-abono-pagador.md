# Contexto IA — CxC: quién abona (pagador)

**Última actualización:** 2026-09-11.  
**OpenSpec:** `openspec/specs/cxc-abono-pagador/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.5 / §10.3  
**SQL:** `52_abono_cxc_cliente_pagador.sql`  
**Ayuda UI:** `ayuda-documental/tickets-cxc/`

## Qué es

En el panel derecho **Crédito** (rail), al **Registrar abono**, el cajero indica **quién entrega el dinero**. Puede ser el mismo deudor de la CxC u **otro cliente** ya registrado (o crear uno con **+** / Enter del selector).

El deudor de la cuenta (`cuenta_por_cobrar.cliente_id`) no cambia: solo se registra el pagador del abono.

## Modelo

| Campo | Tabla |
|-------|--------|
| `cliente_pagador_id` | `abono_cxc` (FK `client`) |
| `cliente_pagador_nombre` | snapshot al registrar |

Si no se envía pagador, el BE usa el deudor de la CxC.

## FE

- Dialog `registrar-abono-cxc-dialog`: `cliente-selector` con label **Quién abona** (preselecciona deudor). Al enfocar **Monto del abono**, el valor queda seleccionado (listo para reemplazar).
- Rail: lista de abonos muestra medio · **nombre pagador** (negrita). Hover sobre la fecha corta (`19/ago`) muestra la traza `FechaUtilService.formatDate` («Hoy, 8:30 p. m.»).
- Saldos del rail: **Total ticket**, **Abonado**, **Saldo**. No se muestra ni se calcula «Original crédito».
- Estilo rail: tipografía más legible; **Saldo** resaltado; ancho ~320px.

## API

`POST /cuentas-por-cobrar/{id}/abonos` body incluye opcional:

```json
{
  "monto": 10000,
  "metodoPagoId": 3,
  "clientePagadorId": 42,
  "clientePagadorNombre": "María Pérez"
}
```

## Migración sandbox

Aplicar `52_abono_cxc_cliente_pagador.sql` tras `50`/`51` si también liberan presentaciones.
