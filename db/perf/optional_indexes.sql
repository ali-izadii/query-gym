-- ============================================================
-- 80_optional_indexes.sql  (NOT applied by `make build`)
-- These are the indexes the performance exercises ask you to discover.
-- Run selectively:  \i /db/perf/optional_indexes.sql
-- Then re-run the matching EXPLAIN and compare plans / timings.
-- ============================================================
SET search_path = shop, hr, analytics, public;

-- T14-02: seller revenue by month
CREATE INDEX IF NOT EXISTS idx_order_items_seller_order ON shop.order_items(seller_id, order_id);

-- T14-04: "orders of user X in a date window"
CREATE INDEX IF NOT EXISTS idx_orders_user_placed ON shop.orders(user_id, placed_at DESC);

-- T14-06: funnel per event type inside a month (partition-local)
CREATE INDEX IF NOT EXISTS idx_page_events_type_time ON analytics.page_events(event_type, occurred_at);

-- T14-08: sort-avoidance for top-N per category
CREATE INDEX IF NOT EXISTS idx_products_cat_price ON shop.products(category_id, base_price DESC);

-- T14-10: payments status filter is very selective
CREATE INDEX IF NOT EXISTS idx_payments_status_created ON shop.payments(status, created_at);

-- T14-12: review ranking per product
CREATE INDEX IF NOT EXISTS idx_reviews_product_rating ON shop.reviews(product_id, rating DESC)
  WHERE reply_to IS NULL;

-- T14-14: case-insensitive seller name search
CREATE INDEX IF NOT EXISTS idx_sellers_display_trgm ON shop.sellers USING gin(display_name gin_trgm_ops);

ANALYZE shop.order_items; ANALYZE shop.orders; ANALYZE analytics.page_events;
ANALYZE shop.products; ANALYZE shop.payments; ANALYZE shop.reviews; ANALYZE shop.sellers;
