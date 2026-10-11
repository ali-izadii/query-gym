#!/usr/bin/env bash
# Run every *.sql in a directory, in filename order, inside the db container.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
require_db

dir="${1:?usage: run_sql_dir.sh db/schema}"
shift || true

for f in $(ls "$dir"/*.sql | sort); do
  echo "==> $f"
  # files live under /db (or /scripts) inside the container
  $DC exec -T db psql -v ON_ERROR_STOP=1 -X \
      -U "$PG_USER" -d "$PG_DB" \
      -v DBNAME="$PG_DB" "$@" \
      -f "/${f}"
done
echo "done: $dir"
