# 15. DML, UPSERT, MERGE & transactions

**2** basic, **4** intermediate, **4** advanced, **6** expert — 16 exercises

```bash
make new Q=T15-01                 # scaffold work/T15-01.sql
make diff Q=T15-01 F=work/T15-01.sql   # grade your answer
make run Q=T15-01                 # see the reference result
make explain Q=T15-01             # see the plan
```

---

### T15-01 — INSERT with RETURNING

🟢 basic · `INSERT, RETURNING`

Insert one new seller and return the generated row's seller_id and display_name.

<details><summary>hint</summary>

RETURNING turns a write into a query; essential for server-generated values.

</details>

### T15-02 — INSERT ... SELECT

🟢 basic · `INSERT SELECT, ON CONFLICT DO NOTHING, counting writes`

Copy every active product of seller 1 into shop.wishlist_items for user 1 (ignoring conflicts) and report how many rows were inserted.

<details><summary>hint</summary>

INSERT ... SELECT ... ON CONFLICT DO NOTHING, then use a data-modifying CTE to count the RETURNING rows.

</details>

### T15-03 — UPSERT with DO UPDATE

🟡 intermediate · `UPSERT, EXCLUDED, conflict target`

Upsert an inventory row for (warehouse_id 1, variant_id 4): set qty_on_hand to 999 on conflict, and return the resulting row.

<details><summary>hint</summary>

ON CONFLICT (pk) DO UPDATE SET ... uses the special EXCLUDED row.

</details>

### T15-04 — Conditional UPSERT

🟡 intermediate · `conditional DO UPDATE, WHERE on conflict action`

Upsert the same inventory row but only overwrite when the incoming quantity is larger than the stored one; return the final quantity.

<details><summary>hint</summary>

ON CONFLICT ... DO UPDATE ... WHERE inventory.qty_on_hand < EXCLUDED.qty_on_hand.

</details>

### T15-05 — UPDATE ... FROM a join

🟡 intermediate · `UPDATE FROM, avoiding no-op updates, RETURNING count`

Recompute orders.item_total from order_items for order_ids 1..100 and return how many rows changed.

<details><summary>hint</summary>

UPDATE ... SET ... FROM (aggregate) WHERE join condition; add a "value actually differs" predicate to avoid no-op writes.

</details>

### T15-06 — DELETE ... USING

🟡 intermediate · `DELETE USING, join-driven deletes`

Delete cart_items belonging to carts that are abandoned and older than 2023-06-01, limited to cart_ids below 500, and report the count.

<details><summary>hint</summary>

DELETE FROM child USING parent WHERE join AND filter.

</details>

### T15-07 — Data-modifying CTE pipeline

🟠 advanced · `data-modifying CTEs, chaining writes, snapshot semantics`

In one statement: insert a support ticket, insert its first message referencing the new ticket_id, and return both ids.

<details><summary>hint</summary>

A CTE with INSERT ... RETURNING can feed the next CTE. All CTEs see the same snapshot, so order matters only through data flow.

</details>

### T15-08 — MERGE

🟠 advanced · `MERGE, WHEN MATCHED, WHEN NOT MATCHED`

Use MERGE to synchronise a small staging set into shop.inventory: update the quantity when the row exists, insert it otherwise. Report the row counts you touched by querying the affected rows afterwards.

<details><summary>hint</summary>

Postgres 15+ supports MERGE ... WHEN MATCHED / WHEN NOT MATCHED. MERGE itself has no RETURNING before PG17, so verify with a SELECT.

</details>

### T15-09 — Idempotent backfill in batches

🟠 advanced · `batched backfill, idempotency, LIMIT inside a write`

Backfill users.loyalty_points to 10 points per paid order, in a single batch of at most 1000 users (user_id order), and report rows updated.

<details><summary>hint</summary>

Batch with a subquery that selects the next N candidate ids; add a "already correct" guard so re-running changes nothing.

</details>

### T15-10 — Soft delete with a partial unique index in mind

🟠 advanced · `soft deletes, RETURNING, guard predicates`

Soft-delete users 2 and 3 (set deleted_at) and return the affected rows with their new state.

<details><summary>hint</summary>

UPDATE ... WHERE user_id IN (...) AND deleted_at IS NULL, with RETURNING.

</details>

### T15-11 — SELECT ... FOR UPDATE and SKIP LOCKED queue

🔴 expert · `row locking, SKIP LOCKED, work queues`

Claim up to 5 pending orders as a worker would: lock them with FOR UPDATE SKIP LOCKED, mark them 'paid', and return the claimed ids.

<details><summary>hint</summary>

SKIP LOCKED lets concurrent workers take disjoint batches without blocking each other.

</details>

### T15-12 — Constraint violation handling

🔴 expert · `CHECK constraints, exception handling, SQLSTATE classes`

Show that inserting an order_item with qty = 0 violates the CHECK constraint, and that the error is catchable.

<details><summary>hint</summary>

Wrap the insert in a PL/pgSQL block and trap check_violation.

</details>

### T15-13 — Savepoints

🔴 expert · `savepoints, partial rollback, error recovery`

Inside one transaction, insert a seller, create a savepoint, perform an invalid insert that fails, roll back to the savepoint and confirm the first insert survived. Return the surviving count.

<details><summary>hint</summary>

SAVEPOINT / ROLLBACK TO SAVEPOINT scope the failure.

</details>

### T15-14 — Isolation levels and visibility

🔴 expert · `isolation levels, snapshots, read stability`

In a REPEATABLE READ transaction, read the order count twice around a same-transaction insert and show both values; explain why the second read sees your own write but would not see another session's.

<details><summary>hint</summary>

A transaction always sees its own uncommitted changes; the snapshot only hides other sessions' concurrent commits.

</details>

### T15-15 — Generated columns are not writable

🔴 expert · `generated columns, immutability, error codes`

Show that order_items.line_total cannot be inserted directly, and that it is computed from qty, unit_price and discount instead.

<details><summary>hint</summary>

Writing to a GENERATED ALWAYS column raises error 428C9.

</details>

### T15-16 — Bulk load pattern with a staging table

🔴 expert · `staging tables, bulk load, ON CONFLICT accounting`

Create a temporary staging table, load 1000 synthetic rows into it, then merge them into shop.wishlist_items, reporting inserted and skipped counts.

<details><summary>hint</summary>

Temp tables disappear at the end of the session; this is the standard COPY -> transform -> UPSERT shape.

</details>
