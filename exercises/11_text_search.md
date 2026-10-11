# 11. Text, regex & full-text search

**3** basic, **4** intermediate, **7** advanced, **4** expert — 18 exercises

```bash
make new Q=T11-01                 # scaffold work/T11-01.sql
make diff Q=T11-01 F=work/T11-01.sql   # grade your answer
make run Q=T11-01                 # see the reference result
make explain Q=T11-01             # see the plan
```

---

### T11-01 — LIKE and ILIKE

🟢 basic · `LIKE, ILIKE, wildcards`

Count products whose title starts with 'Smart' (case-sensitive) and whose title contains 'lamp' in any case. Columns: starts_smart, contains_lamp.

<details><summary>hint</summary>

LIKE 'Smart%' is sargable with a btree index on text_pattern_ops; ILIKE '%lamp%' is not, which is why the trigram index exists.

</details>

### T11-02 — String functions

🟢 basic · `length, split_part`

For the 10 lowest user_ids, return user_id, the email, its length, the part before '@' and the domain. Columns: user_id, email, len, local, domain.

<details><summary>hint</summary>

length(), split_part(email, '@', 1) and split_part(..., 2).

</details>

### T11-03 — Normalising case and whitespace

🟢 basic · `btrim, lower, data cleaning`

From shop.raw_leads, return the 10 lowest raw_ids with email_raw and a cleaned version: trimmed and lower-cased. Columns: raw_id, email_raw, email_clean.

<details><summary>hint</summary>

lower(btrim(email_raw)).

</details>

### T11-04 — Regex match

🟡 intermediate · `regex operators, anchors, character classes`

Count raw_leads rows whose email_raw looks like a plausible email (one @, a dot in the domain), and those that do not (excluding NULLs). Columns: plausible, implausible.

<details><summary>hint</summary>

~ is case-sensitive regex match, ~* case-insensitive.

</details>

### T11-05 — Capture groups with regexp_match

🟡 intermediate · `regexp_match, capture groups, array subscript`

For the 10 lowest product_ids, extract the trailing suffix of the title (the last whitespace-separated token) using a regex capture group. Columns: product_id, title, suffix.

<details><summary>hint</summary>

(regexp_match(title, '(\S+)$'))[1].

</details>

### T11-06 — Split text into rows

🟡 intermediate · `regexp_split_to_array, unnest WITH ORDINALITY`

For product_id 1..3, split the title into words, one row per word with its position. Columns: product_id, pos, word. Order by product_id, pos.

<details><summary>hint</summary>

regexp_split_to_table(...) WITH ORDINALITY is not allowed directly; use regexp_split_to_array + unnest WITH ORDINALITY.

</details>

### T11-07 — Regex replace

🟡 intermediate · `regexp_replace, global flag`

For the 10 lowest raw_ids where amount_raw is not null, strip every character that is not a digit or a dot and return the numeric-looking result. Columns: raw_id, amount_raw, amount_clean.

<details><summary>hint</summary>

regexp_replace(amount_raw, '[^0-9.]', '', 'g') — the 'g' flag matters.

</details>

### T11-08 — Full-text search with to_tsquery

🟠 advanced · `tsvector, to_tsquery, @@ operator, GIN`

Find active products matching the full-text query 'wireless & headphones'. Return product_id, title. Order by product_id. Limit 15.

<details><summary>hint</summary>

products.search_tsv is a generated tsvector with a GIN index; use @@ to_tsquery('english', ...).

</details>

### T11-09 — Ranked full-text search

🟠 advanced · `ts_rank, relevance ordering, weighted tsvector`

Search products for 'waterproof | noise' and return the 10 best matches by ts_rank. Columns: product_id, title, rank (4 decimals).

<details><summary>hint</summary>

ts_rank(search_tsv, query) — note the weights set in the generated column (title A, brand B, description C).

</details>

### T11-10 — Phrase search and websearch syntax

🟠 advanced · `phraseto_tsquery, websearch_to_tsquery`

Count products matching the phrase 'travel case' (adjacent words) and those matching the websearch query '"travel case" -plastic'. Columns: phrase_hits, websearch_hits.

<details><summary>hint</summary>

phraseto_tsquery for adjacency, websearch_to_tsquery for user-facing syntax with quotes and minus signs.

</details>

### T11-11 — Highlighted snippets

🟠 advanced · `ts_headline, snippet generation`

For the 5 best matches of 'noise & cancellation', return product_id and a highlighted snippet of the description. Columns: product_id, snippet.

<details><summary>hint</summary>

ts_headline('english', description, query, 'MaxFragments=1').

</details>

### T11-12 — Inspect a tsvector

🟠 advanced · `unnest(tsvector), lexemes, weights`

For product_id 1, list the 10 lexemes of search_tsv with their positions and weights. Columns: lexeme, positions, weights.

<details><summary>hint</summary>

unnest(search_tsv) returns (lexeme, positions, weights).

</details>

### T11-13 — Trigram similarity search

🟠 advanced · `pg_trgm, similarity, fuzzy matching`

Find the 10 products whose title is most similar to the misspelled 'rugd keybord'. Columns: product_id, title, sim (4 decimals).

<details><summary>hint</summary>

similarity(title, 'rugd keybord') with the pg_trgm GIN index, or the % operator which uses pg_trgm.similarity_threshold.

</details>

### T11-14 — Trigram distance operator

🟠 advanced · `<-> distance operator, KNN ordering`

Return the 10 sellers whose display_name is closest to 'Khan Store' by trigram distance. Columns: seller_id, display_name, dist (4 decimals).

<details><summary>hint</summary>

The <-> operator is 1 - similarity and supports index-assisted nearest-neighbour ordering with a GiST/GIN trigram index.

</details>

### T11-15 — Search reviews and aggregate sentiment-ish signal

🔴 expert · `FTS in aggregates, FILTER, comparative analysis`

For reviews matching 'refund | broke | damaged', return the average rating and the count, plus the same for reviews matching 'excellent | perfect | recommend'. Columns: negative_n, negative_avg, positive_n, positive_avg (2 decimals).

<details><summary>hint</summary>

Two FILTERed aggregates over the same scan using the body_tsv index.

</details>

### T11-16 — Normalise accents for search

🔴 expert · `unaccent, diacritic folding`

Show that unaccent() folds diacritics: return the unaccented form of 'Café Münster Ångström' and whether it equals 'Cafe Munster Angstrom'. Columns: folded, matches.

<details><summary>hint</summary>

unaccent('...') — in production you would build a custom text search configuration that applies unaccent to the dictionary chain.

</details>

### T11-17 — Deduplicate dirty leads

🔴 expert · `normalisation before deduplication, HAVING`

In shop.raw_leads, group rows by normalised email (trim + lower, ignoring NULLs) and return the 10 normalised emails appearing more than once with their occurrence count. Columns: email_norm, occurrences.

<details><summary>hint</summary>

Normalise first in a CTE, then GROUP BY ... HAVING count(*) > 1.

</details>

### T11-18 — Parse multi-format dates defensively

🔴 expert · `defensive parsing, regex classification, CASE`

From raw_leads, classify signup_raw into 'iso', 'dmy', 'textual', 'compact', 'empty' or 'invalid' and count each. Columns: fmt, n. Order by n DESC.

<details><summary>hint</summary>

Match with regexes before attempting a cast; '2025-13-45' is ISO shaped but not a valid date, so test it with a safe cast or keep it as 'iso' and note the trap.

</details>
