-- ===================================================================
--                      DAY 4: ADVANCED PERFORMANCE & FEATURES
--    Indexing | EXPLAIN | CTEs | Window Functions | JSON | Partitioning
-- ===================================================================

-- ===================================================================
-- SECTION 1: SETUP (Large Test Dataset for Performance Demos)
-- ===================================================================

DROP DATABASE IF EXISTS demo_performance;
CREATE DATABASE demo_performance;
USE demo_performance;

-- Create a large sales table for indexing and performance tests
CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    category VARCHAR(50),
    sale_date DATE NOT NULL,
    amount DECIMAL(10,2),
    region VARCHAR(20),
    is_promo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a supporting customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    signup_date DATE,
    loyalty_points INT DEFAULT 0
);

-- Insert 100,000 sample rows into sales (using a stored procedure to generate data)
DELIMITER //
CREATE PROCEDURE sp_populate_sales(IN p_rows INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_customer INT;
    DECLARE v_product INT;
    DECLARE v_category VARCHAR(50);
    DECLARE v_date DATE;
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_region VARCHAR(20);
    
    -- Pre-populate customers
    TRUNCATE customers;
    INSERT INTO customers (first_name, last_name, email, signup_date, loyalty_points)
    SELECT 
        CONCAT('First', seq),
        CONCAT('Last', seq),
        CONCAT('user', seq, '@example.com'),
        DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 1000) DAY),
        FLOOR(RAND() * 1000)
    FROM 
        (SELECT @row := @row + 1 AS seq 
         FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t1,
              (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t2,
              (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
              (SELECT @row := 0) r
         LIMIT 1000) AS seq_table;

    -- Populate sales
    WHILE i < p_rows DO
        SET v_customer = 1 + FLOOR(RAND() * 1000);
        SET v_product = 1 + FLOOR(RAND() * 500);
        SET v_category = ELT(1 + FLOOR(RAND() * 4), 'Electronics', 'Clothing', 'Groceries', 'Furniture');
        SET v_date = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 730) DAY); -- Last 2 years
        SET v_amount = ROUND(10 + RAND() * 500, 2);
        SET v_region = ELT(1 + FLOOR(RAND() * 3), 'North', 'South', 'West');
        
        INSERT INTO sales (customer_id, product_id, category, sale_date, amount, region, is_promo)
        VALUES (v_customer, v_product, v_category, v_date, v_amount, v_region, RAND() > 0.7);
        
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Generate 50,000 rows (adjust as needed for your system, but 50k is good for demo)
CALL sp_populate_sales(50000);

-- Verify data
SELECT COUNT(*) FROM sales;
SELECT COUNT(*) FROM customers;
SELECT * FROM sales LIMIT 10;


-- ===================================================================
-- SECTION 2: INDEXING (ALL TYPES & PERMUTATIONS)
-- ===================================================================

-- [VARIATION 1] Single-column index (B-Tree default)
CREATE INDEX idx_sales_customer ON sales(customer_id);

-- [VARIATION 2] Composite (Multi-column) index - Order matters!
CREATE INDEX idx_sales_date_category ON sales(sale_date, category);

-- [VARIATION 3] Unique index (prevents duplicate values)
CREATE UNIQUE INDEX idx_customers_email ON customers(email);

-- [VARIATION 4] Full-Text index (for text search on VARCHAR/TEXT)
ALTER TABLE customers ADD FULLTEXT INDEX ft_customers_name (first_name, last_name);

-- [VARIATION 5] Spatial index (for GIS data - using POINT as example)
ALTER TABLE sales ADD COLUMN location POINT;
UPDATE sales SET location = POINT(10 + RAND()*20, 20 + RAND()*30);
CREATE SPATIAL INDEX sp_sales_location ON sales(location);

-- [VARIATION 6] Descending index (MySQL 8.0+)
CREATE INDEX idx_sales_amount_desc ON sales(amount DESC);

-- [VARIATION 7] Invisible index (hidden from optimizer, for testing)
CREATE INDEX idx_sales_region_invisible ON sales(region) INVISIBLE;

