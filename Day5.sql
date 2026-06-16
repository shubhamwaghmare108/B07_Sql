-- ===================================================================
--                      DAY 5: DQL COMPLETE
--       The Ultimate SELECT Statement Encyclopedia
-- ===================================================================

-- ===================================================================
-- SECTION 1: SETUP (Dedicated Database for DQL Demos)
-- ===================================================================

DROP DATABASE IF EXISTS demo_dql;
CREATE DATABASE demo_dql;
USE demo_dql;

-- Departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

-- Employees table (for JOINs, Subqueries, Aggregates)
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    dept_id INT,
    salary DECIMAL(10,2),
    commission_pct DECIMAL(5,2) DEFAULT 0.00,
    hire_date DATE,
    manager_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Orders table (for date ranges, grouping, and analysis)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    total_amount DECIMAL(12,2),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Products table (for UNION/INTERSECT/EXCEPT scenarios)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT
);

-- Order_Items (for complex joins)
CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Insert sample data
INSERT INTO departments (dept_name, location) VALUES
('Engineering', 'New York'),
('Sales', 'Los Angeles'),
('HR', 'Chicago'),
('Finance', 'Boston'),
('Marketing', 'San Francisco');

INSERT INTO employees (first_name, last_name, email, dept_id, salary, commission_pct, hire_date, manager_id) VALUES
('John', 'Doe', 'john.doe@email.com', 1, 85000, 0.05, '2019-01-15', NULL),
('Jane', 'Smith', 'jane.smith@email.com', 1, 92000, 0.07, '2018-06-20', 1),
('Bob', 'Johnson', 'bob.j@email.com', 2, 62000, 0.10, '2020-03-10', 1),
('Alice', 'Williams', 'alice.w@email.com', 3, 54000, 0.00, '2021-07-01', 2),
('Charlie', 'Brown', 'charlie.b@email.com', 2, 68000, 0.12, '2019-11-05', 3),
('David', 'Miller', 'david.m@email.com', 4, 78000, 0.03, '2020-09-12', 1),
('Eva', 'Davis', 'eva.d@email.com', 5, 60000, 0.08, '2022-01-20', 3),
('Frank', 'Wilson', 'frank.w@email.com', 4, 82000, 0.04, '2018-12-01', 6),
('Grace', 'Lee', 'grace.l@email.com', 1, 95000, 0.06, '2017-10-15', 1),
('Henry', 'Taylor', 'henry.t@email.com', 3, 49000, 0.00, '2022-06-11', 4),
('Ivy', 'Anderson', 'ivy.a@email.com', 2, 71000, 0.11, '2020-02-14', 3),
('Jack', 'Thomas', 'jack.t@email.com', 5, 64000, 0.09, '2021-08-25', 7);

INSERT INTO products (product_name, category, price, stock_quantity) VALUES
('Laptop Pro', 'Electronics', 1200.00, 50),
('Wireless Mouse', 'Electronics', 25.99, 200),
('Desk Chair', 'Furniture', 350.00, 30),
('Coffee Mug', 'Home', 12.50, 500),
('Monitor 27"', 'Electronics', 450.00, 40),
('Bookshelf', 'Furniture', 180.00, 15),
('Pen Set', 'Office', 15.75, 300),
('Headphones', 'Electronics', 85.00, 75);

INSERT INTO orders (emp_id, order_date, order_status, total_amount) VALUES
(1, '2025-01-10', 'Completed', 1650.00),
(2, '2025-01-12', 'Completed', 475.99),
(3, '2025-01-15', 'Pending', 350.00),
(4, '2025-01-18', 'Cancelled', 25.00),
(5, '2025-01-20', 'Completed', 1800.00),
(6, '2025-01-22', 'Completed', 85.00),
(7, '2025-01-25', 'Processing', 620.50),
(1, '2025-02-01', 'Completed', 240.00),
(2, '2025-02-03', 'Completed', 800.00),
(3, '2025-02-05', 'Pending', 120.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),
(1, 2, 2, 25.99),
(2, 5, 1, 450.00),
(2, 8, 1, 25.99),
(3, 3, 1, 350.00),
(4, 4, 2, 12.50),
(5, 1, 1, 1200.00),
(5, 6, 1, 180.00),
(5, 2, 2, 25.99),
(6, 8, 1, 85.00),
(7, 5, 1, 450.00),
(7, 2, 1, 25.99),
(7, 6, 1, 180.00),
(8, 4, 2, 12.50),
(8, 7, 1, 15.75),
(9, 3, 1, 350.00),
(9, 5, 1, 450.00);

