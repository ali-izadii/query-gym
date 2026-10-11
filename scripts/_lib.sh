#!/usr/bin/env bash
# Shared helpers for all scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a; # shellcheck disable=SC1091
  source .env; set +a
fi

PG_USER="${POSTGRES_USER:-qp}"
PG_DB="${POSTGRES_DB:-querypractice}"
DC="${DC:-docker compose}"

psql_q() {  # quiet, tuples only
  $DC exec -T db psql -v ON_ERROR_STOP=1 -qtAX -U "$PG_USER" -d "$PG_DB" "$@"
}

psql_r() {  # normal output
  $DC exec -T db psql -v ON_ERROR_STOP=1 -X -U "$PG_USER" -d "$PG_DB" "$@"
}

require_db() {
  if ! $DC exec -T db pg_isready -U "$PG_USER" -d "$PG_DB" >/dev/null 2>&1; then
    echo "postgres not running. start it with: make up" >&2
    exit 1
  fi
}

# Resolve an exercise id (T05-03, t05-03, 0503, 05-03) to a solution file path.
find_solution() {
  local q="${1^^}" norm f
  norm=$(printf '%s' "$q" | tr -cd '0-9')
  f=$(grep -rilE "^--[[:space:]]*id:[[:space:]]*${q}[[:space:]]*$" solutions --include='*.sql' | head -1 || true)
  if [[ -z "$f" && -n "$norm" ]]; then
    # match on digits only: 0503 -> T05-03
    f=$(grep -rilE "^--[[:space:]]*id:[[:space:]]*T?${norm:0:2}-?${norm:2}[[:space:]]*$" \
        solutions --include='*.sql' | head -1 || true)
  fi
  [[ -n "$f" ]] || { echo "no solution with id '$1'" >&2; exit 1; }
  printf '%s\n' "$f"
}

# Strip the leading "-- key: value" metadata header, leaving runnable SQL.
strip_header() {
  awk 'BEGIN{h=1}
       h && /^--/ {next}
       {h=0; print}' "$1"
}

# Read a header field.
sol_field() {
  grep -m1 -iE "^--[[:space:]]*$2:" "$1" | sed -E "s/^--[[:space:]]*$2:[[:space:]]*//I" || true
}

sol_id()   { sol_field "$1" id; }
sol_kind() { local k; k=$(sol_field "$1" kind); echo "${k:-select}"; }
