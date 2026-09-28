# Actualización QA — oleada 2026-09-03

**Para:** tester + IA en pair testing (sandbox).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre; §4.6 / §10.9).  
**Narrativo:** `contextos-ia/historial-tickets.md`.  
**Spec:** `openspec/specs/historial-tickets/spec.md`.  
**Reset:** menú admin **Reset datos transaccionales** (sandbox). Detalle técnico: `contextos-ia/sandbox-reset-transaccional.md`.

**Chat / trabajo de referencia:** Historial Tickets — filtros Cliente/Producto, lista compacta, documentos en 2 columnas, TOTAL sin cruce con el monto ni con la tuerca.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Filtro Cliente** | Autocomplete; X limpia; anónimo no sale como nombre en la fila |
| **Filtro Producto** | Autocomplete; la venta aparece si **incluye** ese producto |
| **Lista** | Monto · VTA · fecha; abajo cliente + `atendió: Nombre a.`; icono de medio (visto si QR/Nequi confirmado) |
| **Documentos** | Fecha de venta y Cajero **frente a** Comprobante y Estado |
| **TOTAL** | Un poco a la izquierda (no lo tapa la tuerca); en millones no se cruza con la palabra TOTAL |
| **Reset** | Punto cero: ventas 0, sin corte 0, movimientos 0 (salvo base inicial) |

La oleada `ACTUALIZACION-QA-2026-09-02.md` (medios / plantillas / Asociar) **sigue vigente**.

---

## 2. Checklist pair testing (prioridad)

### A. Punto cero (~5 min)

1. Admin → **Reset datos transaccionales** → confirmar.
2. Logout + login. Si pide base inicial, regístrala (anota el monto).
3. Historial Tickets: cualquier filtro → **lista vacía**.
4. Orígenes de fondos: tickets sin corte = **0**. Movimientos en 0 salvo la base.

### B. Semilla corta (~15 min)

Cobra y anota (cambia nombres por clientes/productos reales del catálogo):

| Ticket | Medio | Cliente | Productos | Después |
|--------|-------|---------|-----------|---------|
| T1 | Efectivo | Ana | P1 | Pagado |
| T2 | QR o Nequi | Bruno | P2 | Pagado |
| T3 | Mixto (efectivo + electrónico) | Ana | P1 + P2 | Pagado |
| T4 | Efectivo | sin cliente | P1 | Pagado |
| T5 | Efectivo | Ana | P2 | **Anular** |
| T6 | Efectivo | Bruno | P1 | **Restaurar** |
| — | — | — | — | **Cierre** |
| T7 | Efectivo | Ana | P1 | Tras el cierre |

### C. Filtros (~15 min)

Recorre la tabla F0–F16 de `CONTEXTO-TESTER-POS.md` §4.6. Mínimo obligatorio:

1. Pagado / Anulados / Restaurados / Todos.
2. Fecha hoy vs un día vacío.
3. Efectivo vs Mixto vs el medio de T2.
4. Tickets sin corte = solo T7.
5. Cliente Ana vs Bruno; X limpia.
6. Producto P1 vs P2; X limpia.
7. Ana + Efectivo; P1 + sin corte.

### D. Detalle UI (~5 min)

1. Elige T1: Fecha y Cajero a la **derecha** de Comprobante / Estado.
2. TOTAL no tapado por la tuerca.
3. Si puedes, una venta grande (millones) o revisa que el pill verde no se meta en la palabra TOTAL.

---

## 3. Sí reportar / No es bug

| Observación | Tip |
|-------------|-----|
| Lista vacía justo después del reset | **Diseño OK** |
| Lista vacía con 3 filtros a la vez y no hay venta que cumpla los tres | **Diseño OK** |
| Mixto no aparece en Efectivo | **Diseño OK** — usar Mixto |
| Anónimo sin nombre en la fila | **Diseño OK** |
| T7 no sale en “sin corte” o T1 sí sale | **Bug** |
| Ana ve tickets de Bruno | **Bug** |
| P1 no saca una venta que sí lo tenía | **Bug** |
| Fecha/cajero debajo (no al frente) de Comprobante/Estado | **Bug** de layout |
| TOTAL cruzado con el monto o tapado por la tuerca | **Bug** de layout |

---

## 4. Entregar a la IA / tester

1. Este archivo + `CONTEXTO-TESTER-POS.md`.  
2. Si el ciclo se ensucia: **reset otra vez** y vuelve a sembrar. No pelear con datos viejos.
