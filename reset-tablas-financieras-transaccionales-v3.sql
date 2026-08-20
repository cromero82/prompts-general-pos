-- =============================================================================
-- Reset tablas transaccionales (POS) — v3
-- =============================================================================
-- BD: controlneg_rmx_db
-- Vacía ventas, cortes, ledger OF, egresos, inventario mov., CxC, notificaciones
-- de pago, etc. CONSERVA catálogos / paramétricas / maestros.
--
-- Conserva (NO truncar):
--   origen_fondos, metodo_pago, motivo_movimiento, motivo_operacion,
--   tipo_*, plantilla_notificacion_pago, establecimiento, producto,
--   client, proveedor, company, funcionalidad_*, estado_recibos,
--   configuracion_app, sesion, app_log, bitacora_usuario, security.*
--
-- DBeaver:
--   1) Auto-commit = ON (Preferences → SQL Editor → SQL Execution).
--   2) Ejecutar como SCRIPT completo: Alt+X.
--   3) Tras OK: logout + login ADMIN → modal "Entrada manual" / base inicial.
-- =============================================================================

SET lock_timeout = '5s';
SET client_min_messages = NOTICE;

DO $$
DECLARE
  candidatas text[] := ARRAY[
    -- CxC / abonos (schema 37_)
    'abono_cxc',
    'cuenta_por_cobrar',
    -- Cortes / arqueo
    'corte_venta_detalle',
    'ventas_tipo',
    'corte_venta',
    -- Ledger OF + egresos
    'movimiento_origen_fondos',
    'movimiento_bolsillo',
    'egreso',
    -- Inventario transaccional
    'entrada_inventario_detalle',
    'entrada_inventario',
    'movimiento_inventario_detalle',
    'movimiento_inventario',
    'inventario_kardex',
    -- Notas / ediciones
    'nota_ajuste_detalle',
    'nota_ajuste_documento',
    'edicion_recibo_detalle',
    'edicion_recibo',
    -- Confirmación pagos / email
    'ticket_sin_notificacion',
    'notificacion_email_pago',
    'historial_recibos_electronicos',
    -- Ventas / tickets / multipago
    'ticket_recibo',
    'historial_recibo_pago',
    'historial_recibo_detalle',
    'recibo_detalle_historico',
    'recibo_detalle',
    'documento_venta',
    'historial_recibo',
    'recibo',
    'ticket',
    -- Consecutivos (VTA- reinicia) + agregados
    'consecutivo_documento',
    'estadistica_fin',
    'flujo_dinero',
    -- Cargues / historial precio (operativo de prueba)
    'cargue_producto_conflictos',
    'cargue_productos',
    'historial_precio_producto',
    'historial_producto'
  ];
  t text;
  existentes text[] := ARRAY[]::text[];
BEGIN
  FOREACH t IN ARRAY candidatas LOOP
    IF EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = t
        AND table_type = 'BASE TABLE'
    ) THEN
      existentes := array_append(existentes, format('%I', t));
    ELSE
      RAISE NOTICE 'Omitida (no existe): %', t;
    END IF;
  END LOOP;

  IF coalesce(array_length(existentes, 1), 0) = 0 THEN
    RAISE EXCEPTION 'Ninguna tabla candidata existe; abortando reset.';
  END IF;

  EXECUTE format(
    'TRUNCATE TABLE %s RESTART IDENTITY CASCADE',
    array_to_string(existentes, ', ')
  );

  RAISE NOTICE 'TRUNCATE OK (% tablas)', array_length(existentes, 1);
END $$;

-- Aserción: modal base inicial requiere ledger limpio + sin cortes activos
DO $$
DECLARE
  n_base bigint;
  n_corte bigint;
  n_hr bigint;
  n_mof bigint;
BEGIN
  SELECT COUNT(*) INTO n_base
  FROM movimiento_origen_fondos
  WHERE origen_tipo = 'BASE_INICIAL';

  SELECT COUNT(*) INTO n_corte
  FROM corte_venta
  WHERE estado <> 'eliminado';

  SELECT COUNT(*) INTO n_hr FROM historial_recibo;
  SELECT COUNT(*) INTO n_mof FROM movimiento_origen_fondos;

  IF n_base > 0 OR n_corte > 0 OR n_hr > 0 OR n_mof > 0 THEN
    RAISE EXCEPTION
      'Reset incompleto (¿sin Commit?): BASE_INICIAL=%, cortes_activos=%, historial_recibo=%, MOF=%. Re-ejecuta con Auto-commit ON.',
      n_base, n_corte, n_hr, n_mof;
  END IF;

  RAISE NOTICE 'OK: ventas/cortes/ledger en 0. Logout + login ADMIN → base inicial.';
END $$;

-- Verificación legible
SELECT tabla, n
FROM (
  SELECT 'corte_venta'::text AS tabla, COUNT(*)::bigint AS n FROM corte_venta
  UNION ALL SELECT 'movimiento_origen_fondos', COUNT(*) FROM movimiento_origen_fondos
  UNION ALL SELECT 'historial_recibo', COUNT(*) FROM historial_recibo
  UNION ALL SELECT 'historial_recibo_pago', COUNT(*) FROM historial_recibo_pago
  UNION ALL SELECT 'documento_venta', COUNT(*) FROM documento_venta
  UNION ALL SELECT 'ticket', COUNT(*) FROM ticket
  UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
  UNION ALL SELECT 'notificacion_email_pago', COUNT(*) FROM notificacion_email_pago
  UNION ALL SELECT 'cuenta_por_cobrar', COUNT(*) FROM cuenta_por_cobrar
  UNION ALL SELECT 'abono_cxc', COUNT(*) FROM abono_cxc
  UNION ALL SELECT 'estadistica_fin', COUNT(*) FROM estadistica_fin
  UNION ALL SELECT 'flujo_dinero', COUNT(*) FROM flujo_dinero
  -- Paramétricas (deben seguir con filas)
  UNION ALL SELECT 'origen_fondos (catálogo)', COUNT(*) FROM origen_fondos
  UNION ALL SELECT 'motivo_movimiento (catálogo)', COUNT(*) FROM motivo_movimiento
  UNION ALL SELECT 'metodo_pago (catálogo)', COUNT(*) FROM metodo_pago
  UNION ALL SELECT 'plantilla_notificacion_pago (catálogo)', COUNT(*) FROM plantilla_notificacion_pago
  UNION ALL SELECT 'producto (maestro)', COUNT(*) FROM producto
  UNION ALL SELECT 'establecimiento (config)', COUNT(*) FROM establecimiento
) v
ORDER BY 1;

SELECT 'OK: logout + login ADMIN para modal Entrada manual (valor inicial caja)' AS siguiente_paso;
