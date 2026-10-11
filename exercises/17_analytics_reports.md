# 17. Capstone analytics reports

**9** advanced, **9** expert — 18 exercises

```bash
make new Q=T17-01                 # scaffold work/T17-01.sql
make diff Q=T17-01 F=work/T17-01.sql   # grade your answer
make run Q=T17-01                 # see the reference result
make explain Q=T17-01             # see the plan
```

---

### T17-01 — RFM segmentation

🟠 advanced · `RFM, ntile, composite scoring`

Build an RFM table for users with paid orders: recency_days (since 2026-01-01), frequency (orders), monetary (revenue), plus r_score, f_score, m_score as ntile(5) and rfm (concatenated). Return the 15 best customers (r_score, f_score, m_score all high) ordered by monetary DESC.

<details><summary>hint</summary>

Compute the base metrics in one CTE, then ntile() each; note recency must be reversed (lower days = better score).

</details>

### T17-02 — Customer lifetime value to date

🟠 advanced · `LTV, lifecycle metrics, derived columns`

For the 15 highest-value customers, return user_id, first_order, last_order, orders, revenue, avg_order_value and active_days (last - first). Order by revenue DESC.

<details><summary>hint</summary>

One GROUP BY with min/max/count/sum; derive the rest.

</details>

### T17-03 — Market basket — frequent product pairs

🟠 advanced · `basket analysis, self-join pair generation, co-occurrence`

Find the 15 product pairs most frequently bought in the same order. Columns: product_a, product_b, orders_together.

<details><summary>hint</summary>

Self-join order_items on order_id with product_id < product_id to get unordered pairs once. Restrict to a slice of orders to keep it fast.

</details>

### T17-04 — Lift for a product pair

🟠 advanced · `association rules, lift, probability from counts`

For the single most frequent pair from the previous exercise, compute support_a, support_b, support_ab and lift = P(AB) / (P(A)*P(B)) over the same order slice. Columns: product_a, product_b, support_ab, lift (4 decimals).

<details><summary>hint</summary>

Count the orders containing A, B and both, divided by the total number of orders in the slice.

</details>

### T17-05 — Channel attribution — first vs last touch

🟠 advanced · `attribution models, DISTINCT ON, comparative aggregation`

For converted sessions in 2025, compare revenue attributed to the session channel (last touch) with revenue attributed to the user's first ever session channel (first touch). Columns: channel, last_touch_revenue, first_touch_revenue. Order by channel.

<details><summary>hint</summary>

Last touch is the converting session's own channel; first touch needs each user's earliest session via DISTINCT ON or row_number.

</details>

### T17-06 — Marketing efficiency — CAC and ROAS

🟠 advanced · `multi-source joins on a time key, derived KPIs`

For each month of 2025, combine ad spend with new-customer counts and paid revenue: month, spend, new_customers, cac (spend/new_customers), revenue, roas (revenue/spend). 2 decimals. Order by month.

<details><summary>hint</summary>

Three independent aggregates joined on the month key; guard the divisions with NULLIF.

</details>

### T17-07 — Seller scorecard

🟠 advanced · `multi-fact assembly, avoiding fan-out, KPI composition`

Build a scorecard for the 15 sellers with the most revenue: seller_id, display_name, tier, revenue, orders, units, avg_rating (2 decimals), refund_rate (refunded amount / revenue, 4 decimals).

<details><summary>hint</summary>

Pre-aggregate sales, ratings and refunds separately, then join — a single join would fan out.

</details>

### T17-08 — ABC / Pareto classification

🟠 advanced · `Pareto analysis, cumulative share, bucketing on a window result`

Classify products into A (top 80% of cumulative revenue), B (next 15%) and C (rest). Return the class summary: abc_class, products, revenue (2 decimals), revenue_share (4 decimals). Order by abc_class.

<details><summary>hint</summary>

Rank products by revenue, take a running share with a window, then bucket on the cumulative share.

</details>

### T17-09 — Inventory coverage and reorder alerts

🟠 advanced · `inventory KPIs, rate calculation, NULL-safe division`

For variants whose total on-hand stock is below their reorder point, compute days_of_cover = stock / average daily units sold over the last 90 days of data. Columns: variant_id, stock, reorder_point, daily_units (3 decimals), days_of_cover (1 decimal). Limit 20, worst cover first.

