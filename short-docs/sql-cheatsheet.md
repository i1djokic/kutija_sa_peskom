# SQL — DevOps Cheatsheet

## Query Basics

```sql
SELECT col1, col2
FROM table
WHERE condition
GROUP BY col
HAVING agg_condition
ORDER BY col DESC
LIMIT 10 OFFSET 0;

SELECT DISTINCT col FROM table;
SELECT * FROM table WHERE col IN (1, 2, 3);
SELECT * FROM table WHERE col BETWEEN 10 AND 20;
SELECT * FROM table WHERE col LIKE '%pattern%';
SELECT * FROM table WHERE col IS NULL;
```

## Joins

```sql
-- INNER: only matching rows
SELECT * FROM a JOIN b ON a.id = b.id;

-- LEFT: all a, nulls for unmatched b
SELECT * FROM a LEFT JOIN b ON a.id = b.id;

-- RIGHT: all b, nulls for unmatched a
SELECT * FROM a RIGHT JOIN b ON a.id = b.id;

-- FULL: all rows from both
SELECT * FROM a FULL OUTER JOIN b ON a.id = b.id;

-- CROSS: cartesian product
SELECT * FROM a CROSS JOIN b;

-- SELF
SELECT * FROM employees e1 JOIN employees e2 ON e1.manager_id = e2.id;
```

## Aggregation

```sql
SELECT
  dept,
  COUNT(*) AS cnt,
  SUM(salary) AS total,
  AVG(salary) AS avg,
  MIN(salary) AS min,
  MAX(salary) AS max
FROM employees
GROUP BY dept
HAVING COUNT(*) > 5
ORDER BY total DESC;
```

## Subqueries

```sql
-- scalar
SELECT * FROM t WHERE id = (SELECT MAX(id) FROM t);

-- correlated
SELECT * FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept = e.dept);

-- EXISTS
SELECT * FROM dept d
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.id);

-- IN / ANY / ALL
SELECT * FROM t WHERE id IN (SELECT id FROM other);
SELECT * FROM t WHERE salary > ALL (SELECT salary FROM managers);
```

## Window Functions

```sql
SELECT
  col,
  ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn,
  RANK()       OVER (PARTITION BY dept ORDER BY salary DESC) AS rk,
  DENSE_RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS dr,
  LAG(salary)  OVER (PARTITION BY dept ORDER BY hire_date) AS prev_sal,
  LEAD(salary) OVER (PARTITION BY dept ORDER BY hire_date) AS next_sal,
  FIRST_VALUE(salary) OVER (PARTITION BY dept ORDER BY hire_date) AS first_sal,
  SUM(salary)  OVER (PARTITION BY dept) AS dept_total,
  AVG(salary)  OVER (PARTITION BY dept) AS dept_avg
FROM employees;
```

## CTE (WITH)

```sql
WITH dept_stats AS (
  SELECT dept, AVG(salary) AS avg_sal
  FROM employees GROUP BY dept
)
SELECT e.*, d.avg_sal
FROM employees e
JOIN dept_stats d ON e.dept = d.dept
WHERE e.salary > d.avg_sal;
```

## DDL

```sql
CREATE TABLE users (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(100) NOT NULL,
  email     VARCHAR(255) UNIQUE,
  age       INTEGER CHECK (age > 0),
  active    BOOLEAN DEFAULT true,
  dept_id   INTEGER REFERENCES depts(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
DROP TABLE users;
TRUNCATE TABLE users;        -- removes all rows fast
TRUNCATE TABLE users CASCADE; -- also cascades to FK refs
```

## DML

```sql
INSERT INTO users (name, email) VALUES ('Alice', 'a@b.com');
INSERT INTO users (name, email) VALUES ('Bob', 'b@b.com'), ('Carol', 'c@b.com');
UPDATE users SET active = false WHERE id = 1;
DELETE FROM users WHERE id = 1;
```

## Indexes

```sql
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_email_unique ON users(email);
CREATE INDEX idx_users_dept ON users(dept_id) WHERE active = true; -- partial
DROP INDEX idx_users_email;
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'a@b.com';
```

