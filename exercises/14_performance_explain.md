# 14. Performance: EXPLAIN, indexes, plans

**1** basic, **4** intermediate, **7** advanced, **6** expert — 18 exercises

```bash
make new Q=T14-01                 # scaffold work/T14-01.sql
make diff Q=T14-01 F=work/T14-01.sql   # grade your answer
make run Q=T14-01                 # see the reference result
make explain Q=T14-01             # see the plan
```

---

### T14-01 — Read your first plan

🟢 basic · `EXPLAIN ANALYZE, scan types, estimate accuracy`

Explain a simple count of orders in March 2025 and identify the scan type, estimated vs actual rows, and whether the index on placed_at is used.

<details><summary>hint</summary>

Compare "rows=" in the plan line with "actual rows=".

</details>

### T14-02 — Sargable vs non-sargable predicate

🟡 intermediate · `sargability, function-wrapped columns, index usability`

Compare two equivalent filters on placed_at: one wrapping the column in a function, one using a half-open range. Explain both and note which can use idx_orders_placed_at.

<details><summary>hint</summary>

date_trunc('month', placed_at) = ... hides the column from the index; placed_at >= x AND placed_at < y does not.

</details>

### T14-03 — Index-only scan

🟡 intermediate · `index-only scan, covering index, heap fetches, visibility map`

Explain a query that can be answered entirely from idx_orders_user_covering (user_id, placed_at) INCLUDE (grand_total, status) and confirm "Index Only Scan" plus a Heap Fetches line.

<details><summary>hint</summary>

Select only indexed/included columns and filter on the leading column.

</details>

### T14-04 — Partition pruning

🟡 intermediate · `declarative partitioning, partition pruning, Append nodes`

Explain a count of page_events for a single month and verify that only one partition is scanned; then explain a count without a time filter and observe all partitions being appended.

<details><summary>hint</summary>

Look for "Subplans Removed" / the list of scanned relations under Append.

</details>

### T14-05 — BRIN vs btree on a huge append-only column

🟡 intermediate · `BRIN, bitmap scans, physical correlation`

Explain a wide time-range scan on page_events and note whether the BRIN index on occurred_at is used, plus the lossy recheck.

<details><summary>hint</summary>

BRIN gives a Bitmap Heap Scan with "Recheck Cond"; it is tiny on disk but only helps when physical order correlates with the column.

</details>

### T14-06 — Nested loop vs hash join

🟠 advanced · `join algorithms, planner GUCs, cost comparison`

Explain the same seller-revenue join twice: once as written, once with enable_hashjoin off, and compare total time and plan shape.

<details><summary>hint</summary>

SET LOCAL inside a transaction keeps the override local to the test.

</details>

### T14-07 — The missing index, measured

🟠 advanced · `index design, buffers, before/after measurement`

Explain "revenue per seller per month" before adding idx_order_items_seller_order, note the sequential scan, then apply db/perf/optional_indexes.sql (make indexes) and compare.

<details><summary>hint</summary>

Watch shared read/hit buffer counts, not just time.

</details>

### T14-08 — Sort avoidance with a matching index

🟠 advanced · `ORDER BY pushdown, Sort nodes, work_mem spills`

Explain a top-N query ordered by (category_id, base_price DESC) and determine whether the plan sorts or walks an index in order.

<details><summary>hint</summary>

idx_products_cat_price in the optional file matches this ORDER BY; without it you get a Sort node (possibly an external merge sort).

</details>

### T14-09 — Rewrite a correlated subquery as a join

🟠 advanced · `query rewriting, correlated subquery cost, pre-aggregation`

Two queries return per-user order counts for 200 users: one with a correlated scalar subquery, one with a pre-aggregated join. Explain both and compare.

<details><summary>hint</summary>

The correlated form re-executes per row; the join aggregates once.

</details>

### T14-10 — OR predicates and bitmap index combination

🟠 advanced · `BitmapOr, OR rewriting, selectivity`

Explain a filter with OR across two indexed columns and observe BitmapOr; then rewrite it as a UNION ALL of two sargable branches and compare.

<details><summary>hint</summary>

Bitmap Index Scan + BitmapOr is often fine; UNION ALL helps when one branch is far more selective.

</details>

### T14-11 — Statistics and mis-estimation

🟠 advanced · `CREATE STATISTICS, dependencies, estimate error`

Explain a query filtering on two correlated columns (status + channel) and compare the row estimate with the actual. Extended statistics (stat_orders_status_channel) already exist — drop them in a transaction to see the difference.

<details><summary>hint</summary>

Without multivariate stats the planner multiplies selectivities and underestimates correlated predicates.

</details>

### T14-12 — LIMIT changes the optimal plan

🟠 advanced · `startup vs total cost, LIMIT-aware planning`

Explain the same ordered query with LIMIT 10 and without a limit, and explain why the planner may switch from a sort to an index walk.

<details><summary>hint</summary>

With a small LIMIT the startup cost dominates; without it the total cost does.

</details>

### T14-13 — Parallel query

🔴 expert · `parallel plans, Gather, worker accounting`

Explain a large aggregate with parallelism enabled and then with max_parallel_workers_per_gather = 0, comparing Gather nodes and runtime.

<details><summary>hint</summary>

Watch "Workers Launched" and the per-worker loop counts.

</details>

### T14-14 — CTE inlining vs materialization

🔴 expert · `CTE inlining, predicate pushdown, optimisation fences`

Explain the same query twice: with a NOT MATERIALIZED CTE (inlined, filter pushed down) and with MATERIALIZED (full CTE computed first).

<details><summary>hint</summary>

Since Postgres 12 single-use CTEs are inlined unless you say MATERIALIZED.

</details>

### T14-15 — Find the expensive queries with pg_stat_statements

🔴 expert · `pg_stat_statements, workload analysis`

Return the 10 statements with the highest total execution time, excluding this query itself. Columns: calls, total_ms (2 decimals), mean_ms (2 decimals), rows, query_snippet (first 70 chars).

<details><summary>hint</summary>

pg_stat_statements is preloaded; reset it with pg_stat_statements_reset() before a measurement run.

</details>

### T14-16 — Index bloat and usage audit

🔴 expert · `index usage statistics, pruning unused indexes`

List indexes on shop and analytics tables that have never been used (idx_scan = 0), with their size. Columns: schema_name, table_name, index_name, index_size, idx_scan. Order by size DESC, limit 20.

<details><summary>hint</summary>

pg_stat_user_indexes joined to pg_relation_size.

</details>

### T14-17 — Table and index size breakdown

🔴 expert · `storage accounting, TOAST, size functions`

For the 10 largest tables in shop/analytics/hr, return table_name, heap size, index size, toast size and total, all human readable.

<details><summary>hint</summary>

pg_table_size, pg_indexes_size, pg_total_relation_size.

</details>

### T14-18 — Rewrite a slow top-N-per-group query

🔴 expert · `top-N-per-group strategies, plan comparison`

Compare three ways to get each seller's single best-selling product: window function, DISTINCT ON, and LATERAL. Explain all three.

<details><summary>hint</summary>

DISTINCT ON and LATERAL can stop early with the right index; the window function must rank every row.

</details>