-- [VARIATION 8] Make an index visible/invisible
ALTER INDEX idx_sales_region_invisible ON sales VISIBLE;
ALTER INDEX idx_sales_region_invisible ON sales INVISIBLE;

-- [VARIATION 9] Covering index (includes all columns needed for a query)
CREATE INDEX idx_sales_covering ON sales(customer_id, sale_date, amount, region);

-- [VARIATION 10] Prefix index (index only first N characters of a string)
CREATE INDEX idx_sales_category_prefix ON sales(category(3));

-- [VARIATION 11] Show all indexes on a table
SHOW INDEX FROM sales;
SHOW INDEX FROM customers;

-- [VARIATION 12] Drop index
-- DROP INDEX idx_sales_region_invisible ON sales;

-- [VARIATION 13] Rename index (MySQL 8.0+)
ALTER TABLE sales RENAME INDEX idx_sales_customer TO idx_sales_cust;

-- [VARIATION 14] CREATE INDEX with USING clause (BTREE, HASH, RTREE)
CREATE INDEX idx_sales_hash ON sales(customer_id) USING HASH;  -- InnoDB silently uses BTREE


-- ===================================================================
-- SECTION 3: QUERY OPTIMIZATION - EXPLAIN & ANALYZE
-- ===================================================================

-- [VARIATION 1] Basic EXPLAIN (Execution Plan)
EXPLAIN SELECT * FROM sales WHERE customer_id = 100;

-- [VARIATION 2] EXPLAIN with FORMAT=JSON (Detailed plan)
EXPLAIN FORMAT=JSON 
SELECT * FROM sales WHERE customer_id = 100 AND sale_date > '2024-01-01';

-- [VARIATION 3] EXPLAIN with FORMAT=TREE (Visual representation - MySQL 8.0+)
EXPLAIN FORMAT=TREE 
SELECT * FROM sales WHERE customer_id = 100 AND sale_date > '2024-01-01';

-- [VARIATION 4] EXPLAIN ANALYZE (Actually executes and shows timings - MySQL 8.0.18+)
EXPLAIN ANALYZE 
SELECT s.*, c.first_name 
FROM sales s 
INNER JOIN customers c ON s.customer_id = c.customer_id 
WHERE s.amount > 400 AND s.sale_date BETWEEN '2025-01-01' AND '2025-12-31';

-- [VARIATION 5] OPTIMIZER_TRACE (See why MySQL chose a plan)
SET OPTIMIZER_TRACE = "enabled=on";
SELECT * FROM sales WHERE customer_id = 100;
SELECT * FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE\G
SET OPTIMIZER_TRACE = "enabled=off";

-- [VARIATION 6] USE INDEX (Force optimizer to consider a specific index)
SELECT * FROM sales USE INDEX (idx_sales_cust) WHERE customer_id = 100;

-- [VARIATION 7] FORCE INDEX (Force optimizer to use a specific index)
SELECT * FROM sales FORCE INDEX (idx_sales_date_category) WHERE sale_date = '2025-06-01';

-- [VARIATION 8] IGNORE INDEX (Prevent optimizer from using an index)
SELECT * FROM sales IGNORE INDEX (idx_sales_cust) WHERE customer_id = 100;


-- ===================================================================
-- SECTION 4: CTEs - Common Table Expressions (WITH clause)
-- ===================================================================

-- [VARIATION 1] Simple CTE (Subquery alternative)
WITH cte_high_value AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM sales
    GROUP BY customer_id
    HAVING SUM(amount) > 10000
)
SELECT c.first_name, c.last_name, h.total_spent
FROM customers c
INNER JOIN cte_high_value h ON c.customer_id = h.customer_id;

-- [VARIATION 2] Multiple CTEs in one query
WITH 
cte_avg_sales AS (
    SELECT AVG(amount) AS avg_amount FROM sales
),
cte_top_regions AS (
    SELECT region, SUM(amount) AS total
    FROM sales
    GROUP BY region
    ORDER BY total DESC
    LIMIT 1
)
SELECT a.avg_amount, r.region, r.total
FROM cte_avg_sales a, cte_top_regions r;

