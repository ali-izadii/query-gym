-- ============================================================
-- 06_events.sql : sessions + partitioned clickstream + ad spend
-- Largest tables. Generated last so the rest of the DB is usable sooner.
-- ============================================================
SET search_path = analytics, shop, practice, public;

-- ---------- sessions ----------
INSERT INTO analytics.sessions (session_id, user_id, started_at, ended_at, event_count,
                                device, channel, landing_path, converted, revenue)
SELECT md5(n::text || '-session')::uuid,
       CASE WHEN practice.prand(n, 401) < 0.65
            THEN practice.prand_zipf(n, 402, (SELECT n_users FROM practice.seed_config), 1.3) END,
       st.started_at,
       st.started_at + ((practice.prand_int(n, 403, 20, 5400))::text || ' seconds')::interval,
       (1 + practice.prand_int(n, 404, 0, 40))::int,
       practice.prand_pick(n, 405, ARRAY['desktop','mobile','mobile','mobile','tablet']),
       practice.prand_pick(n, 406, ARRAY['organic','organic','paid_search','social','email','direct','affiliate']),
       practice.prand_pick(n, 407, ARRAY['/','/deals','/search','/category/electronics','/category/fashion','/product','/cart']),
       conv.converted,
       CASE WHEN conv.converted THEN round((15 + 400 * power(practice.prand(n, 408), 2))::numeric, 2) ELSE 0 END
FROM generate_series(1, (SELECT n_sessions FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 409, (SELECT t_start FROM practice.seed_config),
                                   (SELECT t_end FROM practice.seed_config)) AS started_at
) st
CROSS JOIN LATERAL (SELECT practice.prand(n, 410) < 0.07 AS converted) conv;

-- ---------- page events ----------
-- Each session gets a realistic funnel: view -> search -> add_to_cart -> checkout -> purchase.
INSERT INTO analytics.page_events (event_id, occurred_at, session_id, user_id, event_type,
                                   page_path, product_id, referrer, device, browser,
                                   country_code, utm, duration_ms)
SELECT n,
       ev.occurred_at,
       s.session_id,
       s.user_id,
       ev.event_type,
       ev.page_path,
       CASE WHEN ev.event_type IN ('view','add_to_cart','purchase')
            THEN practice.prand_zipf(n, 421, (SELECT n_products FROM practice.seed_config), 1.9) END,
       CASE WHEN practice.prand(n, 422) < 0.55
            THEN practice.prand_pick(n, 423, ARRAY['https://google.com/','https://facebook.com/',
                 'https://news.ycombinator.com/','https://instagram.com/','https://bing.com/']) END,
       s.device,
       practice.prand_pick(n, 424, ARRAY['Chrome','Chrome','Chrome','Safari','Firefox','Edge']),
       u.country_code,
       jsonb_strip_nulls(jsonb_build_object(
         'source',   practice.prand_pick(n, 425, ARRAY['google','newsletter','fb','tiktok','direct',NULL]),
         'medium',   practice.prand_pick(n, 426, ARRAY['cpc','organic','email','social',NULL]),
         'campaign', CASE WHEN practice.prand(n, 427) < 0.45
                          THEN practice.prand_pick(n, 428, ARRAY['spring_sale','bf2024','retarget_7d','brand_always_on','app_install'])
                     END,
         'ab_bucket', practice.prand_pick(n, 429, ARRAY['A','B'])
       )),
       (practice.prand_int(n, 430, 150, 90000))::int
FROM generate_series(1, (SELECT n_events FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT ss.session_id, ss.user_id, ss.device, ss.started_at, ss.ended_at
  FROM analytics.sessions ss
  WHERE ss.session_id = md5((practice.prand_int(n, 431, 1, (SELECT n_sessions FROM practice.seed_config)))::text || '-session')::uuid
) s
LEFT JOIN shop.users u ON u.user_id = s.user_id
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 432, s.started_at, s.ended_at) AS occurred_at,
         t.event_type,
         CASE t.event_type
           WHEN 'view'        THEN '/product/' || practice.prand_int(n, 433, 1, 20000)
           WHEN 'search'      THEN '/search?q=' || practice.prand_pick(n, 434, ARRAY['headphones','tent','lamp','running+shoe','blender','monitor'])
           WHEN 'add_to_cart' THEN '/cart/add'
           WHEN 'checkout'    THEN '/checkout'
           WHEN 'purchase'    THEN '/checkout/success'
           ELSE '/' END AS page_path
  FROM (SELECT CASE
                 WHEN practice.prand(n, 435) < 0.58 THEN 'view'
                 WHEN practice.prand(n, 435) < 0.78 THEN 'search'
                 WHEN practice.prand(n, 435) < 0.90 THEN 'add_to_cart'
                 WHEN practice.prand(n, 435) < 0.97 THEN 'checkout'
                 ELSE 'purchase' END AS event_type) t
) ev;

