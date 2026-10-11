# 10. Arrays, ranges & multiranges

**3** basic, **4** intermediate, **6** advanced, **5** expert — 18 exercises

```bash
make new Q=T10-01                 # scaffold work/T10-01.sql
make diff Q=T10-01 F=work/T10-01.sql   # grade your answer
make run Q=T10-01                 # see the reference result
make explain Q=T10-01             # see the plan
```

---

### T10-01 — Array contains an element

🟢 basic · `array containment, GIN index on arrays`

Count products tagged 'bestseller'.

<details><summary>hint</summary>

tags @> ARRAY['bestseller'] (index-friendly) or 'bestseller' = ANY(tags).

</details>

### T10-02 — Array overlap

🟢 basic · `&& overlap operator`

Count products carrying at least one of the tags 'eco' or 'handmade'.

<details><summary>hint</summary>

&& is the overlap operator.

</details>

### T10-03 — Array length and empty arrays

🟢 basic · `cardinality vs array_length, NULL vs 0`

Count products per number of tags. Columns: tag_count, products. Order by tag_count.

<details><summary>hint</summary>

cardinality(tags) handles the empty array as 0, unlike array_length(tags, 1) which returns NULL.

</details>

### T10-04 — unnest to count tag frequency

🟡 intermediate · `unnest, array expansion, GROUP BY`

Count how many products carry each tag. Columns: tag, products. Order by products DESC, tag.

<details><summary>hint</summary>

unnest(tags) in a LATERAL or directly in FROM.

</details>

### T10-05 — Aggregate rows back into an array

🟡 intermediate · `array_agg, ORDER BY inside aggregate`

For the 10 lowest category_ids at depth 3, return category_id and an array of up to 5 product titles sorted alphabetically, as titles.

<details><summary>hint</summary>

array_agg(title ORDER BY title) combined with a LATERAL LIMIT 5.

</details>

### T10-06 — Array subscripting and slicing

🟡 intermediate · `1-based subscripts, slices`

For the 10 lowest product_ids with at least 2 tags, return product_id, the first tag, the last tag and the first two as a slice. Columns: product_id, first_tag, last_tag, first_two.

<details><summary>hint</summary>

tags[1], tags[cardinality(tags)], tags[1:2].

</details>

### T10-07 — Array equality vs set semantics

🟡 intermediate · `array ordering, normalising arrays for comparison`

Count products whose tag set is exactly {'eco','gift'} regardless of order. Column: exact_set.

<details><summary>hint</summary>

Arrays compare element-wise in order; sort them first, e.g. with ARRAY(SELECT unnest(tags) ORDER BY 1).

</details>

### T10-08 — Array set operations

🟠 advanced · `set operations on arrays, scalar array subqueries`

For the 10 lowest product_ids with at least 3 tags, return product_id, the tags, the intersection with {'eco','premium','gift'} and the difference. Columns: product_id, tags, common, only_mine.

<details><summary>hint</summary>

intarray only covers int[]; for text[] use ARRAY(SELECT ... INTERSECT ...) style set operations inside a scalar subquery.

</details>

### T10-09 — unnest WITH ORDINALITY

🟠 advanced · `WITH ORDINALITY, preserving array order`

For product_id 1..3, list each tag with its 1-based position. Columns: product_id, pos, tag. Order by product_id, pos.

<details><summary>hint</summary>

unnest(tags) WITH ORDINALITY AS t(tag, pos).

</details>

### T10-10 — Range containment on price history

🟠 advanced · `daterange, @> containment, GiST`

Count price_history rows whose validity window contains 2025-06-15.

<details><summary>hint</summary>

valid_range @> date '2025-06-15' uses the GiST exclusion index.

</details>

### T10-11 — Range overlap

🟠 advanced · `tstzrange, && overlap`

Count promotions whose active_range overlaps the whole of December 2024.

<details><summary>hint</summary>

active_range && tstzrange('2024-12-01','2025-01-01','[)').

</details>

### T10-12 — Range bounds and inclusivity

🟠 advanced · `range accessor functions`

For the 10 lowest promo_ids, return promo_id, lower and upper bounds, whether each bound is inclusive, and the duration in days. Columns: promo_id, starts, ends, lower_inc, upper_inc, days.

<details><summary>hint</summary>

lower(), upper(), lower_inc(), upper_inc().

</details>

### T10-13 — Range intersection and union

🟠 advanced · `range * operator, range_merge`

For promo_id 1 and 2, return the intersection and the union-ish span of their active ranges. Columns: intersection, span.

<details><summary>hint</summary>

* is intersection; + requires contiguous ranges, so use range_merge() for a span that covers both. Ranges have no max() aggregate, so pick the two rows with scalar subqueries or a self-join.

</details>

### T10-14 — Detect overlapping time-off requests

🔴 expert · `overlap self-join, pairwise comparison, deduplicating pairs`

Find pairs of approved time_off rows for the same employee whose periods overlap. Columns: employee_id, request_a, request_b. Order by employee_id, request_a. Limit 20. (The schema does not forbid these, unlike salary_history.)

<details><summary>hint</summary>

Self-join on employee_id with a.request_id < b.request_id and a.period && b.period.

</details>

### T10-15 — Multirange aggregation

🔴 expert · `range_agg, multiranges`

For the 10 lowest employee_ids with approved time off, return employee_id and the union of all their approved periods as a datemultirange, named off_periods.

<details><summary>hint</summary>

range_agg() aggregates ranges into a multirange (Postgres 14+).

</details>

### T10-16 — Total covered days from overlapping ranges

🔴 expert · `range_agg + unnest, overlap-safe duration`

For the same employees, compute the number of distinct days covered by their approved time off, correctly handling overlaps. Columns: employee_id, covered_days. Order by employee_id. Limit 10.

<details><summary>hint</summary>

Build the multirange with range_agg, unnest it back into ranges and sum (upper - lower) per employee.

</details>

### T10-17 — Exclusion constraint in action

🔴 expert · `EXCLUDE constraint, GiST, transactional DDL/DML testing`

Demonstrate that shop.price_history forbids overlapping windows for the same variant: attempt an overlapping INSERT and show that the transaction fails, then roll back.

<details><summary>hint</summary>

The EXCLUDE USING gist (variant_id WITH =, daterange WITH &&) constraint raises "conflicting key value violates exclusion constraint".

</details>

### T10-18 — Gap detection between consecutive ranges

🔴 expert · `lead over ranges, gap detection in temporal data`

price_history windows are contiguous per variant. Prove it: for the 10 variants with the most rows, report every consecutive pair and whether a gap exists between valid_to and the next valid_from. Columns: variant_id, window_end, next_window_start, gap_days. Order by variant_id, window_end. Limit 20.

<details><summary>hint</summary>

lead(valid_from) over each variant ordered by valid_from, then subtract. gap_days = 0 everywhere means the history is contiguous.

</details>
