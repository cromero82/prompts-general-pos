## Aplicación POS Infinito

El monorepo se entiende como **composición de varios proyectos**. Los prompts
generales para IAs viven en esta carpeta: **`prompts-general-pos/`**.

### Los 5 proyectos

| Pieza | Ruta (relativa al monorepo `repos/`) | Notas |
|---|---|---|
| Lógica de tienda (backend) | `pos-relational-data-service/` | Rama trabajo: **`dian-v2`**. Onboarding: `src/main/resources/doc/contextos/AI-ONBOARDING-basic.md`. SQL: `src/main/resources/doc/contextos/database/`. Backup dian: `src/main/resources/backups/dump-controlneg_rmx_db-202607261840_linux_dian-v2.sql`. |
| Frontend Angular | `infinito-ai-front/` | Rama trabajo: **`dian-version`**. Reglas: `.cursor/rules/pos-app-map.mdc`, `pos-component-inventory.mdc`. Finanzas: `.cursor/rules/movimientos-almacen/`. |
| Seguridad | `infinito-security/` | `src/main/resources/info.md`, `notas.md` |
| Correos (Gmail dev) | `infinito-smtp-service/` | `src/main/resources/install/notas.md` |
| Lanzador (JavaFX) | `intinito-launcher/` | Sube/baja MS, logs, actualizar git + compilar |

**Prod (referencia sin OF completo):** `others-versions/pos-relational-data-service` @ `feature/prod`.

**Others:** ignorar (pruebas / otros proyectos).

### Base de datos

- PostgreSQL `controlneg_rmx_db` — lógica de tienda.
- Logs FluxBD: documentación en otras ramas; hoy muchos logs siguen en tablas PG.

### Prompts de esta carpeta (IA)

| Archivo | Cuándo usarlo |
|---|---|
| `COMPILACION-CAMBIOS-DIAN-VS-PROD.md` | Entender delta prod ↔ dian (FE/BE/BD) |
| `MIGRATE-PROD-TO-DIAN-V2.md` | Migrar schema BD prod → dian-v2 |
| `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Vaciar ventas/movimientos/egresos de prueba |
| `apply-reset-tablas-financieras-transaccionales.sh` | Ejecutar ese reset |
| `conceptos.txt` / `prompts-ajustes-egresos-ymov.sql` | Notas/SQL auxiliares previos |

### Flujo típico al abrir un chat nuevo

1. Leer este README.
2. Si la BD destino no tiene `origen_fondos` / distribución → `MIGRATE-PROD-TO-DIAN-V2.md`.
3. Si se reinician pruebas → reset transaccional.
4. Backend `dian-v2` + frontend `dian-version` deben coincidir con el schema.
