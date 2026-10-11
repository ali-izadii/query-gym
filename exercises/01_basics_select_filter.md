# 01. Basics: SELECT, WHERE, NULL, ORDER BY

**10** basic, **6** intermediate — 16 exercises

```bash
make new Q=T01-01                 # scaffold work/T01-01.sql
make diff Q=T01-01 F=work/T01-01.sql   # grade your answer
make run Q=T01-01                 # see the reference result
make explain Q=T01-01             # see the plan
```

---

### T01-01 — Active products with a price range

🟢 basic · `WHERE, BETWEEN, ORDER BY, LIMIT`

List product_id, title and base_price for active products priced between 100 and 200 inclusive. Order by base_price descending, then product_id ascending. Return the 20 most expensive.

<details><summary>hint</summary>

BETWEEN is inclusive on both sides; combine ORDER BY with LIMIT.

</details>

### T01-02 — Users who never logged in

🟢 basic · `NULL semantics, IS NULL, count(*)`

Count users whose last_login_at is unknown. Return a single column named never_logged_in.

<details><summary>hint</summary>

NULL is never equal to anything, not even NULL. Use IS NULL.

</details>

### T01-03 — Distinct order channels

🟢 basic · `DISTINCT, ORDER BY`

List the distinct channels orders arrive through, alphabetically.

<details><summary>hint</summary>

DISTINCT applies to the whole select list, not one column.

</details>

### T01-04 — Soft-deleted vs live users

🟢 basic · `FILTER clause, conditional aggregation, NULL`

Return two columns: live_users (deleted_at IS NULL) and deleted_users (deleted_at IS NOT NULL) as a single row.

<details><summary>hint</summary>

count(expr) ignores NULLs, or use count(*) FILTER (WHERE ...).

</details>

### T01-05 — Sellers in a set of countries

🟢 basic · `IN, boolean column, ORDER BY`

List seller_id and display_name of non-suspended sellers located in Germany, France or Italy, ordered by seller_id.

<details><summary>hint</summary>

IN (...) beats a chain of ORs for readability.

</details>

### T01-06 — Coalesce a missing rating

🟢 basic · `coalesce, NULL substitution`

For the first 15 sellers by seller_id, show seller_id, rating, and a column rating_display that prints the rating or 0.00 when it is NULL.

<details><summary>hint</summary>

coalesce(rating, 0) — mind the numeric type so both branches match.

</details>

### T01-07 — Orders placed in a window

🟢 basic · `timestamptz range filter, sargable predicates`

Count orders placed in March 2025 (UTC).

<details><summary>hint</summary>

Prefer a half-open range (>= start AND < next month) over casting the timestamp to a date, so an index on placed_at stays usable.

</details>

### T01-08 — Cheapest three variants per SKU prefix

🟢 basic · `ORDER BY, LIMIT, tie-breaking`

Show sku, variant_name and price_delta for the 10 variants with the smallest price_delta, breaking ties by sku.

<details><summary>hint</summary>

ORDER BY two keys, then LIMIT.

</details>

### T01-09 — NULL-safe comparison of two columns

🟢 basic · `IS NOT DISTINCT FROM, three-valued logic`

Count orders where paid_at and cancelled_at are "the same" in the NULL-safe sense (both NULL, or equal values). Name the column both_unset.

<details><summary>hint</summary>

IS NOT DISTINCT FROM treats NULL = NULL as true.

</details>

### T01-10 — Derived columns and aliases

🟢 basic · `expressions, NULLIF, round, division by zero`

For 10 orders with the highest grand_total, show order_id, item_total, discount_total, and discount_pct = discount_total / item_total rounded to 2 decimals. Guard against division by zero.

<details><summary>hint</summary>

NULLIF(item_total, 0) turns a zero denominator into NULL.

</details>

### T01-11 — Pagination that does not drift

🟡 intermediate · `OFFSET/LIMIT pagination, stable sort keys`

Return page 3 (25 rows per page) of active products ordered by base_price DESC, product_id DESC — using OFFSET. Then note in your own query why keyset pagination is preferable.

<details><summary>hint</summary>

OFFSET 50 LIMIT 25. OFFSET still reads and discards the skipped rows.

</details>

### T01-12 — Keyset (cursor) pagination

🟡 intermediate · `row-value comparison, keyset pagination`

Continue the previous listing after the row (base_price = 1500.00, product_id = 9999): return the next 25 active products in the same order without OFFSET.

<details><summary>hint</summary>

Compare the whole sort key as a row value: (base_price, product_id) < (1500.00, 9999).

</details>

### T01-13 — CASE buckets

🟡 intermediate · `CASE, GROUP BY expression, custom sort order`

Bucket every product into 'budget' (< 50), 'mid' (50–299), 'premium' (300–999) and 'luxury' (>= 1000) by base_price, and count products per bucket. Order buckets from cheapest to most expensive.

<details><summary>hint</summary>

Use a CASE expression in both SELECT and GROUP BY, or GROUP BY the alias's ordinal position. Control the output order with a second CASE.

</details>

### T01-14 — DISTINCT ON — one row per group

🟡 intermediate · `DISTINCT ON, Postgres-specific top-1-per-group`

For each seller_id, return the single most expensive active product (product_id, title, base_price). Order the output by seller_id.

<details><summary>hint</summary>

DISTINCT ON (seller_id) requires ORDER BY to start with seller_id.

</details>

### T01-15 — Boolean logic precedence trap

🟡 intermediate · `operator precedence, boolean predicates`

Count orders that are (paid OR delivered) AND came from the 'ios' channel. Verify that dropping the parentheses changes the answer.

<details><summary>hint</summary>

AND binds tighter than OR; parenthesise the OR group.

</details>

### T01-16 — Ordering with NULLs placed explicitly

🟡 intermediate · `NULLS FIRST/LAST, ORDER BY defaults`

List the 15 sellers with the highest rating, but show unrated sellers (NULL rating) last. Return seller_id, display_name, rating.

<details><summary>hint</summary>

ORDER BY rating DESC NULLS LAST. In Postgres DESC defaults to NULLS FIRST, which would put unrated sellers on top.

</details>
