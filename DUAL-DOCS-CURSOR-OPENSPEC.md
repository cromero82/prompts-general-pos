# Documentación triple: Cursor + OpenSpec + QA

> Archivo histórico: `DUAL-DOCS-CURSOR-OPENSPEC.md` (antes «documentación dual»).  
> Desde 2026-08-25 el estándar es **triple**.

Este repo (`prompts-general-pos/`) es el **almacén de contexto cruzado** del POS y el **root OpenSpec** del producto.

## Tres capas (siempre juntas al tocar una capacidad)

| Capa | Para qué | Dónde |
|------|----------|--------|
| **1. Contexto (narrativo Cursor)** | Cómo/dónde funciona; onboarding IA; reglas por glob | `contextos-ia/*.md`, `infinito-ai-front/.cursor/rules/**` |
| **2. OpenSpec (contratos)** | Qué *debe* cumplirse; deltas ADDED/MODIFIED/REMOVED | `openspec/specs/`, `openspec/changes/` |
| **3. QA / perfil tester** | Aceptación funcional en español de negocio; IA general | `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` |

No compiten: el narrativo explica *cómo/dónde*; OpenSpec fija *qué debe cumplirse*; el perfil QA traduce eso a *cómo probar / qué reportar*.

## Flujo actual (híbrido)

1. Implementas o documentas con Cursor (como hasta ahora).
2. Alimentas **las tres capas**:
   - Comportamiento vigente → `openspec/specs/<capacidad>/spec.md`
   - Narrativo → `contextos-ia/<tema>.md`
   - Criterios de prueba → sección correspondiente en `CONTEXTO-TESTER-POS.md`
   - Trabajo nuevo → `/opsx-propose` → artifacts → código → `/opsx-archive`
3. Si aplica, actualizas la rule FE en `.cursor/rules/`.

## Flujo futuro (OpenSpec first)

1. `/opsx-propose "…"` en este workspace (o con root `prompts-general-pos`).
2. Revisas proposal / design / delta specs / tasks.
3. `/opsx-apply` (Cursor ejecuta debajo).
4. `/opsx-archive` mergea deltas a `specs/`.
5. Refrescas narrativo + § tester; la rule Cursor se regenera o se acorta a “leer openspec/specs/…”.

## Capacidades OpenSpec hoy

| Capacidad | Spec | Narrativo Cursor | Vista funcional (tester) |
|-----------|------|------------------|--------------------------|
| `confirmacion-pagos-electronicos` | `openspec/specs/confirmacion-pagos-electronicos/spec.md` | `contextos-ia/confirmacion-pagos-electronicos.md` | `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` §4.12 / §10.5 |
| `metodos-pago-notificacion` | `openspec/specs/metodos-pago-notificacion/spec.md` | `contextos-ia/metodos-pago-notificacion.md` | `CONTEXTO-TESTER-POS.md` §4.12 / §4.14 / §10.5 |
| `navegacion-traslados-of` | `openspec/specs/navegacion-traslados-of/spec.md` | `contextos-ia/origenes-fondos.md` | `CONTEXTO-TESTER-POS.md` §4.11 |
| `origenes-fondos-lista` | `openspec/specs/origenes-fondos-lista/spec.md` | `contextos-ia/origenes-fondos.md` | `CONTEXTO-TESTER-POS.md` §4.11 (cebra, orden id DESC) |
| `sandbox-entorno-pruebas` | `openspec/specs/sandbox-entorno-pruebas/spec.md` | `contextos-ia/sandbox-reset-transaccional.md` | `CONTEXTO-TESTER-POS.md` § ambientes (reset); consulta BD = API/IA |
| `egresos-naturaleza-tipo` | `openspec/specs/egresos-naturaleza-tipo/spec.md` | `contextos-ia/egresos.md` | `CONTEXTO-TESTER-POS.md` §4.10 |
| `egresos-personas` | `openspec/specs/egresos-personas/spec.md` | `contextos-ia/egresos.md` | `CONTEXTO-TESTER-POS.md` §4.10 |
| `historial-tickets` | `openspec/specs/historial-tickets/spec.md` | `contextos-ia/historial-tickets.md` | `CONTEXTO-TESTER-POS.md` §4.6 / §4.11 / §10.9 |
| `producto-presentaciones-uom` | `openspec/specs/producto-presentaciones-uom/spec.md` | `contextos-ia/producto-presentaciones.md` | `CONTEXTO-TESTER-POS.md` §4.2 (menudeo) |
| `cxc-abono-pagador` | `openspec/specs/cxc-abono-pagador/spec.md` | `contextos-ia/cxc-abono-pagador.md` | `CONTEXTO-TESTER-POS.md` §4.5 / §10.3 |
| `ticket-observaciones` | `openspec/specs/ticket-observaciones/spec.md` | `contextos-ia/ticket-observaciones.md` | `CONTEXTO-TESTER-POS.md` §4.5 / §10.3 |
| `cierre-asistente-caja` | `openspec/specs/cierre-asistente-caja/spec.md` | `contextos-ia/cierre-asistente-caja.md` | `CONTEXTO-TESTER-POS.md` §4.9 / §10.1 / §10.6 |
| `cierre-turno-indicadores` | `openspec/specs/cierre-turno-indicadores/spec.md` | `contextos-ia/cierre-turno-indicadores.md` | `CONTEXTO-TESTER-POS.md` §4.9 / §4.11 |
| `ingresos-dashboard` | `openspec/specs/ingresos-dashboard/spec.md` | `contextos-ia/ingresos-dashboard.md` | `CONTEXTO-TESTER-POS.md` §2.4 / §4.9 / §10.1; oleada `ACTUALIZACION-QA-2026-09-12.md` |
| `corte-venta-split` (**pruebas humanas pendientes**) | `openspec/specs/corte-venta-split/spec.md` | `contextos-ia/corte-venta-split.md` | `CONTEXTO-TESTER-POS.md` §4.9 / §10.1 |
| `notificacion-egreso-vinculo` | `openspec/specs/notificacion-egreso-vinculo/spec.md` | `contextos-ia/notificacion-egreso-vinculo.md` | `CONTEXTO-TESTER-POS.md` §4.15 / §10.10 |
| `ambientes-launcher-tienda-infinito` | `openspec/specs/ambientes-launcher-tienda-infinito/spec.md` | `contextos-ia/ambientes-launcher-tienda-infinito.md` | `CONTEXTO-TESTER-POS.md` § ambientes (URL de caja; sin infra) |
| `lectora-codigo-barras` (**aparcado**) | `openspec/specs/lectora-codigo-barras/spec.md` | `contextos-ia/lectora-codigo-barras.md` | `CONTEXTO-TESTER-POS.md` §4.2 / §10.11 |
| `ajustes-configurables-sistema` | `openspec/specs/ajustes-configurables-sistema/spec.md` | `contextos-ia/ajustes-configurables-sistema.md` | `CONTEXTO-TESTER-POS.md` §4.16 / §10.12 |
| `teclas-acceso-rapido` | `openspec/specs/teclas-acceso-rapido/spec.md` | pendiente | pendiente |

