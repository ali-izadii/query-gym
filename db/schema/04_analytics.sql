-- ============================================================
-- 04_analytics.sql : event stream (partitioned), ad spend, fx, budgets
-- ============================================================
SET search_path = analytics, shop, practice, public;

-- ---------- clickstream, range-partitioned by month ----------
CREATE TABLE analytics.page_events (
  event_id    bigint      NOT NULL,
  occurred_at timestamptz NOT NULL,
  session_id  uuid        NOT NULL,
  user_id     bigint,                              -- NULL => anonymous
  event_type  text        NOT NULL,                -- view / search / add_to_cart / checkout / purchase
  page_path   text        NOT NULL,
  product_id  bigint,
  referrer    text,
  device      text        NOT NULL,                -- desktop / mobile / tablet
  browser     text        NOT NULL,
  country_code char(2),
  utm         jsonb       NOT NULL DEFAULT '{}'::jsonb,
  duration_ms int,
  PRIMARY KEY (event_id, occurred_at)
) PARTITION BY RANGE (occurred_at);

-- 2023-01 .. 2025-12 monthly partitions + catch-all default
DO $$
DECLARE
  m date := date '2023-01-01';
BEGIN
  WHILE m < date '2026-01-01' LOOP
    EXECUTE format(
      'CREATE TABLE analytics.page_events_%s PARTITION OF analytics.page_events
         FOR VALUES FROM (%L) TO (%L)',
      to_char(m, 'YYYY_MM'), m, (m + interval '1 month')::date);
    m := (m + interval '1 month')::date;
  END LOOP;
END $$;

CREATE TABLE analytics.page_events_default
  PARTITION OF analytics.page_events DEFAULT;

-- ---------- session roll-up (funnel / sessionisation practice) ----------
CREATE TABLE analytics.sessions (
  session_id   uuid PRIMARY KEY,
  user_id      bigint REFERENCES shop.users(user_id),
  started_at   timestamptz NOT NULL,
  ended_at     timestamptz NOT NULL,
  event_count  int NOT NULL,
  device       text NOT NULL,
  channel      text NOT NULL,            -- organic / paid_search / social / email / direct
  landing_path text NOT NULL,
  converted    boolean NOT NULL DEFAULT false,
  revenue      numeric(12,2) NOT NULL DEFAULT 0
);

-- ---------- marketing spend (daily grain, for join-to-conversions practice) ----------
CREATE TABLE analytics.ad_spend (
  spend_date   date NOT NULL,
  channel      text NOT NULL,
  campaign     text NOT NULL,
  country_code char(2) NOT NULL REFERENCES shop.countries(country_code),
  impressions  bigint NOT NULL,
  clicks       bigint NOT NULL,
  cost         numeric(12,2) NOT NULL,
  PRIMARY KEY (spend_date, channel, campaign, country_code)
);

-- ---------- fx rates: sparse series => LOCF / gap filling practice ----------
CREATE TABLE analytics.fx_rates (
  rate_date     date NOT NULL,
  currency_code char(3) NOT NULL REFERENCES shop.currencies(currency_code),
  rate_to_usd   numeric(14,8) NOT NULL,
  PRIMARY KEY (rate_date, currency_code)
);

-- ---------- targets (budget vs actual) ----------
CREATE TABLE analytics.monthly_targets (
  target_month date NOT NULL,                       -- first day of month
  region       text NOT NULL,
  revenue_target numeric(14,2) NOT NULL,
  orders_target  int NOT NULL,
  PRIMARY KEY (target_month, region)
);

-- ---------- calendar dimension (gap filling without generate_series) ----------
CREATE TABLE analytics.calendar (
  day        date PRIMARY KEY,
  year       int  NOT NULL,
  quarter    int  NOT NULL,
  month      int  NOT NULL,
  month_name text NOT NULL,
  week_iso   int  NOT NULL,
  day_of_week int NOT NULL,
  is_weekend boolean NOT NULL,
  is_holiday boolean NOT NULL DEFAULT false,
  fiscal_year int NOT NULL
);

-- ---------- slowly changing dimension type 2 ----------
CREATE TABLE analytics.dim_seller_scd2 (
  sk           bigserial PRIMARY KEY,
  seller_id    int  NOT NULL,
  tier         shop.seller_tier NOT NULL,
  country_code char(2) NOT NULL,
  valid_from   date NOT NULL,
  valid_to     date,
  is_current   boolean NOT NULL,
  EXCLUDE USING gist (seller_id WITH =, daterange(valid_from, valid_to, '[)') WITH &&)
);

-- ---------- append-only audit log, jsonb diffs ----------
CREATE TABLE analytics.audit_log (
  audit_id   bigserial PRIMARY KEY,
  table_name text NOT NULL,
  row_pk     text NOT NULL,
  action     text NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  changed_at timestamptz NOT NULL,
  changed_by text NOT NULL,
  before_row jsonb,
  after_row  jsonb
);
