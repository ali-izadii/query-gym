# Learning path

288 exercises is a lot. Here are three routes through them.

Each exercise id encodes topic and position: `T05-03` = topic 05, item 03.
Difficulty: 🟢 basic · 🟡 intermediate · 🟠 advanced · 🔴 expert.

---

## Route A — foundations first (recommended, ~4 weeks)

| Phase | Topics | Why |
|---|---|---|
| 1. Reading data | 01, 02 🟢🟡 | filtering, NULL semantics, join shapes |
| 2. Summarising | 03, 04 | aggregation + subquery/CTE structure |
| 3. **Windows** | 05 then 06 | the single highest-leverage advanced topic |
| 4. Shapes of data | 08, 13 | pivots, grouping sets, set operations |
| 5. Hierarchies | 07 | recursion, trees, graphs |
| 6. Postgres types | 09, 10, 11, 12 | JSONB, arrays/ranges, text, time |
| 7. Writing data | 15 | UPSERT, MERGE, locking, isolation |
| 8. Making it fast | 14 | EXPLAIN, indexes, plan shapes |
| 9. Real work | 16, 17 | data quality and capstone reports |

Within a topic, do all 🟢 and 🟡 first, then come back for 🟠 and 🔴.

## Route B — interview prep (~1 week)

The patterns that appear most often in SQL interviews:

```
T01-14  DISTINCT ON (top-1 per group)
T02-07  anti-join (never ordered)
T02-13  LATERAL top-N per group
T03-06  conditional aggregation with FILTER
T03-12  median / percentiles
T04-06  NOT EXISTS vs NOT IN with NULLs
T05-06  top-N per partition
T05-07  lag: month-over-month change
T05-10  running total
T05-12  moving average
T05-17  ntile buckets
T05-20  deduplicate with row_number
T06-02  gaps and islands (consecutive days)
T06-05  sessionisation with a timeout
T06-08  funnel conversion per step
T06-10  cohort retention
T07-08  recursive org chart
T08-05  pivot with FILTER
T12-04  gap filling a date series
T17-01  RFM segmentation
T17-03  market basket pairs
```

## Route C — by technique

Looking for a specific thing?

| I want to practise… | Exercises |
|---|---|
| NULL semantics | T01-02, T01-04, T01-09, T04-06, T04-18, T16-01 |
| pagination | T01-11 (OFFSET), T01-12 (keyset) |
| LATERAL | T02-13, T02-14, T04-11, T17-15 |
| join cardinality / fan-out | T02-16, T02-05, T17-07 |
| window frames (ROWS/RANGE/GROUPS) | T05-12, T05-13, T05-14, T12-12 |
| ranking and ties | T05-05, T06-12 |
| gaps & islands | T06-01, T06-02, T06-03, T06-04, T10-18 |
| cohorts & retention | T06-10, T06-11, T17-12 |
| funnels & sessions | T06-05, T06-07, T06-08, T17-10 |
| LOCF / as-of joins | T06-09, T17-15, T17-16 |
| recursion | all of topic 07 |
| pivot / unpivot | T08-05, T08-07, T08-08, T08-09, T08-12 |
| JSONB containment & jsonpath | T09-04, T09-09, T09-19, T09-20 |
| JSONB building | T09-11, T09-12, T09-18 |
| arrays | T10-01 … T10-09 |
| ranges & temporal integrity | T10-10 … T10-18, T02-15 |
| full-text search | T11-08 … T11-12 |
| fuzzy matching | T11-13, T11-14, T16-16 |
| time zones / DST | T12-07, T12-16 |
| time bucketing | T12-05, T12-06, T12-11 |
| EXPLAIN reading | T14-01 … T14-06 |
| index design | T14-03, T14-07, T14-08, T14-16 |
| partitioning | T14-04, T14-05 |
| query rewriting | T14-09, T14-10, T14-14, T14-18 |
| UPSERT / MERGE | T15-03, T15-04, T15-08 |
| transactions & locking | T15-11, T15-13, T15-14 |
| data validation | T16-07 … T16-14 |

---

## How to actually practise

1. `make show Q=T06-05` — read the task, resist opening the answer.
2. `make new Q=T06-05` — scaffold a file.
3. Write the query. Iterate in `make psql` if you want fast feedback.
4. `make diff Q=T06-05 F=work/T06-05.sql` — grade it.
5. Only then `make answer Q=T06-05`, and compare approaches. A different
   query that produces the same rows is a pass, not a failure.
6. For 🟠/🔴 exercises, also run `make explain Q=...` and ask why the plan
   looks the way it does.

If `make diff` fails on row counts, check your `WHERE` boundaries
(half-open ranges) and whether you dropped NULLs accidentally. If it fails on
values, check rounding — the reference answers round explicitly where the task
says so.
