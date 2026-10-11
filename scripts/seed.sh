#!/usr/bin/env bash
# Generate the dataset. SCALE=1 (default) ~ 250k orders / 2M events.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
require_db

SCALE="${SCALE:-1}"
echo "seeding at SCALE=$SCALE"

for f in $(ls db/seed/*.sql | sort); do
  echo "==> $f"
  start=$(date +%s)
  $DC exec -T db psql -v ON_ERROR_STOP=1 -X \
      -U "$PG_USER" -d "$PG_DB" \
      -v scale="$SCALE" -v DBNAME="$PG_DB" \
      -f "/${f}"
  echo "    (${f##*/} took $(( $(date +%s) - start ))s)"
done

echo "==> matviews + statistics"
bash scripts/run_sql_dir.sh db/maintenance >/dev/null
echo "seed complete"
bash -c 'source scripts/_lib.sh; psql_r -f /db/maintenance/90_report_sizes.sql'
