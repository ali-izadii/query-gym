# My SQL practice progress

Mark an exercise complete by changing `- [ ]` to `- [x]`.
Update the summary below manually; Markdown does not calculate progress.

**Completed: 0/288 exercises**

```text
[--------------------] 0.0%
```

Each filled `#` represents 5%. Percentage = completed ÷ total × 100.

## 01. Basics: SELECT, WHERE, NULL, ORDER BY

[Open exercises](exercises/01_basics_select_filter.md) · 16 exercises

- [ ] **T01-01** — Active products with a price range
- [ ] **T01-02** — Users who never logged in
- [ ] **T01-03** — Distinct order channels
- [ ] **T01-04** — Soft-deleted vs live users
- [ ] **T01-05** — Sellers in a set of countries
- [ ] **T01-06** — Coalesce a missing rating
- [ ] **T01-07** — Orders placed in a window
- [ ] **T01-08** — Cheapest three variants per SKU prefix
- [ ] **T01-09** — NULL-safe comparison of two columns
- [ ] **T01-10** — Derived columns and aliases
- [ ] **T01-11** — Pagination that does not drift
- [ ] **T01-12** — Keyset (cursor) pagination
- [ ] **T01-13** — CASE buckets
- [ ] **T01-14** — DISTINCT ON — one row per group
- [ ] **T01-15** — Boolean logic precedence trap
- [ ] **T01-16** — Ordering with NULLs placed explicitly

## 02. Joins: inner, outer, anti, self, LATERAL

[Open exercises](exercises/02_joins.md) · 18 exercises

- [ ] **T02-01** — Inner join products to sellers
- [ ] **T02-02** — Three-table join
- [ ] **T02-03** — LEFT JOIN keeps unmatched rows
- [ ] **T02-04** — Join with an extra filter in ON vs WHERE
- [ ] **T02-05** — Count rows per side of a join
- [ ] **T02-06** — USING shorthand
- [ ] **T02-07** — Anti-join — products never ordered
- [ ] **T02-08** — Semi-join — users who reviewed something
- [ ] **T02-09** — Self-join on the referral graph
- [ ] **T02-10** — Self-join for manager pairs
- [ ] **T02-11** — FULL OUTER JOIN to reconcile two sets
- [ ] **T02-12** — CROSS JOIN to build a dense grid
- [ ] **T02-13** — LATERAL top-N per group
- [ ] **T02-14** — LEFT JOIN LATERAL keeps empty groups
- [ ] **T02-15** — Range join on a temporal table
- [ ] **T02-16** — Join fan-out and how to avoid double counting
- [ ] **T02-17** — Multi-column join against a dimension
- [ ] **T02-18** — Non-equi join — price bands

## 03. Aggregation: GROUP BY, HAVING, FILTER, percentiles

[Open exercises](exercises/03_aggregation.md) · 18 exercises

- [ ] **T03-01** — Orders and revenue per status
- [ ] **T03-02** — Average rating per product, rounded
- [ ] **T03-03** — HAVING filters groups, WHERE filters rows
- [ ] **T03-04** — min, max, span
- [ ] **T03-05** — COUNT variants
- [ ] **T03-06** — Conditional aggregation with FILTER
- [ ] **T03-07** — Multi-level grouping
- [ ] **T03-08** — DISTINCT inside an aggregate
- [ ] **T03-09** — Weighted average
- [ ] **T03-10** — Aggregating booleans
- [ ] **T03-11** — String aggregation
- [ ] **T03-12** — Ordered-set aggregates — median and percentiles
- [ ] **T03-13** — Discrete percentile and mode
- [ ] **T03-14** — Statistical aggregates
- [ ] **T03-15** — Correlation and regression
- [ ] **T03-16** — Aggregate over an aggregate (two-step)
- [ ] **T03-17** — Guarding against the empty group
- [ ] **T03-18** — Average of per-group maxima, in one pass

## 04. Subqueries & CTEs

