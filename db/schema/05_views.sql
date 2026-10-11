-- ============================================================
-- 05_views.sql : convenience views + exercise-runner scaffolding
-- ============================================================
SET search_path = shop, hr, analytics, practice, public;

-- Flattened order line view: handy for "rewrite this view as a query" exercises.
CREATE VIEW shop.v_order_lines AS
SELECT o.order_id,
       o.user_id,
       o.placed_at,
       o.status,
       o.channel,
       o.currency_code,
       oi.order_item_id,
       oi.product_id,
       oi.variant_id,
       oi.seller_id,
       p.title        AS product_title,
       p.category_id,
       c.name         AS category_name,
       s.display_name AS seller_name,
       oi.qty,
       oi.unit_price,
       oi.discount,
       oi.line_total
FROM shop.orders o
JOIN shop.order_items oi ON oi.order_id = o.order_id
JOIN shop.products   p   ON p.product_id = oi.product_id
JOIN shop.categories c   ON c.category_id = p.category_id
JOIN shop.sellers    s   ON s.seller_id = oi.seller_id;

-- Revenue recognised = paid/shipped/delivered orders only.
CREATE VIEW shop.v_paid_orders AS
SELECT *
FROM shop.orders
WHERE status IN ('paid','packed','shipped','delivered');

-- Current price per variant (temporal table collapse).
CREATE VIEW shop.v_current_prices AS
SELECT ph.variant_id, ph.price, ph.valid_from
FROM shop.price_history ph
WHERE ph.valid_to IS NULL;

-- Org chart with full path; a reference answer the exercises ask you to rebuild.
CREATE RECURSIVE VIEW hr.v_org_chart(employee_id, manager_id, full_name, level, path) AS
  SELECT e.employee_id, e.manager_id,
         e.first_name || ' ' || e.last_name,
         1,
         ARRAY[e.employee_id]
  FROM hr.employees e
  WHERE e.manager_id IS NULL
UNION ALL
  SELECT e.employee_id, e.manager_id,
         e.first_name || ' ' || e.last_name,
         oc.level + 1,
         oc.path || e.employee_id
  FROM hr.employees e
  JOIN v_org_chart oc ON e.manager_id = oc.employee_id;

-- ---------- runner scaffolding ----------
CREATE TABLE practice.exercise_runs (
  run_id      bigserial PRIMARY KEY,
  exercise_id text NOT NULL,
  ran_at      timestamptz NOT NULL DEFAULT now(),
  duration_ms numeric(12,3),
  row_count   bigint,
  passed      boolean,
  note        text
);

CREATE VIEW practice.v_table_sizes AS
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       c.reltuples::bigint AS approx_rows,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
       pg_total_relation_size(c.oid) AS total_bytes
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','p','m')
  AND n.nspname IN ('shop','hr','analytics')
ORDER BY pg_total_relation_size(c.oid) DESC;

-- Timer helper used by some performance exercises.
CREATE OR REPLACE FUNCTION practice.time_query(sql text)
RETURNS TABLE (ms numeric, rows_returned bigint)
LANGUAGE plpgsql AS $$
DECLARE
  t0 timestamptz;
  n  bigint;
BEGIN
  t0 := clock_timestamp();
  EXECUTE format('SELECT count(*) FROM (%s) _q', sql) INTO n;
  RETURN QUERY SELECT round(extract(epoch FROM clock_timestamp() - t0) * 1000, 3)::numeric, n;
END $$;
