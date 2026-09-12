## Aplicación POS Infinito

El monorepo se entiende como **composición de varios proyectos**. Los prompts
generales para IAs viven en esta carpeta: **`prompts-general-pos/`**.

### Índice (esta carpeta)

| Quiero… | Abrir |
|---------|--------|
| **Índice general** | este README |
| **Instalar v02 en la PC de tienda** (junto a la caja actual) | [`MIGRATE-TIENDA-INFINITO-V02.md`](MIGRATE-TIENDA-INFINITO-V02.md) · prompt Cursor: [`CURSOR-IA-PC-TIENDA-V02.md`](CURSOR-IA-PC-TIENDA-V02.md) |
| Narrativos para IA (cómo/dónde) | [`contextos-ia/`](contextos-ia/) |
| Contratos OpenSpec | [`openspec/specs/`](openspec/specs/) |
| Perfil tester / QA de negocio | [`doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md`](doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md) |
| Arranque laptop (dev + sandbox) | [`ARRANQUE-LOCAL-Y-SANDBOX.md`](ARRANQUE-LOCAL-Y-SANDBOX.md) |
| Docs triple (contexto + spec + QA) | [`DUAL-DOCS-CURSOR-OPENSPEC.md`](DUAL-DOCS-CURSOR-OPENSPEC.md) |

### Los 5 proyectos

| Pieza | Ruta (relativa al monorepo `repos/`) | Notas |
|---|---|---|
| Lógica de tienda (backend) | `pos-relational-data-service/` | Rama **`dian-v2`** (contexto movimientos/OF). Onboarding: `…/doc/contextos/AI-ONBOARDING-basic.md`. Handoff finanzas: `AI-HANDOFF-FINANZAS-2026-08.md`. SQL: `…/doc/contextos/database/`. |
| Frontend Angular | `infinito-ai-front/` | Rama **`dian-version`**. Finanzas: `.cursor/rules/movimientos-almacen/`. Monitor HAR: handoff Monitor en contextos BE. |
| Seguridad | `infinito-security/` | `src/main/resources/info.md`, `notas.md` |
| Correos (Gmail dev) | `infinito-smtp-service/` | `src/main/resources/install/notas.md` |
| Lanzador (JavaFX) | `intinito-launcher/` | Sube/baja MS, logs, actualizar git + compilar |

**Prod (referencia sin OF completo):** `others-versions/pos-relational-data-service` @ `feature/prod`.

### Base de datos

- PostgreSQL `controlneg_rmx_db` — lógica de tienda (**caja actual**).
- PostgreSQL `controlneg_rmx_db_v02` — pila Tienda Infinito en paralelo. Runbook: **`MIGRATE-TIENDA-INFINITO-V02.md`**. SQL: `create-db-controlneg-rmx-db-v02.sql`.
- Migraciones schema (sobre la BD que indiques): `MIGRATE-PROD-TO-DIAN-V2.md` + `apply-migrate-prod-to-dian-v2.sh` en contextos BE.
- Reset datos de prueba: **`reset-tablas-financieras-transaccionales-v2.sql`** (no el legacy v1).

### Prompts de esta carpeta (IA)

