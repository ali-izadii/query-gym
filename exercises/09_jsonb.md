# 09. JSONB

**3** basic, **5** intermediate, **7** advanced, **5** expert — 20 exercises

```bash
make new Q=T09-01                 # scaffold work/T09-01.sql
make diff Q=T09-01 F=work/T09-01.sql   # grade your answer
make run Q=T09-01                 # see the reference result
make explain Q=T09-01             # see the plan
```

---

### T09-01 — Extract a top-level key

🟢 basic · `->, ->>, jsonb access`

For the 10 lowest user_ids, return user_id and the prefs locale as text, named locale.

<details><summary>hint</summary>

prefs->>'locale' returns text; prefs->'locale' returns jsonb.

</details>

### T09-02 — Nested path access

🟢 basic · `nested JSONB access, casting`

For the 10 lowest user_ids, return user_id and whether email notifications are enabled, as email_notify (boolean).

<details><summary>hint</summary>

prefs->'notify'->>'email' gives text; cast it to boolean.

</details>

### T09-03 — Count by a JSONB attribute

🟢 basic · `GROUP BY on JSONB expression`

Count products per attrs->>'color', ordered by products DESC. Columns: color, products.

<details><summary>hint</summary>

GROUP BY the extracted text expression.

</details>

### T09-04 — Containment operator with a GIN index

🟡 intermediate · `@> containment, GIN index usage`

Count products whose attrs contain {"material": "bamboo"}.

<details><summary>hint</summary>

attrs @> '{"material":"bamboo"}'::jsonb can use the jsonb_path_ops GIN index; ->> cannot.

</details>

### T09-05 — Key existence

🟡 intermediate · `? operator, key existence`

Count products that have a 'certifications' key, and those that have a nested 'specs' key. Columns: with_certs, with_specs.

<details><summary>hint</summary>

? tests a top-level key. Note jsonb_path_ops does not support ?.

</details>

### T09-06 — Numeric comparison on a JSONB value

🟡 intermediate · `casting JSONB text to numeric, NULL handling`

Count products whose warranty_months exceeds 48.

<details><summary>hint</summary>

Cast the extracted text to int: (attrs->>'warranty_months')::int. Mind rows where the key is missing (NULL).

</details>

### T09-07 — Expand a JSONB object into rows

🟡 intermediate · `jsonb_each_text, set-returning functions`

For product_id 1, list every top-level attrs key and its value as text. Columns: key, value. Order by key.

<details><summary>hint</summary>

jsonb_each_text(attrs) returns (key, value) rows.

</details>

### T09-08 — Expand a JSONB array

🟡 intermediate · `jsonb_array_elements_text, LATERAL, array expansion`

Count how often each certification appears across products. Columns: certification, products. Order by products DESC.

<details><summary>hint</summary>

jsonb_array_elements_text(attrs->'certifications') — guard rows where the key is absent.

</details>

### T09-09 — jsonpath existence query

🟠 advanced · `@? operator, jsonpath filter expressions`

Count products whose nested specs.battery_wh is greater than 150.

<details><summary>hint</summary>

attrs @? '$.specs.battery_wh ? (@ > 150)' uses the SQL/JSON path language and the GIN jsonb_path_ops index.

</details>

### T09-10 — jsonb_path_query to project nested values

🟠 advanced · `jsonb_path_query_first, #> path operator`

For the 10 lowest product_ids that have specs, return product_id and the ports array as jsonb, named ports.

<details><summary>hint</summary>

jsonb_path_query_first(attrs, '$.specs.ports') or plain attrs#>'{specs,ports}'.

</details>

### T09-11 — Aggregate rows into a JSONB array

🟠 advanced · `jsonb_agg, jsonb_build_object`

For the 5 lowest order_ids, return order_id and a JSONB array of the order's items, each as {"variant_id":..., "qty":...}, named items.

<details><summary>hint</summary>

jsonb_agg(jsonb_build_object(...) ORDER BY ...).

</details>

### T09-12 — Build nested JSON documents

🟠 advanced · `nested jsonb_build_object, document assembly`

For the 5 lowest order_ids, build one JSONB document per order with keys order_id, status, user (object with user_id and email) and item_count. Column: doc. Order by order_id.

<details><summary>hint</summary>

Nest jsonb_build_object calls; count items in a scalar subquery.

</details>

### T09-13 — Modify JSONB without touching the table

🟠 advanced · `jsonb_set, || merge, immutability of the stored value`

For the 5 lowest user_ids, return user_id, the original theme and a patched prefs where theme = 'dark' and a new key 'patched' = true. Columns: user_id, old_theme, new_prefs.

<details><summary>hint</summary>

jsonb_set(prefs, '{theme}', '"dark"') then || '{"patched":true}'.

</details>

### T09-14 — Remove keys and deep paths

🟠 advanced · `- operator, #- operator`

For user_id 1, return prefs with the top-level 'channels' key removed and the nested notify.sms path removed. Column: trimmed.

<details><summary>hint</summary>

prefs - 'channels' removes a key; #- '{notify,sms}' removes a path.

</details>

### T09-15 — Audit log diff — which keys changed

🟠 advanced · `jsonb_each_text, diffing two documents, array_agg`

For the 10 lowest audit_log ids, list audit_id and the keys whose values differ between before_row and after_row, as changed_keys (text[]).

<details><summary>hint</summary>

Expand before_row with jsonb_each_text and compare to the matching after_row value, aggregating keys with array_agg.

</details>

### T09-16 — Aggregate UTM parameters from the event stream

🔴 expert · `JSONB in a large partitioned table, key filtering`

For March 2025, count events per utm->>'campaign', ignoring events without a campaign. Columns: campaign, events. Order by events DESC.

<details><summary>hint</summary>

The key may be absent; filter with utm ? 'campaign'.

</details>

### T09-17 — JSONB to relational projection with jsonb_to_record

🔴 expert · `jsonb_to_record, typed projection`

For the 10 lowest product_ids having dimensions, project attrs->'dimensions' into typed columns w, h, d and compute volume (w*h*d). Columns: product_id, w, h, d, volume.

<details><summary>hint</summary>

jsonb_to_record(attrs->'dimensions') AS x(w int, h int, d int) inside a LATERAL.

</details>

### T09-18 — Aggregate a key/value store back into one document

🔴 expert · `jsonb_object_agg, document output`

Produce a single JSONB object mapping each seller tier to the number of sellers in it. Column: tier_counts.

<details><summary>hint</summary>

Aggregate per tier in a CTE, then jsonb_object_agg over that.

</details>

### T09-19 — Filter on an element inside a JSONB array

🔴 expert · `array containment inside JSONB, @>`

Count users whose prefs.beta_features array contains 'ai_search'.

<details><summary>hint</summary>

The array lives under a key, so use containment on the whole document: prefs @> '{"beta_features":["ai_search"]}'.

</details>

### T09-20 — jsonpath with variables and arithmetic

🔴 expert · `jsonb_path_exists, jsonpath variables, arithmetic in jsonpath`

Count products where the dimensions describe a box with a footprint (w * h) above 5000, using a single jsonpath predicate.

<details><summary>hint</summary>

jsonb_path_exists(attrs, '$.dimensions ? (@.w * @.h > $min)', jsonb_build_object('min', 5000)).

</details>
