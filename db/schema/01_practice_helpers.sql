-- ============================================================
-- 01_practice_helpers.sql : deterministic pseudo-random helpers
-- Everything in the seed is derived from these so that two people
-- cloning the repo at the same SCALE get byte-identical data.
-- ============================================================
SET search_path = practice, public;

-- Uniform double in [0,1) derived from a row number + salt. IMMUTABLE => usable
-- in generated columns, parallel plans and CHECK-free seeding.
CREATE OR REPLACE FUNCTION practice.prand(n bigint, salt integer DEFAULT 0)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT (abs(hashtextextended(n::text || '#' || salt::text, 42)) % 1000000000)::double precision
         / 1000000000.0;
$$;

-- Integer in [lo, hi] inclusive.
CREATE OR REPLACE FUNCTION practice.prand_int(n bigint, salt integer, lo bigint, hi bigint)
RETURNS bigint
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT least(hi, lo + floor(practice.prand(n, salt) * (hi - lo + 1))::bigint)
$$;

-- Pick one element of a text array.
CREATE OR REPLACE FUNCTION practice.prand_pick(n bigint, salt integer, choices text[])
RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT choices[1 + floor(practice.prand(n, salt) * array_length(choices, 1))::int]
$$;

-- Skewed pick: earlier elements much more likely (power law, alpha>1 => steeper).
CREATE OR REPLACE FUNCTION practice.prand_zipf(n bigint, salt integer, hi bigint, alpha double precision DEFAULT 1.6)
RETURNS bigint
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT 1 + least(hi - 1, floor(power(practice.prand(n, salt), alpha) * hi))::bigint
$$;

-- Normal-ish value via sum of 3 uniforms (cheap CLT), clamped.
CREATE OR REPLACE FUNCTION practice.prand_norm(n bigint, salt integer, mean double precision, sd double precision)
RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT mean + sd * (
      (practice.prand(n, salt) + practice.prand(n, salt + 7777) + practice.prand(n, salt + 991) - 1.5) * 1.1547
  )
$$;

-- Timestamp uniformly inside a window.
CREATE OR REPLACE FUNCTION practice.prand_ts(n bigint, salt integer, lo timestamptz, hi timestamptz)
RETURNS timestamptz
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT lo + (practice.prand(n, salt) * (hi - lo))
$$;

-- Human-ish names from syllable tables (keeps the repo free of name datasets).
CREATE OR REPLACE FUNCTION practice.fake_first_name(n bigint)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT practice.prand_pick(n, 11, ARRAY[
    'Ava','Liam','Noah','Mia','Zoe','Omar','Sara','Yuki','Ines','Hugo','Nina','Leo',
    'Maya','Ali','Elena','Ravi','Tom','Lena','Hana','Jonas','Amara','Pedro','Ivy','Kai',
    'Clara','Ahmad','Freya','Nikolai','Chen','Fatima','Oscar','Priya','Erik','Rosa','Tariq','Wen'])
$$;

CREATE OR REPLACE FUNCTION practice.fake_last_name(n bigint)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$
  SELECT practice.prand_pick(n, 23, ARRAY[
    'Novak','Silva','Kim','Haddad','Weber','Rossi','Dubois','Olsen','Khan','Tanaka',
    'Garcia','Smith','Ivanov','Mehta','Berg','Costa','Fischer','Nowak','Lopez','Yilmaz',
    'Moreau','Hansen','Okafor','Petrov','Rahman','Brandt','Castro','Lindqvist','Varga','Zhao'])
$$;

COMMENT ON FUNCTION practice.prand(bigint, integer) IS
  'Deterministic uniform [0,1) from a row id. Seed data must never use random().';
