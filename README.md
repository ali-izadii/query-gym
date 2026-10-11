# query-practice

A self-contained PostgreSQL 17 lab for practising SQL from the basics up to
window functions, recursive CTEs, JSONB, partitioning and query tuning.

- **Realistic schema** — a marketplace: 30 tables across `shop`, `hr` and
  `analytics`, including a category tree, an org chart, JSONB attributes,
  `tsvector` full-text columns, `daterange` temporal tables with exclusion
  constraints, and a month-partitioned clickstream.
- **Reproducible data** — generated inside the database from deterministic
  hash functions. No dumps in git; same `SCALE` always yields the same rows.
- **288 exercises in 17 topics**, each with a reference answer, hints,
  difficulty and concept tags.
- **Automatic grading** — write your query, run `make diff`, get a row-level
  comparison against the reference result.

---

## Quick start

```bash
cp .env.example .env     # optional: change ports / SCALE
make build               # containers + schema + data   (~3 min at SCALE=1)
make list                # see the topics
make show Q=T05-03       # read one task
make new  Q=T05-03       # creates work/T05-03.sql
#   ... write your query in work/T05-03.sql ...
make diff Q=T05-03 F=work/T05-03.sql
```

- Postgres: `localhost:5433` (user `qp`, password `qp`, db `querypractice`)
- pgAdmin: <http://localhost:5050> — the server is pre-registered
- psql shell: `make psql`

## The practice loop

| Command | What it does |
|---|---|
| `make list` | topic overview with difficulty counts |
| `make list T=window` | list exercises of matching topics |
| `make show Q=T06-05` | task text, hint and concepts (no answer) |
| `make new Q=T06-05` | scaffold `work/T06-05.sql` with the task as a comment |
| `make diff Q=T06-05 F=work/T06-05.sql` | **grade**: compares your result set to the reference |
| `make answer Q=T06-05` | print the reference SQL |
| `make run Q=T06-05` | execute the reference SQL and show the rows |
| `make explain Q=T06-05` | `EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)` |
| `make check` / `make check T=14` | run every reference answer (CI-style smoke test) |

Grading rules:

- Row order is ignored **unless** the reference query has an `ORDER BY`, in
  which case order must match.
- Column *names* are not compared, but column **count, order and values** are.
- Failures print the first differing rows on both sides.

## Topics

| # | Topic | Exercises |
|---|-------|-----------|
| 01 | Basics: SELECT, WHERE, NULL, ORDER BY, pagination | 16 |
| 02 | Joins: inner, outer, anti/semi, self, cross, LATERAL | 18 |
| 03 | Aggregation: GROUP BY, HAVING, FILTER, ordered-set aggregates | 18 |
| 04 | Subqueries & CTEs: correlated, EXISTS, materialization | 18 |
| 05 | Window functions I: ranking, lag/lead, frames (ROWS/RANGE/GROUPS) | 20 |
| 06 | Window functions II: gaps & islands, sessionisation, funnels, cohorts | 16 |
| 07 | Recursive CTEs: trees, graphs, paths, `SEARCH`/`CYCLE` | 16 |
| 08 | GROUPING SETS, ROLLUP, CUBE, pivot/unpivot, crosstab | 14 |
| 09 | JSONB: containment, jsonpath, building, GIN indexes | 20 |
| 10 | Arrays, ranges, multiranges, exclusion constraints | 18 |
| 11 | Text: LIKE, regex, full-text search, trigram, fuzzy matching | 18 |
| 12 | Dates, intervals, time zones, `date_bin`, time series | 16 |
| 13 | Set operations & data reconciliation | 12 |
| 14 | Performance: EXPLAIN, index types, sargability, partition pruning | 18 |
| 15 | DML: UPSERT, `UPDATE FROM`, MERGE, `SKIP LOCKED`, isolation | 16 |
| 16 | Data quality: profiling, dedup, validation, outliers | 16 |
| 17 | Capstone reports: RFM, LTV, basket analysis, attribution, SCD2 | 18 |

Full task text: [`exercises/README.md`](exercises/README.md).
Difficulty: 🟢 51 basic · 🟡 72 intermediate · 🟠 99 advanced · 🔴 66 expert.

## Dataset

`SCALE` in `.env` multiplies the fact tables. Defaults:

| SCALE | orders | order items | page events | DB size | seed time |
|---|---|---|---|---|---|
| 1 (default) | 250 k | ~750 k | 2 M | ~1.1 GB | ~3 min |
| 5 | 1.25 M | ~3.7 M | 10 M | ~5 GB | ~15 min |
| 20 | 5 M | ~15 M | 40 M | ~20 GB | ~1 h |

```bash
make reset SCALE=5       # wipe volumes and rebuild bigger
```

Data properties that exercises rely on: NULLs in optional columns, ~12 % of
products never sold, skewed (Zipf) customer and product popularity, failed
payment retries, partial refunds, threaded reviews and support messages,
deliberate gaps in FX rates and shift calendars, and a dirty
`shop.raw_leads` staging table.

See [`docs/schema.md`](docs/schema.md) for the full ER description and
[`docs/learning-path.md`](docs/learning-path.md) for a suggested order.

## Performance work

The shipped index set in `db/schema/06_indexes.sql` is deliberately
incomplete. Topic 14 asks you to find what is missing:

```bash
make explain Q=T14-07    # plan before
make indexes             # applies db/perf/optional_indexes.sql
make explain Q=T14-07    # plan after
```

Reset to the original index set with `make schema seed` (or `make reset`).

## Layout

```
db/schema/        DDL: extensions, tables, views, indexes
db/seed/          deterministic data generation (00..06)
db/maintenance/   matviews, extended statistics, size report
db/perf/          the "discover these yourself" indexes
solutions/        reference answers + task metadata (source of truth)
exercises/        generated markdown (make exercises)
scripts/qp.py     the CLI behind every make target
work/             your attempts (git-ignored)
config/           postgresql.conf used by the container
```

## Requirements

Docker with Compose v2, GNU make, Python 3.8+ (standard library only).
No local Postgres client needed — `psql` runs inside the container.
