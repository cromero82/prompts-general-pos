# Contexto IA — Dashboard Ingresos (ventas sin desfase)

**Última actualización:** 2026-09-28.  
**OpenSpec:** `openspec/specs/ingresos-dashboard/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §2.4 / §4.9 / §10.1; oleada `ACTUALIZACION-QA-2026-09-12.md`  
**Glosario:** `GLOSARIO-NUCLEO-FINANCIERO.md`

## Qué es

Fuente de verdad de Ingresos = **Ventas del sistema** (`totalVentasSistema`: tickets cobrados). **Sin desfase.**

Tras registrar el corte, esa cifra va al KPI, la gráfica y la tabla. Base, Esperado, Contado y Diferencia son arqueo: se guardan, no corrigen la venta del día. Más adelante los desfases se verán como afectación a OF/caja.

**Cortes que no cuentan:** `eliminado` y `dividido` (constante `ESTADOS_NO_VIGENTES`). Un corte `dividido` es el original de un SPLIT: sus ventas ya las heredaron los cortes nuevos, así que contarlo otra vez las duplicaría (se veía como un día sumando original + particiones). Ver `contextos-ia/corte-venta-split.md`.

## Campos

| Campo | Significado | ¿Ingresos? |
|-------|-------------|------------|
| `totalVentasSistema` / `corte_venta.total_ventas_sistema` | Tickets cobrados | **Sí — verdad** |
| `consultar-rango.total` / `corte.totalSistema` | Esperado = base + ventas − egresos ± movs | No |
| `corte.total` | Contado (físico) | No (columna Total caja) |
| `desfase` | Contado − Esperado | No (guardado; OF después) |

Ejemplo: ventas 100k+100k+100k = **300.000**; Esperado 1.350.000; Contado distinto. Ingresos = **300.000**.

## FE / BE

- Cierre: `cierre-ventas.component` — persiste ventas, contado y desfase. Las Ventas no se recalculan con el conteo.
- Ingresos: `ingresos.component` — KPI/gráfica/tabla = solo ventas (sin desfase, sin cobranzas).
  La tabla va **desc** (día más reciente arriba). El gráfico va **asc** (más reciente a la derecha).
- Search DTO incluye `totalVentasSistema` de cabecera.
- SQL: `65_corte_venta_total_ventas_sistema.sql` (solo v02 / prod v02).

## No es

- Ajuste visible de desfases en OF o caja (pendiente).
- Incluir el turno abierto (sin corte) en el dashboard.
- Usar `vt.total` (Contado) o el desfase como fallback de ventas.
- El conteo del **Asistente contar billetes** (eso es arqueo, no Ingresos).
- Corregir cortes: Eliminar / Dividir viven en `corte-venta-split` (botones en «Detalles por Fecha»).
- **Ver** (Detalles por Fecha): modal `Corte de venta #n` — KPIs + tabla Compacta/Extendida +
  ‹ › entre días consultados. Spec: `cierre-turno-indicadores`.
- Panel izquierdo: KPI **Cartera** (saldo CxC, torta cobrada/pendiente, delta vs día anterior).
