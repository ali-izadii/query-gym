-- ============================================================
-- 02_actors.sql : users, addresses, sellers, warehouses, employees
-- ============================================================
SET search_path = shop, hr, practice, public;

-- ---------- users ----------
INSERT INTO shop.users (user_id, email, first_name, last_name, birth_date, country_code,
                        signup_at, last_login_at, segment, referred_by, loyalty_points,
                        marketing_opt_in, prefs, deleted_at)
SELECT n,
       lower(practice.fake_first_name(n)) || '.' || lower(practice.fake_last_name(n))
         || n::text || '@' || practice.prand_pick(n, 41, ARRAY['mail.com','example.org','webmail.net','post.io','inbox.dev']),
       practice.fake_first_name(n),
       practice.fake_last_name(n),
       -- ~7% have no birth date
       CASE WHEN practice.prand(n, 3) < 0.07 THEN NULL
            ELSE (date '1995-01-01' - (practice.prand_int(n, 4, -9000, 9000))::int) END,
       ctry.country_code,
       sg.signup_at,
       -- 11% never logged in; others login after signup
       CASE WHEN practice.prand(n, 6) < 0.11 THEN NULL
            ELSE sg.signup_at + (practice.prand(n, 7) * (cfg.t_end - sg.signup_at)) END,
       (CASE
          WHEN practice.prand(n, 8) < 0.04 THEN 'vip'
          WHEN practice.prand(n, 8) < 0.20 THEN 'loyal'
          WHEN practice.prand(n, 8) < 0.55 THEN 'casual'
          WHEN practice.prand(n, 8) < 0.80 THEN 'new'
          ELSE 'churned'
        END)::shop.user_segment,
       -- 30% were referred by an earlier user
       CASE WHEN n > 50 AND practice.prand(n, 9) < 0.30
            THEN practice.prand_int(n, 10, 1, n - 1) END,
       (practice.prand(n, 11) * practice.prand(n, 12) * 12000)::int,
       practice.prand(n, 13) < 0.42,
       jsonb_build_object(
         'locale',   practice.prand_pick(n, 14, ARRAY['en-US','en-GB','de-DE','fr-FR','es-ES','ja-JP','pt-BR']),
         'theme',    practice.prand_pick(n, 15, ARRAY['light','dark','system']),
         'notify',   jsonb_build_object(
                       'email', practice.prand(n, 16) < 0.6,
                       'push',  practice.prand(n, 17) < 0.35,
                       'sms',   practice.prand(n, 18) < 0.12),
         'channels', to_jsonb((SELECT array_agg(x) FROM (
                        SELECT practice.prand_pick(n, 19 + k, ARRAY['email','push','sms','whatsapp']) AS x
                        FROM generate_series(0, (practice.prand_int(n, 20, 0, 2))::int) k) q)),
         'currency', ctry.currency_code
       ) || CASE WHEN practice.prand(n, 21) < 0.25
                 THEN jsonb_build_object('beta_features', ARRAY['new_checkout','ai_search'])
                 ELSE '{}'::jsonb END,
       -- 2% soft-deleted
       CASE WHEN practice.prand(n, 22) < 0.02
            THEN sg.signup_at + interval '200 days' END
