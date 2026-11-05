#!/usr/bin/env bash
# Runs the migrations and their tests in a throwaway PostgreSQL container.
#   bash backend/supabase/tests/run.sh
# Needs Docker. Uses postgres:15 (the major version Supabase runs).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
name=sfm-sql-test
image=postgres:15-alpine

docker rm -f "$name" >/dev/null 2>&1 || true
docker run -d --name "$name" -e POSTGRES_PASSWORD=test "$image" >/dev/null
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT

# Over TCP: the image's first-start setup server listens only on the socket and
# then shuts down, so a socket check can pass too early.
for _ in $(seq 1 30); do
  docker exec "$name" pg_isready -h 127.0.0.1 -U postgres -q && break
  sleep 1
done

psql() { docker exec -i "$name" psql -U postgres -v ON_ERROR_STOP=1 -q "$@"; }

psql < "$here/00_supabase_stub.sql"
for m in "$here"/../migrations/*.sql; do psql < "$m"; done
psql < "$here/../seed_codes.sql"
# One session for both files: the dashboard tests use the sync tests'
# helpers and data. Show only the checks and errors.
cat "$here/sync_functions_test.sql" "$here/dashboard_test.sql" \
  | psql -t 2>&1 | grep -E 'NOTICE|ERROR|FAILED|CONTEXT'
status="${PIPESTATUS[1]}"
[ "$status" -eq 0 ] && echo 'ALL SQL CHECKS PASSED'
exit "$status"
