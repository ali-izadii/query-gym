-- ============================================================
-- 06_indexes.sql : the "shipped" index set.
-- Deliberately incomplete: the performance topic asks you to find the
-- missing ones. See db/maintenance/80_optional_indexes.sql for the
-- indexes you are supposed to discover yourself.
-- ============================================================
SET search_path = shop, hr, analytics, public;

-- ---------- foreign-key support (btree) ----------
CREATE INDEX idx_users_country           ON shop.users(country_code);
CREATE INDEX idx_users_signup            ON shop.users(signup_at);
CREATE INDEX idx_users_referred_by       ON shop.users(referred_by) WHERE referred_by IS NOT NULL;
CREATE INDEX idx_addresses_user          ON shop.user_addresses(user_id);

CREATE INDEX idx_categories_parent       ON shop.categories(parent_id);
CREATE INDEX idx_sellers_parent          ON shop.sellers(parent_seller_id);

CREATE INDEX idx_products_seller         ON shop.products(seller_id);
CREATE INDEX idx_products_category       ON shop.products(category_id);
CREATE INDEX idx_variants_product        ON shop.product_variants(product_id);

CREATE INDEX idx_orders_user             ON shop.orders(user_id);
CREATE INDEX idx_orders_placed_at        ON shop.orders(placed_at);
CREATE INDEX idx_order_items_order       ON shop.order_items(order_id);
CREATE INDEX idx_order_items_product     ON shop.order_items(product_id);
CREATE INDEX idx_payments_order          ON shop.payments(order_id);
CREATE INDEX idx_refunds_payment         ON shop.refunds(payment_id);
CREATE INDEX idx_shipments_order         ON shop.shipments(order_id);
CREATE INDEX idx_reviews_product         ON shop.reviews(product_id);
CREATE INDEX idx_reviews_user            ON shop.reviews(user_id);
CREATE INDEX idx_reviews_reply_to        ON shop.reviews(reply_to) WHERE reply_to IS NOT NULL;
CREATE INDEX idx_cart_items_variant      ON shop.cart_items(variant_id);
CREATE INDEX idx_tickets_user            ON shop.support_tickets(user_id);
CREATE INDEX idx_ticket_messages_ticket  ON shop.ticket_messages(ticket_id);

CREATE INDEX idx_employees_manager       ON hr.employees(manager_id);
CREATE INDEX idx_employees_department    ON hr.employees(department_id);
CREATE INDEX idx_shifts_employee_date    ON hr.shifts(employee_id, shift_date);
CREATE INDEX idx_salary_history_emp      ON hr.salary_history(employee_id);

CREATE INDEX idx_sessions_user           ON analytics.sessions(user_id);
CREATE INDEX idx_sessions_started        ON analytics.sessions(started_at);

-- ---------- special index types to practise with ----------
-- GIN on tsvector: full text search
CREATE INDEX idx_products_tsv            ON shop.products USING gin(search_tsv);
CREATE INDEX idx_reviews_tsv             ON shop.reviews  USING gin(body_tsv);

-- GIN on jsonb: containment / key-exists queries
CREATE INDEX idx_products_attrs_gin      ON shop.products USING gin(attrs jsonb_path_ops);

-- GIN on array: tag overlap
CREATE INDEX idx_products_tags_gin       ON shop.products USING gin(tags);

-- trigram: ILIKE '%foo%' and fuzzy matching
CREATE INDEX idx_products_title_trgm     ON shop.products USING gin(title gin_trgm_ops);

-- BRIN: giant append-only time column, tiny index
CREATE INDEX idx_page_events_brin        ON analytics.page_events USING brin(occurred_at)
  WITH (pages_per_range = 32);

-- partial: hot subset only
CREATE INDEX idx_orders_pending          ON shop.orders(placed_at) WHERE status = 'pending';

-- expression index: case-insensitive email lookup
CREATE INDEX idx_users_lower_email       ON shop.users(lower(email));

-- covering / INCLUDE index: index-only scan practice
CREATE INDEX idx_orders_user_covering    ON shop.orders(user_id, placed_at)
  INCLUDE (grand_total, status);

COMMENT ON INDEX shop.idx_orders_user_covering IS
  'INCLUDE columns enable index-only scans; compare EXPLAIN with and without it.';