[Open exercises](exercises/04_subqueries_ctes.md) · 18 exercises

- [ ] **T04-01** — Scalar subquery in the select list
- [ ] **T04-02** — Subquery in WHERE with a computed threshold
- [ ] **T04-03** — IN with a subquery
- [ ] **T04-04** — Derived table (subquery in FROM)
- [ ] **T04-05** — Correlated subquery per row
- [ ] **T04-06** — EXISTS vs IN with NULLs
- [ ] **T04-07** — ANY / ALL quantified comparison
- [ ] **T04-08** — Row constructor subquery
- [ ] **T04-09** — Simple CTE for readability
- [ ] **T04-10** — Multiple chained CTEs
- [ ] **T04-11** — Correlated subquery vs LATERAL
- [ ] **T04-12** — CTE materialization control
- [ ] **T04-13** — Reusing a CTE twice
- [ ] **T04-14** — Semi-join with a composite key
- [ ] **T04-15** — Anti-join on two columns
- [ ] **T04-16** — Correlated subquery in HAVING
- [ ] **T04-17** — Subquery returning multiple columns via row comparison
- [ ] **T04-18** — Rewriting NOT IN safely

## 05. Window functions I: ranking, offsets, frames

[Open exercises](exercises/05_window_basics.md) · 20 exercises

- [ ] **T05-01** — row_number over the whole set
- [ ] **T05-02** — Aggregate as a window function
- [ ] **T05-03** — Share of total per row
- [ ] **T05-04** — PARTITION BY
- [ ] **T05-05** — rank vs dense_rank vs row_number
- [ ] **T05-06** — Top-N per partition
- [ ] **T05-07** — lag — difference from the previous row
- [ ] **T05-08** — lead with a default
- [ ] **T05-09** — Percent change with growth rate
- [ ] **T05-10** — Running total (default frame)
- [ ] **T05-11** — Running total per partition, reset each month
- [ ] **T05-12** — Moving average with a ROWS frame
- [ ] **T05-13** — ROWS vs RANGE with duplicate keys
- [ ] **T05-14** — GROUPS frame
- [ ] **T05-15** — first_value / last_value done right
- [ ] **T05-16** — nth_value and named WINDOW clause
- [ ] **T05-17** — ntile buckets
- [ ] **T05-18** — percent_rank and cume_dist
- [ ] **T05-19** — Window over a window (two passes)
- [ ] **T05-20** — Deduplicate with row_number

## 06. Window functions II: gaps/islands, funnels, cohorts

[Open exercises](exercises/06_window_advanced.md) · 16 exercises

- [ ] **T06-01** — Find gaps in a sequence
- [ ] **T06-02** — Islands of consecutive days (classic gaps-and-islands)
- [ ] **T06-03** — Longest streak per employee
- [ ] **T06-04** — Islands over a status change (change-point detection)
- [ ] **T06-05** — Sessionisation with a 30-minute inactivity timeout
- [ ] **T06-06** — Time between consecutive orders per customer
- [ ] **T06-07** — First and last event of each session
- [ ] **T06-08** — Funnel conversion per step
- [ ] **T06-09** — LOCF — carry the last known FX rate forward
- [ ] **T06-10** — Signup cohorts and monthly retention
- [ ] **T06-11** — Retention as a percentage of the cohort
- [ ] **T06-12** — Rank within partition and keep ties
- [ ] **T06-13** — Second purchase latency
- [ ] **T06-14** — Cumulative distinct count (approximate running reach)
- [ ] **T06-15** — Year-over-year comparison with a 12-month lag
- [ ] **T06-16** — Top-N with "others" rollup

## 07. Recursive CTEs & hierarchies

[Open exercises](exercises/07_recursive_hierarchies.md) · 16 exercises

