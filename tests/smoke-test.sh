#!/usr/bin/env bash

# Start the image against a fresh database and wait for Odoo to answer
# The setup hook installs adomi_community, so every bundled addon gets installed

# Configuration options for this script
export SMOKE_IMAGE_TAG=${1:-${SMOKE_IMAGE_TAG:-"adomi-community-base:test"}}
export SMOKE_TIMEOUT=${SMOKE_TIMEOUT:-900}
export SMOKE_PORT=${SMOKE_PORT:-18069}

export SMOKE_POSTGRES_IMAGE=${SMOKE_POSTGRES_IMAGE:-"postgres:17"}
export SMOKE_NETWORK_NAME=${SMOKE_NETWORK_NAME:-"odoo_smoke_$$"}
export SMOKE_ODOO_CONTAINER_NAME=${SMOKE_ODOO_CONTAINER_NAME:-"${SMOKE_NETWORK_NAME}_odoo"}
export SMOKE_POSTGRES_CONTAINER_NAME=${SMOKE_POSTGRES_CONTAINER_NAME:-"${SMOKE_NETWORK_NAME}_db"}

export SMOKE_DB_USER=${SMOKE_DB_USER:-"odoo"}
export SMOKE_DB_PASSWORD=${SMOKE_DB_PASSWORD:-"odoo"}
export SMOKE_DB_NAME=${SMOKE_DB_NAME:-"smoke"}

# Cleanup our mess when we are done
cleanup() {
  docker rm -f "${SMOKE_ODOO_CONTAINER_NAME}" "${SMOKE_POSTGRES_CONTAINER_NAME}" >/dev/null 2>&1 || true
  docker network rm "${SMOKE_NETWORK_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "${SMOKE_NETWORK_NAME}" >/dev/null

# Start the database as a daemon
docker run -d \
  --name "${SMOKE_POSTGRES_CONTAINER_NAME}" \
  --network "${SMOKE_NETWORK_NAME}" \
  -e POSTGRES_USER="${SMOKE_DB_USER}" \
  -e POSTGRES_PASSWORD="${SMOKE_DB_PASSWORD}" \
  -e POSTGRES_DB="postgres" \
  "${SMOKE_POSTGRES_IMAGE}" >/dev/null

# Start Odoo
docker run -d \
  --name "${SMOKE_ODOO_CONTAINER_NAME}" \
  --network "${SMOKE_NETWORK_NAME}" \
  -p "127.0.0.1:${SMOKE_PORT}:8069" \
  -e ODOO_DB_HOST="${SMOKE_POSTGRES_CONTAINER_NAME}" \
  -e ODOO_DB_PORT="5432" \
  -e ODOO_DB_USER="${SMOKE_DB_USER}" \
  -e ODOO_DB_PASSWORD="${SMOKE_DB_PASSWORD}" \
  -e ODOO_DB_NAME="${SMOKE_DB_NAME}" \
  "${SMOKE_IMAGE_TAG}" >/dev/null

echo "Starting ${SMOKE_IMAGE_TAG}, waiting up to ${SMOKE_TIMEOUT} seconds ..."

START_TIME=$(date +%s)

# Wait for the health endpoint
while ! curl -fs -o /dev/null "http://127.0.0.1:${SMOKE_PORT}/web/health"; do
  ELAPSED=$(( $(date +%s) - START_TIME ))

  if [ "$(docker inspect -f '{{.State.Running}}' "${SMOKE_ODOO_CONTAINER_NAME}")" != "true" ]; then
    echo "Odoo exited before it became healthy"
    docker logs --tail 80 "${SMOKE_ODOO_CONTAINER_NAME}"
    exit 1
  fi

  if [ "${ELAPSED}" -ge "${SMOKE_TIMEOUT}" ]; then
    echo "Odoo did not become healthy within ${SMOKE_TIMEOUT} seconds"
    docker logs --tail 80 "${SMOKE_ODOO_CONTAINER_NAME}"
    exit 1
  fi

  sleep 5
done

ELAPSED=$(( $(date +%s) - START_TIME ))
echo "Odoo is healthy after ${ELAPSED} seconds"

# A healthy server with a traceback in the log is still a failure
if docker logs "${SMOKE_ODOO_CONTAINER_NAME}" 2>&1 | grep -qE "CRITICAL|Traceback"; then
  echo "Errors in the Odoo log"
  docker logs "${SMOKE_ODOO_CONTAINER_NAME}" 2>&1 | grep -E "CRITICAL|Traceback" | head -20
  exit 1
fi

# Everything passed!
echo "Smoke test passed"
