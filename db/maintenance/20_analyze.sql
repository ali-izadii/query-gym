-- ============================================================
-- 20_analyze.sql : extended statistics + full ANALYZE
-- ============================================================
SET search_path = shop, hr, analytics, public;

-- correlated columns the planner otherwise mis-estimates
CREATE STATISTICS IF NOT EXISTS stat_orders_status_channel (dependencies, ndistinct)
  ON status, channel FROM shop.orders;

CREATE STATISTICS IF NOT EXISTS stat_products_cat_seller (dependencies, ndistinct)
  ON category_id, seller_id FROM shop.products;

CREATE STATISTICS IF NOT EXISTS stat_events_type_device (dependencies, ndistinct)
  ON event_type, device FROM analytics.page_events;

ANALYZE;
