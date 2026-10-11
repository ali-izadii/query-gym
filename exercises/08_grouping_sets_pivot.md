# 08. GROUPING SETS, ROLLUP, CUBE, pivot

**4** intermediate, **6** advanced, **4** expert — 14 exercises

```bash
make new Q=T08-01                 # scaffold work/T08-01.sql
make diff Q=T08-01 F=work/T08-01.sql   # grade your answer
make run Q=T08-01                 # see the reference result
make explain Q=T08-01             # see the plan
```

---

### T08-01 — ROLLUP for subtotals

🟡 intermediate · `ROLLUP, subtotals, NULL as "all"`

Revenue per (region, channel) with per-region subtotals and a grand total. Columns: region, channel, revenue. Order by region NULLS LAST, channel NULLS LAST.

<details><summary>hint</summary>

GROUP BY ROLLUP (region, channel) adds the aggregate rows with NULL in the rolled-up columns.

</details>

### T08-02 — Distinguish a real NULL from a rollup NULL

🟡 intermediate · `GROUPING(), interpreting aggregate rows`

Same rollup as before, but add a row_kind column saying 'detail', 'region total' or 'grand total'.

<details><summary>hint</summary>

GROUPING(col) returns 1 when the column was rolled up.

</details>

### T08-03 — CUBE for every combination

🟡 intermediate · `CUBE, marginal aggregates`

Orders count by every combination of status and channel (both dimensions, their marginals and the total). Columns: status, channel, orders. Order by status NULLS LAST, channel NULLS LAST.

<details><summary>hint</summary>

GROUP BY CUBE (status, channel) = 2^2 grouping sets.

</details>

### T08-04 — Explicit GROUPING SETS

🟡 intermediate · `GROUPING SETS, independent aggregates in one pass`

In one query return (a) revenue per month and (b) revenue per channel for 2025 — no cross combination. Columns: month, channel, revenue. Order by month NULLS LAST, channel NULLS LAST.

<details><summary>hint</summary>

GROUP BY GROUPING SETS ((month), (channel)).

</details>

### T08-05 — Manual pivot with FILTER

🟠 advanced · `pivot, conditional aggregation, FILTER`

Pivot monthly 2025 revenue by channel into columns: month, web, ios, android, partner_api (2 decimals each). Order by month.

<details><summary>hint</summary>

sum(grand_total) FILTER (WHERE channel = 'web') AS web, etc.

</details>

### T08-06 — Pivot counts with CASE (portable form)

🟠 advanced · `CASE pivot, portability`

Per seller tier, pivot order status counts into columns delivered, shipped, cancelled, returned. Order by tier.

<details><summary>hint</summary>

sum(CASE WHEN ... THEN 1 ELSE 0 END) is the portable equivalent of count(*) FILTER (...).

</details>

### T08-07 — crosstab() from the tablefunc extension

🟠 advanced · `crosstab, tablefunc, dynamic pivot`

Using crosstab, build a matrix of order counts with one row per status and one column per channel (web, ios, android, partner_api). Columns: status, web, ios, android, partner_api. Order by status.

<details><summary>hint</summary>

crosstab(source_sql, category_sql) needs the source ordered by row_name, category_name; declare the output column types explicitly.

</details>

### T08-08 — Unpivot columns into rows

🟠 advanced · `unpivot, LATERAL VALUES, long format`

Turn the order money columns into rows for the 5 lowest order_ids. Columns: order_id, component ('item_total','discount_total', 'shipping_fee','tax_total'), amount. Order by order_id, component.

<details><summary>hint</summary>

A LATERAL VALUES list (or unnest of two arrays) unpivots cleanly.

</details>

### T08-09 — Unpivot with unnest of parallel arrays

🟠 advanced · `unnest multiple arrays, ROWS FROM semantics`

Same unpivot as before, for order_ids 1..3, but built with unnest(ARRAY[...], ARRAY[...]). Columns: order_id, component, amount. Order by order_id, component.

<details><summary>hint</summary>

unnest with multiple arrays zips them row-wise in the FROM clause.

</details>

### T08-10 — Percent of subtotal using ROLLUP output

🟠 advanced · `ROLLUP + window, share of subtotal`

Per region and channel, return revenue and pct_of_region (share of that region's total, 2 decimals), with the region subtotal rows included.

<details><summary>hint</summary>

Compute the rollup in a CTE, then use a window partitioned by region on the detail rows, or divide by the matching subtotal row.

</details>

### T08-11 — Multi-level grouping sets with mixed dimensions

🔴 expert · `GROUPING SETS, labelling aggregate levels`

In one query, return revenue grouped by: (region, channel), (region), (channel) and overall. Columns: region, channel, revenue, level_label. Order by region NULLS LAST, channel NULLS LAST.

<details><summary>hint</summary>

GROUPING SETS ((region,channel),(region),(channel),()) and label with GROUPING().

</details>

### T08-12 — Pivot a dynamic key set from JSONB

🔴 expert · `jsonb_object_agg, dynamic pivot without DDL`

Build a per-device event-type matrix for 2025-03 as JSONB: one row per device with a jsonb object mapping event_type to the count. Columns: device, counts. Order by device.

<details><summary>hint</summary>

jsonb_object_agg(event_type, n) over a pre-aggregated set — a pivot that does not require knowing the keys in advance.

</details>

### T08-13 — Sparse matrix with dense axes

🔴 expert · `dense grid, LEFT JOIN to aggregate, coalesce`

Produce a dense 12x3 matrix of 2025 monthly revenue per region — every month/region pair must appear, with 0 where there were no orders. Columns: month, region, revenue. Order by month, region.

<details><summary>hint</summary>

Build the axes with a CROSS JOIN, then LEFT JOIN the aggregate.

</details>

### T08-14 — Budget vs actual with variance

🔴 expert · `budget vs actual, variance, composite join`

Join analytics.monthly_targets to actual 2025 revenue per region and month. Columns: target_month, region, revenue_target, actual, variance_pct (actual/target - 1, 2 decimals). Order by target_month, region.

<details><summary>hint</summary>

Aggregate actuals per (month, region) first, then join on both keys.

</details>
