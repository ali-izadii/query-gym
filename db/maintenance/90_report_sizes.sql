-- row counts + on-disk sizes
\pset border 2
SELECT schema_name, table_name, approx_rows, total_size
FROM practice.v_table_sizes
WHERE total_bytes > 100000
ORDER BY total_bytes DESC
LIMIT 40;

SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;
