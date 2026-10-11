-- ============================================================
-- 01_reference.sql : countries, currencies, calendar, fx, category tree
-- ============================================================
SET search_path = shop, analytics, practice, public;

INSERT INTO shop.currencies (currency_code, currency_name, minor_units) VALUES
  ('USD','US Dollar',2), ('EUR','Euro',2), ('GBP','Pound Sterling',2),
  ('JPY','Japanese Yen',0), ('CAD','Canadian Dollar',2), ('AUD','Australian Dollar',2),
  ('BRL','Brazilian Real',2), ('INR','Indian Rupee',2), ('SEK','Swedish Krona',2),
  ('CHF','Swiss Franc',2), ('PLN','Polish Zloty',2), ('TRY','Turkish Lira',2),
  ('AED','UAE Dirham',2), ('ZAR','South African Rand',2), ('SGD','Singapore Dollar',2),
  ('MXN','Mexican Peso',2), ('NOK','Norwegian Krone',2), ('KRW','South Korean Won',0);

INSERT INTO shop.countries (country_code, country_name, region, subregion, currency_code, vat_rate, is_eu) VALUES
  ('US','United States','AMER','North America','USD',0.0000,false),
  ('CA','Canada','AMER','North America','CAD',0.0500,false),
  ('MX','Mexico','AMER','Latin America','MXN',0.1600,false),
  ('BR','Brazil','AMER','Latin America','BRL',0.1700,false),
  ('GB','United Kingdom','EMEA','Western Europe','GBP',0.2000,false),
  ('DE','Germany','EMEA','Western Europe','EUR',0.1900,true),
  ('FR','France','EMEA','Western Europe','EUR',0.2000,true),
  ('NL','Netherlands','EMEA','Western Europe','EUR',0.2100,true),
  ('ES','Spain','EMEA','Southern Europe','EUR',0.2100,true),
  ('IT','Italy','EMEA','Southern Europe','EUR',0.2200,true),
  ('PL','Poland','EMEA','Eastern Europe','PLN',0.2300,true),
  ('SE','Sweden','EMEA','Nordics','SEK',0.2500,true),
  ('NO','Norway','EMEA','Nordics','NOK',0.2500,false),
  ('CH','Switzerland','EMEA','Western Europe','CHF',0.0770,false),
  ('TR','Turkey','EMEA','Middle East','TRY',0.2000,false),
  ('AE','United Arab Emirates','EMEA','Middle East','AED',0.0500,false),
  ('ZA','South Africa','EMEA','Africa','ZAR',0.1500,false),
  ('IN','India','APAC','South Asia','INR',0.1800,false),
  ('JP','Japan','APAC','East Asia','JPY',0.1000,false),
  ('KR','South Korea','APAC','East Asia','KRW',0.1000,false),
  ('SG','Singapore','APAC','South East Asia','SGD',0.0800,false),
  ('AU','Australia','APAC','Oceania','AUD',0.1000,false);

-- ---------- calendar 2022-01-01 .. 2026-12-31 ----------
INSERT INTO analytics.calendar (day, year, quarter, month, month_name, week_iso,
                                day_of_week, is_weekend, is_holiday, fiscal_year)
SELECT d::date,
       extract(year    FROM d)::int,
       extract(quarter FROM d)::int,
       extract(month   FROM d)::int,
       to_char(d, 'Month'),
       extract(week FROM d)::int,
       extract(isodow FROM d)::int,
       extract(isodow FROM d) >= 6,
       -- a handful of fixed holidays so holiday-aware exercises have data
       (to_char(d,'MM-DD') IN ('01-01','05-01','07-04','11-11','12-24','12-25','12-26','12-31')),
       CASE WHEN extract(month FROM d) >= 2
            THEN extract(year FROM d)::int
            ELSE extract(year FROM d)::int - 1 END
FROM generate_series(date '2022-01-01', date '2026-12-31', interval '1 day') g(d);

-- ---------- fx rates: sparse on purpose (weekdays only, with random gaps) ----------
INSERT INTO analytics.fx_rates (rate_date, currency_code, rate_to_usd)
SELECT c.day,
       cur.currency_code,
       round((base.r * (1 + 0.08 * sin(extract(epoch FROM c.day) / 2600000.0)
                          + 0.01 * (practice.prand(extract(epoch FROM c.day)::bigint, ascii(substr(cur.currency_code,1,1))) - 0.5)
             ))::numeric, 8)
