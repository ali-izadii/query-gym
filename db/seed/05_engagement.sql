-- ============================================================
-- 05_engagement.sql : reviews (threaded), wishlists, support tickets, shifts
-- ============================================================
SET search_path = shop, hr, practice, public;

-- ---------- reviews: root reviews from real purchases where possible ----------
INSERT INTO shop.reviews (review_id, product_id, user_id, order_item_id, rating, title, body,
                          created_at, helpful_votes, reply_to, is_flagged)
SELECT n,
       src.product_id,
       src.user_id,
       src.order_item_id,
       rt.rating,
       practice.prand_pick(n, 301, ARRAY['Exactly what I needed','Not as described','Great value',
             'Broke after a week','Would buy again','Mixed feelings','Fast shipping, good product',
             'Disappointed','Perfect gift','Does the job']),
       practice.prand_pick(n, 302, ARRAY[
         'The build quality is solid and it arrived earlier than promised.',
         'Material feels cheap, the seams came apart almost immediately.',
         'Battery life is excellent, easily three days of normal use.',
         'Colour is noticeably different from the product photos.',
         'Customer support replied within an hour and sent a replacement.',
         'Works fine but the instructions are almost unreadable.',
         'Perfect size for travel, fits in a carry-on without trouble.',
         'Stopped charging after two weeks, requesting a refund.']) || ' ' ||
       practice.prand_pick(n, 303, ARRAY[
         'Shipping was quick.', 'Packaging was damaged.', 'Would recommend to a friend.',
         'Price feels high for what you get.', 'Second one I have bought.', '']),
       src.created_at,
       (practice.prand(n, 304) * practice.prand(n, 305) * 400)::int,
       NULL,
       practice.prand(n, 306) < 0.02