-- Verify data
SELECT '=== DATABASE SETUP COMPLETE ===' AS Status;
SELECT COUNT(*) AS Total_Employees FROM employees;
SELECT COUNT(*) AS Total_Orders FROM orders;


-- ===================================================================
-- SECTION 2: SELECT - THE BASICS (ALL PERMUTATIONS)
-- ===================================================================

-- [2.1] SELECT ALL columns
SELECT * FROM employees;

-- [2.2] SELECT specific columns
SELECT first_name, last_name, salary FROM employees;

-- [2.3] SELECT with DISTINCT (remove duplicates)
SELECT DISTINCT dept_id FROM employees;
SELECT DISTINCT dept_id, salary FROM employees; -- Unique combinations

-- [2.4] SELECT with Aliases (Column and Table)
SELECT e.first_name AS "First Name", e.salary AS Salary FROM employees e;

-- [2.5] SELECT with Calculated Columns (Expressions)
SELECT first_name, salary, salary * 1.10 AS "Salary + 10% Bonus" FROM employees;

-- [2.6] SELECT with Concatenation
SELECT CONCAT(first_name, ' ', last_name) AS Full_Name FROM employees;

-- [2.7] SELECT with CASE expression (Simple & Searched)
SELECT first_name, salary,
    CASE 
        WHEN salary >= 90000 THEN 'Executive'
        WHEN salary >= 70000 THEN 'Senior'
        WHEN salary >= 50000 THEN 'Mid-Level'
        ELSE 'Junior'
    END AS level
FROM employees;

-- [2.8] SELECT with IF() function (Simple conditional)
SELECT first_name, salary, IF(salary > 70000, 'High', 'Standard') AS salary_grade FROM employees;

-- [2.9] SELECT with NULL handling (IFNULL, COALESCE)
SELECT first_name, 
       IFNULL(commission_pct, 0) AS comm_pct_ifnull,
       COALESCE(commission_pct, 0, 999) AS comm_pct_coalesce -- returns first non-null
FROM employees;

-- [2.10] SELECT with Literals
SELECT 'Employee Record' AS Header, first_name, salary FROM employees;

-- [2.11] SELECT with `LIMIT` (Row restriction)
SELECT * FROM employees LIMIT 5;          -- First 5 rows
SELECT * FROM employees LIMIT 2 OFFSET 3; -- Skip 3, take 2 (Pagination)
SELECT * FROM employees LIMIT 3, 2;       -- Same as LIMIT 2 OFFSET 3 (MySQL syntax)


-- ===================================================================
-- SECTION 3: WHERE CLAUSE - ALL OPERATORS
-- ===================================================================

-- [3.1] Comparison Operators: =, !=/<> , >, >=, <, <=
SELECT * FROM employees WHERE salary = 85000;
SELECT * FROM employees WHERE salary <> 85000;
SELECT * FROM employees WHERE salary > 70000;
SELECT * FROM employees WHERE hire_date <= '2020-01-01';

-- [3.2] Logical Operators: AND, OR, NOT
SELECT * FROM employees WHERE dept_id = 1 AND salary > 90000;
SELECT * FROM employees WHERE dept_id = 1 OR dept_id = 2;
SELECT * FROM employees WHERE NOT (dept_id = 3);

-- [3.3] BETWEEN (Inclusive range)
SELECT * FROM employees WHERE salary BETWEEN 60000 AND 80000;
SELECT * FROM employees WHERE hire_date BETWEEN '2020-01-01' AND '2021-12-31';

