# Reset tablas financieras transaccionales (POS)

Instrucciones para cualquier IA: vaciar datos operativos de prueba **sin** tocar catálogos ni configuración del establecimiento.

## Contexto

- Base de datos: PostgreSQL `controlneg_rmx_db` (servicio `pos-relational-data-service`, puerto típico `:8088`).
- Objetivo: dejar el sistema como “instalación limpia” para re-probar base inicial, tickets, egresos, OF, cortes, multipago, notificaciones email, CxC.
- **Conservar:** `origen_fondos`, `metodo_pago`, `motivo_movimiento`, `tipo_*`, `plantilla_notificacion_pago`, usuarios, establecimiento, proveedores, productos, `client`, etc.

## Qué NO truncar (catálogos / maestros)

| Tabla | Motivo |
|---|---|
| `origen_fondos` | Árbol de cajas / bolsillos |
| `metodo_pago` | Medios de pago POS |
| `motivo_movimiento` | Motivos de ajuste / base turno / legalizar |
| `plantilla_notificacion_pago` | Plantillas extracción email |
| `tipo_*`, `estado_recibos` | Catálogos |
| `establecimiento`, usuarios/roles, `funcionalidad_*` | Configuración |
| `producto`, `client`, `proveedor` | Maestros |
| `sesion`, `app_log`, `bitacora_usuario` | Operativo/auditoría (no requerido para re-probar finanzas) |

## Qué sí vaciar (transaccional)

Cortes, ledger OF, egresos, tickets/recibos/historial + **`historial_recibo_pago`**, documentos VTA, consecutivos, kardex/movimientos inventario, estadistica_fin, flujo_dinero, **notificaciones email**, **CxC/abonos**, cargues e historial precio.

> Un reset parcial (solo MOF + corte) **no** basta.

## Script canónico (v3 — actual)

Archivo: [`reset-tablas-financieras-transaccionales-v3.sql`](./reset-tablas-financieras-transaccionales-v3.sql)

Incluye v2 + CxC, notificaciones, multipago, cargues.

**Usar v3.** v2 / v1 quedan como históricos.

### Ejecutar (psql)

```bash
DB_URL="${DB_URL:-postgresql://romax-admin:f4ast3rv3rs10n*@localhost:5432/controlneg_rmx_db}"
psql "$DB_URL" -v ON_ERROR_STOP=1 \
  -f /Users/carlosromero/Documents/dev/repos/prompts-general-pos/reset-tablas-financieras-transaccionales-v3.sql

# o:
bash /Users/carlosromero/Documents/dev/repos/prompts-general-pos/apply-reset-tablas-financieras-transaccionales.sh
```

### DBeaver

1. Auto-commit = ON  
2. Abrir `reset-tablas-financieras-transaccionales-v3.sql`  
3. Alt+X (script completo)  
4. Logout + login ADMIN → modal base inicial  

### Pedirle a la IA

> Resetea las tablas de movimientos, ventas, egresos, etc. Deja los catálogos.

La IA debe ejecutar **v3** con `ON_ERROR_STOP=1`, verificar conteos 0 en transaccionales y >0 en catálogos, y avisar logout+login admin.

## Verificación mínima

```sql
SELECT 'corte_venta' AS tabla, COUNT(*)::bigint AS n FROM corte_venta
UNION ALL SELECT 'movimiento_origen_fondos', COUNT(*) FROM movimiento_origen_fondos
UNION ALL SELECT 'historial_recibo', COUNT(*) FROM historial_recibo
UNION ALL SELECT 'historial_recibo_pago', COUNT(*) FROM historial_recibo_pago
UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
UNION ALL SELECT 'notificacion_email_pago', COUNT(*) FROM notificacion_email_pago
UNION ALL SELECT 'cuenta_por_cobrar', COUNT(*) FROM cuenta_por_cobrar
UNION ALL SELECT 'origen_fondos', COUNT(*) FROM origen_fondos
UNION ALL SELECT 'metodo_pago', COUNT(*) FROM metodo_pago
ORDER BY 1;
```

Esperado: transaccionales en **0**; catálogos con filas.

## Después del reset

1. Logout completo + login **admin** → modal Entrada manual / base inicial.  
2. Re-probar ventas, egresos, OF, cierre.

## Artefactos

| Archivo | Uso |
|---|---|
| `RESET-TABLAS-FINANCIERAS-TRANSACCIONALES.md` | Este instructivo |
| `reset-tablas-financieras-transaccionales-v3.sql` | **SQL canónico actual** |
| `reset-tablas-financieras-transaccionales-v2.sql` | Histórico |
| `reset-tablas-financieras-transaccionales.sql` | Legacy v1 |
| `apply-reset-tablas-financieras-transaccionales.sh` | Wrapper → v3 |
