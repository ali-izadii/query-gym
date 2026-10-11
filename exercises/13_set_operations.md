# 13. Set operations & reconciliation

**2** basic, **4** intermediate, **4** advanced, **2** expert — 12 exercises

```bash
make new Q=T13-01                 # scaffold work/T13-01.sql
make diff Q=T13-01 F=work/T13-01.sql   # grade your answer
make run Q=T13-01                 # see the reference result
make explain Q=T13-01             # see the plan
```

---

### T13-01 — UNION removes duplicates

🟢 basic · `UNION, deduplication`

Combine the country codes used by users and by sellers into one deduplicated list. Columns: country_code. Order by country_code.

<details><summary>hint</summary>

UNION deduplicates; UNION ALL does not.

</details>

### T13-02 — UNION ALL with a source tag

🟢 basic · `UNION ALL, literal discriminator column`

List 10 rows combining users and sellers from Germany, tagged with their source. Columns: source, id. Order by source, id. Limit 10.

<details><summary>hint</summary>

UNION ALL keeps duplicates and is cheaper — no sort/hash to dedupe.

</details>

### T13-03 — INTERSECT

🟡 intermediate · `INTERSECT, set semantics`

Find product_ids that appear both in a wishlist and in an actual order. Return the 15 lowest such product_ids.

<details><summary>hint</summary>

INTERSECT compares whole rows and deduplicates.

</details>

### T13-04 — EXCEPT

🟡 intermediate · `EXCEPT, anti-set`

Find product_ids that are wishlisted but never ordered. Return the 15 lowest, plus verify the count.

<details><summary>hint</summary>

EXCEPT is the set difference; it also deduplicates.

</details>

### T13-05 — EXCEPT ALL preserves multiplicity

🟡 intermediate · `EXCEPT vs EXCEPT ALL, bag vs set semantics`

Show the difference between EXCEPT and EXCEPT ALL on the same inputs: return cnt_except and cnt_except_all for wishlisted-minus-ordered product_ids.

<details><summary>hint</summary>

EXCEPT ALL subtracts occurrence counts rather than collapsing them.

</details>

### T13-06 — VALUES as an inline table

🟡 intermediate · `VALUES list, inline dimension table`

Join an inline mapping of channel -> friendly label to order counts. Columns: label, orders. Order by orders DESC.

<details><summary>hint</summary>

A VALUES list in a CTE or in FROM behaves like a table.

</details>

### T13-07 — Reconcile two aggregates with FULL JOIN vs set ops

🟠 advanced · `reconciliation, FULL JOIN, IS DISTINCT FROM`

Compare per-status order counts computed from shop.orders with those computed by joining order_items (orders having at least one item). Return statuses where the two differ. Columns: status, from_orders, from_items.

<details><summary>hint</summary>

Aggregate both ways, FULL JOIN on status, filter where the counts differ (NULL-safe with IS DISTINCT FROM).

</details>

### T13-08 — Symmetric difference

🟠 advanced · `symmetric difference, combining set operations`

Compute the symmetric difference between the set of users who have placed an order and the set of users who have written a review: return only_buyers and only_reviewers counts.

<details><summary>hint</summary>

(A EXCEPT B) UNION ALL (B EXCEPT A), or count each side separately.

</details>

### T13-09 — Set operations with multiple columns

🟠 advanced · `multi-column EXCEPT, row comparison`

Find (user_id, product_id) pairs that are wishlisted but were never purchased by that same user. Return the 15 lowest pairs by user_id, product_id.

<details><summary>hint</summary>

Set operators compare the whole row, so project exactly two columns on both sides.

</details>

### T13-10 — Ordering and LIMIT inside set operations

🟠 advanced · `parenthesised set branches, per-branch ORDER BY/LIMIT`

Return the 3 most expensive and the 3 cheapest active products in one result with a side column. Columns: side, product_id, base_price. Order by side, base_price DESC.

<details><summary>hint</summary>

Each branch needs its own parentheses to carry ORDER BY ... LIMIT.

</details>

### T13-11 — Type unification across branches

🔴 expert · `UNION ALL type unification, event feeds`

Build a single audit-ish feed of recent activity: order placed, review written and ticket opened, for the 15 most recent events overall. Columns: happened_at, kind, ref_id.

<details><summary>hint</summary>

Every branch must produce compatible types; cast ids to bigint and use the same timestamp type.

</details>

### T13-12 — Compare two query results row by row

🔴 expert · `query equivalence testing, EXCEPT as assertion`

Verify that shop.v_paid_orders equals the inline status filter: return missing_in_view and extra_in_view counts (both should be 0).

<details><summary>hint</summary>

Two EXCEPT queries in scalar subqueries make a cheap equivalence test.

</details>
