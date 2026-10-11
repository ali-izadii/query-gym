# 03. Aggregation: GROUP BY, HAVING, FILTER, percentiles

**5** basic, **6** intermediate, **6** advanced, **1** expert — 18 exercises

```bash
make new Q=T03-01                 # scaffold work/T03-01.sql
make diff Q=T03-01 F=work/T03-01.sql   # grade your answer
make run Q=T03-01                 # see the reference result
make explain Q=T03-01             # see the plan
```

---

### T03-01 — Orders and revenue per status

🟢 basic · `GROUP BY, sum, count`

Per order status, return orders (row count) and revenue (sum of grand_total), ordered by revenue DESC.

<details><summary>hint</summary>

GROUP BY status; sum() ignores NULLs.

</details>

### T03-02 — Average rating per product, rounded

🟢 basic · `avg, count, GROUP BY, ORDER BY aggregate`

For the 15 products with the most root reviews, return product_id, review_count and avg_rating rounded to 2 decimals.

<details><summary>hint</summary>

avg() returns numeric here; round(avg(x), 2) works directly.

</details>

### T03-03 — HAVING filters groups, WHERE filters rows

🟢 basic · `HAVING, GROUP BY`

List countries with more than 1200 users: country_code and users, ordered by users DESC.

<details><summary>hint</summary>

Row-level predicates go in WHERE; aggregate predicates in HAVING.

</details>

### T03-04 — min, max, span

🟢 basic · `min/max, interval arithmetic`

Return the earliest and latest placed_at in shop.orders and the span between them as days (integer). Columns: first_order, last_order, span_days.

<details><summary>hint</summary>

Subtracting timestamptz values gives an interval; extract the days with EXTRACT(DAY FROM ...) or divide by interval '1 day'.

</details>

### T03-05 — COUNT variants

🟢 basic · `count(*), count(col), count(DISTINCT)`

Return count_star, count_rating (non-NULL ratings) and count_distinct_rating from shop.reviews.

<details><summary>hint</summary>

count(*) counts rows; count(col) skips NULLs; count(DISTINCT col) deduplicates.

</details>

### T03-06 — Conditional aggregation with FILTER

🟡 intermediate · `FILTER, ratio of aggregates`

Per channel, return orders, delivered, cancelled and cancel_rate (cancelled / orders, 4 decimals), ordered by orders DESC.

<details><summary>hint</summary>

count(*) FILTER (WHERE ...) is cleaner than sum(CASE WHEN ...).

</details>

### T03-07 — Multi-level grouping

🟡 intermediate · `GROUP BY multiple keys, join before aggregating`

Revenue per (region, channel) for paid-or-later orders. Columns: region, channel, orders, revenue. Order by region, revenue DESC.

<details><summary>hint</summary>

Reuse shop.v_paid_orders, or repeat the status filter.

</details>

### T03-08 — DISTINCT inside an aggregate

🟡 intermediate · `count(DISTINCT), join then aggregate`

Per seller, count distinct buyers and distinct products sold for the 15 sellers with the most distinct buyers. Columns: seller_id, buyers, products_sold.

<details><summary>hint</summary>

count(DISTINCT ...) over the joined order_items/orders rows.

</details>

### T03-09 — Weighted average

🟡 intermediate · `weighted aggregation, ratio of sums`

Compute the overall average unit price weighted by quantity across all order_items (one row). Also return the unweighted average. Columns: weighted_avg_price, plain_avg_price, both rounded to 4 decimals.

<details><summary>hint</summary>

weighted = sum(price*qty)/sum(qty).

</details>

### T03-10 — Aggregating booleans

🟡 intermediate · `bool_or, bool_and, boolean aggregation`

Per seller tier, return sellers, suspended_count, and any_suspended / all_suspended booleans. Order by tier.

<details><summary>hint</summary>

bool_or() and bool_and() aggregate booleans directly.

</details>

### T03-11 — String aggregation

🟡 intermediate · `string_agg, ORDER BY inside aggregate, DISTINCT in aggregate`

For the 10 lowest order_ids that have at least 3 items, return order_id and a comma-separated, alphabetically sorted list of distinct product titles named titles.

<details><summary>hint</summary>

string_agg(DISTINCT p.title, ', ' ORDER BY p.title).

</details>

### T03-12 — Ordered-set aggregates — median and percentiles

🟠 advanced · `percentile_cont, WITHIN GROUP, ordered-set aggregate`

Return the median, p90 and p99 of orders.grand_total, plus the mean, all rounded to 2 decimals.

<details><summary>hint</summary>

percentile_cont(0.5) WITHIN GROUP (ORDER BY grand_total).

</details>

### T03-13 — Discrete percentile and mode

🟠 advanced · `percentile_disc, mode(), ordered-set aggregates`

Per channel, return the discrete median grand_total (an actually occurring value) and the modal order status. Order by channel.

<details><summary>hint</summary>

percentile_disc(0.5) WITHIN GROUP (...) and mode() WITHIN GROUP (ORDER BY status).

</details>

### T03-14 — Statistical aggregates

🟠 advanced · `stddev, variance, derived statistics`

For order_items.unit_price return count, stddev_samp, var_samp and the coefficient of variation (stddev/avg), each rounded to 4 decimals.

<details><summary>hint</summary>

stddev_samp / var_samp; cast to numeric before round().

</details>

### T03-15 — Correlation and regression

🟠 advanced · `corr, regr_slope, regr_r2`

Across order_items, measure how line_total relates to qty: return corr, regr_slope and regr_r2, each rounded to 5 decimals.

<details><summary>hint</summary>

corr(y, x), regr_slope(y, x), regr_r2(y, x) — note the y-first argument order.

</details>

### T03-16 — Aggregate over an aggregate (two-step)

🟠 advanced · `nested aggregation, CTE, avoiding fan-out`

Compute the average number of items per order, and the average order value, per channel. Columns: channel, avg_items, avg_value (2 decimals). Order by channel.

<details><summary>hint</summary>

Aggregate per order first in a CTE, then aggregate that result.

</details>

### T03-17 — Guarding against the empty group

🟠 advanced · `NULL from empty aggregates, coalesce`

Return revenue for status 'returned' in year 2099 as 0 rather than NULL, with a row_count of 0. Columns: revenue, row_count.

<details><summary>hint</summary>

sum() over zero rows yields NULL; count(*) yields 0. Wrap in coalesce.

</details>

### T03-18 — Average of per-group maxima, in one pass

🔴 expert · `two-phase aggregation, percentile_cont`

For each seller, find their single highest-priced order_item line (max line_total), then return the average and median of those maxima. Columns: avg_of_max, median_of_max (2 decimals).

<details><summary>hint</summary>

Group once to get per-seller maxima, then aggregate that set.

</details>