FROM analytics.calendar c
CROSS JOIN shop.currencies cur
JOIN (VALUES
      ('USD',1.0),('EUR',1.09),('GBP',1.27),('JPY',0.0067),('CAD',0.74),('AUD',0.66),
      ('BRL',0.20),('INR',0.012),('SEK',0.095),('CHF',1.13),('PLN',0.25),('TRY',0.031),
      ('AED',0.27),('ZAR',0.053),('SGD',0.74),('MXN',0.058),('NOK',0.093),('KRW',0.00075)
     ) AS base(code, r) ON base.code = cur.currency_code
WHERE c.day BETWEEN date '2022-12-01' AND date '2026-01-31'
  AND NOT c.is_weekend                               -- weekend gaps
  AND practice.prand(extract(epoch FROM c.day)::bigint, 5) > 0.04;  -- ~4% missing weekdays

-- ---------- monthly targets ----------
INSERT INTO analytics.monthly_targets (target_month, region, revenue_target, orders_target)
SELECT m::date,
       r.region,
       round((practice.prand_norm(extract(epoch FROM m)::bigint + ascii(r.region), 3, 1.0, 0.12)
              * CASE r.region WHEN 'AMER' THEN 2400000 WHEN 'EMEA' THEN 1800000 ELSE 900000 END)::numeric, 2),
       (practice.prand_norm(extract(epoch FROM m)::bigint + ascii(r.region), 4, 1.0, 0.1)
        * CASE r.region WHEN 'AMER' THEN 42000 WHEN 'EMEA' THEN 31000 ELSE 15000 END)::int
FROM generate_series(date '2023-01-01', date '2025-12-01', interval '1 month') g(m)
CROSS JOIN (VALUES ('AMER'),('EMEA'),('APAC')) AS r(region);

-- ============================================================
-- category tree: 8 roots -> ~40 level-2 -> ~200 level-3
-- ============================================================
-- level 1
INSERT INTO shop.categories (category_id, parent_id, name, slug, depth, commission_pct)
SELECT i,
       NULL,
       root.name,
       lower(replace(root.name, ' ', '-')),
       1,
       root.pct
FROM (VALUES
  (1,'Electronics',0.0800),
  (2,'Home & Kitchen',0.1000),
  (3,'Fashion',0.1500),
  (4,'Sports & Outdoors',0.1200),
  (5,'Books & Media',0.0500),
  (6,'Beauty & Health',0.1400),
  (7,'Toys & Games',0.1100),
  (8,'Automotive',0.0700)
) AS root(i, name, pct);

-- level 2 : 5 children per root => ids 9..48
INSERT INTO shop.categories (category_id, parent_id, name, slug, depth, commission_pct)
SELECT 8 + (p.category_id - 1) * 5 + s.n,
       p.category_id,
       p.name || ' / ' || practice.prand_pick((p.category_id * 10 + s.n)::bigint, 31, ARRAY[
         'Essentials','Premium','Accessories','Smart','Outlet','Pro','Everyday','Compact',
         'Heavy Duty','Kids','Travel','Designer','Refurbished','Seasonal','Bundles']) ,
       'c2-' || (8 + (p.category_id - 1) * 5 + s.n),
       2,
       CASE WHEN s.n = 1 THEN NULL          -- inherits from parent on purpose
            ELSE round((p.commission_pct * (0.8 + 0.4 * practice.prand((p.category_id*10+s.n)::bigint, 2)))::numeric, 4)
       END
FROM shop.categories p
CROSS JOIN generate_series(1,5) s(n)
WHERE p.depth = 1;

-- level 3 : 5 children per level-2 => ids 49..248
INSERT INTO shop.categories (category_id, parent_id, name, slug, depth, commission_pct)
SELECT 48 + (row_number() OVER (ORDER BY p.category_id, s.n))::int,
       p.category_id,
       split_part(p.name, ' / ', 1) || ' > ' ||
         practice.prand_pick((p.category_id * 100 + s.n)::bigint, 37, ARRAY[
           'Cables','Speakers','Monitors','Chairs','Lamps','Cookware','Sneakers','Jackets',
           'Yoga','Camping','Fiction','Comics','Skincare','Vitamins','Puzzles','Figures',
           'Tyres','Oils','Headphones','Keyboards','Blenders','Rugs','Watches','Backpacks']) ||
         ' ' || s.n,
       'c3-' || (48 + (row_number() OVER (ORDER BY p.category_id, s.n))::int),
       3,
       CASE WHEN s.n <= 2 THEN NULL
            ELSE round((0.05 + 0.12 * practice.prand((p.category_id*100+s.n)::bigint, 6))::numeric, 4)
       END
FROM shop.categories p
CROSS JOIN generate_series(1,5) s(n)
WHERE p.depth = 2;

-- a few deactivated leaves
UPDATE shop.categories
SET is_active = false
WHERE depth = 3 AND practice.prand(category_id, 9) < 0.06;

ANALYZE shop.categories;
