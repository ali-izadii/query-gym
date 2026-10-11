-- ============================================================
-- 02_shop_core.sql : transactional marketplace core
-- ============================================================
SET search_path = shop, practice, public;

-- ---------- reference data ----------
CREATE TABLE shop.countries (
  country_code  char(2) PRIMARY KEY,
  country_name  text        NOT NULL,
  region        text        NOT NULL,       -- EMEA / AMER / APAC
  subregion     text        NOT NULL,
  currency_code char(3)     NOT NULL,
  vat_rate      numeric(5,4) NOT NULL DEFAULT 0,
  is_eu         boolean     NOT NULL DEFAULT false
);

CREATE TABLE shop.currencies (
  currency_code char(3) PRIMARY KEY,
  currency_name text    NOT NULL,
  minor_units   smallint NOT NULL DEFAULT 2
);

-- ---------- hierarchy: category tree (recursive CTE practice) ----------
CREATE TABLE shop.categories (
  category_id   int PRIMARY KEY,
  parent_id     int REFERENCES shop.categories(category_id),
  name          text    NOT NULL,
  slug          text    NOT NULL UNIQUE,
  depth         smallint NOT NULL,          -- denormalised, verify it with a recursive CTE
  is_active     boolean NOT NULL DEFAULT true,
  commission_pct numeric(5,4),              -- NULL => inherit from ancestor (recursion practice)
  CONSTRAINT categories_no_self_parent CHECK (parent_id IS DISTINCT FROM category_id)
);

-- ---------- customers ----------
CREATE TYPE shop.user_segment AS ENUM ('new','casual','loyal','vip','churned');

CREATE TABLE shop.users (
  user_id       bigint PRIMARY KEY,
  email         text   NOT NULL UNIQUE,
  first_name    text   NOT NULL,
  last_name     text   NOT NULL,
  full_name     text GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  birth_date    date,                        -- nullable on purpose
  country_code  char(2) NOT NULL REFERENCES shop.countries(country_code),
  signup_at     timestamptz NOT NULL,
  last_login_at timestamptz,                 -- NULL = never logged in
  segment       shop.user_segment NOT NULL DEFAULT 'new',
  referred_by   bigint REFERENCES shop.users(user_id),   -- self-referencing graph
  loyalty_points int NOT NULL DEFAULT 0,
  marketing_opt_in boolean NOT NULL DEFAULT false,
  prefs         jsonb  NOT NULL DEFAULT '{}'::jsonb,
  deleted_at    timestamptz
);

CREATE TABLE shop.user_addresses (
  address_id   bigint PRIMARY KEY,
  user_id      bigint NOT NULL REFERENCES shop.users(user_id),
  label        text   NOT NULL,              -- home / work / other
  line1        text   NOT NULL,
  city         text   NOT NULL,
  postal_code  text,
  country_code char(2) NOT NULL REFERENCES shop.countries(country_code),
  is_default   boolean NOT NULL DEFAULT false,
  geo_lat      numeric(8,5),
  geo_lon      numeric(8,5)
);
-- only one default address per user => partial unique index practice
CREATE UNIQUE INDEX user_addresses_one_default
  ON shop.user_addresses(user_id) WHERE is_default;

-- ---------- sellers ----------
CREATE TYPE shop.seller_tier AS ENUM ('bronze','silver','gold','platinum');

