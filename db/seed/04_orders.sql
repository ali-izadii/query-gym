-- ============================================================
-- 04_orders.sql : orders, items, payments, refunds, shipments, carts
-- Totals are derived from the item rows, so aggregate exercises reconcile.
-- ============================================================
SET search_path = shop, practice, public;

-- ---------- orders skeleton (totals filled in later) ----------
INSERT INTO shop.orders (order_id, user_id, status, placed_at, paid_at, cancelled_at,
                         currency_code, ship_address_id, promo_id, channel, notes)
SELECT n,
       u.user_id,
       st.status,
       pl.placed_at,
       CASE WHEN st.status <> 'pending' AND st.status <> 'cancelled'
            THEN pl.placed_at + ((practice.prand_int(n, 201, 10, 7200))::text || ' seconds')::interval END,
       CASE WHEN st.status = 'cancelled'
            THEN pl.placed_at + ((practice.prand_int(n, 202, 1, 72))::text || ' hours')::interval END,
       ctry.currency_code,
       addr.address_id,
       CASE WHEN practice.prand(n, 203) < 0.18
            THEN practice.prand_int(n, 204, 1, (SELECT n_promotions FROM practice.seed_config))::int END,
       practice.prand_pick(n, 205, ARRAY['web','web','web','ios','android','partner_api']),
       CASE WHEN practice.prand(n, 206) < 0.05
            THEN practice.prand_pick(n, 207, ARRAY['leave at door','gift wrap please','call on arrival','fragile']) END