Oleada QA vigente (pair testing): `doc-ayuda-inteligente/ACTUALIZACION-QA-2026-09-12.md` (Ingresos = ventas sin desfase). Siguen vigentes: `2026-09-10` (PAGASTE ↔ egreso), `2026-09-06` (comentario + asistente + minimizar), `2026-09-03` (Historial), `2026-09-02` (medios+plantillas+Asociar). Anterior: `ACTUALIZACION-QA-2026-08-30.md` (presentaciones UI + CxC pagador + panel QR).

Para una **IA de propósito general / QA de negocio**, entregar **`CONTEXTO-TESTER-POS.md`** + la **oleada** del ciclo.  
Para **IA de entorno sandbox / verificación de datos**, cargar también `contextos-ia/sandbox-reset-transaccional.md`.

## Comandos útiles

```bash
cd prompts-general-pos
npx @fission-ai/openspec list --specs
npx @fission-ai/openspec validate
npx @fission-ai/openspec show confirmacion-pagos-electronicos
```

En Cursor (con este folder abierto o multi-root): `/opsx-propose`, `/opsx-apply`, `/opsx-archive`, `/opsx-explore`.

## Regla al tocar confirmación QR / panel / Asociar / monto distinto

1. Spec: `openspec/specs/confirmacion-pagos-electronicos/spec.md` (o change + archive).
2. Narrativo: `contextos-ia/confirmacion-pagos-electronicos.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.12 / §10.5.
4. Si el cambio es de UX/código FE: rule `infinito-ai-front/.cursor/rules/confirmacion-pagos-electronicos.mdc` + estilos tema panel (`azul-atras`: tipografía, layout botones, leyenda tiempo completa). Minimizar (dock footer) ≠ `notificaciones.activa=false` (SQL `55_`).

## Regla al tocar métodos de pago / plantillas de extracción / Dominios link

1. Spec: `openspec/specs/metodos-pago-notificacion/spec.md`.
2. Narrativo: `contextos-ia/metodos-pago-notificacion.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.12 / §4.14 / §10.5 + oleada del ciclo.
4. Rules FE: `metodos-pago-notificacion.mdc`, y si toca panel/Asociar también `confirmacion-pagos-electronicos.mdc`.
5. SQL: `53_metodo_pago_permite_notificacion.sql`, `54_plantilla_naturaleza_ingreso.sql`.

## Regla al tocar Orígenes de fondos (lista / traslados / tabla)