-- [3.4] IN / NOT IN (List of values)
SELECT * FROM employees WHERE dept_id IN (1, 2, 5);
SELECT * FROM employees WHERE dept_id NOT IN (3, 4);

-- [3.5] LIKE / NOT LIKE (Pattern matching)
SELECT * FROM employees WHERE first_name LIKE 'J%';    -- Starts with J
SELECT * FROM employees WHERE first_name LIKE '%a%';   -- Contains 'a'
SELECT * FROM employees WHERE first_name LIKE '_o%';   -- Second letter is 'o'
SELECT * FROM employees WHERE first_name NOT LIKE 'A%';

-- [3.6] REGEXP / RLIKE (Regular Expressions - Powerful!)
SELECT * FROM employees WHERE first_name REGEXP '^J';         -- Starts with J
SELECT * FROM employees WHERE first_name REGEXP 'a$';         -- Ends with a
SELECT * FROM employees WHERE first_name REGEXP '[aeiou]';    -- Contains vowel
SELECT * FROM employees WHERE first_name REGEXP '^[A-G]';     -- Starts with A-G

-- [3.7] IS NULL / IS NOT NULL (Handling missing data)
SELECT * FROM employees WHERE commission_pct IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;

-- [3.8] EXISTS / NOT EXISTS (Subquery condition)
SELECT * FROM employees e 
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id);

SELECT * FROM employees e 
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id);

-- [3.9] ANY / SOME / ALL (Subquery comparisons)
-- Find employees earning more than ANY employee in department 2 (i.e., more than the lowest)
SELECT * FROM employees 
WHERE salary > ANY (SELECT salary FROM employees WHERE dept_id = 2);

-- Find employees earning more than ALL employees in department 3 (i.e., more than the highest)
SELECT * FROM employees 
WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 3);

-- SOME is a synonym for ANY
SELECT * FROM employees 
WHERE salary = SOME (SELECT salary FROM employees WHERE dept_id = 1);


-- ===================================================================
-- SECTION 4: ORDER BY - SORTING (ALL VARIATIONS)
-- ===================================================================

-- [4.1] Single column (ASC default)
SELECT * FROM employees ORDER BY salary;  -- Ascending
SELECT * FROM employees ORDER BY salary ASC; -- Explicit ascending

-- [4.2] Descending
SELECT * FROM employees ORDER BY salary DESC;

-- [4.3] Multiple columns
SELECT * FROM employees ORDER BY dept_id ASC, salary DESC;

-- [4.4] By Column Alias
SELECT first_name, salary AS sal FROM employees ORDER BY sal DESC;

-- [4.5] By Column Position (Numeric - not recommended for readability)
SELECT first_name, salary FROM employees ORDER BY 2 DESC; -- Sorts by 2nd column

-- [4.6] By Expression
SELECT first_name, salary FROM employees ORDER BY salary * 0.90 DESC;

-- [4.7] NULLS FIRST / NULLS LAST (MySQL 8.0+)
SELECT first_name, commission_pct FROM employees ORDER BY commission_pct NULLS FIRST;
SELECT first_name, commission_pct FROM employees ORDER BY commission_pct NULLS LAST;

-- [4.8] With LIMIT (Top N)
SELECT * FROM employees ORDER BY salary DESC LIMIT 3; -- Top 3 highest paid


-- ===================================================================
-- SECTION 5: AGGREGATE FUNCTIONS & GROUP BY (ALL PERMUTATIONS)
-- ===================================================================

-- [5.1] Basic Aggregates: COUNT, SUM, AVG, MIN, MAX, STDDEV, VARIANCE
SELECT 
    COUNT(*) AS total_employees,
    COUNT(DISTINCT dept_id) AS total_departments,
    SUM(salary) AS total_salary_budget,
    AVG(salary) AS average_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    STDDEV(salary) AS salary_stddev,
    VARIANCE(salary) AS salary_variance
FROM employees;

-- [5.2] GROUP BY (Single column)
SELECT dept_id, 
       COUNT(*) AS emp_count,
       AVG(salary) AS avg_dept_salary
FROM employees
GROUP BY dept_id;

-- [5.3] GROUP BY (Multiple columns)
SELECT dept_id, is_active, 
       COUNT(*) AS count
