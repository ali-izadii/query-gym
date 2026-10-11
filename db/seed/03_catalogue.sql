-- ============================================================
-- 03_catalogue.sql : products, variants, prices, inventory, promotions
-- ============================================================
SET search_path = shop, practice, public;

-- ---------- products ----------
INSERT INTO shop.products (product_id, seller_id, category_id, title, description, brand, status,
                           created_at, updated_at, base_price, currency_code, weight_grams, tags, attrs)
SELECT n,
       practice.prand_zipf(n, 111, (SELECT n_sellers FROM practice.seed_config), 1.5)::int,
       leaf.category_id,
       initcap(adj.w) || ' ' || noun.w || ' ' ||
         practice.prand_pick(n, 112, ARRAY['Mk II','Pro','Lite','2024','XL','Mini','Plus','Classic']),
       -- description: keeps full-text search interesting
       'The ' || adj.w || ' ' || noun.w || ' is built for ' ||
         practice.prand_pick(n, 113, ARRAY['daily commuting','professional studios','family kitchens','outdoor expeditions','gaming marathons','minimalist desks']) ||
         '. Features ' ||
         practice.prand_pick(n, 114, ARRAY['waterproof housing','wireless charging','recycled aluminium','a lifetime warranty','noise cancellation','a modular design']) ||
         ' and ships with ' ||
         practice.prand_pick(n, 115, ARRAY['a travel case','two spare parts','a quick-start guide','free lifetime support']) || '.',
       practice.prand_pick(n, 116, ARRAY['Nimbus','Volta','Kestrel','Lumio','Terrano','Orbis','Hyko','Fjell','Mera','Axon','Dorsa','Quill']),
       (CASE
          WHEN practice.prand(n, 117) < 0.72 THEN 'active'
          WHEN practice.prand(n, 117) < 0.84 THEN 'paused'
          WHEN practice.prand(n, 117) < 0.94 THEN 'archived'
          ELSE 'draft' END)::shop.product_status,
       cr.created_at,
       cr.created_at + (practice.prand(n, 118) * interval '400 days'),
       round((5 + power(practice.prand(n, 119), 2.2) * 1800)::numeric, 2),
       'USD',
       CASE WHEN practice.prand(n, 120) < 0.05 THEN NULL
            ELSE (practice.prand_int(n, 121, 50, 25000))::int END,
       ARRAY(SELECT DISTINCT practice.prand_pick(n, 122 + k, ARRAY[
               'bestseller','eco','handmade','imported','clearance','new-arrival','limited',
               'bundle','refurbished','gift','premium','budget'])
             FROM generate_series(0, (practice.prand_int(n, 123, 0, 3))::int) k),
       jsonb_strip_nulls(jsonb_build_object(
         'color',  practice.prand_pick(n, 124, ARRAY['black','white','red','blue','green','graphite','sand']),
         'material', practice.prand_pick(n, 125, ARRAY['aluminium','plastic','cotton','steel','bamboo','leather']),
         'warranty_months', (practice.prand_int(n, 126, 0, 60))::int,
         'dimensions', jsonb_build_object(
             'w', (practice.prand_int(n, 127, 5, 120))::int,
             'h', (practice.prand_int(n, 128, 5, 120))::int,
             'd', (practice.prand_int(n, 129, 2, 60))::int),
         'specs', CASE WHEN practice.prand(n, 130) < 0.55
                       THEN jsonb_build_object(
                              'battery_wh', (practice.prand_int(n, 131, 5, 200))::int,
                              'bluetooth',  practice.prand(n, 132) < 0.6,
                              'ports', to_jsonb(ARRAY['usb-c','hdmi']))
                  END,
         'certifications', CASE WHEN practice.prand(n, 133) < 0.3
                                THEN to_jsonb(ARRAY['CE','FCC','RoHS']) END,
         'rating_cache', round((1 + 4 * practice.prand(n, 134))::numeric, 1)
       ))
FROM generate_series(1, (SELECT n_products FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT c.category_id FROM shop.categories c
  WHERE c.depth = 3
  ORDER BY c.category_id
  OFFSET (practice.prand_zipf(n, 135, 200, 1.4) - 1) LIMIT 1
) leaf
CROSS JOIN LATERAL (SELECT practice.prand_pick(n, 136, ARRAY[
  'ultra','compact','rugged','silent','smart','vintage','thermal','ergonomic','modular','featherweight']) AS w) adj
CROSS JOIN LATERAL (SELECT practice.prand_pick(n, 137, ARRAY[
  'Headphones','Blender','Monitor','Backpack','Desk Lamp','Running Shoe','Tent','Keyboard',
  'Coffee Grinder','Yoga Mat','Drone','Speaker','Jacket','Cookware Set','Skateboard','Camera']) AS w) noun
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 138, timestamptz '2021-06-01', timestamptz '2025-10-01') AS created_at
) cr;

-- ---------- variants: 1..3 per product ----------
INSERT INTO shop.product_variants (variant_id, product_id, sku, variant_name, options,
                                   price_delta, barcode, is_active)