- [ ] **T07-01** — Generate a numeric series recursively
- [ ] **T07-02** — Walk down the category tree
- [ ] **T07-03** — Walk up to the root (ancestor chain)
- [ ] **T07-04** — Materialised path and breadcrumb
- [ ] **T07-05** — Verify a denormalised depth column
- [ ] **T07-06** — Inherited commission (first non-NULL ancestor)
- [ ] **T07-07** — Subtree aggregation (roll revenue up the tree)
- [ ] **T07-08** — Org chart with level and path
- [ ] **T07-09** — Count direct and total reports
- [ ] **T07-10** — Breadth-first ordering with SEARCH
- [ ] **T07-11** — Depth-first ordering with SEARCH
- [ ] **T07-12** — Cycle-safe graph walk
- [ ] **T07-13** — Threaded review replies as a tree
- [ ] **T07-14** — Transitive closure of the seller group structure
- [ ] **T07-15** — Recursive gap filling of a date series
- [ ] **T07-16** — Bill-of-materials style explosion with quantities

## 08. GROUPING SETS, ROLLUP, CUBE, pivot

[Open exercises](exercises/08_grouping_sets_pivot.md) · 14 exercises

- [ ] **T08-01** — ROLLUP for subtotals
- [ ] **T08-02** — Distinguish a real NULL from a rollup NULL
- [ ] **T08-03** — CUBE for every combination
- [ ] **T08-04** — Explicit GROUPING SETS
- [ ] **T08-05** — Manual pivot with FILTER
- [ ] **T08-06** — Pivot counts with CASE (portable form)
- [ ] **T08-07** — crosstab() from the tablefunc extension
- [ ] **T08-08** — Unpivot columns into rows
- [ ] **T08-09** — Unpivot with unnest of parallel arrays
- [ ] **T08-10** — Percent of subtotal using ROLLUP output
- [ ] **T08-11** — Multi-level grouping sets with mixed dimensions
- [ ] **T08-12** — Pivot a dynamic key set from JSONB
- [ ] **T08-13** — Sparse matrix with dense axes
- [ ] **T08-14** — Budget vs actual with variance

## 09. JSONB

[Open exercises](exercises/09_jsonb.md) · 20 exercises

- [ ] **T09-01** — Extract a top-level key
- [ ] **T09-02** — Nested path access
- [ ] **T09-03** — Count by a JSONB attribute
- [ ] **T09-04** — Containment operator with a GIN index
- [ ] **T09-05** — Key existence
- [ ] **T09-06** — Numeric comparison on a JSONB value
- [ ] **T09-07** — Expand a JSONB object into rows
- [ ] **T09-08** — Expand a JSONB array
- [ ] **T09-09** — jsonpath existence query
- [ ] **T09-10** — jsonb_path_query to project nested values
- [ ] **T09-11** — Aggregate rows into a JSONB array
- [ ] **T09-12** — Build nested JSON documents
- [ ] **T09-13** — Modify JSONB without touching the table
- [ ] **T09-14** — Remove keys and deep paths
- [ ] **T09-15** — Audit log diff — which keys changed
- [ ] **T09-16** — Aggregate UTM parameters from the event stream
- [ ] **T09-17** — JSONB to relational projection with jsonb_to_record
- [ ] **T09-18** — Aggregate a key/value store back into one document
- [ ] **T09-19** — Filter on an element inside a JSONB array
- [ ] **T09-20** — jsonpath with variables and arithmetic

## 10. Arrays, ranges & multiranges

[Open exercises](exercises/10_arrays_ranges.md) · 18 exercises

- [ ] **T10-01** — Array contains an element
- [ ] **T10-02** — Array overlap
- [ ] **T10-03** — Array length and empty arrays
- [ ] **T10-04** — unnest to count tag frequency
- [ ] **T10-05** — Aggregate rows back into an array
- [ ] **T10-06** — Array subscripting and slicing
- [ ] **T10-07** — Array equality vs set semantics
- [ ] **T10-08** — Array set operations
- [ ] **T10-09** — unnest WITH ORDINALITY
- [ ] **T10-10** — Range containment on price history
- [ ] **T10-11** — Range overlap
- [ ] **T10-12** — Range bounds and inclusivity
- [ ] **T10-13** — Range intersection and union
- [ ] **T10-14** — Detect overlapping time-off requests
- [ ] **T10-15** — Multirange aggregation
- [ ] **T10-16** — Total covered days from overlapping ranges
- [ ] **T10-17** — Exclusion constraint in action
- [ ] **T10-18** — Gap detection between consecutive ranges