FROM generate_series(1, (SELECT n_reviews FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  -- 70% verified (tied to an order item), 30% unverified
  SELECT CASE WHEN practice.prand(n, 307) < 0.7 THEN oi.order_item_id END AS order_item_id,
         coalesce(oi.product_id, practice.prand_zipf(n, 308, (SELECT n_products FROM practice.seed_config), 1.8)) AS product_id,
         coalesce(o.user_id,     practice.prand_zipf(n, 309, (SELECT n_users FROM practice.seed_config), 1.3)) AS user_id,
         coalesce(o.placed_at + ((practice.prand_int(n, 310, 1, 60))::text || ' days')::interval,
                  practice.prand_ts(n, 311, timestamptz '2023-02-01', timestamptz '2025-12-20')) AS created_at
  FROM (SELECT (practice.prand_int(n, 312, 1, (SELECT max(order_item_id) FROM shop.order_items))) AS oi_id) pick
  LEFT JOIN shop.order_items oi ON oi.order_item_id = pick.oi_id
  LEFT JOIN shop.orders o       ON o.order_id = oi.order_id
) src
CROSS JOIN LATERAL (
  -- ratings skewed high, like real marketplaces
  SELECT (CASE
            WHEN practice.prand(n, 313) < 0.52 THEN 5
            WHEN practice.prand(n, 313) < 0.74 THEN 4
            WHEN practice.prand(n, 313) < 0.85 THEN 3
            WHEN practice.prand(n, 313) < 0.93 THEN 2
            ELSE 1 END)::smallint AS rating
) rt
ON CONFLICT (review_id) DO NOTHING;

-- threaded replies: seller/customer answers hanging off existing reviews
INSERT INTO shop.reviews (review_id, product_id, user_id, order_item_id, rating, title, body,
                          created_at, helpful_votes, reply_to, is_flagged)
SELECT (SELECT max(review_id) FROM shop.reviews) + row_number() OVER (ORDER BY r.review_id, lvl.k),
       r.product_id,
       practice.prand_zipf(r.review_id * 10 + lvl.k, 321, (SELECT n_users FROM practice.seed_config), 1.1),
       NULL,
       NULL,                                  -- replies carry no rating
       NULL,
       practice.prand_pick(r.review_id * 10 + lvl.k, 322, ARRAY[
         'Thanks for the feedback, we have shipped a replacement.',
         'Did you try the firmware update from our support page?',
         'Same experience here, mine failed too.',
         'Please contact support with your order id and we will sort it out.',
         'Mine has worked perfectly for six months.']),
       r.created_at + ((practice.prand_int(r.review_id * 10 + lvl.k, 323, 1, 600))::text || ' hours')::interval,
       (practice.prand(r.review_id * 10 + lvl.k, 324) * 40)::int,
       r.review_id,
       false
FROM shop.reviews r
CROSS JOIN LATERAL generate_series(1, (practice.prand_int(r.review_id, 325, 0, 2))::int) lvl(k)
WHERE r.reply_to IS NULL
  AND practice.prand(r.review_id, 326) < 0.18;

-- ---------- wishlists ----------
INSERT INTO shop.wishlist_items (user_id, product_id, added_at)
SELECT u.user_id,
       practice.prand_zipf(u.user_id * 10 + k.k, 331, (SELECT n_products FROM practice.seed_config), 1.9),
       practice.prand_ts(u.user_id * 10 + k.k, 332, timestamptz '2023-01-01', timestamptz '2025-12-25')
FROM shop.users u
CROSS JOIN LATERAL generate_series(1, (practice.prand_int(u.user_id, 333, 0, 5))::int) k(k)
ON CONFLICT (user_id, product_id) DO NOTHING;

-- ---------- support tickets + threaded messages ----------
INSERT INTO shop.support_tickets (ticket_id, user_id, order_id, subject, priority, status,
                                  opened_at, first_response_at, solved_at, assigned_to, csat_score)
SELECT n,
       coalesce(o.user_id, practice.prand_zipf(n, 341, (SELECT n_users FROM practice.seed_config), 1.2)),
       o.order_id,
       practice.prand_pick(n, 342, ARRAY['Where is my order?','Refund not received','Wrong item delivered',
             'Cannot apply promo code','Account locked','Invoice request','Damaged packaging','Change address']),
       practice.prand_pick(n, 343, ARRAY['low','normal','normal','normal','high','urgent']),
       stt.status,
       op.opened_at,
       -- 9% never got a first response
       CASE WHEN practice.prand(n, 344) < 0.91
            THEN op.opened_at + ((practice.prand_int(n, 345, 3, 2880))::text || ' minutes')::interval END,
       CASE WHEN stt.status IN ('solved','closed')
            THEN op.opened_at + ((practice.prand_int(n, 346, 60, 20160))::text || ' minutes')::interval END,
       CASE WHEN practice.prand(n, 347) < 0.93
            THEN (practice.prand_int(n, 348, 1, (SELECT n_employees FROM practice.seed_config)))::int END,
       CASE WHEN stt.status IN ('solved','closed') AND practice.prand(n, 349) < 0.6
            THEN (practice.prand_int(n, 350, 1, 5))::smallint END
FROM generate_series(1, (SELECT n_tickets FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 351, timestamptz '2023-01-15', timestamptz '2025-12-20') AS opened_at
) op
CROSS JOIN LATERAL (
  SELECT CASE
           WHEN practice.prand(n, 352) < 0.12 THEN 'open'
           WHEN practice.prand(n, 352) < 0.22 THEN 'pending'
           WHEN practice.prand(n, 352) < 0.78 THEN 'solved'
           ELSE 'closed' END AS status
) stt
LEFT JOIN LATERAL (
  SELECT oo.order_id, oo.user_id FROM shop.orders oo
  WHERE oo.order_id = practice.prand_int(n, 353, 1, (SELECT max(order_id) FROM shop.orders))
) o ON practice.prand(n, 354) < 0.75;

INSERT INTO shop.ticket_messages (message_id, ticket_id, parent_message_id, author_kind, author_id, body, sent_at)
SELECT t.ticket_id * 10 + k.k,
       t.ticket_id,
       CASE WHEN k.k > 1 THEN t.ticket_id * 10 + (k.k - 1) END,
       CASE WHEN k.k % 2 = 1 THEN 'customer'
            WHEN practice.prand(t.ticket_id * 10 + k.k, 361) < 0.9 THEN 'agent'
            ELSE 'system' END,
       CASE WHEN k.k % 2 = 1 THEN t.user_id ELSE t.assigned_to END,
       practice.prand_pick(t.ticket_id * 10 + k.k, 362, ARRAY[
         'Hi, my order still has not arrived and the tracking has not moved for five days.',
         'Thanks for reaching out, I can see the parcel is stuck at the sorting hub.',
         'Could you refund the shipping fee at least?',
         'I have issued a partial refund, it should appear in 3-5 business days.',
         'Still nothing on my statement.',
         'Escalating to the payments team now.']),
       t.opened_at + ((k.k * practice.prand_int(t.ticket_id, 363, 20, 900))::text || ' minutes')::interval
FROM shop.support_tickets t
CROSS JOIN LATERAL generate_series(1, (1 + practice.prand_int(t.ticket_id, 364, 0, 5))::int) k(k);

-- ---------- shifts: consecutive-day streaks with deliberate gaps ----------
INSERT INTO hr.shifts (employee_id, shift_date, started_at, ended_at, role, warehouse_id)
SELECT e.employee_id,
       d.day,
       (d.day + time '06:00') AT TIME ZONE 'UTC' + (off.h || ' hours')::interval,
       (d.day + time '06:00') AT TIME ZONE 'UTC' + ((off.h + 8) || ' hours')::interval,
       practice.prand_pick(e.employee_id, 372, ARRAY['picker','packer','shift lead','driver','support']),
       CASE WHEN practice.prand(e.employee_id, 373) < 0.7
            THEN (practice.prand_int(e.employee_id, 374, 1, (SELECT n_warehouses FROM practice.seed_config)))::int END
FROM hr.employees e
CROSS JOIN LATERAL (
  SELECT g::date AS day, (g::date - date '2025-01-01')::bigint AS dnum
  FROM generate_series(date '2025-01-01', date '2025-06-30', interval '1 day') g
) d
CROSS JOIN LATERAL (
  SELECT (practice.prand_int(e.employee_id * 1000 + d.dnum, 371, 0, 8))::int AS h
) off
WHERE e.terminated_on IS NULL
  AND e.employee_id % 3 = 0                                        -- only ops-ish staff
  AND practice.prand(e.employee_id * 1000 + d.dnum, 375) < 0.72;   -- deliberate gaps

-- ---------- time off ----------
INSERT INTO hr.time_off (employee_id, kind, period, approved_by, status)
SELECT e.employee_id,
       practice.prand_pick(e.employee_id * 10 + k.k, 381, ARRAY['vacation','vacation','sick','parental','unpaid']),
       daterange(st.s, (st.s + (practice.prand_int(e.employee_id * 10 + k.k, 382, 1, 15))::int), '[)'),
       e.manager_id,
       practice.prand_pick(e.employee_id * 10 + k.k, 383, ARRAY['approved','approved','approved','requested','rejected','cancelled'])
FROM hr.employees e
CROSS JOIN LATERAL generate_series(1, (practice.prand_int(e.employee_id, 384, 0, 3))::int) k(k)
CROSS JOIN LATERAL (
  SELECT (date '2025-01-01' + (practice.prand_int(e.employee_id * 10 + k.k, 385, 0, 330))::int) AS s
) st;

-- ---------- SCD2 seller dimension ----------
INSERT INTO analytics.dim_seller_scd2 (seller_id, tier, country_code, valid_from, valid_to, is_current)
SELECT s.seller_id,
       CASE WHEN k.k = 1 THEN 'bronze'::shop.seller_tier ELSE s.tier END,
       s.country_code,
       CASE WHEN k.k = 1 THEN s.joined_on ELSE s.joined_on + 400 END,
       CASE WHEN k.k = 1 AND cnt.n > 1 THEN s.joined_on + 400 END,
       (k.k = cnt.n)
FROM shop.sellers s
CROSS JOIN LATERAL (SELECT CASE WHEN practice.prand(s.seller_id, 391) < 0.45 THEN 2 ELSE 1 END AS n) cnt
CROSS JOIN LATERAL generate_series(1, cnt.n) k(k);

ANALYZE shop.reviews; ANALYZE shop.support_tickets; ANALYZE shop.ticket_messages; ANALYZE hr.shifts;
