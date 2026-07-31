#!/usr/bin/env bash
# Vacía tablas financieras transaccionales de prueba. Conserva catálogos.
# Uso:
#   bash apply-reset-tablas-financieras-transaccionales.sh
#   DB_URL='postgresql://user:pass@host:5432/db' bash apply-reset-tablas-financieras-transaccionales.sh
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_URL="${DB_URL:-postgresql://romax-admin:f4ast3rv3rs10n*@localhost:5432/controlneg_rmx_db}"
SQL="$DIR/reset-tablas-financieras-transaccionales.sql"

echo ">>> Reset tablas financieras transaccionales"
echo "    DB: ${DB_URL%%@*}@***"
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SQL"
echo ">>> Listo. Catálogos conservados; transacciones en 0."
