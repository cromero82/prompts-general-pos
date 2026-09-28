# Contexto IA — Indicadores del Cierre de turno (modo simple + footer)

**Última actualización:** 2026-09-28.  
**OpenSpec:** `openspec/specs/cierre-turno-indicadores/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.9 / §4.11  
**SQL:** footer/4 cifras sobre `arbol` + `consultar-rango`. Snapshot opcional `74_corte_venta_kpis_snapshot.sql`. `cartera-maxima` (`75_`) no entra en estas tortas.

## Qué es

El **modo simple** del Cierre de turno: cuatro cifras de dinero + **Cartera**, tabla **Compacta**
(por defecto) o **Extendida**, y la vista de solo lectura **Corte de venta #n** (Ingresos →
Detalles por Fecha → Ver). Las cuatro de dinero se publican en el **footer** de Ingresos y
Orígenes de fondos. Cartera no va al footer.

## Los cuatro indicadores de dinero

| Orden | Etiqueta | Cálculo |
|-------|----------|---------|
| 1 | **Ventas turno** | Σ (`totalVentasSistema` + `totalCobranzasSistema`) de todos los medios |
| 2 | **Efectivo disponible** | efectivo de la registradora + saldo de las demás cajas FISICAS |
| 3 | **Dinero medios electrónicos** | todo lo que no es efectivo físico |
| 4 | **Total dinero disponible** | (2) + (3) |

Se excluyen las cajas de **dueños** (`tipoOrigenFondosCodigo = DUENOS`). `naturaleza = FISICA`
→ efectivo; `ELECTRONICA`, `MIXTA` o sin declarar → electrónico.

«Ventas turno» se llamaba **«Vendido»** hasta 2026-09-25. En el cierre: delta vs **último corte
vigente** (fecha `dd/MM` + monto), botón **Ver detalles** (desglose por medio). No se registra
el cierre si Ventas turno = 0.

## Cartera

Saldo CxC vigente (`ABIERTA`/`PARCIAL`). Torta: cobrada verde / pendiente rojo
(`totalTicket` − saldo vs saldo). Delta vs **inicio del día calendario** (no vs snapshot nulo
del último corte). SUBE = más deuda (alerta); BAJA = mejora. Día anterior 0 y hoy > 0 → +100 %
SUBE. `cartera-maxima` no pinta esta torta.

En **Ver** de un corte sin snapshot: reconstruir a esa fecha con CxC + abonos +
`recibo_detalle.fechaCreacion`.

## Dos orígenes para la misma cifra de dinero

| Dónde | De dónde sale el disponible |
|-------|------------------------------|
| Diálogo de Cierre de turno | columna **Real** de cada fila + saldo de las otras cajas |
| Footer de Ingresos / Orígenes de fondos | solo saldos: `saldoOrigenConVentasSinCorte` |

Las cobranzas del turno ya están en el ledger: no se vuelven a sumar al disponible (sí en
«Ventas turno»).

## Vista Ver (Corte de venta #n)

- Mismos KPIs y misma tabla Compacta (`Sistema` / `Real`, Efectivo sin base) | Extendida
  (`Esperado` / `Real`).
- Título: `#n` + fecha + **‹ ›** para recorrer los días ya consultados en Detalles por Fecha
  (sin cerrar ni Consultar otra vez). Varios cortes el mismo día: pestañas; ‹ › cambia de día.
- Ventas turno en Ver: delta vs **día calendario anterior**.

## FE

- **`origenes-fondos/service/total-disponible.service.ts`** — mecanismo de las 4 cifras +
  `LABEL_*` (incluye `LABEL_CARTERA`).
- **`ingresos/kpis-turno.util.ts`** — Cartera (resumen, delta, as-of día), merge referencia
  Ventas turno.
- **`ingresos/cierre-ventas/cierre-ventas.component.*`** — KPIs live, toggle, (?), Ver detalles.
- **`ingresos/ingresos.component.ts`** — panel Cartera, footer, Detalles por Fecha → Ver.
- **`origenes-fondos/movimiento-referencia-dialog/`** — modal Ver corte: KPIs, tabla, ‹ ›.
- **`origenes-fondos/origenes-list/`** — footer de las 4 cifras.

## Tabla del cierre (y del modal Ver)

- **Compacta** (por defecto): `Método de pago | Sistema | Real | Diferencia`. En Efectivo no
  suma la base en Sistema ni en Real. Total = lo mostrado.
- **Extendida**: todas las columnas, incluida Base; encabezado «Esperado».
- Columna de conteo: **Real** (antes «Contado»).

## No es

- Fuente de verdad de Ingresos: `totalVentasSistema` (tickets, sin cobranzas). «Ventas turno»
  **sí** incluye cobranzas.
- Torta vs CARTERA MAXIMA (el parámetro existe para otras funciones).
- Arqueo de dueños.
- Conteo de billetes: **Asistente contar billetes**.
