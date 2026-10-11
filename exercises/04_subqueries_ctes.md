# 04. Subqueries & CTEs

**4** basic, **6** intermediate, **5** advanced, **3** expert — 18 exercises

```bash
make new Q=T04-01                 # scaffold work/T04-01.sql
make diff Q=T04-01 F=work/T04-01.sql   # grade your answer
make run Q=T04-01                 # see the reference result
make explain Q=T04-01             # see the plan
```

---

### T04-01 — Scalar subquery in the select list

🟢 basic · `scalar subquery, uncorrelated subquery`

For the 10 lowest product_ids, show product_id, base_price and the overall average base_price (same value on every row) as avg_price, rounded to 2 decimals.

<details><summary>hint</summary>

A subquery returning exactly one row and column can be used as a value.

</details>

### T04-02 — Subquery in WHERE with a computed threshold

🟢 basic · `subquery in WHERE, aggregate threshold`

Count active products priced above the overall average base_price.

<details><summary>hint</summary>

The comparison value itself is a subquery.

</details>

### T04-03 — IN with a subquery

🟢 basic · `IN (subquery), semi-join`

Count orders belonging to users from the APAC region.

<details><summary>hint</summary>

Build the user_id set with a subquery, or just join. Compare plans.

</details>

### T04-04 — Derived table (subquery in FROM)

🟢 basic · `derived table, CASE bucketing`

From a derived table of per-user order counts, return how many users placed exactly 1, 2, 3 and 4+ orders. Columns: bucket, users. Order: '1','2','3','4+'.

<details><summary>hint</summary>

Aggregate inside the subquery, bucket outside.

</details>

### T04-05 — Correlated subquery per row

🟡 intermediate · `correlated subquery, per-row evaluation`

For the 10 lowest seller_ids, show seller_id and their product count using a correlated scalar subquery (not a join).

<details><summary>hint</summary>

The inner query references the outer seller_id.

</details>

### T04-06 — EXISTS vs IN with NULLs

🟡 intermediate · `NOT EXISTS, NULL pitfalls of NOT IN`

Count orders that have NO payment row with status 'captured'.

<details><summary>hint</summary>

NOT EXISTS is NULL-safe; NOT IN against a NULLable column can return zero rows unexpectedly.

</details>

### T04-07 — ANY / ALL quantified comparison

🟡 intermediate · `ANY, ALL, quantified comparisons`

Count products whose base_price is greater than ALL base prices in category 50, and (separately) greater than ANY of them. Columns: gt_all, gt_any.

<details><summary>hint</summary>

> ALL (subquery) and > ANY (subquery). ALL over an empty set is true.

</details>

### T04-08 — Row constructor subquery

🟡 intermediate · `row values, max via subquery`

Find the order_items row with the single largest line_total and return order_item_id, order_id, line_total — matching on the whole tuple.

<details><summary>hint</summary>

WHERE (line_total) = (SELECT max(line_total) ...) or use a row comparison against (SELECT max(...), min(...)).

</details>

### T04-09 — Simple CTE for readability

🟡 intermediate · `WITH clause, date_trunc, GROUP BY`

Using a CTE of 2025 paid orders, return monthly revenue: month (date), orders, revenue. Order by month.

<details><summary>hint</summary>

date_trunc('month', placed_at)::date gives a clean month key.

</details>

### T04-10 — Multiple chained CTEs

🟡 intermediate · `chained CTEs, percentile threshold`

Chain three CTEs: (1) paid orders in 2025, (2) revenue per user, (3) users above the 95th percentile of that revenue. Return user_id and revenue for the top 15 by revenue.

<details><summary>hint</summary>

Later CTEs can reference earlier ones.

</details>

### T04-11 — Correlated subquery vs LATERAL

🟠 advanced · `LATERAL vs correlated scalar subqueries`

For the 10 lowest user_ids that have orders, return user_id, last_order_at and last_order_total. Solve it with a LATERAL subquery returning both columns at once.

<details><summary>hint</summary>

Two correlated scalar subqueries would scan twice; LATERAL fetches the row once.

</details>

### T04-12 — CTE materialization control

🟠 advanced · `MATERIALIZED / NOT MATERIALIZED, CTE inlining`

Count rows of a CTE that filters order_items to line_total > 500, forcing Postgres to materialize it. Column: big_lines.

<details><summary>hint</summary>

Postgres 12+ inlines single-use CTEs; AS MATERIALIZED forces the old behaviour. Compare EXPLAIN with AS NOT MATERIALIZED.

</details>

### T04-13 — Reusing a CTE twice

🟠 advanced · `CTE reuse, UNION ALL, top/bottom N`

From one CTE of per-category revenue, return the top 3 and the bottom 3 categories in a single result with a side column ('top'/'bottom'). Columns: side, category_id, revenue. Order: side, revenue DESC.

<details><summary>hint</summary>

A CTE referenced twice is materialized once; combine the halves with UNION ALL.

</details>

### T04-14 — Semi-join with a composite key

🟠 advanced · `EXISTS with multiple predicates, composite correlation`

Count order_items rows whose (order_id, seller_id) pair also appears in a support ticket's order (i.e. the order has a ticket) for sellers in tier 'platinum'.

<details><summary>hint</summary>

EXISTS can test several correlated conditions at once.

</details>

### T04-15 — Anti-join on two columns

🟠 advanced · `anti-join, DISTINCT subquery`

Count variants that exist in shop.inventory but have never been sold (no order_items row for that variant).

<details><summary>hint</summary>

Two-step: restrict to stocked variants, then NOT EXISTS against order_items.

</details>

### T04-16 — Correlated subquery in HAVING

🔴 expert · `HAVING with subquery, global vs group aggregate`

List sellers whose average order_item line_total exceeds twice the global average line_total. Columns: seller_id, avg_line (2 decimals). Order by avg_line DESC, limit 15.

<details><summary>hint</summary>

The global average is an uncorrelated scalar subquery usable in HAVING.

</details>

### T04-17 — Subquery returning multiple columns via row comparison

🔴 expert · `row-value comparison, correlated min`

Find all orders whose (user_id, placed_at) equals the earliest order of that user — i.e. each user's first order. Return the 10 lowest order_ids with user_id and placed_at.

<details><summary>hint</summary>

Compare a row constructor to a correlated subquery that returns the minimum placed_at per user.

</details>

### T04-18 — Rewriting NOT IN safely

🔴 expert · `NOT IN vs NOT EXISTS, NULL propagation`

Count products whose category_id is not among the categories that have a NULL commission_pct — written so NULLs in the subquery cannot silently empty the result.

<details><summary>hint</summary>

Either add "AND commission_pct IS NULL" semantics carefully, or use NOT EXISTS. Verify by also computing the naive NOT IN variant.

</details>