## Transactions

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
-- or ROLLBACK;
```

## Constraints

```sql
PRIMARY KEY (col)
FOREIGN KEY (col) REFERENCES table(col) ON DELETE CASCADE
UNIQUE (col)
NOT NULL
CHECK (col > 0)
DEFAULT value
```

## String Functions

```sql
UPPER(col), LOWER(col)
LENGTH(col)
SUBSTRING(col FROM 1 FOR 5)   -- or SUBSTR(col, 1, 5)
TRIM(col)
REPLACE(col, 'old', 'new')
CONCAT(a, ' ', b)              -- or a || ' ' || b
POSITION('sub' IN col)
COALESCE(col, 'default')       -- first non-null
NULLIF(a, b)                   -- null if equal
```

## Date/Time

```sql
NOW(), CURRENT_TIMESTAMP, CURRENT_DATE
DATE_TRUNC('month', created_at)
EXTRACT(YEAR FROM created_at)
AGE(created_at)                 -- interval since
created_at + INTERVAL '7 days'
TO_CHAR(created_at, 'YYYY-MM-DD')
```

## Joining Strings (Agg)

```sql
-- PostgreSQL
STRING_AGG(name, ', ' ORDER BY name)

-- MySQL
GROUP_CONCAT(name ORDER BY name SEPARATOR ', ')

-- SQLite
GROUP_CONCAT(name, ', ')
```

## Set Operations

```sql
SELECT col FROM a
UNION       -- distinct
UNION ALL   -- duplicates
INTERSECT
EXCEPT      -- rows in first not in second
ORDER BY col;
```

## Common Table Modifiers

```sql
-- UPSERT (PostgreSQL)
INSERT INTO users (id, name) VALUES (1, 'Alice')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- UPSERT (MySQL)
INSERT INTO users (id, name) VALUES (1, 'Alice')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- RETURNING (PostgreSQL)
DELETE FROM users WHERE id = 1 RETURNING *;
UPDATE users SET name = 'Bob' WHERE id = 1 RETURNING id, name;
INSERT INTO users (name) VALUES ('Carol') RETURNING id;
```

## Performance

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'a@b.com';
EXPLAIN ANALYZE SELECT ...;  -- MySQL

-- slow query log
-- PostgreSQL: SET log_min_duration_statement = 1000;
-- MySQL:      SET slow_query_log = 1;

-- current queries
SELECT * FROM pg_stat_activity WHERE state = 'active';
SHOW FULL PROCESSLIST;  -- MySQL
```

## DevOps-Specific Queries

```sql
-- connection count
SELECT count(*) FROM pg_stat_activity;
SHOW STATUS LIKE 'Threads_connected';  -- MySQL

-- table size
SELECT pg_size_pretty(pg_total_relation_size('users'));
SELECT table_name, round(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.tables WHERE table_schema = 'public';  -- MySQL

-- database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- locks
SELECT * FROM pg_locks WHERE NOT granted;
SHOW OPEN TABLES WHERE In_use > 0;  -- MySQL

-- running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;

-- kill query
SELECT pg_cancel_backend(pid);  -- cancel
SELECT pg_terminate_backend(pid);  -- terminate
-- MySQL: KILL QUERY process_id;

-- disk usage per table (PostgreSQL)
SELECT relname, n_live_tup, n_dead_tup, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;
```

## Key Concepts

| Concept | Summary |
|---------|---------|
| **ACID** | Atomicity, Consistency, Isolation, Durability |
| **Normalization** | reduce redundancy (1NF→3NF) |
| **Index** | speeds reads, slows writes |
| **Transaction** | group of ops, all or nothing |
| **View** | virtual table (saved query) |
| **Materialized View** | physically stored, can be refreshed |
| **Partitioning** | split table by range/list/hash |
| **Replication** | primary → replica (sync/async) |
| **Sharding** | horizontal split across DBs |
| **Vacuum** (PG) | reclaim dead tuples space |
| **EXPLAIN** | query plan analysis |
