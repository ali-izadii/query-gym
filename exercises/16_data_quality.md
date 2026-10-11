# 16. Data quality & validation

**2** basic, **4** intermediate, **6** advanced, **4** expert — 16 exercises

```bash
make new Q=T16-01                 # scaffold work/T16-01.sql
make diff Q=T16-01 F=work/T16-01.sql   # grade your answer
make run Q=T16-01                 # see the reference result
make explain Q=T16-01             # see the plan
```

---

### T16-01 — Profile NULLs across a table

🟢 basic · `data profiling, unpivot, FILTER`

For shop.raw_leads, report the number of NULL (or blank) values per column. Columns: column_name, null_or_blank. Order by null_or_blank DESC.

<details><summary>hint</summary>

One count(*) FILTER per column, then unpivot with a VALUES list.

</details>

### T16-02 — Distinct value profile

🟢 basic · `GROUP BY with NULLs, value profiling`

For shop.raw_leads.country_raw, return every distinct raw value with its count, including NULL as its own group. Columns: country_raw, n. Order by n DESC, country_raw NULLS LAST.

<details><summary>hint</summary>

GROUP BY treats all NULLs as one group — unlike WHERE comparisons.

</details>

### T16-03 — Normalise a messy country column

🟡 intermediate · `normalisation, CASE mapping, defensive cleaning`

Map country_raw to a clean 2-letter code: trim, upper-case, and map 'GERMANY'->DE, 'USA'/'U.S.'->US, 'UK'->GB. Report counts per cleaned value. Columns: country_code, n. Order by n DESC, country_code NULLS LAST.

<details><summary>hint</summary>

A CASE over upper(btrim(...)) handles the special cases; everything else of length 2 passes through.

</details>

### T16-04 — Safe numeric coercion

🟡 intermediate · `safe casting, regex validation, defensive ETL`

Convert amount_raw to numeric where possible: strip currency symbols and thousand separators, and count how many values convert vs fail. Columns: convertible, not_convertible.

<details><summary>hint</summary>

Clean first, then test the result with a regex before casting — a plain cast would abort the whole query on the first bad value.

</details>

### T16-05 — Find exact duplicate rows

🟡 intermediate · `duplicate detection, normalised grouping`

In shop.raw_leads, find groups of rows identical on (lower(trim(email_raw)), lower(trim(name_raw))) with more than one member. Return the 10 largest groups: email_norm, name_norm, n.

<details><summary>hint</summary>

GROUP BY the normalised expressions, HAVING count(*) > 1.

</details>

### T16-06 — Keep one row per duplicate group

🟡 intermediate · `deduplication strategy, array_agg, array_remove, survivor choice`

From the same table, return the raw_id to KEEP for each duplicate email group (the lowest raw_id) and the ids to drop as an array. Columns: email_norm, keep_id, drop_ids. Limit 10.

<details><summary>hint</summary>

min() picks the survivor, array_agg(... ORDER BY ...) collects all ids. You cannot call min() inside FILTER, so rank the rows first (or trim the survivor off the array afterwards with array_remove).

</details>

### T16-07 — Referential integrity audit (orphan check)

🟠 advanced · `orphan detection, NOT EXISTS, integrity auditing`

Check for orphans across several relationships at once and report the count per relationship. Columns: relationship, orphans. Order by relationship. (All should be 0 — the FKs enforce it.)

<details><summary>hint</summary>

One NOT EXISTS count per relationship, combined with UNION ALL.

</details>

### T16-08 — Business-rule validation

🟠 advanced · `derived-value validation, floating tolerance`

Find orders whose stored grand_total disagrees with item_total - discount_total + tax_total + shipping_fee by more than 0.01. Columns: order_id, stored, recomputed, diff. Limit 20.

<details><summary>hint</summary>

Compare with abs(difference) > 0.01 to tolerate rounding.

</details>

### T16-09 — Cross-table consistency

🟠 advanced · `reconciliation across tables, coalesce on missing aggregates`

Find orders where the sum of captured payments differs from grand_total by more than 0.01, excluding cancelled and pending orders. Columns: order_id, grand_total, captured, diff. Limit 20.

<details><summary>hint</summary>

Aggregate payments per order first, then compare with coalesce(...,0).

</details>

### T16-10 — Timeline sanity checks

🟠 advanced · `temporal validation, multi-rule auditing`

Find rows that violate chronology: paid_at before placed_at, delivered_at before shipped_at, or solved_at before opened_at. Report the count per rule. Columns: rule, violations. Order by rule.

<details><summary>hint</summary>

Each rule is a separate scan; UNION ALL them.

</details>

### T16-11 — Outlier detection with percentiles

🟠 advanced · `percentile cutoffs, outlier flagging`

Flag order_items whose unit_price is above the 99.9th percentile or below the 0.1th. Columns: order_item_id, unit_price, side. Limit 20.

<details><summary>hint</summary>

Compute both cutoffs once in a CTE, then join (CROSS JOIN) to compare.

</details>

### T16-12 — Z-score outliers per group

🟠 advanced · `window statistics, z-score, per-group outliers`

For sellers with at least 50 sold lines, flag the lines whose line_total is more than 4 standard deviations above that seller's mean. Columns: seller_id, order_item_id, line_total, z (2 decimals). Limit 20.

<details><summary>hint</summary>

Window aggregates avg() and stddev_samp() OVER (PARTITION BY seller_id) give per-group statistics on every row.

</details>

### T16-13 — Detect broken denormalisation

🔴 expert · `denormalisation drift, consistency auditing`

order_items stores product_id redundantly alongside variant_id. Find rows where the stored product_id does not match the variant's real product_id. Columns: order_item_id, stored_product, real_product. (Expect zero rows.)

<details><summary>hint</summary>

Join product_variants and compare.

</details>

### T16-14 — Assertion query that fails loudly

🔴 expert · `assertions, RAISE, data tests`

Write a check that raises an exception when any active product has a negative price, and otherwise reports success.

<details><summary>hint</summary>

A DO block with IF EXISTS (...) THEN RAISE EXCEPTION — the shape used by data tests in CI.

</details>

### T16-15 — Completeness report per table

🔴 expert · `completeness metrics, UNION ALL reporting`

Build a one-row-per-table completeness summary for three tables with row counts and the share of rows having a NULL in a key nullable column. Columns: table_name, rows, null_share (4 decimals). Order by table_name.

<details><summary>hint</summary>

One aggregate per table, combined with UNION ALL; cast counts to numeric before dividing.

</details>

### T16-16 — Fuzzy duplicate customers

🔴 expert · `fuzzy matching, self-join pair generation, pg_trgm`

Find pairs of users in the same country whose full_name similarity is above 0.75 but whose emails differ. Columns: user_a, user_b, name_a, name_b, sim (3 decimals). Limit 15.

<details><summary>hint</summary>

Self-join with a.user_id < b.user_id to avoid mirrored pairs, and use pg_trgm similarity(). Restrict to a slice of user_ids to keep it fast.

</details>
