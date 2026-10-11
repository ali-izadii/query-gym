# 05. Window functions I: ranking, offsets, frames

**5** basic, **6** intermediate, **7** advanced, **2** expert — 20 exercises

```bash
make new Q=T05-01                 # scaffold work/T05-01.sql
make diff Q=T05-01 F=work/T05-01.sql   # grade your answer
make run Q=T05-01                 # see the reference result
make explain Q=T05-01             # see the plan
```

---

### T05-01 — row_number over the whole set

🟢 basic · `row_number, OVER, ORDER BY in window`

Return the 10 most expensive active products with a 1-based rank column rn, plus product_id, title, base_price.

<details><summary>hint</summary>

row_number() OVER (ORDER BY base_price DESC, product_id).

</details>

### T05-02 — Aggregate as a window function

🟢 basic · `OVER (), window vs group aggregate`

For the 10 lowest order_ids, show order_id, grand_total and the grand total of ALL orders (same value on every row) as total_all.

<details><summary>hint</summary>

sum(grand_total) OVER () — an empty OVER means "whole result set".

</details>

### T05-03 — Share of total per row

🟢 basic · `window over aggregated rows, ratio to total`

For the top 10 categories by revenue, show category_id, revenue and pct_of_total (share of the 10 shown rows' revenue, 2 decimals).

<details><summary>hint</summary>

Aggregate first, then divide by sum(revenue) OVER ().

</details>

### T05-04 — PARTITION BY

🟢 basic · `PARTITION BY, window aggregate`

For products in categories 49 and 50, show category_id, product_id, base_price and the average base_price *within that category* (2 decimals) as cat_avg. Order by category_id, product_id. Limit 20.

<details><summary>hint</summary>

avg(...) OVER (PARTITION BY category_id).

</details>

### T05-05 — rank vs dense_rank vs row_number

🟢 basic · `rank, dense_rank, row_number`

Rank order statuses by their order count three ways. Columns: status, orders, rnk, dense_rnk, rn. Order by orders DESC.

<details><summary>hint</summary>

rank() leaves gaps after ties, dense_rank() does not, row_number() never ties.

</details>

### T05-06 — Top-N per partition

🟡 intermediate · `top-N per group, filtering on a window result`

For categories 49–53, return the 2 most expensive active products per category: category_id, product_id, base_price, rn. Order by category_id, rn.

<details><summary>hint</summary>

Rank inside a subquery, then filter rn <= 2 outside — window functions cannot appear in WHERE.

</details>

### T05-07 — lag — difference from the previous row

🟡 intermediate · `lag, month-over-month delta`

For monthly revenue in 2025, show month, revenue, prev_revenue and mom_change (revenue - prev_revenue). Order by month.

<details><summary>hint</summary>

lag(revenue) OVER (ORDER BY month).

</details>

### T05-08 — lead with a default

🟡 intermediate · `lead, offset and default arguments`

Same monthly series: show month, revenue and next_revenue, using 0 when there is no next month. Order by month.

<details><summary>hint</summary>

lead(revenue, 1, 0) OVER (ORDER BY month).

</details>

### T05-09 — Percent change with growth rate

🟡 intermediate · `lag, percentage change, NULLIF`

Monthly revenue for 2024–2025 with pct_change versus the previous month, 2 decimals, NULL for the first month. Columns: month, revenue, pct_change.

<details><summary>hint</summary>

Divide by the lagged value and guard it with NULLIF.

</details>

### T05-10 — Running total (default frame)

🟡 intermediate · `running total, default window frame`

For daily revenue in January 2025, show day, revenue and a running total running_rev. Order by day.

<details><summary>hint</summary>

sum(...) OVER (ORDER BY day) uses RANGE UNBOUNDED PRECEDING TO CURRENT ROW by default.

</details>

### T05-11 — Running total per partition, reset each month

🟡 intermediate · `PARTITION BY + ORDER BY, resetting accumulators`

For daily revenue in Q1 2025, show day, revenue and running_in_month that restarts at the beginning of every month.

<details><summary>hint</summary>

PARTITION BY date_trunc('month', day) combined with ORDER BY day.

</details>

### T05-12 — Moving average with a ROWS frame

🟠 advanced · `ROWS frame, moving average`

Daily revenue for Q1 2025 plus a centred 7-day moving average (3 preceding, current, 3 following), 2 decimals, as ma7.

<details><summary>hint</summary>

ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING.

</details>

### T05-13 — ROWS vs RANGE with duplicate keys

🟠 advanced · `ROWS vs RANGE, peer rows`

Using order_items of order_id 100..120, compare sum(line_total) OVER (ORDER BY order_id ROWS UNBOUNDED PRECEDING) with the same using RANGE. Columns: order_id, line_total, rows_sum, range_sum. Order by order_id, order_item_id.

<details><summary>hint</summary>

RANGE groups peer rows (equal ORDER BY key) together, so every peer sees the whole group; ROWS counts physical rows.

</details>

### T05-14 — GROUPS frame

🟠 advanced · `GROUPS frame mode`

For the same slice, compute sum(line_total) over a frame of the current peer group plus the previous one: GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW. Columns: order_id, order_item_id, line_total, groups_sum.

<details><summary>hint</summary>

GROUPS counts peer groups, not rows — Postgres 11+.

</details>

### T05-15 — first_value / last_value done right

🟠 advanced · `first_value, last_value, explicit frame`

For categories 49–51, show category_id, product_id, base_price, the cheapest and the most expensive price in the category (cheapest_in_cat, priciest_in_cat). Order by category_id, base_price.

<details><summary>hint</summary>

last_value() with the default frame only sees up to the current row; widen the frame to ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.

</details>

### T05-16 — nth_value and named WINDOW clause

🟠 advanced · `nth_value, WINDOW clause, NULLS LAST in windows`

Per seller tier, return tier, seller_id, rating and the 2nd highest rating within the tier as second_best. Use a named window. Limit 20 rows ordered by tier, rating DESC NULLS LAST.

<details><summary>hint</summary>

WINDOW w AS (...) can be reused by several window calls.

</details>

### T05-17 — ntile buckets

🟠 advanced · `ntile, quartiles, bucketed aggregation`

Split users with at least one order into 4 revenue quartiles. Return quartile, users, min_revenue, max_revenue (2 decimals). Order by quartile.

<details><summary>hint</summary>

ntile(4) OVER (ORDER BY revenue) inside a CTE, aggregate outside.

</details>

### T05-18 — percent_rank and cume_dist

🟠 advanced · `percent_rank, cume_dist, distribution functions`

For the 20 sellers with the highest rating, show seller_id, rating, percent_rank and cume_dist (4 decimals) over all rated sellers.

<details><summary>hint</summary>

Compute the window over the full set first, then take the top 20.

</details>

### T05-19 — Window over a window (two passes)

🔴 expert · `multiple windows in one query`

Per month of 2025: revenue, the running total, and each month's share of the year's total (2 decimals). Columns: month, revenue, running_rev, pct_of_year.

<details><summary>hint</summary>

One window can be ORDER BY-based and another empty — both evaluated in the same SELECT.

</details>

### T05-20 — Deduplicate with row_number

🔴 expert · `deduplication, row_number, PARTITION BY multiple columns`

shop.reviews can contain several reviews by the same user for the same product. Keep only the most recent one per (user_id, product_id) and return the 15 lowest review_ids kept, with user_id and product_id.

<details><summary>hint</summary>

row_number() partitioned by both keys, ordered by created_at DESC, then keep rn = 1.

</details>
