#!/usr/bin/env bash
set -euo pipefail

ODOO_DB_NAME="${ODOO_DB_NAME:-odoo}"
INIT_MARKER="/volumes/data/.${ODOO_DB_NAME}_initialized"

# Run only once per persisted data dir
if [ -f "$INIT_MARKER" ]; then
  echo "[hook_setup] $ODOO_DB_NAME already initialized, skipping."
  exit 0
fi

echo "[hook_setup] Waiting for Postgres at ${ODOO_DB_HOST}:${ODOO_DB_PORT}..."

# Setup hook runs before the built-in wait-for-psql, so we do our own wait.
# Uses psycopg2 which is already installed with Odoo.
/usr/local/bin/wait-for-psql.py

echo "[hook_setup] Initializing DB ${ODOO_DB_NAME} and installing adomi_community..."

# This will create the DB if needed and install/update your module
odoo-bin \
  -c "${ODOO_CONFIG:-/volumes/config/_generated.conf}" \
  -d "${ODOO_DB_NAME}" \
  -i adomi_community \
  -u adomi_community \
  --without-demo=true \
  --stop-after-init

touch "$INIT_MARKER"
echo "[hook_setup] Initialization complete."