-- a handful of out-of-range rows so the DEFAULT partition is not empty
INSERT INTO analytics.page_events (event_id, occurred_at, session_id, user_id, event_type,
                                   page_path, device, browser)
SELECT 900000000 + n,
       timestamptz '2022-06-15 10:00:00+00' + (n || ' hours')::interval,
       md5(n::text || '-legacy')::uuid,
       NULL, 'view', '/legacy', 'desktop', 'Chrome'
FROM generate_series(1, 500) g(n);

-- ---------- ad spend ----------
INSERT INTO analytics.ad_spend (spend_date, channel, campaign, country_code,
                                impressions, clicks, cost)
SELECT c.day,
       ch.channel,
       cp.campaign,
       co.country_code,
       (practice.prand_int(extract(epoch FROM c.day)::bigint + ascii(ch.channel) + ascii(cp.campaign), 441, 1000, 900000))::bigint,
       (practice.prand_int(extract(epoch FROM c.day)::bigint + ascii(ch.channel) + ascii(cp.campaign), 442, 10, 30000))::bigint,
       round((practice.prand_int(extract(epoch FROM c.day)::bigint + ascii(ch.channel) + ascii(cp.campaign), 443, 50, 40000))::numeric / 10, 2)
FROM analytics.calendar c
CROSS JOIN (VALUES ('paid_search'),('social'),('display'),('email'),('affiliate')) AS ch(channel)
CROSS JOIN (VALUES ('spring_sale'),('bf2024'),('retarget_7d'),('brand_always_on'),('app_install')) AS cp(campaign)
CROSS JOIN LATERAL (
  SELECT cc.country_code FROM shop.countries cc
  WHERE cc.country_code IN ('US','DE','GB','FR','JP','BR','IN','AU')
  ORDER BY cc.country_code
  OFFSET (practice.prand_int(extract(epoch FROM c.day)::bigint + ascii(ch.channel), 444, 0, 7)) LIMIT 1
) co
WHERE c.day BETWEEN date '2023-01-01' AND date '2025-12-31'
  AND practice.prand(extract(epoch FROM c.day)::bigint + ascii(cp.campaign), 445) < 0.55
ON CONFLICT DO NOTHING;

-- ---------- audit log (jsonb before/after diffs) ----------
INSERT INTO analytics.audit_log (table_name, row_pk, action, changed_at, changed_by, before_row, after_row)
SELECT 'shop.orders',
       o.order_id::text,
       'UPDATE',
       o.placed_at + ((practice.prand_int(o.order_id, 451, 1, 500))::text || ' minutes')::interval,
       'emp' || practice.prand_int(o.order_id, 452, 1, 200),
       jsonb_build_object('status','pending','grand_total', o.grand_total),
       jsonb_build_object('status', o.status::text, 'grand_total', o.grand_total)
FROM shop.orders o
WHERE practice.prand(o.order_id, 453) < 0.15;

-- ---------- messy staging rows ----------
INSERT INTO shop.raw_leads (email_raw, name_raw, country_raw, signup_raw, source, amount_raw)
SELECT CASE
         WHEN practice.prand(n, 461) < 0.06 THEN NULL
         WHEN practice.prand(n, 461) < 0.12 THEN '  ' || upper(practice.fake_first_name(n)) || '.' || practice.fake_last_name(n) || '@MAIL.COM  '
         WHEN practice.prand(n, 461) < 0.20 THEN practice.fake_first_name(n) || '@@mail.com'
         ELSE lower(practice.fake_first_name(n) || '.' || practice.fake_last_name(n) || (n % 500) || '@mail.com')
       END,
       CASE WHEN practice.prand(n, 462) < 0.08 THEN NULL
            ELSE practice.fake_first_name(n) || '  ' || practice.fake_last_name(n) END,
       practice.prand_pick(n, 463, ARRAY['DE','de','DE ','Germany','US','usa','U.S.','GB','uk','','FR',NULL]),
       practice.prand_pick(n, 464, ARRAY['2025-01-15','15/01/2025','Jan 15, 2025','2025-13-45','','20250115',NULL]),
       practice.prand_pick(n, 465, ARRAY['webinar','partner','organic','cold_call',NULL]),
       practice.prand_pick(n, 466, ARRAY['1,234.50','€99','99.00','','  42 ','N/A',NULL])
FROM generate_series(1, (SELECT n_raw_leads FROM practice.seed_config)) g(n);

ANALYZE analytics.sessions; ANALYZE analytics.page_events; ANALYZE analytics.ad_spend;
