-- Reset operativo de prueba: vacía movimientos, ventas, egresos, cortes, tickets/recibos.
-- Conserva catálogos: origen_fondos, metodo_pago, motivo_movimiento, establecimiento, etc.
-- Uso:
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f reset-tablas-financieras-transaccionales.sql
-- CASCADE puede vaciar tablas hijas (p. ej. historial_precio_producto).

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

-- Verificación
SELECT 'corte_venta' AS tabla, COUNT(*)::bigint AS n FROM corte_venta
UNION ALL SELECT 'corte_venta_detalle', COUNT(*) FROM corte_venta_detalle
UNION ALL SELECT 'ventas_tipo', COUNT(*) FROM ventas_tipo
UNION ALL SELECT 'movimiento_origen_fondos', COUNT(*) FROM movimiento_origen_fondos
UNION ALL SELECT 'historial_recibo', COUNT(*) FROM historial_recibo
UNION ALL SELECT 'historial_recibo_detalle', COUNT(*) FROM historial_recibo_detalle
UNION ALL SELECT 'recibo', COUNT(*) FROM recibo
UNION ALL SELECT 'recibo_detalle', COUNT(*) FROM recibo_detalle
UNION ALL SELECT 'documento_venta', COUNT(*) FROM documento_venta
UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
UNION ALL SELECT 'ticket', COUNT(*) FROM ticket
UNION ALL SELECT 'ticket_recibo', COUNT(*) FROM ticket_recibo
UNION ALL SELECT 'movimiento_inventario', COUNT(*) FROM movimiento_inventario
UNION ALL SELECT 'origen_fondos (catálogo)', COUNT(*) FROM origen_fondos
UNION ALL SELECT 'motivo_movimiento (catálogo)', COUNT(*) FROM motivo_movimiento
UNION ALL SELECT 'metodo_pago (catálogo)', COUNT(*) FROM metodo_pago
ORDER BY 1;
