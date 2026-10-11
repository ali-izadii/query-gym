-- ============================================================
-- 10_matviews.sql : materialized views (refresh practice + perf baselines)
-- ============================================================
SET search_path = analytics, shop, public;

DROP MATERIALIZED VIEW IF EXISTS analytics.mv_daily_sales CASCADE;
CREATE MATERIALIZED VIEW analytics.mv_daily_sales AS
SELECT o.placed_at::date            AS sale_date,
       c.region,
       o.channel,
       count(*)                     AS orders,
       count(DISTINCT o.user_id)    AS buyers,
       sum(o.grand_total)           AS revenue,
       sum(o.discount_total)        AS discounts,
       avg(o.grand_total)           AS avg_order_value
FROM shop.orders o
JOIN shop.users u    ON u.user_id = o.user_id
JOIN shop.countries c ON c.country_code = u.country_code
WHERE o.status IN ('paid','packed','shipped','delivered')
GROUP BY 1, 2, 3
WITH NO DATA;

CREATE UNIQUE INDEX ON analytics.mv_daily_sales (sale_date, region, channel);

DROP MATERIALIZED VIEW IF EXISTS analytics.mv_product_stats CASCADE;
CREATE MATERIALIZED VIEW analytics.mv_product_stats AS
SELECT p.product_id,
       p.category_id,
       p.seller_id,
       count(DISTINCT oi.order_id)              AS orders,
       coalesce(sum(oi.qty), 0)                 AS units_sold,
       coalesce(sum(oi.line_total), 0)          AS revenue,
       avg(r.rating)                            AS avg_rating,
       count(r.review_id) FILTER (WHERE r.rating IS NOT NULL) AS review_count
FROM shop.products p
LEFT JOIN shop.order_items oi ON oi.product_id = p.product_id
LEFT JOIN shop.reviews r      ON r.product_id = p.product_id AND r.reply_to IS NULL
GROUP BY 1, 2, 3
WITH NO DATA;

CREATE UNIQUE INDEX ON analytics.mv_product_stats (product_id);

REFRESH MATERIALIZED VIEW analytics.mv_daily_sales;
REFRESH MATERIALIZED VIEW analytics.mv_product_stats;