SELECT p.product_id * 4 + k,
       p.product_id,
       'SKU-' || lpad((p.product_id * 4 + k)::text, 10, '0'),
       practice.prand_pick(p.product_id * 10 + k, 141, ARRAY['Small','Medium','Large','One Size','Pack of 2']) ||
         ' / ' || practice.prand_pick(p.product_id * 10 + k, 142, ARRAY['Black','White','Blue','Red','Natural']),
       jsonb_build_object(
         'size',  practice.prand_pick(p.product_id * 10 + k, 143, ARRAY['S','M','L','XL','OS']),
         'color', practice.prand_pick(p.product_id * 10 + k, 144, ARRAY['black','white','blue','red','natural']),
         'pack',  (practice.prand_int(p.product_id * 10 + k, 145, 1, 4))::int),
       -- delta never pushes a price below ~1.00 (base_price >= 5)
       round((practice.prand(p.product_id * 10 + k, 146) * 60 - 4)::numeric, 2),
       CASE WHEN practice.prand(p.product_id * 10 + k, 147) < 0.12 THEN NULL
            ELSE lpad((practice.prand_int(p.product_id * 10 + k, 148, 1, 999999999999))::text, 13, '0') END,
       practice.prand(p.product_id * 10 + k, 149) > 0.08
FROM shop.products p
CROSS JOIN generate_series(0, 2) k(k)
WHERE k = 0 OR practice.prand(p.product_id * 10 + k, 150) < 0.55;

-- ---------- price history: 1-5 contiguous windows, last one open ----------
INSERT INTO shop.price_history (variant_id, price, valid_from, valid_to)
SELECT v.variant_id,
       round(greatest(0.50, (p.base_price + v.price_delta) * (0.70 + 0.10 * s.k))::numeric, 2),
       (p.created_at::date + ((s.k - 1) * 180))::date,
       CASE WHEN s.k < cnt.n_rows THEN (p.created_at::date + (s.k * 180))::date END
FROM shop.product_variants v
JOIN shop.products p ON p.product_id = v.product_id
CROSS JOIN LATERAL (SELECT 1 + (practice.prand_int(v.variant_id, 151, 0, 4))::int AS n_rows) cnt
CROSS JOIN LATERAL generate_series(1, cnt.n_rows) s(k);

-- ---------- inventory: each variant in 1-3 warehouses ----------
INSERT INTO shop.inventory (warehouse_id, variant_id, qty_on_hand, qty_reserved,
                            reorder_point, last_counted_at)
SELECT w.warehouse_id,
       v.variant_id,
       (practice.prand_int(v.variant_id * 100 + w.warehouse_id, 161, 0, 900))::int,
       (practice.prand_int(v.variant_id * 100 + w.warehouse_id, 162, 0, 40))::int,
       (practice.prand_int(v.variant_id * 100 + w.warehouse_id, 163, 0, 60))::int,
       CASE WHEN practice.prand(v.variant_id * 100 + w.warehouse_id, 164) < 0.2 THEN NULL
            ELSE practice.prand_ts(v.variant_id + w.warehouse_id, 165,
                                   timestamptz '2025-01-01', timestamptz '2025-12-01') END
FROM shop.product_variants v
CROSS JOIN LATERAL (
  SELECT ww.warehouse_id
  FROM shop.warehouses ww
  ORDER BY ((ww.warehouse_id + v.variant_id) * 2654435761::bigint) % 1000003
  LIMIT (1 + (practice.prand_int(v.variant_id, 166, 0, 2))::int)
) w;

-- ---------- promotions ----------
INSERT INTO shop.promotions (promo_id, code, description, discount_type, discount_value,
                             min_order_amount, active_range, max_redemptions, rules)
SELECT n,
       'PROMO' || lpad(n::text, 3, '0') || practice.prand_pick(n, 171, ARRAY['','X','Z','Q']),
       practice.prand_pick(n, 172, ARRAY['Spring sale','Black Friday','Welcome offer','Loyalty boost',
                                         'Clearance','Flash deal','Bundle discount','Free delivery week']),
       practice.prand_pick(n, 173, ARRAY['percent','percent','fixed','free_shipping']),
       CASE practice.prand_pick(n, 173, ARRAY['percent','percent','fixed','free_shipping'])
            WHEN 'percent' THEN (practice.prand_int(n, 174, 5, 40))::numeric
            WHEN 'fixed'   THEN (practice.prand_int(n, 175, 5, 60))::numeric
            ELSE 0 END,
       (practice.prand_int(n, 176, 0, 6) * 25)::numeric,
       tstzrange(st.s, st.s + ((practice.prand_int(n, 177, 7, 90))::text || ' days')::interval, '[)'),
       CASE WHEN practice.prand(n, 178) < 0.4 THEN NULL
            ELSE (practice.prand_int(n, 179, 100, 50000))::int END,
       jsonb_build_object(
         'first_order_only', practice.prand(n, 180) < 0.25,
         'segments', to_jsonb(ARRAY[practice.prand_pick(n, 181, ARRAY['new','casual','loyal','vip'])]),
         'channels', to_jsonb(ARRAY['web','ios','android']),
         'stackable', practice.prand(n, 182) < 0.3)
FROM generate_series(1, (SELECT n_promotions FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 183, timestamptz '2023-01-01', timestamptz '2025-11-01') AS s
) st;

INSERT INTO shop.promotion_categories (promo_id, category_id)
SELECT DISTINCT pr.promo_id, c.category_id
FROM shop.promotions pr
CROSS JOIN LATERAL (
  SELECT cc.category_id FROM shop.categories cc
  ORDER BY ((cc.category_id * 7919 + pr.promo_id * 104729)::bigint) % 999983
  LIMIT (1 + (practice.prand_int(pr.promo_id, 184, 0, 5))::int)
) c;

ANALYZE shop.products; ANALYZE shop.product_variants; ANALYZE shop.inventory; ANALYZE shop.price_history;
