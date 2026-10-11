# 02. Joins: inner, outer, anti, self, LATERAL

**6** basic, **6** intermediate, **6** advanced — 18 exercises

```bash
make new Q=T02-01                 # scaffold work/T02-01.sql
make diff Q=T02-01 F=work/T02-01.sql   # grade your answer
make run Q=T02-01                 # see the reference result
make explain Q=T02-01             # see the plan
```

---

### T02-01 — Inner join products to sellers

🟢 basic · `INNER JOIN, ORDER BY, LIMIT`

For 20 products with the highest base_price, show product_id, title, and the seller's display_name. Order by base_price DESC, product_id.

<details><summary>hint</summary>

Join on products.seller_id = sellers.seller_id.

</details>

### T02-02 — Three-table join

🟢 basic · `multi-table join, generated column`

Show order_id, placed_at, user full_name and country_name for the 10 most recent orders.

<details><summary>hint</summary>

orders -> users -> countries.

</details>

### T02-03 — LEFT JOIN keeps unmatched rows

🟢 basic · `LEFT JOIN, NULL from outer join`

Count warehouses, and how many of them have no owning seller (platform-owned). Return columns total_warehouses, platform_owned.

<details><summary>hint</summary>

LEFT JOIN sellers and count rows where the joined key is NULL — or just test warehouses.seller_id IS NULL and compare.

</details>

### T02-04 — Join with an extra filter in ON vs WHERE

🟢 basic · `ON vs WHERE in outer joins`

For the first 20 users by user_id, list user_id and the order_id of their *cancelled* orders, keeping users with no cancelled order (NULL).

<details><summary>hint</summary>

The status test must live in the ON clause; in WHERE it would turn the LEFT JOIN back into an inner join.

</details>

### T02-05 — Count rows per side of a join

🟢 basic · `join cardinality, count DISTINCT`

Return the number of order_items rows, and the number of distinct orders they belong to, as items and orders.

<details><summary>hint</summary>

count(*) vs count(DISTINCT order_id).

</details>

### T02-06 — USING shorthand

🟢 basic · `USING, GROUP BY`

Join order_items to orders on order_id with USING and return order_id, status and sum of line_total for the 10 orders with the largest summed line_total.

<details><summary>hint</summary>

USING (order_id) merges the two columns into one in the output.

</details>

### T02-07 — Anti-join — products never ordered

🟡 intermediate · `anti-join, NOT EXISTS`

Count active products that appear in no order_items row.

<details><summary>hint</summary>

NOT EXISTS is usually the clearest and the planner turns it into an anti-join. Beware NOT IN with NULLable columns.

</details>

### T02-08 — Semi-join — users who reviewed something

🟡 intermediate · `semi-join, EXISTS`

Count distinct users who wrote at least one root review (reply_to IS NULL). Use a semi-join, not a GROUP BY over the join.

<details><summary>hint</summary>

EXISTS stops at the first matching row, so it never duplicates the outer row.

</details>

### T02-09 — Self-join on the referral graph

🟡 intermediate · `self-join, aliasing`

List 20 pairs (referrer_name, referred_name) ordered by the referred user's id, for users who were referred by someone.

<details><summary>hint</summary>

Join shop.users to itself with an alias for each role.

</details>

### T02-10 — Self-join for manager pairs

🟡 intermediate · `self-join, derived expression, ORDER BY`

List employee_id, employee name, manager name and the salary gap (employee salary minus manager salary) for the 15 employees who earn the most *more* than their own manager.

<details><summary>hint</summary>

Inner join hr.employees to itself on manager_id; the CEO drops out.

</details>

### T02-11 — FULL OUTER JOIN to reconcile two sets

🟡 intermediate · `FULL OUTER JOIN, coalesce on join key`

Compare, per day in January 2025, the number of orders placed and the number of converted sessions. Include days present in only one of the two sets. Columns: day, orders, converted_sessions. Order by day.

<details><summary>hint</summary>

Aggregate each side first, then FULL JOIN on the day and use coalesce() for the key and the counts.

</details>

### T02-12 — CROSS JOIN to build a dense grid

🟡 intermediate · `CROSS JOIN, generate_series, dense grids`

Build every (month, region) combination for 2025 — 12 x 3 = 36 rows — with columns month_start and region, ordered by both.

<details><summary>hint</summary>

generate_series CROSS JOIN a VALUES list.

</details>

### T02-13 — LATERAL top-N per group

🟠 advanced · `LATERAL, per-group LIMIT, correlated subquery in FROM`

For the 10 sellers with the lowest seller_id, return up to 3 of their most expensive active products: seller_id, product_id, title, base_price.

<details><summary>hint</summary>

A LATERAL subquery can reference the outer row, so it can carry its own ORDER BY ... LIMIT 3.

</details>

### T02-14 — LEFT JOIN LATERAL keeps empty groups

🟠 advanced · `LEFT JOIN LATERAL, ON true`

Same as the previous exercise, but keep sellers that have no active product at all (their product columns must be NULL). Use the 10 lowest seller_ids among suspended sellers.

<details><summary>hint</summary>

LEFT JOIN LATERAL ... ON true.

</details>

### T02-15 — Range join on a temporal table

🟠 advanced · `range join, daterange containment, temporal tables`

For 25 order_items of orders placed in 2025, show order_item_id, unit_price and the price_history.price that was valid on the order date. Order by order_item_id.

<details><summary>hint</summary>

Join on variant_id AND the order date falling inside [valid_from, valid_to) — containment with @> on the generated daterange is both shorter and index-friendly (GiST).

</details>

### T02-16 — Join fan-out and how to avoid double counting

🟠 advanced · `join fan-out, double counting, pre-aggregation`

For the 10 orders with the most items, return order_id, item_count and shipment_count without multiplying the two counts together.

<details><summary>hint</summary>

Joining both children at once fans out. Aggregate each child separately (two scalar subqueries, or pre-aggregated CTEs) before joining.

</details>

### T02-17 — Multi-column join against a dimension

🟠 advanced · `composite join key, pre-aggregation`

Join ad_spend to a daily order count per country for 2025-06, keeping only rows where both exist. Return spend_date, country_code, cost and orders, ordered by spend_date, country_code. Limit 30.

<details><summary>hint</summary>

The join key is (date, country_code); aggregate the orders side first.

</details>

### T02-18 — Non-equi join — price bands

🟠 advanced · `non-equi join, inline VALUES dimension`

Classify the first 30 active products (lowest product_id) into bands defined by an inline VALUES table of (band, lo, hi) and return product_id, base_price, band.

<details><summary>hint</summary>

Join with base_price >= lo AND base_price < hi — an inequality join.

</details>