CREATE TABLE shop.sellers (
  seller_id      int PRIMARY KEY,
  legal_name     text NOT NULL,
  display_name   text NOT NULL,
  country_code   char(2) NOT NULL REFERENCES shop.countries(country_code),
  tier           shop.seller_tier NOT NULL DEFAULT 'bronze',
  joined_on      date NOT NULL,
  parent_seller_id int REFERENCES shop.sellers(seller_id),  -- franchise / group structure
  rating         numeric(3,2),
  is_suspended   boolean NOT NULL DEFAULT false,
  payout_schedule text NOT NULL DEFAULT 'monthly',
  metadata       jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE shop.warehouses (
  warehouse_id int PRIMARY KEY,
  code         text NOT NULL UNIQUE,
  seller_id    int  REFERENCES shop.sellers(seller_id),   -- NULL => platform-owned
  country_code char(2) NOT NULL REFERENCES shop.countries(country_code),
  city         text NOT NULL,
  capacity_units int NOT NULL
);

-- ---------- catalogue ----------
CREATE TYPE shop.product_status AS ENUM ('draft','active','paused','archived');

CREATE TABLE shop.products (
  product_id   bigint PRIMARY KEY,
  seller_id    int  NOT NULL REFERENCES shop.sellers(seller_id),
  category_id  int  NOT NULL REFERENCES shop.categories(category_id),
  title        text NOT NULL,
  description  text,
  brand        text,
  status       shop.product_status NOT NULL DEFAULT 'active',
  created_at   timestamptz NOT NULL,
  updated_at   timestamptz NOT NULL,
  base_price   numeric(12,2) NOT NULL CHECK (base_price >= 0),
  currency_code char(3) NOT NULL REFERENCES shop.currencies(currency_code),
  weight_grams int,
  tags         text[] NOT NULL DEFAULT '{}',          -- array operators practice
  attrs        jsonb  NOT NULL DEFAULT '{}'::jsonb,   -- JSONB practice
  -- full text search practice, maintained by the engine:
  search_tsv   tsvector GENERATED ALWAYS AS (
                 setweight(to_tsvector('english', coalesce(title,'')), 'A') ||
                 setweight(to_tsvector('english', coalesce(brand,'')), 'B') ||
                 setweight(to_tsvector('english', coalesce(description,'')), 'C')
               ) STORED
);

CREATE TABLE shop.product_variants (
  variant_id   bigint PRIMARY KEY,
  product_id   bigint NOT NULL REFERENCES shop.products(product_id),
  sku          text   NOT NULL UNIQUE,
  variant_name text   NOT NULL,
  options      jsonb  NOT NULL DEFAULT '{}'::jsonb,   -- {"size":"M","color":"red"}
  price_delta  numeric(10,2) NOT NULL DEFAULT 0,
  barcode      text,
  is_active    boolean NOT NULL DEFAULT true
);

CREATE TABLE shop.inventory (
  warehouse_id int    NOT NULL REFERENCES shop.warehouses(warehouse_id),
  variant_id   bigint NOT NULL REFERENCES shop.product_variants(variant_id),
  qty_on_hand  int    NOT NULL CHECK (qty_on_hand >= 0),
  qty_reserved int    NOT NULL DEFAULT 0,
  reorder_point int   NOT NULL DEFAULT 0,
  last_counted_at timestamptz,
  PRIMARY KEY (warehouse_id, variant_id)
);

-- temporal table: no overlapping price windows per variant (range + exclusion)
CREATE TABLE shop.price_history (
  price_id    bigserial PRIMARY KEY,
  variant_id  bigint NOT NULL REFERENCES shop.product_variants(variant_id),
  price       numeric(12,2) NOT NULL,
  valid_from  date NOT NULL,
  valid_to    date,                                  -- NULL = still current
  valid_range daterange GENERATED ALWAYS AS (
                daterange(valid_from, valid_to, '[)')
              ) STORED,
  EXCLUDE USING gist (variant_id WITH =, daterange(valid_from, valid_to, '[)') WITH &&)
);

-- ---------- promotions ----------
CREATE TABLE shop.promotions (
  promo_id     int PRIMARY KEY,
  code         text NOT NULL UNIQUE,
  description  text NOT NULL,
  discount_type text NOT NULL CHECK (discount_type IN ('percent','fixed','free_shipping')),
  discount_value numeric(10,2) NOT NULL,
  min_order_amount numeric(12,2) NOT NULL DEFAULT 0,
  active_range tstzrange NOT NULL,
  max_redemptions int,
  rules        jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE shop.promotion_categories (     -- many-to-many
  promo_id    int NOT NULL REFERENCES shop.promotions(promo_id),
  category_id int NOT NULL REFERENCES shop.categories(category_id),
  PRIMARY KEY (promo_id, category_id)
);

-- ---------- carts (abandonment / funnel practice) ----------
CREATE TABLE shop.carts (
  cart_id     bigint PRIMARY KEY,
  user_id     bigint REFERENCES shop.users(user_id),   -- NULL => guest cart
  session_id  uuid NOT NULL,
  created_at  timestamptz NOT NULL,
  updated_at  timestamptz NOT NULL,
  status      text NOT NULL CHECK (status IN ('open','converted','abandoned','merged')),
  converted_order_id bigint                           -- FK added after orders
);

CREATE TABLE shop.cart_items (
  cart_id    bigint NOT NULL REFERENCES shop.carts(cart_id),
  variant_id bigint NOT NULL REFERENCES shop.product_variants(variant_id),
  qty        int NOT NULL CHECK (qty > 0),
  added_at   timestamptz NOT NULL,
  unit_price numeric(12,2) NOT NULL,
  PRIMARY KEY (cart_id, variant_id)
);

-- ---------- orders ----------
CREATE TYPE shop.order_status AS ENUM
  ('pending','paid','packed','shipped','delivered','cancelled','returned');

CREATE TABLE shop.orders (
  order_id      bigint PRIMARY KEY,
  user_id       bigint NOT NULL REFERENCES shop.users(user_id),
  status        shop.order_status NOT NULL,
  placed_at     timestamptz NOT NULL,
  paid_at       timestamptz,
  cancelled_at  timestamptz,
  currency_code char(3) NOT NULL REFERENCES shop.currencies(currency_code),
  ship_address_id bigint REFERENCES shop.user_addresses(address_id),
  promo_id      int REFERENCES shop.promotions(promo_id),
  channel       text NOT NULL CHECK (channel IN ('web','ios','android','partner_api')),
  item_total    numeric(12,2) NOT NULL DEFAULT 0,
  discount_total numeric(12,2) NOT NULL DEFAULT 0,
  shipping_fee  numeric(12,2) NOT NULL DEFAULT 0,
  tax_total     numeric(12,2) NOT NULL DEFAULT 0,
  grand_total   numeric(12,2) NOT NULL DEFAULT 0,
  notes         text
);

ALTER TABLE shop.carts
  ADD CONSTRAINT carts_converted_order_fk
  FOREIGN KEY (converted_order_id) REFERENCES shop.orders(order_id);

CREATE TABLE shop.order_items (
  order_item_id bigint PRIMARY KEY,
  order_id      bigint NOT NULL REFERENCES shop.orders(order_id),
  variant_id    bigint NOT NULL REFERENCES shop.product_variants(variant_id),
  product_id    bigint NOT NULL REFERENCES shop.products(product_id),  -- denormalised on purpose
  seller_id     int    NOT NULL REFERENCES shop.sellers(seller_id),
  qty           int    NOT NULL CHECK (qty > 0),
  unit_price    numeric(12,2) NOT NULL,
  discount      numeric(12,2) NOT NULL DEFAULT 0,
  tax_amount    numeric(12,2) NOT NULL DEFAULT 0,
  line_total    numeric(12,2) GENERATED ALWAYS AS (qty * unit_price - discount) STORED,
  fulfilled_from_warehouse int REFERENCES shop.warehouses(warehouse_id)
);

CREATE TABLE shop.payments (
  payment_id   bigint PRIMARY KEY,
  order_id     bigint NOT NULL REFERENCES shop.orders(order_id),
  method       text NOT NULL CHECK (method IN ('card','paypal','bank_transfer','wallet','cod','gift_card')),
  amount       numeric(12,2) NOT NULL,
  currency_code char(3) NOT NULL REFERENCES shop.currencies(currency_code),
  status       text NOT NULL CHECK (status IN ('authorized','captured','failed','voided','chargeback')),
  created_at   timestamptz NOT NULL,
  captured_at  timestamptz,
  provider_ref text,
  risk_score   numeric(4,3)
);

CREATE TABLE shop.refunds (
  refund_id   bigint PRIMARY KEY,
  payment_id  bigint NOT NULL REFERENCES shop.payments(payment_id),
  order_item_id bigint REFERENCES shop.order_items(order_item_id),  -- NULL => order level
  amount      numeric(12,2) NOT NULL CHECK (amount > 0),
  reason      text NOT NULL,
  created_at  timestamptz NOT NULL,
  approved_by int                     -- hr.employees, FK added in 03_hr.sql
);

CREATE TABLE shop.shipments (
  shipment_id   bigint PRIMARY KEY,
  order_id      bigint NOT NULL REFERENCES shop.orders(order_id),
  carrier       text NOT NULL,
  tracking_code text,
  shipped_at    timestamptz,
  delivered_at  timestamptz,
  status        text NOT NULL CHECK (status IN ('label_created','in_transit','delivered','lost','returned')),
  weight_grams  int,
  cost          numeric(10,2)
);

CREATE TABLE shop.shipment_items (
  shipment_id   bigint NOT NULL REFERENCES shop.shipments(shipment_id),
  order_item_id bigint NOT NULL REFERENCES shop.order_items(order_item_id),
  qty           int NOT NULL CHECK (qty > 0),
  PRIMARY KEY (shipment_id, order_item_id)
);

-- ---------- reviews (threaded => recursion) ----------
CREATE TABLE shop.reviews (
  review_id     bigint PRIMARY KEY,
  product_id    bigint NOT NULL REFERENCES shop.products(product_id),
  user_id       bigint NOT NULL REFERENCES shop.users(user_id),
  order_item_id bigint REFERENCES shop.order_items(order_item_id),  -- NULL => unverified review
  rating        smallint CHECK (rating BETWEEN 1 AND 5),            -- NULL for replies
  title         text,
  body          text,
  created_at    timestamptz NOT NULL,
  helpful_votes int NOT NULL DEFAULT 0,
  reply_to      bigint REFERENCES shop.reviews(review_id),          -- threaded replies
  is_flagged    boolean NOT NULL DEFAULT false,
  body_tsv      tsvector GENERATED ALWAYS AS (
                  to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,''))
                ) STORED
);