FROM employees
GROUP BY dept_id, is_active;

-- [5.4] HAVING clause (Filter after grouping)
SELECT dept_id, 
       AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 70000;

-- [5.5] HAVING with aggregate conditions (without SELECTing the aggregate)
SELECT dept_id, COUNT(*) AS emp_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) >= 3;  -- Filter departments with 3+ employees

-- [5.6] GROUP BY with WHERE (Filter before grouping)
SELECT dept_id, AVG(salary) 
FROM employees
WHERE hire_date >= '2020-01-01'
GROUP BY dept_id;

-- [5.7] GROUP_CONCAT (Comma-separated list)
SELECT dept_id, 
       GROUP_CONCAT(first_name ORDER BY first_name SEPARATOR ', ') AS employee_list
FROM employees
GROUP BY dept_id;

-- [5.8] GROUP BY with ROLLUP (Subtotals and Grand Totals - MySQL 8.0+)
SELECT 
    dept_id,
    IFNULL(manager_id, 0) AS manager,
    SUM(salary) AS total_salary
FROM employees
GROUP BY dept_id, manager_id WITH ROLLUP;

-- [5.9] GROUPING() function (Identify ROLLUP rows - MySQL 8.0+)
SELECT 
    dept_id,
    GROUPING(dept_id) AS dept_grouping, -- 1 if row is a subtotal for dept
    SUM(salary) AS total_salary
FROM employees
GROUP BY dept_id WITH ROLLUP;

-- [5.10] Filtering groups with HAVING and COMPLEX conditions
SELECT dept_id, 
       AVG(salary) AS avg_sal,
       COUNT(*) AS cnt
FROM employees
GROUP BY dept_id
HAVING avg_sal > 60000 AND cnt >= 2;


-- ===================================================================
-- SECTION 6: JOINS - EVERY TYPE (ALL PERMUTATIONS)
-- ===================================================================

-- [6.1] INNER JOIN (Explicit syntax - returns only matching rows)
SELECT e.first_name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- [6.2] INNER JOIN (Implicit syntax - old style)
SELECT e.first_name, d.dept_name
FROM employees e, departments d
WHERE e.dept_id = d.dept_id;

-- [6.3] LEFT JOIN (All rows from left, matching from right, NULL if no match)
SELECT e.first_name, o.order_id, o.total_amount
FROM employees e
LEFT JOIN orders o ON e.emp_id = o.emp_id;

-- [6.4] RIGHT JOIN (All rows from right, matching from left)
SELECT o.order_id, e.first_name
FROM employees e
RIGHT JOIN orders o ON e.emp_id = o.emp_id;

-- [6.5] FULL OUTER JOIN (MySQL workaround using UNION of LEFT and RIGHT)
SELECT e.first_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.first_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- [6.6] CROSS JOIN (Cartesian product - every row from A combined with every row from B)
SELECT e.first_name, d.dept_name
FROM employees e
CROSS JOIN departments d
LIMIT 10; -- (Too many rows, so limiting)

-- [6.7] NATURAL JOIN (Joins on columns with same name - DANGEROUS, but included)
-- Note: This joins on 'dept_id' automatically because it exists in both.
SELECT e.first_name, d.dept_name
FROM employees e
NATURAL JOIN departments d;

-- [6.8] SELF JOIN (Join a table to itself)
-- Find employees and their managers
SELECT e1.first_name AS Employee, e2.first_name AS Manager
FROM employees e1
LEFT JOIN employees e2 ON e1.manager_id = e2.emp_id;

-- [6.9] STRAIGHT_JOIN (Force join order - optimizer hint)
SELECT STRAIGHT_JOIN e.first_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- [6.10] JOIN with USING clause (Simpler when column names match)
SELECT e.first_name, d.dept_name
FROM employees e
INNER JOIN departments d USING(dept_id);

-- [6.11] JOIN with multiple conditions
SELECT o.order_id, oi.product_id, p.product_name
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed';

