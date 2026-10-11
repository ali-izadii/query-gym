-- ============================================================
-- 00_extensions.sql : extensions + clean slate
-- ============================================================
\set ON_ERROR_STOP on

DROP SCHEMA IF EXISTS shop CASCADE;
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS practice CASCADE;

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- trigram / fuzzy search
CREATE EXTENSION IF NOT EXISTS btree_gist;     -- exclusion constraints on ranges
CREATE EXTENSION IF NOT EXISTS tablefunc;      -- crosstab / pivot
CREATE EXTENSION IF NOT EXISTS unaccent;       -- full text search normalisation
CREATE EXTENSION IF NOT EXISTS intarray;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA shop;        -- transactional e-commerce core
CREATE SCHEMA hr;          -- employees / org chart (hierarchy practice)
CREATE SCHEMA analytics;   -- events, ad spend, matviews, aggregates
CREATE SCHEMA practice;    -- helper funcs/views used by exercises & runner

COMMENT ON SCHEMA shop      IS 'Transactional marketplace core: users, products, orders, payments';
COMMENT ON SCHEMA hr        IS 'Org chart + payroll, for recursive CTE / hierarchy practice';
COMMENT ON SCHEMA analytics IS 'Event stream, ad spend, FX rates, materialized views';
COMMENT ON SCHEMA practice  IS 'Scaffolding for the exercise runner';

-- Every session in this DB sees the practice schemas without qualifying.
ALTER DATABASE :"DBNAME" SET search_path = shop, hr, analytics, practice, public;
SET search_path = shop, hr, analytics, practice, public;