-- [VARIATION 3] CTE with WHERE clause inside
WITH cte_recent AS (
    SELECT * FROM sales WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT category, AVG(amount) FROM cte_recent GROUP BY category;

-- [VARIATION 4] Recursive CTE (Generate hierarchy / numbers)
WITH RECURSIVE cte_numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM cte_numbers WHERE n < 10
)
SELECT * FROM cte_numbers;

-- [VARIATION 5] Recursive CTE for Employee Hierarchy (Simulating with customers as tree)
-- First, add a manager_id to customers to simulate org tree
ALTER TABLE customers ADD COLUMN manager_id INT NULL;
UPDATE customers SET manager_id = FLOOR(RAND() * 10) + 1 WHERE customer_id > 10;
-- Recursive query to find all subordinates of manager 1
WITH RECURSIVE emp_tree AS (
    SELECT customer_id, first_name, manager_id, 0 AS level
    FROM customers
    WHERE customer_id = 1
    UNION ALL
    SELECT c.customer_id, c.first_name, c.manager_id, e.level + 1
    FROM customers c
    INNER JOIN emp_tree e ON c.manager_id = e.customer_id
)
SELECT * FROM emp_tree ORDER BY level;

-- [VARIATION 6] CTE with DELETE (Delete duplicates)
WITH cte_duplicates AS (
    SELECT customer_id, email,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY customer_id) AS rn
    FROM customers
)
DELETE FROM customers 
WHERE customer_id IN (SELECT customer_id FROM cte_duplicates WHERE rn > 1);

-- [VARIATION 7] CTE with UPDATE
WITH cte_bonus_customers AS (
    SELECT customer_id FROM sales GROUP BY customer_id HAVING SUM(amount) > 20000
)
UPDATE customers c
SET loyalty_points = loyalty_points + 100
WHERE customer_id IN (SELECT customer_id FROM cte_bonus_customers);


-- ===================================================================
-- SECTION 5: WINDOW FUNCTIONS (OVER clause - ALL PERMUTATIONS)
-- ===================================================================

-- [VARIATION 1] ROW_NUMBER() - Assign sequential number per partition
SELECT sale_id, customer_id, amount,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY sale_date DESC) AS row_num
FROM sales
LIMIT 20;

-- [VARIATION 2] RANK() - Rank with gaps
SELECT sale_id, category, amount,
       RANK() OVER (PARTITION BY category ORDER BY amount DESC) AS rank_in_category
FROM sales
LIMIT 20;

-- [VARIATION 3] DENSE_RANK() - Rank without gaps
SELECT sale_id, category, amount,
       DENSE_RANK() OVER (PARTITION BY category ORDER BY amount DESC) AS dense_rank_in_category
FROM sales
LIMIT 20;

-- [VARIATION 4] LAG() - Access previous row value
SELECT sale_id, customer_id, amount,
       LAG(amount, 1, 0) OVER (PARTITION BY customer_id ORDER BY sale_date) AS prev_sale_amount,
       amount - LAG(amount, 1, 0) OVER (PARTITION BY customer_id ORDER BY sale_date) AS diff
FROM sales
LIMIT 20;

-- [VARIATION 5] LEAD() - Access next row value
SELECT sale_id, customer_id, amount,
       LEAD(amount, 1, 0) OVER (PARTITION BY customer_id ORDER BY sale_date) AS next_sale_amount
FROM sales
LIMIT 20;

-- [VARIATION 6] FIRST_VALUE() - First value in partition
SELECT sale_id, customer_id, amount,
       FIRST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY sale_date) AS first_purchase_amount
FROM sales
LIMIT 20;

