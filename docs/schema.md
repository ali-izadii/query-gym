# Schema reference

Three schemas, 39 base tables (36 + the partitioned `page_events` and its
monthly children). Row counts below are for `SCALE=1`.

```
shop       transactional marketplace core
hr         org chart, payroll, shifts
analytics  clickstream, marketing, FX, SCD2, audit
practice   seeding helpers + the exercise runner's bookkeeping
```

Default `search_path` is `shop, hr, analytics, practice, public`, so most
queries can omit the schema prefix. The exercises qualify it anyway for
clarity.

---

## shop — transactional core

| Table | Rows | Notable for practice |
|---|---:|---|
| `countries` | 22 | region/subregion/currency dimension, `vat_rate` |
| `currencies` | 18 | `minor_units` (JPY/KRW have 0) |
| `categories` | 248 | **self-referencing tree**, 3 levels, `commission_pct` NULL = inherit |
| `users` | 50 000 | `prefs jsonb`, `referred_by` self-FK, generated `full_name`, soft delete, nullable `birth_date`/`last_login_at` |
| `user_addresses` | 85 080 | **partial unique index** (one default per user), nullable postal code |
| `sellers` | 2 000 | `parent_seller_id` group structure, enum `tier`, nullable `rating`, `metadata jsonb` |
| `warehouses` | 120 | nullable `seller_id` = platform-owned |
| `products` | 20 000 | `attrs jsonb` (nested + arrays), `tags text[]`, **generated `search_tsv`** with A/B/C weights, enum `status` |
| `product_variants` | 42 191 | `options jsonb`, `price_delta`, nullable `barcode` |
| `inventory` | 84 382 | composite PK (warehouse, variant), reorder points |
| `price_history` | 126 318 | **temporal**: `daterange` generated column + `EXCLUDE USING gist` (no overlaps) |
| `promotions` | 60 | `tstzrange active_range`, `rules jsonb` |
| `promotion_categories` | 189 | many-to-many bridge |
| `carts` / `cart_items` | 60 000 / 150 214 | guest carts (NULL user), abandonment funnel |
| `orders` | 250 000 | enum `status`, money columns reconcile with items, nullable `paid_at`/`cancelled_at` |
| `order_items` | 750 667 | **generated `line_total`**, denormalised `product_id`/`seller_id` |
| `payments` | 265 733 | retries (failed then captured), `chargeback`, `risk_score` |
| `refunds` | 37 227 | partial and full, order-level (NULL `order_item_id`) or line-level |
| `shipments` / `shipment_items` | 210 126 / 630 597 | carrier, transit times, lost/returned |
| `reviews` | 177 104 | **threaded** via `reply_to`, verified (`order_item_id`) vs not, generated `body_tsv`, ratings skewed high |
| `wishlist_items` | 125 199 | composite PK, overlaps with purchases |
| `support_tickets` | 20 000 | SLA fields, nullable `first_response_at`, `csat_score`, FK to `hr.employees` |
| `ticket_messages` | 69 985 | `parent_message_id` chain, three author kinds |
| `raw_leads` | 5 000 | **intentionally dirty**: mixed case, whitespace, 6 date formats, `'€99'`, NULLs, duplicates |

## hr — hierarchy & scheduling

| Table | Rows | Notable for practice |
|---|---:|---|
| `departments` | 18 | self-referencing department tree |
| `job_titles` | 25 | families and salary bands |
| `employees` | 1 200 | **org chart** `manager_id`, depth 6, 12 % terminated, nullable `bonus_pct` |
| `salary_history` | 3 007 | temporal, `EXCLUDE` on `(employee_id, daterange)` |
| `shifts` | 45 907 | one row per worked day with deliberate gaps → **gaps-and-islands** |
| `time_off` | 1 786 | `daterange period`, *overlaps allowed on purpose* |

## analytics — events & marketing

