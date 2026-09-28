# Contexto IA — Presentaciones / UoM (menudeo vs paquete)

**Última actualización:** 2026-08-30.  
**OpenSpec:** `openspec/specs/producto-presentaciones-uom/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.2 / menudeo  
**SQL:** `50_producto_presentacion.sql`, `51_producto_presentacion_migracion_final.sql`  
**Sandbox:** aplicar `50` → `51` (y `52` si también liberan CxC pagador).

## Problema que resuelve

Antes, `producto` tenía `precio` + `precio_unidad` pero la línea de ticket solo guardaba `producto_id`. Al agregar el mismo producto en modo unidad y luego paquete, el FE fusionaba por `productoId` y sobrescribía el modo.

## Modelo

| Concepto | Tabla / campo |
|----------|----------------|
| Ítem de inventario | `producto` (`existencia` = **unidad base**) |
| Forma vendible | `producto_presentacion` (`PAQUETE`, `UNIDAD`, …) con `factor_a_base` y `precio_venta` |
| Línea de venta | `recibo_detalle.presentacion_id` + snapshots (`factor_snapshot`, `precio_unitario_snapshot`, `cantidad_base`) |

Vista stock paquete (no es columna mutable):

```text
existencia_paquetes = floor(existencia / factor_paquete)
resto_unidades      = existencia % factor_paquete
```

Vender 1 PAQUETE (factor 20): `existencia -= 20` (vía `cantidad_base`).

## APIs

| Método | Ruta |
|--------|------|
| GET | `/products/{id}/presentaciones` |
| POST | `/products/{id}/presentaciones` (admin) |
| POST | `/products/{id}/presentaciones/ensure` |
| PUT/DELETE | `/producto-presentaciones/{id}` |
| POST/PUT | `/recibo-detalles` acepta `presentacionId` |

## FE — ticket (`detalle-ticket`)

- Merge por **`presentacionId`** (paquete y unidad no se fusionan).
- Líneas del mismo producto base se **agrupan** (paquete junto a unidad).
- Línea menudeo muestra **`(Por unidad)`** en negrita junto al nombre.
- Toggle «usar precio por unidad / empaque»:
  - Visible solo si el producto tiene menudeo **y** aún no coexisten ambas presentaciones en el ticket.
  - Antes de alternar hace `ensure` de presentaciones y cambia `presentacionId` + precio (`precioVenta`).
- Si ya hay paquete + unidad del mismo producto: **no** se muestra el toggle.

## FE — modal Seleccionar producto

- Precio dual (General / Unidad): tipografía legible; celda más alta.
- Producto **deshabilitado** (`activate ≠ 1`): fila gris (como lista Productos); no se puede Seleccionar / Enter / doble clic; sí se puede Editar.

## Migración

1. Ejecutar `50_…` (DDL + backfill mínimo).
2. Sprint final: `51_…` (todos los productos + inferencia histórica por precio).
3. Factores reales de paquete (p.ej. 20): UPDATE operativo / planilla — no inventar en script.

## Compat

`producto.precio` / `precio_unidad` se mantienen sync desde presentaciones para UI legacy.