-- [6.12] Joining more than 3 tables
SELECT e.first_name, o.order_id, p.product_name, oi.quantity
FROM employees e
INNER JOIN orders o ON e.emp_id = o.emp_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LIMIT 10;


-- ===================================================================
-- SECTION 7: SUBQUERIES (ALL TYPES & POSITIONS)
-- ===================================================================

-- [7.1] Subquery in SELECT (Scalar subquery - must return 1 row, 1 column)
SELECT first_name, salary,
       (SELECT AVG(salary) FROM employees) AS company_avg_salary,
       salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- [7.2] Subquery in FROM (Derived Table - must have alias)
SELECT dept_id, avg_salary
FROM (SELECT dept_id, AVG(salary) AS avg_salary FROM employees GROUP BY dept_id) AS dept_stats
WHERE avg_salary > 70000;

-- [7.3] Subquery in WHERE (returns a single value)
SELECT * FROM employees 
WHERE salary > (SELECT AVG(salary) FROM employees);

-- [7.4] Subquery in WHERE with IN (returns a list)
SELECT * FROM employees 
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'New York');

-- [7.5] Subquery in WHERE with EXISTS (Correlated subquery)
SELECT * FROM employees e
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id AND o.total_amount > 1000);

-- [7.6] Subquery in HAVING
SELECT dept_id, AVG(salary) AS avg_sal
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- [7.7] Correlated Subquery (references outer query)
-- Find employees who earn more than average salary in their own department
SELECT e1.first_name, e1.salary, e1.dept_id
FROM employees e1
WHERE e1.salary > (SELECT AVG(e2.salary) FROM employees e2 WHERE e2.dept_id = e1.dept_id);

-- [7.8] Multiple Row Subqueries with ANY/ALL (covered above, but recap)
SELECT * FROM employees WHERE salary > ANY (SELECT salary FROM employees WHERE dept_id = 2);
SELECT * FROM employees WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 3);

