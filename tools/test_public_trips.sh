#!/usr/bin/env bash
# Isolated PostGIS contract tests. Never connects to a linked Supabase project.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_container="kaunti-public-trips-test-$$"
cleanup() { docker rm -f "$test_container" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run --rm -d --platform linux/amd64 --name "$test_container" \
  -e POSTGRES_HOST_AUTH_METHOD=trust postgis/postgis:16-3.4 >/dev/null
ready=false
for attempt in {1..60}; do
  if docker exec "$test_container" pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
if [[ "$ready" != true ]]; then
  echo 'Local PostGIS did not become ready' >&2
  exit 1
fi
docker exec "$test_container" createdb -U postgres -T template0 public_trip_tests
run_sql() {
  echo "SQL: $(basename "$1")"
  docker exec -i "$test_container" psql -X -q -U postgres -d public_trip_tests \
    -v ON_ERROR_STOP=1 < "$1"
}
run_sql "$repo_root/supabase/tests/public_trips/bootstrap.sql"
run_sql "$repo_root/supabase/migrations/20260925130000_add_private_journeys.sql"
run_sql "$repo_root/supabase/tests/public_trips/contracts.sql"
for migration in "$repo_root"/supabase/migrations/20261004*_public_trip_*.sql; do
  run_sql "$migration"
done
for test_file in "$repo_root"/supabase/tests/public_trips/*_test.sql; do
  run_sql "$test_file"
done
echo 'Public Trips SQL contract tests passed.'