| Table | Rows | Notable for practice |
|---|---:|---|
| `page_events` | 2 000 485 | **RANGE partitioned by month** (2023-01 … 2025-12 + DEFAULT), `utm jsonb`, BRIN on `occurred_at`, funnel event types |
| `sessions` | 300 000 | sessionisation source, channel, `converted`, revenue |
| `ad_spend` | 14 895 | daily × channel × campaign × country, sparse |
| `fx_rates` | 14 454 | **weekend + random gaps** → LOCF / as-of joins |
| `monthly_targets` | 108 | budget vs actual |
| `calendar` | 1 826 | weekend/holiday flags, ISO week, February-start fiscal year |
| `dim_seller_scd2` | 2 895 | **SCD type 2** with `is_current` and non-overlapping windows |
| `audit_log` | 37 544 | `before_row`/`after_row` JSONB diffs |

### Materialized views

`analytics.mv_daily_sales` (date × region × channel) and
`analytics.mv_product_stats` (per-product sales + ratings). Refresh with
`make analyze`.

### Views

- `shop.v_order_lines` — flattened order/item/product/seller join
- `shop.v_paid_orders` — `status IN ('paid','packed','shipped','delivered')`
- `shop.v_current_prices` — open row per variant from `price_history`
- `hr.v_org_chart` — recursive view (a reference answer for topic 07)
- `practice.v_table_sizes` — row counts and on-disk sizes

---

## Relationships that matter

```
users ──< orders ──< order_items >── product_variants >── products >── categories(tree)
             │            │                                   └──> sellers(group tree)
             ├──< payments ──< refunds
             ├──< shipments ──< shipment_items
             └──< support_tickets ──< ticket_messages(chain)

users ──< user_addresses            users ──< reviews(threaded) >── products
users ──< wishlist_items            users ──< carts ──< cart_items
users.referred_by ──> users         sellers.parent_seller_id ──> sellers

hr.employees.manager_id ──> hr.employees      hr.employees ──< hr.shifts
hr.employees ──< hr.salary_history             hr.employees ──< hr.time_off

analytics.sessions ──< analytics.page_events (by session_id, not FK)
analytics.ad_spend  ── (date, country) ─ orders aggregates
```

## Index inventory (shipped)

Foreign-key btrees plus the special types the exercises target:

| Index | Type | Used by |
|---|---|---|
| `idx_products_tsv`, `idx_reviews_tsv` | GIN on `tsvector` | topic 11 |
| `idx_products_attrs_gin` | GIN `jsonb_path_ops` | topic 09 (`@>`, `@?`) |
| `idx_products_tags_gin` | GIN on `text[]` | topic 10 |
| `idx_products_title_trgm` | GIN `gin_trgm_ops` | topic 11 fuzzy |
| `idx_page_events_brin` | BRIN | topic 14 |
| `idx_orders_pending` | partial | topic 14 |
| `idx_users_lower_email` | expression | topic 14 |
| `idx_orders_user_covering` | btree + `INCLUDE` | index-only scans |
| `user_addresses_one_default` | partial unique | constraint practice |
| `price_history`, `salary_history`, `dim_seller_scd2` | GiST `EXCLUDE` | temporal integrity |

`db/perf/optional_indexes.sql` holds seven more indexes that are **not**
created by `make build`; topic 14 asks you to discover them and measure the
difference (`make indexes`).

## Determinism

All seed values come from `practice.prand*` functions built on
`hashtextextended(row_id, salt)` — never `random()`. Consequences:

- Two clones at the same `SCALE` contain byte-identical data, so reference
  answers and expected row counts stay valid.
- Ids are predictable: `order_items.order_item_id = order_id * 8 + k`,
  `user_addresses.address_id = user_id * 4 + k`, and
  `sessions.session_id = md5(n || '-session')::uuid`.
- Distributions are intentional: Zipf-skewed customers and products, high
  ratings, ~8 % payment retries, ~12 % of products never sold, ~4 % missing
  weekday FX rates, ~28 % missing shift days.
