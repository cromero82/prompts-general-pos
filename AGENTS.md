# AGENTS — prompts-general-pos

**Contexto general de la app** y de la **instalación en producción** (Tienda Infinito). Vive junto a los otros repos en `…/repos/prompts-general-pos`. El launcher y el BE no sustituyen este almacén.

PC de tienda: cargar `CURSOR-IA-PC-TIENDA-V02.md`. El launcher no aplica SQL. Cambios de BD → migración nueva (SQL `NN_…` en el BE).

**Desarrollo funcional (solo BE + FE + BD `controlneg_rmx_db_v02`):** cargar [`desarrollo-lite.md`](desarrollo-lite.md).

Almacén de contexto cruzado + **root OpenSpec** del producto.

## Antes de cambiar comportamiento

1. Leer `DUAL-DOCS-CURSOR-OPENSPEC.md` (**documentación triple**: contexto + OpenSpec + QA).
2. Preferir spec vigente en `openspec/specs/` sobre chat suelto.
3. Tras cambios de feature: actualizar spec (o change+archive), `contextos-ia/` **y** la sección correspondiente de `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md`.

## OpenSpec (modo futuro first)

- Proponer: `/opsx-propose`
- Aplicar: `/opsx-apply`
- Archivar: `/opsx-archive`

CLI: `npx @fission-ai/openspec …` desde este directorio.

## Capacidades

- `confirmacion-pagos-electronicos` — QR/email/panel/Asociar/monto distinto/faltante→CxC
- `navegacion-traslados-of` — Atrás/Adelante entre patas de traslado OF
- `origenes-fondos-lista` — cebra/densidad tabla movimientos OF
- `modo-cuentas-of` — flexible solo en medios no físicos; efectivo `FISICA` siempre exige saldo
- `sandbox-entorno-pruebas` — aislamiento sandbox, reset transaccional, consulta BD SELECT-only
- `egresos-naturaleza-tipo` — tipo snapshot + naturaleza en egreso, filtros (Naturaleza primero), export CSV
- `egresos-personas` — catálogo Personas, XOR proveedor, `esDuenoPropietario`, origen Cuenta del dueño
- `notificacion-egreso-vinculo` — PAGASTE/EGRESO vs egreso POS: hold inbound, campanita, asociar o Sin Clasificar, filtro lista egresos
- `cierre-turno-indicadores` — Cierre: 4 cifras de dinero + Cartera; Compacta|Extendida; footer de las 4 en Ingresos/OF; modal Ver corte (mismos KPIs/tabla, ‹ ›)
- `corte-venta-split` — corregir cortes: Eliminar bloqueado por movimientos posteriores, Dividir (reverso + puente + re-corte), estado `dividido` fuera de circulación. **Pruebas humanas pendientes.**
- `ambientes-launcher-tienda-infinito` — dev-local / sandbox / caja-actual / tienda-infinito. Instalación prod: `CURSOR-IA-PC-TIENDA-V02.md` (el launcher no aplica SQL).
- `ajustes-configurables-sistema` — modal admin del menú de usuario: editar `configuracion_app.value` (label = `leyenda`) y refrescar el `localStorage` del login
- `teclas-acceso-rapido` — en Tickets, `Shift+1` / `Shift+2` eligen método de pago con el foco en `#productSearchInput`; mapa en `configuracion_app` (`73_`)
- `monitor-bug` — traza HAR del Monitor: `configuracion_app` `monitor-bug.secciones` recorta el JSON copiado y el panel Editar # según `trazable`