## 11. Text, regex & full-text search

[Open exercises](exercises/11_text_search.md) · 18 exercises

- [ ] **T11-01** — LIKE and ILIKE
- [ ] **T11-02** — String functions
- [ ] **T11-03** — Normalising case and whitespace
- [ ] **T11-04** — Regex match
- [ ] **T11-05** — Capture groups with regexp_match
- [ ] **T11-06** — Split text into rows
- [ ] **T11-07** — Regex replace
- [ ] **T11-08** — Full-text search with to_tsquery
- [ ] **T11-09** — Ranked full-text search
- [ ] **T11-10** — Phrase search and websearch syntax
- [ ] **T11-11** — Highlighted snippets
- [ ] **T11-12** — Inspect a tsvector
- [ ] **T11-13** — Trigram similarity search
- [ ] **T11-14** — Trigram distance operator
- [ ] **T11-15** — Search reviews and aggregate sentiment-ish signal
- [ ] **T11-16** — Normalise accents for search
- [ ] **T11-17** — Deduplicate dirty leads
- [ ] **T11-18** — Parse multi-format dates defensively

## 12. Dates, time zones & time series

[Open exercises](exercises/12_dates_time.md) · 16 exercises

- [ ] **T12-01** — Truncate and extract
- [ ] **T12-02** — Interval arithmetic
- [ ] **T12-03** — Age and duration
- [ ] **T12-04** — Daily series with gap filling
- [ ] **T12-05** — Weekly buckets
- [ ] **T12-06** — Arbitrary bucket width with date_bin
- [ ] **T12-07** — Time zone conversion
- [ ] **T12-08** — Business-day bucketing with the calendar table
- [ ] **T12-09** — Holiday-aware SLA
- [ ] **T12-10** — Month-end and month-start edge cases
- [ ] **T12-11** — Hour-of-day heatmap
- [ ] **T12-12** — Rolling 7-day window by date range
- [ ] **T12-13** — Overlapping shifts per day
- [ ] **T12-14** — Time to first event per entity
- [ ] **T12-15** — Fiscal year reporting
- [ ] **T12-16** — DST-safe daily bucketing in a local zone

## 13. Set operations & reconciliation

[Open exercises](exercises/13_set_operations.md) · 12 exercises

- [ ] **T13-01** — UNION removes duplicates
- [ ] **T13-02** — UNION ALL with a source tag
- [ ] **T13-03** — INTERSECT
- [ ] **T13-04** — EXCEPT
- [ ] **T13-05** — EXCEPT ALL preserves multiplicity
- [ ] **T13-06** — VALUES as an inline table
- [ ] **T13-07** — Reconcile two aggregates with FULL JOIN vs set ops
- [ ] **T13-08** — Symmetric difference
- [ ] **T13-09** — Set operations with multiple columns
- [ ] **T13-10** — Ordering and LIMIT inside set operations
- [ ] **T13-11** — Type unification across branches
- [ ] **T13-12** — Compare two query results row by row

## 14. Performance: EXPLAIN, indexes, plans

[Open exercises](exercises/14_performance_explain.md) · 18 exercises

