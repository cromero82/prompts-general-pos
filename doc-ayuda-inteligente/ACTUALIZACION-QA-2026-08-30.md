# Actualización QA — oleada 2026-08-30

**Para:** tester + IA en pair testing (sandbox / pos-sandbox).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre).  
**Narrativos:** `contextos-ia/producto-presentaciones.md`, `contextos-ia/cxc-abono-pagador.md`, `contextos-ia/confirmacion-pagos-electronicos.md`.  
**SQL sandbox (orden):** `50_producto_presentacion.sql` → `51_producto_presentacion_migracion_final.sql` → `52_abono_cxc_cliente_pagador.sql`.

**Chat / trabajo de referencia:** presentaciones UoM (UI ticket + selector), Quién abona en CxC, rediseño panel Pagos electrónicos (`azul-atras`).

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Menudeo / UoM** | Mismo producto unidad + paquete = **2 líneas** juntas; `(Por unidad)` en negrita; sin botón sync si ya hay ambas; toggle sí cambia modo/precio si solo hay una. |
| **Seleccionar producto** | Dual precio más grande; deshabilitado **gris** y no seleccionable. |
| **CxC Quién abona** | En Registrar abono: selector (otro cliente o +); rail muestra quién pagó; Saldo resaltado. |
| **Panel QR** | Tema azul claro atrás + tarjeta clara; botones Asociar \| Ya no esperar arriba; Ver productos abajo der.; leyenda tiempo **completa** (sin `…`). |

---

## 2. Checklist pair testing (prioridad)

### A. Presentaciones / menudeo (~15 min)
1. Producto con precio unidad: agregar **paquete** → luego **unidad** (o al revés) → 2 líneas; unidad con `(Por unidad)`; **sin** botón sync.
2. Solo una presentación en ticket: toggle cambia precio y vuelve.
3. Modal Seleccionar: dual legible; deshabilitar producto en Productos → buscarlo → gris, no Seleccionar.
4. Confirmar que SQL 50/51 corridos (si no hay presentaciones, ensure al vender).

### B. CxC pagador (~10 min)
1. Abrir crédito → Registrar abono → Quién abona = deudor → OK.
2. Abonar con **otro** cliente (o crear con +) → rail muestra ese nombre; deudor del crédito no cambia.
3. Saldo del panel se ve destacado.

### C. Panel Pagos electrónicos (~10 min)
1. Cobro QR → pendiente visible, tipografía legible.
2. Layout: icono|monto; Asociar + Ya no esperar; recibo abajo; **Hoy, … · Hace N minutos** sin cortar.
3. Asociar / Ya no esperar siguen funcionando.

---

## 3. Sí reportar / No es bug (atajos)

| Observación | Tip |
|-------------|-----|
| Unidad y paquete se fusionan en 1 línea | **Bug** UoM |
| Sin toggle cuando ya hay ambas | **Diseño OK** |
| Deshabilitado se agrega al ticket | **Bug** |
| No aparece Quién abona | ¿SQL 52 + BE reiniciado? |
| Leyenda con `…` | **Bug** UI panel |
| Panel muy oscuro / ilegible | Comparar con tema `azul-atras` liberado |

---

## 4. Entregar a la IA / tester

1. Este archivo + `CONTEXTO-TESTER-POS.md`.  
2. Specs: `producto-presentaciones-uom`, `cxc-abono-pagador`, `confirmacion-pagos-electronicos`.  
3. Confirmar scripts 50→51→52 en BD sandbox.
