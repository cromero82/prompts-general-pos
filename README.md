## Aplicación POS Infinito

El monorepo se entiende como **composición de varios proyectos**. Los prompts
generales para IAs viven en esta carpeta: **`prompts-general-pos/`**.

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

- PostgreSQL `controlneg_rmx_db` — lógica de tienda.
- Migraciones schema: `MIGRATE-PROD-TO-DIAN-V2.md` + `apply-migrate-prod-to-dian-v2.sh` en contextos BE.
- Reset datos de prueba: **`reset-tablas-financieras-transaccionales-v2.sql`** (no el legacy v1).

### Prompts de esta carpeta (IA)

| Archivo | Cuándo usarlo |
|---|---|
| `COMPILACION-CAMBIOS-DIAN-VS-PROD.md` | Delta prod ↔ dian (FE/BE/BD) |
| `MIGRATE-PROD-TO-DIAN-V2.md` | Migrar schema BD prod → dian-v2 (incluye `30_` multipago) |
| `MULTIPAGO-MEDIOS-POR-TICKET.md` | Diseño + estado de cobro con 2–3 medios; corte por líneas |
| `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Instructivo reset (DBeaver, base inicial) |
| `reset-tablas-financieras-transaccionales-v2.sql` | **SQL canónico** (incl. egreso, stats, aserción BASE_INICIAL) |
| `apply-reset-tablas-financieras-transaccionales.sh` | Wrapper → v2 |
| `interceptar-pagos-tunel.md` | Confirmación pagos electrónicos / túnel |
| `contextos-ia/origenes-fondos.md` | **IA:** cambios OF, plantillas email, Trasladar, reglas DnD |
| `ayuda-documental/` | **Humano / futura UI:** ayuda en línea (empieza en Orígenes de fondos) |

### Flujo típico al abrir un chat nuevo

1. Leer `pos-relational-data-service/.../AI-ONBOARDING-basic.md` + este README.
2. Finanzas/movimientos → `AI-HANDOFF-FINANZAS-2026-08.md`.
3. Si la BD no tiene OF / distribución / multipago schema → `MIGRATE-PROD-TO-DIAN-V2.md`.
4. Cobro mixto / líneas de pago → `MULTIPAGO-MEDIOS-POR-TICKET.md`.
5. Si se reinician pruebas → reset **v2** (Auto-commit ON en DBeaver) → logout + login admin.
6. BE `dian-v2` + FE alineados al schema.
7. Trabajo en OF / correos banco → `contextos-ia/origenes-fondos.md`. Ayuda de usuario → `ayuda-documental/origenes-fondos/`.