CREATE TABLE shop.wishlist_items (
  user_id    bigint NOT NULL REFERENCES shop.users(user_id),
  product_id bigint NOT NULL REFERENCES shop.products(product_id),
  added_at   timestamptz NOT NULL,
  PRIMARY KEY (user_id, product_id)
);

-- ---------- support (threaded messages, SLA practice) ----------
CREATE TABLE shop.support_tickets (
  ticket_id   bigint PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES shop.users(user_id),
  order_id    bigint REFERENCES shop.orders(order_id),
  subject     text NOT NULL,
  priority    text NOT NULL CHECK (priority IN ('low','normal','high','urgent')),
  status      text NOT NULL CHECK (status IN ('open','pending','solved','closed')),
  opened_at   timestamptz NOT NULL,
  first_response_at timestamptz,
  solved_at   timestamptz,
  assigned_to int,                   -- hr.employees, FK added in 03_hr.sql
  csat_score  smallint CHECK (csat_score BETWEEN 1 AND 5)
);

CREATE TABLE shop.ticket_messages (
  message_id  bigint PRIMARY KEY,
  ticket_id   bigint NOT NULL REFERENCES shop.support_tickets(ticket_id),
  parent_message_id bigint REFERENCES shop.ticket_messages(message_id),
  author_kind text NOT NULL CHECK (author_kind IN ('customer','agent','system')),
  author_id   bigint,
  body        text NOT NULL,
  sent_at     timestamptz NOT NULL
);

-- ---------- deliberately dirty staging table (data-quality exercises) ----------
CREATE TABLE shop.raw_leads (
  raw_id       bigserial PRIMARY KEY,
  email_raw    text,              -- mixed case, whitespace, duplicates, NULLs
  name_raw     text,
  country_raw  text,              -- 'de', 'DE ', 'Germany', NULL
  signup_raw   text,              -- several date formats
  source       text,
  amount_raw   text               -- '1,234.50', '€99', '', NULL
);

COMMENT ON TABLE shop.raw_leads IS
  'Intentionally messy: NULLs, duplicates, mixed formats. Used by the data-cleaning topic.';