-- [VARIATION 7] LAST_VALUE() - Last value in partition (with frame)
SELECT sale_id, customer_id, amount,
       LAST_VALUE(amount) OVER (PARTITION BY customer_id ORDER BY sale_date 
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_purchase_amount
FROM sales
LIMIT 20;

-- [VARIATION 8] NTILE() - Divide rows into buckets
SELECT sale_id, amount,
       NTILE(4) OVER (ORDER BY amount DESC) AS quartile
FROM sales
LIMIT 20;

-- [VARIATION 9] Aggregate Window Functions (SUM, AVG, COUNT over partition)
SELECT sale_id, customer_id, amount,
       SUM(amount) OVER (PARTITION BY customer_id) AS total_customer_spend,
       AVG(amount) OVER (PARTITION BY customer_id) AS avg_customer_spend,
       COUNT(*) OVER (PARTITION BY customer_id) AS customer_purchase_count
FROM sales
LIMIT 20;

-- [VARIATION 10] Window function with ROWS/RANGE frame
SELECT sale_id, sale_date, amount,
       SUM(amount) OVER (ORDER BY sale_date 
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sum_3days
FROM sales
ORDER BY sale_date
LIMIT 20;

-- [VARIATION 11] CUME_DIST() - Cumulative distribution
SELECT category, amount,
       CUME_DIST() OVER (PARTITION BY category ORDER BY amount) AS cumulative_dist
FROM sales
LIMIT 20;

-- [VARIATION 12] PERCENT_RANK() - Percentage rank
SELECT category, amount,
       PERCENT_RANK() OVER (PARTITION BY category ORDER BY amount) AS percent_rank
FROM sales
LIMIT 20;


-- ===================================================================
-- SECTION 6: JSON DATA TYPE (ALL PERMUTATIONS)
-- ===================================================================

-- Add a JSON column to customers for storing preferences
ALTER TABLE customers ADD COLUMN preferences JSON;

-- [VARIATION 1] Insert JSON data using JSON_OBJECT
UPDATE customers SET preferences = JSON_OBJECT(
    'theme', 'dark',
    'notifications', JSON_ARRAY('email', 'sms'),
    'language', 'en',
    'categories', JSON_ARRAY('Electronics', 'Clothing')
)
WHERE customer_id = 1;

-- [VARIATION 2] Insert JSON using JSON_ARRAY
UPDATE customers SET preferences = '{"theme":"light","notifications":["push"],"language":"es"}' 
WHERE customer_id = 2;

-- [VARIATION 3] Insert multiple JSON objects using JSON_ARRAYAGG (Aggregate)
UPDATE customers 
SET preferences = JSON_ARRAY(
    JSON_OBJECT('key', 'pref1', 'value', 'yes'),
    JSON_OBJECT('key', 'pref2', 'value', 'no')
)
WHERE customer_id = 3;

-- [VARIATION 4] JSON_EXTRACT (->> operator for unquoting)
SELECT customer_id, 
       JSON_EXTRACT(preferences, '$.theme') AS theme,
       preferences -> '$.language' AS language,
       preferences ->> '$.language' AS language_unquoted
FROM customers
WHERE preferences IS NOT NULL;

-- [VARIATION 5] JSON_UNQUOTE (Alternative to ->>)
SELECT customer_id, 
       JSON_UNQUOTE(JSON_EXTRACT(preferences, '$.theme')) AS theme
FROM customers
WHERE preferences IS NOT NULL;

-- [VARIATION 6] JSON_CONTAINS (Check if JSON array contains a value)
SELECT customer_id 
FROM customers 
WHERE JSON_CONTAINS(preferences, '"email"', '$.notifications');

-- [VARIATION 7] JSON_CONTAINS_PATH (Check if a path exists)
SELECT customer_id 
FROM customers 
WHERE JSON_CONTAINS_PATH(preferences, 'one', '$.theme');

-- [VARIATION 8] JSON_SET (Update/add values)
UPDATE customers 
SET preferences = JSON_SET(preferences, '$.theme', 'blue', '$.timezone', 'UTC')
WHERE customer_id = 1;

-- [VARIATION 9] JSON_INSERT (Only adds if path doesn't exist)
UPDATE customers 
SET preferences = JSON_INSERT(preferences, '$.new_field', 'new_value')
WHERE customer_id = 1;

-- [VARIATION 10] JSON_REPLACE (Only updates if path exists)
UPDATE customers 
SET preferences = JSON_REPLACE(preferences, '$.theme', 'red')
WHERE customer_id = 1;

-- [VARIATION 11] JSON_REMOVE (Remove a key)
UPDATE customers 
SET preferences = JSON_REMOVE(preferences, '$.timezone')
WHERE customer_id = 1;

-- [VARIATION 12] JSON_KEYS (Get all keys)
SELECT customer_id, JSON_KEYS(preferences) AS keys
FROM customers
WHERE preferences IS NOT NULL;

-- [VARIATION 13] JSON_LENGTH (Get array length or object size)
SELECT customer_id, 
       JSON_LENGTH(preferences, '$.notifications') AS notification_count
FROM customers
WHERE preferences IS NOT NULL;

-- [VARIATION 14] JSON_TABLE (Convert JSON to relational table - MySQL 8.0+)
SELECT jt.*
FROM customers,
     JSON_TABLE(
         preferences,
         '$' COLUMNS(
             theme VARCHAR(20) PATH '$.theme',
             language VARCHAR(10) PATH '$.language',
             NESTED PATH '$.notifications[*]' COLUMNS (
                 notification VARCHAR(20) PATH '$'
             )
         )
     ) AS jt
WHERE preferences IS NOT NULL;

-- [VARIATION 15] JSON_SEARCH (Search for a value)
SELECT customer_id, 
       JSON_SEARCH(preferences, 'all', 'email') AS path
FROM customers
WHERE preferences IS NOT NULL;

-- [VARIATION 16] JSON_ARRAY_APPEND (Append to array)
UPDATE customers 
SET preferences = JSON_ARRAY_APPEND(preferences, '$.notifications', 'whatsapp')
WHERE customer_id = 1;

-- [VARIATION 17] JSON_ARRAY_INSERT (Insert at specific position)
UPDATE customers 
SET preferences = JSON_ARRAY_INSERT(preferences, '$.notifications[1]', 'telegram')
WHERE customer_id = 1;

-- [VARIATION 18] Index on JSON field (Generated Column)
ALTER TABLE customers 
ADD COLUMN theme VARCHAR(20) 
GENERATED ALWAYS AS (preferences ->> '$.theme') STORED;

CREATE INDEX idx_customers_theme ON customers(theme);

-- Query using generated column
SELECT * FROM customers WHERE theme = 'dark';


-- ===================================================================
-- SECTION 7: PARTITIONING (RANGE, LIST, HASH, KEY)
-- ===================================================================

-- [VARIATION 1] RANGE Partitioning (By date)
CREATE TABLE sales_partitioned (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATE NOT NULL,
    amount DECIMAL(10,2),
    region VARCHAR(20)
) PARTITION BY RANGE (YEAR(sale_date)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Insert sample data
INSERT INTO sales_partitioned (sale_id, customer_id, sale_date, amount, region)
SELECT sale_id, customer_id, sale_date, amount, region FROM sales LIMIT 1000;

-- Query specific partition
SELECT * FROM sales_partitioned PARTITION (p2024);

-- Show partition info
SELECT PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE TABLE_NAME = 'sales_partitioned';

-- [VARIATION 2] LIST Partitioning (By discrete values)
CREATE TABLE customers_partitioned (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    region VARCHAR(20)
) PARTITION BY LIST COLUMNS(region) (
    PARTITION p_north VALUES IN ('North'),
    PARTITION p_south VALUES IN ('South'),
    PARTITION p_west VALUES IN ('West'),
    PARTITION p_other VALUES IN ('East', 'Central')
);

-- [VARIATION 3] HASH Partitioning (Distribute evenly)
CREATE TABLE sales_hash (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATE,
    amount DECIMAL(10,2)
) PARTITION BY HASH(customer_id) PARTITIONS 4;

-- [VARIATION 4] KEY Partitioning (Similar to HASH, but uses MySQL's internal function)
CREATE TABLE sales_key (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATE,
    amount DECIMAL(10,2)
) PARTITION BY KEY(customer_id) PARTITIONS 4;

-- [VARIATION 5] Subpartitioning (Partition by RANGE, subpartition by HASH)
CREATE TABLE sales_subpart (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    region VARCHAR(20)
) PARTITION BY RANGE (YEAR(sale_date))
SUBPARTITION BY HASH (MONTH(sale_date)) 
SUBPARTITIONS 3 (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026)
);

-- [VARIATION 6] ALTER TABLE ADD/DROP/REORGANIZE PARTITION
ALTER TABLE sales_partitioned ADD PARTITION (
    PARTITION p2026 VALUES LESS THAN (2027)
);

ALTER TABLE sales_partitioned DROP PARTITION p_future;

ALTER TABLE sales_partitioned REORGANIZE PARTITION p2024, p2025 INTO (
    PARTITION p_new2024 VALUES LESS THAN (2025),
    PARTITION p_new2025 VALUES LESS THAN (2026)
);

-- [VARIATION 7] TRUNCATE PARTITION (Remove data from a specific partition)
ALTER TABLE sales_partitioned TRUNCATE PARTITION p2023;

-- [VARIATION 8] Check if a table is partitioned
SELECT CREATE_OPTIONS 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'sales_partitioned';


-- ===================================================================
-- SECTION 8: DATA EXPORT & IMPORT (SELECT INTO OUTFILE / LOAD DATA INFILE)
-- ===================================================================

-- ⚠️ Note: These commands require FILE privilege and the secure_file_priv setting.
-- To check: SHOW VARIABLES LIKE 'secure_file_priv';

-- [VARIATION 1] Export entire table to CSV (comma separated, enclosed in quotes)
-- SELECT * INTO OUTFILE '/tmp/sales_export.csv'
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n'
-- FROM sales LIMIT 1000;

-- [VARIATION 2] Export with custom delimiter and header (using UNION)
-- (SELECT 'sale_id', 'customer_id', 'amount') UNION (SELECT sale_id, customer_id, amount FROM sales LIMIT 100)
-- INTO OUTFILE '/tmp/sales_header.csv'
-- FIELDS TERMINATED BY ',' 
-- LINES TERMINATED BY '\n';

-- [VARIATION 3] Export specific columns with WHERE clause
-- SELECT customer_id, amount, sale_date 
-- INTO OUTFILE '/tmp/sales_filtered.csv'
-- FIELDS TERMINATED BY ','
-- LINES TERMINATED BY '\n'
-- FROM sales 
-- WHERE region = 'North' LIMIT 100;

-- [VARIATION 4] LOAD DATA INFILE (Import CSV back into a table)
-- LOAD DATA INFILE '/tmp/sales_export.csv'
-- INTO TABLE sales_import
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;  -- If header exists

-- [VARIATION 5] LOAD DATA with SET clause (transform data during import)
-- LOAD DATA INFILE '/tmp/sales_export.csv'
-- INTO TABLE sales_import
-- FIELDS TERMINATED BY ','
-- LINES TERMINATED BY '\n'
-- (customer_id, amount, @sale_date)
-- SET sale_date = STR_TO_DATE(@sale_date, '%Y-%m-%d');

-- [VARIATION 6] Export using mysql command-line (not SQL, but good to know):
-- mysql -u root -p -e "SELECT * FROM demo_performance.sales" > /tmp/sales.txt


-- ===================================================================
-- SECTION 9: ADVANCED QUERY OPTIMIZATION TECHNIQUES
-- ===================================================================

-- [VARIATION 1] Subquery vs JOIN (Which is faster? Let's see the plan)
EXPLAIN SELECT * FROM sales WHERE customer_id IN (SELECT customer_id FROM customers WHERE loyalty_points > 500);
EXPLAIN SELECT s.* FROM sales s INNER JOIN customers c ON s.customer_id = c.customer_id WHERE c.loyalty_points > 500;

-- [VARIATION 2] EXISTS vs IN
EXPLAIN SELECT * FROM sales s WHERE EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = s.customer_id AND c.loyalty_points > 500);

-- [VARIATION 3] UNION vs UNION ALL (UNION ALL is faster if you don't need distinct)
EXPLAIN SELECT customer_id, amount FROM sales WHERE region = 'North'
UNION
SELECT customer_id, amount FROM sales WHERE region = 'South';

EXPLAIN SELECT customer_id, amount FROM sales WHERE region = 'North'
UNION ALL
SELECT customer_id, amount FROM sales WHERE region = 'South';

-- [VARIATION 4] Derived Table vs CTE (CTEs are more readable, performance similar)
SELECT * FROM (SELECT customer_id, AVG(amount) AS avg_amt FROM sales GROUP BY customer_id) AS derived WHERE avg_amt > 500;

WITH cte_avg AS (SELECT customer_id, AVG(amount) AS avg_amt FROM sales GROUP BY customer_id)
SELECT * FROM cte_avg WHERE avg_amt > 500;

-- [VARIATION 5] Optimizing LIKE queries with FULLTEXT
-- Instead of: SELECT * FROM customers WHERE first_name LIKE '%John%';
-- Use: SELECT * FROM customers WHERE MATCH(first_name, last_name) AGAINST('John' IN NATURAL LANGUAGE MODE);

-- [VARIATION 6] Use STRAIGHT_JOIN to force join order
EXPLAIN SELECT STRAIGHT_JOIN s.*, c.first_name 
FROM sales s 
INNER JOIN customers c ON s.customer_id = c.customer_id 
WHERE s.amount > 500;

-- [VARIATION 7] SQL_NO_CACHE (Disable query cache - removed in MySQL 8.0, but shown for legacy)
-- SELECT SQL_NO_CACHE * FROM sales WHERE customer_id = 100;


-- ===================================================================
-- SECTION 10: PERFORMANCE DIAGNOSTICS (All SHOW commands)
-- ===================================================================

-- [VARIATION 1] SHOW INDEX (already shown)
SHOW INDEX FROM sales;

-- [VARIATION 2] SHOW TABLE STATUS (Get table size, row count, avg row length)
SHOW TABLE STATUS FROM demo_performance LIKE 'sales';

-- [VARIATION 3] SHOW STATUS (Global and session variables)
SHOW STATUS LIKE 'Innodb_rows_read';
SHOW STATUS LIKE 'Slow_queries';

-- [VARIATION 4] SHOW PROCESSLIST (See currently running queries)
SHOW FULL PROCESSLIST;

-- [VARIATION 5] SHOW ENGINE INNODB STATUS (InnoDB internals)
-- SHOW ENGINE INNODB STATUS\G

-- [VARIATION 6] SHOW VARIABLES (Configuration settings)
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'query_cache%';  -- (Deprecated in 8.0)


-- ===================================================================
-- SECTION 11: FINAL CLEANUP (Optional)
-- ===================================================================

-- DROP DATABASE IF EXISTS demo_performance;

-- ===================================================================
--                           SUMMARY OF COVERAGE
-- 
-- INDEXES:      Single, Composite, Unique, Full-Text, Spatial, 
--               Descending, Invisible, Covering, Prefix, 
--               CREATE/ALTER/DROP, SHOW, RENAME.
-- 
-- EXPLAIN:      Basic, FORMAT=JSON, FORMAT=TREE, EXPLAIN ANALYZE,
--               OPTIMIZER_TRACE, USE/FORCE/IGNORE INDEX.
-- 
-- CTEs:         Simple, Multiple, Recursive, with DELETE/UPDATE.
-- 
-- WINDOW FUNCS: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, 
--               FIRST_VALUE, LAST_VALUE, NTILE, SUM/AVG/COUNT OVER,
--               ROWS/RANGE frames, CUME_DIST, PERCENT_RANK.
-- 
-- JSON:         JSON_OBJECT, JSON_ARRAY, JSON_EXTRACT (->>), 
--               JSON_CONTAINS, JSON_CONTAINS_PATH, JSON_SET, 
--               JSON_INSERT, JSON_REPLACE, JSON_REMOVE, JSON_KEYS,
--               JSON_LENGTH, JSON_TABLE, JSON_SEARCH, 
--               JSON_ARRAY_APPEND, JSON_ARRAY_INSERT, Generated Columns.
-- 
-- PARTITIONING: RANGE, LIST, HASH, KEY, Subpartitioning, 
--               ADD/DROP/REORGANIZE/TRUNCATE PARTITION.
-- 
-- EXPORT/IMPORT: SELECT INTO OUTFILE, LOAD DATA INFILE (with options).
-- 
-- OPTIMIZATION: EXISTS vs IN, UNION vs UNION ALL, Subquery vs JOIN,
--               STRAIGHT_JOIN, Diagnostic SHOW commands.
-- ===================================================================