1. Narrativo: `contextos-ia/origenes-fondos.md`.
2. Specs según el tema:
   - navegación Atrás/Adelante → `openspec/specs/navegacion-traslados-of/spec.md`
   - cebra / densidad / orden id DESC del historial → `openspec/specs/origenes-fondos-lista/spec.md`
3. Tester: `CONTEXTO-TESTER-POS.md` §4.11.
4. Código FE principal: `infinito-ai-front/.../origenes-fondos/origenes-list/`.

## Regla al tocar sandbox (reset / consulta BD / flags)

1. Narrativo: `contextos-ia/sandbox-reset-transaccional.md`.
2. Spec: `openspec/specs/sandbox-entorno-pruebas/spec.md`.
3. Tester: § ambientes en `CONTEXTO-TESTER-POS.md`.
4. Código BE: `pos-relational-data-service` (+ mirror `sandbox/…`) — `SandboxAdminController`, servicios reset/consulta.
5. Si el cambio es UX de reset: FE sandbox `environment.sandbox` + menú admin.

## Regla al tocar presentaciones / menudeo / UoM de producto

1. Narrativo: `contextos-ia/producto-presentaciones.md`.
2. Spec: `openspec/specs/producto-presentaciones-uom/spec.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.2 (menudeo).
4. SQL: `50_producto_presentacion.sql`, `51_producto_presentacion_migracion_final.sql`.
5. FE: `detalle-ticket` (merge/`presentacionId`, toggle, `(Por unidad)`, agrupación); `selector-productos` (dual precio, inactivos); BE: `ProductoPresentacion*`, `ReciboDetalle`.

## Regla al tocar CxC / abono / quién abona

1. Narrativo: `contextos-ia/cxc-abono-pagador.md` (+ ayuda `ayuda-documental/tickets-cxc/`).
2. Spec: `openspec/specs/cxc-abono-pagador/spec.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.5 / §10.3.
4. SQL: `52_abono_cxc_cliente_pagador.sql` (además del esquema CxC 37/41–44).
5. FE: `registrar-abono-cxc-dialog`, `cxc-ticket-rail`; BE: `CuentaPorCobrarServiceImpl` / `AbonoCxc`.

## Regla al tocar comentario / observación de ticket

1. Narrativo: `contextos-ia/ticket-observaciones.md`.
2. Spec: `openspec/specs/ticket-observaciones/spec.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.5 / §10.3 + oleada `ACTUALIZACION-QA-2026-09-06.md`.
4. SQL: `56_ticket_observaciones.sql`.
5. FE: `ticket-observacion-dialog`, `cxc-ticket-rail`, menú tab en `tickets.component`; BE: `PUT /tickets/{id}/observaciones`, limpieza al liquidar CxC / `crearReciboYEnlace`.
6. Rule FE: `infinito-ai-front/.cursor/rules/ticket-observaciones.mdc`.

## Regla al tocar el Asistente contar billetes (antes «asistente de cierre de caja»)

1. Narrativo: `contextos-ia/cierre-asistente-caja.md`.
2. Spec: `openspec/specs/cierre-asistente-caja/spec.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.9 / §10.1 / §10.6 + oleada `ACTUALIZACION-QA-2026-09-06.md`.
4. Sin SQL de schema. FE: `asistente-cierre-caja-dialog` desde `cierre-ventas`.
5. No mezclar con fecha-sistema / simular día (`AI-HANDOFF-SANDBOX-SIMULAR-DIA-2026-09.md`).

## Regla al tocar Historial Tickets / modal sin corte OF

1. Narrativo: `contextos-ia/historial-tickets.md`.
2. Spec: `openspec/specs/historial-tickets/spec.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.6 / §4.11 / §10.9 (+ oleada `ACTUALIZACION-QA-2026-09-03.md`).
4. FE: `historial-ventas/`, `tickets-sin-corte-dialog/`, `ticket-productos-dialog/`.
5. BE: `HistorialReciboServiceImpl` (search + enrich multipago / HRE).

## Regla al tocar PAGASTE / vínculo notificación ↔ egreso

1. Spec: `openspec/specs/notificacion-egreso-vinculo/spec.md`.
2. Narrativo: `contextos-ia/notificacion-egreso-vinculo.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.15 / §10.10 + oleada `ACTUALIZACION-QA-2026-09-10.md`.
4. SQL: `59_notificacion_vinculo_operacion.sql`.
5. FE: `toolbar-alerta-egreso`, `alerta-egreso-sin-vincular-dialog`, `egreso-list` (filtro + Borrar filtro), `origenes-list` (icono Sin Clasificar), `asociar-notificacion-egreso-dialog`.
6. BE: `puente-tienda` `MovimientoDesdeNotificacionService` / `GestionNotificacionService` (hold inbound, alertas, DELETE par POR IDENTIFICAR). Reiniciar :8095 si cambia el jar.
7. No mezclar con el panel de cobros QR (`confirmacion-pagos-electronicos`).