FROM generate_series(1, (SELECT n_orders FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  -- customers are skewed: a few buy a lot (zipf over user ids)
  SELECT uu.user_id, uu.country_code, uu.signup_at
  FROM shop.users uu
  WHERE uu.user_id = practice.prand_zipf(n, 208, (SELECT n_users FROM practice.seed_config), 1.25)
) u
JOIN shop.countries ctry ON ctry.country_code = u.country_code
CROSS JOIN LATERAL (
  -- placed after signup, with a seasonal bias towards Q4
  SELECT greatest(u.signup_at + interval '1 hour',
                  practice.prand_ts(n, 209,
                        (SELECT t_start FROM practice.seed_config),
                        (SELECT t_end   FROM practice.seed_config))
                  + CASE WHEN practice.prand(n, 210) < 0.25 THEN interval '0' ELSE interval '0' END
         ) AS placed_at
) pl
CROSS JOIN LATERAL (
  SELECT (CASE
            WHEN practice.prand(n, 211) < 0.04 THEN 'pending'
            WHEN practice.prand(n, 211) < 0.09 THEN 'cancelled'
            WHEN practice.prand(n, 211) < 0.13 THEN 'returned'
            WHEN practice.prand(n, 211) < 0.20 THEN 'paid'
            WHEN practice.prand(n, 211) < 0.27 THEN 'packed'
            WHEN practice.prand(n, 211) < 0.40 THEN 'shipped'
            ELSE 'delivered' END)::shop.order_status AS status
) st
LEFT JOIN LATERAL (
  SELECT a.address_id FROM shop.user_addresses a
  WHERE a.user_id = u.user_id
  ORDER BY a.is_default DESC, a.address_id
  LIMIT 1
) addr ON true
WHERE pl.placed_at <= (SELECT t_end FROM practice.seed_config);

-- ---------- order items ----------
INSERT INTO shop.order_items (order_item_id, order_id, variant_id, product_id, seller_id,
                              qty, unit_price, discount, tax_amount, fulfilled_from_warehouse)
SELECT o.order_id * 8 + k.k,
       o.order_id,
       v.variant_id,
       v.product_id,
       p.seller_id,
       q.qty,
       pr.unit_price,
       round(CASE WHEN o.promo_id IS NOT NULL
                  THEN pr.unit_price * q.qty * (practice.prand_int(o.order_id * 10 + k.k, 221, 5, 25)::numeric / 100)
                  WHEN practice.prand(o.order_id * 10 + k.k, 222) < 0.12
                  THEN pr.unit_price * q.qty * 0.10
                  ELSE 0 END, 2),
       round(pr.unit_price * q.qty * c.vat_rate, 2),
       wh.warehouse_id
FROM shop.orders o
JOIN shop.users u      ON u.user_id = o.user_id
JOIN shop.countries c  ON c.country_code = u.country_code
CROSS JOIN LATERAL (
  SELECT 1 + (practice.prand_int(o.order_id, 223, 0, 4))::int AS n_items
) cnt
CROSS JOIN LATERAL generate_series(1, cnt.n_items) k(k)
CROSS JOIN LATERAL (
  -- only the first 88% of the catalogue is ever sold, so ~12% of products
  -- stay unsold on purpose (anti-join exercises need them)
  SELECT vv.variant_id, vv.product_id, vv.price_delta
  FROM shop.product_variants vv
  WHERE vv.variant_id = (
    SELECT min(variant_id) FROM shop.product_variants
    WHERE product_id = practice.prand_zipf(o.order_id * 10 + k.k, 224,
                                           (SELECT (n_products * 88) / 100 FROM practice.seed_config), 1.7)
  )
) v
JOIN shop.products p ON p.product_id = v.product_id
CROSS JOIN LATERAL (
  SELECT CASE WHEN practice.prand(o.order_id * 10 + k.k, 225) < 0.75 THEN 1
              WHEN practice.prand(o.order_id * 10 + k.k, 225) < 0.93 THEN 2
              ELSE (practice.prand_int(o.order_id * 10 + k.k, 226, 3, 8))::int END AS qty
) q
CROSS JOIN LATERAL (
  SELECT round(greatest(0.50, (p.base_price + v.price_delta) *
               (0.9 + 0.2 * practice.prand(o.order_id * 10 + k.k, 227))::numeric), 2) AS unit_price
) pr
LEFT JOIN LATERAL (
  SELECT i.warehouse_id FROM shop.inventory i
  WHERE i.variant_id = v.variant_id
  ORDER BY i.warehouse_id
  LIMIT 1
) wh ON practice.prand(o.order_id * 10 + k.k, 228) > 0.05;   -- 5% unknown warehouse

-- ---------- recompute order totals from the items ----------
WITH agg AS (
  SELECT oi.order_id,
         sum(oi.qty * oi.unit_price)  AS item_total,
         sum(oi.discount)             AS discount_total,
         sum(oi.tax_amount)           AS tax_total
  FROM shop.order_items oi
  GROUP BY oi.order_id
)
UPDATE shop.orders o
SET item_total     = a.item_total,
    discount_total = a.discount_total,
    tax_total      = a.tax_total,
    shipping_fee   = CASE WHEN a.item_total > 50 THEN 0
                          ELSE round((3 + 7 * practice.prand(o.order_id, 231))::numeric, 2) END,
    grand_total    = a.item_total - a.discount_total + a.tax_total
                     + CASE WHEN a.item_total > 50 THEN 0
                            ELSE round((3 + 7 * practice.prand(o.order_id, 231))::numeric, 2) END
FROM agg a
WHERE a.order_id = o.order_id;

-- ---------- payments: 0..2 rows per order (failures + retries) ----------
INSERT INTO shop.payments (payment_id, order_id, method, amount, currency_code, status,
                           created_at, captured_at, provider_ref, risk_score)
SELECT o.order_id * 4 + att.k,
       o.order_id,
       practice.prand_pick(o.order_id, 241, ARRAY['card','card','card','paypal','wallet','bank_transfer','cod','gift_card']),
       o.grand_total,
       o.currency_code,
       pay.status,
       o.placed_at + ((att.k * practice.prand_int(o.order_id, 242, 5, 600))::text || ' seconds')::interval,
       CASE WHEN pay.status = 'captured'
            THEN o.placed_at + ((att.k * practice.prand_int(o.order_id, 243, 20, 900))::text || ' seconds')::interval END,
       'ref_' || encode(int8send(o.order_id * 4 + att.k), 'hex'),
       round(practice.prand(o.order_id * 10 + att.k, 244)::numeric, 3)
FROM shop.orders o
CROSS JOIN LATERAL (
  -- failed first attempt for ~8% of orders => two payment rows
  SELECT generate_series(1, CASE WHEN practice.prand(o.order_id, 245) < 0.08 THEN 2 ELSE 1 END) AS k
) att
CROSS JOIN LATERAL (
  SELECT CASE
           WHEN o.status = 'pending' THEN 'authorized'
           WHEN o.status = 'cancelled' THEN 'voided'
           WHEN att.k = 1 AND practice.prand(o.order_id, 245) < 0.08 THEN 'failed'
           WHEN practice.prand(o.order_id, 246) < 0.005 THEN 'chargeback'
           ELSE 'captured' END AS status
) pay
WHERE o.status <> 'pending' OR practice.prand(o.order_id, 247) < 0.6;

-- ---------- refunds (partial + full) ----------
INSERT INTO shop.refunds (refund_id, payment_id, order_item_id, amount, reason, created_at, approved_by)
SELECT row_number() OVER (ORDER BY pay.payment_id, oi.order_item_id),
       pay.payment_id,
       CASE WHEN practice.prand(oi.order_item_id, 251) < 0.7 THEN oi.order_item_id END,
       round(least(oi.line_total,
             oi.line_total * (CASE WHEN practice.prand(oi.order_item_id, 252) < 0.5 THEN 1.0
                                   ELSE 0.3 + 0.4 * practice.prand(oi.order_item_id, 253) END))::numeric, 2),
       practice.prand_pick(oi.order_item_id, 254, ARRAY['damaged','wrong item','late delivery','changed mind','duplicate order','quality issue']),
       o.placed_at + ((practice.prand_int(oi.order_item_id, 255, 2, 40))::text || ' days')::interval,
       CASE WHEN practice.prand(oi.order_item_id, 256) < 0.85
            THEN (practice.prand_int(oi.order_item_id, 257, 1, (SELECT n_employees FROM practice.seed_config)))::int END
FROM shop.order_items oi
JOIN shop.orders o   ON o.order_id = oi.order_id
JOIN shop.payments pay ON pay.order_id = oi.order_id AND pay.status = 'captured'
WHERE oi.line_total > 0
  AND ( (o.status = 'returned'  AND practice.prand(oi.order_item_id, 258) < 0.8)
     OR (o.status = 'delivered' AND practice.prand(oi.order_item_id, 258) < 0.03) );

-- ---------- shipments ----------
INSERT INTO shop.shipments (shipment_id, order_id, carrier, tracking_code, shipped_at,
                            delivered_at, status, weight_grams, cost)
SELECT o.order_id,
       o.order_id,
       practice.prand_pick(o.order_id, 261, ARRAY['DHL','UPS','FedEx','PostNL','Royal Mail','Yamato','Correios']),
       CASE WHEN practice.prand(o.order_id, 262) < 0.97
            THEN upper(encode(int8send(o.order_id), 'hex')) END,
       ship.shipped_at,
       CASE WHEN o.status IN ('delivered','returned')
            THEN ship.shipped_at + ((practice.prand_int(o.order_id, 263, 1, 14))::text || ' days')::interval END,
       CASE o.status
            WHEN 'delivered' THEN 'delivered'
            WHEN 'returned'  THEN 'returned'
            WHEN 'shipped'   THEN 'in_transit'
            ELSE 'label_created' END,
       (practice.prand_int(o.order_id, 264, 100, 20000))::int,
       round((4 + 20 * practice.prand(o.order_id, 265))::numeric, 2)
FROM shop.orders o
CROSS JOIN LATERAL (
  SELECT o.placed_at + ((practice.prand_int(o.order_id, 266, 4, 120))::text || ' hours')::interval AS shipped_at
) ship
WHERE o.status IN ('packed','shipped','delivered','returned');

INSERT INTO shop.shipment_items (shipment_id, order_item_id, qty)
SELECT s.shipment_id, oi.order_item_id, oi.qty
FROM shop.shipments s
JOIN shop.order_items oi ON oi.order_id = s.order_id;

-- ---------- carts (converted + abandoned) ----------
INSERT INTO shop.carts (cart_id, user_id, session_id, created_at, updated_at, status, converted_order_id)
SELECT n,
       CASE WHEN practice.prand(n, 271) < 0.80
            THEN practice.prand_zipf(n, 272, (SELECT n_users FROM practice.seed_config), 1.2) END,
       gen_random_uuid(),
       cr.created_at,
       cr.created_at + ((practice.prand_int(n, 273, 1, 5000))::text || ' seconds')::interval,
       stt.status,
       CASE WHEN stt.status = 'converted'
            THEN practice.prand_int(n, 274, 1, (SELECT max(order_id) FROM shop.orders)) END
FROM generate_series(1, (SELECT n_carts FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 275, (SELECT t_start FROM practice.seed_config),
                                   (SELECT t_end FROM practice.seed_config)) AS created_at
) cr
CROSS JOIN LATERAL (
  SELECT CASE
           WHEN practice.prand(n, 276) < 0.30 THEN 'converted'
           WHEN practice.prand(n, 276) < 0.85 THEN 'abandoned'
           WHEN practice.prand(n, 276) < 0.95 THEN 'open'
           ELSE 'merged' END AS status
) stt;

INSERT INTO shop.cart_items (cart_id, variant_id, qty, added_at, unit_price)
SELECT c.cart_id,
       v.variant_id,
       (1 + practice.prand_int(c.cart_id * 10 + k.k, 281, 0, 3))::int,
       c.created_at + ((practice.prand_int(c.cart_id * 10 + k.k, 282, 1, 600))::text || ' seconds')::interval,
       round(greatest(0.50, p.base_price + v.price_delta)::numeric, 2)
FROM shop.carts c
CROSS JOIN LATERAL generate_series(1, (1 + practice.prand_int(c.cart_id, 283, 0, 3))::int) k(k)
CROSS JOIN LATERAL (
  SELECT vv.variant_id, vv.product_id, vv.price_delta
  FROM shop.product_variants vv
  WHERE vv.variant_id = (
    SELECT min(variant_id) FROM shop.product_variants
    WHERE product_id = practice.prand_zipf(c.cart_id * 10 + k.k, 284,
                                           (SELECT n_products FROM practice.seed_config), 1.6))
) v
JOIN shop.products p ON p.product_id = v.product_id
ON CONFLICT (cart_id, variant_id) DO NOTHING;

ANALYZE shop.orders; ANALYZE shop.order_items; ANALYZE shop.payments;
ANALYZE shop.shipments; ANALYZE shop.carts; ANALYZE shop.cart_items;
