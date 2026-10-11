# 07. Recursive CTEs & hierarchies

**2** basic, **4** intermediate, **6** advanced, **4** expert — 16 exercises

```bash
make new Q=T07-01                 # scaffold work/T07-01.sql
make diff Q=T07-01 F=work/T07-01.sql   # grade your answer
make run Q=T07-01                 # see the reference result
make explain Q=T07-01             # see the plan
```

---

### T07-01 — Generate a numeric series recursively

🟢 basic · `WITH RECURSIVE, anchor + recursive term, termination`

Produce the numbers 1..10 in a column n using a recursive CTE (no generate_series). Order by n.

<details><summary>hint</summary>

Anchor SELECT 1, recursive part adds 1 until the stop condition.

</details>

### T07-02 — Walk down the category tree

🟢 basic · `recursive descent, tree traversal`

Starting at category_id 1 ('Electronics'), return every descendant plus the root: category_id, name, depth. Order by depth, category_id.

<details><summary>hint</summary>

Anchor on the root, then join categories.parent_id to the previous level's category_id.

</details>

### T07-03 — Walk up to the root (ancestor chain)

🟡 intermediate · `upward traversal, level counter`

For category_id 150, return its ancestor chain from itself up to the root: category_id, name, level (0 = the category itself). Order by level.

<details><summary>hint</summary>

Anchor on the starting node; the recursive step joins the *parent*.

</details>

### T07-04 — Materialised path and breadcrumb

🟡 intermediate · `path accumulation, string building in recursion`

For every level-3 category under root 3 ('Fashion'), return category_id and a breadcrumb string 'Root > Mid > Leaf' as path. Order by path. Limit 15.

<details><summary>hint</summary>

Accumulate text in the recursive term: t.path || ' > ' || c.name.

</details>

### T07-05 — Verify a denormalised depth column

🟡 intermediate · `recursion for validation, data integrity check`

shop.categories stores depth. Recompute it recursively and return any rows where the stored value disagrees: category_id, stored_depth, computed_depth. (Expect zero rows.)

<details><summary>hint</summary>

Compute depth in the recursion, then join back and compare.

</details>

### T07-06 — Inherited commission (first non-NULL ancestor)

🟡 intermediate · `inheritance through a hierarchy, DISTINCT ON over recursion`

For level-3 categories 49..60, return category_id, own commission_pct and effective_pct = the first non-NULL commission_pct found walking up the tree. Order by category_id.

<details><summary>hint</summary>

Recurse upward carrying the leaf id, stop collecting once a non-NULL is found — or collect all ancestors and pick the closest non-NULL with DISTINCT ON.

</details>

### T07-07 — Subtree aggregation (roll revenue up the tree)

🟠 advanced · `subtree rollup, mapping descendants to ancestors`

For each level-1 category, total the revenue of every product in its whole subtree. Columns: root_id, root_name, revenue. Order by revenue DESC.

<details><summary>hint</summary>

Recursively map every category to its root, then join products and order_items and aggregate by root.

</details>

### T07-08 — Org chart with level and path

🟠 advanced · `recursive org chart, array path accumulation`

Build the employee hierarchy from the CEO down: employee_id, name, level (1 = CEO) and path (array of ids). Return the 20 deepest rows ordered by level DESC, employee_id.

<details><summary>hint</summary>

Accumulate the path as an int[]: path || e.employee_id.

</details>

### T07-09 — Count direct and total reports

🟠 advanced · `transitive closure, counting descendants`

For the 10 managers with the most *total* (transitive) reports, return employee_id, direct_reports and total_reports.

<details><summary>hint</summary>

Direct reports is a simple GROUP BY on manager_id; total reports needs a recursive descent from each manager — or a single recursion that records the starting ancestor.

</details>

### T07-10 — Breadth-first ordering with SEARCH

🟠 advanced · `SEARCH BREADTH FIRST, traversal order`

Traverse the category subtree of root 2 breadth-first and return category_id, depth in BFS order, limited to 20 rows.

<details><summary>hint</summary>

Postgres 14+: SEARCH BREADTH FIRST BY category_id SET seq, then ORDER BY seq.

</details>

### T07-11 — Depth-first ordering with SEARCH

🟠 advanced · `SEARCH DEPTH FIRST`

Same subtree, but depth-first. Return category_id, depth in DFS order, limited to 20 rows.

<details><summary>hint</summary>

SEARCH DEPTH FIRST BY category_id SET seq.

</details>

### T07-12 — Cycle-safe graph walk

🟠 advanced · `CYCLE clause, graph traversal, infinite loop protection`

Walk the user referral graph starting from user_id 1 and return user_id, hops and is_cycle, protecting against cycles. Limit 20 rows, ordered by hops, user_id.

<details><summary>hint</summary>

Postgres 14+: CYCLE user_id SET is_cycle USING path.

</details>

### T07-13 — Threaded review replies as a tree

🔴 expert · `threaded comments, recursion over a self-FK`

For the 5 lowest root review_ids that have replies, return the whole thread: review_id, reply_to, depth, ordered by root review then depth. Limit 30 rows.

<details><summary>hint</summary>

Anchor on the chosen roots, recurse on reply_to, carry the root id.

</details>

### T07-14 — Transitive closure of the seller group structure

🔴 expert · `transitive closure, ultimate ancestor`

For every seller that belongs to a group, find its ultimate top-level parent. Return seller_id, top_parent_id, hops for the 20 largest hops.

<details><summary>hint</summary>

Recurse upward from each seller, keep the row with the highest hop count per seller (DISTINCT ON ... ORDER BY hops DESC).

</details>

### T07-15 — Recursive gap filling of a date series

🔴 expert · `recursive date series, gap filling`

Without generate_series, build every date from 2025-01-01 to 2025-01-15 and LEFT JOIN daily paid order counts, showing 0 for empty days. Columns: day, orders. Order by day.

<details><summary>hint</summary>

Recursive CTE adding interval '1 day' until the end date.

</details>

### T07-16 — Bill-of-materials style explosion with quantities

🔴 expert · `numeric accumulation in recursion, BOM explosion pattern`

Treat the category tree as a multiplier chain: starting at root 1 with weight 1.0, each level multiplies the weight by 0.5. Return category_id, depth and weight for depth <= 3, ordered by depth, category_id. Limit 25.

<details><summary>hint</summary>

Carry a numeric accumulator through the recursion.

</details>