- [ ] **T14-01** — Read your first plan
- [ ] **T14-02** — Sargable vs non-sargable predicate
- [ ] **T14-03** — Index-only scan
- [ ] **T14-04** — Partition pruning
- [ ] **T14-05** — BRIN vs btree on a huge append-only column
- [ ] **T14-06** — Nested loop vs hash join
- [ ] **T14-07** — The missing index, measured
- [ ] **T14-08** — Sort avoidance with a matching index
- [ ] **T14-09** — Rewrite a correlated subquery as a join
- [ ] **T14-10** — OR predicates and bitmap index combination
- [ ] **T14-11** — Statistics and mis-estimation
- [ ] **T14-12** — LIMIT changes the optimal plan
- [ ] **T14-13** — Parallel query
- [ ] **T14-14** — CTE inlining vs materialization
- [ ] **T14-15** — Find the expensive queries with pg_stat_statements
- [ ] **T14-16** — Index bloat and usage audit
- [ ] **T14-17** — Table and index size breakdown
- [ ] **T14-18** — Rewrite a slow top-N-per-group query

## 15. DML, UPSERT, MERGE & transactions

[Open exercises](exercises/15_dml_transactions.md) · 16 exercises

- [ ] **T15-01** — INSERT with RETURNING
- [ ] **T15-02** — INSERT ... SELECT
- [ ] **T15-03** — UPSERT with DO UPDATE
- [ ] **T15-04** — Conditional UPSERT
- [ ] **T15-05** — UPDATE ... FROM a join
- [ ] **T15-06** — DELETE ... USING
- [ ] **T15-07** — Data-modifying CTE pipeline
- [ ] **T15-08** — MERGE
- [ ] **T15-09** — Idempotent backfill in batches
- [ ] **T15-10** — Soft delete with a partial unique index in mind
- [ ] **T15-11** — SELECT ... FOR UPDATE and SKIP LOCKED queue
- [ ] **T15-12** — Constraint violation handling
- [ ] **T15-13** — Savepoints
- [ ] **T15-14** — Isolation levels and visibility
- [ ] **T15-15** — Generated columns are not writable
- [ ] **T15-16** — Bulk load pattern with a staging table

## 16. Data quality & validation

[Open exercises](exercises/16_data_quality.md) · 16 exercises

- [ ] **T16-01** — Profile NULLs across a table
- [ ] **T16-02** — Distinct value profile
- [ ] **T16-03** — Normalise a messy country column
- [ ] **T16-04** — Safe numeric coercion
- [ ] **T16-05** — Find exact duplicate rows
- [ ] **T16-06** — Keep one row per duplicate group
- [ ] **T16-07** — Referential integrity audit (orphan check)
- [ ] **T16-08** — Business-rule validation
- [ ] **T16-09** — Cross-table consistency
- [ ] **T16-10** — Timeline sanity checks
- [ ] **T16-11** — Outlier detection with percentiles
- [ ] **T16-12** — Z-score outliers per group
- [ ] **T16-13** — Detect broken denormalisation
- [ ] **T16-14** — Assertion query that fails loudly
- [ ] **T16-15** — Completeness report per table
- [ ] **T16-16** — Fuzzy duplicate customers

## 17. Capstone analytics reports

[Open exercises](exercises/17_analytics_reports.md) · 18 exercises

- [ ] **T17-01** — RFM segmentation
- [ ] **T17-02** — Customer lifetime value to date
- [ ] **T17-03** — Market basket — frequent product pairs
- [ ] **T17-04** — Lift for a product pair
- [ ] **T17-05** — Channel attribution — first vs last touch
- [ ] **T17-06** — Marketing efficiency — CAC and ROAS
- [ ] **T17-07** — Seller scorecard
- [ ] **T17-08** — ABC / Pareto classification
- [ ] **T17-09** — Inventory coverage and reorder alerts
- [ ] **T17-10** — Cart abandonment funnel by device
- [ ] **T17-11** — Churn flag with a rolling definition
- [ ] **T17-12** — Repeat purchase rate by cohort month
- [ ] **T17-13** — Price elasticity proxy
- [ ] **T17-14** — Seasonality index per month
- [ ] **T17-15** — Multi-currency revenue normalised to USD
- [ ] **T17-16** — SCD2 as-of lookup
- [ ] **T17-17** — Support SLA breach report
- [ ] **T17-18** — Executive one-row KPI snapshot