-- [7.9] Subquery in UPDATE (derived table in SET)
-- (Example: Set commission based on avg)
UPDATE employees 
SET commission_pct = 0.05 
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'New York');
-- Rollback to original values for demo safety:
UPDATE employees SET commission_pct = 0.05 WHERE dept_id = 1; -- Re-add if needed (but we'll just leave it)

-- [7.10] Subquery in INSERT (INSERT INTO ... SELECT)
CREATE TABLE emp_high_salaries AS SELECT * FROM employees WHERE 1=0; -- empty copy
INSERT INTO emp_high_salaries 
SELECT * FROM employees WHERE salary > (SELECT AVG(salary) FROM employees);
SELECT * FROM emp_high_salaries; -- Verify

-- [7.11] Subquery with LIMIT (Top N in subquery)
SELECT * FROM employees 
WHERE salary IN (SELECT salary FROM employees ORDER BY salary DESC LIMIT 3);


-- ===================================================================
-- SECTION 8: SET OPERATIONS (UNION, UNION ALL, INTERSECT, EXCEPT)
-- ===================================================================

-- Create tables for set operation demos
CREATE TABLE sales_team AS SELECT * FROM employees WHERE dept_id = 2;
CREATE TABLE support_team AS SELECT * FROM employees WHERE dept_id = 3;

-- [8.1] UNION (Removes duplicates)
SELECT first_name, last_name FROM sales_team
UNION
SELECT first_name, last_name FROM support_team;

-- [8.2] UNION ALL (Keeps duplicates - faster)
SELECT first_name, last_name FROM sales_team
UNION ALL
SELECT first_name, last_name FROM support_team;

-- [8.3] INTERSECT (MySQL 8.0+ - rows that exist in BOTH queries)
SELECT first_name, last_name FROM sales_team
INTERSECT
SELECT first_name, last_name FROM support_team; -- Usually returns empty if no overlap

-- Create overlap to test:
INSERT INTO sales_team (first_name, last_name, email, dept_id, salary, hire_date) 
VALUES ('Common', 'User', 'common@email.com', 2, 50000, CURDATE());
INSERT INTO support_team (first_name, last_name, email, dept_id, salary, hire_date) 
VALUES ('Common', 'User', 'common@email.com', 3, 50000, CURDATE());

-- Now INTERSECT returns 'Common User'
SELECT first_name, last_name FROM sales_team
INTERSECT
SELECT first_name, last_name FROM support_team;

-- [8.4] EXCEPT (MySQL 8.0+ - rows in first query but NOT in second)
SELECT first_name, last_name FROM sales_team
EXCEPT
SELECT first_name, last_name FROM support_team; -- Returns all sales team except 'Common User'

-- [8.5] ORDER BY with SET operations (Must be applied to the final result)
SELECT first_name, last_name FROM sales_team
UNION
SELECT first_name, last_name FROM support_team
ORDER BY first_name;

-- [8.6] LIMIT with SET operations
(SELECT first_name, last_name FROM sales_team LIMIT 1)
UNION ALL
(SELECT first_name, last_name FROM support_team LIMIT 1);


-- ===================================================================
-- SECTION 9: ADVANCED SELECT FEATURES
-- ===================================================================

-- [9.1] SELECT INTO (Assign query results to variables)
SELECT @avg_salary := AVG(salary), @max_salary := MAX(salary) 
FROM employees;
SELECT @avg_salary AS avg_sal, @max_salary AS max_sal;

-- [9.2] SELECT with GET DIAGNOSTICS (for error handling - often used in procedures)
-- (Skipping as it's procedural, not purely DQL)

-- [9.3] SELECT ... FOR UPDATE (Row locks - covered in Day2, but included for completeness)
START TRANSACTION;
SELECT * FROM employees WHERE emp_id = 1 FOR UPDATE;
-- Do something
COMMIT;

-- [9.4] SELECT ... LOCK IN SHARE MODE (Shared locks)
START TRANSACTION;
SELECT * FROM employees WHERE emp_id = 2 LOCK IN SHARE MODE;
COMMIT;

-- [9.5] SELECT with ROW_NUMBER, RANK, etc. (Window Functions - Detailed in Day4)
SELECT first_name, salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
       RANK() OVER (ORDER BY salary DESC) AS rank_num,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank_num
FROM employees;

-- [9.6] SELECT with CTE (WITH clause - covered in Day4)
WITH high_earners AS (
    SELECT * FROM employees WHERE salary > 75000
)
SELECT first_name, salary FROM high_earners ORDER BY salary DESC;

-- [9.7] SELECT with JSON functions (covered in Day4, but here's a quick DQL-only example)
SELECT JSON_OBJECT('id', emp_id, 'name', first_name, 'salary', salary) AS employee_json
FROM employees WHERE emp_id = 1;

-- [9.8] SELECT with GROUP BY and BIT functions (BIT_AND, BIT_OR, BIT_XOR)
-- Add a BIT column to test
ALTER TABLE employees ADD COLUMN has_laptop BIT DEFAULT 0;
UPDATE employees SET has_laptop = 1 WHERE emp_id IN (1, 2, 5, 7);
SELECT dept_id, 
       BIT_AND(has_laptop) AS all_have_laptop,
       BIT_OR(has_laptop) AS any_have_laptop,
       BIT_XOR(has_laptop) AS xor_laptop
FROM employees
GROUP BY dept_id;

-- [9.9] SELECT with GROUP BY and JSON_ARRAYAGG / JSON_OBJECTAGG (MySQL 5.7+)
SELECT dept_id,
       JSON_ARRAYAGG(first_name) AS employees_list,
       JSON_OBJECTAGG(emp_id, first_name) AS emp_id_name_map
FROM employees
GROUP BY dept_id;


-- ===================================================================
-- SECTION 10: PERFORMANCE-ORIENTED DQL (HINTS & OPTIMIZER)
-- ===================================================================

-- [10.1] SQL_CALC_FOUND_ROWS (Count total rows without running query twice - deprecated in 8.0 but legacy)
-- SELECT SQL_CALC_FOUND_ROWS * FROM employees LIMIT 5;
-- SELECT FOUND_ROWS(); -- Total count

-- [10.2] SELECT with USE INDEX (Covered Day4, included for DQL completeness)
SELECT * FROM employees USE INDEX (PRIMARY) WHERE emp_id = 1;

-- [10.3] SELECT with IGNORE INDEX
SELECT * FROM employees IGNORE INDEX (PRIMARY) WHERE emp_id = 1;

-- [10.4] SELECT with FORCE INDEX
SELECT * FROM employees FORCE INDEX (PRIMARY) WHERE emp_id = 1;

-- [10.5] SELECT ... WITH ROLLUP (covered in aggregate section)
-- [10.6] SELECT ... PROCEDURE ANALYSE() (Deprecated, skipping)


-- ===================================================================
-- SECTION 11: DQL WITH DATE/TIME FUNCTIONS (ALL PERMUTATIONS)
-- ===================================================================

-- [11.1] Extract Year, Month, Day
SELECT order_date,
       YEAR(order_date) AS year,
       MONTH(order_date) AS month,
       DAY(order_date) AS day,
       QUARTER(order_date) AS quarter,
       WEEK(order_date) AS week
FROM orders;

-- [11.2] Date arithmetic
SELECT order_date, 
       DATE_ADD(order_date, INTERVAL 7 DAY) AS plus_week,
       DATE_SUB(order_date, INTERVAL 1 MONTH) AS minus_month,
       DATEDIFF(CURDATE(), order_date) AS days_ago
FROM orders;

-- [11.3] Date formatting
SELECT order_date,
       DATE_FORMAT(order_date, '%W, %M %d, %Y') AS formatted_date,
       DATE_FORMAT(order_date, '%Y-%m') AS year_month
FROM orders;

-- [11.4] GROUP BY date parts
SELECT YEAR(order_date) AS order_year, COUNT(*) AS order_count
FROM orders
GROUP BY YEAR(order_date);

-- [11.5] Between dates (covered, but emphasis)
SELECT * FROM orders WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';


-- ===================================================================
-- SECTION 12: FINAL CLEANUP (Optional)
-- ===================================================================

-- DROP DATABASE IF EXISTS demo_dql;

-- ===================================================================
--                   DQL COMPLETE - SUMMARY OF COVERAGE
-- 
-- SELECT:          * | columns | DISTINCT | AS aliases | Expressions |
--                  IF/CASE | NULL handling | LITERALS | LIMIT/OFFSET
-- 
-- WHERE:           =, !=, >, <, <=, >= | AND, OR, NOT | BETWEEN | IN | 
--                  LIKE (%, _) | REGEXP/RLIKE | IS NULL | EXISTS | 
--                  ANY/SOME/ALL
-- 
-- ORDER BY:        ASC/DESC | Multiple columns | By Alias | By Position |
--                  By Expression | NULLS FIRST/LAST | with LIMIT
-- 
-- AGGREGATES:      COUNT, SUM, AVG, MIN, MAX, STDDEV, VARIANCE, 
--                  GROUP_CONCAT | GROUP BY (single/multiple) | HAVING | 
--                  WITH ROLLUP | GROUPING()
-- 
-- JOINS:           INNER (explicit/implicit) | LEFT | RIGHT | CROSS |
--                  NATURAL | SELF | STRAIGHT_JOIN | USING() | 
--                  Multi-table | FULL OUTER (via UNION)
-- 
-- SUBQUERIES:      In SELECT (Scalar) | In FROM (Derived) | In WHERE |
--                  In HAVING | Correlated | Multiple Row (ANY/ALL/IN) |
--                  In INSERT/UPDATE | with LIMIT
-- 
-- SET OPERATIONS:  UNION | UNION ALL | INTERSECT | EXCEPT | 
--                  ORDER BY/LIMIT with SET ops
-- 
-- ADVANCED:        SELECT INTO @vars | FOR UPDATE | LOCK IN SHARE MODE |
--                  Window Functions (ROW_NUMBER, RANK, DENSE_RANK) |
--                  CTEs (WITH) | JSON_OBJECT/JSON_ARRAYAGG |
--                  BIT_AND/OR/XOR | Date/Time functions |
--                  Optimizer hints (USE/FORCE/IGNORE INDEX)
-- ===================================================================