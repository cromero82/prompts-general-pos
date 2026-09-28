# Actualización QA — oleada 2026-09-12

**Para:** tester + IA en pair testing (Ingresos / cierre).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre; §2.4 / §4.9 / §10.1 / §10.6).  
**Narrativo:** `contextos-ia/ingresos-dashboard.md`.  
**Spec:** `ingresos-dashboard`.  
**Glosario:** `GLOSARIO-NUCLEO-FINANCIERO.md`.

**Chat / trabajo de referencia:** ventas del sistema (`totalVentasSistema`) como fuente de verdad de Ingresos; el desfase del conteo **no** corrige esa cifra.

Las oleadas `2026-09-10` (PAGASTE ↔ egreso), `2026-09-06` (asistente de caja), `2026-09-03` (Historial) y `2026-09-02` (medios) **siguen vigentes**.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Ventas = tickets** | Columna Ventas del cierre = suma de tickets cobrados. Ese mismo número va al dashboard. |
| **Sin desfase** | Si el Contado no calza con el Esperado, Ingresos **no** sube ni baja. El desfase se guarda; aún no se ve en OF/caja. |
| **No es Esperado** | Esperado (base + ventas − egresos ± movs) **no** es la venta del día. Ej. ventas 300.000 y Esperado 1.350.000 → Ingresos = 300.000. |
| **KPI y gráfica** | Solo ventas. Cobranzas en columna propia; no entran al KPI ni a las barras. |
| **Orden** | Tabla: día más reciente arriba. Gráfico: más reciente a la **derecha**. |

---

## 2. Checklist pair testing (prioridad)

### A. Ventas vs Esperado (~10 min)

1. Abrir **Cierre de turno** (desde último cierre → ahora).
2. Anotar la columna **Ventas** (suma del pie).
3. Registrar el cierre (Contado puede ser igual o distinto al Esperado).
4. Ir a **Ingresos** (dashboard y tabla / vista corte).
5. El día debe mostrar **esa** cifra de Ventas, no el Esperado ni el Contado.

### B. Desfase no mueve Ingresos (~10 min)

1. En un medio, declarar Contado distinto del Esperado y elegir motivo de diferencia.
2. Guardar el cierre.
3. Ingresos: Ventas = tickets de ese turno (paso A). **No** tickets ± desfase.
4. El desfase queda en el corte; **no** exigir todavía verlo en Orígenes de fondos.

### C. Cobranzas y orden (~5 min)

1. Un abono CxC no infla la columna Ventas ni el KPI ni las barras.
2. Tabla de Ingresos: más reciente arriba.
3. Gráfico: más reciente a la derecha (si el eje se ve al revés, recargar; a veces es cache).

---

## 3. Sí reportar / No es bug

| Observación | Tip |
|-------------|-----|
| Dashboard = columna Ventas del cierre (tickets) | **Diseño OK** |
| Diferencia de caja distinta de cero | **Diseño OK** si el conteo no calza con Esperado |
| Desfase guardado y OF/caja aún no lo muestran | **Diseño OK** (pendiente) |
| KPI/gráfica sin cobranzas | **Diseño OK** |
| Ingresos muestra Esperado o Contado como Ventas | **Bug** |
| Ingresos = tickets ± desfase | **Bug** |
| Cobranzas dentro de Ventas o del KPI | **Bug** |
| Gráfico con el día más nuevo a la izquierda (tras recargar) | **Bug** |
