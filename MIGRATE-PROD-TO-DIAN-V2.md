# Prompt para IA — Migrar BD producción → esquema dian-v2

Úsalo cuando el usuario pida alinear una base **prod** (rama `feature/prod` /
carpeta `others-versions/pos-relational-data-service`) con la estructura
**dian-v2** (orígenes de fondos, ledger, cierres con detalle, distribución, base inicial).

## Repositorios de referencia

| Rol | Ruta / rama |
|---|---|
| Backend prod (referencia) | `others-versions/pos-relational-data-service` → `feature/prod` |
| Backend destino | `pos-relational-data-service` → **`dian-v2`** |
| Frontend destino | `infinito-ai-front` → **`dian-version`** |
| Dump referencia dian | `pos-relational-data-service/src/main/resources/backups/dump-controlneg_rmx_db-202607261840_linux_dian-v2.sql` |
| Scripts SQL | `pos-relational-data-service/src/main/resources/doc/contextos/database/` |
| Prompts generales POS | `prompts-general-pos/` (esta carpeta) |

## Objetivo

Dejar el schema PostgreSQL `controlneg_rmx_db` con:

- Tablas: `origen_fondos`, `movimiento_origen_fondos`, `tipo_origen_fondos`, `motivo_movimiento`, `corte_venta_detalle`, …
- Columnas en `corte_venta`: watermarks, `distribucion_efectivo_estado`, `base_siguiente_efectivo`, workflow
- Columnas en `egreso`: `metodo_pago_id`, `origen_fondos_id`
- Caja Menor / Caja General **sin** `metodo_pago_id`
- Motivo `INVERSION_INICIAL_BASE`

**No** es un truncate de datos de negocio (para eso: `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md`).

## Pasos obligatorios para la IA

1. **Backup** de la BD destino antes de migrar (pg_dump). No continuar sin confirmación si no hay backup.
2. Confirmar URL: `DB_URL` o default local `postgresql://…@localhost:5432/controlneg_rmx_db`.
3. Ejecutar el script maestro (idempotente en lo posible):

```bash
chmod +x pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh
bash pos-relational-data-service/src/main/resources/doc/contextos/database/apply-migrate-prod-to-dian-v2.sh "$DB_URL"
```

4. Verificar salida: tablas/columnas presentes, `INVERSION_INICIAL_BASE` = 1, Caja Menor sin MP.
5. Desplegar **backend `dian-v2`** y **frontend `dian-version`** (código + BD deben ir juntos).
6. Smoke test:
   - Login admin → modal Base inicial (si no hay cortes ni `BASE_INICIAL`)
   - OF list carga
   - Egreso exige origen de fondos
   - Cierre muestra Base / Movimientos (admin)

## Orden de scripts (detalle)

El wrapper aplica en este orden (omitir `25_repair_*`):

`00`→`05`(+backfill) → `07`→`08`→`06`→`09` → `10`→`11` → `12`→`18` (bolsillos + rename) → `19`→`26`

Ver también `database/README-SPRINTS.md` y el índice en
`COMPILACION-CAMBIOS-DIAN-VS-PROD.md`.

## Datos históricos tras migrar

| Tema | Comportamiento |
|---|---|
| Egresos viejos | Backfill `origen_fondos_id` / `metodo_pago_id` en scripts `07`/`16` |
| Cortes viejos | `20` crea `corte_venta_detalle` desde `ventas_tipo`; estado `revisada` |
| Ledger | Vacío hasta que haya movimientos nuevos / cortes con `ENTRADA_VENTA` |
| Distribución | Cortes legacy pueden quedar sin `PENDIENTE`; solo el último vigente se marca en `23` |
| Base siguiente | Null hasta primera distribución confirmada |

Migración de **saldos físicos reales** de prod al ledger (apertura) es un paso de negocio aparte: usar Base inicial o entradas manuales; no inventar saldos en el script.

## Si falla a mitad

- Revisar el último `>>> archivo.sql` en el log.
- Scripts son mayormente idempotentes; se puede re-ejecutar el wrapper.
- Si quedó en nombres intermedios (`cuenta_bolsillo` sin rename `18`), aplicar desde `18` en adelante.
- Comparar con dump dian o entidades JPA en `dian-v2` vs prod.

## Qué no hacer

- No truncar ventas/egresos de prod salvo petición explícita.
- No aplicar `25_repair_entrada_venta_corte1.sql` en prod.
- No desplegar solo FE o solo BE.
- No re-vincular Caja Menor a `metodo_pago` id 4.
