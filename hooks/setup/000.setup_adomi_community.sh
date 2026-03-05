#!/usr/bin/env bash
set -euo pipefail

ODOO_DB_NAME="${ODOO_DB_NAME:-odoo}"

echo "[hook_setup] Waiting for Postgres at ${ODOO_DB_HOST}:${ODOO_DB_PORT}..."

# Setup hook runs before the built-in wait-for-psql, so we do our own wait.
# Uses psycopg2 which is already installed with Odoo.
/usr/local/bin/wait-for-psql.py


odoo-bin \
  -c "${ODOO_CONFIG:-/volumes/config/_generated.conf}" \
  -d "${ODOO_DB_NAME}" \
  -i adomi_community \
  -u adomi_community \
  --without-demo=true \
  --stop-after-init

echo "[hook_setup] Initialization complete."
