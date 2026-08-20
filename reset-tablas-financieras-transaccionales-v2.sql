-- =============================================================================
-- Reset tablas financieras transaccionales (POS) — v2
-- =============================================================================
-- BD: controlneg_rmx_db
--
-- DBeaver (importante — evita el fallo intermitente del modal base inicial):
--   1) Preferir Auto-commit = ON (Window → Preferences → Editors → SQL Editor
--      → SQL Execution → Auto-commit).
--   2) Ejecutar como SCRIPT completo: Alt+X / "Execute SQL Script"
--      (no "Execute SQL Statement" sentencia a sentencia).
--   3) NO hace falta pulsar Commit después: este script NO abre BEGIN/COMMIT
--      externo; cada TRUNCATE queda visible de inmediato para el backend.
--   4) Si Auto-commit está OFF: tras ejecutar, Commit UNA vez en la toolbar
--      ANTES de cerrar sesión / login en la app.
--
-- Tras el reset: logout completo + login como ADMIN → modal "Entrada manual".
-- El modal NO aparece si queda 1 fila BASE_INICIAL o un corte_venta activo.
-- =============================================================================

-- Falla rápido si otra sesión (p. ej. Spring) sostiene locks demasiado tiempo.
SET lock_timeout = '5s';
SET client_min_messages = NOTICE;

DO $$
DECLARE
  candidatas text[] := ARRAY[
    'corte_venta_detalle',
    'ventas_tipo',
    'corte_venta',
    'movimiento_origen_fondos',
    'entrada_inventario_detalle',
    'entrada_inventario',
    'egreso',
    'movimiento_inventario_detalle',
    'movimiento_inventario',
    'inventario_kardex',
    'nota_ajuste_detalle',
    'nota_ajuste_documento',
    'edicion_recibo_detalle',
    'edicion_recibo',
    'ticket_recibo',
    'historial_recibo_pago',
    'historial_recibos_electronicos',
    'historial_recibo_detalle',
    'recibo_detalle_historico',
    'recibo_detalle',
    'documento_venta',
    'historial_recibo',
    'recibo',
    'ticket',
    'consecutivo_documento',
    'estadistica_fin',
    'flujo_dinero'
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

  -- Un solo TRUNCATE: atómico en la sentencia; con Auto-commit ON queda
  -- confirmado al terminar el bloque DO (en PG el DO corre en una transacción
  -- implícita de la sentencia y se confirma al final si Auto-commit está ON).
  EXECUTE format(
    'TRUNCATE TABLE %s RESTART IDENTITY CASCADE',
    array_to_string(existentes, ', ')
  );

  RAISE NOTICE 'TRUNCATE OK (% tablas)', array_length(existentes, 1);
END $$;

-- Aserción: si esto falla, el modal de caja NO saldrá (datos no quedaron en 0).
DO $$
DECLARE
  n_base bigint;
  n_corte bigint;
BEGIN
  SELECT COUNT(*) INTO n_base
  FROM movimiento_origen_fondos
  WHERE origen_tipo = 'BASE_INICIAL';

  SELECT COUNT(*) INTO n_corte
  FROM corte_venta
  WHERE estado <> 'eliminado';

  IF n_base > 0 OR n_corte > 0 THEN
    RAISE EXCEPTION
      'Reset incompleto (¿transacción sin Commit en DBeaver?): BASE_INICIAL=%, cortes_activos=%. Haz Commit o re-ejecuta con Auto-commit ON.',
      n_base, n_corte;
  END IF;

  RAISE NOTICE 'OK base inicial pendiente: BASE_INICIAL=0, cortes_activos=0. Logout + login ADMIN.';
END $$;

-- Verificación legible
SELECT tabla, n
FROM (
  SELECT 'corte_venta'::text AS tabla, COUNT(*)::bigint AS n FROM corte_venta
  UNION ALL SELECT 'movimiento_origen_fondos', COUNT(*) FROM movimiento_origen_fondos
  UNION ALL SELECT 'movimiento BASE_INICIAL', (
    SELECT COUNT(*) FROM movimiento_origen_fondos WHERE origen_tipo = 'BASE_INICIAL'
  )
  UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
  UNION ALL SELECT 'ticket', COUNT(*) FROM ticket
  UNION ALL SELECT 'estadistica_fin', COUNT(*) FROM estadistica_fin
  UNION ALL SELECT 'flujo_dinero', COUNT(*) FROM flujo_dinero
  UNION ALL SELECT 'origen_fondos (catálogo)', COUNT(*) FROM origen_fondos
  UNION ALL SELECT 'motivo_movimiento (catálogo)', COUNT(*) FROM motivo_movimiento
  UNION ALL SELECT 'metodo_pago (catálogo)', COUNT(*) FROM metodo_pago
) v
ORDER BY 1;

SELECT 'OK: logout + login ADMIN para modal Entrada manual (valor inicial caja)' AS siguiente_paso;
