# Reset tablas financieras transaccionales (POS)

Instrucciones para cualquier IA: vaciar datos operativos de prueba **sin** tocar catálogos ni configuración del establecimiento.

## Contexto

- Base de datos: PostgreSQL `controlneg_rmx_db` (servicio `pos-relational-data-service`, puerto típico `:8088`).
- Objetivo: dejar el sistema como “instalación limpia” para re-probar:
  - Base inicial / inversión de caja
  - Tickets / ventas
  - Egresos
  - Orígenes de fondos (ledger)
  - Cortes y distribución de efectivo
- **Conservar:** `origen_fondos`, `metodo_pago`, `motivo_movimiento`, `tipo_*`, usuarios, establecimiento, proveedores (catálogo), productos, etc.

## Qué NO truncar (catálogos / maestros)

| Tabla | Motivo |
|---|---|
| `origen_fondos` | Árbol de cajas / bolsillos |
| `metodo_pago` | Medios de pago POS |
| `motivo_movimiento` | Motivos de ajuste / base turno |
| `tipo_bolsillo`, `tipo_egreso`, … | Catálogos |
| `establecimiento`, usuarios/roles | Configuración |
| `producto`, inventario maestro | Stock de catálogo (sí se vacía kardex/movimientos) |

## Qué sí vaciar (transaccional)

Cortes, ledger OF, egresos, tickets/recibos/historial, documentos de venta, consecutivos, movimientos/kardex de inventario ligados a ventas.

Script SQL canónico (mismo contenido que `reset-tablas-financieras-transaccionales.sql` en esta carpeta):

```sql
BEGIN;

TRUNCATE TABLE
  corte_venta_detalle,
  ventas_tipo,
  corte_venta,
  movimiento_origen_fondos,
  movimiento_inventario_detalle,
  movimiento_inventario,
  inventario_kardex,
  nota_ajuste_detalle,
  nota_ajuste_documento,
  edicion_recibo_detalle,
  edicion_recibo,
  entrada_inventario_detalle,
  entrada_inventario,
  egreso,
  ticket_recibo,
  historial_recibo_detalle,
  recibo_detalle_historico,
  recibo_detalle,
  documento_venta,
  historial_recibo,
  recibo,
  ticket,
  consecutivo_documento
RESTART IDENTITY CASCADE;

COMMIT;
```

**Nota:** `CASCADE` puede vaciar tablas hijas (p. ej. `historial_precio_producto`). Es esperado en reset de prueba.

## Cómo ejecutarlo

### Opción A — script de esta carpeta

```bash
# Desde el repo (ajusta la URL si el entorno difiere)
DB_URL="${DB_URL:-postgresql://romax-admin:f4ast3rv3rs10n*@localhost:5432/controlneg_rmx_db}"
psql "$DB_URL" -v ON_ERROR_STOP=1 -f /home/carlosr/Documentos/dev/repos/prompts-general-pos/reset-tablas-financieras-transaccionales.sql
```

O el wrapper:

```bash
bash /home/carlosr/Documentos/dev/repos/prompts-general-pos/apply-reset-tablas-financieras-transaccionales.sh
```

### Opción B — pedirle a la IA

Frase típica del usuario:

> Resetea las tablas de movimientos, ventas, egresos, etc. Deja los catálogos.

La IA debe:

1. Ejecutar el `TRUNCATE` anterior (o el `.sql` de esta carpeta) con `ON_ERROR_STOP=1`.
2. Verificar conteos ≈ 0 en tablas transaccionales y > 0 en catálogos.
3. **No** borrar `origen_fondos` / `metodo_pago` / `motivo_movimiento`.
4. No hacer `DROP`, ni tocar `git config`, ni subir cambios a remoto salvo que el usuario lo pida.
5. Avisar que conviene cerrar sesión / reiniciar el backend solo si hay estado en memoria (normalmente no hace falta).

## Verificación mínima

```sql
SELECT 'corte_venta' AS tabla, COUNT(*)::bigint AS n FROM corte_venta
UNION ALL SELECT 'movimiento_origen_fondos', COUNT(*) FROM movimiento_origen_fondos
UNION ALL SELECT 'historial_recibo', COUNT(*) FROM historial_recibo
UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
UNION ALL SELECT 'ticket', COUNT(*) FROM ticket
UNION ALL SELECT 'documento_venta', COUNT(*) FROM documento_venta
UNION ALL SELECT 'origen_fondos', COUNT(*) FROM origen_fondos
UNION ALL SELECT 'motivo_movimiento', COUNT(*) FROM motivo_movimiento
UNION ALL SELECT 'metodo_pago', COUNT(*) FROM metodo_pago
ORDER BY 1;
```

Esperado tras reset: transaccionales en **0**; catálogos con filas (p. ej. ~5 orígenes, ~16 motivos, ~4 métodos).

## Después del reset (flujo de prueba típico)

1. Login **admin** → modal **Entrada manual** (inversión inicial / base de caja) si no hay `BASE_INICIAL` ni cortes.
2. Ventas (tickets) por medio de pago.
3. Egresos desde orígenes (Caja: Efectivo, Caja Menor, …).
4. Orígenes de fondos: ledger + “tickets sin corte”.
5. Cierre de ventas → Distribución de efectivo (saldo = total físico de caja tras `ENTRADA_VENTA` del corte).
6. Logout / siguiente turno.

## Ubicación de artefactos

| Archivo | Uso |
|---|---|
| `prompts-general-pos/RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Este instructivo |
| `prompts-general-pos/reset-tablas-financieras-transaccionales.sql` | SQL idempotente de truncate |
| `prompts-general-pos/apply-reset-tablas-financieras-transaccionales.sh` | Wrapper `psql` |
| Ver también migración schema: `MIGRATE-PROD-TO-DIAN-V2.md` y `COMPILACION-CAMBIOS-DIAN-VS-PROD.md` |