| Archivo | Cuándo usarlo |
|---|---|
| `COMPILACION-CAMBIOS-DIAN-VS-PROD.md` | Delta prod ↔ dian (FE/BE/BD) |
| `MIGRATE-TIENDA-INFINITO-V02.md` | **Ops tienda:** instalar pila v02 (puertos 4220/8288, BD `_v02`) **sin apagar** la caja actual |
| `create-db-controlneg-rmx-db-v02.sql` | Crear `controlneg_rmx_db_v02` (vacía o ver comentarios TEMPLATE) |
| `MIGRATE-PROD-TO-DIAN-V2.md` | Migrar schema BD prod → dian-v2 (incluye `30_` multipago); en v02 usa esa BD, no la vieja |
| `MULTIPAGO-MEDIOS-POR-TICKET.md` | Diseño + estado de cobro con 2–3 medios; corte por líneas |
| `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Instructivo reset (DBeaver, base inicial) |
| `reset-tablas-financieras-transaccionales-v2.sql` | **SQL canónico** (incl. egreso, stats, aserción BASE_INICIAL) |
| `apply-reset-tablas-financieras-transaccionales.sh` | Wrapper → v2 |
| `ARRANQUE-LOCAL-Y-SANDBOX.md` | **Ops:** comandos para levantar local (`:4200` / `:8088` / `:8095`) y puente sandbox (`:8195`). Spec ambientes: `openspec/specs/ambientes-launcher-tienda-infinito/spec.md` |
| `interceptar-pagos-tunel.md` | Plan infra email/túnel Cloudflare (histórico + pendientes Worker) |
| `contextos-ia/confirmacion-pagos-electronicos.md` | **IA:** panel QR/email, Asociar live, monto distinto, faltante→CxC, **minimizar vs ocultar** |
| `contextos-ia/ticket-observaciones.md` | **IA:** comentario de ticket, rail Crédito/Observación, limpieza al liquidar |
| `openspec/specs/ticket-observaciones/spec.md` | **OpenSpec:** contratos observación de ticket |
| `contextos-ia/cierre-asistente-caja.md` | **IA:** asistente contar billetes en Cierre de turno |
| `openspec/specs/cierre-asistente-caja/spec.md` | **OpenSpec:** Contado = total billetes; diferencia vs Esperado |
| `DUAL-DOCS-CURSOR-OPENSPEC.md` | **Docs triple:** contexto + OpenSpec + QA (`CONTEXTO-TESTER-POS`) |
| `openspec/specs/confirmacion-pagos-electronicos/spec.md` | **OpenSpec:** contratos de comportamiento confirmación pagos |
| `contextos-ia/origenes-fondos.md` | **IA:** OF, plantillas, Trasladar, DnD, Atrás/Adelante, **cebra tabla movimientos** |
| `openspec/specs/navegacion-traslados-of/spec.md` | **OpenSpec:** navegación entre patas de traslado |
| `openspec/specs/origenes-fondos-lista/spec.md` | **OpenSpec:** cebra/densidad historial OF |
| `contextos-ia/guia-en-linea.md` | **IA:** componente genérico ayuda en línea + caso Tickets/CxC |
| `contextos-ia/sandbox-reset-transaccional.md` | **IA:** sandbox (clone BD, reset, **consulta BD SELECT**, flags) |
| `openspec/specs/sandbox-entorno-pruebas/spec.md` | **OpenSpec:** contratos sandbox (reset + consulta-bd) |
| `contextos-ia/egresos.md` | **IA:** egresos Plan 1+2 (tipo, naturaleza, Personas XOR proveedor, `esDuenoPropietario`, filtros, CSV) |
| `openspec/specs/egresos-naturaleza-tipo/spec.md` | **OpenSpec:** tipo + naturaleza + listado/export |
| `openspec/specs/egresos-personas/spec.md` | **OpenSpec:** Personas + origen Cuenta del dueño |
| `ayuda-documental/` | **Humano / UI:** ayuda en línea (OF + tickets-cxc; FE parcial) |
| `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` | **Tester / IA general:** **un solo archivo** funcional (QA). Incluye QR, **PAGASTE ↔ egreso**, CxC/comentario, asistente cierre, minimizar panel, OF Atrás/Adelante, **Ingresos = ventas sin desfase**. Sin detalle de infra. |
| `doc-ayuda-inteligente/ACTUALIZACION-QA-2026-09-12.md` | **Oleada vigente:** Ingresos = tickets (`totalVentasSistema`) **sin desfase**; gráfico asc / tabla desc |
| `doc-ayuda-inteligente/ACTUALIZACION-QA-2026-09-10.md` | Oleada anterior: campanita PAGASTE, diálogo asociar vs bolsa, Borrar filtro notificación; SQL `59` |
| `contextos-ia/ingresos-dashboard.md` | **IA:** fuente de verdad de Ingresos (ventas sin desfase) |
| `openspec/specs/ingresos-dashboard/spec.md` | **OpenSpec:** Ventas = tickets; desfase no corrige Ingresos |
| `contextos-ia/notificacion-egreso-vinculo.md` | **IA:** hold inbound EGRESO, alertas, asociar (DELETE par bolsa), filtro egresos |
| `openspec/specs/notificacion-egreso-vinculo/spec.md` | **OpenSpec:** contratos PAGASTE ↔ egreso |
| `contextos-ia/ambientes-launcher-tienda-infinito.md` | **IA:** launcher (dev/sandbox/tienda), Worker, hostname de caja |
| `openspec/specs/ambientes-launcher-tienda-infinito/spec.md` | **OpenSpec:** tres ambientes, túnel propio, health vs reloj |

### Flujo típico al abrir un chat nuevo

1. Leer `pos-relational-data-service/.../AI-ONBOARDING-basic.md` + este README.
2. Finanzas/movimientos → `AI-HANDOFF-FINANZAS-2026-08.md`.
3. Si la BD no tiene OF / distribución / multipago schema → `MIGRATE-PROD-TO-DIAN-V2.md`.
4. Cobro mixto / líneas de pago → `MULTIPAGO-MEDIOS-POR-TICKET.md`.
5. Si se reinician pruebas → reset **v2** (Auto-commit ON en DBeaver) → logout + login admin.
6. BE `dian-v2` + FE alineados al schema.
7. Trabajo en OF / correos banco → `contextos-ia/origenes-fondos.md`. Ayuda de usuario → `ayuda-documental/`.
8. Ayuda contextual overlay (CxC / genérico) → `contextos-ia/guia-en-linea.md`.
9. Acompañar a una **tester de negocio** → entregar **solo** `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` (archivo autónomo; ella lo carga en su IA, sin carpeta de MDs).
10. Instalar / convivir v02 en la PC de tienda → **`MIGRATE-TIENDA-INFINITO-V02.md`**. Narrativo: `contextos-ia/ambientes-launcher-tienda-infinito.md`.