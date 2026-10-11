# 12. Dates, time zones & time series

**3** basic, **4** intermediate, **5** advanced, **4** expert — 16 exercises

```bash
make new Q=T12-01                 # scaffold work/T12-01.sql
make diff Q=T12-01 F=work/T12-01.sql   # grade your answer
make run Q=T12-01                 # see the reference result
make explain Q=T12-01             # see the plan
```

---

### T12-01 — Truncate and extract

🟢 basic · `date_trunc, extract`

For the 10 lowest order_ids, return order_id, placed_at, the month start, the ISO day of week and the hour. Columns: order_id, placed_at, month_start, isodow, hour.

<details><summary>hint</summary>

date_trunc('month', ...), extract(isodow ...), extract(hour ...).

</details>

### T12-02 — Interval arithmetic

🟢 basic · `interval subtraction, half-open ranges`

Count orders placed in the 7 days before 2025-07-01 (exclusive end).

<details><summary>hint</summary>

placed_at >= timestamptz '2025-07-01+00' - interval '7 days'.

</details>

### T12-03 — Age and duration

🟢 basic · `interval to numeric, floor`

For the 10 lowest shipment_ids that were delivered, return shipment_id, shipped_at, delivered_at and transit_days (integer days, rounded down). Columns as named.

<details><summary>hint</summary>

delivered_at - shipped_at gives an interval; extract(epoch ...)/86400 then floor it.

</details>

### T12-04 — Daily series with gap filling

🟡 intermediate · `generate_series, LEFT JOIN, dense time series`

For 2025-02, return every day with the number of paid orders, zero where none. Columns: day, orders. Order by day.

<details><summary>hint</summary>

generate_series LEFT JOIN the aggregate, or LEFT JOIN analytics.calendar.

</details>

### T12-05 — Weekly buckets

🟡 intermediate · `date_trunc week, ISO weeks`

Count orders per ISO week for Q1 2025. Columns: week_start, orders. Order by week_start.

<details><summary>hint</summary>

date_trunc('week', ...) starts weeks on Monday.

</details>

### T12-06 — Arbitrary bucket width with date_bin

🟡 intermediate · `date_bin, fixed-width time bucketing`

Bucket page_events of 2025-03-01 into 15-minute bins and return the 10 busiest bins. Columns: bin, events.

<details><summary>hint</summary>

date_bin(interval '15 minutes', occurred_at, timestamptz '2025-03-01+00').

</details>

### T12-07 — Time zone conversion

🟡 intermediate · `AT TIME ZONE, timestamptz vs timestamp`

For the 10 lowest order_ids, show placed_at in UTC and in 'Asia/Tokyo' and 'America/New_York' local time. Columns: order_id, utc_time, tokyo_time, ny_time.

<details><summary>hint</summary>

timestamptz AT TIME ZONE 'zone' yields a timestamp without time zone in that zone.

</details>

### T12-08 — Business-day bucketing with the calendar table

🟠 advanced · `calendar dimension, join on date, conditional grouping`

For March 2025, count paid orders on weekdays vs weekends using analytics.calendar. Columns: day_kind, orders, revenue (2 decimals).

<details><summary>hint</summary>

Join orders to calendar on the date and group by is_weekend.

</details>

### T12-09 — Holiday-aware SLA

🟠 advanced · `calendar flags, interval averaging, NULL exclusion`

For support tickets opened in 2025, compute the average first-response time in hours, split by whether the ticket was opened on a holiday. Columns: on_holiday, tickets, avg_hours (2 decimals).

<details><summary>hint</summary>

Join analytics.calendar and use is_holiday; ignore tickets that never got a response.

</details>

### T12-10 — Month-end and month-start edge cases

🟠 advanced · `month boundaries, end-of-month arithmetic`

For each month of 2025, return month_start, month_end (last day) and days_in_month. Order by month_start.

<details><summary>hint</summary>

month_start + interval '1 month' - interval '1 day' gives the last day; subtracting dates gives an integer number of days.

</details>

### T12-11 — Hour-of-day heatmap

🟠 advanced · `multi-dimensional time grouping, heatmap data`

For 2025 paid orders, produce a weekday x hour count matrix in long format: isodow, hour, orders. Keep only cells with more than 400 orders. Order by isodow, hour.

<details><summary>hint</summary>

Group by two extracted parts at once.

</details>

### T12-12 — Rolling 7-day window by date range

🟠 advanced · `RANGE frame with interval offset, rolling windows`

For March 2025, return each day with the sum of paid revenue over the trailing 7 days (including the day itself). Columns: day, rev_7d (2 decimals). Order by day.

<details><summary>hint</summary>

A RANGE frame over a date column: RANGE BETWEEN '6 days' PRECEDING AND CURRENT ROW — note that RANGE on dates uses interval offsets.

</details>

### T12-13 — Overlapping shifts per day

🔴 expert · `temporal overlap counting, non-equi join`

For 2025-02-03, count how many shifts were in progress at each hour boundary (00:00..23:00) across all employees. Columns: hour_start, active_shifts. Order by hour_start.

<details><summary>hint</summary>

CROSS JOIN the hours with shifts and test started_at <= hour_start < ended_at.

</details>

### T12-14 — Time to first event per entity

🔴 expert · `first-event latency, percentile_cont, join on aggregate`

For users who signed up in 2024, compute the median hours between signup and their first page_event (users with no event are excluded). Columns: users, median_hours (2 decimals).

<details><summary>hint</summary>

Get min(occurred_at) per user, join to signup_at, then percentile_cont over the hour differences.

</details>

### T12-15 — Fiscal year reporting

🔴 expert · `fiscal calendars, modular arithmetic on months`

Using analytics.calendar.fiscal_year (February start), return revenue per fiscal year and fiscal quarter for paid orders. Columns: fiscal_year, fiscal_quarter, revenue (2 decimals). Order by fiscal_year, fiscal_quarter.

<details><summary>hint</summary>

Derive the fiscal quarter from the month offset: ((month - 2 + 12) % 12) / 3 + 1.

</details>

### T12-16 — DST-safe daily bucketing in a local zone

🔴 expert · `DST handling, local-day bucketing, AT TIME ZONE ordering`

Count orders per local calendar day in 'Europe/Berlin' for the week around the 2025 spring DST change (2025-03-23..2025-03-31). Columns: local_day, orders. Order by local_day.

<details><summary>hint</summary>

date_trunc('day', placed_at AT TIME ZONE 'Europe/Berlin') buckets by local wall-clock days; truncating the timestamptz directly would bucket by UTC and split the DST day wrongly.

</details>
