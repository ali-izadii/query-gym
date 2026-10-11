# 06. Window functions II: gaps/islands, funnels, cohorts

**1** intermediate, **8** advanced, **7** expert — 16 exercises

```bash
make new Q=T06-01                 # scaffold work/T06-01.sql
make diff Q=T06-01 F=work/T06-01.sql   # grade your answer
make run Q=T06-01                 # see the reference result
make explain Q=T06-01             # see the plan
```

---

### T06-01 — Find gaps in a sequence

🟡 intermediate · `lead, gap detection`

In order_items, find the 10 smallest gaps in the order_item_id sequence: return gap_start (last id before the gap) and gap_end (next id present), only where the difference is greater than 1. Order by gap_start.

<details><summary>hint</summary>

lead(order_item_id) over the ordered ids, then filter next - current > 1.

</details>

### T06-02 — Islands of consecutive days (classic gaps-and-islands)

🟠 advanced · `gaps and islands, row_number offset trick`

For employee_id 3, collapse hr.shifts into streaks of consecutive shift_dates. Return streak_start, streak_end, days. Order by streak_start.

<details><summary>hint</summary>

The trick: shift_date - row_number()*1day is constant inside a streak. Group by that constant.

</details>

### T06-03 — Longest streak per employee

🟠 advanced · `gaps and islands per partition, DISTINCT ON`

For employees 3, 6 and 9, return the longest consecutive-day shift streak each: employee_id, days, streak_start. Order by employee_id.

<details><summary>hint</summary>

Build islands per employee (PARTITION BY employee_id), then take the max streak per employee with DISTINCT ON or a second window.

</details>

### T06-04 — Islands over a status change (change-point detection)

🟠 advanced · `change detection with lag, running sum as group label`

For order_ids 1..200 ordered by order_id, group consecutive orders that share the same status into runs. Return run_start_order, status, run_length for runs of length >= 2, ordered by run_start_order.

<details><summary>hint</summary>

Compare each row's status with lag(); a change starts a new group, so a running sum of "is_change" labels the runs.

</details>

### T06-05 — Sessionisation with a 30-minute inactivity timeout

🟠 advanced · `sessionisation, lag on timestamps, running sum`

For page_events of 2025-03-01, split each session_id's events into sub-sessions whenever the gap between consecutive events exceeds 30 minutes. Return the 15 session_ids with the most sub-sessions: session_id, sub_sessions, events.

<details><summary>hint</summary>

lag(occurred_at) per session; flag gaps > interval '30 min'; running sum of flags = sub-session number.

</details>

### T06-06 — Time between consecutive orders per customer

🟠 advanced · `lag per partition, interval to numeric conversion`

For users with at least 5 paid orders, return user_id, orders and the average days between consecutive orders (2 decimals) as avg_gap_days. Show the 15 smallest average gaps.

<details><summary>hint</summary>

lag(placed_at) within each user, then average the differences.

</details>

### T06-07 — First and last event of each session

🟠 advanced · `first_value, last_value, DISTINCT ON alternative`

For 10 sessions (lowest session_id) with at least 3 events on 2025-03-01, return session_id, first_event, last_event (the event_type values) and events.

<details><summary>hint</summary>

first_value / last_value with a full frame, or min/max FILTER with row_number — compare both.

</details>

### T06-08 — Funnel conversion per step

🟠 advanced · `funnel analysis, lag over an ordered dimension`

Using analytics.page_events for March 2025, count distinct sessions reaching each funnel step (view, search, add_to_cart, checkout, purchase) and the conversion rate versus the previous step (4 decimals). Columns: step, sessions, step_conv. Keep funnel order.

<details><summary>hint</summary>

Count per event_type, then lag() over the manually ordered steps.

</details>

### T06-09 — LOCF — carry the last known FX rate forward

🟠 advanced · `last observation carried forward, counting non-NULLs as group id`

analytics.fx_rates has weekend and random gaps. For EUR in January 2025, produce one row per calendar day with the last known rate. Columns: day, rate (the carried value). Order by day.

<details><summary>hint</summary>

LEFT JOIN the calendar to the rates, then use a window: last value IGNORE NULLS is not available, so use max(rate) OVER (ORDER BY day ROWS UNBOUNDED PRECEDING) on a grouped "block id" built from count(rate) OVER (ORDER BY day).

</details>

### T06-10 — Signup cohorts and monthly retention

🔴 expert · `cohort analysis, month arithmetic, distinct counting`

For users who signed up in 2024, build cohort retention: cohort_month, month_offset (0..n, months since signup where the user placed an order), users (distinct buyers). Keep offsets 0..3 and order by cohort_month, month_offset.

<details><summary>hint</summary>

Floor both dates to months, then compute the month difference with EXTRACT on an age() or with a direct arithmetic expression.

</details>

### T06-11 — Retention as a percentage of the cohort

🔴 expert · `window over cohort, ratio to partition total`

Extend the previous result: add cohort_size and retention_pct (users / cohort_size, 4 decimals) for offsets 0..3 of 2024 cohorts.

<details><summary>hint</summary>

Compute cohort_size with a window over the cohort partition, or join a separate per-cohort count.

</details>

### T06-12 — Rank within partition and keep ties

🔴 expert · `rank vs row_number for ties`

Per category, list every active product whose price ties for the highest in that category (so ties are all kept). Return category_id, product_id, base_price for categories 49..60, ordered by category_id, product_id.

<details><summary>hint</summary>

rank() = 1 keeps ties; row_number() = 1 would drop them.

</details>

### T06-13 — Second purchase latency

🔴 expert · `row_number pivoting, conditional aggregation, percentile_cont`

For users whose first two paid orders are known, compute the days between order #1 and order #2. Return the overall median and average (2 decimals) as median_days, avg_days.

<details><summary>hint</summary>

row_number() per user ordered by placed_at, pivot rows 1 and 2 with FILTER, then aggregate.

</details>

### T06-14 — Cumulative distinct count (approximate running reach)

🔴 expert · `first-event-per-entity, running sum, cumulative reach`

For March 2025, per day: new_buyers = users whose FIRST ever paid order happened that day, and a running total of them. Columns: day, new_buyers, cumulative_buyers. Order by day.

<details><summary>hint</summary>

Compute each user's first order date once, then aggregate by that date and apply a running sum.

</details>

### T06-15 — Year-over-year comparison with a 12-month lag

🔴 expert · `lag with offset, year-over-year`

Monthly paid revenue for 2024–2025 with revenue_ly (12 months earlier) and yoy_pct (2 decimals). Columns: month, revenue, revenue_ly, yoy_pct. Order by month.

<details><summary>hint</summary>

lag(revenue, 12) works only if every month is present — the series is dense here, but in general join on month - interval '1 year'.

</details>

### T06-16 — Top-N with "others" rollup

🔴 expert · `top-N plus remainder, UNION ALL, custom ordering`

Top 5 sellers by revenue, plus one extra row named 'OTHERS' holding the summed revenue of everyone else. Columns: seller_label, revenue. Order: the 5 sellers by revenue DESC, 'OTHERS' last.

<details><summary>hint</summary>

Rank sellers in a CTE, then UNION ALL the aggregate of rank > 5. Use a sort key column to force OTHERS to the bottom.

</details>
