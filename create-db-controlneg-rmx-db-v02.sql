-- Runbook: prompts-general-pos/MIGRATE-TIENDA-INFINITO-V02.md
-- Base v02 (Tienda Infinito), misma instancia Postgres :5432.
-- La caja productiva sigue en controlneg_rmx_db. Esta BD es para la pila nueva
-- (launcher ambiente tienda-infinito: POS :8288, auth :8281, puente :8295).
--
-- Vacía (luego migraciones / correcciones):
CREATE DATABASE controlneg_rmx_db_v02 OWNER "romax-admin";

-- Copia idéntica de la actual (alternativa; requiere que nadie esté conectado a la origen):
-- CREATE DATABASE controlneg_rmx_db_v02 WITH TEMPLATE controlneg_rmx_db OWNER "romax-admin";
