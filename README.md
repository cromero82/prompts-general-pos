## Aplicación POS Infinito

**Este repo (`prompts-general-pos/`) es el contexto general de la app y de la instalación en producción.** Vive en el **mismo path** que los demás proyectos (`…/repos/prompts-general-pos` al lado de `infinito-ai-front`, `pos-relational-data-service`, `intinito-launcher`, …).

No es el código que corre. Es el almacén para IAs y para el humano que instala:

| Quién | Qué vive aquí | Qué no |
|-------|----------------|--------|
| Chat en la **laptop de producción** (tienda) | Cómo instalar y arrancar Tienda Infinito | Compilar JARs (eso es cada repo) |
| Chat de producto | OpenSpec, narrativos, QA tester | SQL de schema (eso es el BE `…/database/`) |
| Infinito Launcher | Solo se **nombra**: es el panel Iniciar/Detener | No guarda el runbook de prod |

En la PC de tienda, abre Cursor con `prompts-general-pos` (multi-root con los otros repos) y carga **[`CURSOR-IA-PC-TIENDA-V02.md`](CURSOR-IA-PC-TIENDA-V02.md)**. El launcher no aplica scripts: los cambios de BD se aplican como migraciones (SQL `NN_…` en el BE).

### Índice (esta carpeta)

| Quiero… | Abrir |
|---------|--------|
| **Índice general** | este README |
| **Desarrollo lite (solo BE + FE + BD actual)** | [`desarrollo-lite.md`](desarrollo-lite.md) |
| **Instalar Tienda Infinito en la PC de prod** | [`CURSOR-IA-PC-TIENDA-V02.md`](CURSOR-IA-PC-TIENDA-V02.md) |
| Narrativos para IA (cómo/dónde) | [`contextos-ia/`](contextos-ia/) |
| Contratos OpenSpec | [`openspec/specs/`](openspec/specs/) |
| Perfil tester / QA de negocio | [`doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md`](doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md) |
| Arranque laptop (dev + sandbox) | [`ARRANQUE-LOCAL-Y-SANDBOX.md`](ARRANQUE-LOCAL-Y-SANDBOX.md) |
| Docs triple (contexto + spec + QA) | [`DUAL-DOCS-CURSOR-OPENSPEC.md`](DUAL-DOCS-CURSOR-OPENSPEC.md) |

### Proyectos hermanos (`…/repos/`)

| Pieza | Carpeta | Rol |
|---|---|---|
| **Contexto general + instalación prod** | `prompts-general-pos/` | **Este repo.** OpenSpec, narrativos, QA, runbook de tienda. |
| Lógica de tienda (backend) | `pos-relational-data-service/` | Código + SQL (`…/doc/contextos/database/`). Onboarding de dominio: `AI-ONBOARDING-basic.md`. |
| Frontend Angular | `infinito-ai-front/` | UI POS. Rules en `.cursor/rules/`. |
| Seguridad | `infinito-security/` | Auth `:8081` / `:8281`. |
| Correos (SMTP) | `infinito-smtp-service/` | Gmail dev / SMTP de pila. |
| Puente (inbound banco) | `puente-tienda/` | `POST /api/email-inbound`. |
| Lanzador (JavaFX) | `intinito-launcher/` | Panel Iniciar/Detener. **No** es el contexto de instalación. |

### Base de datos

- PostgreSQL `controlneg_rmx_db` — lógica de tienda (**caja actual**).
- PostgreSQL `controlneg_rmx_db_v02` — pila Tienda Infinito en paralelo. SQL: `create-db-controlneg-rmx-db-v02.sql`.
- Cambios de BD → **migración nueva** (SQL `NN_…` en `pos-relational-data-service/…/doc/contextos/database/`).
- Reset datos de prueba: **`reset-tablas-financieras-transaccionales-v2.sql`** (no el legacy v1).

### Prompts de esta carpeta (IA)

| Archivo | Cuándo usarlo |
|---|---|
| `create-db-controlneg-rmx-db-v02.sql` | Crear `controlneg_rmx_db_v02` (vacía o ver comentarios TEMPLATE) |
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
| `contextos-ia/lectora-codigo-barras.md` | **IA (aparcado):** lectora HID, pitido sin texto, idle 400 ms |
| `openspec/specs/lectora-codigo-barras/spec.md` | **OpenSpec (aparcado):** un escaneo = una búsqueda; retomar en caja |

### Flujo típico al abrir un chat nuevo

1. Leer `pos-relational-data-service/.../AI-ONBOARDING-basic.md` + este README.
2. Finanzas/movimientos → `AI-HANDOFF-FINANZAS-2026-08.md`.
3. BD de trabajo → cambios nuevos = migración nueva (SQL `NN_…` en el BE).
4. Cobro mixto / líneas de pago → `MULTIPAGO-MEDIOS-POR-TICKET.md`.
5. Si se reinician pruebas → reset **v2** (Auto-commit ON en DBeaver) → logout + login admin.
6. BE + FE alineados al schema.
7. Trabajo en OF / correos banco → `contextos-ia/origenes-fondos.md`. Ayuda de usuario → `ayuda-documental/`.
8. Ayuda contextual overlay (CxC / genérico) → `contextos-ia/guia-en-linea.md`.
9. Acompañar a una **tester de negocio** → entregar **solo** `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` (archivo autónomo; ella lo carga en su IA, sin carpeta de MDs).
10. Instalar / convivir v02 en la PC de tienda → **`CURSOR-IA-PC-TIENDA-V02.md`**. Narrativo: `contextos-ia/ambientes-launcher-tienda-infinito.md`.