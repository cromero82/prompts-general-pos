# Contexto IA — Asistente contar billetes

**Última actualización:** 2026-09-25.  
**OpenSpec:** `openspec/specs/cierre-asistente-caja/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.9 / §10.1 / §10.6; oleada `ACTUALIZACION-QA-2026-09-06.md`  
**SQL:** ninguno (solo UI + `corte-venta.base-efectivo` ya existente).

> Se llama **«Asistente contar billetes»** (antes «Asistente para cierre de caja»). El
> componente conserva el nombre `asistente-cierre-caja-dialog` en el código.

## Qué es

Diálogo desde **Cierre de turno** (fila Efectivo, botón con tooltip «Asistente contar
billetes») para contar billetes/monedas COP y asociar el resultado como efectivo de la caja.

**El cajero deja la base en el cajón y cuenta solo el resto.** La leyenda lo dice con el monto
real: «Deja la base $150.000 en la caja y cuenta los demás billetes por denominación».

## Fórmulas

| Concepto | Cálculo |
|----------|---------|
| Total billetes | Σ (cantidad × denominación) — efectivo **sin** base |
| **Contado** (lo que se asocia al cierre) | total billetes **+ base** |
| **Diferencia** | Contado − Esperado (fila efectivo, que incluye base) |

El resumen del diálogo muestra **solo Total billetes y Diferencia**.

Por qué se vuelve a sumar la base: el corte guarda el efectivo completo del cajón y el
Esperado incluye la base, así que comparar sin ella daría una diferencia falsa. Como el cierre
en vista **Compacta** muestra Efectivo sin base, ahí la columna Real coincide exactamente con
el Total billetes del asistente.

Denominaciones: `billetes-cop.const` (`BILLETES_COP`).

## FE

- `asistente-cierre-caja-dialog.component.*` (arrastrable, CDK drag en el header).
- Padre: `cierre-ventas.component` — al Asociar, `row.totalRealCtrl` = `resultado.contado`
  (efectivo completo); guarda `conteosPrevios` para rehidratar.
- Base: `ConfigurationService.obtenerBaseEfectivoSugerida` (`corte-venta.base-efectivo`),
  **solo lectura** para la leyenda.

## No es

- Editor de la base: el diálogo ya no la modifica ni la persiste (antes sí). Ajustarla es de
  otra pantalla.
- «Ventas (menos movimientos)», Esperado ni fórmula: salieron del resumen.
- Reloj / fecha-sistema para simular día 01/02/03 (handoff diferido:
  `AI-HANDOFF-SANDBOX-SIMULAR-DIA-2026-09.md`).
- Distribución de efectivo post-cierre (otro diálogo).
- Motivo de desfase: se elige en el cierre, no dentro del conteo.
- Indicadores del cierre ni vistas Compacta/Extendida: eso es
  `contextos-ia/cierre-turno-indicadores.md`.
- Fuente de verdad de Ingresos: esa sigue siendo `totalVentasSistema` (tickets, sin desfase).