<details><summary>hint</summary>

Aggregate inventory per variant, aggregate sales per variant over the window, then divide with NULLIF.

</details>

### T17-10 — Cart abandonment funnel by device

🔴 expert · `funnel by dimension, join on surrogate key, rate metrics`

For 2025, per device: sessions, carts created, carts converted and abandonment_rate (4 decimals). Columns: device, sessions, carts, converted, abandonment_rate. Order by sessions DESC.

<details><summary>hint</summary>

Carts link to sessions via session_id; aggregate both sides on device taken from analytics.sessions.

</details>

### T17-11 — Churn flag with a rolling definition

🔴 expert · `churn definition, bucketing, cohort summary`

Label every customer as 'active', 'at_risk' or 'churned' based on days since their last paid order relative to 2026-01-01 (<=60 active, 61-180 at_risk, >180 churned) and report counts plus revenue per bucket. Columns: state, customers, revenue (2 decimals). Order by state.

<details><summary>hint</summary>

One CTE for per-user recency and revenue, then a CASE and a GROUP BY.

</details>

### T17-12 — Repeat purchase rate by cohort month

🔴 expert · `repeat purchase metric, FILTER, cohort join`

For 2024 signup cohorts, compute the share of customers who placed at least two paid orders. Columns: cohort_month, customers, repeaters, repeat_rate (4 decimals). Order by cohort_month.

<details><summary>hint</summary>

Count orders per user, join to the cohort, then aggregate with FILTER.

</details>

### T17-13 — Price elasticity proxy

🔴 expert · `per-group median, conditional aggregation, elasticity proxy`

For the 15 products with the most distinct price points, compare units sold at above-median vs below-median price. Columns: product_id, price_points, units_cheap, units_expensive. Order by price_points DESC.

<details><summary>hint</summary>

Compute the per-product median unit_price with a window percentile_cont inside a CTE, then aggregate with FILTER.

</details>

### T17-14 — Seasonality index per month

🔴 expert · `seasonality, two-level aggregation, window over aggregates`

Compute a seasonality index per calendar month: the month's average daily revenue divided by the overall average daily revenue, across all data. Columns: month_of_year, avg_daily_revenue (2 decimals), seasonality_index (3 decimals). Order by month_of_year.

<details><summary>hint</summary>

Aggregate to daily revenue first, then average per calendar month and divide by the grand average with a window.

</details>

### T17-15 — Multi-currency revenue normalised to USD

🔴 expert · `as-of join, LOCF via LATERAL, currency normalisation`

Convert 2025 paid revenue to USD using the FX rate of the order date, carrying the last known rate forward when a date is missing. Columns: currency_code, revenue_native (2 decimals), revenue_usd (2 decimals). Order by revenue_usd DESC.

<details><summary>hint</summary>

For each order find the latest fx_rates row on or before the order date — a correlated LATERAL with ORDER BY rate_date DESC LIMIT 1.

</details>

### T17-16 — SCD2 as-of lookup

🔴 expert · `slowly changing dimensions, as-of joins, temporal correctness`

Using analytics.dim_seller_scd2, report revenue per seller tier *as the tier was on 2024-06-30*. Columns: tier, sellers, revenue (2 decimals). Order by tier.

<details><summary>hint</summary>

Pick the SCD2 row whose validity window contains the as-of date, then join sales.

</details>

### T17-17 — Support SLA breach report

🔴 expert · `SLA modelling, percentiles per group, inline thresholds`

For 2025 tickets, per priority: tickets, median_first_response_hours, p90_first_response_hours and breach_rate where the SLA is 4h for urgent, 12h high, 24h normal, 48h low. 2/4 decimals. Order by priority.

<details><summary>hint</summary>

Put the SLA table inline with VALUES and join on priority; compute percentiles on the response interval in hours.

</details>

### T17-18 — Executive one-row KPI snapshot

🔴 expert · `KPI snapshot, scalar subqueries, reporting layout`

Produce a single row summarising 2025: orders, revenue, aov, active_customers, new_customers, units, refund_amount, cancel_rate. All money values rounded to 2 decimals.

<details><summary>hint</summary>

Use independent scalar subqueries — each one is cheap and the result is a readable single row.

</details>
