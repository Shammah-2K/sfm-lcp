#!/usr/bin/env bash
# Runs the migration and its tests in a throwaway PostgreSQL container.
#   bash backend/supabase/tests/run.sh
# Needs Docker. Uses postgres:15 (the major version Supabase runs).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
name=sfm-sql-test
image=postgres:15-alpine

docker rm -f "$name" >/dev/null 2>&1 || true
docker run -d --name "$name" -e POSTGRES_PASSWORD=test "$image" >/dev/null
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 30); do
  docker exec "$name" pg_isready -U postgres -q && break
  sleep 1
done

psql() { docker exec -i "$name" psql -U postgres -v ON_ERROR_STOP=1 -q "$@"; }

psql < "$here/00_supabase_stub.sql"
psql < "$here/../migrations/20261027000000_sync.sql"
psql < "$here/../seed_codes.sql"
# Show only the checks and errors, not the empty result of each call.
psql -t < "$here/sync_functions_test.sql" 2>&1 | grep -E 'NOTICE|ERROR|FAILED|CONTEXT|PASSED'
exit "${PIPESTATUS[0]}"