FROM practice.seed_config cfg
CROSS JOIN generate_series(1, (SELECT n_users FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT practice.prand_ts(n, 1, cfg.t_start - interval '2 years', cfg.t_end - interval '10 days') AS signup_at
) sg
CROSS JOIN LATERAL (
  -- country distribution skewed towards US/DE/GB
  SELECT c.country_code, c.currency_code
  FROM shop.countries c
  ORDER BY c.country_code
  OFFSET (practice.prand_zipf(n, 2, 22, 1.35) - 1) LIMIT 1
) ctry;

-- ---------- addresses: 1-3 per user, exactly one default ----------
INSERT INTO shop.user_addresses (address_id, user_id, label, line1, city, postal_code,
                                 country_code, is_default, geo_lat, geo_lon)
SELECT (u.user_id * 4 + k),
       u.user_id,
       CASE k WHEN 0 THEN 'home' WHEN 1 THEN 'work' ELSE 'other' END,
       (practice.prand_int(u.user_id * 10 + k, 51, 1, 400))::text || ' ' ||
         practice.prand_pick(u.user_id * 10 + k, 52, ARRAY['Maple St','Oak Ave','Market Rd','Station Rd','Hauptstr.','Rue Centrale','Kings Way','Park Lane']),
       practice.prand_pick(u.user_id * 10 + k, 53, ARRAY['Springfield','Berlin','Lyon','Leeds','Porto','Osaka','Austin','Toronto','Pune','Malmo']),
       CASE WHEN practice.prand(u.user_id * 10 + k, 54) < 0.08 THEN NULL
            ELSE lpad((practice.prand_int(u.user_id * 10 + k, 55, 1000, 99999))::text, 5, '0') END,
       u.country_code,
       (k = 0),
       round((practice.prand_norm(u.user_id * 10 + k, 56, 40, 18))::numeric, 5),
       round((practice.prand_norm(u.user_id * 10 + k, 57, 5, 60))::numeric, 5)
FROM shop.users u
CROSS JOIN generate_series(0, 2) k(k)
WHERE k = 0
   OR practice.prand(u.user_id * 10 + k, 58) < 0.35;

-- ---------- sellers: group structure (parents are lower ids) ----------
INSERT INTO shop.sellers (seller_id, legal_name, display_name, country_code, tier, joined_on,
                          parent_seller_id, rating, is_suspended, payout_schedule, metadata)
SELECT n,
       practice.fake_last_name(n) || ' ' ||
         practice.prand_pick(n, 61, ARRAY['GmbH','Ltd','LLC','S.A.','B.V.','Pty','Inc']),
       practice.fake_last_name(n) || practice.prand_pick(n, 62, ARRAY['Store','Shop','Depot','Market','Outlet','Trading','Goods']),
       ctry.country_code,
       (CASE
          WHEN practice.prand(n, 63) < 0.05 THEN 'platinum'
          WHEN practice.prand(n, 63) < 0.18 THEN 'gold'
          WHEN practice.prand(n, 63) < 0.45 THEN 'silver'
          ELSE 'bronze' END)::shop.seller_tier,
       (date '2019-01-01' + (practice.prand_int(n, 64, 0, 2100))::int),
       -- 22% belong to a group, parent id strictly smaller
       CASE WHEN n > 20 AND practice.prand(n, 65) < 0.22
            THEN practice.prand_int(n, 66, 1, (n / 2)::bigint) END,
       CASE WHEN practice.prand(n, 67) < 0.05 THEN NULL      -- unrated sellers
            ELSE round(least(5.0, greatest(1.0, practice.prand_norm(n, 68, 4.2, 0.6)))::numeric, 2) END,
       practice.prand(n, 69) < 0.03,
       practice.prand_pick(n, 70, ARRAY['weekly','biweekly','monthly']),
       jsonb_build_object(
         'verified',    practice.prand(n, 71) < 0.7,
         'warehouses',  (practice.prand_int(n, 72, 1, 4))::int,
         'sla_days',    (practice.prand_int(n, 73, 1, 7))::int,
         'categories_focus', practice.prand_pick(n, 74, ARRAY['electronics','fashion','home','sports','beauty','books'])
       )
FROM generate_series(1, (SELECT n_sellers FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT c.country_code FROM shop.countries c ORDER BY c.country_code
  OFFSET (practice.prand_zipf(n, 75, 22, 1.2) - 1) LIMIT 1
) ctry;

-- ---------- warehouses ----------
INSERT INTO shop.warehouses (warehouse_id, code, seller_id, country_code, city, capacity_units)
SELECT n,
       'WH-' || lpad(n::text, 4, '0'),
       -- 1/4 are platform-owned (NULL seller)
       CASE WHEN practice.prand(n, 81) < 0.25 THEN NULL
            ELSE practice.prand_int(n, 82, 1, (SELECT n_sellers FROM practice.seed_config)) END,
       ctry.country_code,
       practice.prand_pick(n, 83, ARRAY['Rotterdam','Memphis','Shenzhen','Hamburg','Dubai','Singapore','Sao Paulo','Chicago','Lodz','Mumbai']),
       (practice.prand_int(n, 84, 5000, 500000))::int
FROM generate_series(1, (SELECT n_warehouses FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT c.country_code FROM shop.countries c ORDER BY c.country_code
  OFFSET (practice.prand_zipf(n, 85, 22, 1.1) - 1) LIMIT 1
) ctry;

-- ============================================================
-- HR
-- ============================================================
INSERT INTO hr.departments (department_id, name, parent_department_id, cost_center, country_code) VALUES
  (1,'Executive',NULL,'CC-1000','US'),
  (2,'Engineering',1,'CC-2000','US'),
  (3,'Platform',2,'CC-2100','DE'),
  (4,'Data',2,'CC-2200','US'),
  (5,'Mobile',2,'CC-2300','PL'),
  (6,'Operations',1,'CC-3000','NL'),
  (7,'Warehouse Ops',6,'CC-3100','NL'),
  (8,'Logistics',6,'CC-3200','DE'),
  (9,'Customer Support',1,'CC-4000','IN'),
  (10,'Support EMEA',9,'CC-4100','TR'),
  (11,'Support AMER',9,'CC-4200','MX'),
  (12,'Support APAC',9,'CC-4300','SG'),
  (13,'Sales',1,'CC-5000','GB'),
  (14,'Seller Success',13,'CC-5100','GB'),
  (15,'Finance',1,'CC-6000','CH'),
  (16,'Accounting',15,'CC-6100','CH'),
  (17,'Marketing',1,'CC-7000','US'),
  (18,'Performance Marketing',17,'CC-7100','US');

INSERT INTO hr.job_titles (job_id, title, job_family, level, min_salary, max_salary) VALUES
  (1,'CEO','exec',8,300000,500000),
  (2,'VP Engineering','exec',7,220000,320000),
  (3,'VP Operations','exec',7,200000,300000),
  (4,'VP Support','exec',7,180000,260000),
  (5,'VP Sales','exec',7,190000,280000),
  (6,'CFO','exec',8,250000,400000),
  (7,'Engineering Manager','eng',6,150000,210000),
  (8,'Staff Engineer','eng',6,160000,230000),
  (9,'Senior Engineer','eng',5,120000,175000),
  (10,'Engineer','eng',4,90000,130000),
  (11,'Junior Engineer','eng',3,60000,95000),
  (12,'Data Engineer','eng',5,115000,170000),
  (13,'Data Analyst','eng',4,85000,125000),
  (14,'Ops Manager','ops',5,95000,140000),
  (15,'Warehouse Lead','ops',4,55000,80000),
  (16,'Warehouse Associate','ops',2,32000,48000),
  (17,'Logistics Coordinator','ops',3,45000,68000),
  (18,'Support Lead','support',4,52000,78000),
  (19,'Support Agent','support',2,30000,46000),
  (20,'Senior Support Agent','support',3,40000,60000),
  (21,'Account Executive','sales',4,70000,110000),
  (22,'Sales Manager','sales',5,100000,150000),
  (23,'Accountant','finance',3,55000,85000),
  (24,'Finance Manager','finance',5,105000,155000),
  (25,'Marketing Specialist','sales',3,50000,78000);

-- employee 1 = CEO; employees 2..7 = VPs reporting to CEO; rest hang off a
-- deterministic parent with a smaller id => guaranteed acyclic tree, depth ~6
INSERT INTO hr.employees (employee_id, manager_id, department_id, job_id, first_name, last_name,
                          email, hired_on, terminated_on, salary, bonus_pct, country_code, is_manager)
SELECT n,
       CASE
         WHEN n = 1 THEN NULL
         WHEN n <= 7 THEN 1
         ELSE greatest(2, (n / 4))          -- parent id < n  => tree
       END,
       d.department_id,
       j.job_id,
       practice.fake_first_name(n * 7 + 1),
       practice.fake_last_name(n * 13 + 5),
       'emp' || n || '.' || lower(practice.fake_last_name(n * 13 + 5)) || '@marketplace.example',
       hire.hired_on,
       -- 12% have left
       CASE WHEN practice.prand(n, 91) < 0.12
            THEN hire.hired_on + (practice.prand_int(n, 92, 120, 1600))::int END,
       round(greatest(j.min_salary,
             least(j.max_salary, j.min_salary + (j.max_salary - j.min_salary) * practice.prand(n, 93)))::numeric, 2),
       CASE WHEN practice.prand(n, 94) < 0.25 THEN NULL
            ELSE round((0.02 + 0.18 * practice.prand(n, 95))::numeric, 4) END,
       d.country_code,
       (n <= 7 OR n % 4 = 0)
FROM generate_series(1, (SELECT n_employees FROM practice.seed_config)) AS g(n)
CROSS JOIN LATERAL (
  SELECT (date '2017-01-01' + (practice.prand_int(n, 96, 0, 2900))::int) AS hired_on
) hire
CROSS JOIN LATERAL (
  SELECT dd.department_id, dd.country_code
  FROM hr.departments dd
  ORDER BY dd.department_id
  OFFSET CASE WHEN n = 1 THEN 0 ELSE (practice.prand_int(n, 97, 1, 17)) END
  LIMIT 1
) d
CROSS JOIN LATERAL (
  SELECT jt.job_id, jt.min_salary, jt.max_salary
  FROM hr.job_titles jt
  WHERE CASE
          WHEN n = 1 THEN jt.job_id = 1
          WHEN n <= 7 THEN jt.job_id = n          -- VPs/CFO
          ELSE jt.job_id >= 7
        END
  ORDER BY jt.job_id
  OFFSET CASE WHEN n <= 7 THEN 0 ELSE (practice.prand_int(n, 98, 0, 18)) END
  LIMIT 1
) j;

-- salary history: 1-4 non-overlapping windows per employee, last one open
INSERT INTO hr.salary_history (employee_id, salary, effective_from, effective_to, reason)
SELECT e.employee_id,
       round((e.salary * (0.72 + 0.07 * s.k))::numeric, 2),
       bounds.from_date,
       bounds.to_date,
       practice.prand_pick(e.employee_id * 10 + s.k, 101,
         ARRAY['hire','annual review','promotion','market adjustment','role change'])
FROM hr.employees e
CROSS JOIN LATERAL (
  SELECT 1 + (practice.prand_int(e.employee_id, 102, 0, 3))::int AS n_rows
) cnt
CROSS JOIN LATERAL generate_series(1, cnt.n_rows) s(k)
CROSS JOIN LATERAL (
  SELECT (e.hired_on + ((s.k - 1) * 420))::date AS from_date,
         CASE WHEN s.k < cnt.n_rows THEN (e.hired_on + (s.k * 420))::date END AS to_date
) bounds;

ANALYZE shop.users; ANALYZE shop.sellers; ANALYZE shop.warehouses; ANALYZE hr.employees;