## Regla al tocar launcher / ambientes / hostname de tienda / Worker inbound

1. Spec: `openspec/specs/ambientes-launcher-tienda-infinito/spec.md`.
2. Narrativo: `contextos-ia/ambientes-launcher-tienda-infinito.md`.
3. Change abierto (piloto): `openspec/changes/2026-09-11-ambientes-launcher-tienda-infinito/`.
4. Ops: `MIGRATE-TIENDA-INFINITO-V02.md` (PC tienda) y `ARRANQUE-LOCAL-Y-SANDBOX.md` (laptop). Tester: § ambientes (no detallar túnel).
5. Código: `intinito-launcher`, `puente-tienda/workers/email-inbound`, `infinito-ai-front/server.js`.
6. MUST NOT enrutar `pagos@` a la caja ni arrancar el túnel `tienda-infinito` en la laptop de desarrollo.

## Regla al tocar corrección de cortes (Eliminar bloqueado / Dividir / estado `dividido`)

1. Spec: `openspec/specs/corte-venta-split/spec.md`.
2. Narrativo: `contextos-ia/corte-venta-split.md` (+ detalle técnico e incidente en `ayuda-documental/corte-venta-split/`).
3. Tester: `CONTEXTO-TESTER-POS.md` §4.9 / §10.1.
4. Change abierto (pruebas humanas): `openspec/changes/2026-09-24-corte-venta-split/`.
5. SQL: `68_corte_venta_split.sql` (aditiva). MUST NOT tocar las queries de saldo (`sumImpactoByCuentaId*`) ni añadir columnas de supersede.
6. BE: `CorteVentaServiceImpl.dividirCorte` / `delete`, `MovimientoOrigenFondosServiceImpl.validarCorteEliminable` / `revertirParaSplit` / `cerrarPuenteSplit`.
7. FE: `ingresos.component.*`, `dividir-corte-dialog/`, `corte-venta.service.ts`.
8. Al agregar un estado no vigente, actualizar `ESTADOS_NO_VIGENTES` en BE **y** FE: si se cuela en Ingresos o en «último corte vigente», se duplican ventas o se corrompen los watermarks.
9. Si cambia el schema de corrección, sincronizar el reset transaccional (`reset-tablas-financieras-transaccionales-v3.sql`).

## Regla al tocar egresos (tipo / naturaleza / personas / Cuenta del dueño)

1. Narrativo: `contextos-ia/egresos.md` (+ enlace OF en `origenes-fondos.md` si clasificar vs pagar).
2. Specs:
   - tipo + naturaleza + listado/export → `openspec/specs/egresos-naturaleza-tipo/spec.md`
   - Personas + `esDuenoPropietario` + origen Cuenta del dueño → `openspec/specs/egresos-personas/spec.md`
3. Tester: `CONTEXTO-TESTER-POS.md` §4.10.
4. FE: `infinito-ai-front/.../financiero/egresos/` + Dominios Personas.
5. BE: `Egreso` / `Persona` / `EgresoServiceImpl` / ledger; SQL `46_`…`49_`.
6. Recordar: Cuenta del dueño = clasificación OF (`visible_en_egreso=false`); bajar saldo = egreso PERSONAL/DIVIDENDOS con persona **dueño/propietario** (no naturaleza «retiro»).

## Regla al tocar ajustes configurables del sistema

1. Spec: `openspec/specs/ajustes-configurables-sistema/spec.md`.
2. Narrativo: `contextos-ia/ajustes-configurables-sistema.md`.
3. Tester: `CONTEXTO-TESTER-POS.md` §4.16 / §10.12.
4. FE: menú `toolbar-user-dropdown` + modal `ajustes-configurables/`. Sync `localStorage` = `ConfigurationService.obtenerTodasConfiguraciones()`.
5. BE: `ConfiguracionApp.leyenda` en `GET /configuracion-app/obtenerTodos`. Guardar solo `value` con `PUT /configuracion-app/key/{key}`.
6. No editar la columna `key` ni `leyenda` desde el modal. Si `leyenda` está vacía, el label es la `key`.

## Regla al tocar atajos de teclado en Tickets

1. Spec: `openspec/specs/teclas-acceso-rapido/spec.md`.
2. Change abierto: `openspec/changes/2026-09-27-teclas-acceso-rapido/`.
3. FE: `acceso-teclado.ts`, `acceso-teclado.service.ts`, botón en `metodos-pago`, `#productSearchInput`.
4. BD: `73_teclas_acceso_rapido.sql`. No usar `70_` para esta clave.
5. Narrativo y tester: pendientes.
