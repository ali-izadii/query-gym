-- ============================================================
-- 00_config.sql : row-count plan, derived from :scale
-- Everything downstream reads practice.seed_config, so the whole dataset
-- is reproducible: same scale => same rows, same ids, same values.
-- ============================================================
\if :{?scale}
\else
  \set scale 1
\endif

SET search_path = practice, shop, hr, analytics, public;

DROP TABLE IF EXISTS practice.seed_config;

CREATE TABLE practice.seed_config AS
SELECT
  (:scale)::int                     AS scale,
  timestamptz '2023-01-01 00:00:00+00' AS t_start,
  timestamptz '2025-12-31 23:59:59+00' AS t_end,
  -- fixed-size dimensions (independent of scale)
  248::int                          AS n_categories,
  -- scaled facts
  (2000  * :scale)::int             AS n_sellers,
  (120   * :scale)::int             AS n_warehouses,
  (50000 * :scale)::bigint          AS n_users,
  (20000 * :scale)::bigint          AS n_products,
  (3)::int                          AS variants_per_product,
  (60)::int                         AS n_promotions,
  (250000 * :scale)::bigint         AS n_orders,
  (60000  * :scale)::bigint         AS n_carts,
  (150000 * :scale)::bigint         AS n_reviews,
  (80000  * :scale)::bigint         AS n_wishlist,
  (20000  * :scale)::bigint         AS n_tickets,
  (1200   * :scale)::int            AS n_employees,
  (300000 * :scale)::bigint         AS n_sessions,
  (2000000 * :scale)::bigint        AS n_events,
  (5000)::int                       AS n_raw_leads;

ALTER TABLE practice.seed_config ADD PRIMARY KEY (scale);

\echo '--- seed plan ---'
SELECT scale, n_users, n_products, n_orders, n_events FROM practice.seed_config;
